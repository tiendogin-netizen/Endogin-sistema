-- v54: aulas obrigatórias visíveis pro aluno + marca de "veterano".
--
-- (1) A política de leitura de `lessons` pro aluno (v26) só deixava passar
--     'semanal' e 'evento'. As aulas da trilha ('trilha') ficavam invisíveis
--     pra ele — por isso o Portal dizia "sua CS ainda não liberou as aulas".
-- (2) As 5 aulas preparatórias do v29 são reinseridas aqui (é um upsert; se
--     já existirem, só atualiza título e link).
-- (3) students.veterano: quem já está na mentoria há tempo não refaz a trilha
--     nem o 1x1 — o Portal mostra essas etapas como dispensadas. Boas-vindas
--     e DISC continuam obrigatórios pra todo mundo. A CS muda isso na ficha.

-- ---------- (1) política ----------
drop policy if exists lessons_select_student on lessons;
create policy lessons_select_student
  on lessons for select
  to authenticated
  using (
    current_student_id() is not null
    and lesson_type in ('semanal', 'evento', 'trilha')
    and (branch_id is null or branch_id in (
      select branch_id from deliveries
      where student_id = current_student_id() and status = 'ativo'
    ))
  );

-- ---------- (2) aulas preparatórias ----------
alter table lessons add column if not exists sort_order int;

-- Sem depender de constraint única: insere o que falta e atualiza o que já
-- existe, pelo id da Cademi.
with aulas(cademi_lesson_id, title, link_url, sort_order) as (values
  ('7320282', 'Onboarding 3 — SND! Os três pilares da venda!',
    'https://membros.mentoriaendogin.com.br/area/conteudo/aula/7320282', 1),
  ('7320280', 'Agendamento 2.0 e 7 passos da venda!',
    'https://membros.mentoriaendogin.com.br/area/conteudo/aula/7320280', 2),
  ('7661640', 'Os passos 2, 3 e 4 como vocês nunca viram! Detalhando a técnica da casinha',
    'https://membros.mentoriaendogin.com.br/area/conteudo/aula/7661640', 3),
  ('9412205', 'Aula Ouro — Caixa-Preta: Do Zero ao Primeiro Milhão | Dr. Vinícius Carruego',
    'https://membros.mentoriaendogin.com.br/area/conteudo/aula/9412205', 4),
  ('7320401', 'Aula Ouro - Dr. Wilson - Programas de Acompanhamento na Prática',
    'https://membros.mentoriaendogin.com.br/area/conteudo/aula/7320401', 5)
), atualizadas as (
  update lessons l
     set title = a.title, lesson_type = 'trilha', branch_id = null,
         link_url = a.link_url, sort_order = a.sort_order
    from aulas a
   where l.cademi_lesson_id = a.cademi_lesson_id
  returning l.cademi_lesson_id
)
insert into lessons (cademi_lesson_id, title, lesson_type, branch_id, link_url, sort_order)
select a.cademi_lesson_id, a.title, 'trilha', null, a.link_url, a.sort_order
  from aulas a
 where not exists (select 1 from lessons l where l.cademi_lesson_id = a.cademi_lesson_id);

-- ---------- (3) veterano ----------
alter table students add column if not exists veterano boolean not null default false;

-- Ninguém nasce veterano: todo aluno começa como "novo" (trilha + 1x1 a
-- fazer). Quem já passou por isso a Thaís marca na ficha, caso a caso.

-- ---------- (4) quando o aluno entrou no Portal ----------
-- O Portal grava no login: first_login_at só na primeira vez, last_login_at
-- sempre. É o que a CS vê na ficha e na coluna "Jornada" da lista.
alter table students add column if not exists first_login_at timestamptz;
alter table students add column if not exists last_login_at  timestamptz;

notify pgrst, 'reload schema';

-- conferência
select
  (select count(*) from lessons where lesson_type = 'trilha')       as aulas_trilha,
  (select count(*) from students where veterano)                     as veteranos,
  (select count(*) from students where not veterano)                 as novos;
