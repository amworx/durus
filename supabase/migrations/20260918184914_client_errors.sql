-- ============================================================
-- Durus (دروس) — Migration 036: client error reports
-- Append-only log of app-side failures (uncaught framework errors plus
-- explicit reports from guarded RPC paths like owner_overview). Exists so
-- the next "error with no details" arrives with its server message
-- attached. Messages are exception texts (no passwords/tokens); rows are
-- owner-readable only.
-- ============================================================

create table if not exists public.client_errors (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid references auth.users (id) on delete set null,
  school_id   uuid,
  app_version text not null default '',
  platform    text not null default '',
  screen      text not null default '',
  message     text not null check (char_length(message) between 1 and 500),
  stack       text not null default '' check (char_length(stack) <= 2000),
  created_at  timestamptz not null default now()
);
alter table public.client_errors enable row level security;
create index if not exists idx_client_errors_created
  on public.client_errors (created_at desc);

-- Authenticated users log only their own rows. (Pre-login failures can't
-- be attributed, so they stay client-side — accepted v1 tradeoff.)
drop policy if exists client_errors_insert_own on public.client_errors;
create policy client_errors_insert_own on public.client_errors
  for insert with check (user_id = auth.uid());

-- Owner reads everything; nobody updates or deletes via the API.
drop policy if exists client_errors_select_owner on public.client_errors;
create policy client_errors_select_owner on public.client_errors
  for select using (public.is_app_owner());

-- Latest 20 reports with author email attached. Fails closed ('not_owner')
-- like owner_overview.
create or replace function public.owner_errors()
returns jsonb
language plpgsql security definer set search_path = public
as $$
begin
  if not public.is_app_owner() then
    raise exception 'not_owner';
  end if;

  return coalesce((
    select jsonb_agg(t) from (
      select e.message, e.screen, e.app_version, e.platform,
             e.created_at, p.full_name as author_name, p.email as author_email
        from public.client_errors e
        left join public.profiles p on p.id = e.user_id
       order by e.created_at desc
       limit 20
    ) t
  ), '[]'::jsonb);
end $$;
