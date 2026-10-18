-- ============================================================
-- Durus (دروس) — Migration 038: app_meta → v1.1.19
-- Bump the in-app update metadata for the v1.1.19 release — the owner
-- dashboard rebuilt as four bottom-bar tabs (overview / schools /
-- requests / errors) with an explicit teachers card, plus the update
-- check no longer going dark when the backend is unreachable.
-- No schema change; data row only.
-- `apk_url` points at the single published arm64 asset. Publication is
-- `release_one_apk` (memory/playbooks.md): exactly one asset per release.
-- ============================================================

insert into public.app_meta (key, value) values (
  'latest_release',
  jsonb_build_object(
    'version', '1.1.19',
    'url', 'https://github.com/amworx/durus/releases/tag/v1.1.19',
    'notes', 'لوحة المالك على 4 تبويبات: نظرة عامة، المدارس، الطلبات، الأخطاء — مع بطاقة صريحة لعدد المعلمين. وفحص التحديثات يعمل الآن حتى لو تعذّر الوصول إلى الخادم.',
    'apk_url', 'https://github.com/amworx/durus/releases/download/v1.1.19/durus-1.1.19-arm64.apk'
  )
)
on conflict (key) do update set
  value = excluded.value,
  updated_at = now();
