# Operations — Durus

Append-only. Format: `OP-YYYYMMDD-XXXX`.

| ID | Timestamp | Workflow | Project | Steps | Duration | Result | Lessons | Reusable pattern |
|---|---|---|---|---|---|---|---|---|
| OP-20260913-0001 | 2026-09-13 | Project initialization | durus | research domain → scope with user (6 questions) → confirm container/name/frontend → create scaffold (AGENTS.md, docs/plans/tasks/src/memory) → write plan + tasks + ADRs → update container root AGENTS.md | ~1 session | Project "Durus (دروس)" scaffolded; master plan approved; Phase 1 tasks defined (approval-gated) | Scope first with the 6 questions; frontend split is the one architecture fork worth asking; everything else inferred | Research-driven project init with approval-gated Phase 1 |
| OP-20260913-0002 | 2026-09-13 | Phase 0–3 implementation (incl. notifications) | durus | pin pubspec → pub get → supabase init/link → migrations 001–004 (2 transient failures fixed) → 4 parallel workers (core, shell, CRUD, notifications+portal) → integration: l10n_ext + import patch, analyzer fixes (12), dart fix (41), tests (10), build web + apk-debug → docs/memory update | ~1 session | Backend live; app compiles for web + Android; 0 analyze issues; 10/10 tests; notifications shipped | (1) postgrest 2.9.1: filters only on PostgrestFilterBuilder — apply before `order()`/`limit()`; (2) Flutter 3.44 removed `start/end` from `EdgeInsets.only` (use `EdgeInsetsDirectional`); (3) `ref.invalidate()` per provider, no `invalidateAll` on WidgetRef; (4) PowerShell 5.1 Get-Content garbles UTF-8 Arabic in display only — verify files with a UTF-8 reader, save via `[IO.File]` + `UTF8Encoding($false)`; (5) `.arb` keys must be flat camelCase (dotted keys invalid) | Parallel worker build → single-threaded integration gate (gen-l10n, analyze, test, build) with explicit contract file shared before workers start || OP-20260913-0003 | 2026-09-13 | Smoke test (first real run) | durus | flutter run web-server 8080 > chrome-devtools MCP a11y tree > admin-API user creation (email_confirm) > full teacher flow (login, wizard, subject, student, portal link, slot, attendance, fee, payment, notifications, themes) > parent portal in 2nd tab > DB cross-checks | ~1 session | Core product loop verified live in browser; 3 minor findings pending fix decision | (1) Flutter web needs 'Enable accessibility' click per page; fill tool drops chars on Flutter inputs - use focus + Ctrl+A + type_text; (2) reserved-TLD emails and email-confirmation block pure-form signup - create users via admin API for tests; (3) verify provider freshness by reloading/invalidating - cache can lag DB | Smoke test via accessibility tree + DB cross-checks; bypass email confirmation for tests with service-role admin users |
| OP-20260913-0004 | 2026-09-13 | Fix loop (3 findings) | durus | (1) add l10n keys in app_ar.arb > gen-l10n; (2) home_shell.dart: add realtime channel (onPostgresChanges, notifications) + migration 005 (supabase_realtime publication) > db push; (3) fees_screens.dart: month TextFormField validator (YYYY-MM) + select-all-on-tap; Patch corrupted fee row; (4) auth_screens.dart: extract _authErrorText helper + authCheckEmail snackbar > analyze > test > build web + apk | ~1 session | Findings 1-3 fixed; test and build green | _authErrorText must be a top-level or shared function if referenced across multiple StatefulWidget classes; supabase_flutter channel(...).subscribe() returns RealtimeChannel not StreamSubscription; supabase_realtime publication must explicitly include each table for onPostgresChanges to work | Fix loop pattern: memory/approval → l10n → implement → db push → analyze/test/build → commit |

---

### OP-20260913-0005

