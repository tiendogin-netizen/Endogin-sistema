-- v41: cria o grupo de WhatsApp "Ativação" e libera a equipe a criar grupos
-- pela própria tela.
--
-- Contexto: a Evelyn cuida da mentoria Ativação e os alunos dela aparecem como
-- "sem nenhum grupo" no raio-x da aba Grupos — não porque estejam fora de um
-- grupo, mas porque o grupo de Ativação nunca existiu no sistema. Ela não tinha
-- onde marcá-los.
--
-- A aba Grupos era só leitura: `whatsapp_groups` só era consultada, nunca
-- escrita, então não havia como cadastrar um grupo novo sem passar por aqui.
-- Por isso, além de inserir o de Ativação, esta migration abre a escrita para
-- a equipe — assim o próximo grupo não precisa de migration nenhuma.

insert into whatsapp_groups (name, sort_order, is_broadcast_list)
select 'Ativação', coalesce(max(sort_order), 0) + 1, false
from whatsapp_groups
where not exists (select 1 from whatsapp_groups where name = 'Ativação');

-- Permite qualquer staff criar/editar/reordenar grupo pela tela.
--
-- Só CREATE POLICY, de propósito: não há `enable row level security` aqui.
-- Se a RLS já estiver ligada nesta tabela, a política passa a valer e a tela
-- funciona; se estiver desligada, a política fica inerte e nada muda. Ligar a
-- RLS por conta própria seria arriscado — sem uma política de leitura no mesmo
-- lugar, a lista de grupos sumiria para todo mundo, inclusive para os alunos.
drop policy if exists whatsapp_groups_write_staff on whatsapp_groups;
create policy whatsapp_groups_write_staff on whatsapp_groups
  for all to authenticated
  using (exists (select 1 from staff where staff.auth_user_id = auth.uid()))
  with check (exists (select 1 from staff where staff.auth_user_id = auth.uid()));

notify pgrst, 'reload schema';
