-- ============================================================
-- Durus (دروس) — Migration 006: monthly report generation
-- RPC computes a per-student monthly summary (attendance, fee,
-- tests, notes) and upserts it into public.reports.
-- ============================================================

alter table public.reports drop constraint if exists reports_student_month_unique;
alter table public.reports add constraint reports_student_month_unique unique (student_id, month);

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
      'rescheduled', count(*) filter (where attendance = 'rescheduled')::int
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

grant execute on function public.generate_report(uuid, text) to authenticated;