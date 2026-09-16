-- ============================================================
-- Durus (دروس) — Migration 015: app_meta → v1.1.5
-- Bump the in-app update metadata for the v1.1.5 hotfix release:
--   (1) fixed in-app update install — APK now downloads into the app-private
--       cache dir reported by the native side (FileProvider <cache-path>
--       covered) instead of Directory.systemTemp, which on Android resolves
--       outside both the FileProvider root AND user-visible storage (the
--       v1.1.4 "cannot update / cannot find the APK" bug); if the installer
--       still can't be addressed, the APK is exported to user-visible
--       Downloads and the UI points the user to it.
--   (2) brand launcher icon — teal graduation-cap adaptive icon (v26/v33)
--       with legacy PNGs for older devices, replacing the Flutter template.
-- `apk_url` points at the arm64 build (most common Android ABI); other ABIs
-- remain reachable from the release page `url`. GitHub Releases API still
-- feeds auto-detection (DurusApi.latestRelease merges both sources).
-- ============================================================

insert into public.app_meta (key, value) values (
  'latest_release',
  jsonb_build_object(
    'version', '1.1.5',
    'url', 'https://github.com/amworx/durus/releases/tag/v1.1.5',
    'notes', 'إصلاح تحديث التطبيق: أصبح التنزيل والتثبيت يتم داخل التطبيق مباشرة (إصلاح مشكلة "لا يمكن التحديث" وعدم العثور على الملف) • أيقونة تطبيق جديدة (قبعة تخرج بلون التطبيق)',
    'apk_url', 'https://github.com/amworx/durus/releases/download/v1.1.5/app-arm64-v8a-release.apk'
  )
)
on conflict (key) do update set
  value = excluded.value,
  updated_at = now();