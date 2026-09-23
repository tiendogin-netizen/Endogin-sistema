-- v62: a carteira de cada CS e as pendências de 1:1 da planilha da Thaís.
--
-- Por que existe: no v60 eu atualizei o `cs_id` do ALUNO, mas quem manda na
-- visibilidade (e na contagem das Carteiras) é o `cs_id` de cada ENTREGA
-- (mentoria) — regra do v52. Entregas antigas continuaram com a CS anterior,
-- e por isso os números não batem com a planilha.
--
-- PARTE 1 e 2 são relatório. A 3 corrige. A 4 traz os 1:1.

-- ============================================================
-- PARTE 0 — o que a planilha diz
-- ============================================================
drop table if exists conferencia_cs;
create table conferencia_cs (cs text, na_planilha int);
insert into conferencia_cs (cs, na_planilha) values
  ('Ana Vitória', 98),
  ('Evelyn', 78),
  ('Horjana', 71),
  ('Thabata', 71),
  ('Cauane', 65),
  ('Thais', 35),
  ('Viviane', 47);

-- ============================================================
-- PARTE 1 — RELATÓRIO: planilha x sistema, por CS
-- ============================================================
select c.cs,
       c.na_planilha,
       (select count(*) from students s join staff st on st.id = s.cs_id
         where st.full_name ilike c.cs || '%' and s.status not in ('inativo','cancelado'))       as por_cs_principal,
       (select count(distinct d.student_id) from deliveries d join staff st on st.id = d.cs_id
         where st.full_name ilike c.cs || '%' and d.status = 'ativo')                            as por_entrega_hoje
  from conferencia_cs c
 order by c.cs;

-- 1.2 alunos cuja entrega está com uma CS diferente da planilha
select s.full_name, b.name as mentoria,
       stf_hoje.full_name as cs_na_entrega_hoje,
       p.cs               as cs_na_planilha
  from planilha_thais p
  join students s   on lower(s.email) = p.email
  join branches b   on b.name = p.mentoria
  join deliveries d on d.student_id = s.id and d.branch_id = b.id
  left join staff stf_hoje on stf_hoje.id = d.cs_id
 where coalesce(stf_hoje.full_name, '') not ilike p.cs || '%'
 order by p.cs, s.full_name;

-- ============================================================
-- PARTE 2 — RELATÓRIO: entregas que a planilha não tem
-- (aluno em duas mentorias no sistema, uma só na planilha)
-- ============================================================
select s.full_name, b.name as mentoria_no_sistema, d.status,
       stf.full_name as cs_da_entrega, p.mentoria as mentoria_na_planilha
  from students s
  join deliveries d on d.student_id = s.id and d.status = 'ativo'
  join branches b   on b.id = d.branch_id
  left join staff stf on stf.id = d.cs_id
  left join planilha_thais p on p.email = lower(s.email)
 where p.mentoria is null or b.name <> p.mentoria
 order by s.full_name;

-- ============================================================
-- PARTE 3 — CORRIGE a CS de cada entrega conforme a planilha
-- ============================================================
update deliveries d
   set cs_id = st.id
  from planilha_thais p
  join students s on lower(s.email) = p.email
  join branches b on b.name = p.mentoria
  join staff st   on st.full_name ilike p.cs || '%' and st.is_active
 where d.student_id = s.id and d.branch_id = b.id
   and d.cs_id is distinct from st.id;

-- e o cs_id principal do aluno acompanha a entrega ativa dele
update students s set cs_id = d.cs_id
  from deliveries d
 where d.student_id = s.id and d.status = 'ativo' and d.cs_id is not null
   and s.cs_id is distinct from d.cs_id;

-- conferência depois de corrigir
select c.cs, c.na_planilha,
       (select count(distinct d.student_id) from deliveries d join staff st on st.id = d.cs_id
         where st.full_name ilike c.cs || '%' and d.status = 'ativo') as no_sistema_agora
  from conferencia_cs c order by c.cs;

-- ============================================================
-- PARTE 4 — sessões 1:1 que a planilha aponta (89 pendências)
-- ============================================================
alter table students add column if not exists one_on_one_type text;

