// ============================================================================
// ENDOGIN OS — Edge Function: recebe os webhooks da Cademi
//
// Trata dois eventos (cadastre os dois na Cademi apontando pra essa mesma
// URL — Webhooks → "+ Novo Webhook" → escolher o evento):
//   - "usuario.criado"     → aluno novo, distribui pro CS com menos gente
//                            (se a distribuição automática estiver ligada),
//                            gera login mágico e (se configurado) manda e-mail
//   - "entrega.adicionada" → aluno ganhou acesso a um braço/produto,
//                            registra no histórico de entregas
//
// Formato real confirmado na documentação da Cademi (Configurações → API →
// Webhooks): os dados vêm dentro de `event.usuario` e, quando aplicável,
// `event.entrega` — não soltos na raiz do corpo como eu tinha assumido antes.
//
// ATENÇÃO: até onde a documentação mostra, não existe um evento de "entrega
// removida" — então esta função só sabe quando um aluno GANHA acesso a um
// braço, não quando perde. Enquanto isso não existir, a saída de um braço
// precisa ser registrada manualmente na Área CS.
// ============================================================================

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const WEBHOOK_SECRET = Deno.env.get("CADEMI_WEBHOOK_SECRET") ?? "";
const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
const RESEND_API_KEY = Deno.env.get("RESEND_API_KEY") ?? "";
const PORTAL_BASE_URL = Deno.env.get("PORTAL_BASE_URL") ?? "https://app.mentoriaendogin.com.br";

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

type CademiUsuario = {
  id: number | string;
  nome: string;
  email: string;
  doc?: string | null;
  celular?: string | null;
  login_auto?: string | null;
  criado_em?: string | null;
  ultimo_acesso_em?: string | null;
};

type CademiEntrega = {
  id: number | string;
  nome: string;
  engine?: string;
  engine_id?: string;
};

type CademiWebhookPayload = {
  event_id?: string;
  event_type?: string;
  event?: {
    usuario?: CademiUsuario;
    entrega?: CademiEntrega;
  } | string; // string quando é o formato "V2" (ex: "user.progress")
  version?: string;
  payload?: {
    user?: {
      id: number | string;
      name: string;
      email: string;
      document?: string | null;
      phone?: string | null;
    };
    product?: {
      id: number | string;
      name: string;
    };
    progress_percentage?: number;
  };
};

// A Cademi manda pelo menos dois "formatos de envelope" diferentes conforme
// a versão do webhook escolhida na hora de cadastrar (confirmado direto com
// um payload real entregue por ela, não documentação):
//   - V1 (usuario.criado / entrega.adicionada): { event_type, event: { usuario, entrega } }
//   - V2 (user.progress):                       { version: "2", event: "user.progress", payload: { user, product, progress_percentage } }
function mapV2UserToUsuario(u: NonNullable<CademiWebhookPayload["payload"]>["user"]): CademiUsuario {
  return {
    id: u!.id,
    nome: u!.name,
    email: u!.email,
    doc: u!.document ?? null,
    celular: u!.phone ?? null,
  };
}

function randomToken(): string {
  const bytes = new Uint8Array(24);
  crypto.getRandomValues(bytes);
  return Array.from(bytes, (b) => b.toString(16).padStart(2, "0")).join("");
}

// A Thais (dona da CS) pode ligar/desligar a distribuição automática pela
// tabela `app_settings` — desligada, alunos novos entram sem CS e ela
// atribui à mão pela Área CS.
async function autoDistributionEnabled(): Promise<boolean> {
  const { data } = await supabase
    .from("app_settings")
    .select("auto_distribution_enabled")
    .eq("id", true)
    .maybeSingle();
  // se a linha de config não existir ainda por algum motivo, assume ligado
  // (comportamento anterior, mais seguro do que travar tudo)
  return data ? Boolean(data.auto_distribution_enabled) : true;
}

async function assignLeastLoadedCs(): Promise<string | null> {
  if (!(await autoDistributionEnabled())) return null;

  const { data, error } = await supabase
    .from("cs_load")
    .select("cs_id, active_students")
    .order("active_students", { ascending: true });

  if (error || !data || data.length === 0) return null;

  // `cs_load` lista TODA a staff com a contagem — inclusive quem ja saiu do
  // time. Como ela vem ordenada por menor carga, a primeira da fila e
  // justamente a CS inativa (zero alunos), e todo aluno novo cairia na conta
  // de alguem que nao trabalha mais aqui. Na pratica some da vista da equipe
  // igual a ficar sem CS nenhuma. Por isso a escolha e feita entre as ativas.
  const { data: ativas } = await supabase
    .from("staff")
    .select("id")
    .eq("role", "cs")
    .eq("is_active", true);

  const permitidas = new Set((ativas ?? []).map((row) => row.id as string));
  const escolhida = data.find((row) => permitidas.has(row.cs_id as string));
  return escolhida ? (escolhida.cs_id as string) : null;
}

