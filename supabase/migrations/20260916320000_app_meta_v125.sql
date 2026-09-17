-- ============================================================
-- Durus (دروس) — Migration 031: app_meta → v1.1.15
-- Bump the in-app update metadata for the v1.1.15 release:
-- concentric first-run intro (once per install, then sign-in flow)
-- and the portal chrome upgrade (cycle switcher card with dots +
-- floating card dock bottom bar, switcher persistent on every tab).
-- `apk_url` points at the arm64 build (most common Android ABI); other
-- ABIs remain reachable from the release page `url`. GitHub Releases API
-- still feeds auto-detection (DurusApi.latestRelease merges both sources).
-- ============================================================

insert into public.app_meta (key, value) values (
  'latest_release',
  jsonb_build_object(
    'version', '1.1.15',
    'url', 'https://github.com/amworx/durus/releases/tag/v1.1.15',
    'notes', 'شاشة تعريف افتتاحية بحركة دائرية عند أول تشغيل، وبوابة أهل ببطاقة تنقل بين الأبناء وشريط سفلي عائم يظهر في كل التبويبات.',
    'apk_url', 'https://github.com/amworx/durus/releases/download/v1.1.15/app-arm64-v8a-release.apk'
  )
)
on conflict (key) do update set
  value = excluded.value,
  updated_at = now();
