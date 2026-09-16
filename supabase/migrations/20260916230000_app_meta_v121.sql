-- ============================================================
-- Durus (دروس) — Migration 022: app_meta → v1.1.11
-- Bump the in-app update metadata for the v1.1.11 release:
-- safety + usability fixes — recurring calendar blocks are tappable
-- again (record attendance straight from the schedule), the teacher
-- activate/deactivate toggle asks for confirmation (lockout-grade
-- action), and notification delete has a 4-second undo window.
-- `apk_url` points at the arm64 build (most common Android ABI); other
-- ABIs remain reachable from the release page `url`. GitHub Releases API
-- still feeds auto-detection (DurusApi.latestRelease merges both sources).
-- ============================================================

insert into public.app_meta (key, value) values (
  'latest_release',
  jsonb_build_object(
    'version', '1.1.11',
    'url', 'https://github.com/amworx/durus/releases/tag/v1.1.11',
    'notes', 'إصلاحات: حصص الجدول المكررة أصبحت قابلة للضغط — سجّل الحضور مباشرة من التقويم. زر تفعيل/إيقاف المعلم يطلب تأكيدًا قبل التنفيذ. حذف الإشعار أصبح مع مهلة تراجع 4 ثوانٍ.',
    'apk_url', 'https://github.com/amworx/durus/releases/download/v1.1.11/app-arm64-v8a-release.apk'
  )
)
on conflict (key) do update set
  value = excluded.value,
  updated_at = now();
