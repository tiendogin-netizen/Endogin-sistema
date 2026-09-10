-- v49 - data de entrada por mentoria
-- O aluno pode ter entrado na Mae em janeiro e na Start em fevereiro. Uma
-- data so por aluno (students.entry_date) nao representa isso. A data passa
-- a existir tambem em cada entrega (deliveries), e a ficha grava uma por
-- mentoria marcada.
--
-- students.entry_date continua existindo: e a data da primeira entrada, e
-- as telas antigas seguem lendo dela. A partir de agora, quem quiser saber
-- "quando entrou NESTA mentoria" olha deliveries.entry_date.

alter table deliveries
  add column if not exists entry_date date;

-- Preenche o que da para preencher sem inventar: a entrega ativa de quem so
-- tem UMA mentoria recebe a data de entrada do aluno, porque nesse caso as
-- duas datas sao a mesma coisa. Quem tem duas ou mais mentorias fica em
-- branco para a CS preencher — ali o sistema nao tem como saber.
update deliveries d
   set entry_date = s.entry_date
  from students s
 where s.id = d.student_id
   and d.entry_date is null
   and s.entry_date is not null
   and d.status = 'ativo'
   and (select count(*) from deliveries d2 where d2.student_id = s.id and d2.status = 'ativo') = 1;

notify pgrst, 'reload schema';

-- conferencia: quantas entregas ativas ficaram com data, e quantas ficaram
-- em branco (alunos com mais de uma mentoria - a CS preenche na ficha)
select count(*) filter (where entry_date is not null) as entregas_com_data,
       count(*) filter (where entry_date is null)     as entregas_sem_data_para_a_cs_preencher,
       count(*)                                        as entregas_ativas
from deliveries
where status = 'ativo';
