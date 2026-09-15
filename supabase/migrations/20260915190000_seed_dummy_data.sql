-- ============================================================
-- Durus (دروس) — Seed: dummy data for local testing
-- Project ref: rdlapngvsxhdcoxdcjov
-- Single-teacher mode: school_id = teacher_id = manager profile id
--   e77576b3-fa4a-4aae-95a9-71b924f1180a (smoke teacher / manager)
-- Idempotent: every row uses a fixed UUID + ON CONFLICT DO NOTHING.
-- Notifications are NOT inserted here: the schema triggers
-- (notify_session_change / notify_note_change / notify_test_change /
--  notify_fee_change / notify_payment_change) create them automatically.
-- ============================================================

-- ---------- 1. SUBJECTS (fixed ids; "اللغة العربية" appears twice on
-- purpose so Subject.displayLabel "name — grade" can be verified) ----------
insert into public.subjects (id, school_id, name, grade, notes) values
  ('11111111-1111-4111-8111-111111111111', 'e77576b3-fa4a-4aae-95a9-71b924f1180a', 'اللغة العربية', 'الأول', 'قراءة وإملاء'),
  ('22222222-2222-4222-8222-222222222222', 'e77576b3-fa4a-4aae-95a9-71b924f1180a', 'اللغة العربية', 'الثاني', 'قواعد وإملاء'),
  ('33333333-3333-4333-8333-333333333333', 'e77576b3-fa4a-4aae-95a9-71b924f1180a', 'الرياضيات', 'الأول', 'أساسيات الحساب'),
  ('44444444-4444-4444-8444-444444444444', 'e77576b3-fa4a-4aae-95a9-71b924f1180a', 'العلوم', 'الثالث', 'الطبيعة والبيئة')
on conflict (id) do nothing;

-- ---------- 2. STUDENTS (4 new; أحمد already exists with a parent token) ----------
insert into public.students (id, school_id, name, grade, birth_year, default_location, assigned_teacher_id, parent_name, parent_phone, parent_token, notes) values
  ('2a2a2a2a-2a2a-4a2a-8a2a-2a2a2a2a2a2a', 'e77576b3-fa4a-4aae-95a9-71b924f1180a', 'محمد الأحمد', 'الأول', 2019, 'student_home', 'e77576b3-fa4a-4aae-95a9-71b924f1180a', 'أبو محمد', '0944556677', '6e6e6e6e-6e6e-4e6e-8e6e-6e6e6e6e6e6e', 'طالب جديد'),
  ('3b3b3b3b-3b3b-4b3b-8b3b-3b3b3b3b3b3b', 'e77576b3-fa4a-4aae-95a9-71b924f1180a', 'سارة خالد', 'الثاني', 2018, 'student_home', 'e77576b3-fa4a-4aae-95a9-71b924f1180a', 'أم سارة', '0955889900', '7f7f7f7f-7f7f-4f7f-8f7f-7f7f7f7f7f7f', null),
  ('4c4c4c4c-4c4c-4c4c-8c4c-4c4c4c4c4c4c', 'e77576b3-fa4a-4aae-95a9-71b924f1180a', 'عمر ناصر', 'الثالث', 2017, 'teacher_home', 'e77576b3-fa4a-4aae-95a9-71b924f1180a', null, null, '8a8a8a8a-8a8a-4a8a-8a8a-8a8a8a8a8a8a', 'بدون رقم هاتف للاختبار'),
  ('5d5d5d5d-5d5d-4d5d-8d5d-5d5d5d5d5d5d', 'e77576b3-fa4a-4aae-95a9-71b924f1180a', 'لين يوسف', 'الثاني', 2018, 'teacher_home', 'e77576b3-fa4a-4aae-95a9-71b924f1180a', 'أم لين', '0966112233', '9b9b9b9b-9b9b-4b9b-8b9b-9b9b9b9b9b9b', null)
on conflict (id) do nothing;

