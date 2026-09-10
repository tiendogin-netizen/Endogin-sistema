-- v50 - vencimento por mentoria, e a data do aluno passa a ser derivada
--
-- Cada mentoria do aluno ganha o proprio vencimento (deliveries.renewal_date),
-- como ja tinha a entrada (v49). E a data do ALUNO (students.entry_date /
-- renewal_date) deixa de ser digitada: passa a ser calculada pelo banco a
-- partir das mentorias ativas — primeira entrada e vencimento mais proximo.
--
-- Por que no banco e nao na tela: se a tela calcula, qualquer outro caminho
-- que escreva em deliveries (importacao, webhook, SQL) deixaria o aluno com
-- a data velha. Gatilho garante que os dois lugares nunca discordam.
--
-- Aluno sem nenhuma mentoria ativa com data fica como esta: nao ha de onde
-- derivar, e a ficha volta a deixar digitar.

alter table deliveries
  add column if not exists renewal_date date;

-- Preenche sem inventar: so quem tem UMA mentoria ativa recebe o vencimento
-- do aluno, porque ali as duas datas sao a mesma coisa.
update deliveries d
   set renewal_date = s.renewal_date
  from students s
 where s.id = d.student_id
   and d.renewal_date is null
   and s.renewal_date is not null
   and d.status = 'ativo'
   and (select count(*) from deliveries d2 where d2.student_id = s.id and d2.status = 'ativo') = 1;

-- O gatilho. Security definer porque roda com a permissao de quem editou a
-- entrega, e a RLS de students podia nao deixar essa pessoa escrever ali.
create or replace function public.sincroniza_datas_do_aluno()
returns trigger
language plpgsql
security definer
set search_path = public
as $function$
declare
  v_student uuid := coalesce(new.student_id, old.student_id);
  v_entrada date;
  v_venc    date;
begin
  select min(entry_date), min(renewal_date)
    into v_entrada, v_venc
  from deliveries
  where student_id = v_student and status = 'ativo';

  update students
     set entry_date   = coalesce(v_entrada, entry_date),
         renewal_date = coalesce(v_venc, renewal_date)
   where id = v_student
     and (entry_date   is distinct from coalesce(v_entrada, entry_date)
       or renewal_date is distinct from coalesce(v_venc, renewal_date));

  return null;
end
$function$;

drop trigger if exists trg_sincroniza_datas_do_aluno on deliveries;
create trigger trg_sincroniza_datas_do_aluno
  after insert or update of entry_date, renewal_date, status or delete
  on deliveries
  for each row execute function public.sincroniza_datas_do_aluno();

-- Aplica a regra na base que ja existe, uma vez.
update students s
   set entry_date   = coalesce(x.ent, s.entry_date),
       renewal_date = coalesce(x.ven, s.renewal_date)
  from (
    select student_id, min(entry_date) as ent, min(renewal_date) as ven
    from deliveries where status = 'ativo' group by student_id
  ) x
 where x.student_id = s.id
   and (s.entry_date is distinct from coalesce(x.ent, s.entry_date)
     or s.renewal_date is distinct from coalesce(x.ven, s.renewal_date));

notify pgrst, 'reload schema';

-- conferencia
select count(*) filter (where renewal_date is not null) as entregas_com_vencimento,
       count(*) filter (where renewal_date is null)     as entregas_sem_vencimento_para_a_cs_preencher,
       count(*)                                          as entregas_ativas
from deliveries
where status = 'ativo';
