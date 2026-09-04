-- v33: biblioteca de materiais/documentos ("Protocolos e materiais" no
-- print que o Luiz mandou) — CS sobe PDF/documento/artigo com metadados
-- (categoria, tipo, versão, responsável, vigente/arquivado) e o aluno vê
-- só a versão vigente, filtrando por categoria e por mentoria.
--
-- Primeira vez que este projeto usa Supabase Storage (até agora fotos
-- ficavam como data-URL direto na coluna `photo_url` — funciona pra imagem
-- pequena, mas um PDF de vários MB não deveria ir num campo de banco).

insert into storage.buckets (id, name, public)
values ('materiais', 'materiais', true)
on conflict (id) do nothing;

-- upload/gestão: qualquer staff (não só master) — é a própria CS que sobe
-- o material da aula/protocolo pro aluno.
drop policy if exists materiais_insert_staff on storage.objects;
create policy materiais_insert_staff on storage.objects
  for insert to authenticated
  with check (bucket_id = 'materiais' and exists (select 1 from staff where staff.auth_user_id = auth.uid()));

drop policy if exists materiais_update_staff on storage.objects;
create policy materiais_update_staff on storage.objects
  for update to authenticated
  using (bucket_id = 'materiais' and exists (select 1 from staff where staff.auth_user_id = auth.uid()));

drop policy if exists materiais_delete_staff on storage.objects;
create policy materiais_delete_staff on storage.objects
  for delete to authenticated
  using (bucket_id = 'materiais' and exists (select 1 from staff where staff.auth_user_id = auth.uid()));

drop policy if exists materiais_select_all on storage.objects;
create policy materiais_select_all on storage.objects
  for select using (bucket_id = 'materiais');

-- ---------------------------------------------------------------------------
create table if not exists documents (
  id uuid primary key default gen_random_uuid(),
  code text,                    -- ex: PROT-EMG-004
  title text not null,
  category text,                -- Emagrecimento / TRH Feminina / TRH Masculina /
                                 -- Implantes / Lipedema / Gestão / Atualização / Geral
  doc_type text,                -- PDF / Checklist / Fluxograma / Planilha /
                                 -- Documento / Formulário / Termo / Artigo comentado
  version text,                 -- ex: v3.1
  revision_date date,
  responsible_name text,        -- ex: Dr. Caio Saraiva (texto livre, não precisa
                                 -- ser uma conta de staff)
  status text not null default 'vigente' check (status in ('vigente', 'arquivado')),
  file_url text not null,
  view_only boolean not null default false,   -- "só leitura" — mostra "Abrir" em
                                                -- vez de "Baixar" pro aluno
  branch_id uuid references branches(id),      -- null = todas as mentorias
  is_new boolean not null default true,
  created_by uuid references staff(id),
  created_at timestamptz not null default now()
);

create index if not exists idx_documents_category on documents(category);
create index if not exists idx_documents_status on documents(status);

alter table documents enable row level security;

drop policy if exists documents_select_staff on documents;
create policy documents_select_staff on documents
  for select to authenticated
  using (exists (select 1 from staff where staff.auth_user_id = auth.uid()));

drop policy if exists documents_select_student on documents;
create policy documents_select_student on documents
  for select to authenticated
  using (
    status = 'vigente'
    and (
      branch_id is null
      or branch_id in (
        select d.branch_id from deliveries d
        join students s on s.id = d.student_id
        where s.auth_user_id = auth.uid() and d.status = 'ativo'
      )
    )
  );

drop policy if exists documents_write_staff on documents;
create policy documents_write_staff on documents
  for all to authenticated
  using (exists (select 1 from staff where staff.auth_user_id = auth.uid()))
  with check (exists (select 1 from staff where staff.auth_user_id = auth.uid()));

notify pgrst, 'reload schema';
