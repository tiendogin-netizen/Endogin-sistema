-- v60: conferência e atualização da base com a carteira da Thaís
-- (arquivo "carteiras-cs-endogin", gerado em 22/09/2026 — 465 mentorados).
--
-- RODE POR PARTES, na ordem. A PARTE 3 é só relatório: nada muda no banco.
-- Só rode a PARTE 4 depois de olhar o relatório e concordar com ele.

-- ============================================================
-- PARTE 1 — colunas que faltavam no nosso cadastro
-- ============================================================
alter table students add column if not exists especialidade text;
alter table students add column if not exists cidade_uf text;
-- quem encerrou a mentoria continua visível pra CS/Thaís, mas some das telas
-- da diretoria (pedido do Luiz)
alter table students add column if not exists oculto_diretoria boolean not null default false;

-- ============================================================
-- PARTE 2 — a planilha vira uma tabela temporária de conferência
-- ============================================================
drop table if exists planilha_thais;
create table planilha_thais (
  nome text, email text, telefone text, mentoria text, cs text,
  status text, status_planilha text, entrada date, vencimento date,
  temperatura text, renovacao text, obs text, aniversario date,
  instagram text, especialidade text, cidade_uf text, respondeu_icp boolean
);

insert into planilha_thais
  (nome,email,telefone,mentoria,cs,status,status_planilha,entrada,vencimento,
   temperatura,renovacao,obs,aniversario,instagram,especialidade,cidade_uf,respondeu_icp)
