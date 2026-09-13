-- ============================================================
-- Durus (دروس) — Migration 001: tables, indexes, triggers
-- Project ref: rdlapngvsxhdcoxdcjov
-- ============================================================

-- ---------- 1. PROFILES ----------
create table if not exists public.profiles (
  id          uuid primary key references auth.users (id) on delete cascade,
  email       text not null,
  full_name   text,
  role        text not null default 'teacher' check (role in ('manager','teacher')),
  is_manager  boolean not null default false,
  manager_id  uuid references public.profiles (id) on delete set null,
  school_id   uuid, -- = manager id; for single-mode creator, own id
  created_at  timestamptz not null default now()
);
alter table public.profiles enable row level security;

create or replace function public.handle_new_user()
returns trigger
language plpgsql security definer set search_path = public
as $$
begin
  insert into public.profiles (id, email, full_name)
  values (new.id, new.email, coalesce(new.raw_user_meta_data->>'full_name', ''))
  on conflict (id) do nothing;
  return new;
end $$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- ---------- 2. SUBJECTS ----------
create table if not exists public.subjects (
  id         uuid primary key default gen_random_uuid(),
  school_id  uuid not null,
  name       text not null,
  grade      text,
  notes      text,
  created_at timestamptz not null default now()
);
alter table public.subjects enable row level security;

-- ---------- 3. STUDENTS ----------
create table if not exists public.students (
  id                 uuid primary key default gen_random_uuid(),
  school_id          uuid not null,
  name               text not null,
  grade              text,
  birth_year         int,
  default_location   text not null default 'student_home' check (default_location in ('student_home','teacher_home')),
  assigned_teacher_id uuid not null references public.profiles (id),
  parent_name        text,
  parent_phone       text,
  parent_token       uuid unique,           -- secret PIN/link for parent portal
  notes              text,
  created_at         timestamptz not null default now()
);
alter table public.students enable row level security;

create table if not exists public.student_subjects (
  student_id uuid not null references public.students (id) on delete cascade,
  subject_id uuid not null references public.subjects (id) on delete cascade,
  primary key (student_id, subject_id)
);
alter table public.student_subjects enable row level security;

-- ---------- 4. RECURRING SCHEDULE ----------
create table if not exists public.recurring_slots (
  id            uuid primary key default gen_random_uuid(),
  school_id     uuid not null,
  student_id    uuid not null references public.students (id) on delete cascade,
  subject_id    uuid references public.subjects (id) on delete set null,
  day_of_week   int  not null check (day_of_week between 1 and 7), -- DateTime.weekday (1=Mon..7=Sun)
  start_minutes int  not null check (start_minutes between 0 and 1439),
  end_minutes   int  not null check (end_minutes between 1 and 1440),
  location      text not null default 'student_home' check (location in ('student_home','teacher_home')),
  teacher_id    uuid not null references public.profiles (id),
  active        boolean not null default true,
  created_at    timestamptz not null default now()
);
alter table public.recurring_slots enable row level security;

-- ---------- 5. SESSIONS / ATTENDANCE ----------
create table if not exists public.sessions (
  id          uuid primary key default gen_random_uuid(),
  school_id   uuid not null,
  student_id  uuid not null references public.students (id) on delete cascade,
  subject_id  uuid references public.subjects (id) on delete set null,
  slot_id     uuid references public.recurring_slots (id) on delete set null,
  date        date not null,
  attendance  text not null check (attendance in ('present','absent','rescheduled')),
  note        text,
  recorded_by uuid references public.profiles (id),
  created_at  timestamptz not null default now(),
  unique (student_id, slot_id, date)
);
alter table public.sessions enable row level security;

-- ---------- 6. FEES + PAYMENTS ----------
create table if not exists public.fees (
  id          uuid primary key default gen_random_uuid(),
  school_id   uuid not null,
  student_id  uuid not null references public.students (id) on delete cascade,
  month       text not null, -- 'YYYY-MM'
  amount      numeric(10,2) not null default 0,
  paid_amount numeric(10,2) not null default 0,
  status      text not null default 'unpaid' check (status in ('unpaid','partial','paid')),
  due_date    date,
  notes       text,
  created_at  timestamptz not null default now(),
  unique (student_id, month)
);
alter table public.fees enable row level security;

