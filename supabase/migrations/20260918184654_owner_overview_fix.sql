-- ============================================================
-- Durus (دروس) — Migration 035: fix owner_overview schools block
-- The per-school aggregate correlated on bare p.school_id / p.id inside
-- a GROUP BY query → 42803 "subquery uses ungrouped column". Restructured
-- to group a distinct-school driver first; correlated subqueries now
-- reference only the grouped key. Found live 2026-09-18 via a temporary
-- owner probe (throwaway user + temp app_owners row, both removed after).
-- ============================================================

create or replace function public.owner_overview()
returns jsonb
language plpgsql security definer set search_path = public
as $$
declare
  v_is_owner boolean := public.is_app_owner();
  v_month_start date := date_trunc('month', now())::date;
  v_week_ago timestamptz := now() - interval '7 days';
  v_day_ago timestamptz := now() - interval '24 hours';
begin
  if not v_is_owner then
    raise exception 'not_owner';
  end if;

  return jsonb_build_object(
    'totals', (
      select jsonb_build_object(
        'users',     count(*),
        'managers',  count(*) filter (where is_manager),
        'teachers',  count(*) filter (where not is_manager),
        'active',    count(*) filter (where active),
        'schools',   count(distinct coalesce(school_id, id)),
        'students',  (select count(*) from public.students),
        'subjects',  (select count(*) from public.subjects),
        'sessions_month', (
          select count(*) from public.sessions
           where date >= v_month_start
        ),
        'collected_month', (
          select coalesce(sum(amount), 0) from public.payments
           where paid_at >= v_month_start
        ),
        'outstanding', (
          select coalesce(sum(amount - paid_amount), 0) from public.fees
           where status <> 'paid'
        ),
        'invites_pending', (
          select count(*) from public.invitations where status = 'pending'
        ),
        'requests_open', (
          select count(*) from public.feature_requests
           where status in ('new', 'reviewing', 'planned')
        )
      )
      from public.profiles
    ),
    'active_today', (
      select count(*) from public.client_heartbeats
       where last_seen >= v_day_ago
    ),
    'active_week', (
      select count(*) from public.client_heartbeats
       where last_seen >= v_week_ago
    ),
    'versions', (
      select coalesce(jsonb_agg(t), '[]'::jsonb) from (
        select app_version as version, platform,
               count(*) as users, max(last_seen) as last_seen
          from public.client_heartbeats
         group by app_version, platform
         order by max(last_seen) desc
         limit 20
      ) t
    ),
    'signups_per_week', (
      select coalesce(jsonb_agg(t), '[]'::jsonb) from (
        select to_char(date_trunc('week', created_at), 'YYYY-MM-DD') as week,
               count(*) as count
          from auth.users
         where created_at >= now() - interval '8 weeks'
         group by 1
         order by 1
      ) t
    ),
    'schools', (
      select coalesce(jsonb_agg(t), '[]'::jsonb) from (
        select g.school_id,
               max(case when p.is_manager then p.full_name end) as manager,
               max(case when p.is_manager then p.email end) as email,
               count(p.id) filter (where not p.is_manager) as teachers,
               (select count(*) from public.students s
                 where s.school_id = g.school_id) as students,
               (select max(se.date) from public.sessions se
                 where se.school_id = g.school_id) as last_session
          from (select distinct coalesce(school_id, id) as school_id
                  from public.profiles) g
          left join public.profiles p
            on coalesce(p.school_id, p.id) = g.school_id
         group by g.school_id
         order by students desc
         limit 100
      ) t
    ),
    'requests', (
      select coalesce(jsonb_agg(t), '[]'::jsonb) from (
        select r.id, r.type, r.title, r.body, r.status, r.created_at,
               r.author_id, p.full_name as author_name, p.email as author_email
          from public.feature_requests r
          left join public.profiles p on p.id = r.author_id
         order by r.created_at desc
         limit 20
      ) t
    )
  );
end $$;
