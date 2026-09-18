-- ============================================================
-- Durus (دروس) — Migration 034: owner dashboard + feature requests
-- App-owner visibility (deployed state, usage, health) and user
-- feature/edit requests. Access control lives in Postgres:
-- `app_owners` holds owner emails, `is_app_owner()` gates the
-- `owner_overview()` aggregate RPC and the owner-wide selects. The app
-- never decides ownership client-side.
-- ============================================================

-- ---------- 1. APP OWNERS ----------
create table if not exists public.app_owners (
  email      text primary key,
  created_at timestamptz not null default now()
);
alter table public.app_owners enable row level security;
-- No policies: API roles get no direct access; only security-definer
-- functions read this table.

insert into public.app_owners (email) values ('amworxx@gmail.com')
on conflict (email) do nothing;

-- Owner gate, defined before any policy that references it.
create or replace function public.is_app_owner()
returns boolean
language sql stable security definer set search_path = public
as $$
  select exists (
    select 1
      from public.app_owners o
     where lower(o.email) = lower((
       select u.email from auth.users u where u.id = auth.uid()
     ))
  );
$$;

-- ---------- 2. CLIENT HEARTBEATS (deployed-state telemetry) ----------
-- One row per user, upserted by the app on launch (fire-and-forget).
-- Powers version distribution + daily-active counts. No PII beyond what
-- auth already stores.
create table if not exists public.client_heartbeats (
  user_id     uuid primary key references auth.users (id) on delete cascade,
  app_version text not null default '',
  platform    text not null default '',
  last_seen   timestamptz not null default now()
);
alter table public.client_heartbeats enable row level security;

drop policy if exists heartbeats_insert_own on public.client_heartbeats;
create policy heartbeats_insert_own on public.client_heartbeats
  for insert with check (user_id = auth.uid());

drop policy if exists heartbeats_update_own on public.client_heartbeats;
create policy heartbeats_update_own on public.client_heartbeats
  for update using (user_id = auth.uid())
  with check (user_id = auth.uid());

drop policy if exists heartbeats_select_owner on public.client_heartbeats;
create policy heartbeats_select_owner on public.client_heartbeats
  for select using (public.is_app_owner());

-- ---------- 3. FEATURE / EDIT REQUESTS ----------
create table if not exists public.feature_requests (
  id         uuid primary key default gen_random_uuid(),
  school_id  uuid not null,
  author_id  uuid references public.profiles (id) on delete set null,
  type       text not null default 'feature'
             check (type in ('feature', 'edit')),
  title      text not null check (char_length(title) between 1 and 150),
  body       text not null default '' check (char_length(body) <= 2000),
  status     text not null default 'new'
             check (status in ('new', 'reviewing', 'planned', 'done', 'rejected')),
  created_at timestamptz not null default now()
);
alter table public.feature_requests enable row level security;
create index if not exists idx_feature_requests_school
  on public.feature_requests (school_id, created_at desc);

-- Authors work within their own school; the owner sees everything.
drop policy if exists feature_requests_select on public.feature_requests;
create policy feature_requests_select on public.feature_requests
  for select using (
    school_id = public.current_school_id() or public.is_app_owner()
  );

drop policy if exists feature_requests_insert on public.feature_requests;
create policy feature_requests_insert on public.feature_requests
  for insert with check (
    school_id = public.current_school_id() and author_id = auth.uid()
  );

-- Authors may edit only their own still-new requests (title/body); only
-- the owner moves status or touches anything else.
drop policy if exists feature_requests_update on public.feature_requests;
create policy feature_requests_update on public.feature_requests
  for update
  using (
    (author_id = auth.uid() and status = 'new') or public.is_app_owner()
  )
  with check (
    (
      author_id = auth.uid()
      and school_id = public.current_school_id()
      and status = 'new'
    )
    or public.is_app_owner()
  );

drop policy if exists feature_requests_delete on public.feature_requests;
create policy feature_requests_delete on public.feature_requests
  for delete using (
    (author_id = auth.uid() and status = 'new') or public.is_app_owner()
  );

-- ---------- 4. OWNER OVERVIEW RPC ----------

-- Whole-product snapshot for the owner dashboard. Fails closed for
-- everyone else ('not_owner'); runs definer because the aggregates span
-- schools and auth.users, which no teacher role may read.
create or replace function public.owner_overview()
returns jsonb
language plpgsql security definer set search_path = public
as $$
declare
  v_is_owner boolean := public.is_app_owner();
  v_month_start date := date_trunc('month', now())::date;
  v_week_ago timestamptz := now() - interval '7 days';
  v_day_ago timestamptz := now() - interval '24 hours';
begin
  if not v_is_owner then
    raise exception 'not_owner';
  end if;

  return jsonb_build_object(
    'totals', (
      select jsonb_build_object(
        'users',     count(*),
        'managers',  count(*) filter (where is_manager),
        'teachers',  count(*) filter (where not is_manager),
        'active',    count(*) filter (where active),
        'schools',   count(distinct coalesce(school_id, id)),
        'students',  (select count(*) from public.students),
        'subjects',  (select count(*) from public.subjects),
        'sessions_month', (
          select count(*) from public.sessions
           where date >= v_month_start
        ),
        'collected_month', (
          select coalesce(sum(amount), 0) from public.payments
           where paid_at >= v_month_start
        ),
        'outstanding', (
          select coalesce(sum(amount - paid_amount), 0) from public.fees
           where status <> 'paid'
        ),
        'invites_pending', (
          select count(*) from public.invitations where status = 'pending'
        ),
        'requests_open', (
          select count(*) from public.feature_requests
           where status in ('new', 'reviewing', 'planned')
        )
      )
      from public.profiles
    ),
    'active_today', (
      select count(*) from public.client_heartbeats
       where last_seen >= v_day_ago
    ),
    'active_week', (
      select count(*) from public.client_heartbeats
       where last_seen >= v_week_ago
    ),
    'versions', (
      select coalesce(jsonb_agg(t), '[]'::jsonb) from (
        select app_version as version, platform,
               count(*) as users, max(last_seen) as last_seen
          from public.client_heartbeats
         group by app_version, platform
         order by max(last_seen) desc
         limit 20
      ) t
    ),
    'signups_per_week', (
      select coalesce(jsonb_agg(t), '[]'::jsonb) from (
        select to_char(date_trunc('week', created_at), 'YYYY-MM-DD') as week,
               count(*) as count
          from auth.users
         where created_at >= now() - interval '8 weeks'
         group by 1
         order by 1
      ) t
    ),
    'schools', (
      select coalesce(jsonb_agg(t), '[]'::jsonb) from (
        select coalesce(p.school_id, p.id) as school_id,
               max(case when p.is_manager then p.full_name end) as manager,
               max(case when p.is_manager then p.email end) as email,
               count(*) filter (where not p.is_manager) as teachers,
               (select count(*) from public.students s
                 where s.school_id = coalesce(p.school_id, p.id)) as students,
               (select max(date) from public.sessions se
                 where se.school_id = coalesce(p.school_id, p.id)
              ) as last_session
          from public.profiles p
         group by coalesce(p.school_id, p.id)
         order by students desc
         limit 100
      ) t
    ),
    'requests', (
      select coalesce(jsonb_agg(t), '[]'::jsonb) from (
        select r.id, r.type, r.title, r.body, r.status, r.created_at,
               r.author_id, p.full_name as author_name, p.email as author_email
          from public.feature_requests r
          left join public.profiles p on p.id = r.author_id
         order by r.created_at desc
         limit 20
      ) t
    )
  );
end $$;
