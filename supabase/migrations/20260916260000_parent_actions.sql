-- ============================================================
-- Durus (دروس) — Migration 025: parent actions (absence excuses + receipts)
-- Parents move beyond read-only via token-validated RPCs (same precedent
-- as parent_mark_read) — no accounts, no RLS widening for writes:
-- - absence_excuses: one row per (student, date) excuse with reason.
--   parent_report_absence() stores it + notifies the assigned teacher
--   (type 'absence_excuse', mapped to the attendance category client-side).
--   The unique constraint doubles as double-send protection.
-- - parent_receipts: (student, kind, item) read confirmations for notes
--   and announcements. Teachers read aggregates via a school-scoped
--   select policy; all writes go through RPCs.
-- ============================================================

create table if not exists public.absence_excuses (
  id          uuid primary key default gen_random_uuid(),
  school_id   uuid not null,
  student_id  uuid not null references public.students (id) on delete cascade,
  excuse_date date not null,
  reason      text not null,
  created_at  timestamptz not null default now(),
  unique (student_id, excuse_date)
);
alter table public.absence_excuses enable row level security;

create table if not exists public.parent_receipts (
  id         uuid primary key default gen_random_uuid(),
  school_id  uuid not null,
  student_id uuid not null references public.students (id) on delete cascade,
  kind       text not null check (kind in ('note', 'announcement')),
  item_id    uuid not null,
  created_at timestamptz not null default now(),
  unique (student_id, kind, item_id)
);
alter table public.parent_receipts enable row level security;

-- Teachers/managers read aggregates for their own school.
create policy parent_receipts_select on public.parent_receipts
  for select using (school_id = public.current_school_id());
create policy absence_excuses_select on public.absence_excuses
  for select using (school_id = public.current_school_id());

-- ---------- RPC: report an absence excuse ----------
create or replace function public.parent_report_absence(
  p_token uuid, p_date date, p_reason text
)
returns void
language plpgsql security definer set search_path = public
as $$
declare
  v_student public.students%rowtype;
  v_reason  text;
begin
  select * into v_student from public.students where parent_token = p_token;
  if not found then
    raise exception 'invalid_token';
  end if;
  if p_date is null then
    raise exception 'bad_date';
  end if;
  v_reason := nullif(trim(coalesce(p_reason, '')), '');
  if v_reason is null then
    raise exception 'empty_reason';
  end if;
  if exists (
    select 1 from public.absence_excuses
    where student_id = v_student.id and excuse_date = p_date
  ) then
    raise exception 'already_exists';
  end if;
  insert into public.absence_excuses (school_id, student_id, excuse_date, reason)
  values (v_student.school_id, v_student.id, p_date, v_reason);
  insert into public.notifications
    (school_id, recipient_type, recipient_id, type, title, body, entity_ref)
  values (
    v_student.school_id, 'teacher', v_student.assigned_teacher_id,
    'absence_excuse', 'عذر غياب',
    v_student.name || ' — ' || p_date::text || ': ' || v_reason,
    jsonb_build_object('student_id', v_student.id, 'date', p_date::text)
  );
end $$;

-- ---------- RPC: list sent excuses ----------
create or replace function public.parent_excuses(p_token uuid)
returns jsonb
language plpgsql security definer set search_path = public
as $$
declare
  v_student uuid;
begin
  select id into v_student from public.students where parent_token = p_token;
  if not found then
    raise exception 'invalid_token';
  end if;
  return coalesce((
    select jsonb_agg(jsonb_build_object(
      'id', id, 'date', excuse_date, 'reason', reason,
      'created_at', created_at
    ) order by excuse_date desc)
    from public.absence_excuses
    where student_id = v_student
    limit 20
  ), '[]'::jsonb);
end $$;

-- ---------- RPC: confirm reading a note / announcement ----------
create or replace function public.parent_confirm_read(
  p_token uuid, p_kind text, p_item_id uuid
)
returns void
language plpgsql security definer set search_path = public
as $$
declare
  v_student public.students%rowtype;
begin
  select * into v_student from public.students where parent_token = p_token;
  if not found then
    raise exception 'invalid_token';
  end if;
  if p_kind not in ('note', 'announcement') then
    raise exception 'bad_kind';
  end if;
  if p_kind = 'note' then
    if not exists (
      select 1 from public.notes
      where id = p_item_id and student_id = v_student.id
    ) then
      raise exception 'not_found';
    end if;
  else
    if not exists (
      select 1 from public.announcements
      where id = p_item_id
        and school_id = v_student.school_id
        and audience in ('all', 'parents')
        and (expires_at is null or expires_at > now())
    ) then
      raise exception 'not_found';
    end if;
  end if;
  insert into public.parent_receipts (school_id, student_id, kind, item_id)
  values (v_student.school_id, v_student.id, p_kind, p_item_id)
  on conflict (student_id, kind, item_id) do nothing;
end $$;

-- ---------- RPC: list my confirmed receipts ----------
create or replace function public.parent_receipts(p_token uuid)
returns jsonb
language plpgsql security definer set search_path = public
as $$
declare
  v_student uuid;
begin
  select id into v_student from public.students where parent_token = p_token;
  if not found then
    raise exception 'invalid_token';
  end if;
  return coalesce((
    select jsonb_agg(jsonb_build_object('kind', kind, 'item_id', item_id))
    from public.parent_receipts
    where student_id = v_student
  ), '[]'::jsonb);
end $$;

grant execute on function public.parent_report_absence(uuid, date, text) to anon, authenticated;
grant execute on function public.parent_excuses(uuid) to anon, authenticated;
grant execute on function public.parent_confirm_read(uuid, text, uuid) to anon, authenticated;
grant execute on function public.parent_receipts(uuid) to anon, authenticated;
