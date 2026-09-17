-- ============================================================
-- Durus (دروس) — Migration 030: app_meta → v1.1.14
-- Bump the in-app update metadata for the v1.1.14 release:
-- excuse-session integrity guard (excuses only attach to real sessions)
-- and the portal bottom-navbar regroup (home/attendance/schedule/fees/
-- more tabs with the excuse form living in its attendance context).
-- `apk_url` points at the arm64 build (most common Android ABI); other
-- ABIs remain reachable from the release page `url`. GitHub Releases API
-- still feeds auto-detection (DurusApi.latestRelease merges both sources).
-- ============================================================

insert into public.app_meta (key, value) values (
  'latest_release',
  jsonb_build_object(
    'version', '1.1.14',
    'url', 'https://github.com/amworx/durus/releases/tag/v1.1.14',
    'notes', 'سلامة الأعذار وتنظيم البوابة: عذر الغياب لا يُقبل إلا في يوم فيه حصة فعلية للطالب، وبوابة الأهل أصبحت بخمسة تبويبات سفلية (الرئيسية والحضور والجدول والرسوم والمزيد) بدل التمرير الطويل.',
    'apk_url', 'https://github.com/amworx/durus/releases/download/v1.1.14/app-arm64-v8a-release.apk'
  )
)
on conflict (key) do update set
  value = excluded.value,
  updated_at = now();
