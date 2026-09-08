-- v42: acesso da diretoria (Dr. Caio e Dr. Vinícius) — leitura ampla, sem
-- poder de alteração.
--
-- Por que não marcar os dois como master: `is_current_staff_master()` libera
-- SELECT **e** UPDATE em students, além de habilitar na Área CS o botão de
-- excluir login, a troca de senha de aluno e a edição de qualquer ficha. Para
-- uma tela de diretoria isso é poder demais — o que eles precisam é enxergar
-- a base inteira, não mexer nela.
--
-- Então entra uma marca própria (`is_diretoria`) e políticas de SELECT. Quem
-- for só diretoria lê tudo e não escreve nada em students.

alter table staff
  add column if not exists is_diretoria boolean not null default false;

create or replace function public.is_current_staff_diretoria()
returns boolean
language sql
stable
security definer
as $function$
  select coalesce(
    (select is_diretoria and is_active from staff where auth_user_id = auth.uid()),
    false
  );
$function$;

-- students: a diretoria enxerga a base toda, mas só para leitura. As políticas
-- de UPDATE existentes (own_or_master) continuam iguais e não citam diretoria.
drop policy if exists students_select_diretoria on students;
create policy students_select_diretoria on students
  for select to authenticated
  using (is_current_staff_diretoria());

-- deliveries: sem isso a mentoria de cada aluno não aparece nos gráficos.
drop policy if exists deliveries_select_diretoria on deliveries;
create policy deliveries_select_diretoria on deliveries
  for select to authenticated
  using (is_current_staff_diretoria());

-- As demais tabelas só ganham política se existirem — assim esta migration não
-- quebra inteira caso alguma tenha outro nome. Rode e me diga se sobrar aviso.
do $$
begin
  if to_regclass('public.course_progress') is not null then
    execute 'drop policy if exists course_progress_select_diretoria on course_progress';
    execute 'create policy course_progress_select_diretoria on course_progress
             for select to authenticated using (is_current_staff_diretoria())';
  end if;

  if to_regclass('public.nps_responses') is not null then
    execute 'drop policy if exists nps_select_diretoria on nps_responses';
    execute 'create policy nps_select_diretoria on nps_responses
             for select to authenticated using (is_current_staff_diretoria())';
  end if;

  if to_regclass('public.feedback_entries') is not null then
    execute 'drop policy if exists feedback_select_diretoria on feedback_entries';
    execute 'create policy feedback_select_diretoria on feedback_entries
             for select to authenticated using (is_current_staff_diretoria())';
  end if;

  if to_regclass('public.recados') is not null then
    execute 'drop policy if exists recados_select_diretoria on recados';
    execute 'create policy recados_select_diretoria on recados
             for select to authenticated using (is_current_staff_diretoria())';
  end if;

  if to_regclass('public.mentoring_sessions') is not null then
    execute 'drop policy if exists sessions_select_diretoria on mentoring_sessions';
    execute 'create policy sessions_select_diretoria on mentoring_sessions
             for select to authenticated using (is_current_staff_diretoria())';
  end if;
end $$;

notify pgrst, 'reload schema';

-- ---------------------------------------------------------------------------
-- DEPOIS de rodar isto, marque os dois (troque os e-mails pelos reais):
--
--   update staff set is_diretoria = true
--   where email in ('email-do-dr-caio@...', 'email-do-dr-vinicius@...');
--
-- Se eles ainda não têm cadastro em `staff`, crie primeiro pela aba Equipe da
-- Área CS e depois rode o update acima.
-- ---------------------------------------------------------------------------