values
  ('Luana Cavalcante Bonaparte','luanacb@icloud.com','82993126107','Start Caio e Jordana','Ana Vitória','ativo','Ativo','2025-12-13','2026-12-13','Frio',null,null,'1985-11-20','@drabonaparte','Nutróloga','Maceió/ AL',false),
  ('Alice Zanella','zanella.alice@gmail.com','5192645858','Start Caio e Jordana','Ana Vitória','ativo','Ativo','2025-10-28','2026-10-28','Morno',null,null,'1987-09-27','@alicezanella_','cardiologista','Frederico Westphalen/RS',true),
  ('Ana Roberta de Melo Andrada','anarobertaandrada@hotmail.com','63999510111','Start Caio e Jordana','Ana Vitória','ativo','Ativo','2025-12-03','2026-12-03','Morno',null,null,'1992-11-13','@anarobertaandrada','Endocrinologista','Brasilia/DF',false),
  ('Andressa Cristina de Paula Mol','aandressadepaula@gmail.com','38991529772','Start Caio e Jordana','Ana Vitória','ativo','Ativo','2026-02-06','2027-02-06','Morno',null,null,'1994-09-25','@dra.andressadepaulamol','Ginecologista','Viçosa/Ponte Nova /MG',false),
  ('Augusto Sergio Simon Fava Leite','augustofavaleite@gmail.com','31983141479','Start Caio e Jordana','Ana Vitória','ativo','Ativo','2026-03-01','2027-03-01','Morno',null,null,'1993-09-15','@draugustofava','Psiquiatra','João Monlevade/MG',false),
  ('Bianca Coelho Damin Ribeiro','biancacdamin@gmail.com','65981443276','Start Caio e Jordana','Ana Vitória','ativo','Ativo','2025-09-24','2026-09-24','Morno',null,null,'1988-02-27','@drabiancacoelhodamin','Infectologista','Cuiabá/MT',false),
  ('Blima Luciene Bortoloni De Rossi','drablimaderossi@hotmail.com','27999338888','Start Caio e Jordana','Ana Vitória','ativo','Ativo','2025-10-29','2026-10-29','Quente',null,null,'1988-12-23','@drablimaderossi','Nutrologia','Vitória/ES',true),
  ('Bruna Andressa da Rocha','bruhandressa23@icloud.com','66981212146','Start Caio e Jordana','Ana Vitória','ativo','Ativo','2025-11-24','2026-11-24','Morno',null,null,'1993-08-25','drabrunarocha.clinica','Ginecologista','Itanhangá/MT',false),
  ('Bruna Hering','drabrunahering@gmail.com','11996851110','Start Caio e Jordana','Ana Vitória','ativo','Ativo','2025-11-11','2026-11-11','Morno',null,null,'1983-06-29','@dra.brunahering','Dermatologia','São Paulo/SP',false),
  ('Bruno Marinho Pinto de Águila','bruno.aguila87@gmail.com','84988450901','Start Caio e Jordana','Ana Vitória','ativo','Ativo','2025-09-27','2026-09-27','Frio',null,null,'1987-03-06','@brunoaguila','Cirurgião Oncológico','Mossoró/RN',false),
  ('Camila Gava','cami_gava@hotmail.com','41999879191','Start Caio e Jordana','Ana Vitória','ativo','Ativo','2025-11-09','2026-11-09','Quente',null,null,'1991-10-28','@dracamilagava','Emagrecimento','Curitiba/PR',false),
  ('Camila Teixeira Pinto e Lacerda','ctplacerda@outlook.com','21965971013','Start Caio e Jordana','Ana Vitória','ativo','Ativo','2026-05-18','2027-05-18','Morno',null,null,'1991-06-06','@dra_camilateixeira','Nutrologia','Leblon/RJ',false),
  ('Christiane Falci','chrisfalci@hotmail.com','3391055416','Start Caio e Jordana','Ana Vitória','ativo','Ativo','2025-10-24','2026-10-24','Morno',null,null,'1988-05-12','@dra.chrisfalci','Endocrinologista','Governador Valadares/MG',false),
  ('Cibele Lemos Lacerda','cibele-lemos@hotmail.com','35999170042','Start Caio e Jordana','Ana Vitória','ativo','Ativo','2026-02-13','2027-02-13','Quente',null,null,'1983-12-18','@dracibelelemos','Cirurgiã','Passos / MG (Cidade Nova/SP)',true),
  ('Daniele Aragão de Albuquerque','dania.albuquerque@gmail.com','81998154474','Start Caio e Jordana','Ana Vitória','ativo','Ativo','2025-12-20','2026-12-20','Morno',null,null,'1985-10-07','@dradanieleaaragao','Ginecologista','Caruaru/PE',true),
  ('David Bortot Raspini','raspini@hotmail.com','47988166025','Start Caio e Jordana','Ana Vitória','ativo','Ativo','2025-11-09','2026-11-09','Morno',null,null,'1981-02-27','@drdavidraspini','Ginecologista','Brusque/SC',true),
  ('Eduardo Jorge','eduardojorge@oncoginecologia.com.br','11986355281','Start Caio e Jordana','Ana Vitória','ativo','Ativo','2025-10-27','2026-10-27','Morno',null,null,'1975-11-24','@dreduardojorge','Ginecologista','São Paulo/SP',true),
  ('Ende Tâned Barroso Barros Amorim','endetaned@outlook.com','11995470909','Start Caio e Jordana','Ana Vitória','ativo','Ativo','2026-02-19','2027-02-19','Morno',null,null,'1989-03-10','@endeamorim @institutoendeamorim','Endocrinologista','São Luis/MA',true),
  ('Fabiana Almeida Miranda','fabianamiranda793@gmail.com','38998222288','Start Caio e Jordana','Ana Vitória','ativo','Ativo','2026-02-14','2027-02-14','Morno',null,null,'1997-06-07','@dra.fabianamiranda793','Endocrinologista','Indaiabira/MG',false),
  ('Fernanda Letícia Perez Moraes','moraesfernandap@gmail.com','41999497200','Start Caio e Jordana','Ana Vitória','cancelado','Encerrou Mentoria','2026-02-02','2027-02-02','Morno',null,null,null,'@fernanda.cirurgia','Cirurgiã','Apiaí/SP',false),
  ('GISELE TEIXEIRA','gisaffonseca@hotmail.com','91991981243','Start Caio e Jordana','Ana Vitória','ativo','Ativo','2026-03-10','2027-03-10','Morno',null,null,'1986-01-23','@dra.giseleteixeira','Ginecologista','Belém/PA',false),
  ('Glauco Soares Maia Piassi','glauco.piassi@hotmail.com','35988787878','Start Caio e Jordana','Ana Vitória','ativo','Ativo','2025-11-20','2026-11-20','Quente',null,null,null,'@drglaucopiassi','cardiologista','Passos/MG',true),
  ('Isabella Carvalho','isabellaccarvalho_@outlook.com','43991511301','Start Caio e Jordana','Ana Vitória','ativo','Ativo','2025-12-13','2026-12-13','Morno',null,null,'1997-01-13','@dra.isabellalcarvalho','Nutrologia','Ourinnhos/SP',false),
  ('ISABELLA CUNHA','draisabellacunha@gmail.com','24992669902','Start Caio e Jordana','Ana Vitória','ativo','Ativo','2026-03-10','2027-03-10','Morno',null,null,'1989-12-21','@draisabellacunha','Ginecologista','Volta Redonda/RJ',false),
  ('Isadora Bernardes Angelícola','isadora.angelicola@gmail.com','17981522324','Start Caio e Jordana','Ana Vitória','ativo','Ativo','2026-01-16','2027-01-16','Morno',null,null,'1991-07-19','@dra.isadoraangelicola','Ginecologista','Ribeirão Preto/SP',true),
  ('João Gabriel Rocha Fonseca','joaofon2912@gmail.com','79998993539','Start Caio e Jordana','Ana Vitória','ativo','Ativo','2025-12-02','2026-12-02','Morno',null,null,'1991-12-29','@drjoao.fonseca','Hormonologia','Aracaju/SE',false),
  ('José Manoel de Souza','drsouzajrkef@gmail.com','64996681986','Start Caio e Jordana','Ana Vitória','ativo','Ativo','2026-06-03','2027-06-03','Morno',null,null,'1976-08-24','@dr.josemanoel','Ginecologista','Rio Verde//GO',true),
  ('Karine Ribeiro Antunes','karinerantunes@hotmail.com','35997672069','Start Caio e Jordana','Ana Vitória','ativo','Ativo','2026-04-01','2027-04-01','Morno',null,null,'1982-04-20','@drakarineantunes','Endocrinologista','Itajubá/SP',false),
  ('Karoline Menezes da Costa Cardoso','karolinemcosta@yahoo.com.br','31995849852','Start Caio e Jordana','Ana Vitória','ativo','Ativo','2025-11-24','2026-11-24','Morno',null,null,null,'@drakarolinemenezes','Ginecologista','Belo Horinzonte/MG',false),
  ('Layza Luyza de Andrade Belo','layzaandrade_84@hotmail.com','85999689748','Start Caio e Jordana','Ana Vitória','ativo','Ativo','2025-09-27','2026-09-27','Morno',null,null,'1989-09-21','@dralayzabelo','Ginecologista','Mossoró/RN',true),
  ('Leônidas Moreira Dias Neto','neto_bz@hotmail.com','31986374155','Start Caio e Jordana','Ana Vitória','ativo','Ativo','2025-11-25','2026-11-25','Morno',null,null,'1988-10-23','@drleonidasneto','Clinico Geral/Nutrologia','Belo Horinzonte/MG',false),
  ('Lívia Paula Vasconcelos Gouveia','liviaapvasconcelos@gmail.com','82981337795','Start Caio e Jordana','Ana Vitória','ativo','Ativo','2025-12-09','2026-12-09','Morno',null,null,'1997-05-24','@Dra.liviavasconcelos','Cirurgiã Oncológica','Maceió/ AL',true),
  ('Lucymaria Barros Dal Col Queiroz','lucymaria-bdc@hotmail.com','33999623052','Start Caio e Jordana','Ana Vitória','ativo','Ativo','2026-01-24','2027-01-24','Frio',null,null,'1988-11-04','@dra.lucymaria','Nutologia','Governador Valadares/MG',false),
  ('Luísa Guimarães Castelo Branco','luisacastelob2@hotmail.com','71999221107','Start Caio e Jordana','Ana Vitória','ativo','Ativo','2026-01-31','2027-01-31','Morno',null,null,'1996-07-11','@ginecoluisacastelo','Ginecologista','Salvador/BA',true),
  ('Luiz Fernando Cabral Rezende','luizfernandocabralrezende@hotmail.com','38991320587','Start Caio e Jordana','Ana Vitória','ativo','Ativo','2025-11-03','2026-11-03','Quente',null,null,'1993-05-20','@dr.luizfernando_cr','Medicina Família','Três Mariaas/MG',true),
  ('Marcos Vinícius Machado Viana','marvis.mv@gmail.com','98987035531','Start Caio e Jordana','Ana Vitória','ativo','Ativo','2025-11-10','2026-11-10','Morno',null,null,'1989-03-04','@drvinicius_mviana','Generalista','Santa Inês/MA',true),
  ('Marianny Barros Dal Col','mbdalcol@hotmail.com','27999784011','Start Caio e Jordana','Ana Vitória','ativo','Ativo','2026-01-24','2027-01-24','Frio',null,null,'1978-01-24','@dramariannydalcol','Ginecologista','Ecoporanga/ES',true),
  ('Mateus Facchin','drmateusfacchin@gmail.com','5499174186454991335301','Start Caio e Jordana','Ana Vitória','ativo','Ativo','2025-11-19','2026-11-19','Morno',null,null,'1977-09-12','@dr.mateusfacchin','Medico do esporte','Caxias do Sul/RS',true),
  ('MICHELE MARTINS FERRAZ','micheleferraz87@gmail.com','61999968698','Start Caio e Jordana','Ana Vitória','ativo','Ativo','2026-04-06','2027-04-06','Quente',null,null,null,'@dramicheleferraz','Endocrinologista','Formosa/GO',true),
  ('Nissrin Antar Mohammed','nis_mohammed@hotmail.com','67992634867','Start Caio e Jordana','Ana Vitória','ativo','Ativo','2025-12-18','2026-12-18','Frio',null,null,'1985-01-23','@niss_antar','Ginecologista','Corumbá/MS',true),
  ('Norma Nágime de Almeida','normanagime@yahoo.com.br','33999814501','Start Caio e Jordana','Ana Vitória','ativo','Ativo','2025-12-13','2026-12-13','Quente',null,null,'1977-01-07','@Dra_normanagime.endocrino','Endocrinologista','Governador Valadares/MG',false),
  ('Raimundo Vitoriano Correia Neto','vitorianoneto@gmail.com','85981892323','Start Caio e Jordana','Ana Vitória','ativo','Ativo','2026-01-15','2027-01-15','Quente',null,null,'1981-06-25','@dr.vitorianoneto','Endocrinologista','Obidos/PA',true),
  ('Renan Alves Garcia','drrenanagarcia@gmail.com','21975928919','Start Caio e Jordana','Ana Vitória','ativo','Ativo','2025-11-08','2026-11-08','Frio',null,null,'1994-09-17','@drrenan.garcia','Emagrecimento','Cabo Frio/ RJ',true),
  ('Roberta Peres Vieira de Melo','robertapvm@gmail.com','24981119076','Start Caio e Jordana','Ana Vitória','ativo','Ativo','2025-11-14','2026-11-14','Frio',null,null,'1981-03-25','@drarobertaperes','Dermatologista','Petrópolis/RJ',true),
  ('Romolo Guida','romolo.guida@gmail.com','21999826705','Start Caio e Jordana','Ana Vitória','ativo','Ativo','2025-11-09','2026-11-09','Quente',null,null,'1975-10-21','@romologuidaurologia','Urologista','Rio de Janeiro/RJ',false),
  ('SÉRGIO DA SILVA FERNANDES','sfcentermed@gmail.com','12996632333','Start Caio e Jordana','Ana Vitória','ativo','Ativo','2026-03-02','2027-03-02','Morno',null,null,'1978-08-16','@dr.sergiofernandes','Nutrologo','Ilhabela/SP',false),
  ('SOHAILA DALBIANCO YOUNES','sohailadalbianco@gmail.com','51997032440','Start Caio e Jordana','Ana Vitória','ativo','Ativo','2026-03-02','2027-03-02','Morno',null,null,'1988-11-21','@dra.sohailayounes','Medico do esporte','Porto Alegre/RS',false),
  ('Suzana Santos Ramos Alves','suzanasralves@gmail.com','92993953132','Start Caio e Jordana','Ana Vitória','ativo','Ativo','2025-11-05','2026-11-05','Frio',null,null,'1983-07-22',null,'Clico Geral','Amazonas/AM',true),
  ('Tatiane Nacif','dratatianenacif@gmail.com','33991483465','Start Caio e Jordana','Ana Vitória','ativo','Ativo','2025-10-27','2026-10-27','Morno',null,null,'1991-08-22','@dratatianenacif','Ginecologista','Caratinga/MG',false),
  ('Thaís Menezes Cardoso','thaismnzs@yahoo.com.br','91980167615','Start Caio e Jordana','Ana Vitória','ativo','Ativo','2026-04-01','2027-04-01','Morno',null,null,null,'@dra.thaismenezes','Ginecologista','Belem/PA',true),
  ('THAISA MARQUES DE LIMA BRAMUSSE','drathaisabramusse@gmail.com','31998898939','Start Caio e Jordana','Ana Vitória','ativo','Ativo','2026-03-02','2027-03-02','Morno',null,null,'1984-03-09','@drathaisa.bramusse','Emagrecimento','Belo Horinzonte/MG',true),
  ('Vanessa Cristina Lacerda','vanessalbrandao@gmail.com','3497905585','Start Caio e Jordana','Ana Vitória','ativo','Ativo','2025-10-24','2026-10-24','Frio',null,null,'1993-12-17','@vanessalacerda.gineco','Ginecologista','Patos de Minas/MG',false),
  ('Vanessa Rocha Pessoa','vanrochapessoa@hotmail.com','88996132346','Start Caio e Jordana','Ana Vitória','ativo','Ativo','2025-11-12','2026-11-12','Morno',null,null,'1983-12-10','@DRA.VANESSARPESSOA','Ginecologista','Eusébio/CE',false),
  ('Wendel Schramm Petrucio','wendel.petrucio@gmail.com','92991505006','Start Caio e Jordana','Ana Vitória','cancelado','Encerrou Mentoria','2025-11-19','2026-11-19','Frio',null,'PAUSADO',null,'@dr.wendelpetrucio','Ginecologista','Manaus/AM',false),
  ('Felipe de Paula Andrade','felipe_dipaula.a@hotmail.com','3291246206','Start Caio e Jordana','Ana Vitória','ativo','Ativo','2026-07-15','2027-07-15','Morno',null,null,'1985-08-03','dr.felipedepaulaandrade','Psiquiatra','Juiz de Fora/MG',true),
  ('Tércia Tarciane Soares de Sousa','dra.terciasousa.med@gmail.com/tercia_tarciane@hotmail.com','11964332872','Start Caio e Jordana','Ana Vitória','ativo','Ativo','2026-07-22','2027-07-22','Morno',null,null,'1985-01-24','@dra.terciasousa','Oncologista','São Paulo/SP',true),
  ('Mariana Muniz Spadini','mmunizspadini@gmail.com','11996039063','Start Caio e Jordana','Ana Vitória','ativo','Ativo','2026-08-03','2027-08-03','Morno',null,null,'1976-08-21','@marimunizderma','Dermatologista','São Paulo/SP',false),
  ('Ana Júlia Pereira Motta','aj_motta@hotmail.com','64999004821','Start Caio e Jordana','Ana Vitória','ativo','Ativo','2026-08-04','2027-08-04','Morno',null,null,'1990-11-07','@anajulia.ginecologista','Ginecologista','Catalão/GO',false),
  ('Carla Romagnoli de Arruda','contato@sincrovida.com.br','15997836881','Start Caio e Jordana','Ana Vitória','ativo','Ativo','2026-08-04','2027-08-04','Morno',null,null,'1980-01-20','@dracarlaromagnoli','Nefrologista','Botucatu/SP',false),
  ('Djeime da Rocha Benfica Ribeiro','dradjeime@gmail.com','11981091099','Start Caio e Jordana','Ana Vitória','ativo','Ativo','2026-08-10','2027-08-04','Morno',null,null,'1983-09-23','@dradjeime','Nutrologo','São Paulo/SP',true),
  ('Ronaldo Roberto Morari','ronaldomorari@gmail.com','96981453710','Start Caio e Jordana','Ana Vitória','ativo','Ativo','2026-08-06','2027-08-06','Morno',null,null,'1992-10-06','@drronaldomorari','Endocrinologista','Macapá/AP',false),
  ('Scheila da Silva','scheilasilva@yahoo.com.br','55996229308','Start Caio e Jordana','Ana Vitória','ativo','Ativo','2026-08-14','2027-08-14','Morno',null,null,'1978-07-27','@drascheilasilva','Ginecologista','Palmitinho/RS',true),
  ('Albino Paim Brandão','albinopaim4@outlook.com','75998525043','Start Caio e Jordana','Ana Vitória','ativo','Ativo','2026-08-15','2027-08-15','Morno',null,null,'1978-01-25','@medinfuse_feiradesantana, @albiclin','Neurologista','Feira de Santana/BA',true),
  ('Tascila Mary Amemiya Momoi','tascila74@gmail.com','11971126871','Start Caio e Jordana','Ana Vitória','ativo','Ativo','2026-08-10','2027-08-10','Morno',null,null,'1987-06-29','@dratascila','Ginecologista','São Jose dos Campos/SP',false),
  ('Thaís Abreu Santos Reggiani','thaisabreureggiani@gmail.com','31999420402','Start Caio e Jordana','Ana Vitória','ativo','Ativo','2026-08-10','2027-08-10','Morno',null,null,'1984-03-11','@drathaisabreureggiani','Ginecologista','Timóteo /MG',true),
  ('KETLIM PRISCILLA GONÇALVES POLLI','ketlimpriscilla@hotmail.com','69992170555','Start Caio e Jordana','Ana Vitória','ativo','Ativo','2026-08-12','2027-08-12','Morno',null,null,'1991-01-07','@dra.priscillapolli','Medica de Familia','Alta Floresta do Oeste/RO',false),
  ('Cristiano Juliani','c-juliani@hotmail.com','77999710011','Start Caio e Jordana','Ana Vitória','ativo','Ativo','2026-08-12','2027-08-12','Morno',null,null,'1977-09-08','drcristianojuliani','Ginecologista','Luis Eduardo Magalhães/BA',false),
  ('Gustavo Jambo Cantarelli','cantarelli@cmdiagnostica.com.br','82999972072','Start Caio e Jordana','Ana Vitória','ativo','Ativo','2026-08-20','2027-08-20','Frio',null,null,'1972-11-20','@Dr.Gustavocantarelli','Ginecologista','Maceió/ AL',false),
  ('Laura Esther de Sousa Amorim','esther-amorim@hotmail.com','32984679559','Start Caio e Jordana','Ana Vitória','ativo','Ativo','2026-08-31','2027-08-31','Morno',null,null,'1991-08-30','@dra.lauraestheramorim','Ginecologista','Ponte Nova/MG',false),
  ('Frederico Fernandes Chaves','dr.fredericofchaves@gmail.com','19971391255','Start Caio e Jordana','Ana Vitória','ativo','Ativo','2026-08-31','2027-08-31','Morno',null,null,'1990-01-19','@drfredericochaves','Generalista','São João da Boa Vista/SP',true),
  ('Karina Tiemi Costa Kakizaki','drakarinakakizaki@gmail.com','66999142210','Start Caio e Jordana','Ana Vitória','ativo','Ativo','2026-08-31','2027-08-31','Morno',null,null,'1986-10-22','@drakarinakakizaki','Clico Geral','Sinop/MT',true),
  ('Nayara Cibelly Alves Morais','nayaracibelly@gmail.com','62992082993','Start Caio e Jordana','Ana Vitória','ativo','Ativo','2026-09-02','2027-09-02','Morno',null,null,'1995-01-07','@dra.nayaracibelly','Nutrologo','Santa Rosa de Goias/GO',false),
  ('Marcela Brasil Ferreira','dramarcelabrasil@hotmail.com','3799073732','Start Caio e Jordana','Ana Vitória','ativo','Ativo','2026-09-02','2027-09-02','Morno',null,null,'1988-02-28','@dra.marcelabrasil','Nutrologo','Divinopolis/MG',false),
  ('Isabelle Maria de Queiroz Rampazzo do Carmo','isarampazzo@me.com','41999902829','Start Caio e Jordana','Ana Vitória','ativo','Ativo','2026-09-02','2027-09-02','Morno',null,null,'1985-08-12','@dra.isabellerampazzo','Ginecologista','Maringá/PR',false),
  ('Savio de Sousa Nobre','savionobree@hotmail.com','889996146204','Start Caio e Jordana','Ana Vitória','ativo','Ativo','2026-09-02','2027-09-02','Morno',null,null,'1994-03-30','@savionobre','Endoscopia','Guaraciaba do Norte/CE',false),
  ('ALMINO CARDOSO RAMOS','ramos.almino@gmail.com','11999840655','Surgical','Ana Vitória','ativo','Ativo','2026-01-30','2027-01-30','Morno',null,null,'1963-01-30','@dr.almino_ramos','Cirurgião Bariatrico','São Paulo/SP',false),
  ('BRUNO ROCHA MOTA','drbrunormota@bol.com.br','82999714219','Surgical','Ana Vitória','ativo','Ativo','2025-11-03','2026-11-03','Morno',null,null,'1979-07-20','@dr.brunomota','Cirurgião Bariatrico','Maceió/ AL',true),
  ('CINTHIA ALBUQUERQUE FEIJÓ','cinthiafeijo@hotmail.com','85981557077','Surgical','Ana Vitória','ativo','Ativo','2026-04-22','2027-04-22','Quente',null,null,'1986-09-27','@dra.cinthiafeijo','Nutrologa','João Pessoa/PB',true),
  ('CLAUDIO MATIAS BARROS JÚNIOR','claudio.pe91@gmail.com','99991663907','Surgical','Ana Vitória','ativo','Ativo','2025-10-30','2026-10-30','Morno',null,null,'1991-05-05','@claudiomatiasdigestiva','Cirurgião Bariatrico','Imperatriz/MA',false),
  ('EDMILSON GOMES DE OLIVEIRA FILHO','edgof@yahoo.com.br','83991219261','Surgical','Ana Vitória','ativo','Ativo','2026-04-02','2027-04-02','Morno',null,null,'1982-03-27','@dredfilho','Anestologista','João Pessoa/PB',false),
  ('GERLIANO MARÇAL DA LUZ GONÇALVES','gerlianom@gmail.com','28992756988','Surgical','Ana Vitória','ativo','Ativo','2026-01-13','2027-01-13','Morno',null,null,'1985-10-30','@gerliano','Cirurgião Bariatrico','Cachoeiro do Itapemerim/ES',false),
  ('GIORGIO ALFREDO PEDROSO BARETTA','giorgio.baretta@gmail.com','41991866677','Surgical','Ana Vitória','ativo','Ativo','2025-10-29','2026-10-29','Quente',null,null,'1977-06-06','@drgiorgiobaretta','Clinico Geral','Curitiba/PR',true),
  ('GUSTAVO MAGALHÃES COIMBRA','drgustavocoimbra@gmail.com','31998580505','Surgical','Ana Vitória','ativo','Ativo','2026-04-18','2027-04-18','Morno',null,null,'1989-06-18','@coimbragustavo','Cirurgião Geral','Belo Horizonte/MG',true),
  ('JEAN RICARDO NICARETA','faturamento@gastro-centro.com / jnicareta@uol.com.br//jnicareta@gmail.com','42988021614','Surgical','Ana Vitória','ativo','Ativo','2025-12-03','2026-12-03','Morno',null,null,'1975-04-25','@gastrocentroguarapuava','Cirurgião Bariatrico','Guarapuava/PR',false),
  ('JIMI SCARPARO','drjimi@scarparoscopia.com','11999219040','Surgical','Ana Vitória','ativo','Ativo','2026-04-13','2027-04-13','Quente',null,null,null,'@dr.jimiscarparo','Cirurgião Bariatrico','São Paulo/SP',true),
  ('JOSÉ APARECIDO VALADÃO','drvaladaoslz@gmail.com','98999733589','Surgical','Ana Vitória','ativo','Ativo','2026-01-20','2027-01-20','Morno',null,null,'1958-05-04','@dr_valadao','Cirurgião Bariatrico','São Luis/MA',false),
  ('JULLIANNY SCARPARO','jully.scarparo@gmail.com','11981798890','Surgical','Ana Vitória','ativo','Ativo','2026-04-13','2027-04-13','Morno',null,null,'1973-11-29','@drajuscarparo','Cirurgião Bariatrico','São Paulo/SP',true),
  ('Lucas Félix Rossi','drlucasrossi@gmail.com','51992821101','Surgical','Ana Vitória','ativo','Ativo','2026-06-19','2027-06-19','Morno',null,null,'1982-02-21','@drlucasrossi_obesidade','Cirurgião Bariatrico','Porto Alegre/RS',false),
  ('LUCIANA TEIXEIRA DE SIQUEIRA','lslucianasiqueira@gmail.com','81999484804','Surgical','Ana Vitória','cancelado','Encerrou Mentoria','2025-12-24','2026-12-24','Morno',null,'PAUSADO',null,'@dralusiqueira','Cirurgião Bariatrico','Recife /PE',false),
  ('MANOELA GALVÃO RAMOS','galvao.manoela@gmail.com','11996203363','Surgical','Ana Vitória','ativo','Ativo','2026-01-29','2027-01-29','Morno',null,null,'1972-04-12','@dramanoelagalvaoramos','Cirurgião Bariatrico','São Paulo/SP',true),
  ('MARCIO RAMOS SCHENATO','marcioschenato@gmail.com','46999752706','Surgical','Ana Vitória','ativo','Ativo','2025-11-03','2026-11-03','Quente',null,null,'1972-05-28','@marcio_schenato','Cirurgião Bariatrico','Francisco Beltrão/PR',true),
  ('MAYARA MAGRY ANDRADE MATIAS','mayaramasilva@hotmail.com//dramayaramagry@gmail.com','99991801222','Surgical','Ana Vitória','ativo','Ativo','2026-01-05','2027-01-05','Morno',null,null,'1989-03-15','@dramayaramagry','Cirurgião Bariatrico','Imperatriz/MA',false),
  ('PAULO VICTOR DE BARROS LIMA SANTOS','paulovblima@gmail.com','82981550908','Surgical','Ana Vitória','cancelado','Encerrou Mentoria','2026-01-12','2027-01-12','Frio',null,null,null,'@drpaulovictorlima','Cirurgião Bariatrico','Maceió/ AL',false),
  ('Raphael Torres Figueiredo de Lucena','raphael_torres@hotmail.com','11992532544','Surgical','Ana Vitória','ativo','Ativo','2026-05-25','2027-05-25','Morno',null,null,'1986-10-21','@dr.raphaellucena','Cirurgião Bariatrico','São Paulo/SP',true),
  ('TIAGO SZEGO','ttsbrasil@gmail.com','11981922576','Surgical','Ana Vitória','ativo','Ativo','2025-12-20','2026-12-20','Morno',null,null,'1981-06-18','@dr.tiagoszego','Cirurgião Bariatrico','São Paulo/SP',false),
  ('Vitor Araújo Vieira','vieira.vitor1@gmail.com','18997784142','Surgical','Ana Vitória','ativo','Ativo','2026-06-16','2027-06-16','Frio',null,null,'1996-07-16','@drvitor.vieira','Cirurgião Bariatrico','Curitiba/PR',true),
  ('Andreia Midori Matuoka Kataiama','andreiakataiama@gmail.com','11961109927','Surgical','Ana Vitória','ativo','Ativo','2026-08-06','2027-08-06','Frio',null,null,'1984-10-31','@dra.andreia_kataiama','cirurgião Bariatrico','São Paulo/SP',false),
  ('Talyta Soares de Vasconcelos Ramos','talytasv@gmail.com','84994063035','Surgical','Ana Vitória','ativo','Ativo','2026-09-09','2026-09-09','Frio',null,null,'1988-05-31','@dratalytavaaconcelos','cirurgião Bariatrico','Campina Grande/PB',false),
  ('Alessandra Candida Miranda','alessandracmiranda@icloud.com','34984105580','Start Regina e Twoany','Viviane','ativo','Ativo','2026-03-28','2027-03-28','Quente',null,null,'1994-01-11','@draalessandracmiranda','Nutróloga','Goiânia / GO e Uberaba /MG',false),
  ('Amanda Jessica Martins Faria','dramanda.go@hotmail.com','34991361216','Start Regina e Twoany','Viviane','ativo','Ativo','2026-08-17','2027-08-17','Morno',null,null,'1991-02-10','@dramanda.go','Ginecologista e Obstetra','São Gotardo / MG',false),
  ('Amanda Rezende Aarão','amanda_aarao@yahoo.com.br','27998004345','Start Regina e Twoany','Viviane','ativo','Ativo','2026-08-13','2027-08-13','Morno',null,null,'1983-04-22','@draamanda.cardiologista','Cardiologia e Nutrologia','Vitória / ES',false),
  ('Ana Carolina de Abreu Teixeira','aninhaabt@yahoo.com.br','31988120981','Start Regina e Twoany','Viviane','ativo','Ativo','2025-11-16','2026-11-16','Morno',null,null,'1987-09-21','@draanacarolinaab',null,null,true),
  ('Bruna Rafaela de Deus Lima','bumlima@hotmail.com','4196971913','Start Regina e Twoany','Viviane','ativo','Ativo','2025-11-10','2026-11-10','Morno','Renovado',null,'1981-05-20','@drabrunalimagineco','Ginecologista','Curitiba /PR',false),
  ('Camile Neves Cardoso','camilecardosoo@gmail.com','51981627979','Start Regina e Twoany','Viviane','ativo','Ativo','2026-05-08','2027-05-08','Morno',null,null,'1990-12-03','@dra_camilecardoso',null,null,false),
  ('Caroline Cassab Genaro Ortigosa','carolcassabgenaro@hotmail.com','11996118707','Start Regina e Twoany','Viviane','ativo','Ativo','2026-08-08','2027-08-08','Quente',null,null,'1987-09-10','@dracarolinecassab','Cardiologista','Rio Claro/ SP',false),
  ('Carolina Faria Migliorin Ribeiro','carolfariamiurim@hotmail.com','27999695035','Start Regina e Twoany','Viviane','ativo','Ativo','2026-02-12','2027-02-12','Quente',null,null,'1993-06-25','dracarolmigliorin','Ginecologista','Baixo Guandu/ ES e Resplendor / MG',false),
  ('Cybelle Bertoldo Santos Falcomer','cybertoldo@hotmail.com','61981379330','Start Regina e Twoany','Viviane','ativo','Ativo','2026-06-16','2027-06-16','Morno',null,null,'1986-01-15','@dracybellebertoldo','Ginecologista','Brasilia / DF',false),
  ('Danielle de Novais Alves','ddenovaisalves@gmail.com','71993597753','Start Regina e Twoany','Viviane','ativo','Ativo','2026-05-31','2027-05-31','Morno',null,null,'1996-10-12','@daniellenovais','Ginecologista','Salvador /BA',false),
  ('Djenifer Scheila Spohs','djeniferscheila@hotmail.com','45998518416','Start Regina e Twoany','Viviane','cancelado','Encerrou Mentoria','2025-12-06','2026-12-06','Não definida',null,'SAIU DA MENTORIA',null,'@dra.djeniferspohr',null,null,false),
  ('Elisa de Souza Lima','elisasouzalima@yahoo.com.br','27992469617','Start Regina e Twoany','Viviane','ativo','Ativo','2025-11-03','2026-11-03','Frio',null,null,'1986-04-15','@draelisa_gineco','Ginecologista','Vila Velha / ES',false),
  ('Emily Roberto Ribeiro da Silva','emimax_babii@hotmail.com','69999221511','Start Regina e Twoany','Viviane','ativo','Ativo','2025-11-26','2026-11-26','Frio',null,null,'1988-11-04','draemilyribeiros',null,'Rolim de Moura / RO',false),
  ('Fernanda de Castro Roque','fernanda.c.roque@hotmail.com','27992966451','Start Regina e Twoany','Viviane','ativo','Ativo','2026-01-26','2027-01-26','Morno',null,null,'2026-03-19','@drafernandaroque','Ginecologista','Vila Velha / ES',true),
  ('Flávia da Cunha Monteiro de Barros','dra_flaviamonteiro@hotmail.com','65996320857','Start Regina e Twoany','Viviane','ativo','Ativo','2026-01-13','2027-01-13','Frio',null,null,'1986-01-08','@dra_flaviamonteiro','Oftalmologia','Rio Claro/ SP',false),
  ('Gabriela Weber da Silva','gabi_webers@hotmail.com','48991902110','Start Regina e Twoany','Viviane','ativo','Ativo','2026-03-02','2027-03-02','Quente',null,null,'1974-10-21','dragabrielaweber','Ginecologista','Tubarão / SC',false),
  ('Gisela Machado Altoe','gisela_altoe@hotmail.com','28999716821','Start Regina e Twoany','Viviane','ativo','Ativo','2026-08-11','2027-08-11','Quente',null,null,'1994-01-11','@dragisela.altoe','Gineco, obstetra e nutróloga','Vargem Alta / ES',false),
  ('Iuri Romanov Batista de Oliveira','driuriromanov@gmail.com','27981143974','Start Regina e Twoany','Viviane','ativo','Ativo','2026-02-10','2027-02-10','Quente','Renovado',null,'1992-07-20','@driuriromanov','Nutrologia','Colatina / ES',false),
  ('Junny Belache de Azeredo Coutinho','junnybelache@hotmail.com','21983239580','Start Regina e Twoany','Viviane','ativo','Ativo','2025-12-09','2026-12-09','Quente','Renovado',null,'1977-09-04','@drajunnybelache','Nutrologia','Rio de Janeiro/RJ',false),
  ('Lara Maria Vilaça de Figueiredo','lara_figueiredo4@hotmail.com','84999434649','Start Regina e Twoany','Viviane','ativo','Ativo','2026-06-15','2027-06-15','Quente',null,null,'1993-02-26','@dralaravfigueiredo','Nutrologia','Mossoró/ RN',false),
  ('Larissa Azevedo Costa','dra.larissaazevedo@gmail.com','63981179125','Start Regina e Twoany','Viviane','ativo','Ativo','2025-12-21','2026-12-21','Quente','Renovado',null,'1987-09-08','@dra.larissazevedo','Cirurgiã Vascular','Aracaju/ SE',false),
  ('Layane Ferreira','layaneferreirab@gmail.com','9591145142','Start Regina e Twoany','Viviane','ativo','Ativo','2025-10-28','2026-10-28','Frio',null,null,'1990-11-10','@dra_layaneferreira',null,'Boa Vista/ RR',false),
  ('Leticia Buzacarini Alvim','leticia.b.alvim@gmail.com','15991365106','Start Regina e Twoany','Viviane','ativo','Ativo','2026-02-26','2027-02-26','Morno',null,null,'1996-10-16','@draleticiaalvim','Endocrinologista','Boituva/ SP',false),
  ('Lizarda Maria de Carvalho Félix','lizardamed@hotmail.com','82991720520','Start Regina e Twoany','Viviane','ativo','Ativo','2026-01-15','2027-01-15','Quente',null,null,'2026-06-30','@dra.lizardafelix','Ginecologista','Maceió/AL',false),
  ('Luan Tagiaroli Florio','luan.tagiaroli.f@gmail.com','11997135482','Start Regina e Twoany','Viviane','ativo','Ativo','2025-11-17','2026-11-17','Morno','Renovado',null,'1993-05-26','@drluanflorio','Nutrólogo','São Paulo/ SP',false),
  ('Luana Alegre Félix','dra.luanaalegrefelix@gmail.com','18981206461','Start Regina e Twoany','Viviane','ativo','Ativo','2026-06-30','2027-06-30','Morno',null,null,'1994-05-13','@draluanaafelix','Endocrinologista','Ribeirão Preto/ SP',false),
  ('Luciana Ximenes Bonani Alvim Brito','ximenes_luciana@hotmail.com','22988085580','Start Regina e Twoany','Viviane','ativo','Ativo','2026-01-09','2027-01-09','Quente',null,null,'2026-08-27','dra.lucianaximenes','Gineco e Obstetra','Itaperuna/ RJ',false),
  ('Maria Luísa de Oliveira Gomes','marialuisagomes23@hotmail.com','27997613066','Start Regina e Twoany','Viviane','ativo','Ativo','2026-08-02','2027-08-02','Frio',null,null,'1997-01-23','@dramarialuisagomes','Endocrinologista','Barra de São Francisco/ ES',false),
  ('Mariam Viviane Jovino Neves','dramariamviviane@gmail.com','61981188806','Start Regina e Twoany','Viviane','ativo','Ativo','2026-03-11','2027-03-11','Quente',null,null,'1987-03-16','@dramariamviviane','Ginecologista','Brasília/ DF',false),
  ('Mateus Louis Rodrigues Cavalcante','cmateusr@gmail.com','48998221616','Start Regina e Twoany','Viviane','ativo','Ativo','2026-02-27','2027-02-27','Morno',null,null,'1995-03-16','@drmateuslouis',null,null,true),
  ('Matheus Ferrari','mahteusferrari@gmail.com','7599103232','Start Regina e Twoany','Viviane','ativo','Ativo','2025-10-07','2026-10-07','Morno',null,null,'1997-06-22','@dr.matheusferrari','Endocrinologia','Uberlândia/ MG',false),
  ('Naiara Fumagalli de Souza Wey','naiara_fumagalli@yahoo.com.br','15981173993','Start Regina e Twoany','Viviane','ativo','Ativo','2026-08-13','2027-08-13','Morno',null,null,'1983-08-10','@dra.naiarafumagalli','Ginecologista','Sorocaba/ SP',false),
  ('Nadhine Calheiros Marques Luz','nadhinecalheiros@outlook.com','82999283906','Start Regina e Twoany','Viviane','ativo','Ativo','2026-02-13','2027-02-13','Frio',null,null,'1996-05-18','@dranadhinecalheiros','Nutrologia','Maceió/ AL',false),
  ('Odilson Simões Nascimento Junior','osnjunior@hotmail.com','27998705953','Start Regina e Twoany','Viviane','ativo','Ativo','2026-01-26','2027-01-26','Morno',null,null,'1984-01-13','@dr.odilsonsimoes','Ginecologista','Colatina/ ES',false),
  ('Roberto Braga Madruga','rbmadruga@gmail.com','21999156150','Start Regina e Twoany','Viviane','ativo','Ativo','2026-07-11','2027-07-11','Frio',null,null,'1979-09-21','@dr.robertomadruga','Gineco e obstetra','Rio de Janeiro/ RJ',false),
  ('Rodrigo Leal de Jesus','rodrigoljalves@gmail.com','11956020050','Start Regina e Twoany','Viviane','ativo','Ativo','2025-11-10','2026-11-10','Morno','Renovado',null,'1987-01-04','@dr.rodrigojesus','Endocrinologia','Barueri / SP',false),
  ('Sandra Takaki França','drsandrapersonal@gmail.com','19997722808','Start Regina e Twoany','Viviane','ativo','Ativo','2026-08-10','2027-08-10','Morno',null,null,'1963-09-05','@clinicadra.sandrafranca','Ginecologista','Paulínia / SP',false),
  ('Samara de Souza Zanin','sszanindra@gmail.com','11983647371','Start Regina e Twoany','Viviane','ativo','Ativo','2025-10-28','2026-10-28','Morno',null,null,'1988-08-18','@dra.samarazanin','Endocrinologia','São Paulo/ SP',false),
  ('Tamiris Giacomin Pralon','tamiris.giacomin@gmail.com','27999090278','Start Regina e Twoany','Viviane','ativo','Ativo','2025-11-05','2026-11-05','Morno',null,null,'1987-08-25','@dra_tamirisgiacomin',null,null,false),
  ('Tatiane Fernandes Vieira','tatianefernandesv@gmail.com','18997405378','Start Regina e Twoany','Viviane','ativo','Ativo','2025-11-28','2026-11-28','Morno',null,null,'1989-07-07','@tatianefvieira',null,null,false),
  ('Tayna Sanches Santiago','taynasantiago7618@gmail.com','67991103737','Start Regina e Twoany','Viviane','ativo','Ativo','2025-12-16','2026-12-16','Quente',null,null,'1989-02-23','@drataynasantiago','Pediatria','Campo Grande/ MS',false),
  ('Thais Cassaro','drathaiscassaroadm@gmail.com','27981111131','Start Regina e Twoany','Viviane','ativo','Ativo','2026-05-15','2027-05-15','Quente',null,null,'1988-01-25','@drathaiscassaro','Gineco e obstetra','Aracruz/ ES',false),
  ('Thais Mendes de Morais Serafim','drathaismendess@gmail.com','71992470549','Start Regina e Twoany','Viviane','ativo','Ativo','2026-07-18','2027-07-18','Quente',null,null,'1992-12-06','@drathaismendess','Ginecologista','Feira de Santana / BA',false),
  ('Vaneska Fleury','vaneska37@gmail.com','11973615425','Start Regina e Twoany','Viviane','cancelado','Encerrou Mentoria','2026-04-09','2027-04-09','Frio',null,'SAIU DA MENTORIA',null,'@dravaneskafleur',null,null,false),
  ('Vinicius Correa','vcorreamed97@gmail.com','12991714576','Start Regina e Twoany','Viviane','ativo','Ativo','2026-02-12','2027-02-12','Frio',null,null,'1980-02-09','@drviniciusnutrologia','Nutrólogo','São José dos Campos/ SP',false),
  ('Vitor Kern','vitoorkern@gmail.com','51997976788','Start Regina e Twoany','Viviane','cancelado','Encerrou Mentoria','2025-12-23','2026-12-23','Não definida',null,'SAIU DA MENTORIA',null,'@dr.vitorkern',null,null,false),
  ('Yara Trigo Martinez','yaratrigo@hotmail.com','27995771727','Start Regina e Twoany','Viviane','ativo','Ativo','2025-12-09','2026-12-09','Morno',null,null,'2026-08-13','@dra.yaratrigo.gineco','Ginecologista','Vitória/ ES',false),
  ('Aguinaldo José Soares Filho','aguinaldojsfilho@gmail.com','63999206006','Ativação','Evelyn','ativo','Ativo','2026-02-24','2027-02-24','Quente','Renovado',null,'1989-08-14','draaguinaldofilho','Anestesia e dor','Palmas TO',true),
  ('Aloisio Lourenço de Carvalho Neto','alo_jere@hotmail.com','79998435130','Ativação','Evelyn','ativo','Ativo','2026-04-29','2027-04-29','Quente','Renovado',null,'1997-01-21','aloisiocarvalho1','Médico Generalista','Paulo Afonso Bahia',true),
  ('Amanda Nercolini Medeiros','amandanercolini@gmail.com','55996240616','Ativação','Evelyn','ativo','Ativo','2026-07-20','2027-07-20','Quente','Renovado',null,'1995-12-30','dra.amandanmedeiros',null,null,true),
  ('Amanda Pereira De Oliveira','amandamed10@gmail.com','11955594847','Ativação','Evelyn','ativo','Ativo','2026-02-24','2027-02-24','Quente','Renovado',null,'1991-07-09','@draamandaoliveirago',null,null,true),
  ('Ana Flávia Von Eicheendorff','dra.ana.flavia@hotmail.com','65981328683','Ativação','Evelyn','ativo','Ativo','2026-03-03','2027-03-03','Morno','Renovado',null,'1987-12-02','@doutoraanaflavia',null,null,false),
  ('Analiana Alencar Arrais de Souza','analianaarrais@gmail.com','8586890466','Ativação','Evelyn','ativo','Ativo','2026-05-22','2027-05-22','Morno','Renovado',null,'1966-12-17','draanalianaarrais','Ginecologista com foco em mulheres 35+ e ginecologista regenerativa','Fortaleza/Ceara',true),
  ('André Luiz Baylão','algaviao@hotmail.com','6281153890','Ativação','Evelyn','ativo','Ativo','2026-05-21','2027-05-21','Quente','Renovado',null,'1963-02-25','drandrebaylao','Ginecologia e Nutrologia(Clinica Afeto)','Goiânia- Goias',true),
  ('Andreza Libéria Oliveira Diniz','andrezadinizbh@hotmail.com','32999953654','Ativação','Evelyn','ativo','Ativo','2026-05-23','2027-05-23','Morno','Renovado',null,'1984-03-09','dra.andrezalodiniz',null,null,false),
  ('Bibiana Del Monaco Silva Misumi','dra.bibianamisumi@gmail.com','12997177113','Ativação','Evelyn','ativo','Ativo','2026-05-20','2027-05-20','Quente','Renovado',null,'1979-11-29','drabibianamisumi','Ginegologista','São José dos Campos, SP,',true),
  ('Bruno Souza de Faria','brunosouzafaria94@gmail.com','61993049242','Ativação','Evelyn','ativo','Ativo','2026-08-15','2027-08-15','Quente','Renovado',null,'1994-04-29','@dr.brunosouzadf','Ginecologia, obstetrícia e Ultrassonografia','Brasília',false),
  ('Caio Cesar  Galvão Cunha Cordeiro','caiocordeiro14@hotmail.com','81994625810','Ativação','Evelyn','ativo','Ativo','2026-02-25','2027-02-25','Quente','Renovado',null,'1997-04-14','@drcaiogalvao','Emagrecimento e Reposição Hormonal','Maceió AL',true),
  ('Camila araujo oliveira','camilaaraujooliveira@yahoo.com.br','38997390505','Ativação','Evelyn','ativo','Ativo','2026-02-19','2027-02-19','Morno','Renovado',null,'1993-06-03','@dra.camilaaraujoo','Nutrologa','Montes Claros MG',true),
  ('Camila Junquilho Zatta','camilazattaa@gmail.com','27981550134','Ativação','Evelyn','ativo','Ativo','2026-03-06','2027-03-06','Quente','Renovado',null,'1997-12-30','@camilazatta','Nutrologa','Vitoria ES',true),
  ('Daiane Lorena Nogueira','dailorenago@gmail.com','61992544954','Ativação','Evelyn','ativo','Ativo','2026-02-06','2027-02-06','Quente','Renovado',null,'1985-07-30','@dradaianelorena','Ginecologista','Brasilia- DF',false),
  ('Daniel Tomaz Lopes','dtlopes@gmail.com','67999084301','Ativação','Evelyn','ativo','Ativo','2026-03-14','2027-03-14','Quente','Renovado',null,'1977-10-28','@Drdanieltomqzlopes',null,null,false),
  ('Estela Simone R Dal Ben','esteladalben@gmail.com','51992278615','Ativação','Evelyn','ativo','Ativo','2026-03-07','2027-03-07','Quente','Renovado',null,'1967-09-03','@dra.esteladalben','Ginecologista e Obstetra','Porto Alegre - RS',true),
  ('Fernanda Ferreira Palhares Macedo','fernanda_palhares@yahoo.com.br','63992050990','Ativação','Evelyn','ativo','Ativo','2026-05-20','2027-05-20','Quente','Renovado',null,'1988-10-01','drafernandapalhares','Ginegologista','Araguaína-TO',true),
  ('Flavia H Csizmar','flavinhahcsi@hotmail.com','11982727313','Ativação','Evelyn','ativo','Ativo','2026-03-05','2027-03-05','Morno','Renovado',null,null,'@draflaviacsizmar','Nutrologa e Medicina Preventiva','Santo André SP',false),
  ('Gabriel Manea Comerio','gabriel_comerio@hotmail.com','27999701921','Ativação','Evelyn','ativo','Ativo','2026-04-21','2027-04-21','Quente','Renovado',null,null,'@gabrielcomerio',null,null,true),
  ('Genia Pithon Barreto','geniapithon@outlook.com','11993052441','Ativação','Evelyn','ativo','Ativo','2026-03-16','2027-03-16','Quente','Renovado',null,'1975-10-05','@drageniapithon','Nutrologia  e Endocrinologia','São Paulo - Vila Olímpia e Morumbi',false),
  ('Gisele Fernanda Sanchez','ginandasanchez@gmail.com','65998151711','Ativação','Evelyn','ativo','Ativo','2026-02-25','2027-02-25','Quente','Renovado',null,'1983-11-19','Dra.giselesanchez','Clínica geral: pós em Medicina de saúde da família, Perita Federal (sai dos desses vínculos) Pós graduação em Nutrologia e medicina funcional integrativa','Tangará da Serra-MT',true),
  ('Gisele Motta Elias Martins','giselemotta@uol.com.br','11981985078','Ativação','Evelyn','ativo','Ativo','2026-02-24','2027-02-24','Quente','Renovado',null,'1977-03-16','@dragiselemotta','Endocrinologista','Guarulhos- SP',true),
  ('Isabela Gomes Alves Munhoz','munhoz.iga88@gmail.com','82996204121','Ativação','Evelyn','ativo','Ativo','2026-02-24','2027-02-24','Quente','Renovado',null,'1988-05-10','@belinha88_al','Clinica Medica','Maceio Alagoas',true),
  ('Ítalo Gonçalo Matias Vilasbôas','italo.gmv@gmail.com','71991827013','Ativação','Evelyn','ativo','Ativo','2026-09-18','2027-09-18','Quente',null,null,'1993-08-28','italo_vilasboas','Ginecologista e Obstetra','Salvador',false),
  ('Josélia Lima Nunes Carvalhaes','nunesjoselia@gmail.com','61992985875','Ativação','Evelyn','ativo','Ativo','2026-02-25','2027-02-25','Quente','Renovado',null,'1978-05-13','@dra.joseliacarvalhaes','Ginecologista e Mastologista, com foco em Climatério e Menopausa','Bralisia-DF',true),
  ('Juliana Fernanda Meyer','dra.julianameyer@gmail.com','19996801518','Ativação','Evelyn','ativo','Ativo','2026-04-02','2027-04-02','Quente','Renovado',null,'1984-05-26','@drajulianameyer','Endocrinologia e Medicina Integrativa','Campinas- SP',true),
  ('Julio Cesar De Luca Filho','juliocesardelucafilho@gmail.com','4899894096','Ativação','Evelyn','ativo','Ativo','2026-02-19','2027-02-19','Frio','Renovado',null,null,'drjuliodeluca',null,null,false),
  ('Karenn Rocha','karennrocha@hotmail.com','92982819441','Ativação','Evelyn','ativo','Ativo','2026-04-03','2027-04-03','Quente','Renovado',null,'1994-02-20','@karennrocha','Medicina do Esporte','Manaus - AM',true),
  ('Karina Monique Santos Alves Nunes Torres','karinamoniquea@hotmail.com','87981101212','Ativação','Evelyn','ativo','Ativo','2026-02-06','2027-02-06','Morno','Renovado',null,'1996-11-25','@dra.karinamoniques','Médica generalista','Petrolina-PE',true),
  ('Larissa Papst Novaes Guedes','papst.lari@gmail.com','11954193113','Ativação','Evelyn','ativo','Ativo','2026-06-04','2027-06-04','Morno','Renovado',null,'1989-09-28','@laripapst','Emagrecimento, saude metabólica e procedimento de estética','Brooklin',false),
  ('Laylla Kristyna Rezende Breve','layllabreve@gmail.com','38992297111','Ativação','Evelyn','ativo','Ativo','2026-05-20','2027-05-20','Quente','Renovado',null,'1993-08-19','dralayllabreve','Ginecologista','Brasilia',false),
  ('Livia escobar siqueira','liviaescobar16@gmail.com','11982010516','Ativação','Evelyn','ativo','Ativo','2026-02-18','2027-02-18','Quente','Renovado',null,'2001-03-16','@draliviaescobar','Nutrologia e Medicina Integrativa','São Pulo /Alphaville',true),
  ('Luana Mayara de Lima','luana_limalima@outlook.com','67998225958','Ativação','Evelyn','ativo','Ativo',null,null,'Quente','Renovado',null,'1989-05-09','dra.luanalimaa','Nutrologia','Ivinhema MS',true),
  ('Luanna Gabrielle Vieira Leite','luannagvleitec@gmail.com','87999973800','Ativação','Evelyn','ativo','Ativo','2026-02-24','2027-02-24','Morno','Renovado',null,'1994-05-03','draluannaleite','Pós graduação Endocrinologia','Petrolina- PE',false),
  ('Lucas Almeida Campagnaro','drlucas_a_campagnaro@gmail.com','27981468221','Ativação','Evelyn','ativo','Ativo','2026-02-25','2027-02-25','Quente','Renovado',null,'1998-10-19','drlucascampagnaro','Ortopedia e traumatologia Medicina esporte Nutrologia','Venda nova do imigrante - ES',true),
  ('Lucas Martins De Almeida','drlucasma1994@gmail.com','79991199999','Ativação','Evelyn','ativo','Ativo','2026-04-18','2027-04-18','Morno','Renovado',null,'1994-12-09','drlucas.martins',null,null,false),
  ('Ludimila Queiroz Oliveira','ludi.med@gmail.com','62981309412','Ativação','Evelyn','ativo','Ativo','2026-03-13','2027-03-13','Quente','Renovado',null,null,'Dra.ludimilaqueirox',null,null,false),
  ('Luise Ávila Da Silva Pinto','dra.luisevila@gmail.com','55999691558','Ativação','Evelyn','ativo','Ativo','2026-02-24','2027-02-24','Morno','Renovado',null,'1996-11-09','@dra.luiseavila',null,null,true),
  ('Marcos Roberto Caetano','drcaetano7@yahoo.com.br','19996104434','Ativação','Evelyn','ativo','Ativo','2026-04-13','2027-04-13','Quente','Renovado',null,'1972-10-16','@drmarcoscaetano','Ginecologia','Região Metropolitana de Campinas-SP',true),
  ('Maria Gertrudes Ouriques Teles','ggertrudesouriquesteles@gmail.com','88996130061','Ativação','Evelyn','ativo','Ativo','2026-08-12','2027-08-12','Quente','Renovado',null,'2026-08-06','@gertrudesourique','Ginecologista focado em menopausa e emagrecimento','Sobral- CE',true),
  ('Maria Isabel Navarro Muccillo','mariaisabel.consultorio@gmail.com','11972779734','Ativação','Evelyn','ativo','Ativo','2026-05-20','2027-05-20','Quente','Renovado',null,'1982-08-19','@mariaisabel.muccillo','Ginegologista','Moema- SP',true),
  ('Nilson Da Cruz Santos Júnior','jutaio@hotmail.com','38991286443','Ativação','Evelyn','ativo','Ativo','2026-02-24','2027-02-24','Quente','Renovado',null,'1986-12-04','@nilsoncsjunior','Medicina Esportiva','Taiobeiras MG',true),
  ('Paola Lobo Muniz','paolalmuniz@hotmail.com','4198882888','Ativação','Evelyn','ativo','Ativo','2026-02-24','2027-02-24','Quente','Renovado',null,'1992-05-29','@drapaolalobomuniz','endocrinologista','maringa Pr',true),
  ('Patricia Moraes Vilela Rezende','drapatriciarezende@gmail.com','62992354457','Ativação','Evelyn','ativo','Ativo','2026-02-25','2027-02-25','Morno','Renovado',null,'2026-10-28','@dra.patriciamvrezende','Obesidade e Medicina Integrativa','Caiapônia- GO',true),
  ('Pedro Ivo Santos Aranas','piaranas@gmail.com','16997060667','Ativação','Evelyn','ativo','Ativo','2026-04-14','2027-04-14','Quente','Renovado',null,null,'@dr.pedroivoaranas','Medicina do Espote e Ginecologia Endócrina','Ribeirão Preto- SP',true),
  ('Rafaelly Duarte','rafaelly.rd@gmail.com','88996120817','Ativação','Evelyn','ativo','Ativo','2026-02-12','2027-02-12','Morno','Renovado',null,'1992-07-04','@drarafaellydf','Ginecologia e Obstetricia','Fortaleza-CE',true),
  ('Silvana Valdemarin Alves','silviaval13@gmail.com','11993124704','Ativação','Evelyn','ativo','Ativo','2026-07-30','2027-07-30','Quente','Renovado',null,'1974-07-13','drasilviavaldemarin','Nutrologa','Jardins - SP',true),
  ('Sinara Maria de Castro','drasinaracastro@yahoo.com.br','62981857459','Ativação','Evelyn','ativo','Ativo','2026-02-25','2027-02-25','Quente','Renovado',null,null,'drasinara_castro','Ginegologista','Goiânia Goiás',true),
  ('Sofia Gonçalves Pereira','drasofiagpereira@gmail.com','21981184778','Ativação','Evelyn','ativo','Ativo','2026-02-24','2027-02-24','Quente','Renovado',null,'1988-11-10','@dra_sofiapereira','Endocrinologia','Rio de Janeiro',false),
  ('Sonia Gasparoni','soniagasparoni.endocrino@gmail.com','48999628448','Ativação','Evelyn','ativo','Ativo','2026-02-27','2027-02-27','Quente','Renovado',null,'1980-02-04','@drasoniagasparoni',null,null,false),
  ('Tatiana Lauria dos Santos Costa','tati_lauria@hotmail.com','21979413981','Ativação','Evelyn','ativo','Ativo','2026-06-18','2027-06-18','Frio','Renovado',null,'1984-06-06','@dratatianalauria','Ginecologia / regenerativa /endoscopia ginecológica','Rio de Janeiro',true),
  ('Thania Ferreira Rodrigues Cunha','thaniacunha@yahoo.com.br','34999421126','Ativação','Evelyn','ativo','Ativo','2026-02-24','2027-02-24','Quente','Renovado',null,'1981-12-13','@drathaniacunha','Ginecologista','Uberlândia MG',true),
  ('Tuanny Canedo Costa','tuannycanedo@gmail.com','89999074990','Ativação','Evelyn','ativo','Ativo','2026-02-25','2027-02-25','Quente','Renovado',null,'1987-11-06','Dra tuannycanedo','Ginecologista','São João do Piauí',true),
  ('Victor Rodrigues da Silva','victorsilva43@gmail.com','27996334371','Ativação','Evelyn','ativo','Ativo','2026-07-27','2027-07-27','Quente','Renovado',null,null,'victor.ord','ainda não tem','colatina Espírito Santo',true),
  ('Vilson Luiz Maciel','vilsonlm@hotmail.com','48999471686','Ativação','Evelyn','ativo','Ativo','2026-04-14','2027-04-14','Quente','Renovado',null,null,'@vilson.ginecologista','Ginecologista e Fertileuta, especialista em Reprodução Assistida pela Febrasgo(Crifert)','Criciúma/SC',true),
  ('Walter José Pitman Machado Da Silva','walterpitman@gmail.com','99992020022','Ativação','Evelyn','ativo','Ativo','2026-02-24','2027-02-24','Quente','Renovado',null,null,'dr.walterpitman',null,null,true),
  ('Wanessa Neves Stival','drawanessastival@gmail.com','61992534646','Ativação','Evelyn','ativo','Ativo','2026-04-14','2027-04-14','Morno','Renovado',null,'1990-12-20','drawanessastival.endocrino','Endocrinologista','Brasília',true),
  ('Wilton Mario Gomes','gomeswilton50@yahoo.com','94991839827','Ativação','Evelyn','ativo','Ativo','2026-02-28','2027-02-28','Quente','Renovado',null,'1956-12-20','Wilton w1',null,null,true),
  ('Poliana Andrade Santos Armelau','poliandrade15@hotmail.com','21999891821','Ativação','Evelyn','ativo','Ativo','2026-08-31','2027-08-31','Quente','Renovado',null,'1976-02-15','@drapoliana.andrade','Ginecologia','Rio de Janeiro',true),
  ('Alícia Christiane Imada de Oliveira','aliciacimada@gmail.com','21981856942','Ativação','Evelyn','ativo','Ativo','2026-09-02','2027-09-02','Quente','Renovado',null,'1987-08-04','draaliciaimada','Nefrologista e Nutróloga','Rio de janeiro',true),
  ('Mariana Barbosa Gregolini','mari.gregolini@gmail.com','11985617978','Mentoria Mãe','Evelyn','ativo','Ativo','2025-04-22','2027-04-22','Quente','Renovado',null,'1991-07-08','https://www.instagram.com/dramarianagregolini?igsh=bDU2Y21qZXIzdWUx',null,null,false),
  ('Naor Rios Passos','riosnaor@gmail.com','7199068561','Mentoria Mãe','Evelyn','ativo','Ativo','2025-04-10','2026-04-10','Frio','Em negociação','ARI TA RESOLVENDO','1997-02-25','https://www.instagram.com/drnaorrios?igsh=c3J0amRhc2x3OHY4',null,null,false),
  ('Begoña García Wicks','begwicks@uol.com.br','71991125470','Mentoria Mãe','Evelyn','ativo','Ativo','2026-08-03','2027-08-03','Quente','Renovado','CLIENTE NOVO',null,'@begwicks',null,null,true),
  ('Thayse Priscila Casagrande','thaysec@gmail.com','43999307493','Mentoria Mãe','Evelyn','ativo','Ativo','2026-08-03','2027-08-03','Quente','Renovado','CLIENTE NOVO',null,'@drathaysecasagrande',null,null,false),
  ('Amisbele Angelucci','amisbele@gmail.com','14997754500','Mentoria Mãe','Evelyn','ativo','Ativo','2026-08-07','2027-08-07','Quente','Renovado','CLIENTE NOVO','1972-11-21','em construção',null,null,true),
  ('ANÍBAL DA TORRE BOGOSSIAN','drbogos61@hotmail.com','21999844606','Mentoria Mãe','Evelyn','ativo','Ativo','2026-08-02','2027-08-02','Quente','Renovado','CLIENTE NOVO','1961-09-20','@dr.anibalbogossian',null,null,true),
  ('Fabiano Winckler','financeiro@nucleofw.com','49991679982','Mentoria Mãe','Evelyn','ativo','Ativo','2025-07-07','2026-07-07','Quente','Em negociação','ARI TA RESOLVENDO','1978-10-04','@fawinckler',null,null,true),
  ('Mayara Bega Freitas Veloza','mayveloza@hotmail.com','119982378401','Mentoria Mãe','Evelyn','ativo','Ativo','2026-05-15','2027-05-15','Quente','Renovado',null,'1988-03-04','mayveloza',null,null,true),
  ('Bárbara Castro Muniz Xisto','barbaracastromuniz@gmail.com','5577981363807','Mentoria Mãe','Evelyn','ativo','Ativo','2025-10-11','2026-10-11','Morno','Em negociação','ARI TA RESOLVENDO','1996-09-19','drabarbaracmuniz',null,null,true),
  ('Eduardo Alencar Viana e Silva','eduardoalencar_duda@hotmail.com','5568999990606','Mentoria Mãe','Evelyn','ativo','Ativo','2024-10-16','2027-08-13','Morno','Renovado','Renovou com a Vitoria','1998-03-07','@dr.eduardoalencar',null,null,true),
  ('Daniela Moreira','danielamra@hotmail.com','5511999173789','Mentoria Mãe','Evelyn','ativo','Ativo','2026-05-08','2027-05-08','Quente','Renovado',null,'1974-12-12','danielamoreira_dra',null,null,true),
  ('Afra Maria Mendes Barbosa','consultorioafra@gmail.com','5582991190635','Mentoria Mãe','Evelyn','ativo','Ativo','2025-07-13','2027-06-30','Quente','Renovado',null,'1964-09-26','https://www.instagram.com/draafrabarbosa?igsh=MWhsMXYxODI2ZjJvZA==',null,null,true),
  ('Gardenia Cenci','gardcenci@gmail.com','61999526170','Mentoria Mãe','Evelyn','ativo','Ativo','2026-08-03','2027-08-03','Quente','Renovado','CLIENTE NOVO','1985-08-06','@dragardeniacenci',null,null,true),
  ('Jeane Doffiny Bogossian','clinicabogossian@hotmaill.com','21999163049','Mentoria Mãe','Evelyn','ativo','Ativo','2025-08-31','2027-08-02','Quente','Renovado',null,'1967-09-14','@dra.jeanebogossian',null,null,true),
  ('Fernanda Ferraz Costa','ferrazfc@hotmail.com','719992867345','Mentoria Mãe','Evelyn','ativo','Ativo','2024-11-27','2026-11-27','Quente','Renovado','Renovou com a Thabata no evento','1995-02-23','https://www.instagram.com/fferraz.dra?igsh=azFsMTd5cXpseDY1',null,null,false),
  ('Bruno Rocha Peixoto','drbrunopeixoto1@gmail.com','5511913177762','Mentoria Mãe','Evelyn','ativo','Ativo','2025-08-31','2027-08-02','Quente','Renovado','Renovou',null,'drbrunopeixoto1',null,null,false),
  ('Ana Valéria Ramirez','anaramirez@terra.com.br','5517981153000','Mentoria Mãe','Evelyn','ativo','Ativo','2025-08-24','2027-09-03','Quente','Renovado','Renovou com a Vitoria dia 03/09/26','2026-04-22','dra.anavalerianutrologa',null,null,true),
  ('Carmen Maria de Araújo Lima','carmenaraujolima@hotmail.com','31999198613','Mentoria Mãe','Evelyn','ativo','Ativo','2026-08-03','2027-08-03','Quente','Renovado','CLIENTE NOVO','1977-12-03','@dracarmenaraujo',null,null,true),
  ('Alhender Salvador Bridi','alhender.bridi@hotmail.com','27998861433','Mentores Masters','Horjana','ativo','Ativo','2025-07-16','2026-11-09','Morno','Em negociação','CASO PASSADO AOS DOUTORES','1996-07-22','dr.alhenderbridi',null,'São Paulo',false),
  ('Alice Lopes de Almeida',null,'5551997230255','Mentores Masters','Horjana','ativo','Ativo','2025-04-28',null,'Quente','Renovado',null,null,'https://www.instagram.com/dra_alicealmeida?igsh=MWV1OTV3ZG5jbTF2Yw==',null,null,false),
  ('AMANDA BISSOLI LOPES VALDUGA','amanda_bissoli@hotmail.com','67981432099','Mentores Masters','Horjana','ativo','Ativo','2025-09-02','2026-09-02','Morno','Em negociação','CASO PASSADO AOS DOUTORES','1990-02-28','draamandabissoli',null,null,false),
  ('Ana Cristina Batalha','tinabatalha8@gmail.com','71999888822','Mentores Masters','Horjana','ativo','Ativo','2025-09-11','2026-09-11','Quente','Em negociação','CASO PASSADO AOS DOUTORES',null,'dratinabatalha',null,null,false),
  ('Andrea Lopes Saldezas Tanuri','andreatanuri@gmail.com','5514996525767','Mentoria Mãe','Horjana','ativo','Ativo','2025-08-30','2027-08-02','Quente','Renovado','Renovou com a Thabata no evento','1975-06-04','https://www.instagram.com/draandreatanuri?igsh=MXdkbjFieHp2ODF3bQ==',null,null,true),
  ('Bruna Francielle Pereira Santos Hryniewicz','doutorabrunasantos@hotmail.com','5569999941690','Mentoria Mãe','Horjana','ativo','Ativo','2025-08-31','2027-07-16','Morno','Renovado',null,'1987-09-27','Drabrunasantoshryniewiz',null,null,true),
  ('Caio de Almeida Toledo Pires','caioatps@hotmail.com','41992461317','Mentores Masters','Horjana','ativo','Ativo','2025-02-28','2027-02-28','Quente','Renovado',null,null,'caiopiresgineco',null,null,false),
  ('Camila Vieira Giannecchini','camilagiannecchini@gmail.com','34996476462','Mentoria Mãe','Horjana','ativo','Ativo','2026-08-03','2027-08-03','Quente','Renovado','CLIENTE NOVO','1988-12-28','@dracamilagiannecchini',null,null,true),
  ('Catharine Coelho da Silva Santos','contato@dracathycoelho.com','5571993015097','Mentoria Mãe','Horjana','ativo','Ativo','2025-01-22','2027-01-27','Quente','Renovado',null,'1990-03-01','https://www.instagram.com/dracatharinecoelho?igsh=MjZ0NHVrcHc5bWU5','Mastologista','São paulo',false),
  ('Cristiano Marcel Andrade Cruz','crismac19@yahoo.com.br','5534992790001','Mentoria Mãe','Horjana','ativo','Ativo','2025-09-10','2027-08-02','Quente','Renovado',null,'1983-04-26','@drcristianocruz','ortopedia e nutrologia','Uberlândia',false),
  ('Cristinne Miranda Breval Teixeira','cbreval79@gmail.com','92984153166','Mentoria Mãe','Horjana','ativo','Ativo','2024-11-13','2026-11-25','Quente','A vencer',null,'1979-12-09','https://www.instagram.com/dracrisbreval?igsh=MXhvejRobXZlYWU5aA==','Nutrologia','Amazonas',true),
  ('Deyzarth Lopes Viana Spínola','clinicamater@hotmail.com','77988358490','Mentores Masters','Horjana','ativo','Ativo','2025-02-18','2027-02-18','Quente','Renovado','ARIANE: ficou de mandar os cheques',null,'dradeyzarthviana',null,null,false),
  ('Divino de Oliveira Mamede Filho','divinomed@hotmail.com','3499649309','Mentores Masters','Horjana','ativo','Ativo','2025-03-25','2027-03-25','Quente','Renovado',null,'1980-10-16','drdivinomamede',null,null,false),
  ('Edgar Oliveira Sarmento','dredgarsarmento@gmail.com','61996065036','Mentores Masters','Horjana','ativo','Ativo','2026-01-11','2027-01-11','Quente','Renovado',null,'1988-05-02','dredgarsarmento',null,null,false),
  ('EDIR SOCCOL JUNIOR','soccoljr@hotmail.com','46999222222','Mentores Masters','Horjana','ativo','Ativo','2026-06-02','2027-05-02','Quente','Renovado',null,'1979-01-29','dredirsoccoljr',null,null,false),
  ('Eduardo Pachu Raia dos Santos','eduardopachu350@hotmail.com','83996104015','Mentores Masters','Horjana','ativo','Ativo','2025-04-27','2027-04-27','Quente','Renovado',null,'1981-08-18','dreduardopachu',null,null,false),
  ('Erika domingues ferraz jacob','erikadfj@gmail.com','32984219581','Mentoria Mãe','Horjana','ativo','Ativo','2026-08-10','2027-08-10','Quente','Renovado','CLIENTE NOVO','1990-06-13','@draerikajacob',null,null,true),
  ('Esthela Oliveira','draesthela@sideclinic.com.br','11972910279','Mentores Masters','Horjana','ativo','Ativo','2026-03-10','2027-03-10','Quente','Renovado',null,'1985-04-27','draesthelaoliveira',null,null,false),
  ('Felipe Balem Borges da Silva','fbalem@hotmail.com','46991200000','Mentores Masters','Horjana','ativo','Ativo','2026-05-04','2027-05-02','Quente','Renovado',null,null,'drfelipebalem',null,null,false),
  ('FERNANDA BRUNO MACEDO','fernandabrunomacedo@gmail.com','7799907601','Mentoria Mãe','Horjana','ativo','Ativo','2026-08-10','2027-08-10','Quente','Renovado','CLIENTE NOVO','1978-10-27','dra.fernandabruno',null,null,false),
  ('Fernanda Slovinski Demoliner','drafernadasd@gmail.com','69992752639','Mentoria Mãe','Horjana','ativo','Ativo','2026-09-11','2027-09-11','Quente','Renovado','CLIENTE NOVO','1987-06-25','drafernandademoliner',null,null,false),
  ('Gabriel Mattos Henriques','gabrielmattos@msn.com','93981157065','Mentores Masters','Horjana','ativo','Ativo','2026-05-26','2027-05-26','Quente','Renovado',null,'1994-08-09','drgabrielmhenriques',null,null,false),
  ('Geciele Nunes de Paula','drageciele@gmail.com','69992370230','Mentoria Mãe','Horjana','ativo','Ativo','2025-06-25','2027-06-25','Frio','Renovado',null,'1991-09-25','drageciele.npaula',null,null,false),
  ('Giselle Rodrigues Máximo','giselle_rm@hotmail.com','12996608400','Mentoria Mãe','Horjana','ativo','Ativo','2025-04-01','2027-04-27','Quente','Renovado',null,null,'https://www.instagram.com/dragisellemaximo?igsh=MTV3eGpieHcyM3VhYw==','Ginecologia e obstetrícia','São José dos Campos - SP',false),
  ('HENRIQUE PERES ROCHA','hperesrocha@gmail.com','4896050088','Mentores Masters','Horjana','ativo','Ativo','2025-12-03','2026-12-03','Quente','A vencer',null,'1978-01-16','drhenriqueperesrocha',null,null,true),
  ('HIGOR MICHEL MOREIRA CALDATO','higorcaldato@outlook.com','21981351803','Mentores Masters','Horjana','ativo','Ativo','2026-05-04','2027-05-02','Quente','Renovado',null,'1985-03-24','drhigorcaldato',null,null,true),
  ('Hilloa Rodrigues Pereira','drahilloa@gmail.com','71988625052','Mentores Masters','Horjana','ativo','Ativo','2025-12-29','2026-12-29','Quente','A vencer',null,'1981-06-16','drahilloarodrigues.nutrologa',null,null,true),
  ('Iana Carruego',null,'71999979244','Mentores Masters','Horjana','ativo','Ativo',null,null,'Quente','Renovado',null,null,'draianacarruego',null,null,false),
  ('Isabelle Ledo',null,'71991372560','Mentores Masters','Horjana','ativo','Ativo',null,null,'Quente','Renovado',null,null,'draisabelleledo',null,null,false),
  ('João Lauro D''Angelo Caminhas','gestaodrjoaolauro@gmail.com','33991990088','Mentores Masters','Horjana','ativo','Ativo','2025-10-18','2027-10-18','Quente','Renovado','Renovou com a Ariane','1983-04-17','drjoaolauro',null,null,false),
  ('Jordana Nascimento Pereira','pereirajordana94@gmail.com','4199886127','Mentores Masters','Horjana','ativo','Ativo','2025-08-25','2027-08-25','Quente','Renovado','Renovou com a Ariane','1994-05-09','jordanapereiragineco',null,null,false),
  ('Juliana Paola de Melhado e Lima','drajuliana@gmail.com','12981111400','Mentores Masters','Horjana','ativo','Ativo','2025-10-20','2026-10-20','Quente','Em negociação','CASO PASSADO AOS DOUTORES','1973-12-14','drajulianapaola',null,null,false),
  ('Katiana Bassani Turon','katianaturon@hotmail.com','21998305669','Mentoria Mãe','Horjana','ativo','Ativo','2025-02-12','2027-02-27','Frio','Renovado',null,'1986-10-13','https://www.instagram.com/drakatianaturon?igsh=bmVoeHFqZW81YXg1',null,null,false),
  ('Kelso Passos da Silva','kelso@kelsopassos.com.br','79999722177','Mentoria Mãe','Horjana','ativo','Ativo','2026-08-14','2027-08-14','Morno','Renovado','CLIENTE NOVO','1968-06-29','@drkelsopassos','Ginecologista e obstetra','Aracaju',false),
  ('Leciana de Sousa Ramos','lecianaramos@hotmail.com','9881266986','Mentores Masters','Horjana','ativo','Ativo','2026-05-26','2027-05-26','Quente','Renovado',null,'1987-07-31','draleciana',null,null,false),
  ('Livia Cristina Cardoso Ninno Andraus','livinhaninno@gmail.com','14999057755','Mentoria Mãe','Horjana','ativo','Ativo','2025-06-04','2027-06-04','Morno','Renovado','Renovou a Vitoria',null,'https://www.instagram.com/dralivianandraus.emagrecimento?igsh=MTR6bmRpenppcGQ0bQ==',null,null,false),
  ('Lucas Miranda Bessa','drlucasmirandabessa@gmail.com','11998667087','Mentoria Mãe','Horjana','ativo','Ativo','2025-06-14','2027-05-30','Quente','Renovado',null,null,'https://www.instagram.com/dr_lucasmiranda?igsh=NmYxNXhxcGx3aGRl',null,null,false),
  ('Lucio Oliveira','lucio@grapeclinic.com.br','35984022017','Mentores Masters','Horjana','ativo','Ativo','2025-12-28','2026-12-28','Morno','A vencer',null,'1987-11-05','luciogrape',null,null,false),
  ('Luisa Cherubini Mussi','luisafernasopolis@hotmaik.com','19996789055','Mentores Masters','Horjana','ativo','Ativo','2026-03-09','2027-03-09','Quente','Renovado',null,'1989-01-21','draluisacherubini',null,null,false),
  ('Luísa Guedes de Oliveira','drluissguedes@gmail.com','48988421545','Mentores Masters','Horjana','ativo','Ativo','2025-08-14','2026-08-14','Quente','Em negociação','CASO PASSADO AOS DOUTORES','1981-05-22','https://www.instagram.com/draluisaguedes?igsh=MTNmNDZzcnpka3g5YQ==',null,null,false),
  ('Luiz Guilherme De Campos Ribeiro Filho','luizdcrf@gmail.com','91993111355','Mentoria Mãe','Horjana','ativo','Ativo','2026-08-03','2027-08-03','Morno','Renovado','CLIENTE NOVO','1982-05-16','dr.luizdecampos',null,null,true),
  ('Marcela Ferreira De Oliveira','marcela@grapeclinic.com.br','3498444727','Mentores Masters','Horjana','ativo','Ativo','2025-05-27','2026-12-28','Quente','A vencer',null,'1988-08-31','marcelagrape',null,null,false),
  ('Márcia Verônica Paes Fonsêca','marciagineco@gmail.com','83991219333','Mentoria Mãe','Horjana','ativo','Ativo','2026-08-03','2027-08-03','Quente','Renovado','CLIENTE NOVO',null,'@dramarciafonseca',null,null,true),
  ('Marcos Vinícius Santana','marcosvinicius@hotmail.com','68999586351','Mentoria Mãe','Horjana','ativo','Ativo','2025-07-30','2027-09-01','Morno','Renovado','Renovou com a Vitoria',null,'https://www.instagram.com/marcossantana1?igsh=MXZ2cGczdzJ6bzhwZw==',null,null,false),
  ('Maria Cláudia Rosenbaum','mcrosenbaum@outlook.com','67999269011','Mentores Masters','Horjana','ativo','Ativo','2024-09-30','2026-11-10','Quente','Em negociação','CASO PASSADO AOS DOUTORES','1990-10-15','dra.mariaclaudiarosenbaum',null,null,false),
  ('Mariana Pereira silva Lemos','malemosps@gmail.com','11997069313','Mentores Masters','Horjana','ativo','Ativo','2026-05-02','2027-05-02','Frio','Renovado',null,null,'dra.marianalemosps',null,null,false),
  ('Mariana Vilela','maryvalves@hotmail.com','34991527696','Mentoria Mãe','Horjana','ativo','Ativo','2024-07-27','2026-09-01','Quente','Em negociação','CASO PASSADO AOS DOUTORES',null,'https://www.instagram.com/dramarianavilelaa?igsh=MTF0ems3bjkwbWJnbQ==',null,null,false),
  ('Mariela Muniz','marielalmuniz@yahoo.com.br','12981229396','Mentores Masters','Horjana','ativo','Ativo','2025-11-02','2026-11-02','Quente','Em negociação','CASO PASSADO AOS DOUTORES','1977-03-31','marielamunizdermato',null,null,true),
  ('Marina Mayara Pagoto','marinamtbarboza@gmail.com','92984314131','Mentoria Mãe','Horjana','ativo','Ativo','2025-08-02','2027-09-07','Morno','Renovado','Renovou com a Vitoria',null,'https://www.instagram.com/dramarinapagotto?igsh=bDc5eTl3M3Q1cTNl',null,null,false),
  ('MATHEUS PEREIRA SILVA LEMOS','drlemosmatheus@gmail.com','17997651202','Mentoria Mãe','Horjana','ativo','Ativo','2027-05-01','2027-05-27','Quente','Renovado',null,'1996-04-22','@drmatheuslemos',null,null,true),
  ('Mayara Maia Ribeiro','mayaralanucy@hotmail.com','63981180100','Mentores Masters','Horjana','ativo','Ativo','2026-01-14','2027-01-14','Quente','A vencer',null,'1986-07-15','dramayaramaia',null,null,false),
  ('Melissa Andrea Wanderley Parente','melvivi5@gmail.com','88999061086','Mentoria Mãe','Horjana','ativo','Ativo','2025-01-15','2027-01-15','Quente','A vencer',null,null,'@dramelissaparente',null,null,false),
  ('Merenciana Duarte Sarkis','merencianaduarte@gmail.com','81991495245','Mentoria Mãe','Horjana','ativo','Ativo','2025-03-20','2027-03-20','Quente','Renovado',null,'1984-10-12','https://www.instagram.com/drameryduarte',null,null,true),
  ('Michelle Buchmuller','michelle.phe27@yahoo.com.br','34999117205','Mentoria Mãe','Horjana','ativo','Ativo','2025-01-01','2027-01-01','Quente','A vencer',null,null,'https://www.instagram.com/dramichellebuchmuller?igsh=MTdsYzBqcnByd2psZA==',null,null,false),
  ('Nathalia Bordin Dal-Prá','nathidalpra@hotmail.com','44988190750','Mentores Masters','Horjana','ativo','Ativo','2025-11-24','2026-11-24','Quente','A vencer',null,'1992-12-02','dra.nathidalpra',null,null,false),
  ('Patrícia Cavalcante Silva Emiliozzi','drapatriciacavalcante@yahoo.com.br','11992670160','Mentores Masters','Horjana','ativo','Ativo','2026-03-09','2027-03-09','Quente','Renovado',null,'1986-05-16','dra.patriciacavalcante',null,null,false),
  ('Patricia Miriam Magier','magierpatricia@gmail.com','21999849171','Mentoria Mãe','Horjana','ativo','Ativo','2025-07-14','2027-07-14','Quente','Renovado',null,null,'https://www.instagram.com/drapatriciamagier?igsh=MWd1bDBhajdkczl6bA==',null,null,false),
  ('Paulo Abreu Neto','dr.pauloabreu@hotmail.com','11999884646','Mentoria Mãe','Horjana','ativo','Ativo','2025-08-06','2026-08-06','Morno','Em negociação','CASO PASSADO AOS DOUTORES','1986-12-05','https://www.instagram.com/drpauloabreu?igsh=MW1tamR6MTJ3dGxtYw==',null,null,true),
  ('PEDRO HENRIQUE GUERRA LUIZ DA SILVA','pedrohluiz27@gmail.com','11963557776','Mentores Masters','Horjana','ativo','Ativo','2025-11-24','2026-11-24','Quente','A vencer',null,'1988-03-28','drpedroguerra',null,null,false),
  ('PEDRO HENRIQUE MENEZES TAKIUTI','pedrotakiuti@hotmail.com','11989092616','Mentoria Mãe','Horjana','ativo','Ativo','2026-08-07','2027-08-07','Quente','Renovado','CLIENTE NOVO. Entrou no lugar da esposa Paula Palacio. entrada de 20k + 4x 22k.','1984-11-17','@drpedrotakiuti',null,null,true),
  ('Priscila Sousa do Nascimento','drapriscilanascimento63@gmail.com','99982277818','Mentoria Mãe','Horjana','ativo','Ativo','2025-08-31','2026-11-30','Morno','Renovado',null,null,'https://www.instagram.com/drapriscilanascimento?igsh=MXc3YnJid3dydzFjMg==',null,null,false),
  ('Regina Ferrante Rebello de Souza','rebellodraregina@gmail.com','27981232524','Mentores Masters','Horjana','ativo','Ativo','2025-02-26','2027-02-26','Quente','Renovado',null,null,'drareginarebello',null,null,true),
  ('Sandra Helena capela Goya Machado','smachado60@yahoo.com','13997111873','Mentoria Mãe','Horjana','ativo','Ativo','2026-08-11','2027-08-11','Morno','Renovado','CLIENTE NOVO','1965-10-12','SANDRAGOYAMACHADO',null,null,true),
  ('Sarita Rodrigues','saritarods@yahoo.com.br','35999618702','Mentores Masters','Horjana','ativo','Ativo','2024-09-20','2027-04-30','Quente','Renovado',null,null,'dra.sarita.rodrigues',null,null,false),
  ('Suzana Lessa','drasuzanalessaplano@gmail.com','21994816246','Mentores Masters','Horjana','ativo','Ativo','2024-12-03','2026-11-26','Quente','A vencer',null,null,'https://www.instagram.com/drasuzanalessa_?igsh=Y2RhdjN0ZXBieXhk',null,null,false),
  ('Talita Lelis','talitalelis2017@gmail.com','71996185802','Mentores Masters','Horjana','ativo','Ativo','2025-09-30','2026-09-30','Quente','Em negociação','CASO PASSADO AOS DOUTORES','1980-12-10','dratalitatelis.medica',null,null,false),
  ('Thiago Collares','thiago@drthiagocollares.com','48991819099','Mentoria Mãe','Horjana','ativo','Ativo','2025-12-15','2026-12-15','Quente','A vencer',null,'1983-05-14','https://www.instagram.com/drthiagocollares/','Não tem especialidade','Balneário Camburiú',false),
  ('Thiago Silveira Pereira','thiagopereiramed@yahoo.com.br','48991168208','Mentoria Mãe','Horjana','ativo','Ativo','2026-08-03','2027-08-03','Quente','Renovado','CLIENTE NOVO',null,'@drthiagosilveira',null,null,false),
  ('Twoany de Jesus Gomes','twoany86@hotmail.com','21980963030','Mentores Masters','Horjana','ativo','Ativo','2024-10-16','2026-10-18','Quente','Em negociação','CASO PASSADO AOS DOUTORES',null,'dratwoany',null,null,false),
  ('Viviane Oliveira Nogueira Ferrari','medicinavitalis@gmail.com','27997661285','Mentoria Mãe','Horjana','ativo','Ativo','2025-09-22','2026-09-22','Quente','Em negociação','THAIS RESOLVENDO',null,null,null,null,false),
  ('Wilson Ninno Netto','nettoninno12@gmail.com','14998148755','Mentoria Mãe','Horjana','ativo','Ativo','2025-07-11','2027-07-11','Quente','Renovado','Renovou com a Vitoria',null,'https://www.instagram.com/wilsonninno?igsh=NjJpNXQ4a3Z0MjQ5',null,null,false),
  ('Alessandro de Bastos','aleleby@yahoo.com.br','35998421284','Mentoria Mãe','Thabata','ativo','Ativo','2026-08-11','2027-08-11','Quente','Renovado','CLIENTE NOVO','1974-05-01','dralessandrobastos',null,null,true),
  ('Ana Sofia Carvalho Calheiros','sofiaccalheiros@yahoo.com.br','82991584060','Mentoria Mãe','Thabata','ativo','Ativo','2025-04-22','2026-04-22','Morno','Em negociação','VI RESOLVENDO',null,'https://www.instagram.com/anasofiacalheiros?igsh=MTJwaDljb2QyZGs2dw==',null,null,false),
  ('Andrea Rúbia Perfeito','arubiap@gmail.com','619997011025','Mentoria Mãe','Thabata','ativo','Ativo','2026-06-29','2027-06-29','Quente','Renovado',null,'1969-04-08','@draandreaperfeito',null,null,true),
  ('Ane Caroline Araújo Barreto','anec.barreto.302@gmail.com','55999330203','Mentoria Mãe','Thabata','ativo','Ativo','2026-06-08','2027-06-08','Quente','Renovado',null,'1994-01-14','draanebarreto',null,null,true),
  ('Brenda dos Santos Mendonça','drabrendamendonca@gmail.com','62982474747','Mentoria Mãe','Thabata','ativo','Ativo','2025-07-11','2027-07-11','Morno','Renovado',null,'1994-08-27','Drabrendamendonca',null,null,true),
  ('Carla Carolina Freitas','dracarlafreitas@outlook.com','71999989445','Mentoria Mãe','Thabata','ativo','Ativo','2025-03-23','2027-03-23','Quente','Renovado',null,null,'dracarlafreitas',null,null,false),
  ('Carolina Moreira dos Santos Starling','carolmsstarling@yahoo.com.br','35998220884','Mentoria Mãe','Thabata','ativo','Ativo','2026-08-11','2027-08-11','Quente','Renovado','CLIENTE NOVO','1976-06-07','dra.carolinastarling',null,null,true),
  ('Dandara Tureta da silva Felisberto','dandaratureta@gmail.com','21996975101','Mentoria Mãe','Thabata','ativo','Ativo','2026-06-19','2027-06-22','Quente','Renovado',null,'1991-11-08','@dra.dandaratureta',null,null,false),
  ('Daniel Barbosa Teixeira','drdanielteixeira@gmail.com','24981337289','Mentoria Mãe','Thabata','ativo','Ativo','2026-05-26','2027-05-26','Quente','Renovado',null,'1985-06-28','@dr.danielbteixeira',null,null,true),
  ('DELMA CONCEIÇÃO PEREIRA DAS NEVES','dradelmanevesnutro@gmail.com','69996040333','Mentoria Mãe','Thabata','ativo','Ativo','2026-08-03','2027-08-03','Morno','Renovado','CLIENTE NOVO','1979-12-08','@DRADELMANEVES',null,null,false),
  ('Fabiano da Cunha Tanuri','ftanuri@yahoo.com.br','14996561414','Mentoria Mãe','Thabata','ativo','Ativo','2026-08-03','2027-08-03','Quente','Renovado','CLIENTE NOVO, Fechou renovação da esposa Andrea e a cadeira dupla dele com a Thabata','1973-06-16','@fabianotanuri',null,null,true),
  ('Juliana Matoso Aliprandi','contato@clinicajulianaaliprandi.com.br','31983568080','Mentoria Mãe','Thabata','ativo','Ativo','2026-08-03','2027-08-03','Morno','Renovado','CLIENTE NOVO','1983-09-05','@drajulianaaliprandi',null,null,true),
  ('Karine Ribeiro Antunes','karinerantunes@hotmail.com','35997672069','Mentoria Mãe','Thabata','ativo','Ativo','2026-08-26','2027-08-26','Quente','Renovado','CLIENTE NOVO','1982-04-20','@drakarineantunes',null,null,false),
  ('Katia Alves Ramos','contato@drakatiaramos.com.br','34991983768','Mentoria Mãe','Thabata','ativo','Ativo','2026-08-11','2027-08-11','Morno','Renovado','CLIENTE NOVO','1979-11-12','@drakatia.ramos',null,null,true),
  ('Kennya Henriqueta de Carvalho','kennya_1104@hotmail.com','43999641131','Mentoria Mãe','Thabata','ativo','Ativo','2025-01-14','2027-01-27','Quente','Renovado',null,null,'https://www.instagram.com/dra.kennyahenriqueta?igsh=MTBkaXpoazZiNW9kcw==',null,null,false),
  ('Kézia Anália Tonel Senra','tonelkezia@gmail.com','85982059528','Mentoria Mãe','Thabata','ativo','Ativo','2025-08-31','2027-08-31','Frio','Em negociação','VITORIA: Em tratativa com a Vitoria pra renovação',null,null,null,null,false),
  ('Lana Kris Montagnani Gonçalves','lanakris@hotmail.com','447475939669','Mentoria Mãe','Thabata','ativo','Ativo','2026-08-03','2027-08-03','Quente','Renovado','CLIENTE NOVO','1982-01-18','@dralanakris',null,null,false),
  ('Larissa Silva e Silva','lsilvaesilva@yahoo.com.br','11994948333','Mentoria Mãe','Thabata','ativo','Ativo','2025-02-18','2027-08-02','Quente','Renovado',null,'1978-08-23','https://www.instagram.com/dralarissasilvaesilva?igsh=bW5lOXdkeTRrM2Zv',null,null,false),
  ('Leidiane Gomes Dias','leidynx1@outlook.com','66984587320','Mentoria Mãe','Thabata','ativo','Ativo','2025-05-10','2027-05-10','Morno','Renovado',null,'1986-11-16','https://www.instagram.com/draleidianedias?igsh=czgyaWdiZ2w1eHUw',null,null,false),
  ('Leonardo Rafael Pozzobon','drleonardopozzobon@hotmail.com','67984165639','Mentoria Mãe','Thabata','ativo','Ativo','2025-06-12','2027-06-12','Quente','Renovado',null,'1983-09-05','https://www.instagram.com/drleonardopozzobon?igsh=em8yZGc5cWprOHNw',null,null,true),
  ('Lise Machado Wiederkehr','doutoralise@gmail.com','21979396268','Mentoria Mãe','Thabata','ativo','Ativo','2025-08-31','2026-08-31','Quente','Em negociação','ARI MANDOU MSG E ELA VAI RENOVAR',null,'https://www.instagram.com/dra.lise?igsh=MW84djNjZXNuYTF3dg==',null,null,false),
  ('Livia Viana Trevisan Paluan','draliviatrevisan@gmail.com','19971417234','Mentoria Mãe','Thabata','ativo','Ativo','2025-07-27','2027-07-27','Frio','Renovado',null,'1987-03-08','https://www.instagram.com/draliviatrevisan?igsh=MW42dnF6bzBiYjQ3cg==',null,null,true),
  ('Lorena Fernandes Melo','lorenafernandesmelof@gmail.com','33991060202','Mentoria Mãe','Thabata','ativo','Ativo','2025-08-31','2027-08-31','Quente','Renovado','Renovou no evento com a Thabata',null,null,null,null,false),
  ('Luaira Ferreira Campos','fc.luaira@gmail.com','22981344488','Mentoria Mãe','Thabata','ativo','Ativo','2025-09-14','2026-09-25','Quente','Em negociação','DR VINICIUS DISSE QUE VAI RENOVAR',null,'https://www.instagram.com/dra.luaira?igsh=cTV1b3V6cnRneDky',null,null,false),
  ('Lucas Missiba Brandão','lucasmissiba@hotmail.com','22998884417','Mentoria Mãe','Thabata','ativo','Ativo','2026-08-31','2027-08-31','Quente','Renovado','CLIENTE NOVO','1986-11-18','@drlucasbrandao.md',null,null,false),
  ('Luciana Leal Deister Machado','ludeister@hotmail.com','21993394353','Mentoria Mãe','Thabata','ativo','Ativo','2025-08-09','2027-08-09','Quente','Renovado','VITORIA: Renovou dia 31/08',null,'https://www.instagram.com/dralucianadeister?igsh=MWVsdGhrbDlxdTdvMw==',null,null,false),
  ('Luciana Virgínia Tempesta Muhe','lux.tempesta@uol.com.br','61982855989','Mentoria Mãe','Thabata','ativo','Ativo','2025-10-18','2027-08-02','Quente','Renovado','Renovou no evento com a Thabata','1972-08-03','@Dra Luciana Tempesta',null,null,true),
  ('Luís Felipe de Castro Neves','lfcastroneves@gmail.com','11998407890','Mentoria Mãe','Thabata','ativo','Ativo','2025-03-11','2027-06-11','Quente','Renovado','Ari disse que ele renovou',null,'https://www.instagram.com/drfelipe.castroneves?igsh=MWlxeHFwYjE0bzJj',null,null,false),
  ('Luiz Henrique Michels Teixeira','drluizmichels@gmail.com','19996042738','Mentoria Mãe','Thabata','ativo','Ativo','2026-02-27','2027-02-27','Quente','Renovado',null,null,'@drluizmichels',null,null,false),
  ('Marcela Filgueiras Mendes','marcelafilgueiras@gmail.com','12981317348','Mentoria Mãe','Thabata','ativo','Ativo','2025-02-26','2027-02-27','Morno','Renovado',null,null,'https://www.instagram.com/dra.marcelafilgueiras?igsh=N2Z0Y3RuZ2hmeDF1',null,null,false),
  ('Marcos Antonio Sahium Jr','masj83@hotmail.com','34999862103','Mentoria Mãe','Thabata','ativo','Ativo','2025-05-21','2027-05-21','Quente','Renovado',null,null,'https://www.instagram.com/marcossahium?igsh=MWJrbjdjaGlrN3Jlaw==',null,null,false),
  ('Maria Paula Silvestre Moura Cavalcante','mariapaula.mourac@gmail.com','82996248191','Mentoria Mãe','Thabata','ativo','Ativo','2026-08-03','2027-08-03','Frio','Renovado','CLIENTE NOVO',null,'Mariapaula_moura',null,null,false),
  ('Matheus Magnabosco Deon','dr.matheusdeon@gmail.com','48999277287','Mentoria Mãe','Thabata','ativo','Ativo','2025-07-11','2027-07-11','Frio','Renovado',null,'1991-08-17','https://www.instagram.com/dr.matheusdeon?igsh=NnNzMnkzNnk4ZmVn',null,null,false),
  ('Maurício Friederich','mauriciofriederich@yahoo.com.br','51999769955','Mentoria Mãe','Thabata','ativo','Ativo','2025-02-11','2027-09-09','Quente','Renovado','Renovado com Thabata',null,'https://www.instagram.com/dr.mauricio_friederich_?igsh=d25ubHJkMWVpdHJn',null,null,false),
  ('Milena Amaro Furlan','miamfurlan@gmail.com','19998386754','Mentoria Mãe','Thabata','ativo','Ativo','2025-10-06','2026-10-06','Quente','Em negociação','ARI TA RESOLVENDO',null,null,null,null,false),
  ('Milene Maria de Castro Buzzato','mmbuzzato@gmail.com','11999956063','Mentoria Mãe','Thabata','ativo','Ativo','2025-01-23','2027-08-02','Quente','Renovado',null,'1977-08-02','https://www.instagram.com/dramilenebuzzato?igsh=MWplMjQ5NXFsemxteA==',null,null,true),
  ('Natalia Suzane Fioramonte Corte','natalia.fioramonte@hotmail.com','19999203177','Mentoria Mãe','Thabata','ativo','Ativo','2025-07-09','2027-07-09','Frio','Renovado',null,'1990-08-09','https://www.instagram.com/natifioramonte?igsh=bjBrdHdmMG0zaDY=',null,null,true),
  ('Natani Dantas espinosa','natani_espinosa@hotmail.com','17997893007','Mentoria Mãe','Thabata','ativo','Ativo','2026-08-03','2027-08-03','Morno','Renovado','CLIENTE NOVO','1995-12-21','Dranataniespinosa',null,null,false),
  ('Pâmella Alves Ferreira Couto','pamella.alves@yahoo.com.br','22998257828','Mentoria Mãe','Thabata','ativo','Ativo','2025-05-01','2027-05-01','Quente','Renovado',null,null,'https://www.instagram.com/drapamella.couto?igsh=MWE0c3hkNHRtcGxhcg==',null,null,false),
  ('Paula Avelar Marquez','paulaavel@gmail.com','19996544060','Mentoria Mãe','Thabata','ativo','Ativo','2025-06-28','2027-06-28','Quente','Renovado',null,'1989-10-31','https://www.instagram.com/drapaulamarquez?igsh=ZmFva3hvb2FvbThy',null,null,true),
  ('Paula Machado de Almeida Alves','paula_machadomed@hotmail.com','21981966041','Mentoria Mãe','Thabata','ativo','Ativo','2025-05-30','2027-05-22','Morno','Renovado',null,null,'https://www.instagram.com/dra.paulamachado?igsh=aG9lb3IyZGFuNTl2',null,null,false),
  ('Paulo José Mantoan dos santos','doutor.mantoan@gmail.com','11971729911','Mentoria Mãe','Thabata','ativo','Ativo','2026-08-15','2027-08-16','Quente','Renovado','CLIENTE NOVO, ARI QUEM CUIDA','1978-08-21','Dr.paulomantoan',null,null,false),
  ('Rachel Souto','rachelsouto@gmail.com','69999571197','Mentoria Mãe','Thabata','ativo','Ativo','2025-04-30','2027-04-30','Quente','Renovado',null,null,'https://www.instagram.com/dra.rachelsouto?igsh=Y3NucGFnNThmZzk5',null,null,false),
  ('Rebeca Maria Filgueiras','filgueirasrebeca@yahoo.com.br','11982541689','Mentoria Mãe','Thabata','ativo','Ativo','2026-08-03','2027-08-03','Quente','Renovado','CLIENTE NOVO','1976-04-09','@dra.rebecafilgueiras',null,null,true),
  ('Renata De Paula F G De Vasconcellos','re_fernandes66@hotmail.com','12996243010','Mentoria Mãe','Thabata','ativo','Ativo','2026-03-27','2027-03-27','Quente','Renovado','Alinhamento','1980-05-26','https://www.instagram.com/drarenatafernandesgineco/',null,null,true),
  ('Renata Gabrielly Custódio Pinto','drarenatagabrielly@gmail.com','65999984757','Mentoria Mãe','Thabata','ativo','Ativo','2024-11-29','2026-11-30','Quente','Em negociação','Em negociaçao com a Thabata',null,'https://www.instagram.com/drarenatagabrielly?igsh=ZzF5ZWRuZzhkcHJp',null,null,false),
  ('Ridelson Alves da Costa de Miranda','drridelson@gmail.com','63984836469','Mentoria Mãe','Thabata','ativo','Ativo','2025-06-30','2027-06-29','Quente','Renovado',null,null,'https://www.instagram.com/dr.ridelsonmiranda?igsh=MXRxeXYzYWhzYmEzOQ==',null,null,false),
  ('Roberta Carlesso Miele','robertamiele@hotmail.com','54991911670','Mentoria Mãe','Thabata','ativo','Ativo','2025-06-16','2027-07-01','Frio','Renovado',null,'1976-10-24','https://www.instagram.com/dra.robertamiele?igsh=bmY4ZTllMjl4NGh3',null,null,true),
  ('Roberto Cesar Leite','robertocesarleite15@gmail.com','41999610659','Mentoria Mãe','Thabata','ativo','Ativo','2026-04-15','2027-04-15','Quente','Renovado',null,'1964-06-15','**',null,null,true),
  ('Rodrigo Alves de Medeiros Queiroz','digo_irece@gmail.com','71996046348','Mentoria Mãe','Thabata','ativo','Ativo','2025-09-08','2027-09-08','Quente','Renovado','Renovou com a Vitoria','1993-04-20','@dr.rodrigo.queiroz',null,null,true),
  ('Romolo Guida','romolo.guida@gmail.com','21999826705','Mentoria Mãe','Thabata','ativo','Ativo','2026-08-11','2027-08-11','Quente','Renovado','CLIENTE NOVO',null,'romologuidaurologia',null,null,false),
  ('Rosana Rassi Sahium','rosana_rassi@hotmail.com','34999350124','Mentoria Mãe','Thabata','ativo','Ativo','2025-05-21','2027-05-21','Quente','Renovado',null,null,'https://www.instagram.com/dra.rosanarassisahium?igsh=MTY5dWlpaHJkNmthOA==',null,null,false),
  ('Samara da Silva Lima','drasamaralima@hotmail.com','93991839065','Mentoria Mãe','Thabata','ativo','Ativo','2025-03-08','2027-03-27','Quente','Renovado',null,null,'https://www.instagram.com/dra_samaralima?igsh=ZWpxN25idnFyejJh',null,null,false),
  ('Sara Faria Ulhoa','sara_ulhoa@hotmail.com','62982971221','Mentoria Mãe','Thabata','ativo','Ativo','2025-02-14','2027-02-27','Quente','Renovado',null,null,'https://www.instagram.com/saraulhoa?igsh=MzI1dnVzdHAwMjBv',null,null,false),
  ('Silvana Guedes Gomes',null,'35997380268','Mentoria Mãe','Thabata','ativo','Ativo','2026-02-24','2027-02-27','Morno','Renovado',null,'1975-11-18','@drasilvanaguedes','Pós Graduada em Nutrologia','Poços de Caldas - MG',true),
  ('Simone do Valle Austgulen','sivalle@gmail.com','21967815151','Mentoria Mãe','Thabata','ativo','Ativo','2025-05-01','2027-06-11','Frio','Renovado',null,null,'https://www.instagram.com/drasimone.endocrino?igsh=NGxicmpmamJyYzlh',null,null,false),
  ('Sinara Vidotti Paltanin','sinara.v.p@hotmail.com','44997202221','Mentoria Mãe','Thabata','ativo','Ativo','2025-08-31','2027-08-31','Quente','Renovado','Renovou com a Thais no evento, mas a Vitoria esta vendo sobre os pagamentos',null,null,null,null,false),
  ('Tainã Maria Durans Brito Tochetto','tainadurans@hotmail.com','45991548199','Mentoria Mãe','Thabata','ativo','Ativo','2025-09-02','2027-09-02','Quente','Renovado','Renovou com a Vitoria','1984-11-13','@dratainatochetto',null,null,true),
  ('Tânia Maria Ferreira de Carvalho','drataniamariacarvalho@gmail.com','19998669701','Mentoria Mãe','Thabata','ativo','Ativo','2025-08-20','2027-08-20','Quente','Renovado',null,null,null,null,null,false),
  ('Thainara Paulucci Centenaro','thaipaulucci@gmail.com','18981011909','Mentoria Mãe','Thabata','ativo','Ativo','2025-07-07','2027-07-06','Quente','Renovado',null,null,'https://www.instagram.com/drathainarapaulucci?igsh=MWRmbm5yajluZ2FnOQ==',null,null,false),
  ('Thalita Silva Carvalho','drathalitasc@gmai','31996800371','Mentoria Mãe','Thabata','ativo','Ativo','2025-01-27','2027-01-21','Quente','Renovado',null,'1991-09-18','https://www.instagram.com/dra.thalitacarvalho?igsh=MTV2ZmVkenF1NzBicw==',null,null,true),
  ('Thiago Veríssimo','drverissimoendocrino@gmail.com','92999970229','Mentoria Mãe','Thabata','ativo','Ativo','2026-05-22','2028-05-22','Quente','Renovado','Vai antecipar Renovação, ja deu 13k no curso, em setembro ele paga ele paga 14k + 3 de 27',null,null,null,null,false),
  ('Vitoria Matioli Sacchetto','vi-sacchetto@hotmail.com','18997726769','Mentoria Mãe','Thabata','ativo','Ativo','2024-12-05','2026-12-05','Quente','A vencer',null,'1991-10-26','https://www.instagram.com/dravitoriasacchetto?igsh=MWRkY2R4aGVlN29nZw==',null,null,true),
  ('Vívian Bastos','viviandani.bastos@gmail.com','91991301571','Mentoria Mãe','Thabata','ativo','Ativo','2025-10-17','2026-10-17','Quente','Em negociação','VI RESOLVENDO','1984-03-24','@DRAVIVIANBASTOS',null,null,true),
  ('Víviann Pecly','viviannpecly@hotmail.com','22998616759','Mentoria Mãe','Thabata','ativo','Ativo','2025-09-04','2027-09-04','Quente','Renovado','Renovou com a Vitoria',null,null,null,null,false),
  ('Wellington Pereira dos Reis','drwellingtonreis@outlook.com','98981137509','Mentoria Mãe','Thabata','ativo','Ativo','2026-08-08','2027-08-08','Quente','Renovado','CLIENTE NOVO','1983-05-13',null,null,null,false),
  ('Wilson Barbosa Sampaio','wilsonbbsampaio@hotmail.com','33999212009','Mentoria Mãe','Thabata','ativo','Ativo','2025-06-10','2027-06-10','Morno','Renovado',null,null,'https://www.instagram.com/drwilsonsampaio?igsh=bXpncTR6Z3RleDJ3',null,null,false),
  ('Yole Maria Minervino Barroso','drayole.endorclinica@gmail.com','8399866808','Mentoria Mãe','Thabata','ativo','Ativo','2025-08-25','2026-08-25','Quente','Em negociação','THAIS RESOLVENDO: Dr Vinicius: Yole pode ir pra cima e diga pra ela renovar e marcarmos reuniao',null,null,null,null,false),
  ('Zelma Maria dos Santos Vilas Boas','zelmavilasboas@gmail.com','11983180284','Mentoria Mãe','Thabata','ativo','Ativo','2025-08-31','2027-08-31','Quente','Renovado','Renovou','1959-06-28','drazelmavilasboas',null,null,true),
  ('Rafaela Nunes Lira Braga Cândido','rafaela.nlbc@gmail.com','83996157997','Mentoria Mãe','Thabata','ativo','Ativo','2026-03-27','2027-06-27','Quente','Renovado',null,'1986-07-24','rafaela_nunes',null,null,true),
  ('Valéria Leal','dra.valeria@clinicavalerialeal.com.br','11999806020','Mentoria Mãe','Thabata','ativo','Ativo','2025-08-31','2027-09-21','Quente','Renovado',null,null,null,null,null,false),
  ('Maisa Fukayama','maisafukayama@hotmail.com','5511995815141','Mentoria Mãe','Cauane','ativo','Ativo','2025-04-04','2027-04-04','Frio','Em negociação','VITORIA: esta tentando contato, pois tem mensalidades do primeiro contrato pendente','1980-10-10','https://www.instagram.com/dra.maisa.fukayama?igsh=MWVyNTg5eGpxaWh6YQ==',null,null,false),
  ('Anne Karoline da Silva','anne.karoline.ferreira@hotmail.com','77999265954','Mentoria Mãe','Cauane','ativo','Ativo','2024-07-31','2026-07-31','Frio','Em negociação','ARI MANDOU MSG',null,'https://www.instagram.com/dra_annekaroline?igsh=MTV2azBzZmp2bjY5dw==',null,null,false),
  ('Grazielly Teles Silva','graziellyteles@hotmail.com.br','5511961980023','Mentoria Mãe','Cauane','ativo','Ativo','2025-08-28','2026-10-28','Frio','A vencer',null,null,null,null,null,false),
  ('Camilla de Lima Carneiro','camillaclc@hotmail.com','5599984247272','Mentoria Mãe','Cauane','ativo','Ativo','2024-08-30','2027-08-30','Morno','Renovado','Renovado com a Thais','2026-09-20','https://www.instagram.com/dra.camillacarneiro?igsh=OHVkbXphbXl0NzBn',null,null,false),
  ('Etianne Andrade Araújo Câmara','etianneandradec@gmail.com','5585981660707','Mentoria Mãe','Cauane','ativo','Ativo','2025-08-31','2027-08-31','Morno','Renovado','Renovou com a Vitoria','1986-05-02',null,null,null,false),
  ('Guilherme Lobo','clinicadrguilhermelobo@gmail.com','11958003841','Mentoria Mãe','Cauane','ativo','Ativo','2025-08-31','2027-08-31','Quente','Renovado','Renovou com a Vitoria',null,'https://www.instagram.com/drguilhermelobo?igsh=MXBuZW1vYWU5OTMxeQ==',null,null,false),
  ('Janaina Borges da Silva','drajanainaborges@gmail.com','34993022444','Mentoria Mãe','Cauane','ativo','Ativo','2025-08-31','2026-08-31','Quente','Em negociação','VI RESOLVENDO','1983-04-18','@janainaborges',null,null,true),
  ('Cláudio Henrique Alegre de Brito','claudiohenriquealegrebrito@gmail.com','5569981206377','Mentoria Mãe','Cauane','ativo','Ativo','2025-09-02','2026-09-02','Quente','Em negociação','VI RESOLVENDO',null,null,null,null,false),
  ('Edson Diego Silva','contato@drdiegosilva.com.br','5543996578534','Mentoria Mãe','Cauane','ativo','Ativo','2025-09-02','2027-09-02','Morno','Renovado','Renovou com a Thais',null,null,null,null,false),
  ('Camila Bandeira','dracamilabandeira@gmail.com','5592984002552','Mentoria Mãe','Cauane','ativo','Ativo','2025-09-04','2027-09-04','Morno','Renovado','Renovou com o Dr Vinicius','1985-03-21','https://www.instagram.com/dra.camilabandeira?igsh=MWlxbHNhaHU2aWMwYw==',null,null,false),
  ('Claudia Regina Simões Rodrigues Pedroso','claudia@dracaludia.com.br','5567981818880','Mentoria Mãe','Cauane','ativo','Ativo','2025-09-09','2027-09-09','Quente','Em negociação','THAIS RESOLVENDO: Vai passar o cartao dia 30','1966-07-14','@draclaudiarodrigues',null,null,true),
  ('Vanessa Fraife','vanessafraifeand@gmail.com','35991378176','Mentoria Mãe','Cauane','ativo','Ativo','2024-09-11','2026-11-17','Frio','A vencer',null,null,'https://www.instagram.com/dravanessafraife?igsh=b2J3a2w2bnJxd3Rr',null,null,false),
  ('Alexandre Simões Florio','simoes_florio@hotmail.com','554599752242','Mentoria Mãe','Cauane','ativo','Ativo','2025-10-01','2027-10-01','Quente','Renovado','Disse que renovou com a Ariane','1972-11-07','dr.alexandreflorio',null,null,true),
  ('Carolina Duarte Ribeiro','carolinaborgesduarte@gmail.com','5562996100822','Mentoria Mãe','Cauane','ativo','Ativo','2025-10-01','2027-10-01','Quente','Em negociação','THAIS RESOLVENDO: vai fazer pix de entrada dia 1 e demais pagamentos em cheque','1987-12-08','@dracarolinaduarte',null,null,false),
  ('Challsie Suzarte Laudano','challsiesuzarte@gmail.com','5575992151157','Mentoria Mãe','Cauane','ativo','Ativo','2025-10-16','2026-10-16','Frio','Em negociação','CASO PASSADO AOS DOUTORES','1994-03-24','@drachallsiesuzarte',null,null,true),
  ('Daniela Jobst','dqjobst@gmail.com','5511981669090','Mentoria Mãe','Cauane','ativo','Ativo','2025-10-24','2026-10-24','Quente','Em negociação','VI RESOLVENDO','1979-09-28','dradanielajobst',null,null,true),
  ('Lucineide Martins de Oliveira Maia','lucineidemmaia@hotmail.com','5524981149211','Mentoria Mãe','Cauane','ativo','Ativo','2025-10-25','2026-10-25','Quente','Em negociação','VI RESOLVENDO',null,null,null,null,false),
  ('Fernanda Nogueira Queiroz Cabral','nandanq.cabral@gmail.com','5592981127600','Mentoria Mãe','Cauane','ativo','Ativo','2025-10-20','2027-09-07','Quente','Renovado','Renovou com a Vitoria','1987-12-05','@dra.fernandacabral',null,null,false),
  ('Anne Karoline de Souza Torres','karolinetorresmed@gmail.com','5527988276868','Mentoria Mãe','Cauane','ativo','Ativo','2025-11-02','2026-11-01','Morno','Em negociação','VI RESOLVENDO','1986-01-06','@dra.annetorres',null,null,true),
  ('Cristiane Navarro Pereira Colombo','crisnavarro83@yahoo.com.br','5517991366537','Mentoria Mãe','Cauane','ativo','Ativo','2025-11-08','2026-11-08','Morno','A vencer',null,'1983-11-30','@dracristianenavarro',null,null,false),
  ('Jessica Repolho','drajessicasrepolho@gmail.com','94992291988','Mentoria Mãe','Cauane','ativo','Ativo','2025-11-12','2027-11-12','Morno','Renovado','Renovação Antecipada 03/09',null,null,null,null,false),
  ('Manuela Fernandes Gomes Rocha Uchoa Lopes','dramanuelamcz@gmail.com','82993316730','Mentoria Mãe','Cauane','ativo','Ativo','2024-11-24','2026-11-24','Morno','A vencer',null,null,'https://www.instagram.com/dramanurocha?igsh=MWdzbmhyYXJvMmxvaQ==',null,null,false),
  ('Gabriel Barreto Bastos','gabrielbastos@yahoo.com','1998868021','Mentoria Mãe','Cauane','ativo','Ativo','2024-11-29','2026-11-26','Morno','A vencer',null,null,'https://www.instagram.com/drgabrielpassos?igsh=cHp6bnBtdHF3dHli',null,null,false),
  ('Georgiana Oliveira da Silva Gama','georgianagama07@gmail.com','91993140710','Mentoria Mãe','Cauane','ativo','Ativo','2025-12-01','2026-12-01','Quente','A vencer',null,'1985-10-07','@drageorgianagsouza',null,null,true),
  ('Andressa Samira Brunelli','andressa.brunelli@hotmail.com','5544999474802','Mentoria Mãe','Cauane','ativo','Ativo','2025-12-04','2026-12-04','Quente','A vencer',null,'1993-03-24','draandressabrunelli.medica',null,null,true),
  ('Getúlio Junio Santos','getuliojs@gmail.com','3197186073','Mentoria Mãe','Cauane','ativo','Ativo','2025-12-05','2026-12-05','Frio','A vencer',null,null,'@drgetuliosantos',null,null,false),
  ('Arthur Vieira de Camargo Barros','arthurbarros2@gmail.com','5515996641028','Mentoria Mãe','Cauane','ativo','Ativo','2025-12-07','2026-12-07','Quente','A vencer',null,'1991-01-01','dr.arthur.barros',null,null,false),
  ('Ingrid Souza Lima','ingridlima-25@hotmail.com','77999211801','Mentoria Mãe','Cauane','ativo','Ativo','2024-12-24','2026-12-25','Morno','A vencer',null,'1994-06-25','https://www.instagram.com/draingrid.lima?igsh=cWY5MjhiZGd1ZTd4',null,null,true),
  ('Erika Valério dos Santos Ferrarez','gynederme@gmail.com','6699227484','Mentoria Mãe','Cauane','ativo','Ativo','2026-01-26','2027-01-27','Morno','Renovado',null,'1976-06-09','@draerikaferrarezioficial',null,null,false),
  ('Igor de Brito Silva Alves','igorbalves@gmail.com','21971129045','Mentoria Mãe','Cauane','ativo','Ativo','2025-01-28','2027-01-27','Morno','Renovado',null,'1982-05-16','https://www.instagram.com/dr.igoralves?igsh=MTd3aWJ2dGhqN3A0MA==',null,null,true),
  ('Karline Gomes Moreira Campos','drakarline@gmail.com','21992628319','Mentoria Mãe','Cauane','ativo','Ativo','2026-01-25','2027-01-27','Frio','Renovado',null,'1983-12-15','@drakarline.endocrino',null,null,true),
  ('Hellena Gabriella Ribeiro Dutra','hellena.gabriella@hotmail.com','17997676466','Mentoria Mãe','Cauane','ativo','Ativo','2024-11-24','2027-01-30','Frio','Renovado',null,null,'https://www.instagram.com/drahellennadutra?igsh=M25veWFwMnoya3Iz',null,null,false),
  ('Diego Fernando Gabaldo Baioni','dr.diegofernando99@gmail.com','5517997461811','Mentoria Mãe','Cauane','ativo','Ativo','2024-11-24','2027-01-30','Frio','Renovado',null,null,'https://www.instagram.com/drdiegofernando?igsh=MWU3YTk0ajhkeHgzZg==',null,null,false),
  ('Bruno C. M. Landim','brunolandin@yahoo.com.br','5521980008822','Mentoria Mãe','Cauane','ativo','Ativo','2026-02-24','2027-02-24','Morno','Renovado',null,null,'DrBrunoLandim',null,null,true),
  ('Izabela Rezende','izabelarezende10@hotmail.com','64999990480','Mentoria Mãe','Cauane','ativo','Ativo','2024-02-18','2027-02-27','Frio','Renovado',null,null,'https://www.instagram.com/izabelarezzende?igsh=MW90ZjE1MWMydW91NA=',null,null,false),
  ('Katrina Ferreira da Rocha Aguiar','katrinarocha02@hotmail.com','9391726855','Mentoria Mãe','Cauane','ativo','Ativo','2025-02-27','2027-02-27','Frio','Renovado',null,'1986-02-17','https://www.instagram.com/drakatrinarocha?igsh=M3JlYTZ0OThpczFi',null,null,false),
  ('Fabíola Pereira Frota','fabiolapfrotamed@gmail.com','5562998892434','Mentoria Mãe','Cauane','ativo','Ativo','2026-03-19','2027-03-19','Quente','Renovado','alinhamento',null,'@drafabiolapfrota',null,null,true),
  ('Flávia Alves de Oliveira','flavia.alves.m@hotmail.com','5541998984013','Mentoria Mãe','Cauane','ativo','Ativo','2025-03-23','2027-03-27','Frio','Renovado',null,'1980-10-09','https://www.instagram.com/draflaviaalves?igsh=MTByMXdzajFxa2VjZA==',null,null,true),
  ('Bruno Manuel Moura de Souza','bmourasousa@yahoo.com.br','93991666404','Mentoria Mãe','Cauane','ativo','Ativo','2025-04-01','2027-04-01','Morno','Renovado','ESTAVA NOS MASTERS','1979-03-21','dr.bmoura',null,null,true),
  ('Edaiane Franco da Silva','edaianefranco@gmail.com','5566996894590','Mentoria Mãe','Cauane','ativo','Ativo','2025-03-20','2027-04-07','Morno','Renovado',null,'1989-08-10','https://www.instagram.com/draedaianefranco?igsh=Yjl6ZGRyb3VzaGZo',null,null,false),
  ('Edmo Galvão Sodré Dourado','edmo_galvao@hotmail.com','28999920808','Mentoria Mãe','Cauane','ativo','Ativo','2025-04-04','2027-04-27','Morno','Renovado',null,'1988-12-08','https://www.instagram.com/drgalvaoedmo?igsh=dG5hY285ODNxNWo3',null,null,true),
  ('João Ferreira da Silva Netto','enfnetto@yahoo.com.br','34992431012','Mentoria Mãe','Cauane','ativo','Ativo','2023-04-23','2027-04-27','Quente','Renovado',null,'1980-09-12','@instituto.drjoaonetto',null,null,true),
  ('Carlos Eduardo Bronzel Dubay','carlosbronzel@hotmail.com','5544998440196','Mentoria Mãe','Cauane','ativo','Ativo','2025-04-10','2027-04-27','Morno','Renovado',null,null,'https://www.instagram.com/drcarlosdubay.cardio?igsh=MTNkd295eThla2J1Yw==',null,null,false),
  ('Gabriela Becker spina','contato@dragabrielabecker.com','63999835117','Mentoria Mãe','Cauane','ativo','Ativo','2026-04-28','2027-04-28','Quente','Renovado',null,'1995-01-10','Dragabrielabecker',null,null,true),
  ('Ana Carolina Rocha Monte Alto','dra.anacarolinarocha@outlook.com','5533991067832','Mentoria Mãe','Cauane','ativo','Ativo','2026-05-04','2027-05-04','Morno','Renovado',null,'1995-08-15','@dra.anacarolinarocha',null,null,false),
  ('Cristiane de Paiva Silveira Aguiar','cristianepsaguiar@gmail.com','5593999544810','Mentoria Mãe','Cauane','ativo','Ativo','2025-05-04','2027-05-04','Morno','Renovado',null,'1968-05-24','https://www.instagram.com/dra_cristianeaguiar_?igsh=MWZtejg5cTR3MzNzMQ==',null,null,true),
  ('Paulo Guilherme Forti de Almeida','esteticalaseraf@gmail.com','6692371473','Mentoria Mãe','Cauane','ativo','Ativo','2025-06-03','2027-06-03','Frio','Renovado','Ira levar os cheques da renovação no curso presencial','1967-11-24','https://www.instagram.com/dr.pauloforti?igsh=aDNzMG4zcHY2cWxt',null,null,false),
  ('Ana Paula Fabrício dos Santos','bellaclin@hotmail.com','5544999219312','Mentoria Mãe','Cauane','ativo','Ativo','2025-06-10','2027-06-10','Quente','Renovado',null,'1970-03-09','https://www.instagram.com/dra.anapaulafabricio?igsh=dzk2dDZ4NmJ4NWx6',null,null,true),
  ('Eline de Almeida Soriano','dra.elinesoriano@gmail.com','82999047975','Mentoria Mãe','Cauane','ativo','Ativo','2026-07-13','2027-07-13','Quente','Renovado',null,'1972-11-07','draelinesoriano',null,null,true),
  ('João Paulo de Freitas Sucupira','freitasjoaopaulo@hotmail.com','83999993074','Mentoria Mãe','Cauane','ativo','Ativo','2026-08-03','2027-08-03','Frio','Renovado','CLIENTE NOVO, ARI QUEM CUIDA','1980-03-24','@drjoaosucupira',null,null,false),
  ('Cibele Pimentel da Silva','cibelepimentel.ciclinic@yahoo.com.br','21981343551','Mentoria Mãe','Cauane','ativo','Ativo','2026-08-03','2027-08-03','Morno','Renovado','CLIENTE NOVO','1981-11-08','@dracibelepimentel',null,null,false),
  ('Fabiane Zilmmer','biazillmer@hotmail.com','66984282369','Mentoria Mãe','Cauane','ativo','Ativo','2026-08-03','2027-08-03','Quente','Renovado','CLIENTE NOVO','1987-09-03','drafabianezillmer',null,null,true),
  ('Ingryd Amaral Nóbrega','indymed@live.com','71999604497','Mentoria Mãe','Cauane','ativo','Ativo','2026-08-03','2027-08-03','Morno','Renovado','CLIENTE NOVO','1988-09-24','Dra. Ingryd Nóbrega',null,null,true),
  ('Marcos Oliveira Pires de Almeida','marcos_opa@yahoo.com.br','81988647919','Mentoria Mãe','Cauane','ativo','Ativo','2025-05-10','2027-08-07','Frio','Renovado',null,'1980-03-14','@drmarcosendocrino',null,null,true),
  ('Jessica Lima de Oliveira','jessika_katriny@hotmail.com','51991213849','Mentoria Mãe','Cauane','ativo','Ativo','2025-06-27','2027-08-17','Frio','Renovado',null,'1996-08-25','https://www.instagram.com/drajessicalim?igsh=ODRzamhmN21uNmg=',null,null,false),
  ('Cybele Cristine da Silva Costa Monteiro','ccybelee@hotmail.com','5585988833540','Mentoria Mãe','Cauane','ativo','Ativo','2025-08-31','2027-08-31','Quente','Renovado',null,'1976-12-10','@dracybelegineco',null,null,true),
  ('Elisabete Mendonça Rêgo Peixoto','elisabetemrp@gmail.com','5582999144971','Mentoria Mãe','Cauane','ativo','Ativo','2025-09-06','2027-09-06','Quente','Renovado',null,'1982-05-18','Draelisabetemendonca',null,null,true),
  ('Frederico Corte','drfredcorte@hotmail.com','19996557650','Mentoria Mãe','Cauane','ativo','Ativo','2024-12-03','2027-12-03','Morno','Renovado',null,'1983-04-21','https://www.instagram.com/drfredcorte.medico?igsh=MXB0bnUyNXVrbGZ6bQ==',null,null,false),
  ('Isadora Machado de Oliveira Santillan','isadoramachadodeoliveira@hotmail.com','44991477832','Mentoria Mãe','Cauane','ativo','Ativo','2026-03-23','2027-05-23','Frio','Renovado','ARIANE: Ari disse que ela quer cancelar',null,'draisadoramachado',null,null,false),
  ('Luanna Gabriela Perencini Perea','luannagpperea@gmail.com','5516981515678','Mentoria Mãe','Cauane','ativo','Ativo','2025-05-05','2027-05-05','Frio','Renovado',null,'1979-04-07','https://www.instagram.com/draluannaperea?igsh=NGY2cjFtbTVmZWw=',null,null,false),
  ('Bruna Karoline Pinheiro França Protásio','bpfranca@yahoo.com.br','5579999969228','Mentoria Mãe','Cauane','ativo','Ativo','2025-09-02','2027-09-08','Morno','Renovado','Renovou com a Thais','1988-07-08','@dra.brunafranca',null,null,true),
  ('Ana Claudia Santiago Siqueira','go.anacsiqueira@gmail.com','5551997819420','Mentoria Mãe','Cauane','ativo','Ativo','2025-08-31','2027-08-31','Morno','Renovado','Renovou com a Vitoria','1971-08-23','@dra.anaclaudiasiqueira',null,null,false),
  ('Marcia da Cunha dos Reis','mcrconsultorio@gmail.com','21999633552','Mentoria Mãe','Cauane','ativo','Ativo','2025-08-31','2027-09-21','Morno','Renovado','Dr Vinicius disse que vai continuar','1968-11-26',null,null,null,false),
  ('Yasmin Penalva Costa Serra','ypcserra@gmail.com','81989757519','Mentoria Mãe','Cauane','ativo','Ativo','2025-08-25','2027-09-21','Quente','Renovado','Dr Vinicius disse que vai continuar',null,null,null,null,false),
  ('Alex Barros','dralexbarros@gmail.com','556392388997','Mentoria Mãe','Cauane','ativo','Ativo','2025-01-30','2027-09-21','Frio','Renovado','Dr Vinicius disse que vai continuar',null,'https://www.instagram.com/dralexbarros?igsh=emdtNnlsdG5wY2M2',null,null,false),
  ('Camila Paes','dra.camila@clinicacasapaes.com.br','49991358135','Mentoria Mãe','Thais','cancelado','Encerrou Mentoria','2025-07-05','2026-07-05','Não definida',null,'ENCERRADO MESMO, JA REMOVI DO SISTEMA, FALTA DOS GRUPOS',null,'dra.camilapaes',null,null,false),
  ('Gabriela Santos Laboissiere Sarmento','gabrielalaboissiere@gmail.com','61999048741','Mentoria Mãe','Thais','cancelado','Encerrou Mentoria','2025-07-29','2026-07-29','Não definida',null,'ENCERRADO MESMO, JA REMOVI DO SISTEMA, FALTA DOS GRUPOS',null,'https://www.instagram.com/dragabrielalaboissiere?igsh=MWRxa3o4aGpyMzR4eQ==',null,null,false),
  ('Luís Carlos Novais Garcia','luiscngarcia@gmail.com','21996371510','Mentoria Mãe','Thais','cancelado','Encerrou Mentoria','2025-08-03','2026-08-03','Não definida',null,'ENCERRADO MESMO, JA REMOVI DO SISTEMA, FALTA DOS GRUPOS',null,'https://www.instagram.com/drluiscngarcia?igsh=MXM4M3B1c3NqMTJyeQ==',null,null,false),
  ('Marília Reis Pereira Vaz','dramarilia.vaz@gmail.com','35999210081','Mentoria Mãe','Thais','cancelado','Encerrou Mentoria','2025-01-14','2026-01-27','Não definida',null,'ENCERRADO MESMO, JA REMOVI DO SISTEMA, FALTA DOS GRUPOS',null,'https://www.instagram.com/dramariliavaz?igsh=MWF4MHJ2ZWJla2psbw==',null,null,false),
  ('Paula de Sousa Correa','pauladscorrea@gmail.com','11997481521','Mentoria Mãe','Thais','cancelado','Encerrou Mentoria','2025-08-27','2026-08-27','Não definida',null,'ENCERRADO MESMO, JA REMOVI DO SISTEMA, FALTA DOS GRUPOS',null,'https://www.instagram.com/drapaula.correa?igsh=MW96cXQ2dHoycG1oeQ==',null,null,false),
  ('Romina Rosa dos Santos Toledo','rominaendocrino@gmail.com','24981112353','Mentoria Mãe','Thais','cancelado','Encerrou Mentoria','2025-08-19','2026-08-19','Não definida',null,'ENCERRADO MESMO, JA REMOVI DO SISTEMA, FALTA DOS GRUPOS',null,null,null,null,false),
  ('Alessandro Xavier Donatti','donatti.a.x@gmail.com','27998343113','Mentoria Mãe','Thais','cancelado','Encerrou Mentoria','2025-04-02','2026-04-26','Não definida',null,'ENCERRADO MESMO, JA REMOVI DO SISTEMA, FALTA DOS GRUPOS',null,'https://www.instagram.com/dralessandrodonatti?igsh=MTNrM2NtbGt4bGRvag==',null,null,false),
  ('Michael  Castillo Caminha','drmichaelcaminha@gmail.com','11954503757','Mentoria Mãe','Thais','cancelado','Encerrou Mentoria','2025-03-20','2026-03-26','Não definida',null,'ENCERRADO MESMO, JA REMOVI DO SISTEMA, FALTA DOS GRUPOS',null,'https://www.instagram.com/drmichael.caminha?igsh=cnYwanh0ZGtzY2Yz',null,null,false),
  ('Marcela de Castro Rezende','marcelamedufu@gmail.com','5534988166183','Mentoria Mãe','Thais','cancelado','Encerrou Mentoria','2025-05-06','2026-05-06','Não definida',null,'ENCERRADO MESMO, JA REMOVI DO SISTEMA, FALTA DOS GRUPOS',null,'https://www.instagram.com/dramarcelarezzende?igsh=MWVzMTU5cWc3eGluMg==',null,null,false),
  ('Fernanda Lima Saldanha','nandalimafls@gmail.com','5511976345092','Mentoria Mãe','Thais','cancelado','Encerrou Mentoria','2025-08-31','2026-08-31','Não definida',null,'ENCERRADO MESMO, PRECISA REMOVER DO SISTEMA',null,'@drafernandalimafls',null,null,false),
  ('Gustavo Caldeira de Figueiredo','gustavocaldeiradr@gmail.com','5533988011223','Mentoria Mãe','Thais','cancelado','Encerrou Mentoria','2025-08-31','2026-08-31','Não definida',null,'ENCERRADO MESMO, PRECISA REMOVER DO SISTEMA',null,null,null,null,false),
  ('Manoela Oliveira Prieto Martins','manoelapietro91@gmail.com','17992473555','Mentoria Mãe','Thais','ativo','Resolvendo','2025-08-03','2026-08-03','Não definida',null,'ARI TA RESOLVENDO',null,'https://www.instagram.com/prieto_ma?igsh=MXFsZWxxN2NhOG8zNg==',null,null,false),
  ('Déborah Rondon Gonçales Schmitt','dradeborahschmitt@gmail.com','65981009505','Mentoria Mãe','Thais','ativo','Resolvendo','2026-08-24','2027-08-24','Não definida',null,'DR VINICIUS DISSE QUE VAI RESOLVER',null,'@dra_deborahschmitt',null,null,false),
  ('Fernanda Mesquita Abi-Rihan Cordeiro','fernandaabirihan@gmail.com','5521991610470','Mentoria Mãe','Thais','ativo','Resolvendo','2024-08-05','2026-09-05','Não definida','Não renovou','CASO PASSADO AOS DOUTORES',null,'https://www.instagram.com/drafernandaabi?igsh=MWFpZm9ka3N3bTJkcw==',null,null,false),
  ('Julia Passamani Abrahão','juliapabrahao95@gmail.com','27992204994','Mentoria Mãe','Thais','ativo','Resolvendo',null,null,'Não definida',null,'CASO PASSADO AOS DOUTORES',null,'https://www.instagram.com/dra.juliapassamani?igsh=MXB5ZGtzY3ZiN2JkcQ==',null,null,false),
  ('Raquel Scremin de Souza Ito','raquelssito@hotmail.com','44920000105','Mentoria Mãe','Thais','ativo','Resolvendo','2025-09-03','2026-09-03','Não definida',null,'CASO PASSADO AOS DOUTORES',null,'https://www.instagram.com/drarenatafernandesgineco/',null,null,false),
  ('Renata Ortiz Nascimento Sauer','renataortiz3@hotmail.com','65996165810','Mentoria Mãe','Thais','ativo','Resolvendo','2025-02-10','2026-02-26','Não definida',null,'CASO PASSADO AOS DOUTORES',null,'https://www.instagram.com/drarenataortizfael?igsh=MTR4OHM3YjkzdzNiZA==',null,null,false),
  ('Wilson Ramos','wilsonmarquesam@gmail.com','92981113235','Mentoria Mãe','Thais','ativo','Resolvendo','2024-09-12','2026-09-12','Não definida',null,'CASO PASSADO AOS DOUTORES',null,'https://www.instagram.com/drwilsonramos?igsh=MTJpN2F2eXYyZGUyZA==',null,null,false),
  ('Dandara Lacerda','dandaralacerda@hotmail.com','5563999672709','Mentoria Mãe','Thais','ativo','Resolvendo','2025-09-30','2026-09-30','Não definida',null,'NAO CONSEGUE PAGAR',null,null,null,null,false),
  ('Fernanda Fernandes Muniz Corrêa','fernandafernandesm@hotmail.com','5521993166568','Mentoria Mãe','Thais','ativo','Resolvendo','2025-08-31','2026-08-31','Não definida',null,'CASO PASSADO AOS DOUTORES',null,null,null,null,false),
  ('Amanda de Arruda Carvalho','amandadearruda@hotmail.com','5511999500287','Mentoria Mãe','Thais','ativo','Resolvendo','2025-01-28','2027-01-27','Não definida',null,'ARI TA RESOLVENDO',null,'https://www.instagram.com/draamandadearruda?igsh=ejA5Y2F2cGY4MjVs',null,null,false),
  ('Juliana Noronha Pinheiro','juliananoronhapinheiro@gmail.com','65996108808','Mentoria Mãe','Thais','ativo','Resolvendo','2025-04-29','2026-04-26','Não definida',null,'ARI TA RESOLVENDO',null,'https://www.instagram.com/dra.juliananpinheiro?igsh=d3RqN25iYWdvNzc2',null,null,false),
  ('Lucas de AlmeidaTosi','lukstosi@hotmail.com','5514982148524','Mentoria Mãe','Thais','ativo','Resolvendo','2025-08-31','2026-08-31','Não definida',null,'ARI TA RESOLVENDO',null,null,null,null,false),
  ('André Luiz Pio Castelões','andrecasteloes@hotmail.com','5514998391252','Mentoria Mãe','Thais','ativo','Ativo','2025-08-31','2026-08-31','Não definida',null,'vai voltar em janeiro',null,null,null,null,false),
  ('Cleisson Renan Borges Eckhardt','dr.cleissonborges@gmail.com','5566999448101','Mentoria Mãe','Thais','ativo','Ativo','2026-03-11','2027-03-11','Não definida',null,null,null,null,null,null,false),
  ('Daniely Alves Freitas','danyafreitas@hotmail.com','5571996962059','Mentoria Mãe','Thais','ativo','Ativo','2025-05-27','2027-05-27','Não definida','Renovado',null,null,'https://www.instagram.com/dradaniely.freitas?igsh=YWoyNXFvaWRlanRt',null,null,false),
  ('João Paulo Vitorino Esmeraldo','joaopaulovitorino@hotmail.com','83996583035','Mentoria Mãe','Thais','ativo','Ativo','2026-01-27','2027-01-27','Não definida',null,null,null,'@drjoaopaulovitorino',null,null,false),
  ('Jonas Cortez Moreira Júnior','jonascortez@nutriterapica.com','91981188498','Mentoria Mãe','Thais','ativo','Ativo','2026-03-08','2027-09-08','Não definida',null,'Trancamento de 6 meses realizado em 03/09/2026. Retorno previsto para 03/03/2027. Prazo contratual prorrogado pelo período de trancamento, com novo encerramento em 08/09/2027','2026-07-31','@jonascortezmjr',null,null,false),
  ('Kamilla Kelly Moura Montenegro de Castro','kkmontenegroc@gmail.com','83999295275','Mentoria Mãe','Thais','ativo','Ativo','2025-10-27','2026-10-27','Não definida',null,null,'1985-09-14','@endocrinokamillamontenegro',null,null,false),
  ('Karolina Alencar Bandeira','karolinalencar.med@gmail.com','5563981405556','Mentoria Mãe','Thais','ativo','Ativo','2025-09-16','2026-09-16','Não definida',null,'doutores ciente pode dar continuidade',null,'@drakarolinabandeira',null,null,false),
  ('Marco Antonio Rodrigues de Moraes','marco.rmoraes@gmail.com','11995900407','Mentoria Mãe','Thais','ativo','Ativo','2026-01-14','2027-01-14','Não definida',null,null,null,null,null,null,false),
  ('Marina Moura Reis','marinamreis@yahoo.com.br','98981199000','Mentoria Mãe','Thais','ativo','Ativo','2026-08-03','2027-08-03','Não definida',null,null,'2000-10-30',null,null,null,false),
  ('Robson Carvalho Frias','frias@cardiol.br','24974018315','Mentoria Mãe','Thais','ativo','Ativo','2025-07-07','2026-07-07','Não definida',null,'Esta com acesso travado por 2 meses',null,'https://www.instagram.com/robson.frias?igsh=MXhsb2tod2F5MHVzbw==',null,null,false),
  ('Ronaldo Borges Mendes','ronaldoborgesmendes@gmail.com','21988950905','Mentoria Mãe','Thais','ativo','Ativo','2025-11-10','2026-11-10','Não definida',null,null,'1986-05-09','@drronaldoborges',null,null,false),
  ('Sabrina Carvalho Ribeiro','drasabrinaribeironutro@gmail.com','63992115936','Mentoria Mãe','Thais','ativo','Ativo','2025-05-10','2026-05-26','Não definida',null,null,null,'https://www.instagram.com/drasabrina.ribeiro?igsh=MTBoNmZnMWQ2bDhlYw==',null,null,false);

