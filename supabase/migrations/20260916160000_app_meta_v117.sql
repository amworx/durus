-- ============================================================
-- Durus (دروس) — Migration 017: app_meta → v1.1.7
-- Bump the in-app update metadata for the v1.1.7 release:
--   (1) student window action bar — all major actions (edit /
--       reports / more / delete) live in a fixed bottom bar;
--   (2) bulk operations on all data tabs — multi-select students,
--       subjects and fees, then apply one action to the whole
--       selection: delete / set grade / assign subject / share
--       parent links (students); delete / set grade (subjects);
--       delete / mark-as-paid (fees);
--   (3) richer filters everywhere — grade + subject + sort for
--       students, grade for subjects, month + payment status for
--       fees.
-- `apk_url` points at the arm64 build (most common Android ABI); other
-- ABIs remain reachable from the release page `url`. GitHub Releases API
-- still feeds auto-detection (DurusApi.latestRelease merges both sources).
-- ============================================================

insert into public.app_meta (key, value) values (
  'latest_release',
  jsonb_build_object(
    'version', '1.1.7',
    'url', 'https://github.com/amworx/durus/releases/tag/v1.1.7',
    'notes', 'شريط إجراءات ثابت أسفل نافذة الطالب (تعديل / تقرير / المزيد / حذف). عمليات جماعية: تحديد متعدد للطلاب والمواد والرسوم وتنفيذ إجراء واحد على الجميع (حذف / تحديد صف / إسناد مادة / مشاركة روابط أولياء الأمور / تعليم كمدفوعة). فلاتر أغنى: الصف والمادة والترتيب للطلاب، الصف للمواد، والشهر وحالة الدفع للرسوم.',
    'apk_url', 'https://github.com/amworx/durus/releases/download/v1.1.7/app-arm64-v8a-release.apk'
  )
)
on conflict (key) do update set
  value = excluded.value,
  updated_at = now();