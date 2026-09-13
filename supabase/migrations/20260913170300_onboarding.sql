-- ============================================================
-- Durus (دروس) — Migration 004: onboarding flag + onboarding RPC
-- ============================================================

alter table public.profiles
  add column if not exists onboarded boolean not null default false;

-- Complete first-launch setup for the school creator (manager).
-- Security definer so the creator can set is_manager/school_id on their row
-- (the RLS update policy intentionally forbids flipping is_manager directly).
create or replace function public.complete_onboarding(p_full_name text, p_is_manager boolean)
returns void
language plpgsql security definer set search_path = public
as $$
begin
  if p_is_manager then
    update public.profiles
       set full_name = coalesce(nullif(trim(p_full_name), ''), full_name),
           role = 'manager',
           is_manager = true,
           school_id = auth.uid(),
           onboarded = true
     where id = auth.uid();
  else
    update public.profiles
       set full_name = coalesce(nullif(trim(p_full_name), ''), full_name),
           onboarded = true
     where id = auth.uid();
  end if;
end $$;

-- Teacher created directly with credentials is ready immediately.
create or replace function public.create_teacher_with_credentials(p_email text, p_password text, p_full_name text)
returns uuid
language plpgsql security definer set search_path = public, auth
as $$
declare
  v_school uuid := public.current_school_id();
  v_id     uuid;
begin
  if not public.is_manager() or v_school is null then
    raise exception 'forbidden';
  end if;
  select id into v_id from auth.users where email = p_email;
  if v_id is not null then
    raise exception 'email_exists';
  end if;
  v_id := (auth.admin_create_user(
    email := p_email,
    password := p_password,
    email_confirm := true,
    user_metadata := jsonb_build_object('full_name', p_full_name)
  )).id;
  update public.profiles
     set school_id = v_school, is_manager = false, role = 'teacher',
         manager_id = auth.uid(), full_name = p_full_name, onboarded = true
   where id = v_id;
  return v_id;
end $$;

-- Accepting an invitation completes onboarding for that teacher.
create or replace function public.accept_invitation(p_token uuid)
returns void
language plpgsql security definer set search_path = public
as $$
declare
  v public.invitations%rowtype;
begin
  select * into v from public.invitations
  where token = p_token and status = 'pending' and expires_at > now();
  if not found then
    raise exception 'invalid_invitation';
  end if;
  update public.profiles
     set school_id = v.school_id, is_manager = false, role = 'teacher',
         manager_id = v.manager_id, onboarded = true
   where id = auth.uid();
  update public.invitations
     set status = 'accepted', accepted_at = now()
   where id = v.id;
end $$;

grant execute on function public.complete_onboarding(text, boolean) to authenticated;