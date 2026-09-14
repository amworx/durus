-- ============================================================
-- Durus (دروس) — Migration 007: teacher status (active flag).
-- Manager can enable/disable teacher accounts; disabled teachers
-- are blocked at the app gate. RLS only allows self-update of
-- profiles, so the toggle goes through a security-definer RPC.
-- ============================================================

alter table public.profiles add column if not exists active boolean not null default true;

create index if not exists idx_profiles_school on public.profiles (school_id);

-- Manager toggles a teacher's active flag. The manager themself is
-- excluded (is_manager = false) so they can never deactivate themselves.
create or replace function public.set_teacher_active(p_teacher uuid, p_active boolean)
returns void
language plpgsql security definer set search_path = public
as $$
begin
  if not public.is_manager() or public.current_school_id() is null then
    raise exception 'forbidden';
  end if;
  update public.profiles
     set active = p_active
   where id = p_teacher
     and school_id = public.current_school_id()
     and is_manager = false;
  if not found then
    raise exception 'teacher_not_found';
  end if;
end $$;

grant execute on function public.set_teacher_active(uuid, boolean) to authenticated;