-- =============================================================================
-- v45 — qualquer CS pode montar a grade da semana
-- Rode o arquivo inteiro no SQL Editor. Pode rodar mais de uma vez.
-- =============================================================================
--
-- Até agora o botão "Nova aula" só aparecia para a master, e as políticas do
-- banco acompanhavam. Montar a grade é trabalho corrente da CS — cada uma
-- cuida das mentorias dela e não faz sentido a Thais ser gargalo de horário
-- de aula.
--
-- O que NÃO entra aqui de propósito: DELETE. Aula apagada no meio da semana
-- vira aluno que não achou a sala, sem ninguém saber quem tirou. Apagar
-- continua com a master. Se você quiser soltar isso também, é só me dizer.
--
-- =============================================================================


-- Quem é da equipe e está ativa. Deliberadamente não olha o papel: CS,
-- secretária e financeiro montam a grade do mesmo jeito. Quem saiu do time
-- (is_active = false) não escreve nada.
create or replace function public.is_current_staff_ativa()
returns boolean
language sql
stable
security definer
as $function$
  select coalesce(
    (select is_active from staff where auth_user_id = auth.uid()),
    false
  );
$function$;


drop policy if exists lessons_insert_staff on lessons;
create policy lessons_insert_staff on lessons
  for insert to authenticated
  with check (is_current_staff_ativa());

drop policy if exists lessons_update_staff on lessons;
create policy lessons_update_staff on lessons
  for update to authenticated
  using (is_current_staff_ativa())
  with check (is_current_staff_ativa());


notify pgrst, 'reload schema';


-- -----------------------------------------------------------------------------
-- Conferência: quem pode o quê em `lessons`.
-- Tem que aparecer INSERT e UPDATE liberados para a equipe ativa, e o DELETE
-- continuar só nas políticas de master que já existiam.
-- -----------------------------------------------------------------------------

select policyname       as politica,
       cmd              as operacao,
       coalesce(qual, with_check) as regra
from pg_policies
where schemaname = 'public'
  and tablename = 'lessons'
order by cmd, policyname;
