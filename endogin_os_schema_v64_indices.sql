-- v64: índices para a lista de alunos parar de demorar.
--
-- Por quê: a regra de quem vê quem (RLS) chama `atende_o_aluno()` uma vez
-- POR LINHA, e essa função procura em `deliveries` por student_id + cs_id.
-- Sem índice, cada uma dessas buscas varre a tabela inteira. Com ~490 alunos
-- e ~500 entregas, e mais os dados ligados (mentorias, grupos, DISC), isso
-- vira centenas de milhares de varreduras num carregamento só — era isso que
-- deixava a tela em "Carregando alunos...".
--
-- Criar índice não muda dado nenhum e não tem volta a fazer: é seguro.

create index if not exists deliveries_student_idx      on deliveries (student_id);
create index if not exists deliveries_cs_idx           on deliveries (cs_id);
create index if not exists deliveries_student_cs_idx   on deliveries (student_id, cs_id) where status = 'ativo';
create index if not exists deliveries_branch_idx       on deliveries (branch_id);

create index if not exists students_cs_idx             on students (cs_id);
create index if not exists students_cs2_idx            on students (cs_id_2);
create index if not exists students_auth_idx           on students (auth_user_id);
create index if not exists students_email_lower_idx    on students (lower(email));
create index if not exists students_status_idx         on students (status);

create index if not exists staff_auth_idx              on staff (auth_user_id);

create index if not exists disc_results_student_idx    on disc_results (student_id);
create index if not exists nps_student_idx             on nps_responses (student_id);
create index if not exists lesson_progress_student_idx on lesson_progress (student_id);
create index if not exists swg_student_idx             on student_whatsapp_groups (student_id);
create index if not exists course_progress_student_idx on course_progress (student_id);
create index if not exists mentoring_sessions_student_idx on mentoring_sessions (student_id);
create index if not exists live_click_student_idx      on live_click_log (student_id);
create index if not exists feedback_student_idx        on feedback_entries (student_id);

-- as funções de permissão são chamadas por linha: marcá-las como STABLE deixa
-- o Postgres reaproveitar o resultado dentro da mesma consulta
do $$
begin
  execute 'alter function public.current_staff_id() stable';
exception when others then null;
end $$;
do $$
begin
  execute 'alter function public.is_current_staff_master() stable';
exception when others then null;
end $$;
do $$
begin
  execute 'alter function public.atende_o_aluno(uuid) stable';
exception when others then null;
end $$;
do $$
begin
  execute 'alter function public.is_current_staff_diretoria() stable';
exception when others then null;
end $$;

analyze students;
analyze deliveries;

notify pgrst, 'reload schema';

select 'indices criados' as ok;
