-- v28: campos que faltavam em `lessons` pra bater com o design já aprovado
-- no mockup do Portal do Aluno (Endogin_Portal_Aluno_Mockup.html) — lá o
-- card de cada aula tem categoria (gera o rótulo "Aula de X"), capa,
-- descrição curta e o link direto pra aula/zoom. O v26 só tinha o básico
-- (título, dia/data, horário, duração) — faltava isso.

alter table lessons
  add column if not exists category text,
  add column if not exists cover_url text,
  add column if not exists description text,
  add column if not exists link_url text;

notify pgrst, 'reload schema';
