// ============================================================================
// ENDOGIN OS — Edge Function: busca (puxa) o progresso que os alunos JÁ
// fizeram na Cademi, usando a API REST oficial dela.
//
// Por que essa função existe além do webhook (cademi-webhook/user.progress):
// o webhook só dispara DAQUI PRA FRENTE, quando o % de um aluno muda depois
// que o webhook foi cadastrado — ele nunca conta a história de quem já
// assistiu aula antes disso. Pra "capturar o progresso que já foi feito",
// só dá puxando ativamente da API (pull), não esperando webhook (push).
//
// Documentação confirmada em ajuda.cademi.com.br/configuracoes/api:
//   GET /usuario/acesso/{usuario_id}
//       -> lista os produtos que o usuário tem acesso (produto.id, nome)
//   GET /usuario/progresso_por_produto/{usuario_id}/{produto_id}
//       -> progresso.total (ex: "41.7%"), assistidas, completas, aulas[]
//
// A API da Cademí tem limite de 2 disparos/segundo (120/min) — por isso
// processa em LOTES e espera ~600ms entre cada chamada.
//
// CHECKPOINT (v38): em vez de offset/limit (que reprocessa todo mundo do
// zero se der erro no meio ou se a aba for fechada), cada aluno tem um
// carimbo `cademi_progress_synced_at`. A cada chamada, a função pega os
// próximos N alunos com esse carimbo mais antigo (NULL primeiro — ou seja,
// quem nunca foi sincronizado, como um aluno novo, sempre entra primeiro) e
// marca como sincronizado ao terminar. Isso faz o botão "Sincronizar agora"
// ser seguro de clicar quantas vezes for preciso: nunca refaz quem já está
// em dia, só avança na fila de quem falta. Pra forçar uma re-sincronização
// completa (ignorando o carimbo), manda { force: true } no corpo.
//
// Autenticação: exige o token de login de um staff (qualquer um, não só
// master) — mesma ideia do admin-tools, mas sem exigir master, já que aqui
// só se lê e atualiza progresso, não se mexe em login de ninguém.
// ============================================================================

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY") ?? "";

// Ex: https://mentoriaendogin.cademi.com.br/api/v1 (sem barra no final)
const CADEMI_API_BASE_URL = (Deno.env.get("CADEMI_API_BASE_URL") ?? "").replace(/\/$/, "");
const CADEMI_API_KEY = Deno.env.get("CADEMI_API_KEY") ?? "";

const RATE_LIMIT_DELAY_MS = 600; // Cademí permite 2/s — margem de segurança

const admin = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

// Sem isso, o navegador bloqueia a chamada vinda do front (botão "Sincronizar
// agora") antes mesmo dela chegar na função — o supabase-js só reporta um
// genérico "Failed to send a request to the Edge Function", sem detalhe.
const corsHeaders: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function jsonResponse(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function callerIsStaff(req: Request): Promise<boolean> {
  const authHeader = req.headers.get("Authorization") ?? "";
  const token = authHeader.replace(/^Bearer\s+/i, "");
  if (!token) return false;

  const callerClient = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
    global: { headers: { Authorization: `Bearer ${token}` } },
  });
  const { data: userData, error: userErr } = await callerClient.auth.getUser();
  if (userErr || !userData?.user) return false;

  const { data: staffRow } = await admin
    .from("staff")
    .select("id")
    .eq("auth_user_id", userData.user.id)
    .maybeSingle();

  return Boolean(staffRow);
}

type CademiAcessoProduto = { id: number | string; nome: string };
type CademiAcessoItem = { produto: CademiAcessoProduto; encerrado: boolean };
type CademiUsuarioResumo = { id: number | string };

async function cademiGet(path: string): Promise<{ ok: boolean; data: unknown; status: number }> {
  const res = await fetch(`${CADEMI_API_BASE_URL}${path}`, {
    method: "GET",
    headers: { Authorization: CADEMI_API_KEY },
  });
  let body: unknown = null;
  try {
    body = await res.json();
  } catch {
    // resposta não-JSON (raro) — deixa null e segue com status pra decidir
  }
  return { ok: res.ok, data: body, status: res.status };
}

function parsePercent(total: unknown): number {
  if (typeof total === "number") return total;
  if (typeof total === "string") {
    const n = parseFloat(total.replace("%", "").replace(",", "."));
    return isNaN(n) ? 0 : n;
  }
  return 0;
}

