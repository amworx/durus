-- ============================================================
-- Durus (دروس) — Migration 024: manual family linking + guardian relation
-- - students.family_id (uuid, nullable, indexed): teachers link siblings
--   explicitly (manual linking is required — no auto-grouping). Members
--   of one family share the parent portal via parent_family().
-- - students.parent_relation (text): guardian kinship (أب/أم/أخ/...),
--   free text validated client-side against preset labels.
-- - parent_family(p_token): returns the linked siblings (id, name, grade,
--   token) for the portal child switcher; single row when unlinked.
--   Same privilege shape as parent_portal (token-validated, anon-safe).
-- RLS: no policy change — teachers already update own-school student rows.
-- ============================================================

alter table public.students
  add column if not exists family_id uuid,
  add column if not exists parent_relation text;

create index if not exists idx_students_family
  on public.students (school_id, family_id);

create or replace function public.parent_family(p_token uuid)
returns jsonb
language plpgsql security definer set search_path = public
as $$
declare
  v_student public.students%rowtype;
begin
  select * into v_student from public.students where parent_token = p_token;
  if not found then
    raise exception 'invalid_token';
  end if;
  if v_student.family_id is null then
    return jsonb_build_array(jsonb_build_object(
      'id', v_student.id, 'name', v_student.name,
      'grade', coalesce(v_student.grade, ''), 'token', v_student.parent_token
    ));
  end if;
  return coalesce((
    select jsonb_agg(jsonb_build_object(
      'id', id, 'name', name,
      'grade', coalesce(grade, ''), 'token', parent_token
    ) order by name)
    from public.students
    where family_id = v_student.family_id
      and parent_token is not null
  ), '[]'::jsonb);
end $$;

grant execute on function public.parent_family(uuid) to anon, authenticated;
