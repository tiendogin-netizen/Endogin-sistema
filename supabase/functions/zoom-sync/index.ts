// ============================================================================
// ENDOGIN OS — Edge Function: presença nas aulas ao vivo (API do Zoom)
//
// Pra cada aula do Calendário com "ID da reunião no Zoom":
//   1. lista as ocorrências passadas dessa reunião (aula semanal = várias)
//   2. pra cada ocorrência ainda não gravada, baixa o relatório de participantes
//   3. casa cada participante com um aluno (e-mail; senão nome normalizado)
//   4. grava o resumo em live_attendance e os participantes em
//      live_attendance_students
//
// Credenciais: app "Server-to-Server OAuth" no Zoom Marketplace com os
// escopos report:read:admin e meeting:read:admin. Guardadas como segredos:
//   ZOOM_ACCOUNT_ID, ZOOM_CLIENT_ID, ZOOM_CLIENT_SECRET
//
// Quem pode chamar: um membro da equipe logado (JWT no Authorization) ou o
// agendador, com o cabeçalho x-sync-secret = ZOOM_SYNC_SECRET.
// ============================================================================

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
const ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
const ZOOM_ACCOUNT_ID = Deno.env.get("ZOOM_ACCOUNT_ID") ?? "";
const ZOOM_CLIENT_ID = Deno.env.get("ZOOM_CLIENT_ID") ?? "";
const ZOOM_CLIENT_SECRET = Deno.env.get("ZOOM_CLIENT_SECRET") ?? "";
const SYNC_SECRET = Deno.env.get("ZOOM_SYNC_SECRET") ?? "";

const admin = createClient(SUPABASE_URL, SERVICE_KEY);

function json(status: number, body: unknown) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*", "Access-Control-Allow-Headers": "authorization, content-type, x-sync-secret" },
  });
}

function norm(s: string): string {
  return (s || "").normalize("NFD").replace(/[̀-ͯ]/g, "").toLowerCase().replace(/[^a-z0-9 ]/g, " ").replace(/\s+/g, " ").trim();
}

// ---------- Zoom ----------
async function zoomToken(): Promise<string> {
  const basic = btoa(`${ZOOM_CLIENT_ID}:${ZOOM_CLIENT_SECRET}`);
  const r = await fetch(`https://zoom.us/oauth/token?grant_type=account_credentials&account_id=${encodeURIComponent(ZOOM_ACCOUNT_ID)}`, {
    method: "POST",
    headers: { Authorization: `Basic ${basic}` },
  });
  if (!r.ok) throw new Error(`Zoom não deu token (${r.status}): ${await r.text()}`);
  const j = await r.json();
  return j.access_token as string;
}

async function zoomGet(token: string, path: string): Promise<any> {
  const r = await fetch(`https://api.zoom.us/v2${path}`, { headers: { Authorization: `Bearer ${token}` } });
  if (r.status === 404) return null;
  if (!r.ok) throw new Error(`Zoom ${path} (${r.status}): ${await r.text()}`);
  return await r.json();
}

// uuid de ocorrência pode ter "/" e "//": tem que ir duplamente codificado
function encUuid(u: string): string {
  return encodeURIComponent(encodeURIComponent(u));
}

type Participante = { name: string; user_email: string; join_time: string; leave_time: string; duration: number };

async function participantes(token: string, uuid: string): Promise<Participante[]> {
  const todos: Participante[] = [];
  let next = "";
  do {
    const q = `?page_size=300${next ? `&next_page_token=${next}` : ""}`;
    const j = await zoomGet(token, `/report/meetings/${encUuid(uuid)}/participants${q}`);
    if (!j) break;
    (j.participants ?? []).forEach((p: any) => todos.push({
      name: p.name ?? "", user_email: p.user_email ?? "", join_time: p.join_time, leave_time: p.leave_time, duration: p.duration ?? 0,
    }));
    next = j.next_page_token ?? "";
  } while (next);
  return todos;
}