-- ============================================================
-- PARTE 3 — RELATÓRIO (não muda nada). Rode uma consulta por vez.
-- ============================================================

-- 3.1 resumo geral
select
  (select count(*) from planilha_thais)                                          as na_planilha,
  (select count(*) from students)                                                as no_sistema,
  (select count(*) from planilha_thais p
     join students s on lower(s.email) = p.email)                                as casaram_por_email,
  (select count(*) from planilha_thais p
    where p.email is not null
      and not exists (select 1 from students s where lower(s.email) = p.email))  as so_na_planilha,
  (select count(*) from students s
    where s.status not in ('inativo','cancelado')
      and not exists (select 1 from planilha_thais p where p.email = lower(s.email))) as so_no_sistema;

-- 3.2 quem está na planilha e NÃO existe no sistema (vai ser criado)
select p.nome, p.email, p.mentoria, p.cs, p.status_planilha, p.entrada, p.vencimento
  from planilha_thais p
 where p.email is not null
   and not exists (select 1 from students s where lower(s.email) = p.email)
 order by p.mentoria, p.nome;

-- 3.3 quem está ativo no sistema e NÃO está na planilha (conferir com a Thaís)
select s.full_name, s.email, s.status, st.full_name as cs_atual
  from students s left join staff st on st.id = s.cs_id
 where s.status not in ('inativo','cancelado')
   and not exists (select 1 from planilha_thais p where p.email = lower(s.email))
 order by s.full_name;

