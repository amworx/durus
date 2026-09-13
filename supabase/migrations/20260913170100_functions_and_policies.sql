-- ============================================================
-- Durus (دروس) — Migration 002: security helpers, RLS policies,
-- RPCs, grants. Runs after tables exist (migration 001).
-- ============================================================

-- ---------- 1. SECURITY HELPERS ----------
create or replace function public.current_school_id()
returns uuid
language sql stable security definer set search_path = public
as $$
  select case when p.is_manager then p.id else p.manager_id end
  from public.profiles p
  where p.id = auth.uid()
$$;

create or replace function public.is_manager()
returns boolean
language sql stable security definer set search_path = public
as $$
  select coalesce((select p.is_manager from public.profiles p where p.id = auth.uid()), false)
$$;

create or replace function public.can_access_student(p_student uuid)
returns boolean
language sql stable security definer set search_path = public
as $$
  select exists (
    select 1 from public.students s
    where s.id = p_student
      and s.school_id = public.current_school_id()
      and (public.is_manager() or s.assigned_teacher_id = auth.uid())
  )
$$;

-- ---------- 2. RLS POLICIES ----------

-- PROFILES
create policy profiles_select on public.profiles for select using (
  id = auth.uid()
  or manager_id = auth.uid()
  or (school_id = public.current_school_id() and public.is_manager())
);
create policy profiles_update_self on public.profiles for update using (
  id = auth.uid()
) with check (
  id = auth.uid()
  and is_manager = (select p.is_manager from public.profiles p where p.id = auth.uid())
);

-- SUBJECTS
create policy subjects_select on public.subjects for select using (school_id = public.current_school_id());
create policy subjects_insert on public.subjects for insert with check (school_id = public.current_school_id());
create policy subjects_update on public.subjects for update using (school_id = public.current_school_id()) with check (school_id = public.current_school_id());
create policy subjects_delete on public.subjects for delete using (school_id = public.current_school_id());

-- STUDENTS
create policy students_select on public.students for select using (
  school_id = public.current_school_id()
  and (public.is_manager() or assigned_teacher_id = auth.uid())
);
create policy students_insert on public.students for insert with check (
  school_id = public.current_school_id()
  and (public.is_manager() or assigned_teacher_id = auth.uid())
);
create policy students_update on public.students for update using (
  school_id = public.current_school_id()
  and (public.is_manager() or assigned_teacher_id = auth.uid())
) with check (
  school_id = public.current_school_id()
  and (public.is_manager() or assigned_teacher_id = auth.uid())
);
create policy students_delete on public.students for delete using (
  school_id = public.current_school_id()
  and (public.is_manager() or assigned_teacher_id = auth.uid())
);

-- STUDENT_SUBJECTS
create policy student_subjects_select on public.student_subjects for select using (public.can_access_student(student_id));
create policy student_subjects_insert on public.student_subjects for insert with check (public.can_access_student(student_id));
create policy student_subjects_delete on public.student_subjects for delete using (public.can_access_student(student_id));

-- RECURRING SLOTS
create policy slots_select on public.recurring_slots for select using (public.can_access_student(student_id));
create policy slots_insert on public.recurring_slots for insert with check (public.can_access_student(student_id));
create policy slots_update on public.recurring_slots for update using (public.can_access_student(student_id)) with check (public.can_access_student(student_id));
create policy slots_delete on public.recurring_slots for delete using (public.can_access_student(student_id));

-- SESSIONS
create policy sessions_select on public.sessions for select using (public.can_access_student(student_id));
create policy sessions_insert on public.sessions for insert with check (public.can_access_student(student_id));
create policy sessions_update on public.sessions for update using (public.can_access_student(student_id)) with check (public.can_access_student(student_id));
create policy sessions_delete on public.sessions for delete using (public.can_access_student(student_id));

-- FEES
create policy fees_select on public.fees for select using (public.can_access_student(student_id));
create policy fees_insert on public.fees for insert with check (public.can_access_student(student_id));
create policy fees_update on public.fees for update using (public.can_access_student(student_id)) with check (public.can_access_student(student_id));
create policy fees_delete on public.fees for delete using (public.can_access_student(student_id));

