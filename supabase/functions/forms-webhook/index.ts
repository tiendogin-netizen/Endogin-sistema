// ============================================================================
// ENDOGIN OS — Edge Function: recebe respostas do Google Forms
//
// Um script dentro do próprio formulário (Apps Script) chama esta URL a cada
// resposta enviada, e também uma vez pra mandar o que já tinha chegado.
//
// Corpo esperado:
//   { "event_key": "mentalidade-2026-10-17",
//     "responses": [ { "response_id": "...", "submitted_at": "...", "email": "...",
//                      "answers": { "<pergunta>": "<resposta>", ... } } ] }
//
// Cabeçalho obrigatório: x-forms-secret = FORMS_WEBHOOK_SECRET (segredo do
// projeto; o mesmo vai colado no script do formulário).
//
// As perguntas são casadas por palavra-chave (nome, credencial, contato,
// participar, cônjuge, restrição, necessidade) — o texto exato da pergunta
// pode mudar sem quebrar. O que não for reconhecido fica em `raw`.
// ============================================================================

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SECRET = Deno.env.get("FORMS_WEBHOOK_SECRET") ?? "";
const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
const supabase = createClient(SUPABASE_URL, SERVICE_KEY);

type Resposta = {
  response_id: string;
  submitted_at?: string | null;
  email?: string | null;
  answers: Record<string, unknown>;
};

function json(status: number, body: unknown) {
  return new Response(JSON.stringify(body), { status, headers: { "Content-Type": "application/json" } });
}

// tira acento e baixa caixa pra comparar perguntas
function norm(s: string): string {
  return s.normalize("NFD").replace(/[̀-ͯ]/g, "").toLowerCase();
}

function texto(v: unknown): string {
  if (v == null) return "";
  if (Array.isArray(v)) return v.map((x) => String(x)).join(", ");
  return String(v).trim();
}

// "Sim" / "Não" / "Não possuo" / "Outro: ..." → true/false/null
function simNao(v: unknown): boolean | null {
  const t = norm(texto(v));
  if (!t) return null;
  if (t.startsWith("sim") || t === "s" || t === "yes") return true;
  if (t.startsWith("nao") || t === "n" || t === "no") return false;
  return null;
}

// restrição/necessidade: "Não" vira vazio; qualquer outra coisa é o texto
function textoOuVazio(v: unknown): string | null {
  const t = texto(v);
  const n = norm(t);
  if (!t || n === "nao" || n === "nao possuo" || n === "nenhuma" || n === "nenhum") return null;
  return t;
}

function acha(answers: Record<string, unknown>, ...chaves: string[]): unknown {
  const entradas = Object.entries(answers);
  for (const chave of chaves) {
    const hit = entradas.find(([pergunta]) => norm(pergunta).includes(chave));
    if (hit) return hit[1];
  }
  return undefined;
}

function mapeia(r: Resposta) {
  const a = r.answers ?? {};
  const emailForm = texto(acha(a, "e-mail", "email"));
  const email = (r.email && r.email.trim()) || emailForm || null;
  return {
    response_id: r.response_id,
    submitted_at: r.submitted_at || null,
    email: email ? email.toLowerCase() : null,
    full_name: texto(acha(a, "nome completo", "nome")) || null,
    badge_name: texto(acha(a, "credencial", "cracha")) || null,
    phone: texto(acha(a, "contato", "telefone", "whatsapp", "celular")) || null,
    attending: simNao(acha(a, "participar", "participara", "presenca", "estara presente")),
    spouse: simNao(acha(a, "conjuge", "acompanhante", "esposa", "esposo")),
    dietary: textoOuVazio(acha(a, "restricao alimentar", "alimentar", "restricao")),
    special_needs: textoOuVazio(acha(a, "necessidade especial", "necessidade", "acessibilidade")),
    raw: a,
  };
}

Deno.serve(async (req) => {
  if (req.method !== "POST") return json(405, { ok: false, error: "use POST" });
  if (!SECRET || req.headers.get("x-forms-secret") !== SECRET) {
    return json(401, { ok: false, error: "segredo inválido" });
  }

  let body: { event_key?: string; responses?: Resposta[] };
  try {
    body = await req.json();
  } catch {
    return json(400, { ok: false, error: "JSON inválido" });
  }
  const eventKey = (body.event_key ?? "").trim();
  const responses = Array.isArray(body.responses) ? body.responses : [];
  if (!eventKey) return json(400, { ok: false, error: "event_key obrigatório" });
  if (!responses.length) return json(200, { ok: true, gravadas: 0 });

  const linhas = responses
    .filter((r) => r && r.response_id)
    .map((r) => ({ event_key: eventKey, ...mapeia(r) }));

  const { error } = await supabase
    .from("event_rsvps")
    .upsert(linhas, { onConflict: "event_key,response_id" });
  if (error) return json(500, { ok: false, error: error.message });

  return json(200, { ok: true, gravadas: linhas.length });
});
