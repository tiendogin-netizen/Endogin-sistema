// ============================================================================
// ENDOGIN OS — Edge Function: puxa o CATÁLOGO de aulas da Cademi
// (produtos + aulas de cada produto) pra tabela courses / course_lessons.
//
// É o que o chat "Buscar aula" da Área CS usa. Antes o catálogo era carregado
// uma vez na mão e ficou parado — aula nova na Cademi não aparecia no chat.
//
// API (ajuda.cademi.com.br/configuracoes/api):
//   GET /produto                          -> lista de produtos (paginada, 15/pág)
//   GET /item/lista_por_produto/{id}      -> aulas do produto (paginada)
// Limite: 2 chamadas/segundo. Por isso cada invocação processa um lote de
// produtos e devolve quantos faltam; a tela chama de novo até zerar.
// Checkpoint: courses.catalog_synced_at (v59). { force:true } refaz tudo.
// ============================================================================

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
const ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
const BASE = (Deno.env.get("CADEMI_API_BASE_URL") ?? "").replace(/\/$/, "");
const KEY = Deno.env.get("CADEMI_API_KEY") ?? "";
const admin = createClient(SUPABASE_URL, SERVICE_KEY);

const LOTE = 20;            // produtos por chamada
const PAUSA_MS = 600;       // respeita 2 req/s
const TEMPO_MAX_MS = 40000; // devolve antes do limite da função

function json(status: number, body: unknown) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*", "Access-Control-Allow-Headers": "authorization, content-type" },
  });
}
const dormir = (ms: number) => new Promise((r) => setTimeout(r, ms));

async function ehStaff(req: Request): Promise<boolean> {
  const auth = req.headers.get("Authorization") ?? "";
  if (!auth.startsWith("Bearer ")) return false;
  const asUser = createClient(SUPABASE_URL, ANON_KEY, { global: { headers: { Authorization: auth } } });
  const { data: u } = await asUser.auth.getUser();
  if (!u?.user) return false;
  const { data: st } = await admin.from("staff").select("id").eq("auth_user_id", u.user.id).maybeSingle();
  return !!st;
}

async function cademi(pathOrUrl: string): Promise<any> {
  const url = pathOrUrl.startsWith("http") ? pathOrUrl : `${BASE}${pathOrUrl}`;
  const r = await fetch(url, { headers: { Authorization: KEY } });
  const body = await r.json().catch(() => null);
  if (!r.ok || !body?.success) throw new Error(`Cademi ${pathOrUrl} → ${r.status}: ${JSON.stringify(body?.msg ?? body).slice(0, 200)}`);
  return body.data;
}

// pagina até acabar; a Cademi manda next_page_url completo
async function todasAsPaginas(path: string, chave: string): Promise<any[]> {
  const itens: any[] = [];
  let prox: string | null = path;
  let guarda = 0;
  while (prox && guarda++ < 50) {
    const data = await cademi(prox);
    const lista = data?.[chave] ?? (Array.isArray(data) ? data : []);
    itens.push(...lista);
    prox = data?.paginator?.next_page_url ?? null;
    if (prox) await dormir(PAUSA_MS);
  }
  return itens;
}