-- ---------- 3. STUDENT ↔ SUBJECT ----------
insert into public.student_subjects (student_id, subject_id) values
  ('2a2a2a2a-2a2a-4a2a-8a2a-2a2a2a2a2a2a', '11111111-1111-4111-8111-111111111111'),
  ('2a2a2a2a-2a2a-4a2a-8a2a-2a2a2a2a2a2a', '33333333-3333-4333-8333-333333333333'),
  ('3b3b3b3b-3b3b-4b3b-8b3b-3b3b3b3b3b3b', '22222222-2222-4222-8222-222222222222'),
  ('4c4c4c4c-4c4c-4c4c-8c4c-4c4c4c4c4c4c', '44444444-4444-4444-8444-444444444444'),
  ('5d5d5d5d-5d5d-4d5d-8d5d-5d5d5d5d5d5d', '22222222-2222-4222-8222-222222222222')
on conflict (student_id, subject_id) do nothing;

-- ---------- 4. RECURRING SLOTS (1 per new student; أحمد keeps his) ----------
insert into public.recurring_slots (id, school_id, student_id, subject_id, day_of_week, start_minutes, end_minutes, location, teacher_id, active) values
  ('c1c1c1c1-c1c1-4c1c-8c1c-c1c1c1c1c1c1', 'e77576b3-fa4a-4aae-95a9-71b924f1180a', '2a2a2a2a-2a2a-4a2a-8a2a-2a2a2a2a2a2a', '11111111-1111-4111-8111-111111111111', 1, 540, 600, 'student_home', 'e77576b3-fa4a-4aae-95a9-71b924f1180a', true),  -- Mon 09:00-10:00
  ('c2c2c2c2-c2c2-4c2c-8c2c-c2c2c2c2c2c2', 'e77576b3-fa4a-4aae-95a9-71b924f1180a', '3b3b3b3b-3b3b-4b3b-8b3b-3b3b3b3b3b3b', '22222222-2222-4222-8222-222222222222', 2, 600, 660, 'student_home', 'e77576b3-fa4a-4aae-95a9-71b924f1180a', true),  -- Tue 10:00-11:00
  ('c3c3c3c3-c3c3-4c3c-8c3c-c3c3c3c3c3c3', 'e77576b3-fa4a-4aae-95a9-71b924f1180a', '4c4c4c4c-4c4c-4c4c-8c4c-4c4c4c4c4c4c', '44444444-4444-4444-8444-444444444444', 3, 600, 660, 'teacher_home', 'e77576b3-fa4a-4aae-95a9-71b924f1180a', true),  -- Wed 10:00-11:00
  ('c4c4c4c4-c4c4-4c4c-8c4c-c4c4c4c4c4c4', 'e77576b3-fa4a-4aae-95a9-71b924f1180a', '5d5d5d5d-5d5d-4d5d-8d5d-5d5d5d5d5d5d', '22222222-2222-4222-8222-222222222222', 4, 570, 630, 'teacher_home', 'e77576b3-fa4a-4aae-95a9-71b924f1180a', true)   -- Thu 09:30-10:30
on conflict (id) do nothing;

