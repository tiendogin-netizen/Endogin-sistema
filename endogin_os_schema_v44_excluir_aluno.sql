-- =============================================================================
-- v44 — excluir aluno de verdade
-- Rode o arquivo inteiro no SQL Editor. Pode rodar mais de uma vez.
-- =============================================================================
--
-- O sistema nunca teve exclusão de aluno. O único "excluir" da ficha era o do
-- LOGIN, e como nenhum aluno tem login criado ele responde sempre
-- "esse aluno ainda não tem login criado" — que é a mensagem que a Thais está
-- batendo de frente.
--
-- Antes de usar, vale a pena saber o que se perde: excluir apaga o cadastro E
-- tudo que está preso nele (mentorias, progresso de aulas, NPS, feedbacks,
-- sessões 1x1, grupos de WhatsApp). Aluno que saiu da mentoria e fica com
-- status "inativo" continua contando no histórico e nos números da diretoria —
-- excluído, some do denominador e a base passa a parecer melhor do que foi.
-- Para quem cancelou, "inativo" costuma ser a resposta certa; excluir é para
-- cadastro duplicado, teste e erro de importação.
--
-- =============================================================================


create or replace function public.excluir_aluno(p_student_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $function$
declare
  v_nome     text;
  v_rel      record;
  v_apagados jsonb := '{}'::jsonb;
  v_n        bigint;
begin
  -- Mesma regra do resto do sistema: só a master (Thais) e o admin geral.
  -- Uma CS comum não pode apagar nem os alunos da própria carteira — apagar é
  -- de outra ordem que editar.
  if not is_current_staff_master() then
    raise exception 'Só a CS master ou o admin geral podem excluir um aluno.';
  end if;

  select full_name into v_nome from students where id = p_student_id;
  if v_nome is null then
    raise exception 'Aluno não encontrado.';
  end if;

  -- Descobre sozinha quem aponta para students(id), em vez de eu escrever uma
  -- lista de tabelas na mão. Assim uma tabela criada no ano que vem não
  -- transforma a exclusão num erro de chave estrangeira que ninguém entende.
  for v_rel in
    select c.conrelid::regclass::text as tabela,
           a.attname                  as coluna
    from pg_constraint c
    join lateral unnest(c.conkey) with ordinality as k(attnum, ord) on true
    join pg_attribute a on a.attrelid = c.conrelid and a.attnum = k.attnum
    where c.contype = 'f'
      and c.confrelid = 'public.students'::regclass
  loop
    execute format('delete from %s where %I = $1', v_rel.tabela, v_rel.coluna)
      using p_student_id;
    get diagnostics v_n = row_count;
    if v_n > 0 then
      v_apagados := v_apagados || jsonb_build_object(v_rel.tabela, v_n);
    end if;
  end loop;

  delete from students where id = p_student_id;

  -- Devolve o que foi apagado, tabela por tabela, para a tela mostrar à CS o
  -- tamanho real do que sumiu — e não só um "pronto".
  return jsonb_build_object('ok', true, 'aluno', v_nome, 'apagados', v_apagados);

exception
  when foreign_key_violation then
    raise exception 'Não consegui excluir % porque ainda existe registro ligado a ele. Detalhe do banco: %', v_nome, sqlerrm;
end
$function$;

revoke all on function public.excluir_aluno(uuid) from public;
grant execute on function public.excluir_aluno(uuid) to authenticated;

notify pgrst, 'reload schema';


-- -----------------------------------------------------------------------------
-- Conferência: o que está pendurado num aluno hoje.
-- Troque o UUID para ver, ANTES de excluir, o que sairia junto.
-- -----------------------------------------------------------------------------

select c.conrelid::regclass::text as tabela_ligada_ao_aluno,
       a.attname                  as coluna
from pg_constraint c
join lateral unnest(c.conkey) with ordinality as k(attnum, ord) on true
join pg_attribute a on a.attrelid = c.conrelid and a.attnum = k.attnum
where c.contype = 'f'
  and c.confrelid = 'public.students'::regclass
order by 1;