create table if not exists public.payments (
  id         uuid primary key default gen_random_uuid(),
  school_id  uuid not null,
  fee_id     uuid not null references public.fees (id) on delete cascade,
  student_id uuid not null references public.students (id) on delete cascade,
  amount     numeric(10,2) not null check (amount > 0),
  paid_at    date not null default current_date,
  method     text not null default 'cash' check (method in ('cash','transfer','other')),
  note       text,
  created_at timestamptz not null default now()
);
alter table public.payments enable row level security;

create or replace function public.refresh_fee_status()
returns trigger
language plpgsql security definer set search_path = public
as $$
declare v numeric;
begin
  select coalesce(sum(p.amount), 0) into v from public.payments p where p.fee_id = new.fee_id;
  update public.fees f
     set paid_amount = v,
         status = case when v >= f.amount then 'paid'
                       when v > 0 then 'partial'
                       else 'unpaid' end
   where f.id = new.fee_id;
  return new;
end $$;

drop trigger if exists trg_refresh_fee on public.payments;
create trigger trg_refresh_fee
  after insert or update or delete on public.payments
  for each row execute procedure public.refresh_fee_status();

-- ---------- 7. TESTS / NOTES / REPORTS ----------
create table if not exists public.tests (
  id         uuid primary key default gen_random_uuid(),
  school_id  uuid not null,
  student_id uuid not null references public.students (id) on delete cascade,
  subject_id uuid references public.subjects (id) on delete set null,
  type       text not null default 'monthly' check (type in ('monthly','midterm','final','quiz','other')),
  date       date not null default current_date,
  score      numeric(6,2),
  max_score  numeric(6,2),
  note       text,
  created_at timestamptz not null default now()
);
alter table public.tests enable row level security;

create table if not exists public.notes (
  id         uuid primary key default gen_random_uuid(),
  school_id  uuid not null,
  student_id uuid not null references public.students (id) on delete cascade,
  author_id  uuid references public.profiles (id),
  body       text not null,
  session_id uuid references public.sessions (id) on delete set null,
  created_at timestamptz not null default now()
);
alter table public.notes enable row level security;

create table if not exists public.reports (
  id         uuid primary key default gen_random_uuid(),
  school_id  uuid not null,
  student_id uuid not null references public.students (id) on delete cascade,
  month      text not null,
  summary    jsonb not null,
  created_at timestamptz not null default now()
);
alter table public.reports enable row level security;

-- ---------- 8. ANNOUNCEMENTS + INVITATIONS ----------
create table if not exists public.announcements (
  id         uuid primary key default gen_random_uuid(),
  school_id  uuid not null,
  author_id  uuid references public.profiles (id),
  body       text not null,
  created_at timestamptz not null default now()
);
alter table public.announcements enable row level security;

create table if not exists public.invitations (
  id          uuid primary key default gen_random_uuid(),
  school_id   uuid not null,
  manager_id  uuid not null references public.profiles (id),
  token       uuid not null default gen_random_uuid() unique,
  email       text,
  status      text not null default 'pending' check (status in ('pending','accepted','revoked')),
  expires_at  timestamptz not null default (now() + interval '7 days'),
  accepted_at timestamptz,
  created_at  timestamptz not null default now()
);
alter table public.invitations enable row level security;

-- ---------- 9. INDEXES ----------
create index if not exists idx_students_school    on public.students (school_id);
create index if not exists idx_students_teacher   on public.students (assigned_teacher_id);
create index if not exists idx_slots_day          on public.recurring_slots (day_of_week, active);
create index if not exists idx_slots_student      on public.recurring_slots (student_id);
create index if not exists idx_sessions_student_date on public.sessions (student_id, date desc);
create index if not exists idx_sessions_date      on public.sessions (date);
create index if not exists idx_fees_student_month on public.fees (student_id, month);
create index if not exists idx_payments_fee       on public.payments (fee_id);
create index if not exists idx_tests_student      on public.tests (student_id, date desc);
create index if not exists idx_notes_student      on public.notes (student_id, created_at desc);
create index if not exists idx_reports_student    on public.reports (student_id, month);
create index if not exists idx_invitations_school on public.invitations (school_id, status);