-- ---------- 5. SESSIONS / ATTENDANCE (أغسطس + سبتمبر 2026)
-- unique(student_id, slot_id, date) guards re-runs. Omitting 2026-09-13
-- for أحمد because a real session already exists that day. ----------
insert into public.sessions (school_id, student_id, subject_id, slot_id, date, attendance, note, recorded_by) values
-- أحمد — Sun slot (f7119503-08f7-4e12-8aa4-2c05f2ac4c0b)
  ('e77576b3-fa4a-4aae-95a9-71b924f1180a', '2c1b7e72-6444-4359-be05-a7b83c1259ac', '107d36b2-f5a5-45bb-869b-1f69a61f25e4', 'f7119503-08f7-4e12-8aa4-2c05f2ac4c0b', '2026-08-02', 'present', null, 'e77576b3-fa4a-4aae-95a9-71b924f1180a'),
  ('e77576b3-fa4a-4aae-95a9-71b924f1180a', '2c1b7e72-6444-4359-be05-a7b83c1259ac', '107d36b2-f5a5-45bb-869b-1f69a61f25e4', 'f7119503-08f7-4e12-8aa4-2c05f2ac4c0b', '2026-08-09', 'present', null, 'e77576b3-fa4a-4aae-95a9-71b924f1180a'),
  ('e77576b3-fa4a-4aae-95a9-71b924f1180a', '2c1b7e72-6444-4359-be05-a7b83c1259ac', '107d36b2-f5a5-45bb-869b-1f69a61f25e4', 'f7119503-08f7-4e12-8aa4-2c05f2ac4c0b', '2026-08-16', 'absent', 'اعتذار', 'e77576b3-fa4a-4aae-95a9-71b924f1180a'),
  ('e77576b3-fa4a-4aae-95a9-71b924f1180a', '2c1b7e72-6444-4359-be05-a7b83c1259ac', '107d36b2-f5a5-45bb-869b-1f69a61f25e4', 'f7119503-08f7-4e12-8aa4-2c05f2ac4c0b', '2026-08-23', 'present', null, 'e77576b3-fa4a-4aae-95a9-71b924f1180a'),
  ('e77576b3-fa4a-4aae-95a9-71b924f1180a', '2c1b7e72-6444-4359-be05-a7b83c1259ac', '107d36b2-f5a5-45bb-869b-1f69a61f25e4', 'f7119503-08f7-4e12-8aa4-2c05f2ac4c0b', '2026-08-30', 'rescheduled', 'نُقلت إلى الأحد القادم', 'e77576b3-fa4a-4aae-95a9-71b924f1180a'),
  ('e77576b3-fa4a-4aae-95a9-71b924f1180a', '2c1b7e72-6444-4359-be05-a7b83c1259ac', '107d36b2-f5a5-45bb-869b-1f69a61f25e4', 'f7119503-08f7-4e12-8aa4-2c05f2ac4c0b', '2026-09-06', 'present', null, 'e77576b3-fa4a-4aae-95a9-71b924f1180a'),
-- محمد — Mon slot
  ('e77576b3-fa4a-4aae-95a9-71b924f1180a', '2a2a2a2a-2a2a-4a2a-8a2a-2a2a2a2a2a2a', '11111111-1111-4111-8111-111111111111', 'c1c1c1c1-c1c1-4c1c-8c1c-c1c1c1c1c1c1', '2026-08-03', 'present', null, 'e77576b3-fa4a-4aae-95a9-71b924f1180a'),
  ('e77576b3-fa4a-4aae-95a9-71b924f1180a', '2a2a2a2a-2a2a-4a2a-8a2a-2a2a2a2a2a2a', '11111111-1111-4111-8111-111111111111', 'c1c1c1c1-c1c1-4c1c-8c1c-c1c1c1c1c1c1', '2026-08-10', 'present', null, 'e77576b3-fa4a-4aae-95a9-71b924f1180a'),
  ('e77576b3-fa4a-4aae-95a9-71b924f1180a', '2a2a2a2a-2a2a-4a2a-8a2a-2a2a2a2a2a2a', '11111111-1111-4111-8111-111111111111', 'c1c1c1c1-c1c1-4c1c-8c1c-c1c1c1c1c1c1', '2026-08-17', 'absent', 'سفر', 'e77576b3-fa4a-4aae-95a9-71b924f1180a'),
  ('e77576b3-fa4a-4aae-95a9-71b924f1180a', '2a2a2a2a-2a2a-4a2a-8a2a-2a2a2a2a2a2a', '11111111-1111-4111-8111-111111111111', 'c1c1c1c1-c1c1-4c1c-8c1c-c1c1c1c1c1c1', '2026-08-24', 'present', null, 'e77576b3-fa4a-4aae-95a9-71b924f1180a'),
  ('e77576b3-fa4a-4aae-95a9-71b924f1180a', '2a2a2a2a-2a2a-4a2a-8a2a-2a2a2a2a2a2a', '11111111-1111-4111-8111-111111111111', 'c1c1c1c1-c1c1-4c1c-8c1c-c1c1c1c1c1c1', '2026-08-31', 'present', null, 'e77576b3-fa4a-4aae-95a9-71b924f1180a'),
  ('e77576b3-fa4a-4aae-95a9-71b924f1180a', '2a2a2a2a-2a2a-4a2a-8a2a-2a2a2a2a2a2a', '11111111-1111-4111-8111-111111111111', 'c1c1c1c1-c1c1-4c1c-8c1c-c1c1c1c1c1c1', '2026-09-07', 'present', null, 'e77576b3-fa4a-4aae-95a9-71b924f1180a'),
  ('e77576b3-fa4a-4aae-95a9-71b924f1180a', '2a2a2a2a-2a2a-4a2a-8a2a-2a2a2a2a2a2a', '11111111-1111-4111-8111-111111111111', 'c1c1c1c1-c1c1-4c1c-8c1c-c1c1c1c1c1c1', '2026-09-14', 'present', null, 'e77576b3-fa4a-4aae-95a9-71b924f1180a'),
