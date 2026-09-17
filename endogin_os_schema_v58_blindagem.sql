-- v58: blindagem contra conteúdo malicioso vindo de fora.
--
-- Duas portas por onde texto de terceiros entra no banco e depois é mostrado
-- na tela da equipe: o próprio aluno (cadastro na Cademi, Portal, respostas
-- do formulário do Google, nome no Zoom) e o formulário. Um nome como
-- "<img onerror=...>" viraria script rodando no navegador da CS.
--
-- (1) limpa_html(): tira < e > de todo campo de texto ao gravar. Nome, e-mail
--     e telefone nunca têm esses caracteres de verdade, então nada se perde.
-- (2) O aluno só pode mudar no próprio cadastro os campos que o Portal
--     precisa (foto, nascimento, marcas de jornada, acessos). Qualquer outra
--     coluna (nome, e-mail, status, CS, vencimento...) fica bloqueada pra ele
--     mesmo que ele chame a API direto.

-- ---------- (1) ----------
create or replace function public.limpa_html()
returns trigger
language plpgsql
as $$
declare
  j jsonb := to_jsonb(new);
  k text;
  v jsonb;
  limpo jsonb := '{}'::jsonb;
begin
  for k, v in select * from jsonb_each(j) loop
    if jsonb_typeof(v) = 'string' and (v #>> '{}') ~ '[<>]' then
      limpo := limpo || jsonb_build_object(k, regexp_replace(v #>> '{}', '[<>]', '', 'g'));
    else
      limpo := limpo || jsonb_build_object(k, v);
    end if;
  end loop;
  new := jsonb_populate_record(new, limpo);
  return new;
end;
$$;

do $$
declare t text;
begin
  foreach t in array array[
    'students','event_rsvps','live_attendance_students','feedback_entries',
    'nps_responses','mentoring_sessions','staff'
  ]
  loop
    if to_regclass('public.' || t) is null then continue; end if;
    execute format('drop trigger if exists %I on public.%I', t || '_limpa_html', t);
    execute format('create trigger %I before insert or update on public.%I for each row execute function public.limpa_html()',
                   t || '_limpa_html', t);
  end loop;
end $$;

-- o que já estava gravado com < ou >
update students set
  full_name = regexp_replace(coalesce(full_name,''), '[<>]', '', 'g'),
  email     = regexp_replace(coalesce(email,''),     '[<>]', '', 'g'),
  phone     = regexp_replace(coalesce(phone,''),     '[<>]', '', 'g')
where coalesce(full_name,'') ~ '[<>]' or coalesce(email,'') ~ '[<>]' or coalesce(phone,'') ~ '[<>]';

-- ---------- (2) ----------
create or replace function public.aluno_so_muda_o_seu()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  permitidas text[] := array['photo_url','birth_date','onboarding_completed_at','disc_completed_at','first_login_at','last_login_at','updated_at'];
  antes jsonb; depois jsonb;
begin
  -- equipe (CS, master, diretoria) e service role passam direto
  if current_staff_id() is not null or is_current_staff_diretoria() then return new; end if;
  if auth.uid() is null then return new; end if;  -- service role / jobs
  -- aluno logado mexendo no próprio cadastro: só as colunas permitidas
  antes := to_jsonb(old) - permitidas;
  depois := to_jsonb(new) - permitidas;
  if antes <> depois then
    raise exception 'Aluno só pode alterar foto, aniversário e marcas de jornada no próprio cadastro.';
  end if;
  return new;
end;
$$;

drop trigger if exists students_aluno_so_muda_o_seu on students;
create trigger students_aluno_so_muda_o_seu
  before update on students
  for each row execute function public.aluno_so_muda_o_seu();

notify pgrst, 'reload schema';

select 'blindagem aplicada' as ok;
