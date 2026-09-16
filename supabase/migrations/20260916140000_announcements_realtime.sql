-- ============================================================
-- Durus (دروس) — Publish announcements on realtime
-- The teacher app subscribes to the `notifications` table so the
-- badge updates when triggers fire, but the announcements list
-- itself stayed stale until a manual refresh because `announcements`
-- was not on the realtime publication and nothing invalidated the
-- provider. Add the table so clients can subscribe directly.
-- RLS still applies on the subscriber side (school scoping).
-- ============================================================

alter publication supabase_realtime add table public.announcements;