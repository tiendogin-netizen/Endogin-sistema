-- v67: fecha o que faltou do v66.
--
-- Duas coisas explicam a diferença, e as duas são da própria planilha:
--
-- 1) QUATRO alunos não têm e-mail nela (Alice Lopes de Almeida, Iana
--    Carruego, Isabelle Ledo e Silvana Guedes Gomes). Como o casamento é
--    por e-mail, eles ficaram de fora e foram inativados por engano.
--    Aqui eles são casados pelo NOME e voltam a ficar ativos.
--
-- 2) DUAS pessoas aparecem em DUAS linhas cada (Karine Ribeiro Antunes e
--    Romolo Guida, que estão na Mãe e na Start ao mesmo tempo). A planilha
--    tem 465 LINHAS, mas 463 PESSOAS — e 421 pessoas ativas, que é
--    exatamente o número que você falou.
--
-- Alvo final: 421 ativos · 12 em tratativa · 12 trancados · 18 encerraram · 463 pessoas

drop table if exists sem_email_planilha;
create table sem_email_planilha (nome text, mentoria text, cs text);
insert into sem_email_planilha (nome, mentoria, cs) values
  ('Alice Lopes de Almeida','Mentores Masters','Horjana'),
  ('Iana Carruego','Mentores Masters','Horjana'),
  ('Isabelle Ledo','Mentores Masters','Horjana'),
  ('Silvana Guedes Gomes','Mentoria Mãe','Thabata');

-- casa pelo nome (sem acento, sem pontuação)
alter table sem_email_planilha add column student_id uuid;
update sem_email_planilha p set student_id = s.id
  from students s
 where lower(regexp_replace(translate(s.full_name,
        'áàâãäéèêëíìîïóòôõöúùûüçÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇ',
        'aaaaaeeeeiiiiooooouuuucAAAAAEEEEIIIIOOOOOUUUUC'),'[^A-Za-z ]',' ','g'))
     = lower(regexp_replace(translate(p.nome,
        'áàâãäéèêëíìîïóòôõöúùûüçÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇ',
        'aaaaaeeeeiiiiooooouuuucAAAAAEEEEIIIIOOOOOUUUUC'),'[^A-Za-z ]',' ','g'));

-- quem não achou (a Thaís precisa pôr o e-mail na planilha ou cadastrar aqui)
select nome, mentoria, cs from sem_email_planilha where student_id is null;

-- volta pra ativo
update students s set status = 'ativo', oculto_diretoria = false
  from sem_email_planilha p where p.student_id = s.id;

-- mentoria e CS deles
insert into deliveries (student_id, branch_id, label, status, cs_id)
select p.student_id, b.id, b.name, 'ativo',
       (select id from staff st where st.full_name ilike p.cs || '%' and st.is_active limit 1)
  from sem_email_planilha p join branches b on b.name = p.mentoria
 where p.student_id is not null
   and not exists (select 1 from deliveries d where d.student_id = p.student_id and d.branch_id = b.id);

update deliveries d set status = 'ativo',
       cs_id = coalesce((select id from staff st where st.full_name ilike p.cs || '%' and st.is_active limit 1), d.cs_id)
  from sem_email_planilha p join branches b on b.name = p.mentoria
 where d.student_id = p.student_id and d.branch_id = b.id;

update students s set cs_id = d.cs_id
  from deliveries d where d.student_id = s.id and d.status = 'ativo' and d.cs_id is not null
   and s.cs_id is distinct from d.cs_id;

-- ninguém fora da planilha pode ficar ativo (pega 'onboarding' e afins)
update students s set status = 'inativo', oculto_diretoria = true
 where s.status not in ('inativo','cancelado','trancado')
   and not exists (select 1 from espelho_planilha p where p.email = lower(s.email))
   and not exists (select 1 from sem_email_planilha q where q.student_id = s.id);

update deliveries d set status = 'inativo'
  from students s where d.student_id = s.id and s.status = 'inativo' and d.status = 'ativo';

-- ============================================================
-- CONFERÊNCIA FINAL
-- ============================================================
select 'PLANILHA' as fonte, 421 as ativos, 12 as tratativa, 12 as trancados, 18 as encerraram, 463 as pessoas
union all
select 'SISTEMA',
       (select count(*) from students where status='ativo' and coalesce(renewal_status,'')<>'Resolvendo'),
       (select count(*) from students where status='ativo' and renewal_status='Resolvendo'),
       (select count(*) from students where status='trancado'),
       (select count(*) from students where status='cancelado'),
       (select count(*) from students where status in ('ativo','trancado','cancelado'));

select st.full_name as cs, count(distinct d.student_id) as alunos
  from deliveries d join staff st on st.id = d.cs_id
 where d.status='ativo' group by st.full_name order by 2 desc;
