-- ============================================================
-- Durus (دروس) — Migration 016: app_meta → v1.1.6
-- Bump the in-app update metadata for the v1.1.6 release:
--   (1) student tab upgrade — action bar (edit / report / more),
--       WhatsApp + clipboard export of the attendance log and the
--       tests log, tests CRUD (edit / share result / delete),
--       full shareable parent portal link, teacher-side performance
--       summary and a portal-side performance card;
--   (2) announcements now refresh in real time (Realtime channel);
--   (3) on-device push notifications (flutter_local_notifications,
--       no FCM) for attendance / tests / announcements events when
--       the app is not in the foreground.
-- `apk_url` points at the arm64 build (most common Android ABI); other
-- ABIs remain reachable from the release page `url`. GitHub Releases API
-- still feeds auto-detection (DurusApi.latestRelease merges both sources).
-- ============================================================

insert into public.app_meta (key, value) values (
  'latest_release',
  jsonb_build_object(
    'version', '1.1.6',
    'url', 'https://github.com/amworx/durus/releases/tag/v1.1.6',
    'notes', 'تحديث تبويب الطلاب: شريط إجراءات (تعديل / تقرير / المزيد)، تصدير ومشاركة سجل الحضور والاختبارات عبر واتساب والحافظة، تعديل ومشاركة وحذف الاختبارات، رابط بوابة ولي الأمر الكامل للمشاركة، وملخص أداء الطالب للمعلم وولي الأمر. إشعارات محلية على الجهاز (بدون FCM) لإشعار الحضور والاختبارات والإعلانات، وتحديث فوري للإعلانات.',
    'apk_url', 'https://github.com/amworx/durus/releases/download/v1.1.6/app-arm64-v8a-release.apk'
  )
)
on conflict (key) do update set
  value = excluded.value,
  updated_at = now();