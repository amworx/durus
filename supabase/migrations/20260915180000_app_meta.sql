-- ============================================================
-- Durus (دروس) — Migration 010: app_meta (in-app update check)
-- Global, non-school-scoped release metadata so the Settings "check for
-- updates" can read it via the existing supabase client (works on Android
-- and web without extra HTTP dependencies). Writes stay service-role /
-- SQL editor only — no insert/update policy is granted.
-- ============================================================

create table if not exists public.app_meta (
  key        text primary key,
  value      jsonb not null,
  updated_at timestamptz not null default now()
);

alter table public.app_meta enable row level security;

-- Release metadata is public app info (like a download page on a website).
create policy "app_meta public read"
  on public.app_meta
  for select
  to anon, authenticated
  using (true);

-- Seed the current latest release. `url` points at the GitHub release page
-- (lists all ABI variants + notes); bump `version` with each release and
-- keep AppConfig.appVersion / pubspec `version` in sync.
insert into public.app_meta (key, value) values (
  'latest_release',
  jsonb_build_object(
    'version', '1.1.2',
    'url', 'https://github.com/amworx/durus/releases/tag/v1.1.2',
    'notes', 'واجهة البداية • إظهار الصف في المواد • التواصل عبر واتساب • التحقق من التحديثات'
  )
)
on conflict (key) do update set
  value = excluded.value,
  updated_at = now();