-- سارة — Tue slot
  ('e77576b3-fa4a-4aae-95a9-71b924f1180a', '3b3b3b3b-3b3b-4b3b-8b3b-3b3b3b3b3b3b', '22222222-2222-4222-8222-222222222222', 'c2c2c2c2-c2c2-4c2c-8c2c-c2c2c2c2c2c2', '2026-08-04', 'present', null, 'e77576b3-fa4a-4aae-95a9-71b924f1180a'),
  ('e77576b3-fa4a-4aae-95a9-71b924f1180a', '3b3b3b3b-3b3b-4b3b-8b3b-3b3b3b3b3b3b', '22222222-2222-4222-8222-222222222222', 'c2c2c2c2-c2c2-4c2c-8c2c-c2c2c2c2c2c2', '2026-08-11', 'absent', null, 'e77576b3-fa4a-4aae-95a9-71b924f1180a'),
  ('e77576b3-fa4a-4aae-95a9-71b924f1180a', '3b3b3b3b-3b3b-4b3b-8b3b-3b3b3b3b3b3b', '22222222-2222-4222-8222-222222222222', 'c2c2c2c2-c2c2-4c2c-8c2c-c2c2c2c2c2c2', '2026-08-18', 'present', null, 'e77576b3-fa4a-4aae-95a9-71b924f1180a'),
  ('e77576b3-fa4a-4aae-95a9-71b924f1180a', '3b3b3b3b-3b3b-4b3b-8b3b-3b3b3b3b3b3b', '22222222-2222-4222-8222-222222222222', 'c2c2c2c2-c2c2-4c2c-8c2c-c2c2c2c2c2c2', '2026-08-25', 'present', null, 'e77576b3-fa4a-4aae-95a9-71b924f1180a'),
  ('e77576b3-fa4a-4aae-95a9-71b924f1180a', '3b3b3b3b-3b3b-4b3b-8b3b-3b3b3b3b3b3b', '22222222-2222-4222-8222-222222222222', 'c2c2c2c2-c2c2-4c2c-8c2c-c2c2c2c2c2c2', '2026-09-01', 'present', null, 'e77576b3-fa4a-4aae-95a9-71b924f1180a'),
  ('e77576b3-fa4a-4aae-95a9-71b924f1180a', '3b3b3b3b-3b3b-4b3b-8b3b-3b3b3b3b3b3b', '22222222-2222-4222-8222-222222222222', 'c2c2c2c2-c2c2-4c2c-8c2c-c2c2c2c2c2c2', '2026-09-08', 'present', null, 'e77576b3-fa4a-4aae-95a9-71b924f1180a'),
  ('e77576b3-fa4a-4aae-95a9-71b924f1180a', '3b3b3b3b-3b3b-4b3b-8b3b-3b3b3b3b3b3b', '22222222-2222-4222-8222-222222222222', 'c2c2c2c2-c2c2-4c2c-8c2c-c2c2c2c2c2c2', '2026-09-15', 'present', null, 'e77576b3-fa4a-4aae-95a9-71b924f1180a'),
