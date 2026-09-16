-- ============================================================
-- Durus (دروس) — Announcements & notification prefs upgrade
-- 1) announcements += title, audience ('all'|'parents'|'teachers'),
--    pinned, expires_at
-- 2) notify_announcement trigger respects audience + expiry
-- 3) notification_prefs table (per-user category toggles) + RLS
-- ============================================================

-- ---------- 1. ANNOUNCEMENTS ----------
alter table public.announcements add column if not exists title text;
alter table public.announcements add column if not exists audience text not null default 'all'
  check (audience in ('all','parents','teachers'));
alter table public.announcements add column if not exists pinned boolean not null default false;
alter table public.announcements add column if not exists expires_at timestamptz;

create index if not exists idx_announcements_school_pinned
  on public.announcements (school_id, pinned desc, created_at desc);

-- ---------- 2. NOTIFY TRIGGER: audience + expiry ----------
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
    where p.school_id = new.school_id and not p.is_manager;
  end if;
  return new;
end $$;

drop trigger if exists trg_notify_announcement on public.announcements;
create trigger trg_notify_announcement
  after insert on public.announcements
  for each row execute procedure public.notify_announcement();

-- ---------- 3. NOTIFICATION PREFS ----------
create table if not exists public.notification_prefs (
  user_id      uuid primary key references public.profiles (id) on delete cascade,
  attendance   boolean not null default true,
  note         boolean not null default true,
  test         boolean not null default true,
  fee          boolean not null default true,
  payment      boolean not null default true,
  announcement boolean not null default true,
  teacher      boolean not null default true,
  general      boolean not null default true,
  updated_at   timestamptz not null default now()
);
alter table public.notification_prefs enable row level security;

create policy notification_prefs_select on public.notification_prefs
  for select using (user_id = auth.uid());
create policy notification_prefs_insert on public.notification_prefs
  for insert with check (user_id = auth.uid());
create policy notification_prefs_update on public.notification_prefs
  for update using (user_id = auth.uid()) with check (user_id = auth.uid());