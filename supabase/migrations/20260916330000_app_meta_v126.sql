-- ============================================================
-- Durus (دروس) — Migration 032: app_meta → v1.1.16
-- Bump the in-app update metadata for the v1.1.16 release — the quality
-- batch: kinship on family chips, cross-grade assignment warnings,
-- enrolled-only test/slot subjects, schedule zoom setting, subject stat
-- badges + edit-form stats, in-depth income reports, floating add
-- buttons. No schema change this release.
-- `apk_url` points at the arm64 build (most common Android ABI); other
-- ABIs remain reachable from the release page `url`. GitHub Releases API
-- still feeds auto-detection (DurusApi.latestRelease merges both sources).
-- ============================================================

insert into public.app_meta (key, value) values (
  'latest_release',
  jsonb_build_object(
    'version', '1.1.16',
    'url', 'https://github.com/amworx/durus/releases/tag/v1.1.16',
    'notes', 'دفعة الجودة: صلة القرابة على بطاقات الإخوة، تحذير عدم تطابق الصفوف، مواد الاختبارات من المسندة فقط، تكبير الجدول، إحصائيات المواد وتقارير الدخل، وأزرار إضافة عائمة.',
    'apk_url', 'https://github.com/amworx/durus/releases/download/v1.1.16/app-arm64-v8a-release.apk'
  )
)
on conflict (key) do update set
  value = excluded.value,
  updated_at = now();
