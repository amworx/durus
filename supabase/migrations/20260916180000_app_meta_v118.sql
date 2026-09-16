-- ============================================================
-- Durus (دروس) — Migration 018: app_meta → v1.1.8
-- Bump the in-app update metadata for the v1.1.8 release:
--   (1) no more self-notifications — the user is never notified
--       about their own actions (posting an announcement,
--       recording a payment as manager, or creating a teacher
--       via credentials);
--   (2) student window keeps BOTH bottom bars — the main
--       navigation bar stays visible and the student action bar
--       (edit / reports / more / delete) stacks directly above
--       it instead of replacing it;
--   (3) clear slot-time validation — adding a session slot with
--       an end time before/equal to the start time now shows
--       "وقت النهاية يجب أن يكون بعد وقت البداية" (end must be
--       after start) inline and in the snackbar instead of a
--       generic error.
-- `apk_url` points at the arm64 build (most common Android ABI); other
-- ABIs remain reachable from the release page `url`. GitHub Releases API
-- still feeds auto-detection (DurusApi.latestRelease merges both sources).
-- ============================================================

insert into public.app_meta (key, value) values (
  'latest_release',
  jsonb_build_object(
    'version', '1.1.8',
    'url', 'https://github.com/amworx/durus/releases/tag/v1.1.8',
    'notes', 'تحسينات: لن تصلك إشعارات عن أفعالك أنت (نشر إعلان، تسجيل دفعة كمدير، إنشاء معلم). نافذة الطالب تحافظ على الشريط السفلي الرئيسي ويظهر شريط إجراءات الطالب (تعديل / تقرير / المزيد / حذف) فوقه مباشرة. رسالة واضحة عند إدخال وقت جلسة غير منطقي: وقت النهاية يجب أن يكون بعد وقت البداية.',
    'apk_url', 'https://github.com/amworx/durus/releases/download/v1.1.8/app-arm64-v8a-release.apk'
  )
)
on conflict (key) do update set
  value = excluded.value,
  updated_at = now();