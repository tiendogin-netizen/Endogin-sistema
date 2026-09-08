-- =============================================================================
-- v43 — o que a diretoria pode MEXER
-- Rode o arquivo inteiro no SQL Editor. Pode rodar mais de uma vez.
-- Depende da v42 (que criou `is_diretoria` e `is_current_staff_diretoria()`).
-- =============================================================================
--
-- A v42 deu leitura ampla e escrita nenhuma. Agora a diretoria passa a mexer
-- em CONTEÚDO — material, recado e agenda de aula ao vivo. O que NÃO muda:
--
--   students continua fora do alcance deles. As políticas de UPDATE em
--   students seguem sendo `cs_id = current_staff_id() OR is_master`, e nada
--   aqui as toca. Ficha de aluno continua sendo trabalho da CS.
--
-- =============================================================================


-- -----------------------------------------------------------------------------
-- 1) Recados. A tabela real é `announcements` (+ `announcement_branches`, que
--    diz para quais mentorias o recado vai). "recados" é o bucket de anexos.
--
--    A tela da diretoria estava lendo uma tabela chamada `recados`, que não
--    existe — por isso a aba nunca mostrou nada. Corrigido no HTML; aqui entra
--    a permissão que faltava.
-- -----------------------------------------------------------------------------

do $$
declare
  t text;
  acao text;
begin
  foreach t in array array['announcements', 'announcement_branches']
  loop
    if to_regclass('public.' || t) is null then
      raise notice 'tabela public.% nao existe — pulada', t;
      continue;
    end if;

    foreach acao in array array['select', 'insert', 'update', 'delete']
    loop
      execute format('drop policy if exists %I on public.%I', t || '_' || acao || '_diretoria', t);
    end loop;

    execute format('create policy %I on public.%I for select to authenticated using (is_current_staff_diretoria())',
                   t || '_select_diretoria', t);
    execute format('create policy %I on public.%I for insert to authenticated with check (is_current_staff_diretoria())',
                   t || '_insert_diretoria', t);
    execute format('create policy %I on public.%I for update to authenticated using (is_current_staff_diretoria()) with check (is_current_staff_diretoria())',
                   t || '_update_diretoria', t);
    execute format('create policy %I on public.%I for delete to authenticated using (is_current_staff_diretoria())',
                   t || '_delete_diretoria', t);
  end loop;
end $$;

-- O card do recado mostra quem publicou. Sem ler `staff` o nome do autor vem
-- sempre vazio. É leitura de nome de equipe — não tem dado de aluno aqui.
drop policy if exists staff_select_diretoria on staff;
create policy staff_select_diretoria on staff
  for select to authenticated
  using (is_current_staff_diretoria());


-- -----------------------------------------------------------------------------
-- 2) Materiais: poder excluir o que subiram.
--    O registro fica em `documents` e o arquivo no bucket `materiais` — a tela
--    apaga os dois, senão o bucket cresce com arquivo órfão.
-- -----------------------------------------------------------------------------

do $$
begin
  if to_regclass('public.documents') is not null then
    execute 'drop policy if exists documents_delete_diretoria on public.documents';
    execute 'create policy documents_delete_diretoria on public.documents
             for delete to authenticated using (is_current_staff_diretoria())';

    -- editar o registro (trocar versão, arquivar) sem precisar apagar e subir de novo
    execute 'drop policy if exists documents_update_diretoria on public.documents';
    execute 'create policy documents_update_diretoria on public.documents
             for update to authenticated
             using (is_current_staff_diretoria()) with check (is_current_staff_diretoria())';
  end if;
end $$;

drop policy if exists materiais_delete_diretoria on storage.objects;
create policy materiais_delete_diretoria on storage.objects
  for delete to authenticated
  using (bucket_id = 'materiais' and is_current_staff_diretoria());


-- -----------------------------------------------------------------------------
-- 3) Aulas ao vivo: só EDITAR.
--
--    De propósito não entra insert nem delete. Criar e apagar aula continua
--    sendo da CS, na aba Calendário — a agenda precisa de um dono só, senão
--    aula sumida vira caça ao culpado. Se você quiser que eles criem e apaguem
--    também, me avise que eu solto as outras duas.
-- -----------------------------------------------------------------------------

do $$
begin
  if to_regclass('public.lessons') is not null then
    execute 'drop policy if exists lessons_update_diretoria on public.lessons';
    execute 'create policy lessons_update_diretoria on public.lessons
             for update to authenticated
             using (is_current_staff_diretoria()) with check (is_current_staff_diretoria())';
  end if;
end $$;


notify pgrst, 'reload schema';


-- -----------------------------------------------------------------------------
-- 4) Conferência: o que a diretoria pode fazer, tabela por tabela.
--    students tem que aparecer SÓ com SELECT.
-- -----------------------------------------------------------------------------

select
  tablename                                as tabela,
  string_agg(distinct upper(cmd), ', ' order by upper(cmd)) as pode
from pg_policies
where schemaname = 'public'
  and policyname like '%_diretoria'
group by tablename
order by tablename;