-- عمر — Wed slot (teacher_home)
  ('e77576b3-fa4a-4aae-95a9-71b924f1180a', '4c4c4c4c-4c4c-4c4c-8c4c-4c4c4c4c4c4c', '44444444-4444-4444-8444-444444444444', 'c3c3c3c3-c3c3-4c3c-8c3c-c3c3c3c3c3c3', '2026-08-05', 'present', null, 'e77576b3-fa4a-4aae-95a9-71b924f1180a'),
  ('e77576b3-fa4a-4aae-95a9-71b924f1180a', '4c4c4c4c-4c4c-4c4c-8c4c-4c4c4c4c4c4c', '44444444-4444-4444-8444-444444444444', 'c3c3c3c3-c3c3-4c3c-8c3c-c3c3c3c3c3c3', '2026-08-12', 'present', null, 'e77576b3-fa4a-4aae-95a9-71b924f1180a'),
  ('e77576b3-fa4a-4aae-95a9-71b924f1180a', '4c4c4c4c-4c4c-4c4c-8c4c-4c4c4c4c4c4c', '44444444-4444-4444-8444-444444444444', 'c3c3c3c3-c3c3-4c3c-8c3c-c3c3c3c3c3c3', '2026-08-19', 'rescheduled', 'ظرف عائلي', 'e77576b3-fa4a-4aae-95a9-71b924f1180a'),
  ('e77576b3-fa4a-4aae-95a9-71b924f1180a', '4c4c4c4c-4c4c-4c4c-8c4c-4c4c4c4c4c4c', '44444444-4444-4444-8444-444444444444', 'c3c3c3c3-c3c3-4c3c-8c3c-c3c3c3c3c3c3', '2026-08-26', 'present', null, 'e77576b3-fa4a-4aae-95a9-71b924f1180a'),
  ('e77576b3-fa4a-4aae-95a9-71b924f1180a', '4c4c4c4c-4c4c-4c4c-8c4c-4c4c4c4c4c4c', '44444444-4444-4444-8444-444444444444', 'c3c3c3c3-c3c3-4c3c-8c3c-c3c3c3c3c3c3', '2026-09-02', 'absent', null, 'e77576b3-fa4a-4aae-95a9-71b924f1180a'),
  ('e77576b3-fa4a-4aae-95a9-71b924f1180a', '4c4c4c4c-4c4c-4c4c-8c4c-4c4c4c4c4c4c', '44444444-4444-4444-8444-444444444444', 'c3c3c3c3-c3c3-4c3c-8c3c-c3c3c3c3c3c3', '2026-09-09', 'present', null, 'e77576b3-fa4a-4aae-95a9-71b924f1180a'),
-- لين — Thu slot (teacher_home)
  ('e77576b3-fa4a-4aae-95a9-71b924f1180a', '5d5d5d5d-5d5d-4d5d-8d5d-5d5d5d5d5d5d', '22222222-2222-4222-8222-222222222222', 'c4c4c4c4-c4c4-4c4c-8c4c-c4c4c4c4c4c4', '2026-08-06', 'present', null, 'e77576b3-fa4a-4aae-95a9-71b924f1180a'),
  ('e77576b3-fa4a-4aae-95a9-71b924f1180a', '5d5d5d5d-5d5d-4d5d-8d5d-5d5d5d5d5d5d', '22222222-2222-4222-8222-222222222222', 'c4c4c4c4-c4c4-4c4c-8c4c-c4c4c4c4c4c4', '2026-08-13', 'present', null, 'e77576b3-fa4a-4aae-95a9-71b924f1180a'),
  ('e77576b3-fa4a-4aae-95a9-71b924f1180a', '5d5d5d5d-5d5d-4d5d-8d5d-5d5d5d5d5d5d', '22222222-2222-4222-8222-222222222222', 'c4c4c4c4-c4c4-4c4c-8c4c-c4c4c4c4c4c4', '2026-08-20', 'present', null, 'e77576b3-fa4a-4aae-95a9-71b924f1180a'),
  ('e77576b3-fa4a-4aae-95a9-71b924f1180a', '5d5d5d5d-5d5d-4d5d-8d5d-5d5d5d5d5d5d', '22222222-2222-4222-8222-222222222222', 'c4c4c4c4-c4c4-4c4c-8c4c-c4c4c4c4c4c4', '2026-08-27', 'absent', null, 'e77576b3-fa4a-4aae-95a9-71b924f1180a'),
  ('e77576b3-fa4a-4aae-95a9-71b924f1180a', '5d5d5d5d-5d5d-4d5d-8d5d-5d5d5d5d5d5d', '22222222-2222-4222-8222-222222222222', 'c4c4c4c4-c4c4-4c4c-8c4c-c4c4c4c4c4c4', '2026-09-03', 'present', null, 'e77576b3-fa4a-4aae-95a9-71b924f1180a'),
  ('e77576b3-fa4a-4aae-95a9-71b924f1180a', '5d5d5d5d-5d5d-4d5d-8d5d-5d5d5d5d5d5d', '22222222-2222-4222-8222-222222222222', 'c4c4c4c4-c4c4-4c4c-8c4c-c4c4c4c4c4c4', '2026-09-10', 'present', null, 'e77576b3-fa4a-4aae-95a9-71b924f1180a')