-- 3.4 diferenças campo a campo (o que a PARTE 4 vai corrigir)
select p.nome, p.email,
       case when s.full_name is distinct from p.nome then s.full_name || ' → ' || p.nome end as nome_muda,
       case when s.entry_date is distinct from p.entrada then coalesce(s.entry_date::text,'—') || ' → ' || p.entrada::text end as entrada_muda,
       case when s.renewal_date is distinct from p.vencimento then coalesce(s.renewal_date::text,'—') || ' → ' || p.vencimento::text end as vencimento_muda,
       case when s.status is distinct from p.status then s.status || ' → ' || p.status end as status_muda,
       case when coalesce(s.temperature,'') is distinct from coalesce(p.temperatura,'') then coalesce(s.temperature,'—') || ' → ' || coalesce(p.temperatura,'—') end as temperatura_muda,
       case when st.full_name is distinct from p.cs then coalesce(st.full_name,'—') || ' → ' || p.cs end as cs_muda
  from planilha_thais p
  join students s on lower(s.email) = p.email
  left join staff st on st.id = s.cs_id
 where s.full_name is distinct from p.nome
    or s.entry_date is distinct from p.entrada
    or s.renewal_date is distinct from p.vencimento
    or s.status is distinct from p.status
    or coalesce(s.temperature,'') is distinct from coalesce(p.temperatura,'')
 order by p.nome;

