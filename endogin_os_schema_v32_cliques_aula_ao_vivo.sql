-- v32: contar quantos alunos clicaram no botão "Assistir/entrar" de cada
-- aula ao vivo (semanal/evento) no Portal do Aluno.
--
-- Isso NÃO é presença confirmada pelo Zoom (aquilo é o que a tabela
-- `live_attendance`, do v31, vai guardar quando a integração com a API do
-- Zoom existir) — é só "quantos clicaram no link pra entrar", medido
-- direto pela nossa própria plataforma, sem precisar de nenhuma API
-- externa. Já dá um número útil de engajamento hoje.

create table if not exists live_click_log (
  id uuid primary key default gen_random_uuid(),
  lesson_id uuid references lessons(id) not null,
  student_id uuid references students(id) not null,
  clicked_at timestamptz not null default now()
);

create index if not exists idx_live_click_lesson on live_click_log(lesson_id);
create index if not exists idx_live_click_student on live_click_log(student_id);

alter table live_click_log enable row level security;

-- aluno só registra o próprio clique
create policy live_click_insert_own on live_click_log
  for insert to authenticated
  with check (
    student_id in (select id from students where auth_user_id = auth.uid())
  );

-- equipe (qualquer staff) enxerga tudo, pra montar a contagem
create policy live_click_select_staff on live_click_log
  for select to authenticated
  using (exists (select 1 from staff where staff.auth_user_id = auth.uid()));

notify pgrst, 'reload schema';
