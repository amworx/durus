-- ============================================================
-- Durus (دروس) — Migration 037: app_meta → v1.1.18
-- Bump the in-app update metadata for the v1.1.18 release — the owner
-- batch: app-owner dashboard (totals, versions in use, signups, school
-- health, feature-request triage), user feature/edit requests from
-- Settings, client error reporting (owner-visible log + dashboard
-- section), and the owner_overview grouping fix. No schema change beyond
-- the already-pushed 034–036 batch (owners, heartbeats, requests,
-- client_errors).
-- `apk_url` points at the arm64 build (most common Android ABI); other
-- ABIs remain reachable from the release page `url`. GitHub Releases API
-- still feeds auto-detection (DurusApi.latestRelease merges both sources).
-- ============================================================

insert into public.app_meta (key, value) values (
  'latest_release',
  jsonb_build_object(
    'version', '1.1.18',
    'url', 'https://github.com/amworx/durus/releases/tag/v1.1.18',
    'notes', 'لوحة المالك (إحصائيات الاستخدام والنسخ والمدارس) + اقتراحات التحسين من الإعدادات + سجل أخطاء مرئي للمالك.',
    'apk_url', 'https://github.com/amworx/durus/releases/download/v1.1.18/app-arm64-v8a-release.apk'
  )
)
on conflict (key) do update set
  value = excluded.value,
  updated_at = now();
