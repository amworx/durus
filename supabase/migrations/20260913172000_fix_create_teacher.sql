-- ============================================================
-- Durus (دروس) — Migration 008: fix teacher account creation.
--
-- `auth.admin_create_user(...)` is NOT available as a SQL function on
-- this project (GoTrue exposes it only through the Admin API), so
-- `create_teacher_with_credentials` failed with 42883. Redefine it to
-- create the auth user + identity with direct inserts (tcrypt password)
-- inside a security-definer function — no service-role key needed.
-- ============================================================

create extension if not exists pgcrypto with schema extensions;

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
    now(),
    now()
  );

  -- GoTrue added `provider_id` in newer versions; detect it to stay
  -- compatible with both schemas.
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

  -- The on_auth_user_created trigger already inserted a stub profile row.
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