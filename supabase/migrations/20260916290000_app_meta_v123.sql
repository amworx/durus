-- ============================================================
-- Durus (دروس) — Migration 028: app_meta → v1.1.13
-- Bump the in-app update metadata for the v1.1.13 release — the family
-- + portal + lifecycle bundle:
--   family: manual sibling linking with guardian kinship, duplicate-phone
--   resolution, and one parent-portal link per family with a child
--   switcher;
--   portal actions: absence excuses (teacher notified) and read receipts
--   on notes/announcements (visible to teachers as read counts);
--   lifecycle: student status (active/paused/dropped/graduated) with list
--   filter + schedule filtering, September grade rollover, oldest-first
--   payment allocation, remaining-balance waivers, exact-duplicate guard.
-- `apk_url` points at the arm64 build (most common Android ABI); other
-- ABIs remain reachable from the release page `url`. GitHub Releases API
-- still feeds auto-detection (DurusApi.latestRelease merges both sources).
-- ============================================================

insert into public.app_meta (key, value) values (
  'latest_release',
  jsonb_build_object(
    'version', '1.1.13',
    'url', 'https://github.com/amworx/durus/releases/tag/v1.1.13',
    'notes', 'العائلات والبوابة ودورة الحياة: ربط الإخوة يدويًا مع صلة القرابة ورابط بوابة واحد للأبناء، الإبلاغ عن غياب وتأكيد القراءة من البوابة، حالات الطالب مع ترحيل الصفوف وتوزيع الدفعات والإعفاء ومنع التكرار.',
    'apk_url', 'https://github.com/amworx/durus/releases/download/v1.1.13/app-arm64-v8a-release.apk'
  )
)
on conflict (key) do update set
  value = excluded.value,
  updated_at = now();