async function markSynced(studentId: string): Promise<void> {
  await admin.from("students").update({ cademi_progress_synced_at: new Date().toISOString() }).eq("id", studentId);
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return jsonResponse({ ok: false, error: "Método não permitido" }, 405);

  if (!CADEMI_API_BASE_URL || !CADEMI_API_KEY) {
    return jsonResponse(
      { ok: false, error: "CADEMI_API_BASE_URL e/ou CADEMI_API_KEY não configurados como secrets da função." },
      500,
    );
  }

  if (!(await callerIsStaff(req))) {
    return jsonResponse({ ok: false, error: "Só quem é da equipe pode sincronizar." }, 403);
  }

  let body: { limit?: number; force?: boolean } = {};
  try {
    body = await req.json();
  } catch {
    // corpo vazio é aceitável — usa os padrões
  }
  const limit = Math.min(25, Math.max(1, Number(body.limit) || 10));
  const force = body.force === true;

  // Um lote de alunos "pesados" (dezenas de cursos cada) facilmente passa de
  // 100+ chamadas pra Cademí, cada uma com ~600ms de espera, e estoura o
  // tempo máximo de execução da função. Por isso ela se auto-limita por
  // TEMPO: para de trabalhar depois de ~20s e devolve de onde parou — o
  // botão "Sincronizar agora" continua automaticamente na próxima leva.
  const TIME_BUDGET_MS = 20000;
  const startedAt = Date.now();
  function timeUp(): boolean {
    return Date.now() - startedAt > TIME_BUDGET_MS;
  }

  // Não filtra mais por "já ter cademi_user_id" — quem foi importado por
  // planilha (não veio pelo webhook da Cademi) nunca ganhou esse ID, e ficava
  // de fora da sincronização inteira. A API da Cademí aceita buscar por
  // e-mail também (mesmo parâmetro "usuario_email_id_doc" em todos os
  // endpoints), então usa o e-mail de quem ainda não tem o ID — e já
  // aproveita pra gravar o ID assim que encontra, corrigindo o cadastro.
  //
  // CHECKPOINT: pega os N alunos com o carimbo mais antigo (NULL = nunca
  // sincronizado, sempre primeiro). Sem `force`, só entra quem tem o campo
  // NULL — ou seja, alunos novos, já que quem foi sincronizado uma vez não
  // volta pra fila sozinho (é assim que evitamos ficar puxando tudo de novo).
  let query = admin
    .from("students")
    .select("id, full_name, email, cademi_user_id, cademi_progress_synced_at")
    .order("cademi_progress_synced_at", { ascending: true, nullsFirst: true })
    .limit(limit);
  if (!force) {
    query = query.is("cademi_progress_synced_at", null);
  }
  const { data: students, error: studentsErr } = await query;

  if (studentsErr) {
    return jsonResponse({ ok: false, error: studentsErr.message }, 500);
  }

  const results: Array<{ student_id: string; produtos_encontrados: number; cursos_atualizados: number }> = [];
  const errors: Array<{ student_id: string; error: string }> = [];
  const studentList = students ?? [];
  let stoppedEarlyAt = studentList.length;

  // Tudo daqui pra baixo entra num try/catch geral — antes, qualquer erro
  // não previsto (fora do try por-aluno) derrubava a função inteira com um
  // 500 sem corpo nenhum, e o navegador só via "Edge Function returned a
  // non-2xx status code", sem pista do motivo real.
  try {
    for (let i = 0; i < studentList.length; i++) {
      if (timeUp()) {
        stoppedEarlyAt = i;
        break;
      }
      const student = studentList[i];
      let timedOutMidStudent = false;
      try {
        const identifier = student.cademi_user_id ? String(student.cademi_user_id) : student.email;
        if (!identifier) {
          errors.push({ student_id: student.id, error: "sem cademi_user_id e sem e-mail — impossível buscar" });
          await markSynced(student.id); // não adianta reprocessar pra sempre — não tem como buscar mesmo
          continue;
        }

        const acessoRes = await cademiGet(`/usuario/acesso/${encodeURIComponent(identifier)}`);
        await sleep(RATE_LIMIT_DELAY_MS);

        if (!acessoRes.ok) {
          errors.push({ student_id: student.id, error: `acesso (${identifier}): HTTP ${acessoRes.status}` });
          await markSynced(student.id); // marca mesmo assim: um 404 não vira 200 sozinho, evita loop eterno
          continue;
        }

        const acessoData = acessoRes.data as { data?: { usuario?: CademiUsuarioResumo; acesso?: CademiAcessoItem[] } } | null;
        const acessos = acessoData?.data?.acesso ?? [];
        const cademiUsuarioId = acessoData?.data?.usuario?.id;

        // já que achou o aluno na Cademí, aproveita e grava o ID real — assim
        // da próxima vez essa sincronização (e o webhook, se disparar) já usa
        // o ID direto, sem precisar do e-mail de novo.
        if (cademiUsuarioId !== undefined && cademiUsuarioId !== null && !student.cademi_user_id) {
          await admin.from("students").update({ cademi_user_id: String(cademiUsuarioId) }).eq("id", student.id);
        }
        const progressoIdentifier = cademiUsuarioId !== undefined && cademiUsuarioId !== null ? String(cademiUsuarioId) : identifier;

        let cursosAtualizados = 0;

        for (const item of acessos) {
          // checagem de tempo também DENTRO do loop de cursos — sem isso, um
          // único aluno com muitos cursos (ex: 23) podia sozinho estourar
          // bem além dos 20s, arriscando a função inteira dar timeout.
          if (timeUp()) {
            errors.push({
              student_id: student.id,
              error: `tempo esgotado no meio dos cursos deste aluno — ${cursosAtualizados} de ${acessos.length} processados, continua na próxima`,
            });
            timedOutMidStudent = true;
            break;
          }
          const produtoId = item?.produto?.id;
          const produtoNome = item?.produto?.nome;
          if (produtoId === undefined || produtoId === null) continue;

          // garante que o curso existe (mesmo comportamento do cademi-webhook)
          const { data: course, error: courseErr } = await admin
            .from("courses")
            .upsert(
              { cademi_product_id: String(produtoId), name: produtoNome || `Produto ${produtoId}` },
              { onConflict: "cademi_product_id" },
            )
            .select()
            .single();

          if (courseErr || !course) {
            errors.push({ student_id: student.id, error: `curso ${produtoId}: ${courseErr?.message ?? "falha"}` });
            continue;
          }

          const progressoRes = await cademiGet(
            `/usuario/progresso_por_produto/${encodeURIComponent(progressoIdentifier)}/${encodeURIComponent(String(produtoId))}`,
          );
          await sleep(RATE_LIMIT_DELAY_MS);

          if (!progressoRes.ok) {
            errors.push({ student_id: student.id, error: `progresso ${produtoId}: HTTP ${progressoRes.status}` });
            continue;
          }

          const progressoData = progressoRes.data as { data?: { progresso?: { total?: unknown } } } | null;
          const pct = parsePercent(progressoData?.data?.progresso?.total);

          const { error: progressErr } = await admin.from("course_progress").upsert(
            {
              student_id: student.id,
              course_id: course.id,
              progress_percentage: pct,
              updated_at: new Date().toISOString(),
            },
            { onConflict: "student_id,course_id" },
          );

          if (progressErr) {
            errors.push({ student_id: student.id, error: `salvar progresso ${produtoId}: ${progressErr.message}` });
          } else {
            cursosAtualizados++;
          }
        }

        results.push({ student_id: student.id, produtos_encontrados: acessos.length, cursos_atualizados: cursosAtualizados });

        if (timedOutMidStudent) {
          // não marca como sincronizado — fica pendente pra continuar (ou
          // refazer) esse mesmo aluno assim que a próxima leva rodar.
          stoppedEarlyAt = i;
          break;
        }
        await markSynced(student.id);
      } catch (e) {
        errors.push({ student_id: student.id, error: e instanceof Error ? e.message : String(e) });
        await markSynced(student.id); // erro pontual não deve travar a fila pra sempre
      }
    }
  } catch (fatal) {
    return jsonResponse(
      {
        ok: false,
        error: "Erro fatal na sincronização: " + (fatal instanceof Error ? fatal.message : String(fatal)),
        processed_before_fatal: stoppedEarlyAt < studentList.length ? stoppedEarlyAt : results.length,
      },
      500,
    );
  }

  // só é "done" se essa leva já veio menor que o limite pedido (ou seja, não
  // tinha mais ninguém pra pegar) E não parou no meio por causa do tempo.
  const done = stoppedEarlyAt === studentList.length && studentList.length < limit;

  return jsonResponse(
    {
      ok: true,
      processed: stoppedEarlyAt,
      done,
      results,
      errors,
    },
    200,
  );
});
