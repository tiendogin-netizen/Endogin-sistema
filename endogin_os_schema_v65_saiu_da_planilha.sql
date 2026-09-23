-- v65: fecha a diferença entre o sistema (490) e a planilha da Thaís (465).
--
-- De onde vem: comparei o painel dela de 01/09 com o de 22/09. Quem estava
-- como "Desativado", "Encerrado" ou "Inativo" no de 01/09 simplesmente saiu
-- do de 22/09 — ela tirou da planilha em vez de marcar. No nosso sistema
-- esses 16 continuaram contando como ativos.
--
-- Aqui eles viram inativos (o cadastro e o histórico ficam; só param de
-- contar e somem da carteira da CS).

drop table if exists saiu_da_planilha;
create table saiu_da_planilha (email text primary key, nome text, status_antigo text);
insert into saiu_da_planilha (email, nome, status_antigo) values
  ('acruzfreire11@gmail.com','André Cruz Freire','Desativado'),
  ('angelo@pagoto.com','Angelo Bruno Pagoto','Desativado'),
  ('dragiovannamilhomem@gmail.com','Giovanna Milhomem Ignacio','Desativado'),
  ('drleonel-borges@yahoo.com.br','Rogério Leonel Borges','Desativado'),
  ('fonsecasfernanda@gmail.com','Fernanda Carolline Luiz da Fonseca','Desativado'),
  ('glfsantos@hotmail.com','George Luiz Ferreira Santos','Desativado'),
  ('guilherme.b.bonelli25@gmail.com','Guilherme Bermond Bonelli','Desativado'),
  ('islanydiniz@hotmail.com','Islany Diniz Sena','Desativado'),
  ('junior_carvalho.hid@hotmail.com','Joaquim Alves Carvalho Júnior','Encerrado'),
  ('maine.tomas@outlook.com','Maine de Andrade Tomás','Desativado'),
  ('marcelocater@hotmail.com','MARCELO CATER','Desativado'),
  ('mgncossi@gmail.com','Maria Gabriela Nascimento Cossi','Inativo'),
  ('naualelima@gmail.com','Nauale Monique Lima','Desativado'),
  ('phquintao8@gmail.com','Pedro Henrique Quintão de Sá Soares','Desativado'),
  ('raquel@raquelmartins.com.br','Raquel Martins Soares Freire','Desativado'),
  ('renan.merloto@gmail.com','Renan Francisco Merloto','Encerrado')
on conflict (email) do nothing;

-- 1) o que vai mudar (confira antes)
select s.full_name, s.email, s.status as status_hoje, p.status_antigo,
       st.full_name as cs
  from saiu_da_planilha p
  join students s on lower(s.email) = p.email
  left join staff st on st.id = s.cs_id
 order by s.full_name;

-- 2) aplica
update students s
   set status = 'inativo', oculto_diretoria = true
  from saiu_da_planilha p
 where lower(s.email) = p.email and s.status not in ('inativo','cancelado');

update deliveries d set status = 'inativo'
  from saiu_da_planilha p join students s on lower(s.email) = p.email
 where d.student_id = s.id and d.status = 'ativo';

-- 3) conferência: tem que bater com a planilha (423 ativos)
select status, count(*) from students group by status order by 2 desc;

-- ============================================================
-- ATENÇÃO — estes 6 estavam ATIVOS no painel de 01/09 e sumiram do de 22/09
-- sem virar desativados. Não mexi neles. Pergunte à Thaís o que houve:
--   Lucas Almeida Campagnaro | Ativação | drlucascampagnaro
--   Marcos Antonio Sanches | Endogin MÃE | drsanchesmarcos@gmail.com
--   Jose Pedro da Silva Bruno | Endogin MÃE | jpsbruno@hotmail.com
--   Karina Carolina de Oliveira | Endogin MÃE | ka_medicina@hotmail.com
--   Silvana Valdemarin Alves | Ativação | silviaval12@gmail.com
--   Wanessa Câmara de Rezende | Endogin MÃE | w.camararezende@gmail.com
-- ============================================================
select s.full_name, s.email, s.status, st.full_name as cs
  from students s left join staff st on st.id = s.cs_id
 where lower(s.email) in ('drlucascampagnaro', 'drsanchesmarcos@gmail.com', 'jpsbruno@hotmail.com', 'ka_medicina@hotmail.com', 'silviaval12@gmail.com', 'w.camararezende@gmail.com');