drop table if exists pendencias_11;
create table pendencias_11 (nome text, cs text, tipo text, status11 text, data_11 text, obs text);
insert into pendencias_11 (nome,cs,tipo,status11,data_11,obs) values
  ('Alex Barros','Cauane','Renovação','Pendente','RENOVOU','Dr Vinicius disse que vai continuar'),
  ('Alexandre Simões Florio','Cauane','Renovação','Pendente','RENOVOU','Disse que renovou com a Ariane'),
  ('Ana Claudia Santiago Siqueira','Cauane','Renovação','Pendente','RENOVOU','Renovou com a Vitoria'),
  ('Bruna Karoline Pinheiro França Protásio','Cauane','Renovação','Agendada','Dia 2/10 as 14hs','Renovou com a Thais'),
  ('Camila Bandeira','Cauane','Renovação','Agendada','Dia 9/10 as 16hs','Renovou com o Dr Vinicius'),
  ('Camilla de Lima Carneiro','Cauane','Renovação','Agendada','Dia 24/9 as 14hs','Renovado com a Thais'),
  ('Cibele Pimentel da Silva','Cauane','Novo','Concluído','10/08/2026','CLIENTE NOVO'),
  ('Cybele Cristine da Silva Costa Monteiro','Cauane','Renovação','Pendente',null,null),
  ('Edson Diego Silva','Cauane','Renovação','Agendada','Dia 7/10 as 13hs','Renovou com a Thais'),
  ('Eline de Almeida Soriano','Cauane','Renovação','Concluído',null,null),
  ('Elisabete Mendonça Rêgo Peixoto','Cauane','Renovação','Pendente',null,null),
  ('Etianne Andrade Araújo Câmara','Cauane','Renovação','Agendada','Dia 7/10 as 15hs','Renovou com a Vitoria'),
  ('Fabiane Zilmmer','Cauane','Novo','Concluído','07/08/2026','CLIENTE NOVO'),
  ('Fabíola Pereira Frota','Cauane','Renovação','Agendada','Dia 24/9 as 13hs','alinhamento'),
  ('Fernanda Nogueira Queiroz Cabral','Cauane','Renovação','Agendada','Dia 30/10 as 14hs','Renovou com a Vitoria'),
  ('Frederico Corte','Cauane','Renovação','Pendente',null,null),
  ('Guilherme Lobo','Cauane','Renovação','Pendente','RENOVOU','Renovou com a Vitoria'),
  ('Ingryd Amaral Nóbrega','Cauane','Novo','Concluído','10/08/2026','CLIENTE NOVO'),
  ('Jessica Lima de Oliveira','Cauane','Renovação','Pendente','RENOVOU',null),
  ('Jessica Repolho','Cauane','Renovação','Pendente','RENOVOU','Renovação Antecipada 03/09'),
  ('João Paulo de Freitas Sucupira','Cauane','Novo','Concluído','29/08','CLIENTE NOVO, ARI QUEM CUIDA'),
  ('Marcia da Cunha dos Reis','Cauane','Renovação','Pendente','RENOVOU','Dr Vinicius disse que vai continuar'),
  ('Marcos Oliveira Pires de Almeida','Cauane','Renovação','Pendente',null,null),
  ('Yasmin Penalva Costa Serra','Cauane','Renovação','Pendente','RENOVOU','Dr Vinicius disse que vai continuar'),
  ('ANÍBAL DA TORRE BOGOSSIAN','Evelyn','Novo','Agendada','ALUNO NOVO','CLIENTE NOVO'),
  ('Amisbele Angelucci','Evelyn','Novo','Concluído','25/8','CLIENTE NOVO'),
  ('Ana Valéria Ramirez','Evelyn','Renovação','Agendada','Da 23/9 as 13hs','Renovou com a Vitoria dia 03/09/26'),
  ('Begoña García Wicks','Evelyn','Novo','Concluído','25/8','CLIENTE NOVO'),
  ('Bruno Rocha Peixoto','Evelyn','Renovação','Agendada','02/10 ás 13hs','Renovou'),
  ('Carmen Maria de Araújo Lima','Evelyn','Novo','Concluído','11/08/2026','CLIENTE NOVO'),
  ('Eduardo Alencar Viana e Silva','Evelyn','Renovação','Agendada','Dia 7/10 as 16hs','Renovou com a Vitoria'),
  ('Fernanda Ferraz Costa','Evelyn','Renovação','Pendente','RENOVOU','Renovou com a Thabata no evento'),
  ('Gardenia Cenci','Evelyn','Novo','Concluído','12/08/2026','CLIENTE NOVO'),
  ('Jeane Doffiny Bogossian','Evelyn','Renovação','Agendada','RENOVOU',null),
  ('Thayse Priscila Casagrande','Evelyn','Novo','Concluído','25/8','CLIENTE NOVO'),
  ('Andrea Lopes Saldezas Tanuri','Horjana','Renovação','Agendada','Dia 9/10 as 14hs','Renovou com a Thabata no evento'),
  ('Bruna Francielle Pereira Santos Hryniewicz','Horjana','Renovação','Agendada','Dia 24/9 as 16hs',null),
  ('Camila Vieira Giannecchini','Horjana','Novo','Agendada','Dia 23/9 as 17hs','CLIENTE NOVO'),
  ('Erika domingues ferraz jacob','Horjana','Novo','Concluído','30/08','CLIENTE NOVO'),
  ('FERNANDA BRUNO MACEDO','Horjana','Novo','Concluído','16/09/2026','CLIENTE NOVO'),
  ('Jordana Nascimento Pereira','Horjana','Renovação','Pendente','RENOVOU','Renovou com a Ariane'),
  ('João Lauro D''Angelo Caminhas','Horjana','Renovação','Pendente','RENOVOU','Renovou com a Ariane'),
  ('Kelso Passos da Silva','Horjana','Novo','Pendente','ALUNO NOVO','CLIENTE NOVO'),
  ('Livia Cristina Cardoso Ninno Andraus','Horjana','Renovação','Pendente','RENOVOU','Renovou a Vitoria'),
  ('Luiz Guilherme De Campos Ribeiro Filho','Horjana','Novo','Concluído','18/08/2026','CLIENTE NOVO'),
  ('Marcos Vinícius Santana','Horjana','Renovação','Pendente','RENOVOU','Renovou com a Vitoria'),
  ('Marina Mayara Pagoto','Horjana','Renovação','Pendente','RENOVOU','Renovou com a Vitoria'),
  ('Márcia Verônica Paes Fonsêca','Horjana','Novo','Concluído','18/08/2026','CLIENTE NOVO'),
  ('PEDRO HENRIQUE MENEZES TAKIUTI','Horjana','Novo','Concluído','30/08','CLIENTE NOVO. Entrou no lugar da esposa Paula Palacio. entrada de 20k + 4x 22k.'),
  ('Sandra Helena capela Goya Machado','Horjana','Novo','Pendente','ALUNO NOVO','CLIENTE NOVO'),
  ('Thiago Silveira Pereira','Horjana','Novo','Concluído','25/8','CLIENTE NOVO'),
  ('Wilson Ninno Netto','Horjana','Renovação','Pendente','RENOVOU','Renovou com a Vitoria'),
  ('Alessandro de Bastos','Thabata','Novo','Concluído','29/08','CLIENTE NOVO'),
  ('Andrea Rúbia Perfeito','Thabata','Renovação','Concluído','20/07',null),
  ('Ane Caroline Araújo Barreto','Thabata','Renovação','Concluído','01/07/2026',null),
  ('Carolina Moreira dos Santos Starling','Thabata','Novo','Concluído','29/08','CLIENTE NOVO'),
  ('DELMA CONCEIÇÃO PEREIRA DAS NEVES','Thabata','Novo','Concluído','11/08/2026','CLIENTE NOVO'),
  ('Dandara Tureta da silva Felisberto','Thabata','Renovação','Pendente',null,null),
  ('Daniel Barbosa Teixeira','Thabata','Renovação','Concluído','09/06/2026',null),
  ('Fabiano da Cunha Tanuri','Thabata','Novo','Concluído','10/08/2026','CLIENTE NOVO, Fechou renovação da esposa Andrea e a cadeira dupla dele com a Thabata'),
  ('Juliana Matoso Aliprandi','Thabata','Novo','Concluído','11/08/2026','CLIENTE NOVO'),
  ('Karine Ribeiro Antunes','Thabata','Novo','Concluído','17/9/2026','CLIENTE NOVO'),
  ('Katia Alves Ramos','Thabata','Novo','Concluído','18/08/2026','CLIENTE NOVO'),
  ('Lana Kris Montagnani Gonçalves','Thabata','Novo','Concluído','31/08/2026','CLIENTE NOVO'),
  ('Livia Viana Trevisan Paluan','Thabata','Renovação','Pendente',null,null),
  ('Lorena Fernandes Melo','Thabata','Renovação','Pendente','RENOVOU','Renovou no evento com a Thabata'),
  ('Lucas Missiba Brandão','Thabata','Novo','Concluído','16/09/2026','CLIENTE NOVO'),
  ('Luciana Leal Deister Machado','Thabata','Renovação','Pendente','Dia 02/10 as 15hs','VITORIA: Renovou dia 31/08'),
  ('Luciana Virgínia Tempesta Muhe','Thabata','Renovação','Agendada','Dia 09/10 as 13hs','Renovou no evento com a Thabata'),
  ('Maria Paula Silvestre Moura Cavalcante','Thabata','Novo','Concluído','11/08/2026','CLIENTE NOVO'),
  ('Maurício Friederich','Thabata','Renovação','Agendada','Dia 2/10 as 16hs','Renovado com Thabata'),
  ('Milene Maria de Castro Buzzato','Thabata','Renovação','Concluído','Dr Vinicius disse que ja fez 1:1 de renovação',null),
  ('Natani Dantas espinosa','Thabata','Novo','Concluído','10/08/2026','CLIENTE NOVO'),
  ('Paulo José Mantoan dos santos','Thabata','Novo','Concluído','16/09/2026','CLIENTE NOVO, ARI QUEM CUIDA'),
  ('Rafaela Nunes Lira Braga Cândido','Thabata','Renovação','Agendada','Dia 14/10 as 13hs',null),
  ('Rebeca Maria Filgueiras','Thabata','Novo','Concluído','25/08/2026','CLIENTE NOVO'),
  ('Renata De Paula F G De Vasconcellos','Thabata','Renovação','Agendada','Dia 30/9 as 15hs','Alinhamento'),
  ('Roberta Carlesso Miele','Thabata','Renovação','Concluído','Dr Vinicius disse que ja fez 1:1 de renovação',null),
  ('Roberto Cesar Leite','Thabata','Renovação','Pendente',null,null),
  ('Rodrigo Alves de Medeiros Queiroz','Thabata','Renovação','Pendente','RENOVOU','Renovou com a Vitoria'),
  ('Romolo Guida','Thabata','Novo','Concluído','16/09/2026','CLIENTE NOVO'),
  ('Sinara Vidotti Paltanin','Thabata','Renovação','Pendente','RENOVOU','Renovou com a Thais no evento, mas a Vitoria esta vendo sobre os pagamentos'),
  ('Tainã Maria Durans Brito Tochetto','Thabata','Renovação','Pendente','RENOVOU','Renovou com a Vitoria'),
  ('Thiago Veríssimo','Thabata','Renovação','Concluído','01/07/2026','Vai antecipar Renovação, ja deu 13k no curso, em setembro ele paga ele paga 14k + 3 de 27'),
  ('Tânia Maria Ferreira de Carvalho','Thabata','Renovação','Pendente',null,null),
  ('Valéria Leal','Thabata','Renovação','Agendada','Dia 30/9 as 13hs',null),
  ('Víviann Pecly','Thabata','Renovação','Pendente','RENOVOU','Renovou com a Vitoria'),
  ('Wellington Pereira dos Reis','Thabata','Novo','Concluído','OK','CLIENTE NOVO'),
  ('Zelma Maria dos Santos Vilas Boas','Thabata','Renovação','Pendente','RENOVOU','Renovou');

