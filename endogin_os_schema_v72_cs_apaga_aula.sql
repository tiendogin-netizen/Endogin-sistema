-- v72: a CS pode apagar a aula que ela criou.
--
-- Até agora só master apagava (v26). Mas quem monta a semana é a CS, e
-- errar o dia ou o horário é comum — sem poder apagar, ela ficava com aula
-- errada no Portal do aluno até a Thaís resolver.
--
-- A tela já pergunta o nome da aula antes de apagar, e aula apagada some do
-- Portal na hora, então a confirmação não é decorativa.

drop policy if exists lessons_delete_staff on lessons;
create policy lessons_delete_staff on lessons
  for delete to authenticated
  using (current_staff_id() is not null);

notify pgrst, 'reload schema';

select 'CS pode apagar aula' as ok;
