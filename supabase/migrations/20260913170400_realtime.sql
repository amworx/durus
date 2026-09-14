-- ============================================================
-- Durus (دروس) — Migration 005: realtime notifications
-- Publish the notifications table on the default realtime
-- publication so the teacher app's badge/list can refresh
-- automatically when DB triggers insert rows.
-- RLS still applies on the subscriber side (recipient scoping).
-- ============================================================

alter publication supabase_realtime add table public.notifications;