-- =============================================================================
-- v46 - checagem de duplicado para a importacao por planilha
-- Rode o arquivo inteiro no SQL Editor. Pode rodar mais de uma vez.
-- =============================================================================
--
-- O PROBLEMA
--
-- O importador pergunta "esse e-mail ja existe?" com um select comum, e select
-- comum passa pela RLS. Para a Thais (master) a resposta e verdadeira, porque
-- ela enxerga a base inteira. Para uma CS, a consulta so alcanca a carteira
-- dela: se o aluno existe mas e de outra CS, a resposta volta VAZIA, o
-- importador conclui "e novo", tenta criar, e o banco recusa com
-- "duplicate key value violates unique constraint students_email_key".
--
-- A CS nao tem como entender esse erro, porque para ela aquele aluno nao
-- existe em lugar nenhum.
--
-- O QUE ESTA FUNCAO FAZ
--
-- Roda como dona do banco (security definer), entao enxerga a base toda, mas
-- devolve o minimo: se existe, de qual CS e, e se e da propria pessoa que
-- perguntou. NAO devolve nome, telefone, status nem qualquer dado do aluno de
-- outra carteira. O e-mail quem trouxe foi a propria CS, na planilha dela.
--
-- O id so sai quando quem pergunta tem direito de escrever naquele aluno
-- (e da carteira dela, ou e master) - sem isso o id viraria uma chave para
-- alterar aluno alheio por fora da tela.
-- =============================================================================


create or replace function public.checar_email_aluno(p_email text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $function$
declare
  v_id      uuid;
  v_cs_id   uuid;
  v_cs_nome text;
  v_minha   boolean;
  v_master  boolean;
begin
  if not is_current_staff_ativa() then
    raise exception 'Apenas a equipe ativa pode consultar.';
  end if;

  v_master := is_current_staff_master();

  select s.id, s.cs_id, st.full_name
    into v_id, v_cs_id, v_cs_nome
  from students s
  left join staff st on st.id = s.cs_id
  where lower(s.email) = lower(trim(p_email))
  limit 1;

  if v_id is null then
    return jsonb_build_object('existe', false);
  end if;

  v_minha := (v_cs_id is not null and v_cs_id = current_staff_id());

  return jsonb_build_object(
    'existe',  true,
    'minha',   v_minha,
    'cs_nome', coalesce(v_cs_nome, 'sem CS'),
    -- id so para quem pode escrever nesse aluno
    'id',      case when v_minha or v_master then v_id else null end
  );
end
$function$;

revoke all on function public.checar_email_aluno(text) from public;
grant execute on function public.checar_email_aluno(text) to authenticated;

notify pgrst, 'reload schema';


-- -----------------------------------------------------------------------------
-- Conferencia. Troque o e-mail por um que exista na base e rode: deve voltar
-- existe = true e o nome da CS responsavel.
-- -----------------------------------------------------------------------------

select public.checar_email_aluno('adriellylage1@gmail.com') as resposta_para_email_inexistente;
