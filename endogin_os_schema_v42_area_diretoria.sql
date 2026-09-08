-- =============================================================================
-- v42 — Área da Diretoria (Dr. Caio e Dr. Vinícius)
-- Rode este arquivo INTEIRO de uma vez no SQL Editor do Supabase.
-- Pode rodar mais de uma vez sem quebrar nada.
-- =============================================================================
--
-- Por que NÃO marcar os doutores como master: `is_current_staff_master()` libera
-- SELECT **e** UPDATE em students, e ainda liga na Área CS o botão de excluir
-- login, a troca de senha de aluno e a edição de qualquer ficha. Para uma tela
-- de diretoria isso é poder demais — eles precisam enxergar a base inteira, não
-- mexer nela.
--
-- Então entra uma marca própria (`is_diretoria`) com políticas só de leitura.
-- =============================================================================


-- -----------------------------------------------------------------------------
-- PARTE 1 — a marca e a função que as políticas usam
-- -----------------------------------------------------------------------------

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


-- -----------------------------------------------------------------------------
-- PARTE 2 — leitura. Uma política de SELECT por tabela que a tela usa.
--
-- As políticas de UPDATE/DELETE que já existem continuam iguais e não citam
-- diretoria em lugar nenhum: é isso que garante que eles não editam aluno.
--
-- O laço só cria política pra tabela que existe de verdade, então se algum
-- nome mudou o script não quebra inteiro — ele só pula.
-- -----------------------------------------------------------------------------

do $$
declare
  t text;
begin
  foreach t in array array[
    'students',            -- a base toda
    'deliveries',          -- qual mentoria cada aluno faz
    'course_progress',     -- progresso nas aulas gravadas
    'nps_responses',       -- nota de satisfação
    'feedback_entries',    -- feedbacks escritos
    'recados',             -- aba de recados
    'mentoring_sessions',  -- sessões 1x1
    'branches',            -- nomes das mentorias
    'lessons',             -- nomes das aulas
    'live_click_log',      -- presença/cliques nas aulas ao vivo
    'documents'            -- materiais
  ]
  loop
    if to_regclass('public.' || t) is not null then
      execute format('drop policy if exists %I on public.%I', t || '_select_diretoria', t);
      execute format(
        'create policy %I on public.%I for select to authenticated using (is_current_staff_diretoria())',
        t || '_select_diretoria', t
      );
    else
      raise notice 'tabela %.% não existe — política pulada', 'public', t;
    end if;
  end loop;
end $$;

-- A tela primeiro lê a linha do próprio doutor em `staff` pra decidir se deixa
-- entrar. Sem isso ele loga e cai na porta fechada.
drop policy if exists staff_select_self on staff;
create policy staff_select_self on staff
  for select to authenticated
  using (auth_user_id = auth.uid());


-- -----------------------------------------------------------------------------
-- PARTE 3 — a ÚNICA escrita que eles têm: subir material.
--
-- Isso não é dado de aluno, é conteúdo deles. Se você preferir que nem isso
-- eles façam, é só apagar esta parte antes de rodar — a tela vai continuar
-- mostrando os materiais, só não deixa subir novo.
-- -----------------------------------------------------------------------------

do $$
begin
  if to_regclass('public.documents') is not null then
    execute 'drop policy if exists documents_insert_diretoria on public.documents';
    execute 'create policy documents_insert_diretoria on public.documents
             for insert to authenticated with check (is_current_staff_diretoria())';
  end if;
end $$;

drop policy if exists materiais_insert_diretoria on storage.objects;
create policy materiais_insert_diretoria on storage.objects
  for insert to authenticated
  with check (bucket_id = 'materiais' and is_current_staff_diretoria());


-- -----------------------------------------------------------------------------
-- PARTE 4 — cadastro do Dr. Caio
--
-- role = 'mentor' é só rótulo (não dá poder nenhum no sistema).
-- is_master e is_super_admin ficam FALSE de propósito.
-- -----------------------------------------------------------------------------

-- Feito com IF/ELSE em vez de ON CONFLICT porque não dá pra assumir que
-- staff.email tem índice único — assim funciona do mesmo jeito nos dois casos,
-- e rodar duas vezes não cria pessoa repetida.
do $$
declare
  v_nome  text := 'Dr. Caio Saraiva';
  v_email text := 'caiosaraiva99@gmail.com';
begin
  if exists (select 1 from staff where lower(email) = lower(v_email)) then
    update staff
       set is_diretoria   = true,
           is_active      = true,
           is_master      = false,
           is_super_admin = false
     where lower(email) = lower(v_email);
    raise notice 'Dr. Caio já existia em staff — marcado como diretoria.';
  else
    insert into staff (full_name, email, role, is_active, is_master, is_super_admin, is_diretoria)
    values (v_nome, v_email, 'mentor', true, false, false, true);
    raise notice 'Dr. Caio cadastrado em staff.';
  end if;
end $$;

-- Quando você tiver o e-mail do Dr. Vinícius: copie o bloco acima, troque
-- v_nome e v_email, e rode só ele (o resto do arquivo já vai estar aplicado).


-- -----------------------------------------------------------------------------
-- PARTE 5 — ligar o cadastro ao login
--
-- ATENÇÃO: SQL não cria login. A linha acima é só o crachá dele; o usuário e a
-- senha vivem em outro lugar (Authentication). Faça assim, nesta ordem:
--
--   1) Supabase → Authentication → Users → "Add user" → "Create new user"
--   2) E-mail: caiosaraiva99@gmail.com
--      Senha: a que você quiser (mín. 6) — depois ele troca
--      Marque "Auto Confirm User"
--   3) Volte aqui e rode o UPDATE abaixo. Ele acha o usuário pelo e-mail e
--      amarra no crachá — é esse vínculo que as políticas enxergam.
-- -----------------------------------------------------------------------------

update staff s
   set auth_user_id = u.id
  from auth.users u
 where lower(u.email) = lower(s.email)
   and s.is_diretoria = true
   and s.auth_user_id is null;


-- -----------------------------------------------------------------------------
-- PARTE 6 — conferência. O resultado desta última consulta é o que aparece
-- na tela do editor. Tem que vir "PODE ENTRAR".
-- -----------------------------------------------------------------------------

notify pgrst, 'reload schema';

select
  full_name,
  email,
  is_diretoria,
  is_master      as e_master_tem_que_ser_false,
  is_super_admin as e_admin_tem_que_ser_false,
  case
    when auth_user_id is null then 'FALTA O LOGIN — faça o passo 1 e 2 da PARTE 5 e rode o UPDATE de novo'
    else 'PODE ENTRAR'
  end as situacao
from staff
where is_diretoria = true
order by full_name;
