-- v55: a equipe lê o DISC de todo aluno que ela enxerga.
--
-- As regras de disc_results liberavam a CS por mentoria (v52), a CS de apoio
-- (v47) e a diretoria (v53) — mas não a master nem a CS principal (cs_id).
-- A aba "Perfil DISC" mostrava 0 respostas mesmo com resultado gravado.
--
-- A regra nova é "se você vê o aluno na aba Alunos, vê o DISC dele": a
-- subconsulta em students roda com a RLS de quem está logado, então ela
-- devolve exatamente os alunos que essa pessoa já pode ver. Master vê todos,
-- CS vê os dela, diretoria vê todos (leitura). Nada além disso.

drop policy if exists disc_results_select_staff on disc_results;
create policy disc_results_select_staff on disc_results
  for select to authenticated
  using (
    current_staff_id() is not null
    and exists (select 1 from students s where s.id = disc_results.student_id)
  );

notify pgrst, 'reload schema';

-- conferência: respostas gravadas (independe de permissão, roda como dono)
select count(*) as respostas, count(distinct student_id) as alunos_com_disc
  from disc_results;
