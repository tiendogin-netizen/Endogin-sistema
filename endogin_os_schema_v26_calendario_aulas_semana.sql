-- v26: "Aulas da semana" / Calendário. A tabela `lessons` (aula semanal /
-- evento) já existia no schema base, mas nunca teve RLS nem tela pra CS
-- cadastrar nada nela — por isso o card "Calendário" do Portal do Aluno
-- sempre aparecia vazio, mesmo a query já estando pronta lá.
--
-- Este arquivo: (1) adiciona uma coluna de data pra "evento" (encontro
-- avulso, ex: live/masterclass numa data específica — "weekday" só serve
-- pra aula semanal fixa), e (2) liga RLS com o mesmo padrão já usado em
-- courses/whatsapp_groups (staff lê tudo, aluno só vê semanal/evento da(s)
-- sua(s) mentoria(s) ou os "pra todas as mentorias", só master escreve).

alter table lessons
  add column if not exists event_date date;

alter table lessons enable row level security;

drop policy if exists lessons_select_staff on lessons;
create policy lessons_select_staff
  on lessons for select
  to authenticated
  using (current_staff_id() is not null);

drop policy if exists lessons_select_student on lessons;
create policy lessons_select_student
  on lessons for select
  to authenticated
  using (
    current_student_id() is not null
    and lesson_type in ('semanal', 'evento')
    and (branch_id is null or branch_id in (
      select branch_id from deliveries
      where student_id = current_student_id() and status = 'ativo'
    ))
  );

drop policy if exists lessons_write on lessons;
create policy lessons_write
  on lessons for all
  to authenticated
  using (is_current_staff_master())
  with check (is_current_staff_master());

notify pgrst, 'reload schema';
