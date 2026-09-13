-- ============================================================
-- Durus (دروس) — Migration 003: in-app notifications
-- Server-generated notification rows via DB triggers.
-- FCM push is reserved for later: pushed_at + device tokens.
-- ============================================================

create table if not exists public.notifications (
  id             uuid primary key default gen_random_uuid(),
  school_id      uuid not null,
  recipient_type text not null check (recipient_type in ('parent','teacher')),
  recipient_id   uuid not null, -- 'parent' -> student_id ; 'teacher' -> profile id
  type           text not null default 'general' check (type in ('general','attendance','note','test','fee','payment','announcement','teacher')),
  title          text not null,
  body           text,
  entity_ref     jsonb,
  is_read        boolean not null default false,
  pushed_at      timestamptz, -- reserved for FCM push
  created_at     timestamptz not null default now()
);
alter table public.notifications enable row level security;

create index if not exists idx_notifications_recipient on public.notifications (recipient_type, recipient_id, is_read);
create index if not exists idx_notifications_school on public.notifications (school_id, created_at desc);

-- ---------- TRIGGERS ----------

-- 1) Attendance recorded/updated -> notify parent
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
      else 'تأجيل جلسة'
    end,
    case new.attendance
      when 'present' then 'تم تسجيل حضور ' || v_student_name || case when v_subject_name = '' then '' else ' — ' || v_subject_name end
      when 'absent' then 'تم تسجيل غياب ' || v_student_name || case when v_subject_name = '' then '' else ' — ' || v_subject_name end
      else 'تم تأجيل جلسة ' || v_student_name || case when v_subject_name = '' then '' else ' — ' || v_subject_name end
    end,
    jsonb_build_object('table', 'sessions', 'id', new.id)
  );
  return new;
end $$;

drop trigger if exists trg_notify_session on public.sessions;
create trigger trg_notify_session
  after insert or update on public.sessions
  for each row execute procedure public.notify_session_change();

-- 2) New note -> notify parent
create or replace function public.notify_note_change()
returns trigger language plpgsql security definer set search_path = public
as $$
declare v_student_name text; v_author text;
begin
  select name into v_student_name from public.students where id = new.student_id;
  select coalesce(full_name, '') into v_author from public.profiles where id = new.author_id;
  insert into public.notifications (school_id, recipient_type, recipient_id, type, title, body, entity_ref)
  values (
    new.school_id, 'parent', new.student_id, 'note',
    'ملاحظة جديدة',
    'أضاف المعلّم ملاحظة عن ' || v_student_name,
    jsonb_build_object('table', 'notes', 'id', new.id)
  );
  return new;
end $$;

drop trigger if exists trg_notify_note on public.notes;
create trigger trg_notify_note
  after insert on public.notes
  for each row execute procedure public.notify_note_change();

-- 3) New test result -> notify parent
create or replace function public.notify_test_change()
returns trigger language plpgsql security definer set search_path = public
as $$
declare v_student_name text; v_subject_name text;
begin
  select name into v_student_name from public.students where id = new.student_id;
  select coalesce(name, '') into v_subject_name from public.subjects where id = new.subject_id;
  insert into public.notifications (school_id, recipient_type, recipient_id, type, title, body, entity_ref)
  values (
    new.school_id, 'parent', new.student_id, 'test',
    'نتيجة اختبار',
    'أُضيفت نتيجة اختبار ' || v_student_name || case when v_subject_name = '' then '' else ' — ' || v_subject_name end || ' (' || coalesce(new.score::text, '-') || ' / ' || coalesce(new.max_score::text, '-') || ')',
    jsonb_build_object('table', 'tests', 'id', new.id)
  );
  return new;
end $$;

drop trigger if exists trg_notify_test on public.tests;
create trigger trg_notify_test
  after insert on public.tests
  for each row execute procedure public.notify_test_change();

-- 4) Fee created/updated (incl. payment-driven status refresh) -> notify parent
create or replace function public.notify_fee_change()
returns trigger language plpgsql security definer set search_path = public
as $$
declare v_student_name text; v_month_label text; v_status_label text;
begin
  select name into v_student_name from public.students where id = new.student_id;
  v_status_label := case new.status when 'paid' then 'مسدّد' when 'partial' then 'مسدّد جزئياً' else 'غير مسدّد' end;
  insert into public.notifications (school_id, recipient_type, recipient_id, type, title, body, entity_ref)
  values (
    new.school_id, 'parent', new.student_id, 'fee',
    'تحديث القسط',
    'تم تحديث قسط ' || v_student_name || ' (' || new.month || ') — الحالة: ' || v_status_label,
    jsonb_build_object('table', 'fees', 'id', new.id)
  );
  return new;