-- 3.5 aniversários que a planilha tem sem o ano (ex: "15/08") ficaram de fora:
-- o sistema precisa da data completa. Peça esses à Thaís.
select s.full_name, s.email
  from planilha_thais p join students s on lower(s.email) = p.email
 where p.aniversario is null and s.birth_date is null
 order by s.full_name;

-- 3.6 quem vai sumir das telas da diretoria (encerrou a mentoria)
select p.nome, p.email, p.mentoria, p.cs
  from planilha_thais p
 where p.status_planilha = 'Encerrou Mentoria'
 order by p.mentoria, p.nome;

-- ============================================================
-- PARTE 4 — APLICAR. Só depois de conferir a PARTE 3.
-- ============================================================

-- 4.1 atualiza quem já existe (casando por e-mail)
update students s set
  full_name      = coalesce(p.nome, s.full_name),
  phone          = coalesce(p.telefone, s.phone),
  entry_date     = coalesce(p.entrada, s.entry_date),
  renewal_date   = coalesce(p.vencimento, s.renewal_date),
  status         = p.status,
  temperature    = coalesce(p.temperatura, s.temperature),
  renewal_status = coalesce(p.renovacao, s.renewal_status),
  notes          = coalesce(nullif(p.obs,''), s.notes),
  birth_date     = coalesce(p.aniversario, s.birth_date),
  instagram      = coalesce(p.instagram, s.instagram),
  especialidade  = coalesce(p.especialidade, s.especialidade),
  cidade_uf      = coalesce(p.cidade_uf, s.cidade_uf),
  respondeu_icp  = p.respondeu_icp,
  oculto_diretoria = (p.status_planilha = 'Encerrou Mentoria')