alter table pendencias_11 add column student_id uuid;
update pendencias_11 p set student_id = s.id
  from students s
 where lower(regexp_replace(translate(s.full_name,
        'áàâãäéèêëíìîïóòôõöúùûüçÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇ',
        'aaaaaeeeeiiiiooooouuuucAAAAAEEEEIIIIOOOOOUUUUC'), '[^A-Za-z ]', ' ', 'g'))
     = lower(regexp_replace(translate(p.nome,
        'áàâãäéèêëíìîïóòôõöúùûüçÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇ',
        'aaaaaeeeeiiiiooooouuuucAAAAAEEEEIIIIOOOOOUUUUC'), '[^A-Za-z ]', ' ', 'g'));

-- quem não casou pelo nome (a CS acerta na ficha)
select nome, cs, tipo, status11 from pendencias_11 where student_id is null order by nome;

update students s
   set one_on_one_status  = p.status11,
       one_on_one_type    = p.tipo,
       one_on_one_date    = coalesce(p.data_11, s.one_on_one_date),
       one_on_one_summary = coalesce(p.obs, s.one_on_one_summary)
  from pendencias_11 p
 where p.student_id = s.id;

notify pgrst, 'reload schema';

select count(*) filter (where one_on_one_status = 'Pendente')  as pendentes,
       count(*) filter (where one_on_one_status = 'Agendada')  as agendadas,
       count(*) filter (where one_on_one_status = 'Concluído') as concluidas
  from students;
