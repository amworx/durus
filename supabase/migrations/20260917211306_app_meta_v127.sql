-- ============================================================
-- Durus (دروس) — Migration 033: app_meta → v1.1.17
-- Bump the in-app update metadata for the v1.1.17 release — the security
-- + Google batch: pentest hardening (pinned self-update RLS columns,
-- fee/test bounds, text length caps, manager-only 'all' announcements,
-- school-scoped families, 15-minute JWT), Google sign-in alongside
-- email/password (native picker on Android, OAuth on web, password-less
-- notice in Profile), and the split-APK versionCode fix (+N now bumps
-- every release). No schema change this release.
-- `apk_url` points at the arm64 build (most common Android ABI); other
-- ABIs remain reachable from the release page `url`. GitHub Releases API
-- still feeds auto-detection (DurusApi.latestRelease merges both sources).
-- ============================================================

insert into public.app_meta (key, value) values (
  'latest_release',
  jsonb_build_object(
    'version', '1.1.17',
    'url', 'https://github.com/amworx/durus/releases/tag/v1.1.17',
    'notes', 'تعزيز الأمان الشامل (إصلاح ثغرة تبديل المدرسة، حدود الأقساط والدرجات، جلسات 15 دقيقة) + الدخول عبر Google بجانب البريد وكلمة المرور.',
    'apk_url', 'https://github.com/amworx/durus/releases/download/v1.1.17/app-arm64-v8a-release.apk'
  )
)
on conflict (key) do update set
  value = excluded.value,
  updated_at = now();