// Tenta casar o texto cru da entrega (ex: "Mentoria Endogin Start - SCALE")
// com um braço já cadastrado em `branches`, por aproximação de texto. Se não
// achar, devolve null — a CS classifica manualmente depois na tela dela.
async function matchBranch(entregaNome: string): Promise<string | null> {
  const { data } = await supabase.from("branches").select("id, name, slug");
  if (!data) return null;
  const lower = entregaNome.toLowerCase();
  const found = data.find(
    (b) => lower.includes(String(b.name).toLowerCase()) || lower.includes(String(b.slug).toLowerCase()),
  );
  return found ? (found.id as string) : null;
}

async function upsertStudent(usuario: CademiUsuario) {
  const { data: existing } = await supabase
    .from("students")
    .select("id, cs_id")
    .eq("cademi_user_id", String(usuario.id))
    .maybeSingle();

  const isNew = !existing;
  const csId = isNew ? await assignLeastLoadedCs() : existing.cs_id;

  const { data: student, error } = await supabase
    .from("students")
    .upsert(
      {
        cademi_user_id: String(usuario.id),
        full_name: usuario.nome || "Aluno(a) Endogin",
        email: usuario.email,
        phone: usuario.celular ?? null,
        cs_id: csId,
        source: "cademi_webhook",
        raw_webhook_payload: usuario,
      },
      { onConflict: "cademi_user_id" },
    )
    .select()
    .single();

  return { student, error, isNew };
}

async function recordDelivery(studentId: string, entrega: CademiEntrega, rawPayload: unknown) {
  const branchId = await matchBranch(entrega.nome);
  await supabase.from("deliveries").insert({
    student_id: studentId,
    cademi_delivery_id: String(entrega.id),
    branch_id: branchId,
    label: entrega.nome,
    status: "ativo",
    source: "cademi_webhook",
    raw_payload: rawPayload,
  });
}

