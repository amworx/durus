-- ============================================================
-- Durus (دروس) — Migration 029: excuse dates must attach to sessions
-- Critical integrity guard: an absence excuse is meaningless on a day
-- the student has nothing scheduled. parent_report_absence() now
-- rejects dates with neither a recorded session nor an active slot on
-- that weekday ('no_session'). The portal date picker enforces the same
-- rule client-side; this is the unbypassable server half.
-- ISODOW (1=Mon..7=Sun) matches recurring_slots.day_of_week.
-- ============================================================

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
  if not exists (
    select 1 from public.sessions
    where student_id = v_student.id and date = p_date
  ) and not exists (
    select 1 from public.recurring_slots
    where student_id = v_student.id
      and active
      and day_of_week = extract(isodow from p_date)::int
  ) then
    raise exception 'no_session';
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
