-- v56: confirmações de presença em eventos (respostas do Google Forms).
--
-- O Forms manda cada resposta, na hora, pra Edge Function `forms-webhook`
-- (um script no próprio formulário faz isso). A função grava aqui com a
-- service role; a Área CS lê e mostra na aba "Eventos".
--
-- Uma linha por resposta. O aluno é casado automaticamente por e-mail e, se
-- não der, por telefone (últimos 8 dígitos). O que sobrar sem par a CS liga
-- na mão pela tela.

create table if not exists event_rsvps (
  id            uuid primary key default gen_random_uuid(),
  event_key     text not null,                 -- ex: 'mentalidade-2026-10-17'
  response_id   text not null,                 -- id da resposta no Forms (ou "manual:<uuid>")
  submitted_at  timestamptz,
  email         text,
  full_name     text,
  badge_name    text,                          -- nome pra credencial
  phone         text,
  attending     boolean,                       -- vai participar?
  spouse        boolean,                       -- leva cônjuge?
  dietary       text,                          -- restrição alimentar (texto; vazio = não)
  special_needs text,                          -- necessidade especial
  raw           jsonb,                         -- todas as perguntas/respostas, como vieram
  student_id    uuid references students(id) on delete set null,
  matched_by    text,                          -- 'email' | 'phone' | 'manual' | null
  manual        boolean not null default false,-- marcado pela CS, não veio do Forms
  notes         text,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now(),
  unique (event_key, response_id)
);

create index if not exists event_rsvps_event_idx on event_rsvps (event_key);
create index if not exists event_rsvps_student_idx on event_rsvps (student_id);

-- ---------- casamento automático com o aluno ----------
create or replace function public.casa_rsvp_com_aluno()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_id uuid;
  v_tel text;
begin
  new.updated_at := now();
  if new.student_id is not null then
    return new;
  end if;
  if new.email is not null and length(trim(new.email)) > 0 then
    select id into v_id from students
     where lower(trim(email)) = lower(trim(new.email))
     limit 1;
    if v_id is not null then
      new.student_id := v_id; new.matched_by := 'email';
      return new;
    end if;
  end if;
  v_tel := right(regexp_replace(coalesce(new.phone, ''), '\D', '', 'g'), 8);
  if length(v_tel) = 8 then
    select id into v_id from students
     where right(regexp_replace(coalesce(phone, ''), '\D', '', 'g'), 8) = v_tel
     limit 1;
    if v_id is not null then
      new.student_id := v_id; new.matched_by := 'phone';
      return new;
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists event_rsvps_casa on event_rsvps;
create trigger event_rsvps_casa
  before insert or update of email, phone, student_id on event_rsvps
  for each row execute function public.casa_rsvp_com_aluno();

-- ---------- permissões ----------
alter table event_rsvps enable row level security;

-- Toda a equipe lê (é a lista do evento, não é dado por carteira).
drop policy if exists event_rsvps_select_staff on event_rsvps;
create policy event_rsvps_select_staff on event_rsvps
  for select to authenticated using (current_staff_id() is not null);

-- Toda a equipe pode marcar na mão / ligar aluno / anotar.
drop policy if exists event_rsvps_write_staff on event_rsvps;
create policy event_rsvps_write_staff on event_rsvps
  for all to authenticated
  using (current_staff_id() is not null)
  with check (current_staff_id() is not null);

-- Diretoria só lê.
drop policy if exists event_rsvps_select_diretoria on event_rsvps;
create policy event_rsvps_select_diretoria on event_rsvps
  for select to authenticated using (is_current_staff_diretoria());

grant select, insert, update, delete on event_rsvps to authenticated;

notify pgrst, 'reload schema';

select 'event_rsvps pronta' as ok;
