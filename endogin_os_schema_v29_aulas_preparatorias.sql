-- v29: as 5 "aulas preparatórias" que o Dr. Caio/Dr. Vinícius definiram pra
-- todo aluno novo assistir antes do 1x1 (mandaram os links da Cademi).
--
-- Reaproveita a estrutura que já existia (lessons.lesson_type = 'trilha' +
-- lesson_progress, alimentado pelo webhook 'usuario.progresso' da Cademi via
-- lessons.cademi_lesson_id) — só faltavam essas aulas cadastradas. O id da
-- Cademi é o número no final do link (ex: .../aula/7320282 → 7320282).
--
-- branch_id fica null de propósito: é obrigatória pra QUALQUER aluno novo,
-- não é específica de uma mentoria.

insert into lessons (cademi_lesson_id, title, lesson_type, branch_id, link_url)
values
  ('7320282', 'Onboarding 3 — SND! Os três pilares da venda!', 'trilha', null,
    'https://membros.mentoriaendogin.com.br/area/conteudo/aula/7320282'),
  ('7320280', 'Agendamento 2.0 e 7 passos da venda!', 'trilha', null,
    'https://membros.mentoriaendogin.com.br/area/conteudo/aula/7320280'),
  ('7661640', 'Os passos 2, 3 e 4 como vocês nunca viram! Detalhando a técnica da casinha', 'trilha', null,
    'https://membros.mentoriaendogin.com.br/area/conteudo/aula/7661640'),
  ('9412205', 'Aula Ouro — Caixa-Preta: Do Zero ao Primeiro Milhão | Dr. Vinícius Carruego', 'trilha', null,
    'https://membros.mentoriaendogin.com.br/area/conteudo/aula/9412205'),
  ('7320401', 'Aula Ouro - Dr. Wilson - Programas de Acompanhamento na Prática', 'trilha', null,
    'https://membros.mentoriaendogin.com.br/area/conteudo/aula/7320401')
on conflict (cademi_lesson_id) do update set
  title = excluded.title,
  lesson_type = excluded.lesson_type,
  link_url = excluded.link_url;

notify pgrst, 'reload schema';