async function sendWelcomeEmail(toEmail: string, name: string, magicLink: string) {
  if (!RESEND_API_KEY) {
    // Sem chave da Resend configurada ainda — registra como pendente pra
    // alguém do time enviar manualmente (WhatsApp, por exemplo) até a
    // Mentoria Endogin decidir/configurar um provedor de e-mail.
    return { sent: false, reason: "RESEND_API_KEY não configurada" };
  }

  const res = await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${RESEND_API_KEY}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      from: "Mentoria Endogin <acesso@mentoriaendogin.com.br>",
      to: [toEmail],
      subject: "Seu acesso à área de alunos Endogin",
      html:
        `<p>Olá, ${name}!</p>` +
        `<p>Seu acesso à área de alunos da Mentoria Endogin já está liberado.</p>` +
        `<p><a href="${magicLink}">Clique aqui para entrar</a> — o link é pessoal e expira em 48 horas.</p>`,
    }),
  });

  return { sent: res.ok, reason: res.ok ? null : await res.text() };
}

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") {
    return new Response("Método não permitido", { status: 405 });
  }

  // ---- confere o segredo que vem na própria URL ----
  const url = new URL(req.url);
  const secretFromUrl = url.pathname.split("/").pop();
  if (!WEBHOOK_SECRET || secretFromUrl !== WEBHOOK_SECRET) {
    return new Response("Não autorizado", { status: 401 });
  }

  let payload: CademiWebhookPayload;
  try {
    payload = await req.json();
  } catch {
    return new Response("JSON inválido", { status: 400 });
  }

  // ---- formato V2 (progresso de curso — "user.progress") ----
  // Diferente dos outros dois eventos: aqui "event" é o NOME do evento
  // (string), não um objeto, e os dados vêm em "payload", não em "event".
  // progress_percentage é o progresso NO PRODUTO/CURSO inteiro (ex: 10.93%
  // de "Aulas Endogin"), não de uma aula/vídeo específico — por isso vai
  // pra uma tabela própria (course_progress), não pra lesson_progress.
  if (typeof payload.event === "string" && payload.event === "user.progress") {
    const vUser = payload.payload?.user;
    const vProduct = payload.payload?.product;
    const progressPct = payload.payload?.progress_percentage;

    if (!vUser?.email || !vUser?.id || !vProduct?.id) {
      return new Response(
        JSON.stringify({ ok: false, error: "Payload de progresso incompleto", payload }),
        { status: 422, headers: { "Content-Type": "application/json" } },
      );
    }

    const { student, error: upsertError } = await upsertStudent(mapV2UserToUsuario(vUser));
    if (upsertError || !student) {
      return new Response(
        JSON.stringify({ ok: false, error: upsertError?.message ?? "Falha ao salvar aluno" }),
        { status: 500, headers: { "Content-Type": "application/json" } },
      );
    }

    // garante que o curso existe (cria se for a primeira vez que a gente
    // ouve falar desse produto) sem sobrescrever campos que a CS já tenha
    // ajustado manualmente (branch_id, por exemplo) — só toca no que veio
    // no payload.
    const { data: course, error: courseErr } = await supabase
      .from("courses")
      .upsert(
        { cademi_product_id: String(vProduct.id), name: vProduct.name || `Produto ${vProduct.id}` },
        { onConflict: "cademi_product_id" },
      )
      .select()
      .single();

    if (courseErr || !course) {
      return new Response(
        JSON.stringify({ ok: false, error: courseErr?.message ?? "Falha ao salvar curso" }),
        { status: 500, headers: { "Content-Type": "application/json" } },
      );
    }

    const { error: progressErr } = await supabase.from("course_progress").upsert(
      {
        student_id: student.id,
        course_id: course.id,
        progress_percentage: progressPct ?? 0,
        updated_at: new Date().toISOString(),
      },
      { onConflict: "student_id,course_id" },
    );

    return new Response(
      JSON.stringify({
        ok: !progressErr,
        error: progressErr?.message ?? null,
        event: "user.progress",
        student_id: student.id,
        course_id: course.id,
        progress_percentage: progressPct,
      }),
      { status: progressErr ? 500 : 200, headers: { "Content-Type": "application/json" } },
    );
  }

  // ---- formato V1 (usuario.criado / entrega.adicionada) ----
  const eventType = payload.event_type ?? "";
  const eventObj = typeof payload.event === "object" ? payload.event : undefined;
  const usuario = eventObj?.usuario;

  if (!usuario || !usuario.email || !usuario.id) {
    return new Response(
      JSON.stringify({ ok: false, error: "Payload sem event.usuario válido", payload }),
      { status: 422, headers: { "Content-Type": "application/json" } },
    );
  }

  // ---- cria/atualiza o aluno (funciona pra qualquer evento que traga
  // event.usuario — assim, mesmo que a gente perca o "usuario.criado" por
  // algum motivo, um "entrega.adicionada" já recria o aluno certinho) ----
  const { student, error: upsertError, isNew } = await upsertStudent(usuario);

  if (upsertError || !student) {
    return new Response(
      JSON.stringify({ ok: false, error: upsertError?.message ?? "Falha ao salvar aluno" }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }

  // ---- se for evento de entrega, registra no histórico de braços ----
  let deliveryRecorded = false;
  if (eventType === "entrega.adicionada" && eventObj?.entrega) {
    await recordDelivery(student.id, eventObj.entrega, payload);
    deliveryRecorded = true;
  }

  // ---- só gera login mágico e manda e-mail de boas-vindas quando o aluno
  // é realmente novo (evita reenviar o link toda vez que ele ganha uma
  // entrega nova depois de já estar cadastrado) ----
  let emailResult: { sent: boolean; reason: string | null } = {
    sent: false,
    reason: "não aplicável (aluno já existia)",
  };

  if (isNew) {
    const token = randomToken();
    const expiresAt = new Date(Date.now() + 48 * 60 * 60 * 1000).toISOString();

    const { error: tokenErr } = await supabase.from("login_tokens").insert({
      student_id: student.id,
      token,
      expires_at: expiresAt,
    });
    // Sem esta checagem o token podia falhar em silencio e o aluno ficava sem
    // nenhum link de acesso, sem ninguem ficar sabendo.
    if (tokenErr) {
      await supabase.from("notifications").insert({
        student_id: student.id,
        channel: "email",
        category: "onboarding",
        message: "Falha ao gerar o link de acesso deste aluno: " + tokenErr.message,
        status: "pendente",
      });
    }

    const magicLink = `${PORTAL_BASE_URL}/entrar?token=${token}`;
    emailResult = await sendWelcomeEmail(usuario.email, usuario.nome, magicLink);

    if (!emailResult.sent) {
      await supabase.from("notifications").insert({
        student_id: student.id,
        channel: "email",
        category: "onboarding",
        message: `Enviar manualmente o link de acesso: ${magicLink}`,
        status: "pendente",
      });
    }
  }

  return new Response(
    JSON.stringify({
      ok: true,
      event_type: eventType,
      student_id: student.id,
      is_new_student: isNew,
      delivery_recorded: deliveryRecorded,
      email_sent: emailResult.sent,
    }),
    { status: 200, headers: { "Content-Type": "application/json" } },
  );
});
