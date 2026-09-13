-- v53 - a diretoria le os resultados do DISC
-- A v42 deu leitura a diretoria em varias tabelas, mas disc_results ficou de
-- fora. Sem isto a aba "Perfil DISC" da Area da Diretoria mostra zero
-- respostas mesmo quando existem.

do $$
begin
  if to_regclass('public.disc_results') is not null then
    execute 'drop policy if exists disc_results_select_diretoria on public.disc_results';
    execute 'create policy disc_results_select_diretoria on public.disc_results
             for select to authenticated using (is_current_staff_diretoria())';
  end if;
end $$;

notify pgrst, 'reload schema';

-- conferencia: quantos alunos ja responderam, no total
select count(distinct student_id) as alunos_com_disc, count(*) as respostas
from disc_results;
