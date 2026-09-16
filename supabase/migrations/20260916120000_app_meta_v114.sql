-- ============================================================
-- Durus (دروس) — Migration 014: app_meta → v1.1.4
-- Bump the in-app update metadata for the v1.1.4 release: Sessions UI/UX
-- upgrade (5 attendance states, lesson detail sheet, undo) + Announcements/
-- Notifications (compose with title/audience/pin, management screen,
-- notification preference toggles). `apk_url` points at the arm64 build —
-- the most common Android ABI; other ABIs remain reachable from the release
-- page `url`. GitHub Releases API still feeds auto-detection
-- (DurusApi.latestRelease merges both sources).
-- ============================================================

insert into public.app_meta (key, value) values (
  'latest_release',
  jsonb_build_object(
    'version', '1.1.4',
    'url', 'https://github.com/amworx/durus/releases/tag/v1.1.4',
    'notes', 'تحديث كبير للواجهة: 5 حالات حضور (حاضر/غائب/متأخر/مؤجّل/ملغي) مع ورقة تفاصيل الحصة وتراجع فوري • إعلانات بعنوان وجمهور وتثبيت + شاشة إدارة • إشعارات مع تصنيفات وخيارات تخصيص من الإعدادات',
    'apk_url', 'https://github.com/amworx/durus/releases/download/v1.1.4/app-arm64-v8a-release.apk'
  )
)
on conflict (key) do update set
  value = excluded.value,
  updated_at = now();