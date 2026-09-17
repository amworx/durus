-- ============================================================
-- Durus (دروس) — Migration 027: student lifecycle status
-- students.status: 'active' (default) | 'paused' (موقوف مؤقتًا) |
-- 'dropped' (منقطع) | 'graduated' (متخرج).
-- Semantics live in the app, not here: non-active students leave lists
-- and the schedule, but every historical row (sessions, fees, tests,
-- notes, reports) stays untouched. Finishing a course = set graduated
-- (+ delete slots); re-registering = flip back to active. Deleting a
-- student with sessions stays forbidden client-side (cascade would wipe
-- history). RLS: no policy change — teacher self-school update path
-- already covers the column; the check only whitelists values.
-- ============================================================

alter table public.students
  add column if not exists status text not null default 'active';

alter table public.students drop constraint if exists students_status_check;
alter table public.students
  add constraint students_status_check
  check (status in ('active', 'paused', 'dropped', 'graduated'));

create index if not exists idx_students_status
  on public.students (school_id, status);