| Field | Value |
|-------|-------|
| id | OP-20260913-0005 |
| timestamp | 2026-09-13T20:15:00+03:00 |
| workflow | feature-implementation |
| project | durus |
| steps | [1] Migration 006 created + pushed live. [2] MonthlyReport model (+ AttendanceSummary, ReportFee, ReportTest, ReportNote). [3] generateReport API method. [4] isoDate public helper in utils. [5] L10n keys (schedule/calendar/report/attendance). [6] schedule_screen.dart — weekly calendar tab. [7] eports_screen.dart — monthly report screen. [8] Student detail: attendance history section + report navigation button. [9] HomeShell: 6th tab (calendar). [10] 3 new unit tests. [11] lutter analyze 0, tests 13/13, web+APK builds pass. [12] Live Chrome smoke test. [13] Tasks + memory. |
| duration | ~15 min |
| result | success — migration pushed, features verified live in Chrome, committed as latest. |
| lessons | (1) supabase db push --yes needs password from CREDENTIALS.txt (KEY: value format with colon). (2) Background lutter run dies; use lutter build web + python -m http.server for live verification — more reliable and production-like. (3) New screen files must import both pp_localizations.dart (type) and l10n_ext.dart (extension). (4) Nested .when() for multiple async providers is cleaner than record-pattern matching on sealed types. |
| reusable_pattern | "Build → static-serve → Chrome MCP verify" for UI smoke tests: lutter build web, python -m http.server build/web, then chrome-devtools MCP to drive the app. Much faster than lutter run background. |

---

### OP-20260914-0001

| Field | Value |
|-------|-------|
| id | OP-20260914-0001 |
| timestamp | 2026-09-14T14:00:00+03:00 |
| workflow | feature-implementation |
| project | durus |
| steps | [1] Migration 007 (profiles.active + set_teacher_active RPC + index) pushed. [2] Profile model gains `active` (default true) + test. [3] API setTeacherActive. [4] Settings teacher list: status chip + toggle + always-visible add button (was missing in empty state). [5] Router: DisabledAccountScreen gate for `!profile.active`. [6] Home: announcement compose bottom sheet → createAnnouncement → invalidate. [7] l10n keys added + gen-l10n. [8] analyze 0, tests 14/14, build web. [9] Smoke: compose announcement, create teacher2 with credentials, disable → blocked login, re-enable → access. [10] Migration 008 diagnostic + 009 fix: replace auth.admin_create_user with direct GoTrue-complete inserts (token cols '', provider_id detection) + NULL backfill. [11] Portal mobile pass: 390px + 320px overflow check on entry + home. [12] Tasks + memory + commit. |
| duration | ~1 session |
| result | success — teacher disable/enable works end-to-end; announcements compose shipped; teacher creation unblocked; portal mobile-safe |
| lessons | (1) `auth.admin_create_user` is not callable as SQL inside a security-definer function — use direct auth.users/identities inserts. (2) Direct-inserted users need `confirmation_token`/`recovery_token`/`email_change_token_new`/`email_change` = '' (NULL breaks GoTrue password grant with a 500). (3) `auth.identities.provider_id` is NOT NULL in newer GoTrue — detect via information_schema and branch. (4) PostgREST returns scalar-returning RPC output as a bare JSON string. (5) Always verify user creation by actually logging in. |
| reusable_pattern | To add manager-gated account state without a service role: add an `active` column + a security-definer RPC guarded by `is_manager()`, gate the app in the router, and confirm with an isolated-context browser login. For auth-user creation on Supabase without the Admin API, use the "direct GoTrue-complete insert" pattern (token cols '', provider_id branch). |
---

### OP-20260914-0002

| Field | Value |
|-------|-------|
| id | OP-20260914-0002 |
| timestamp | 2026-09-14T18:30:00+03:00 |
| workflow | deployment (100% free) |
| project | durus |
| steps | [1] Create public repo amworx/durus + push master. [2] flutter build web --release --base-href /durus/. [3] Push build/web to gh-pages branch (orphan init in temp dir + .nojekyll). [4] Pages auto-enabled (source gh-pages /); verified live boot in Chrome. [5] keytool: generate durus-release.keystore (random 28-char pw, stored in durus-keys/CREDENTIALS.txt) + key.properties. [6] Wire release signing in app/build.gradle.kts (debug fallback) + disable lint (datastore-jvm:1.1.7 missing). [7] flutter build apk --release → app-release.apk 55.5MB. [8] gh release create v1.0.0 with APK. [9] Commit + push signing change. |
| duration | ~40 min |
| result | success — https://amworx.github.io/durus/ live; APK at https://github.com/amworx/durus/releases/tag/v1.0.0 |
| lessons | keytool writes progress to stderr → PowerShell $? is false even on success; use Test-Path on the artifact instead. gh may be slow uploading 55MB APK — give the create call a 10-min timeout. |
| reusable_pattern | free_deploy_flutter_github: (1) repo create + push; (2) build web with --base-href /<repo>/; (3) orphan gh-pages branch containing build/web + .nojekyll; (4) Pages auto-enables; (5) sign APK with a generated keystore kept outside the repo; (6) gh release create v1.0.0 with the APK. Total cost USD 0. |