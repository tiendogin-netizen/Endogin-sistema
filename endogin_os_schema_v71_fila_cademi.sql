-- v71: a Cademi para de criar aluno sozinha — passa a avisar.
--
-- O problema: toda compra na Cademi criava um cadastro aqui. Quando o aluno
-- já existia (renovou, comprou outra mentoria, usou outro e-mail), virava
-- cadastro duplicado, e aí carteira e contagem saíam erradas.
--
-- A solução não é ficar cego: em vez de criar, a Cademi agora deixa o aviso
-- numa fila. A CS olha, vê se já existe alguém parecido e decide: cadastrar
-- ou ignorar. Nada se perde e nada entra sem revisão.

create table if not exists cademi_entradas (
  id             uuid primary key default gen_random_uuid(),
  cademi_user_id text,
  nome           text,
  email          text,
  telefone       text,
  entrega        text,          -- nome do produto/mentoria comprado
  recebido_em    timestamptz not null default now(),
  situacao       text not null default 'pendente',  -- pendente | cadastrado | ignorado
  resolvido_por  uuid references staff(id),
  resolvido_em   timestamptz,
  student_id     uuid references students(id) on delete set null,
  observacao     text,
  raw            jsonb
);

create index if not exists cademi_entradas_situacao_idx on cademi_entradas (situacao, recebido_em desc);
create index if not exists cademi_entradas_email_idx on cademi_entradas (lower(email));

alter table cademi_entradas enable row level security;

drop policy if exists cademi_entradas_staff on cademi_entradas;
create policy cademi_entradas_staff on cademi_entradas
  for all to authenticated
  using (current_staff_id() is not null)
  with check (current_staff_id() is not null);

grant select, insert, update, delete on cademi_entradas to authenticated;

-- interruptor: se um dia quiserem voltar a criar automático, é só ligar aqui
alter table app_settings add column if not exists criar_aluno_automatico boolean not null default false;

notify pgrst, 'reload schema';

select 'fila da Cademi pronta' as ok;