end $$;

drop trigger if exists trg_notify_fee on public.fees;
create trigger trg_notify_fee
  after insert or update on public.fees
  for each row execute procedure public.notify_fee_change();

-- 5) New payment -> notify manager (financial)
create or replace function public.notify_payment_change()
returns trigger language plpgsql security definer set search_path = public
as $$
declare v_manager uuid; v_student_name text;
begin
  select id into v_manager from public.profiles where school_id = new.school_id and is_manager limit 1;
  if v_manager is null then return new; end if;
  select name into v_student_name from public.students where id = new.student_id;
  insert into public.notifications (school_id, recipient_type, recipient_id, type, title, body, entity_ref)
  values (
    new.school_id, 'teacher', v_manager, 'payment',
    'دفعة جديدة',
    'تم تسجيل دفعة بقيمة ' || new.amount || ' عن ' || v_student_name,
    jsonb_build_object('table', 'payments', 'id', new.id)
  );
  return new;
end $$;

drop trigger if exists trg_notify_payment on public.payments;
create trigger trg_notify_payment
  after insert on public.payments
  for each row execute procedure public.notify_payment_change();

-- 6) New announcement -> notify all non-manager teachers in school
create or replace function public.notify_announcement()
returns trigger language plpgsql security definer set search_path = public
as $$
begin
  insert into public.notifications (school_id, recipient_type, recipient_id, type, title, body, entity_ref)
  select new.school_id, 'teacher', p.id, 'announcement',
         'إعلان جديد', left(new.body, 120),
         jsonb_build_object('table', 'announcements', 'id', new.id)
  from public.profiles p
  where p.school_id = new.school_id and not p.is_manager;
  return new;
end $$;

drop trigger if exists trg_notify_announcement on public.announcements;
create trigger trg_notify_announcement
  after insert on public.announcements
  for each row execute procedure public.notify_announcement();

-- 7) Teacher joins school (invite accepted or credentials created) -> notify manager
create or replace function public.notify_teacher_joined()
returns trigger language plpgsql security definer set search_path = public
as $$
begin
  if new.is_manager is false
     and new.manager_id is not null
     and (old.manager_id is null or old.manager_id is distinct from new.manager_id)
  then
    insert into public.notifications (school_id, recipient_type, recipient_id, type, title, body, entity_ref)
    values (
      new.manager_id, 'teacher', new.manager_id, 'teacher',
      'انضم معلم جديد',
      'انضم ' || coalesce(new.full_name, new.email) || ' إلى المركز',
      jsonb_build_object('table', 'profiles', 'id', new.id)
    );
  end if;
  return new;
end $$;

drop trigger if exists trg_notify_teacher_joined on public.profiles;
create trigger trg_notify_teacher_joined
  after update on public.profiles
  for each row execute procedure public.notify_teacher_joined();

-- ---------- RPCs (parent portal) ----------

create or replace function public.parent_notifications(p_token uuid)
returns jsonb
language plpgsql security definer set search_path = public
as $$
declare v_student uuid;
begin
  select id into v_student from public.students where parent_token = p_token;
  if not found then raise exception 'invalid_token'; end if;
  return jsonb_build_object(
    'unread', (select count(*)::int from public.notifications n where n.recipient_type = 'parent' and n.recipient_id = v_student and not n.is_read),
    'items', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', n.id, 'type', n.type, 'title', n.title, 'body', coalesce(n.body, ''),
        'is_read', n.is_read, 'created_at', n.created_at
      ))
      from (select * from public.notifications
            where recipient_type = 'parent' and recipient_id = v_student
            order by created_at desc limit 30) n
    ), '[]'::jsonb)
  );
end $$;

create or replace function public.parent_mark_read(p_token uuid, p_ids uuid[])
returns void
language plpgsql security definer set search_path = public
as $$
declare v_student uuid;
begin
  select id into v_student from public.students where parent_token = p_token;
  if not found then raise exception 'invalid_token'; end if;
  update public.notifications
     set is_read = true
   where recipient_type = 'parent' and recipient_id = v_student
     and id = any (p_ids);
end $$;

-- ---------- RLS POLICIES (teacher/manager side only; parents via RPC) ----------
create policy notifications_select on public.notifications for select using (
  recipient_type = 'teacher' and recipient_id = auth.uid()
);
create policy notifications_update on public.notifications for update using (
  recipient_type = 'teacher' and recipient_id = auth.uid()
) with check (
  recipient_type = 'teacher' and recipient_id = auth.uid()
);

grant execute on function public.parent_notifications(uuid) to anon, authenticated;
grant execute on function public.parent_mark_read(uuid, uuid[]) to anon, authenticated;