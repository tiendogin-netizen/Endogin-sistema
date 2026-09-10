-- =============================================================================
-- v48 - a CS responsavel por uma mentoria enxerga os alunos dessa mentoria
-- Rode o arquivo inteiro no SQL Editor. Pode rodar mais de uma vez.
-- =============================================================================
--
-- Regra de acesso a partir daqui. Uma CS ve (e edita) um aluno quando:
--   1. ela e a responsavel por ele            (students.cs_id)
--   2. ela e a apoio dele                     (students.cs_id_2, v47)
--   3. ele esta numa mentoria ATIVA pela qual ela e responsavel
--      (deliveries.status = 'ativo' + staff_branches)
-- A master continua vendo tudo. A diretoria continua so lendo.
--
-- ATENCAO: o item 3 vale para toda mentoria marcada em "Mentorias responsavel"
-- no cadastro da equipe. Se varias CS estiverem marcadas na Mentoria Mae,
-- todas passam a ver os alunos da Mae. A conferencia no fim mostra quem esta
-- marcado em que, para a Thais revisar antes.
-- =============================================================================


-- A checagem precisa ler deliveries e staff_branches por fora da RLS dessas
-- tabelas — senao a propria politica de deliveries ("so vejo entregas dos
-- meus alunos") esconderia a entrega que daria o acesso, e a regra nunca
-- valeria. Por isso e uma funcao security definer, e nao um exists inline.
create or replace function public.enxerga_pela_mentoria(p_student_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $function$
  select exists (
    select 1
    from deliveries d
    join staff_branches sbr on sbr.branch_id = d.branch_id
    where d.student_id = p_student_id
      and d.status = 'ativo'
      and sbr.staff_id = current_staff_id()
  );
$function$;

revoke all on function public.enxerga_pela_mentoria(uuid) from public;
grant execute on function public.enxerga_pela_mentoria(uuid) to authenticated;


-- students: ver e editar
drop policy if exists students_select_pela_mentoria on students;
create policy students_select_pela_mentoria on students
  for select to authenticated
  using (enxerga_pela_mentoria(id));

drop policy if exists students_update_pela_mentoria on students;
create policy students_update_pela_mentoria on students
  for update to authenticated
  using (enxerga_pela_mentoria(id))
  with check (enxerga_pela_mentoria(id));


-- as tabelas penduradas no aluno, mesmo padrao da v47
do $$
declare
  t text;
begin
  foreach t in array array[
    'deliveries','student_whatsapp_groups','mentoring_sessions','nps_responses',
    'feedback_entries','course_progress','lesson_progress','live_click_log','disc_results'
  ]
  loop
    if to_regclass('public.' || t) is null then continue; end if;
    if not exists (select 1 from information_schema.columns
                   where table_schema = 'public' and table_name = t and column_name = 'student_id') then
      continue;
    end if;
    execute format('drop policy if exists %I on public.%I', t || '_pela_mentoria', t);
    execute format(
      'create policy %I on public.%I for all to authenticated
         using (enxerga_pela_mentoria(%I.student_id))
         with check (enxerga_pela_mentoria(%I.student_id))',
      t || '_pela_mentoria', t, t, t);
  end loop;
end $$;


-- a checagem da importacao: aluno da minha mentoria tambem conta como "meu"
create or replace function public.checar_email_aluno(p_email text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $function$
declare
  v_id uuid; v_cs_id uuid; v_cs2 uuid; v_cs_nome text; v_minha boolean; v_master boolean;
begin
  if not is_current_staff_ativa() then
    raise exception 'Apenas a equipe ativa pode consultar.';
  end if;
  v_master := is_current_staff_master();

  select s.id, s.cs_id, s.cs_id_2, st.full_name
    into v_id, v_cs_id, v_cs2, v_cs_nome
  from students s
  left join staff st on st.id = s.cs_id
  where lower(s.email) = lower(trim(p_email))
  limit 1;

  if v_id is null then
    return jsonb_build_object('existe', false);
  end if;

  v_minha := (v_cs_id = current_staff_id())
          or (v_cs2 = current_staff_id())
          or enxerga_pela_mentoria(v_id);

  return jsonb_build_object(
    'existe',  true,
    'minha',   coalesce(v_minha, false),
    'cs_nome', coalesce(v_cs_nome, 'sem CS'),
    'id',      case when coalesce(v_minha, false) or v_master then v_id else null end
  );
end
$function$;

notify pgrst, 'reload schema';


-- -----------------------------------------------------------------------------
-- Conferencia: quem esta marcado como responsavel por qual mentoria, e quantos
-- alunos ativos cada marcacao passa a liberar. E AQUI que a Mae precisa ser
-- revisada: cada CS listada nela passa a ver todos esses alunos.
-- -----------------------------------------------------------------------------
select b.name                                                     as mentoria,
       st.full_name                                               as cs_responsavel_pela_mentoria,
       (select count(distinct d.student_id) from deliveries d
         where d.branch_id = b.id and d.status = 'ativo')         as alunos_ativos_que_ela_passa_a_ver
from staff_branches sbr
join staff st   on st.id = sbr.staff_id
join branches b on b.id = sbr.branch_id
where st.is_active
order by b.name, st.full_name;
