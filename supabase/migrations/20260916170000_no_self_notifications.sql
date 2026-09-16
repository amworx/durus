-- ============================================================
-- Durus (دروس) — No self-notifications
-- Users must never receive a notification about their own
-- actions:
--   1) notify_announcement   — exclude the author
--   2) notify_payment_change — skip when the manager records a
--      payment themselves (single-teacher mode)
--   3) notify_teacher_joined — skip when the manager creates a
--      teacher themselves via credentials
-- ============================================================

create or replace function public.notify_announcement()
returns trigger language plpgsql security definer set search_path = public
as $$
begin
  if new.audience in ('all','teachers')
     and (new.expires_at is null or new.expires_at > now())
  then
    insert into public.notifications (school_id, recipient_type, recipient_id, type, title, body, entity_ref)
    select new.school_id, 'teacher', p.id, 'announcement',
           'إعلان جديد', left(coalesce(new.title, new.body), 120),
           jsonb_build_object('table', 'announcements', 'id', new.id)
    from public.profiles p
    where p.school_id = new.school_id
      and not p.is_manager
      and p.id <> new.author_id;  -- the author never notifies themselves
  end if;
  return new;
end $$;

drop trigger if exists trg_notify_announcement on public.announcements;
create trigger trg_notify_announcement
  after insert on public.announcements
  for each row execute procedure public.notify_announcement();

create or replace function public.notify_payment_change()
returns trigger language plpgsql security definer set search_path = public
as $$
declare v_manager uuid; v_student_name text;
begin
  select id into v_manager from public.profiles where school_id = new.school_id and is_manager limit 1;
  -- A manager recording a payment themselves (incl. single-teacher mode)
  -- must not be notified about their own action.
  if v_manager is null or v_manager = auth.uid() then return new; end if;
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

create or replace function public.notify_teacher_joined()
returns trigger language plpgsql security definer set search_path = public
as $$
begin
  if new.is_manager is false
     and new.manager_id is not null
     and new.manager_id is distinct from auth.uid()  -- manager creating the teacher themselves is skipped
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