-- =============================================================================
-- v47 - CS de apoio: o mesmo aluno visivel e editavel por duas CS
-- Rode o arquivo inteiro no SQL Editor. Pode rodar mais de uma vez.
-- =============================================================================
--
-- O pedido era "duplicar" os alunos da Adrielly que estao com a Viviane. Nao
-- duplicamos: duplicar cria dois cadastros da mesma pessoa, e ai a Viviane
-- altera um, a Adrielly altera o outro, e os dois divergem - exatamente o
-- problema que se queria evitar.
--
-- Em vez disso o aluno ganha um segundo campo, cs_id_2 ("CS de apoio"). A
-- responsavel continua sendo quem esta em cs_id (controle, contagem de
-- carteira, rodizio). A apoio enxerga e edita O MESMO registro. Quem esta em
-- cs_id_2 ve so esses alunos - a regra "cada CS ve so os seus" continua.
-- =============================================================================


-- 1) o campo
alter table students
  add column if not exists cs_id_2 uuid references staff(id) on delete set null;
create index if not exists students_cs_id_2_idx on students(cs_id_2);


-- 2) acesso: politicas permissivas se somam as que ja existem
drop policy if exists students_select_cs_apoio on students;
create policy students_select_cs_apoio on students
  for select to authenticated
  using (cs_id_2 is not null and cs_id_2 = current_staff_id());

drop policy if exists students_update_cs_apoio on students;
create policy students_update_cs_apoio on students
  for update to authenticated
  using (cs_id_2 is not null and cs_id_2 = current_staff_id())
  with check (cs_id_2 is not null and cs_id_2 = current_staff_id());


-- 3) as tabelas penduradas no aluno (mentorias, grupos, sessoes, NPS...)
--    Sem isto a apoio veria a ficha mas nao o que esta dentro dela.
--    So cria politica em tabela que existe e tem coluna student_id.
do $$
declare
  t text;
begin
  foreach t in array array[
    'deliveries','student_whatsapp_groups','mentoring_sessions','nps_responses',
    'feedback_entries','course_progress','lesson_progress','live_click_log','disc_results'
  ]
  loop
    if to_regclass('public.' || t) is null then
      raise notice 'tabela % nao existe - pulada', t;
      continue;
    end if;
    if not exists (select 1 from information_schema.columns
                   where table_schema = 'public' and table_name = t and column_name = 'student_id') then
      raise notice 'tabela % nao tem student_id - pulada', t;
      continue;
    end if;

    execute format('drop policy if exists %I on public.%I', t || '_cs_apoio', t);
    execute format(
      'create policy %I on public.%I for all to authenticated
         using (exists (select 1 from students s where s.id = %I.student_id
                        and s.cs_id_2 is not null and s.cs_id_2 = current_staff_id()))
         with check (exists (select 1 from students s where s.id = %I.student_id
                        and s.cs_id_2 is not null and s.cs_id_2 = current_staff_id()))',
      t || '_cs_apoio', t, t, t);
  end loop;
end $$;


-- 4) a checagem da importacao: aluno de apoio tambem conta como "meu"
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

  v_minha := (v_cs_id = current_staff_id()) or (v_cs2 = current_staff_id());

  return jsonb_build_object(
    'existe',  true,
    'minha',   coalesce(v_minha, false),
    'cs_nome', coalesce(v_cs_nome, 'sem CS'),
    'id',      case when coalesce(v_minha, false) or v_master then v_id else null end
  );
end
$function$;

notify pgrst, 'reload schema';


-- 5) os alunos da planilha da Adrielly: ela entra como apoio, a responsavel
--    fica como esta.
create temp table planilha_adrielly (email text) on commit drop;
insert into planilha_adrielly (email) values
    ('alessandracmiranda@icloud.com'),
    ('amanda_aarao@yahoo.com.br'),
    ('aninhaabt@yahoo.com.br'),
    ('bumlima@hotmail.com'),
    ('camilecardosoo@gmail.com'),
    ('carolcassabgenaro@hotmail.com'),
    ('carolfariamiurim@hotmail.com'),
    ('cmateusr@gmail.com'),
    ('cybertoldo@hotmail.com'),
    ('ddenovaisalves@gmail.com'),
    ('dra.larissaazevedo@gmail.com'),
    ('dra.luanaalegrefelix@gmail.com'),
    ('dra_flaviamonteiro@hotmail.com'),
    ('dramanda.go@hotmail.com'),
    ('dramariamviviane@gmail.com'),
    ('drathaiscassaroadm@gmail.com'),
    ('drathaismendess@gmail.com'),
    ('driuriromanov@gmail.com'),
    ('drsandrapersonal@gmail.com'),
    ('elisasouzalima@yahoo.com.br'),
    ('emimax_babii@hotmail.com'),
    ('fernanda.c.roque@hotmail.com'),
    ('gabi_webers@hotmail.com'),
    ('gisela_altoe@hotmail.com'),
    ('junnybelache@hotmail.com'),
    ('lara_figueiredo4@hotmail.com'),
    ('layaneferreirab@gmail.com'),
    ('leticia.b.alvim@gmail.com'),
    ('lizardamed@hotmail.com'),
    ('luan.tagiaroli.f@gmail.com'),
    ('mahteusferrari@gmail.com'),
    ('marialuisagomes23@hotmail.com'),
    ('nadhinecalheiros@outlook.com'),
    ('naiara_fumagalli@yahoo.com.br'),
    ('osnjunior@hotmail.com'),
    ('rbmadruga@gmail.com'),
    ('rodrigoljalves@gmail.com'),
    ('sszanindra@gmail.com'),
    ('tamiris.giacomin@gmail.com'),
    ('tatianefernandesv@gmail.com'),
    ('taynasantiago7618@gmail.com'),
    ('vaneska37@gmail.com'),
    ('vcorreamed97@gmail.com'),
    ('ximenes_luciana@hotmail.com'),
    ('yaratrigo@hotmail.com');

update students s
   set cs_id_2 = (select id from staff where lower(email) = 'adriellylage1@gmail.com')
 where lower(s.email) in (select email from planilha_adrielly);


-- 6) conferencia: cada e-mail da planilha, se foi encontrado e com quem esta.
--    Linha com NAO ENCONTRADO = aluno que nao existe na base com esse e-mail.
select p.email,
       case when s.id is null then '>> NAO ENCONTRADO <<' else s.full_name end as aluno,
       coalesce(r.full_name, 'sem CS')                                           as cs_responsavel,
       coalesce(a.full_name, '-')                                                as cs_apoio
from planilha_adrielly p
left join students s on lower(s.email) = p.email
left join staff r on r.id = s.cs_id
left join staff a on a.id = s.cs_id_2
order by (s.id is null) desc, p.email;
