-- ============================================================
-- Durus (دروس) — Migration 019: app_meta → v1.1.9
-- Bump the in-app update metadata for the v1.1.9 release:
--   (1) unified top bar on every tab-root screen — profile avatar
--       (tap → edit account sheet: change display name in-app),
--       centered title, notification bell with unread badge;
--   (2) brand-new weekly schedule design (option 6 combo) — green
--       "today" hero card showing the next session, 7 day tabs,
--       and a vertical timeline distinguishing recurring slots
--       (dashed teal, "مكرر" chip) from recorded sessions
--       (attendance colors); slot-less sessions grouped as
--       "جلسات بدون موعد".
-- `apk_url` points at the arm64 build (most common Android ABI); other
-- ABIs remain reachable from the release page `url`. GitHub Releases API
-- still feeds auto-detection (DurusApi.latestRelease merges both sources).
-- ============================================================

insert into public.app_meta (key, value) values (
  'latest_release',
  jsonb_build_object(
    'version', '1.1.9',
    'url', 'https://github.com/amworx/durus/releases/tag/v1.1.9',
    'notes', 'جديد: شريط علوي موحد في كل الشاشات (صورة الحساب + جرس الإشعارات + تعديل الاسم من داخل التطبيق). تصميم جديد كليًا لجدول الأسبوع: بطاقة اليوم تعرض الجلسة القادمة، تبويبات الأيام السبعة، وخط زمني واضح يميز الحصص المكررة (مكرر) عن الجلسات المسجلة بألوان الحضور.',
    'apk_url', 'https://github.com/amworx/durus/releases/download/v1.1.9/app-arm64-v8a-release.apk'
  )
)
on conflict (key) do update set
  value = excluded.value,
  updated_at = now();
