-- ============================================================
-- Durus (دروس) — Migration 026: widen notifications.type check
-- The original check predates newer flows: the client already renders
-- 'session_change', and parent absence excuses insert 'absence_excuse'
-- (caught live: parent_report_absence rolled back on
-- notifications_type_check). Both are now legal values.
-- ============================================================

alter table public.notifications drop constraint if exists notifications_type_check;
alter table public.notifications
  add constraint notifications_type_check check (type in (
    'general', 'attendance', 'note', 'test', 'fee', 'payment',
    'announcement', 'teacher', 'session_change', 'absence_excuse'
  ));