-- PAYMENTS
create policy payments_select on public.payments for select using (public.can_access_student(student_id));
create policy payments_insert on public.payments for insert with check (public.can_access_student(student_id));
create policy payments_update on public.payments for update using (public.can_access_student(student_id)) with check (public.can_access_student(student_id));
create policy payments_delete on public.payments for delete using (public.can_access_student(student_id));

-- TESTS
create policy tests_select on public.tests for select using (public.can_access_student(student_id));
create policy tests_insert on public.tests for insert with check (public.can_access_student(student_id));
create policy tests_update on public.tests for update using (public.can_access_student(student_id)) with check (public.can_access_student(student_id));
create policy tests_delete on public.tests for delete using (public.can_access_student(student_id));

-- NOTES
create policy notes_select on public.notes for select using (public.can_access_student(student_id));
create policy notes_insert on public.notes for insert with check (public.can_access_student(student_id) and author_id = auth.uid());
create policy notes_update on public.notes for update using (public.can_access_student(student_id)) with check (public.can_access_student(student_id));
create policy notes_delete on public.notes for delete using (public.can_access_student(student_id));

-- REPORTS
create policy reports_select on public.reports for select using (public.can_access_student(student_id));
create policy reports_insert on public.reports for insert with check (public.can_access_student(student_id));
create policy reports_delete on public.reports for delete using (public.can_access_student(student_id));

-- ANNOUNCEMENTS
create policy announcements_select on public.announcements for select using (school_id = public.current_school_id());
create policy announcements_insert on public.announcements for insert with check (school_id = public.current_school_id() and author_id = auth.uid());
create policy announcements_delete on public.announcements for delete using (school_id = public.current_school_id() and author_id = auth.uid());

-- INVITATIONS (manager only)
create policy invitations_select on public.invitations for select using (public.is_manager() and school_id = public.current_school_id());
create policy invitations_insert on public.invitations for insert with check (public.is_manager() and school_id = public.current_school_id());
create policy invitations_delete on public.invitations for delete using (public.is_manager() and school_id = public.current_school_id());

-- ---------- 3. RPCs ----------

-- Create a teacher account directly (manager shares credentials).
create or replace function public.create_teacher_with_credentials(p_email text, p_password text, p_full_name text)
returns uuid
language plpgsql security definer set search_path = public, auth
as $$
declare
  v_school uuid := public.current_school_id();
  v_id     uuid;
begin
  if not public.is_manager() or v_school is null then
    raise exception 'forbidden';
  end if;
  select id into v_id from auth.users where email = p_email;
  if v_id is not null then
    raise exception 'email_exists';
  end if;
  v_id := (auth.admin_create_user(
    email := p_email,
    password := p_password,
    email_confirm := true,
    user_metadata := jsonb_build_object('full_name', p_full_name)
  )).id;
  update public.profiles
     set school_id = v_school, is_manager = false, role = 'teacher',
         manager_id = auth.uid(), full_name = p_full_name
   where id = v_id;
  return v_id;
end $$;

-- Look up an invitation by token (used during teacher signup).
create or replace function public.invitation_for(p_token uuid)
returns table (school_id uuid, email text)
language sql security definer set search_path = public
as $$
  select i.school_id, i.email
  from public.invitations i
  where i.token = p_token and i.status = 'pending' and i.expires_at > now()
$$;

-- Accept an invitation: links the current user to the school as a teacher.
create or replace function public.accept_invitation(p_token uuid)
returns void
language plpgsql security definer set search_path = public
as $$
declare
  v public.invitations%rowtype;
begin
  select * into v from public.invitations
  where token = p_token and status = 'pending' and expires_at > now();
  if not found then
    raise exception 'invalid_invitation';
  end if;
  update public.profiles
     set school_id = v.school_id, is_manager = false, role = 'teacher',
         manager_id = v.manager_id
   where id = auth.uid();
  update public.invitations
     set status = 'accepted', accepted_at = now()
   where id = v.id;
