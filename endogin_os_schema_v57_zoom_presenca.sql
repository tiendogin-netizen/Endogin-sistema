-- v57: presença real nas aulas ao vivo (API do Zoom).
--
-- A Edge Function `zoom-sync` puxa do Zoom, pra cada aula do Calendário que
-- tem "ID da reunião", as ocorrências passadas e a lista de participantes,
-- casa cada participante com um aluno (e-mail, senão nome) e grava aqui.
-- live_attendance (v31) guarda o resumo por ocorrência; esta tabela guarda
-- quem esteve, quanto tempo ficou, e quem não deu pra identificar.

create table if not exists live_attendance_students (
  id              uuid primary key default gen_random_uuid(),
  lesson_id       uuid not null references lessons(id) on delete cascade,
  occurred_at     date not null,
  zoom_uuid       text,                       -- uuid da ocorrência no Zoom
  student_id      uuid references students(id) on delete set null,
  participant_name  text,
  participant_email text,
  join_time       timestamptz,
  leave_time      timestamptz,
  duration_min    int,                        -- minutos somados (pode entrar e sair)
  matched_by      text,                       -- 'email' | 'nome' | 'manual' | null
  created_at      timestamptz not null default now(),
  unique (lesson_id, occurred_at, participant_name, participant_email)
);

create index if not exists live_att_students_student_idx on live_attendance_students (student_id);
create index if not exists live_att_students_lesson_idx  on live_attendance_students (lesson_id, occurred_at);

alter table live_attendance_students enable row level security;

drop policy if exists live_att_students_select_staff on live_attendance_students;
create policy live_att_students_select_staff on live_attendance_students
  for select to authenticated using (current_staff_id() is not null or is_current_staff_diretoria());

-- a CS pode ligar na mao um participante que ficou sem aluno
drop policy if exists live_att_students_update_staff on live_attendance_students;
create policy live_att_students_update_staff on live_attendance_students
  for update to authenticated
  using (current_staff_id() is not null) with check (current_staff_id() is not null);

grant select, update on live_attendance_students to authenticated;

-- diretoria tambem le o resumo do v31
drop policy if exists live_attendance_select_diretoria on live_attendance;
create policy live_attendance_select_diretoria on live_attendance
  for select to authenticated using (is_current_staff_diretoria());
grant select on live_attendance to authenticated;

-- quando foi a ultima sincronizacao (a tela mostra)
create table if not exists app_settings_kv (
  key text primary key,
  value jsonb,
  updated_at timestamptz not null default now()
);
alter table app_settings_kv enable row level security;
drop policy if exists app_settings_kv_select_staff on app_settings_kv;
create policy app_settings_kv_select_staff on app_settings_kv
  for select to authenticated using (current_staff_id() is not null or is_current_staff_diretoria());
grant select on app_settings_kv to authenticated;

notify pgrst, 'reload schema';

select 'zoom presenca pronto' as ok;
