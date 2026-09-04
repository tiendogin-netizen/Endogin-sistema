-- v31: preparação pro cálculo de presença nas aulas ao vivo (Zoom).
--
-- Isso é só a parte de dados: guarda o ID/link da reunião Zoom em cada aula
-- semanal/evento cadastrada no Calendário, e uma tabela pra guardar a
-- contagem de presença já calculada (pra CS e pros doutores verem sem
-- precisar recalcular toda hora).
--
-- O CÁLCULO em si (chamar a API do Zoom e cruzar quem participou) ainda não
-- dá pra fazer — falta a credencial da API do Zoom (app Server-to-Server
-- OAuth: Account ID, Client ID e Client Secret). Assim que tiver isso, dá
-- pra preencher `live_attendance` automaticamente.

alter table lessons
  add column if not exists zoom_meeting_id text;

create table if not exists live_attendance (
  id uuid primary key default gen_random_uuid(),
  lesson_id uuid references lessons(id) not null,
  occurred_at date not null,           -- qual dia/ocorrência daquela aula semanal
  attendee_count int not null default 0,
  matched_student_count int not null default 0,  -- quantos participantes a gente
                                                   -- conseguiu casar com um aluno
                                                   -- cadastrado (por e-mail)
  raw_report jsonb,                     -- payload cru do relatório do Zoom
  synced_at timestamptz not null default now(),
  unique (lesson_id, occurred_at)
);

alter table live_attendance enable row level security;

create policy live_attendance_select_staff on live_attendance
  for select to authenticated
  using (exists (select 1 from staff where staff.auth_user_id = auth.uid()));

notify pgrst, 'reload schema';
