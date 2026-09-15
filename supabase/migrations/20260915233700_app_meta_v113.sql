-- ============================================================
-- Durus (دروس) — Migration 013: app_meta → v1.1.3
-- Bump the in-app update metadata for the v1.1.3 release (in-app update
-- download + install, auto-detection from GitHub). `apk_url` points at the
-- arm64 build — the most common Android ABI; other ABIs remain reachable
-- from the release page `url`. GitHub Releases API now also feeds detection
-- (DurusApi.latestRelease merges both sources), so this row mainly carries
-- the curated Arabic notes while the API guarantees auto-detection.
-- ============================================================

insert into public.app_meta (key, value) values (
  'latest_release',
  jsonb_build_object(
    'version', '1.1.3',
    'url', 'https://github.com/amworx/durus/releases/tag/v1.1.3',
    'notes', 'تنزيل التحديث وتثبيته مباشرة داخل التطبيق • كشف التحديثات تلقائياً من GitHub',
    'apk_url', 'https://github.com/amworx/durus/releases/download/v1.1.3/app-arm64-v8a-release.apk'
  )
)
on conflict (key) do update set
  value = excluded.value,
  updated_at = now();