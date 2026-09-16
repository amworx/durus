-- ============================================================
-- Durus (دروس) — Sessions upgrade: 5 attendance states + lesson fields
-- 1) attendance: present/absent/late/rescheduled/cancelled
-- 2) sessions += topics (الموضوع المُنجز), homework (الواجب), rescheduled_to
-- 3) triggers + reports + parent_portal handle the new states/fields
-- Idempotent-ish: guard constraints/columns; functions are create-or-replace.
-- ============================================================

-- ---------- 1. ATTENDANCE STATES ----------
alter table public.sessions drop constraint if exists sessions_attendance_check;
alter table public.sessions add constraint sessions_attendance_check
  check (attendance in ('present','absent','late','rescheduled','cancelled'));

-- ---------- 2. LESSON FIELDS ----------
alter table public.sessions add column if not exists topics text;
alter table public.sessions add column if not exists homework text;
alter table public.sessions add column if not exists rescheduled_to date;

-- ---------- 3. NOTIFY TRIGGER: late + cancelled ----------
create or replace function public.notify_session_change()
returns trigger language plpgsql security definer set search_path = public
as $$
declare v_student_name text; v_subject_name text;
begin
  select name into v_student_name from public.students where id = new.student_id;
  select coalesce(name, '') into v_subject_name from public.subjects where id = new.subject_id;
  insert into public.notifications (school_id, recipient_type, recipient_id, type, title, body, entity_ref)
  values (
    new.school_id, 'parent', new.student_id, 'attendance',
    case new.attendance
      when 'present' then 'تحديث الحضور'
      when 'absent' then 'تحديث الغياب'
      when 'late' then 'تحديث التأخر'
      when 'rescheduled' then 'تأجيل جلسة'
      else 'إلغاء جلسة'
    end,
    case new.attendance
      when 'present' then 'تم تسجيل حضور ' || v_student_name || case when v_subject_name = '' then '' else ' — ' || v_subject_name end
      when 'absent' then 'تم تسجيل غياب ' || v_student_name || case when v_subject_name = '' then '' else ' — ' || v_subject_name end
      when 'late' then 'تم تسجيل تأخر ' || v_student_name || case when v_subject_name = '' then '' else ' — ' || v_subject_name end
      when 'rescheduled' then 'تم تأجيل جلسة ' || v_student_name || case when v_subject_name = '' then '' else ' — ' || v_subject_name end
      else 'تم إلغاء جلسة ' || v_student_name || case when v_subject_name = '' then '' else ' — ' || v_subject_name end
    end,
    jsonb_build_object('table', 'sessions', 'id', new.id)
  );
  return new;
end $$;

drop trigger if exists trg_notify_session on public.sessions;
create trigger trg_notify_session
  after insert or update on public.sessions
  for each row execute procedure public.notify_session_change();

-- ---------- 4. REPORT: attendance buckets incl. late/cancelled ----------
create or replace function public.generate_report(p_student uuid, p_month text)
returns jsonb
language plpgsql security definer set search_path = public
as $$
declare
  v_student public.students%rowtype;
  v_from date;
  v_to   date;
  v_att   jsonb;
  v_fee   jsonb;
  v_tests jsonb;
  v_notes jsonb;
  v_summary jsonb;
begin
  if not public.can_access_student(p_student) then
    raise exception 'forbidden';
  end if;

  select * into v_student from public.students where id = p_student;
  if not found then
    raise exception 'not_found';
  end if;

  if p_month !~ '^\d{4}-(0[1-9]|1[0-2])$' then
    raise exception 'invalid_month';
  end if;

  v_from := to_date(p_month || '-01', 'YYYY-MM-DD');
  v_to   := (v_from + interval '1 month')::date;

  v_att := coalesce((
    select jsonb_build_object(
      'total', count(*)::int,
      'present', count(*) filter (where attendance = 'present')::int,
      'absent', count(*) filter (where attendance = 'absent')::int,
      'late', count(*) filter (where attendance = 'late')::int,
      'rescheduled', count(*) filter (where attendance = 'rescheduled')::int,
      'cancelled', count(*) filter (where attendance = 'cancelled')::int
    )
    from public.sessions
    where student_id = p_student and date >= v_from and date < v_to
  ), '{}'::jsonb);

  v_fee := coalesce((
    select jsonb_build_object(
      'month', f.month, 'amount', f.amount,
      'paid_amount', f.paid_amount, 'status', f.status, 'due_date', f.due_date
    )
    from public.fees f
    where f.student_id = p_student and f.month = p_month
    limit 1
  ), '{}'::jsonb);

  v_tests := coalesce((
    select jsonb_agg(jsonb_build_object(
      'subject', coalesce(sub.name, ''), 'type', t.type, 'date', t.date,
      'score', t.score, 'max_score', t.max_score, 'note', coalesce(t.note, '')
    ))
    from (select * from public.tests
          where student_id = p_student and date >= v_from and date < v_to
          order by date desc limit 5) t
    left join public.subjects sub on sub.id = t.subject_id
  ), '[]'::jsonb);

  v_notes := coalesce((
    select jsonb_agg(jsonb_build_object('body', n.body, 'created_at', n.created_at))
    from (select * from public.notes
          where student_id = p_student and created_at >= v_from and created_at < (v_to + interval '1 day')
          order by created_at desc limit 5) n
  ), '[]'::jsonb);

  v_summary := jsonb_build_object(
    'student_id', v_student.id,
    'student_name', v_student.name,
    'grade', coalesce(v_student.grade, ''),
    'month', p_month,
    'generated_at', now(),
    'attendance', v_att,
    'fee', v_fee,
    'tests', v_tests,
    'notes', v_notes
  );

  insert into public.reports (school_id, student_id, month, summary)
  values (v_student.school_id, p_student, p_month, v_summary)
  on conflict (student_id, month)
  do update set summary = excluded.summary, created_at = now();

  return v_summary;
end $$;

-- ---------- 5. PARENT PORTAL: buckets + lesson fields ----------
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
      'late', count(*) filter (where s.attendance = 'late')::int,
      'rescheduled', count(*) filter (where s.attendance = 'rescheduled')::int,
      'cancelled', count(*) filter (where s.attendance = 'cancelled')::int,
      'recent', coalesce((
        select jsonb_agg(jsonb_build_object(
          'date', s3.date, 'status', s3.attendance,
          'note', coalesce(s3.note, ''), 'subject', coalesce(sub3.name, ''),
          'topics', coalesce(s3.topics, ''), 'homework', coalesce(s3.homework, ''),
          'rescheduled_to', s3.rescheduled_to
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
        'title', coalesce(a.title, ''), 'body', a.body, 'created_at', a.created_at
      ))
      from (select * from public.announcements
            where school_id = v_school
              and audience in ('all','parents')
              and (expires_at is null or expires_at > now())
            order by pinned desc, created_at desc limit 5) a
    ), '[]'::jsonb)
  );
end $$;