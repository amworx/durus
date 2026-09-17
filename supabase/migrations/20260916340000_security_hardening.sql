-- ============================================================
-- Durus (دروس) — Migration 034: security hardening (pentest findings)
--
-- 1) Numeric bounds: fees.amount >= 0, tests.score >= 0,
--    tests.max_score > 0 (negative fees were storable; amounts feed
--    status math and income totals, so garbage here corrupts money).
-- 2) profiles_update_self now pins every column the client never
--    legitimately writes (school/manager/role/email/active/onboarded).
--    PROVEN EXPLOIT fixed: a teacher rewrote manager_id to another
--    school and current_school_id() followed, leaking that school's
--    subjects/announcements and planting rows in it. IS NOT DISTINCT
--    FROM (not =) so NULLs compare sanely and managers can't lock
--    themselves out. All legit writes to pinned columns already flow
--    through security-definer RPCs (complete_onboarding,
--    accept_invitation, create_teacher, set_teacher_active).
-- 3) announcements_insert: audience 'all' is manager-only; teachers keep
--    'parents'/'teachers' (parent-spam gate).
-- 4) parent_family(): scope siblings to the same school (defense in
--    depth; family UUIDs are unguessable, but scoping is free).
-- 5) Length caps on free-text columns as NOT VALID constraints: all
--    future writes are bounded, existing rows are never touched, so the
--    migration cannot fail on legacy data.
-- ============================================================

-- ---------- 1. numeric bounds ----------
alter table public.fees drop constraint if exists fees_amount_check;
alter table public.fees add constraint fees_amount_check check (amount >= 0);

alter table public.tests drop constraint if exists tests_score_check;
alter table public.tests
  add constraint tests_score_check check (score is null or score >= 0);
alter table public.tests drop constraint if exists tests_max_score_check;
alter table public.tests
  add constraint tests_max_score_check check (max_score is null or max_score > 0);

-- ---------- 2. pin the self-update policy ----------
drop policy if exists profiles_update_self on public.profiles;
create policy profiles_update_self on public.profiles
  for update using (id = auth.uid())
  with check (
    id = auth.uid()
    and is_manager is not distinct from
      (select p.is_manager from public.profiles p where p.id = auth.uid())
    and school_id is not distinct from
      (select p.school_id from public.profiles p where p.id = auth.uid())
    and manager_id is not distinct from
      (select p.manager_id from public.profiles p where p.id = auth.uid())
    and role is not distinct from
      (select p.role from public.profiles p where p.id = auth.uid())
    and email is not distinct from
      (select p.email from public.profiles p where p.id = auth.uid())
    and active is not distinct from
      (select p.active from public.profiles p where p.id = auth.uid())
    and onboarded is not distinct from
      (select p.onboarded from public.profiles p where p.id = auth.uid())
  );

-- ---------- 3. announcements audience gate ----------
drop policy if exists announcements_insert on public.announcements;
create policy announcements_insert on public.announcements
  for insert with check (
    school_id = public.current_school_id()
    and author_id = auth.uid()
    and (audience in ('parents', 'teachers') or public.is_manager())
  );

-- ---------- 4. family scope ----------
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
      and school_id = v_student.school_id
      and parent_token is not null
  ), '[]'::jsonb);
end $$;

-- ---------- 5. length caps (NOT VALID: future writes only) ----------
alter table public.students add constraint students_name_len check (char_length(name) <= 100) not valid;
alter table public.students add constraint students_parent_name_len check (parent_name is null or char_length(parent_name) <= 100) not valid;
alter table public.students add constraint students_parent_phone_len check (parent_phone is null or char_length(parent_phone) <= 30) not valid;
alter table public.students add constraint students_notes_len check (notes is null or char_length(notes) <= 2000) not valid;
alter table public.students add constraint students_grade_len check (grade is null or char_length(grade) <= 60) not valid;
alter table public.subjects add constraint subjects_name_len check (char_length(name) <= 100) not valid;
alter table public.subjects add constraint subjects_notes_len check (notes is null or char_length(notes) <= 2000) not valid;
alter table public.subjects add constraint subjects_grade_len check (grade is null or char_length(grade) <= 60) not valid;
alter table public.announcements add constraint announcements_title_len check (title is null or char_length(title) <= 200) not valid;
alter table public.announcements add constraint announcements_body_len check (char_length(body) <= 5000) not valid;
alter table public.tests add constraint tests_note_len check (note is null or char_length(note) <= 1000) not valid;
alter table public.fees add constraint fees_notes_len check (notes is null or char_length(notes) <= 1000) not valid;
alter table public.payments add constraint payments_note_len check (note is null or char_length(note) <= 1000) not valid;
alter table public.sessions add constraint sessions_note_len check (note is null or char_length(note) <= 1000) not valid;
alter table public.sessions add constraint sessions_topics_len check (topics is null or char_length(topics) <= 1000) not valid;
alter table public.sessions add constraint sessions_homework_len check (homework is null or char_length(homework) <= 1000) not valid;
alter table public.profiles add constraint profiles_full_name_len check (full_name is null or char_length(full_name) <= 100) not valid;
alter table public.profiles add constraint profiles_bio_len check (bio is null or char_length(bio) <= 500) not valid;
alter table public.profiles add constraint profiles_phone_len check (phone is null or char_length(phone) <= 30) not valid;
