-- v70: o que o aluno preenche no primeiro acesso.
--
-- `special_needs` faltava (necessidade especial / acessibilidade).
-- `perfil_completed_at` marca quem já preencheu a ficha.
-- `source` em feedback_entries separa o feedback do primeiro acesso do que a
-- CS registra no dia a dia (a categoria já diz se é sobre plataforma, CS ou
-- mentoria).

alter table students add column if not exists special_needs text;
alter table students add column if not exists perfil_completed_at timestamptz;
alter table feedback_entries add column if not exists source text;

notify pgrst, 'reload schema';

select 'ficha do primeiro acesso pronta' as ok;
