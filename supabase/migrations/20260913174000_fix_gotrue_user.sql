-- ============================================================
-- Durus (دروس) — Migration 009: full GoTrue-compatible user creation.
--
-- Password login returned 500 "Database error querying schema" because
-- the direct-inserted auth.users row had NULL token columns; GoTrue scans
-- them into non-nullable Go strings. Set them to '' explicitly, backfill
-- any existing NULLs, and drop the temporary diagnostic RPC.
-- ============================================================

-- 1) Backfill NULL token columns on any user rows (no-op for normal users).
update auth.users
   set confirmation_token     = coalesce(confirmation_token, ''),
       recovery_token         = coalesce(recovery_token, ''),
       email_change_token_new = coalesce(email_change_token_new, ''),
       email_change           = coalesce(email_change, '')
 where confirmation_token is null
    or recovery_token is null
    or email_change_token_new is null
    or email_change is null;

-- 2) Redefine the RPC with a GoTrue-complete insert.
create or replace function public.create_teacher_with_credentials(
  p_email text,
  p_password text,
  p_full_name text
)
returns uuid
language plpgsql
security definer
set search_path = public, auth, extensions
as $$
declare
  v_school uuid := public.current_school_id();
  v_id     uuid := gen_random_uuid();
  v_email  text := lower(trim(p_email));
  v_has_provider_id boolean;
begin
  if not public.is_manager() or v_school is null then
    raise exception 'forbidden';
  end if;
  if v_email is null or position('@' in v_email) = 0 then
    raise exception 'invalid_email';
  end if;
  if char_length(coalesce(p_password, '')) < 6 then
    raise exception 'weak_password';
  end if;
  if exists (select 1 from auth.users where lower(email) = v_email) then
    raise exception 'email_exists';
  end if;

  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password,
    email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    created_at, updated_at
  ) values (
    '00000000-0000-0000-0000-000000000000',
    v_id,
    'authenticated',
    'authenticated',
    v_email,
    crypt(p_password, gen_salt('bf')),
    now(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    jsonb_build_object('full_name', p_full_name),
    '', '', '', '',
    now(),
    now()
  );

  select exists (
    select 1 from information_schema.columns
    where table_schema = 'auth'
      and table_name = 'identities'
      and column_name = 'provider_id'
  ) into v_has_provider_id;

  if v_has_provider_id then
    insert into auth.identities (
      id, user_id, provider_id, identity_data, provider,
      last_sign_in_at, created_at, updated_at
    ) values (
      gen_random_uuid(), v_id, v_id::text,
      jsonb_build_object('sub', v_id::text, 'email', v_email),
      'email', now(), now(), now()
    );
  else
    insert into auth.identities (
      id, user_id, identity_data, provider,
      last_sign_in_at, created_at, updated_at
    ) values (
      gen_random_uuid(), v_id,
      jsonb_build_object('sub', v_id::text, 'email', v_email),
      'email', now(), now(), now()
    );
  end if;

  update public.profiles
     set email = v_email,
         school_id = v_school,
         is_manager = false,
         role = 'teacher',
         manager_id = auth.uid(),
         full_name = p_full_name,
         onboarded = true,
         active = true
   where id = v_id;

  return v_id;
end $$;

grant execute on function public.create_teacher_with_credentials(text, text, text) to authenticated;

-- 3) Remove the temporary diagnostic function.
drop function if exists public._diag_auth_columns();