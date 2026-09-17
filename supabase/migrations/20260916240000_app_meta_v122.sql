-- ============================================================
-- Durus (دروس) — Migration 023: app_meta → v1.1.12
-- Bump the in-app update metadata for the v1.1.12 release:
-- advance-payment polish (future months as guided prepayments: honest
-- due totals, future-month chip, in-form advance hint) and reason-aware
-- grade editing (mistake saves silently, real move reminds the teacher
-- to review subjects and weekly slots). No schema change this release.
-- `apk_url` points at the arm64 build (most common Android ABI); other
-- ABIs remain reachable from the release page `url`. GitHub Releases API
-- still feeds auto-detection (DurusApi.latestRelease merges both sources).
-- ============================================================

insert into public.app_meta (key, value) values (
  'latest_release',
  jsonb_build_object(
    'version', '1.1.12',
    'url', 'https://github.com/amworx/durus/releases/tag/v1.1.12',
    'notes', 'الدفع المقدم أصبح رسميًا: أنشئ أشهرًا مستقبلية وسدّد عليها، والإجماليات تعرض المستحق فقط مع شارة شهر مستقبلي. تعديل الصف يسأل عن السبب: تصحيح يحفظ بهدوء، وانتقال حقيقي يذكّر بمراجعة المواد والحصص.',
    'apk_url', 'https://github.com/amworx/durus/releases/download/v1.1.12/app-arm64-v8a-release.apk'
  )
)
on conflict (key) do update set
  value = excluded.value,
  updated_at = now();
