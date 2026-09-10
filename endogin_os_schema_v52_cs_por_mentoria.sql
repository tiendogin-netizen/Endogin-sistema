-- =============================================================================
-- v52 - CS responsavel POR MENTORIA do aluno
-- Rode o arquivo inteiro no SQL Editor. Pode rodar mais de uma vez.
-- =============================================================================
--
-- O modelo ate aqui tinha UMA CS por aluno (students.cs_id). Mas o aluno pode
-- estar na Mae com a Thabata e na Start com a Viviane — e as duas precisam
-- ve-lo. A responsabilidade e por MENTORIA DO ALUNO, nao por aluno.
--
-- Cada entrega (deliveries = aluno numa mentoria) ganha a sua CS. Uma CS ve
-- o aluno se responde por alguma mentoria ativa dele. students.cs_id continua
-- como "principal" (rodizio de aluno novo, contagem geral), mas quem manda no
-- acesso passa a ser a CS de cada entrega.
--
-- Por que isto nao reabre a Mae: a CS fica no aluno-na-mentoria, nao na
-- mentoria. A Cauane responde pelos alunos DELA na Mae, nao pela Mae toda.
-- =============================================================================


-- 1) o campo
alter table deliveries
  add column if not exists cs_id uuid references staff(id) on delete set null;
create index if not exists deliveries_cs_id_idx on deliveries(cs_id);


-- 2) preenchimento inicial, em duas passadas
--    a) a responsavel do aluno responde por todas as mentorias dele
update deliveries d
   set cs_id = s.cs_id
  from students s
 where s.id = d.student_id
   and d.cs_id is null
   and s.cs_id is not null;

--    b) mentoria que tem UMA unica responsavel na equipe (as Starts, a
--       Surgical): essa pessoa responde por todos os alunos daquela mentoria.
--       A Mae tem varias e nao entra aqui — fica com a passada (a).
create temp table cs_unica_por_mentoria on commit drop as
  select sbr.branch_id, (array_agg(sbr.staff_id))[1] as staff_id
  from staff_branches sbr
  join staff st on st.id = sbr.staff_id and st.is_active
  group by sbr.branch_id
  having count(*) = 1;

update deliveries d
   set cs_id = u.staff_id
  from cs_unica_por_mentoria u
 where u.branch_id = d.branch_id
   and d.status = 'ativo'
   and d.cs_id is distinct from u.staff_id;


-- 3) quem responde por alguma mentoria ativa do aluno enxerga o aluno.
--    Security definer: a RLS de deliveries esconderia a propria entrega que
--    da o acesso, e a regra nunca valeria.
create or replace function public.atende_o_aluno(p_student_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $function$
  select exists (
    select 1 from deliveries d
    where d.student_id = p_student_id
      and d.status = 'ativo'
      and d.cs_id = current_staff_id()
  );
$function$;
revoke all on function public.atende_o_aluno(uuid) from public;
grant execute on function public.atende_o_aluno(uuid) to authenticated;

drop policy if exists students_select_por_entrega on students;
create policy students_select_por_entrega on students
  for select to authenticated using (atende_o_aluno(id));

drop policy if exists students_update_por_entrega on students;
create policy students_update_por_entrega on students
  for update to authenticated using (atende_o_aluno(id)) with check (atende_o_aluno(id));

do $$
declare t text;
begin
  foreach t in array array[
    'deliveries','student_whatsapp_groups','mentoring_sessions','nps_responses',
    'feedback_entries','course_progress','lesson_progress','live_click_log','disc_results'
  ]
  loop
    if to_regclass('public.' || t) is null then continue; end if;
    if not exists (select 1 from information_schema.columns
                   where table_schema='public' and table_name=t and column_name='student_id') then continue; end if;
    execute format('drop policy if exists %I on public.%I', t || '_por_entrega', t);
    execute format(
      'create policy %I on public.%I for all to authenticated
         using (atende_o_aluno(%I.student_id)) with check (atende_o_aluno(%I.student_id))',
      t || '_por_entrega', t, t, t);
  end loop;
end $$;


-- 4) entrega nova sem CS: recebe a CS unica da mentoria, se houver; senao a
--    principal do aluno. Assim a tela nao precisa adivinhar e a importacao
--    tambem sai certa.
create or replace function public.define_cs_da_entrega()
returns trigger
language plpgsql
security definer
set search_path = public
as $function$
declare v_cs uuid;
begin
  if new.cs_id is not null then return new; end if;

  select (array_agg(sbr.staff_id))[1] into v_cs
  from staff_branches sbr
  join staff st on st.id = sbr.staff_id and st.is_active
  where sbr.branch_id = new.branch_id
  group by sbr.branch_id
  having count(*) = 1;

  if v_cs is null then
    select cs_id into v_cs from students where id = new.student_id;
  end if;

  new.cs_id := v_cs;
  return new;
end
$function$;

drop trigger if exists trg_define_cs_da_entrega on deliveries;
create trigger trg_define_cs_da_entrega
  before insert on deliveries
  for each row execute function public.define_cs_da_entrega();


-- 5) a checagem da importacao: aluno de mentoria minha conta como "meu"
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
  v_minha := (v_cs_id = current_staff_id()) or (v_cs2 = current_staff_id()) or atende_o_aluno(v_id);
  return jsonb_build_object('existe', true, 'minha', coalesce(v_minha,false),
    'cs_nome', coalesce(v_cs_nome,'sem CS'),
    'id', case when coalesce(v_minha,false) or v_master then v_id else null end);
end $function$;

notify pgrst, 'reload schema';


-- -----------------------------------------------------------------------------
-- Conferencia: por mentoria, quantos alunos ativos cada CS responde.
-- Nas Starts e na Surgical deve aparecer uma CS so (a da equipe). Na Mae,
-- varias — cada uma com os seus. Se alguma Start aparecer com mais de uma,
-- e porque ha mais de uma CS marcada nela no cadastro da equipe.
-- -----------------------------------------------------------------------------
select b.name                              as mentoria,
       coalesce(st.full_name, '>> SEM CS <<') as cs_responsavel,
       count(distinct d.student_id)        as alunos_ativos
from deliveries d
join branches b on b.id = d.branch_id
left join staff st on st.id = d.cs_id
where d.status = 'ativo'
group by b.name, st.full_name
order by b.name, alunos_ativos desc;
