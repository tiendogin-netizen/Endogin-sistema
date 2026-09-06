-- v39: campos que existem nas planilhas da CS e não tinham onde cair no
-- cadastro do aluno. Sem isso, a importação simplesmente descartava a coluna.
--
-- Só entram aqui os que realmente têm dado e não cabem em nenhuma coluna atual:
--
--   ENDEREÇO         -> endereco         (53 preenchidos, só na aba EVELYN)
--   CONTRATO         -> contrato_status  (47, só na aba VIVIANE E ADRIELLY:
--                                         "Pendente" / "Assinado")
--   RESPONDEU ICP?   -> respondeu_icp    (a planilha traz False em todas as
--                                         linhas hoje, mas a coluna existe pra
--                                         quando a CS começar a marcar)
--
-- Ficaram DE FORA de propósito:
--   OBS    -> tem 1 valor preenchido no arquivo inteiro; a importação junta
--             ele no campo de anotações que já existe, não vale uma coluna.
--   DISC   -> a coluna está inutilizável na planilha (valores como "-",
--             "CAUANE" e emoji de pasta). O DISC de verdade já vive na tabela
--             `disc_results`, alimentada pelo próprio Portal do Aluno.
--   NPS e FEEDBACK -> não são campo de cadastro: já têm tabela própria
--             (`nps_responses` e `feedback_entries`) e a importação escreve lá.

alter table students
  add column if not exists endereco text,
  add column if not exists contrato_status text,
  add column if not exists respondeu_icp boolean not null default false;

-- não precisa de policy nova: as colunas entram sob a RLS que já existe em
-- students (v9) — cs_id = current_staff_id() or is_current_staff_master().

notify pgrst, 'reload schema';