on conflict (student_id, slot_id, date) do nothing;

-- ---------- 6. FEES (أغسطس + سبتمبر) — payments refresh fee status via trigger ----------
insert into public.fees (id, school_id, student_id, month, amount, due_date, notes) values
  ('f0f0f0f0-f0f0-4f0f-8f0f-f0f0f0f0f0f0', 'e77576b3-fa4a-4aae-95a9-71b924f1180a', '2c1b7e72-6444-4359-be05-a7b83c1259ac', '2026-08', 50000, '2026-08-01', null),  -- أحمد (أغسطس)
  ('f1f1f1f1-f1f1-4f1f-8f1f-f1f1f1f1f1f1', 'e77576b3-fa4a-4aae-95a9-71b924f1180a', '2a2a2a2a-2a2a-4a2a-8a2a-2a2a2a2a2a2a', '2026-08', 45000, '2026-08-01', null),  -- محمد
  ('f2f2f2f2-f2f2-4f2f-8f2f-f2f2f2f2f2f2', 'e77576b3-fa4a-4aae-95a9-71b924f1180a', '2a2a2a2a-2a2a-4a2a-8a2a-2a2a2a2a2a2a', '2026-09', 45000, '2026-09-01', null),
  ('f3f3f3f3-f3f3-4f3f-8f3f-f3f3f3f3f3f3', 'e77576b3-fa4a-4aae-95a9-71b924f1180a', '3b3b3b3b-3b3b-4b3b-8b3b-3b3b3b3b3b3b', '2026-08', 50000, '2026-08-01', null),  -- سارة
  ('f4f4f4f4-f4f4-4f4f-8f4f-f4f4f4f4f4f4', 'e77576b3-fa4a-4aae-95a9-71b924f1180a', '3b3b3b3b-3b3b-4b3b-8b3b-3b3b3b3b3b3b', '2026-09', 50000, '2026-09-01', null),
  ('f5f5f5f5-f5f5-4f5f-8f5f-f5f5f5f5f5f5', 'e77576b3-fa4a-4aae-95a9-71b924f1180a', '4c4c4c4c-4c4c-4c4c-8c4c-4c4c4c4c4c4c', '2026-08', 40000, '2026-08-01', null),  -- عمر
  ('f6f6f6f6-f6f6-4f6f-8f6f-f6f6f6f6f6f6', 'e77576b3-fa4a-4aae-95a9-71b924f1180a', '4c4c4c4c-4c4c-4c4c-8c4c-4c4c4c4c4c4c', '2026-09', 40000, '2026-09-01', null),
  ('f7f7f7f7-f7f7-4f7f-8f7f-f7f7f7f7f7f7', 'e77576b3-fa4a-4aae-95a9-71b924f1180a', '5d5d5d5d-5d5d-4d5d-8d5d-5d5d5d5d5d5d', '2026-08', 45000, '2026-08-01', null),  -- لين
  ('f8f8f8f8-f8f8-4f8f-8f8f-f8f8f8f8f8f8', 'e77576b3-fa4a-4aae-95a9-71b924f1180a', '5d5d5d5d-5d5d-4d5d-8d5d-5d5d5d5d5d5d', '2026-09', 45000, '2026-09-01', null)
on conflict (student_id, month) do nothing;