end $$;

-- Parent portal data. p_token is the secret link token (uuid) stored on the
-- student row. Anon can call this; the token is the bearer credential.
create or replace function public.parent_portal(p_token uuid)
returns jsonb
language plpgsql security definer set search_path = public
as $$
declare
  v_student public.students%rowtype;
  v_school  uuid;
  v_fee     jsonb;
  v_att     jsonb;
begin
  select * into v_student from public.students where parent_token = p_token;
  if not found then
    raise exception 'invalid_token';
  end if;
  v_school := v_student.school_id;

  select jsonb_build_object(
    'month', f.month, 'amount', f.amount, 'paid_amount', f.paid_amount,
    'status', f.status, 'due_date', f.due_date
  ) into v_fee
  from public.fees f
  where f.student_id = v_student.id
  order by f.month desc
  limit 1;

  v_att := coalesce((
    select jsonb_build_object(
      'total', count(*)::int,
      'present', count(*) filter (where s.attendance = 'present')::int,
      'absent', count(*) filter (where s.attendance = 'absent')::int,
      'rescheduled', count(*) filter (where s.attendance = 'rescheduled')::int,
      'recent', coalesce((
        select jsonb_agg(jsonb_build_object(
          'date', s3.date, 'status', s3.attendance,
          'note', coalesce(s3.note, ''), 'subject', coalesce(sub3.name, '')
        ))
        from (select * from public.sessions where student_id = v_student.id order by date desc limit 14) s3
        left join public.subjects sub3 on sub3.id = s3.subject_id
      ), '[]'::jsonb)
    )
    from public.sessions s
    where s.student_id = v_student.id and s.date >= (current_date - interval '30 days')
  ), '{}'::jsonb);

  return jsonb_build_object(
    'student', jsonb_build_object(
      'id', v_student.id, 'name', v_student.name, 'grade', coalesce(v_student.grade, '')
    ),
    'subjects', coalesce((
      select jsonb_agg(sub.name)
      from public.student_subjects ss
      join public.subjects sub on sub.id = ss.subject_id
      where ss.student_id = v_student.id
    ), '[]'::jsonb),
    'schedule', coalesce((
      select jsonb_agg(jsonb_build_object(
        'day_of_week', r.day_of_week, 'start_minutes', r.start_minutes,
        'end_minutes', r.end_minutes, 'location', r.location,
        'subject', coalesce(sub3.name, '')
      ))
      from (select * from public.recurring_slots where student_id = v_student.id and active) r
      left join public.subjects sub3 on sub3.id = r.subject_id
    ), '[]'::jsonb),
    'attendance', v_att,
    'fee', coalesce(v_fee, '{}'::jsonb),
    'tests', coalesce((
      select jsonb_agg(jsonb_build_object(
        'subject', coalesce(t.subject_name, ''), 'type', t.type, 'date', t.date,
        'score', t.score, 'max_score', t.max_score, 'note', coalesce(t.note, '')
      ))
      from (
        select t.*, sub.name as subject_name
        from public.tests t
        left join public.subjects sub on sub.id = t.subject_id
        where t.student_id = v_student.id
        order by t.date desc
        limit 10
      ) t
    ), '[]'::jsonb),
    'notes', coalesce((
      select jsonb_agg(jsonb_build_object(
        'body', n.body, 'created_at', n.created_at
      ))
      from (select * from public.notes where student_id = v_student.id order by created_at desc limit 10) n
    ), '[]'::jsonb),
    'announcements', coalesce((
      select jsonb_agg(jsonb_build_object(
        'body', a.body, 'created_at', a.created_at
      ))
      from (select * from public.announcements where school_id = v_school order by created_at desc limit 5) a
    ), '[]'::jsonb)
  );
end $$;

-- ---------- 4. Grants ----------
grant execute on function public.create_teacher_with_credentials(text, text, text) to authenticated;
grant execute on function public.invitation_for(uuid) to anon, authenticated;
grant execute on function public.accept_invitation(uuid) to authenticated;
grant execute on function public.parent_portal(uuid) to anon, authenticated;