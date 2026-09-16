-- ============================================================
-- Durus (دروس) — Migration 021: app_meta → v1.1.10
-- Bump the in-app update metadata for the v1.1.10 release:
-- full profile-screen rebuild (green hero + البيانات/الدخول/الصورة
-- tabs), auto-generated Avatune teacher avatars with gender/style
-- picker and shuffle, editable bio/phone, in-app email change (with
-- confirmation notice) and password change (current verified).
-- `apk_url` points at the arm64 build (most common Android ABI); other
-- ABIs remain reachable from the release page `url`. GitHub Releases API
-- still feeds auto-detection (DurusApi.latestRelease merges both sources).
-- ============================================================

insert into public.app_meta (key, value) values (
  'latest_release',
  jsonb_build_object(
    'version', '1.1.10',
    'url', 'https://github.com/amworx/durus/releases/tag/v1.1.10',
    'notes', 'شاشة ملف شخصي جديدة كليًا: بطاقة خضراء بالصورة والاسم والإحصائيات، وتبويبات البيانات والدخول والصورة. صورة رمزية مولّدة تلقائيًا لكل معلم مع اختيار الجنس والستايل. تحرير النبذة والهاتف، تغيير البريد مع رابط تأكيد، وتغيير كلمة المرور من داخل التطبيق.',
    'apk_url', 'https://github.com/amworx/durus/releases/download/v1.1.10/app-arm64-v8a-release.apk'
  )
)
on conflict (key) do update set
  value = excluded.value,
  updated_at = now();