-- ---------- 7. PAYMENTS (status updates via refresh_fee_status trigger) ----------
insert into public.payments (id, school_id, fee_id, student_id, amount, paid_at, method, note) values
  ('aa1aa1aa-aa1a-4aa1-8aa1-aa1aa1aa1aa1', 'e77576b3-fa4a-4aae-95a9-71b924f1180a', 'f0f0f0f0-f0f0-4f0f-8f0f-f0f0f0f0f0f0', '2c1b7e72-6444-4359-be05-a7b83c1259ac', 50000, '2026-08-05', 'cash', 'قسط آب'),
  ('aa2aa2aa-aa2a-4aa2-8aa2-aa2aa2aa2aa2', 'e77576b3-fa4a-4aae-95a9-71b924f1180a', 'f1f1f1f1-f1f1-4f1f-8f1f-f1f1f1f1f1f1', '2a2a2a2a-2a2a-4a2a-8a2a-2a2a2a2a2a2a', 45000, '2026-08-06', 'transfer', 'تحويل مصرفي'),
  ('aa3aa3aa-aa3a-4aa3-8aa3-aa3aa3aa3aa3', 'e77576b3-fa4a-4aae-95a9-71b924f1180a', 'f2f2f2f2-f2f2-4f2f-8f2f-f2f2f2f2f2f2', '2a2a2a2a-2a2a-4a2a-8a2a-2a2a2a2a2a2a', 20000, '2026-09-08', 'cash', 'دفعة أولى'),
  ('aa4aa4aa-aa4a-4aa4-8aa4-aa4aa4aa4aa4', 'e77576b3-fa4a-4aae-95a9-71b924f1180a', 'f3f3f3f3-f3f3-4f3f-8f3f-f3f3f3f3f3f3', '3b3b3b3b-3b3b-4b3b-8b3b-3b3b3b3b3b3b', 50000, '2026-08-07', 'cash', null),
  ('aa5aa5aa-aa5a-4aa5-8aa5-aa5aa5aa5aa5', 'e77576b3-fa4a-4aae-95a9-71b924f1180a', 'f5f5f5f5-f5f5-4f5f-8f5f-f5f5f5f5f5f5', '4c4c4c4c-4c4c-4c4c-8c4c-4c4c4c4c4c4c', 20000, '2026-08-10', 'cash', 'دفعة أولى'),
  ('aa6aa6aa-aa6a-4aa6-8aa6-aa6aa6aa6aa6', 'e77576b3-fa4a-4aae-95a9-71b924f1180a', 'f7f7f7f7-f7f7-4f7f-8f7f-f7f7f7f7f7f7', '5d5d5d5d-5d5d-4d5d-8d5d-5d5d5d5d5d5d', 45000, '2026-08-08', 'cash', null),
  ('aa7aa7aa-aa7a-4aa7-8aa7-aa7aa7aa7aa7', 'e77576b3-fa4a-4aae-95a9-71b924f1180a', 'f8f8f8f8-f8f8-4f8f-8f8f-f8f8f8f8f8f8', '5d5d5d5d-5d5d-4d5d-8d5d-5d5d5d5d5d5d', 45000, '2026-09-05', 'cash', null)
on conflict (id) do nothing;

-- ---------- 8. TESTS (كل اختبار يولّد إشعاراً لولي الأمر تلقائياً) ----------
insert into public.tests (id, school_id, student_id, subject_id, type, date, score, max_score, note) values
  ('b1b1b1b1-b1b1-4b1b-8b1b-b1b1b1b1b1b1', 'e77576b3-fa4a-4aae-95a9-71b924f1180a', '2c1b7e72-6444-4359-be05-a7b83c1259ac', '107d36b2-f5a5-45bb-869b-1f69a61f25e4', 'monthly', '2026-08-30', 42, 50, 'اختبار شهري آب'),
  ('b2b2b2b2-b2b2-4b2b-8b2b-b2b2b2b2b2b2', 'e77576b3-fa4a-4aae-95a9-71b924f1180a', '2c1b7e72-6444-4359-be05-a7b83c1259ac', '107d36b2-f5a5-45bb-869b-1f69a61f25e4', 'quiz', '2026-09-13', 18, 20, 'اختبار قصير'),
  ('b3b3b3b3-b3b3-4b3b-8b3b-b3b3b3b3b3b3', 'e77576b3-fa4a-4aae-95a9-71b924f1180a', '2a2a2a2a-2a2a-4a2a-8a2a-2a2a2a2a2a2a', '11111111-1111-4111-8111-111111111111', 'monthly', '2026-08-24', 38, 40, null),
  ('b4b4b4b4-b4b4-4b4b-8b4b-b4b4b4b4b4b4', 'e77576b3-fa4a-4aae-95a9-71b924f1180a', '2a2a2a2a-2a2a-4a2a-8a2a-2a2a2a2a2a2a', '11111111-1111-4111-8111-111111111111', 'quiz', '2026-09-14', 19, 20, null),
  ('b5b5b5b5-b5b5-4b5b-8b5b-b5b5b5b5b5b5', 'e77576b3-fa4a-4aae-95a9-71b924f1180a', '3b3b3b3b-3b3b-4b3b-8b3b-3b3b3b3b3b3b', '22222222-2222-4222-8222-222222222222', 'monthly', '2026-08-25', 45, 50, 'ممتاز'),
  ('b6b6b6b6-b6b6-4b6b-8b6b-b6b6b6b6b6b6', 'e77576b3-fa4a-4aae-95a9-71b924f1180a', '4c4c4c4c-4c4c-4c4c-8c4c-4c4c4c4c4c4c', '44444444-4444-4444-8444-444444444444', 'monthly', '2026-08-26', 30, 40, null),
  ('b7b7b7b7-b7b7-4b7b-8b7b-b7b7b7b7b7b7', 'e77576b3-fa4a-4aae-95a9-71b924f1180a', '5d5d5d5d-5d5d-4d5d-8d5d-5d5d5d5d5d5d', '22222222-2222-4222-8222-222222222222', 'quiz', '2026-09-10', 17, 20, null)