from planilha_thais p
where lower(s.email) = p.email;

-- 4.2 cria quem está na planilha e não existe
insert into students (full_name, email, phone, status, entry_date, renewal_date,
                      temperature, renewal_status, notes, birth_date, instagram,
                      especialidade, cidade_uf, respondeu_icp, oculto_diretoria, cs_id)
select p.nome, p.email, p.telefone, p.status, p.entrada, p.vencimento,
       p.temperatura, p.renovacao, nullif(p.obs,''), p.aniversario, p.instagram,
       p.especialidade, p.cidade_uf, p.respondeu_icp,
       (p.status_planilha = 'Encerrou Mentoria'),
       (select id from staff st where st.full_name ilike p.cs || '%' and st.is_active limit 1)
  from planilha_thais p
 where p.email is not null
   and not exists (select 1 from students s where lower(s.email) = p.email);

-- 4.3 CS responsável conforme a planilha
update students s
   set cs_id = st.id
  from planilha_thais p
  join staff st on st.full_name ilike p.cs || '%' and st.is_active
 where lower(s.email) = p.email;

-- 4.4 mentoria (entrega) conforme a planilha
insert into deliveries (student_id, branch_id, label, status, entry_date, renewal_date, cs_id)
select s.id, b.id, b.name, 'ativo', p.entrada, p.vencimento, s.cs_id
  from planilha_thais p
  join students s on lower(s.email) = p.email
  join branches b on b.name = p.mentoria
 where not exists (select 1 from deliveries d where d.student_id = s.id and d.branch_id = b.id);

update deliveries d set entry_date = p.entrada, renewal_date = p.vencimento
  from planilha_thais p
  join students s on lower(s.email) = p.email
  join branches b on b.name = p.mentoria
 where d.student_id = s.id and d.branch_id = b.id;

-- 4.5 quem encerrou: entregas desativadas
update deliveries d set status = 'inativo'
  from planilha_thais p join students s on lower(s.email) = p.email
 where d.student_id = s.id and p.status_planilha = 'Encerrou Mentoria';

-- ============================================================
-- PARTE 5 — a diretoria deixa de ver quem encerrou
-- ============================================================
drop policy if exists students_select_diretoria on students;
create policy students_select_diretoria on students
  for select to authenticated
  using (is_current_staff_diretoria() and coalesce(oculto_diretoria, false) = false);

notify pgrst, 'reload schema';

-- conferência final
select
  (select count(*) from students)                                as total,
  (select count(*) from students where oculto_diretoria)         as ocultos_da_diretoria,
  (select count(*) from students where status = 'ativo')         as ativos;
