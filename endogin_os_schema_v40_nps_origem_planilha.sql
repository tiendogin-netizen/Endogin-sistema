-- v40: permite registrar no NPS as notas que vêm das planilhas da CS.
--
-- A restrição original só aceitava origem 'primeiro_acesso' ou 'periodico':
--
--   CHECK (source = ANY (ARRAY['primeiro_acesso'::text, 'periodico'::text]))
--
-- Por isso a primeira importação recusou as 112 notas de NPS da planilha
-- (113 erros "violates check constraint nps_responses_source_check") — o
-- cadastro dos alunos entrou normalmente, só as notas ficaram de fora.
--
-- São DUAS origens novas, não uma, porque as abas da planilha usam escalas
-- diferentes: a aba EVELYN tem "NPS (0-10)" e as demais têm "NPS (0-5)".
-- A área de NPS do sistema é 0-10, então a nota 0-5 é convertida ×2 (5/5
-- vira 10, 4/5 vira 8). Guardar a escala de origem na própria coluna deixa
-- isso auditável depois: dá pra saber quais notas foram convertidas e quais
-- já nasceram 0-10, em vez de descobrir lendo comentário.
--
-- Os dois valores antigos continuam válidos — quem registra NPS pela tela
-- do sistema segue gravando 'periodico'.

alter table nps_responses
  drop constraint if exists nps_responses_source_check;

alter table nps_responses
  add constraint nps_responses_source_check
  check (source = any (array[
    'primeiro_acesso'::text,
    'periodico'::text,
    'planilha_cs_0a5'::text,
    'planilha_cs_0a10'::text
  ]));

notify pgrst, 'reload schema';