on conflict (id) do nothing;

-- ---------- 9. NOTES (تولّد إشعاراً لولي الأمر تلقائياً) ----------
insert into public.notes (id, school_id, student_id, author_id, body, created_at) values
  ('d1d1d1d1-d1d1-4d1d-8d1d-d1d1d1d1d1d1', 'e77576b3-fa4a-4aae-95a9-71b924f1180a', '2c1b7e72-6444-4359-be05-a7b83c1259ac', 'e77576b3-fa4a-4aae-95a9-71b924f1180a', 'أداء ممتاز هذا الأسبوع — حل جميع التمارين بشكل صحيح', '2026-09-01T09:00:00+00:00'),
  ('d2d2d2d2-d2d2-4d2d-8d2d-d2d2d2d2d2d2', 'e77576b3-fa4a-4aae-95a9-71b924f1180a', '3b3b3b3b-3b3b-4b3b-8b3b-3b3b3b3b3b3b', 'e77576b3-fa4a-4aae-95a9-71b924f1180a', 'يحتاج مراجعة قواعد الإملاء قبل الاختبار القادم', '2026-09-08T10:00:00+00:00'),
  ('d3d3d3d3-d3d3-4d3d-8d3d-d3d3d3d3d3d3', 'e77576b3-fa4a-4aae-95a9-71b924f1180a', '4c4c4c4c-4c4c-4c4c-8c4c-4c4c4c4c4c4c', 'e77576b3-fa4a-4aae-95a9-71b924f1180a', 'يُرجى متابعة الحضور — غاب عن جلستين هذا الشهر', '2026-09-09T11:00:00+00:00')
on conflict (id) do nothing;

-- ---------- 10. ANNOUNCEMENTS ----------
insert into public.announcements (id, school_id, author_id, body, created_at) values
  ('e1e1e1e1-e1e1-4e1e-8e1e-e1e1e1e1e1e1', 'e77576b3-fa4a-4aae-95a9-71b924f1180a', 'e77576b3-fa4a-4aae-95a9-71b924f1180a', 'بداية العام الدراسي — يُرجى تسديد الرسوم الشهرية مع بداية كل شهر، ويمكن الدفع نقداً أو تحويلاً.', '2026-09-01T08:00:00+00:00')
on conflict (id) do nothing;

-- ---------- 11. MANUAL TEACHER NOTIFICATION (إشعار تجريبي لمركز الإشعارات) ----------
insert into public.notifications (id, school_id, recipient_type, recipient_id, type, title, body, entity_ref, is_read, created_at) values
  ('abababab-abab-4bab-8bab-abababababab', 'e77576b3-fa4a-4aae-95a9-71b924f1180a', 'teacher', 'e77576b3-fa4a-4aae-95a9-71b924f1180a', 'general', 'أهلاً بك', 'هذه رسالة تجريبية للتأكد من مركز الإشعارات.', null, false, '2026-09-15T06:00:00+00:00')
on conflict (id) do nothing;