// ---------- autorização ----------
async function podeChamar(req: Request): Promise<boolean> {
  if (SYNC_SECRET && req.headers.get("x-sync-secret") === SYNC_SECRET) return true;
  const auth = req.headers.get("Authorization") ?? "";
  if (!auth.startsWith("Bearer ")) return false;
  const asUser = createClient(SUPABASE_URL, ANON_KEY, { global: { headers: { Authorization: auth } } });
  const { data: u } = await asUser.auth.getUser();
  if (!u?.user) return false;
  const { data: st } = await admin.from("staff").select("id,is_active").eq("auth_user_id", u.user.id).maybeSingle();
  return !!(st && st.is_active);
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return json(200, { ok: true });
  if (!(await podeChamar(req))) return json(401, { ok: false, error: "não autorizado" });
  if (!ZOOM_ACCOUNT_ID || !ZOOM_CLIENT_ID || !ZOOM_CLIENT_SECRET) {
    return json(500, { ok: false, error: "Credenciais do Zoom ainda não configuradas (ZOOM_ACCOUNT_ID / CLIENT_ID / CLIENT_SECRET)." });
  }

  const inicio = Date.now();
  const log: string[] = [];
  let token: string;
  try { token = await zoomToken(); } catch (e) { return json(500, { ok: false, error: String((e as Error).message) }); }

  // alunos pra casar
  const { data: alunos, error: eA } = await admin.from("students").select("id,full_name,email");
  if (eA) return json(500, { ok: false, error: eA.message });
  const porEmail = new Map<string, string>();
  const porNome = new Map<string, string>();
  (alunos ?? []).forEach((a) => {
    if (a.email) porEmail.set(a.email.trim().toLowerCase(), a.id);
    const n = norm(a.full_name);
    if (n) porNome.set(n, a.id);
  });
  function casa(p: Participante): { id: string | null; por: string | null } {
    const e = (p.user_email || "").trim().toLowerCase();
    if (e && porEmail.has(e)) return { id: porEmail.get(e)!, por: "email" };
    const n = norm(p.name);
    if (n && porNome.has(n)) return { id: porNome.get(n)!, por: "nome" };
    // primeiro + último nome (participante costuma entrar só com parte do nome)
    const partes = n.split(" ").filter((x) => x.length > 2);
    if (partes.length >= 2) {
      const chave = partes[0] + " " + partes[partes.length - 1];
      for (const [nome, id] of porNome) {
        const pn = nome.split(" ").filter((x) => x.length > 2);
        if (pn.length >= 2 && pn[0] + " " + pn[pn.length - 1] === chave) return { id, por: "nome" };
      }
    }
    return { id: null, por: null };
  }

  // aulas com reunião
  const { data: aulas, error: eL } = await admin.from("lessons").select("id,title,zoom_meeting_id").not("zoom_meeting_id", "is", null);
  if (eL) return json(500, { ok: false, error: eL.message });

  // o que já foi gravado
  const { data: jaTem } = await admin.from("live_attendance").select("lesson_id,occurred_at");
  const gravadas = new Set((jaTem ?? []).map((r) => `${r.lesson_id}|${r.occurred_at}`));

  let ocorrenciasNovas = 0, participantesGravados = 0, semPar = 0;

  for (const aula of aulas ?? []) {
    const meetingId = String(aula.zoom_meeting_id).replace(/\D/g, "");
    if (!meetingId) continue;
    let inst: any;
    try {
      inst = await zoomGet(token, `/past_meetings/${meetingId}/instances`);
    } catch (e) {
      log.push(`${aula.title}: ${(e as Error).message}`);
      continue;
    }
    const meetings: { uuid: string; start_time: string }[] = inst?.meetings ?? [];
    for (const m of meetings) {
      const dia = String(m.start_time).slice(0, 10);
      const chave = `${aula.id}|${dia}`;
      if (gravadas.has(chave)) continue;
      let lista: Participante[];
      try { lista = await participantes(token, m.uuid); } catch (e) { log.push(`${aula.title} ${dia}: ${(e as Error).message}`); continue; }

      // mesma pessoa entra e sai várias vezes: soma por nome+e-mail
      const agrupado = new Map<string, Participante & { total: number }>();
      lista.forEach((p) => {
        const k = `${norm(p.name)}|${(p.user_email || "").toLowerCase()}`;
        const g = agrupado.get(k);
        if (g) {
          g.total += p.duration || 0;
          if (p.join_time < g.join_time) g.join_time = p.join_time;
          if (p.leave_time > g.leave_time) g.leave_time = p.leave_time;
        } else agrupado.set(k, { ...p, total: p.duration || 0 });
      });

      const linhas = [...agrupado.values()].map((p) => {
        const c = casa(p);
        if (!c.id) semPar++;
        return {
          lesson_id: aula.id, occurred_at: dia, zoom_uuid: m.uuid,
          student_id: c.id, matched_by: c.por,
          participant_name: p.name || "(sem nome)", participant_email: p.user_email || "",
          join_time: p.join_time || null, leave_time: p.leave_time || null,
          duration_min: Math.round((p.total || 0) / 60),
        };
      });
      const casados = linhas.filter((l) => l.student_id).length;

      const { error: e1 } = await admin.from("live_attendance").upsert({
        lesson_id: aula.id, occurred_at: dia, attendee_count: linhas.length, matched_student_count: casados,
        raw_report: { uuid: m.uuid, start_time: m.start_time, participantes: lista.length }, synced_at: new Date().toISOString(),
      }, { onConflict: "lesson_id,occurred_at" });
      if (e1) { log.push(`${aula.title} ${dia}: ${e1.message}`); continue; }
      if (linhas.length) {
        const { error: e2 } = await admin.from("live_attendance_students").upsert(linhas, { onConflict: "lesson_id,occurred_at,participant_name,participant_email" });
        if (e2) { log.push(`${aula.title} ${dia}: ${e2.message}`); continue; }
      }
      gravadas.add(chave);
      ocorrenciasNovas++;
      participantesGravados += linhas.length;
    }
  }

  await admin.from("app_settings_kv").upsert({
    key: "zoom_last_sync",
    value: { em: new Date().toISOString(), ocorrencias_novas: ocorrenciasNovas, participantes: participantesGravados, sem_par: semPar, avisos: log.slice(0, 20) },
    updated_at: new Date().toISOString(),
  });

  return json(200, {
    ok: true, aulas_com_zoom: (aulas ?? []).length, ocorrencias_novas: ocorrenciasNovas,
    participantes: participantesGravados, sem_par: semPar, avisos: log, ms: Date.now() - inicio,
  });
});
