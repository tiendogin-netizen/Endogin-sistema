-- v59: catálogo de aulas sincronizado com a Cademi.
-- courses.catalog_synced_at é o checkpoint da função cademi-sync-catalog:
-- produto sem carimbo (ou mais antigo) entra primeiro na fila.
alter table courses add column if not exists catalog_synced_at timestamptz;
create index if not exists course_lessons_cademi_idx on course_lessons (cademi_lesson_id);
notify pgrst, 'reload schema';
select 'catalogo pronto' as ok;
