-- v51 - REVERTE a v48 (visibilidade por mentoria)
--
-- A v48 dava a CS acesso a todos os alunos das mentorias em que ela esta
-- marcada como responsavel. Para as Starts e a Surgical, com uma CS cada,
-- era o comportamento certo. Para a Mentoria Mae, com varias CS marcadas,
-- abriu os 212 alunos da Mae para todas elas — e a regra do sistema e que so
-- a master ve tudo; cada CS ve os seus.
--
-- Rodado em 10/09/2026. O arquivo da v48 foi removido do repositorio para
-- nao ser aplicado de novo por engano. Se um dia a visibilidade por mentoria
-- voltar, tem que ser com uma chave por marcacao, desligada por padrao.

drop policy if exists students_select_pela_mentoria on students;
drop policy if exists students_update_pela_mentoria on students;

do $$
declare t text;
begin
  foreach t in array array['deliveries','student_whatsapp_groups','mentoring_sessions','nps_responses',
                           'feedback_entries','course_progress','lesson_progress','live_click_log','disc_results']
  loop
    if to_regclass('public.'||t) is not null then
      execute format('drop policy if exists %I on public.%I', t||'_pela_mentoria', t);
    end if;
  end loop;
end $$;

-- checar_email_aluno volta a considerar "meu" so responsavel e segunda CS
create or replace function public.checar_email_aluno(p_email text)
returns jsonb language plpgsql security definer set search_path = public as $function$
declare v_id uuid; v_cs_id uuid; v_cs2 uuid; v_cs_nome text; v_minha boolean; v_master boolean;
begin
  if not is_current_staff_ativa() then raise exception 'Apenas a equipe ativa pode consultar.'; end if;
  v_master := is_current_staff_master();
  select s.id, s.cs_id, s.cs_id_2, st.full_name into v_id, v_cs_id, v_cs2, v_cs_nome
  from students s left join staff st on st.id = s.cs_id
  where lower(s.email) = lower(trim(p_email)) limit 1;
  if v_id is null then return jsonb_build_object('existe', false); end if;
  v_minha := (v_cs_id = current_staff_id()) or (v_cs2 = current_staff_id());
  return jsonb_build_object('existe', true, 'minha', coalesce(v_minha,false),
    'cs_nome', coalesce(v_cs_nome,'sem CS'),
    'id', case when coalesce(v_minha,false) or v_master then v_id else null end);
end $function$;

drop function if exists public.enxerga_pela_mentoria(uuid);
notify pgrst, 'reload schema';

select policyname, cmd from pg_policies
where schemaname = 'public' and tablename = 'students' order by policyname;
