-- ============================================================
-- TEMPORARY diagnostic: list auth.users / auth.identities columns.
-- Dropped in the next migration.
-- ============================================================
create or replace function public._diag_auth_columns()
returns table (tbl text, col text, nullable text, dflt text)
language sql security definer set search_path = public, auth
as $$
  select table_name::text, column_name::text, is_nullable::text, coalesce(column_default, '')::text
  from information_schema.columns
  where table_schema = 'auth' and table_name in ('users', 'identities')
  order by table_name, ordinal_position;
$$;

grant execute on function public._diag_auth_columns() to authenticated;