function str(v: unknown): string | null {
  if (v === null || v === undefined) return null;
  const s = String(v).trim();
  return s ? s : null;
}
function pega(o: any, ...ks: string[]): unknown {
  for (const k of ks) {
    const v = k.split(".").reduce((a, p) => (a && a[p] !== undefined ? a[p] : undefined), o);
    if (v !== undefined && v !== null && v !== "") return v;
  }
  return undefined;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return json(200, { ok: true });
  if (!(await ehStaff(req))) return json(401, { ok: false, error: "não autorizado" });
  if (!BASE || !KEY) return json(500, { ok: false, error: "CADEMI_API_BASE_URL / CADEMI_API_KEY não configurados." });

  let body: { force?: boolean } = {};
  try { body = await req.json(); } catch { /* corpo vazio */ }
  const inicio = Date.now();
  const avisos: string[] = [];
  let exemploItem: unknown = null;

  // 1) produtos
  let produtos: any[];
  try { produtos = await todasAsPaginas("/produto", "produto"); } catch (e) { return json(500, { ok: false, error: (e as Error).message }); }

  // garante que todo produto existe em courses
  for (const p of produtos) {
    await admin.from("courses").upsert({ cademi_product_id: String(p.id), name: p.nome || `Produto ${p.id}` }, { onConflict: "cademi_product_id" });
  }

  // 2) quais faltam sincronizar
  const { data: cursos } = await admin.from("courses").select("id,cademi_product_id,name,catalog_synced_at").not("cademi_product_id", "is", null);
  const idsCademi = new Set(produtos.map((p) => String(p.id)));
  let fila = (cursos ?? []).filter((c) => idsCademi.has(String(c.cademi_product_id)));
  if (!body.force) fila = fila.filter((c) => !c.catalog_synced_at);
  fila.sort((a, b) => String(a.catalog_synced_at ?? "").localeCompare(String(b.catalog_synced_at ?? "")));
  const restantesAntes = fila.length;

  let feitos = 0, aulasGravadas = 0;
  for (const c of fila.slice(0, LOTE)) {
    if (Date.now() - inicio > TEMPO_MAX_MS) break;
    await dormir(PAUSA_MS);
    let itens: any[];
    try {
      const data = await cademi(`/item/lista_por_produto/${encodeURIComponent(String(c.cademi_product_id))}`);
      // a chave da lista varia; pega a primeira propriedade que seja array
      const k = Object.keys(data ?? {}).find((x) => Array.isArray((data as any)[x]));
      itens = k ? (data as any)[k] : [];
      let prox = data?.paginator?.next_page_url ?? null, g = 0;
      while (prox && g++ < 30) {
        await dormir(PAUSA_MS);
        const d2 = await cademi(prox);
        const k2 = Object.keys(d2 ?? {}).find((x) => Array.isArray((d2 as any)[x]));
        if (k2) itens.push(...(d2 as any)[k2]);
        prox = d2?.paginator?.next_page_url ?? null;
      }
    } catch (e) {
      avisos.push(`${c.name}: ${(e as Error).message}`);
      continue;
    }
    if (!exemploItem && itens.length) exemploItem = itens[0];

    const { data: existentes } = await admin.from("course_lessons").select("id,cademi_lesson_id").eq("course_id", c.id);
    const porCademi = new Map((existentes ?? []).filter((e) => e.cademi_lesson_id).map((e) => [String(e.cademi_lesson_id), e.id]));

    let ordem = 0;
    for (const it of itens) {
      ordem++;
      const idItem = str(pega(it, "id"));
      const titulo = str(pega(it, "nome", "titulo", "title", "name")) ?? `Aula ${idItem ?? ordem}`;
      const modulo = str(pega(it, "modulo.nome", "modulo", "secao.nome", "secao", "categoria.nome", "pasta.nome"));
      const url = str(pega(it, "url", "link")) ?? (idItem ? `https://membros.mentoriaendogin.com.br/area/conteudo/aula/${idItem}` : null);
      const duracao = str(pega(it, "duracao", "duration", "tempo"));
      const linha = { course_id: c.id, cademi_lesson_id: idItem, title: titulo, module: modulo, url, duration: duracao };
      if (idItem && porCademi.has(idItem)) {
        await admin.from("course_lessons").update(linha).eq("id", porCademi.get(idItem)!);
      } else {
        const { error } = await admin.from("course_lessons").insert(linha);
        if (error) { avisos.push(`${c.name} / ${titulo}: ${error.message}`); continue; }
      }
      aulasGravadas++;
    }
    await admin.from("courses").update({ catalog_synced_at: new Date().toISOString() }).eq("id", c.id);
    feitos++;
  }

  return json(200, {
    ok: true, produtos_na_cademi: produtos.length, processados: feitos, aulas_gravadas: aulasGravadas,
    restantes: Math.max(0, restantesAntes - feitos), avisos: avisos.slice(0, 20), exemplo_item: exemploItem, ms: Date.now() - inicio,
  });
});
