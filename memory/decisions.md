# Decisions — Durus

Append-only. Format: `ADR-YYYYMMDD-XXX`.

## ADR-20260913-001 — Arabic only, RTL

- **Status:** Accepted
- **Context:** Sister teaches grades 1–6 in Syria; parents are non-technical, Arabic-speaking.
- **Decision:** Arabic-only UI, RTL from day one. All strings via `.arb`
  (`app_ar.arb` template); no hardcoded strings, no second locale.
- **Consequences:** No i18n maintenance; RTL is a hard layout requirement.

## ADR-20260913-002 — Flutter all-in-one (Android app + responsive web)

- **Status:** Accepted (user chose Option A)
- **Context:** Need a teacher Android app AND a parent link-based responsive web
  portal AND an admin dashboard; keep it maintainable by one developer.
- **Decision:** ONE Flutter codebase targeting Android (teacher/manager) and
  responsive web (parents + admin dashboard).
- **Consequences:** One language, one project; Flutter web is the parent/admin
  surface. Mirrors the Klear Android+Web pattern.

## ADR-20260913-003 — Supabase backend, RLS as the security boundary

- **Status:** Accepted
- **Context:** Free tier required; existing stack across sibling projects
  (Klear, Dîtin, QR-Menu) is Supabase.
- **Decision:** Supabase (Postgres + Auth + RLS + Realtime), one project.
  Never embed service-role keys; teacher/manager/parent scoping enforced in
  Postgres.
- **Consequences:** All data access flows through anon/authenticated keys with
  strict RLS policies.

## ADR-20260913-004 — Single/multi teacher decided by first-launch wizard

- **Status:** Accepted
- **Context:** App must support either one teacher or a team with a manager.
- **Decision:** A one-time wizard asks at first start. Single → the teacher IS
  the manager. Multi → creator becomes manager; other teachers join via
  invitation link or manager-created credentials.
- **Consequences:** UI identical in both modes; multi-teacher scoping is purely
  data/RLS (`assigned_teacher`), not UI branching.

## ADR-20260913-005 — Parent access via PIN links (no accounts, v1)

- **Status:** Accepted
- **Context:** Parents are non-technical; linking must work on any device with
  zero setup friction.
- **Decision:** Teacher generates a per-student PIN-protected link. Parent
  opens it, enters the PIN, sees only their child. No parent accounts in v1.
- **Consequences:** Simplest possible UX; revisit accounts only if parents need
  multi-student families or messaging (later phase).

## ADR-20260913-006 — Variable monthly fees, ledger-based

- **Status:** Accepted
- **Context:** Monthly wage varies per student; teacher wants complete control.
- **Decision:** Fee record per student/month with free-form amount, due date,
  status, and a payment history (partial payments supported). No fixed pricing
  model in code.
- **Consequences:** Fees are a ledger, not a calculator.

## ADR-20260913-007 — Subjects are full CRUD

- **Status:** Accepted
- **Context:** Teacher manages all subjects and all their details.
- **Decision:** `subjects` is a CRUD entity (name, grade, notes) — no fixed
  enum and no built-in subject list.
- **Consequences:** RLS-scoped like other data; teacher owns the list.