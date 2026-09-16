-- ============================================================
-- Durus (دروس) — Migration 020: teacher-editable profile fields
-- Adds `bio`, `phone`, `avatar_theme`, `avatar_gender`, `avatar_seed`
-- to public.profiles for the rebuilt profile screen:
--   - bio/phone: free-text teacher details;
--   - avatar_theme: Avatune style key ('fatin-verse' | 'yanliu' | 'micah');
--   - avatar_gender: 'm' | 'f' | null (null = neutral style);
--   - avatar_seed: custom shuffle seed; null falls back to profile id.
-- RLS: policy profiles_update_self already allows self-update and only
-- pins `is_manager`, so NO policy change is needed — the new columns
-- are self-editable by design, role/school/status stay guarded.
-- ============================================================

alter table public.profiles
  add column if not exists bio text,
  add column if not exists phone text,
  add column if not exists avatar_theme text not null default 'fatin-verse',
  add column if not exists avatar_gender text,
  add column if not exists avatar_seed text;

alter table public.profiles drop constraint if exists profiles_avatar_gender_check;
alter table public.profiles
  add constraint profiles_avatar_gender_check
  check (avatar_gender is null or avatar_gender in ('m', 'f'));
