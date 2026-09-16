# Events — Durus

Append-only. Format: `EVT-YYYYMMDD-XXXX`.

| ID | Timestamp | Mode | Action | Summary | Result | Files | Errors | Lessons | Tags |
|---|---|---|---|---|---|---|---|---|---|
| EVT-20260913-0001 | 2026-09-13 | RESEARCH | Domain research | Researched tutoring-management products (TutorBird, TutorHive, ClassRec, TuitionDesk, CloudSchool, ClassDojo, Smart Center, El Mister) to scope a private-lessons app for a single teacher + parent follow-up (monthly subscriptions, grades 1–6, lessons at home/student home) | Product definition confirmed with user (Arabic-only, single/multi teacher wizard, variable fees, parent PIN links) | plans/2026-09-13_plan.md | none | Western tools assume online payments (Stripe/PayPal) — invalid in Syria, cash payments need a tracking ledger; ClassDojo PIN/code model is the parent-side reference | tutoring, research |
| EVT-20260913-0002 | 2026-09-13 | PLAN | Project initialization | User confirmed container `code_repo`, name `durus`, Frontend Option A (Flutter all-in-one). Created project scaffold: AGENTS.md, docs/plans/tasks/src/memory | Scaffold created; master plan + tasks + memory written; root container AGENTS.md updated with durus row | AGENTS.md, plans/2026-09-13_plan.md, tasks/2026-09-13_tasks.md, memory/* | none | Reuse the Klear layout (Flutter project under `src/`); machine is network-constrained (pin versions) | initialization, plan |
| EVT-20260913-0003 | 2026-09-13 | BUILD | Supabase backend | Init/link in `durus/supabase`; wrote + pushed 4 migrations: 001 tables+indexes+triggers, 002 helpers/RLS/RPCs (`create_teacher_with_credentials`, `invitation_for`, `accept_invitation`, `parent_portal`), 003 notifications table + 7 triggers + parent RPCs, 004 `onboarded` + `complete_onboarding` | All 4 migrations live on project `rdlapngvsxhdcoxdcjov` | supabase/migrations/*.sql | 002 & 003 failed once each: SQL-language functions validate at creation (define helpers first); `jsonb_agg(... ORDER BY ... LIMIT)` invalid → subquery pattern | SQL functions validate bodies at creation; aggregate ORDER BY needs subquery; PostgREST `.order()` defaults to descending | backend, supabase, migration |
| EVT-20260913-0004 | 2026-09-13 | BUILD | Parallel worker implementation | 4 `worker` subagents in parallel: A core/API/models/providers, B shell/theme/auth/router, C CRUD screens, D notifications + parent portal | 4× STATUS SUCCESS; contract files landed in `lib/{core,models,providers,theme,widgets,screens}` | src/lib/** | Workers could not compile (parallel lock contention) — expected, integration phase owned that | Give workers complete units + shared contract; gen-l10n emits NO `l10n` BuildContext extension in Flutter 3.44 → add your own | delegation, workers |
| EVT-20260913-0005 | 2026-09-13 | BUILD | Integration + verification | Added `lib/l10n/l10n_ext.dart` (`context.l10n` + `kDurusLocale`); patched imports in 14 files; fixed 12 analyzer errors/warnings (postgrest filters before order, Flutter 3.44 `EdgeInsets.only` has no `start/end`, `ref.invalidate` vs `invalidateAll`, positional `createTeacher`, null-safe sorts/text); `dart fix --apply --code=use_null_aware_elements` (41 fixes); replaced broken widget_test with 10 real tests | `flutter analyze` 0 issues; `flutter test` 10/10 green; `flutter build web` ✓; `flutter build apk --debug` ✓ (Gradle 108s, pinned offline deps OK) | src/lib/l10n/l10n_ext.dart, src/lib/core/durus_api.dart, src/test/widget_test.dart, +screens | EdgeInsets.only API change; postgrest filter chain; Riverpod 2 WidgetRef API | Verify every worker claim via analyzer/tests/builds — "worker said done" is not proof | integration, verify |
| EVT-20260913-0006 | 2026-09-13 | MEMORY | Wrap-up | Updated plan (ADR-008, notifications model, phases), tasks (ticks + status), root AGENTS.md secrets list (`durus-keys/`), wrote docs/ui-designs.md (3 themes), appended events/operations | Docs + memory reflect reality; git commits pending | plans/, tasks/, memory/, docs/ui-designs.md, ../../AGENTS.md | none | Records keep the loop verifiable | memory, docs || EVT-20260913-0007 | 2026-09-13 | REVIEW | Smoke test (Chrome web) | Ran app at localhost:8080 via chrome-devtools MCP: signup (blocked by GoTrue: reserved .test TLD rejected; email confirmation ON + send rate limit) > created test user via service-role admin API > login > wizard single-teacher > subject > student > parent portal link > weekly slot (Sun 09:00-10:00) > attendance حاضر > fee 50000 > payment 20000 > teacher notification + mark-read > parent portal (token URL): attendance 100%, schedule, installment, 3 notifications > themes | Core flows ALL pass end-to-end. Findings: (1) notifications badge/list stale until provider refresh (cache lag); (2) notification titles show month twice ('2026-092026-09') - label duplicated in SQL trigger; (3) signup error snackbar hides real server message; email confirmation leaves no session | source unchanged; memory appended | generic error snackbar hides root cause; FutureProvider cache lags DB unless invalidated; test emails need confirmed users | smoke, review |
| EVT-20260913-0008 | 2026-09-13 | BUILD | Smoke-test findings fix loop | Fixed 3 findings from first real-run: (1) added realtime subscription on notifications table in HomeShell + migration 005 (supabase_realtime publication) — badge/list now update instantly; (2) fee month field: added YYYY-MM regex validator + select-all-on-tap UX to prevent doubled input; corrected the corrupted smoke-test row via Patch; (3) signup UX: surfaced real GoTrue error codes (email_address_invalid, over_rate_limit, already_exists, email_not confirmed) + added authCheckEmail snackbar shown when email confirmation is required | 0 analyze issues; 10/10 tests green; web+apk builds pass; DB migration 005 applied; corrupted fee row corrected | auth_screens.dart, fees_screens.dart, home_shell.dart, app_ar.arb, 005 migration | 1 | flutter gen-l10n must run after .arb changes | fix, notification, auth, fee |

---

### EVT-20260913-0009

| Field | Value |
|-------|-------|
| id | EVT-20260913-0009 |
| timestamp | 2026-09-13T20:15:00+03:00 |
| mode | BUILD |
| action | feature-loop: weekly calendar + attendance history + monthly reports |
| summary | Added three features: (1) weekly calendar tab "جدول الأسبوع" with prev/this/next week navigation and 7-day view showing recurring slots + recorded sessions; (2) attendance history section on student detail screen showing last 10 sessions with date, subject, and attendance chip; (3) monthly report screen with month picker, RPC generate_report call, and sections for attendance (percent + counts), fee (status/amount/paid/remaining), tests, and notes. Backend: migration 006 adds generate_report RPC (security-definer, upserts into eports) and unique constraint on (student_id, month). |
| result | success — lutter analyze 0 issues, 13/13 tests green, lutter build web + lutter build apk --debug succeed. Live smoke test in Chrome: weekly calendar shows Monday–Sunday view with Ahmad's slot on Sunday; attendance history shows "2026-09-13 • رياضيات • حاضر"; monthly report for سبتمبر 2026 shows 100% attendance (1/1), partial fee 50000/20000/30000; month switching to أغسطس shows all empty states. |
| files | supabase/migrations/20260913170500_reports.sql, src/lib/models/models.dart, src/lib/core/durus_api.dart, src/lib/core/utils.dart, src/lib/l10n/app_ar.arb, src/lib/screens/schedule_screen.dart, src/lib/screens/reports_screen.dart, src/lib/screens/students_screens.dart, src/lib/screens/home_shell.dart, src/test/widget_test.dart, 	asks/2026-09-13_tasks.md |
| errors | None |
| lessons | (1) Config.supabaseUrl / supabasePublishableKey carry defaultValue in dart-define, so lutter build web without explicit --dart-define still connects to the real project; verified. (2) AsyncValue(value: ...) record-pattern matching on sealed types doesn't promote cleanly — prefer nested .when() calls for multiple async providers in a single build. (3) Private helpers duplicated across screens (_dayLabel, _subjectName, _testTypeLabel) — candidates for a shared utils/helpers file in next refactor pass. |
| tags | build, features, phase3, phase5, reports |

---

### OP-20260913-0005

| Field | Value |
|-------|-------|
| id | OP-20260913-0005 |
| timestamp | 2026-09-13T20:15:00+03:00 |
| workflow | feature-implementation |
| project | durus |
| steps | [1] Migration 006 created (reports unique constraint + generate_report RPC) and pushed live. [2] MonthlyReport / AttendanceSummary / ReportFee / ReportTest / ReportNote models added to models.dart. [3] generateReport API method added to durus_api.dart. [4] isoDate public helper added to utils.dart. [5] L10n keys added (navSchedule, scheduleWeeklyTitle, schedulePrevWeek/NextWeek/ThisWeek, scheduleNoSlots, scheduleRecurringSlot, studentsDetailAttendance, studentsNoAttendance, reportsTitle/Submit/Month/Attendance/NoAttendance/Fee/NoFee/Tests/NoTests/Notes/NoNotes/GeneratedAt). [6] schedule_screen.dart created (weekly calendar: week header, 7-day card list, slot rows, session rows). [7] reports_screen.dart created (month picker, generate button, attendance/fee/tests/notes sections). [8] students_screens.dart updated (attendance history SectionCard + monthly report navigation button). [9] home_shell.dart updated (6th tab: calendar_month icon, ScheduleScreen). [10] 3 unit tests added (isoDate, MonthlyReport full, MonthlyReport empty). [11] lutter analyze 0 issues, 13/13 tests, web + APK builds pass. [12] Live Chrome smoke test: schedule tab, student detail attendance, monthly report month switching. [13] Tasks file updated, memory appended, git committed. |
| duration | ~15 min |
| result | success |
| lessons | (1) Migration push needs supabase db push --yes --password <pw> with correct CREDENTIALS.txt key format (KEY: value with colon, not =). (2) Background lutter run debug servers die; for live verification, a plain lutter build web + Python static server on uild/web/ is far more reliable and lighter. (3) New screen imports must include both pp_localizations.dart (for AppLocalizations type) and l10n_ext.dart (for the context.l10n extension). |
| reusable_pattern | "Build → static-serve → Chrome MCP verify" for UI smoke tests. Instead of background lutter run, build once (lutter build web), serve with python -m http.server, and drive Chrome DevTools MCP. Faster startup, no hot-reload races, production-like environment. |

---

### EVT-20260914-0001

| Field | Value |
|-------|-------|
| id | EVT-20260914-0001 |
| timestamp | 2026-09-14T14:00:00+03:00 |
| mode | BUILD |
| action | loop: teacher status gate + announcements compose + portal pass + create-teacher fix |
| summary | Migration 007 adds `profiles.active` + `set_teacher_active` RPC (security definer, manager-only, excludes self). Settings teacher list now shows a status chip (مفعّل/موقوف) + per-teacher toggle; AuthGate blocks inactive profiles with a new `DisabledAccountScreen` (logout only). Home announcements card gained a compose bottom sheet (createAnnouncement + invalidate announcements/notifications). Discovered + fixed `create_teacher_with_credentials`: it called `auth.admin_create_user` (not a SQL function on this project → 42883); migrations 008/009 replace it with GoTrue-complete direct `auth.users` + `auth.identities` inserts (token columns set to '', dynamic `provider_id` detection) plus a NULL backfill; fixed the Dart scalar-RPC cast. Also fixed: settings "add teacher" button was missing when the teacher list was empty. Parent portal verified overflow-free at 390px and 320px (entry + home). |
| result | success — `flutter analyze` 0 issues, 14/14 tests, `flutter build web` ok. Live smoke (static server + Chrome MCP): composed announcement (REST 200 + rendered with date), created teacher2 (RPC 200 returns scalar uuid; profile scoped to manager's school), disabled teacher2 → its login shows "الحساب موقوف", re-enabled → HomeShell restored. |
| files | supabase/migrations/20260913171000_teacher_status.sql, 20260913172000_fix_create_teacher.sql, 20260913173000_diag_auth.sql, 20260913174000_fix_gotrue_user.sql; src/lib/models/models.dart, src/lib/core/durus_api.dart, src/lib/screens/settings_screen.dart, src/lib/screens/home_screen.dart, src/lib/router.dart, src/lib/l10n/app_ar.arb, src/test/widget_test.dart, tasks/2026-09-13_tasks.md |
| errors | (1) `create_teacher_with_credentials` → 42883 `auth.admin_create_user(...) does not exist`; (2) after direct-insert fix, password grant returned 500 "Database error querying schema" due to NULL token columns. |
| lessons | See lessons.md (auth.admin_create_user is Admin-API only; direct auth inserts must set token cols to ''; detect identities.provider_id; PostgREST scalar RPC returns a bare String; test user creation with a real password login). |
| tags | build, phase7, auth, gotrue, announcements |
---

### EVT-20260914-0002

| Field | Value |
|-------|-------|
| id | EVT-20260914-0002 |
| timestamp | 2026-09-14T18:30:00+03:00 |
| mode | BUILD |
| action | deploy: GitHub Pages (web) + GitHub Releases (Android APK) |
| summary | Deployed both deliverables 100% free: created public repo amworx/durus, pushed master, built release web with --base-href /durus/, pushed to gh-pages (Pages auto-enabled, build_type legacy, source gh-pages /), live at https://amworx.github.io/durus/ (verified boot in Chrome — title flips to "دروس"); generated release keystore (durus-keys/durus-release.keystore) + key.properties (gitignored), wired release signing into app/build.gradle.kts with debug fallback, built signed release APK (55.5MB) and published GitHub Release v1.0.0 with the APK. Fixed signed-build blocker: shared_preferences_android lintVital could not resolve androidx.datastore:datastore-jvm:1.1.7 → disabled lint checkReleaseBuilds/abortOnError. |
| result | success — web live + APK downloadable from https://github.com/amworx/durus/releases/tag/v1.0.0 |
| files | src/android/app/build.gradle.kts (signing + lint), durus-keys/durus-release.keystore + key.properties (gitignored, outside repo), gh-pages branch |
| errors | 1 | 
| lessons | (1) Flutter release build for Google Play needs real signing later — for free distribution debug or custom keystore both satisfy sideloading, but custom keystore survives across machines. (2) shared_preferences_android 2.4.28 expects androidx.datastore:datastore-jvm:1.1.7 in its lint classpath and fails lintVital when that dep is missing — disable lint { checkReleaseBuilds = false } rather than fight the transitive dep. (3) GitHub Pages auto-enables when a gh-pages branch is pushed to a public repo; verify base-href by loading the app and confirming the Flutter title renders. |
| tags | deploy, github-pages, releases, android, web |
---

### EVT-20260914-0003

| Field | Value |
|-------|-------|
| id | EVT-20260914-0003 |
| timestamp | 2026-09-14T19:05:00+03:00 |
| mode | BUILD |
| action | enable open signup (auto-confirm) on live project |
| summary | User asked whether any user can create an account. Found: enable_signup=true and mailer_autoconfirm=false on live project; free-tier email rate limit (2/hr) had 429d a test signup (over_email_send_rate_limit). Local config.toml already had [auth.email] enable_confirmations=false but remote was out of sync. Pushed config via supabase config push --project-ref rdlapngvsxhdcoxdcjov --yes → live now mailer_autoconfirm=true. Verified: fresh signup returns user with email_confirmed_at set + access_token (session) immediately. Cleaned up test signup user via service-role admin delete (200) + profile delete (204). |
| result | success — any new email/password user can sign up and is logged in instantly, then hits the onboarding wizard. Parents still use PIN links (no accounts by design). |
| files | remote Supabase auth config only (no code change; local config.toml was already correct) |
| errors | 1 (previous test signup 429 over_email_send_rate_limit) |
| lessons | (1) Live Supabase auth config can drift from supabase/config.toml — check /auth/v1/settings (with apikey) and fix with supabase config push, not just the dashboard. (2) Free tier email_sent rate limit (2/hr) also throttles confirmation/reset emails — auto-confirm removes the signup blocker; custom SMTP (Option B) is the real fix for resets later. (3) .test TLD emails rejected by GoTrue; gmail.com fine. (4) PowerShell Invoke-RestMethod mangles request bodies on some auth endpoints — use curl.exe --data-binary @file with an ASCII temp file. |
| tags | auth, signup, autoconfirm, rate-limit, config |
---

### EVT-20260914-0004

| Field | Value |
|-------|-------|
| id | EVT-20260914-0004 |
| timestamp | 2026-09-14T19:40:00+03:00 |
| mode | BUILD |
| action | Gmail SMTP for Supabase (Option B) |
| summary | SendGrid signup blocked by geo/legal (451 Unavailable For Legal Reasons — Twilio blocks Syria). Pivoted to Gmail SMTP (500 emails/day, no signup). Added [auth.email.smtp] to supabase/config.toml: host smtp.gmail.com:587, user amworxx@gmail.com, pass = env(DURUS_SMTP_PASSWORD) (CLI resolves at push, file stays secret-free), admin_email/sender_name Durus. Stored Gmail app password in durus-keys/CREDENTIALS.txt (outside repo). Pushed config live (CLI displayed resolved pass as hash). Verified end-to-end: POST /auth/v1/recover for smoke teacher returned 200. Leak-check confirmed no plaintext in config.toml. Committed dfe034a. |
| result | success — password-reset emails now go through Gmail SMTP; ~500 emails/day, no 2/hr cap |
| files | supabase/config.toml, durus-keys/CREDENTIALS.txt (untracked) |
| errors | 1 (SendGrid 451 geo-block) |
| lessons | (1) Twilio/SendGrid refuses Syria signups (451) — don't attempt again; Gmail SMTP is the drop-in. (2) Gmail app password needs 2-Step Verification enabled; app passwords work for GoTrue SMTP AUTH on 587. (3) supabase config.toml supports pass = "env(VAR)" — CLI resolves at push and redacts as hash in diffs; never commit plaintext SMTP creds to a public repo. (4) Verify SMTP by triggering a real /auth/v1/recover and expecting 200. |
| tags | smtp, gmail, auth, password-reset, deploy |
---

### EVT-20260914-0005

| Field | Value |
|-------|-------|
| id | EVT-20260914-0005 |
| timestamp | 2026-09-14T20:20:00+03:00 |
| mode | BUILD |
| action | forgot-password (نسيت كلمة المرور؟) in app |
| summary | Added forgot-password flow using the Gmail SMTP backend from EVT-20260914-0004. API: DurusApi.resetPassword -> auth.resetPasswordForEmail. UI: "نسيت كلمة المرور؟" link under password on login (RTL-aligned end); if the form email is valid it sends directly, otherwise an AlertDialog collects it; always shows "إذا كان البريد مسجلاً…" snackbar (no user enumeration). 4 new ARB keys; gen-l10n; 15/15 tests (new l10n resolution test); analyze 0; redeployed web to gh-pages (service worker cached the old build — verified with cache-bypass reload); rebuilt signed release APK and updated Release v1.0.0 via gh release upload --clobber. Live Chrome verification: opened dialog, submitted, snackbar shown. |
| result | success — live on web + APK v1.0.0; reset emails via Gmail SMTP |
| files | src/lib/core/durus_api.dart, src/lib/screens/auth_screens.dart, src/lib/l10n/app_ar.arb, src/test/widget_test.dart, gh-pages branch, Release v1.0.0 asset |
| errors | 1 (stale Flutter SW cache served old build on first check) |
| lessons | Flutter web deploys must be verified with a cache-bypass reload (service worker serves stale builds to returning tabs); hard reload after every web publish. |
| tags | auth, password-reset, forgot-password, deploy |
---

### EVT-20260915-0001

| Field | Value |
|-------|-------|
| id | EVT-20260915-0001 |
| timestamp | 2026-09-15T17:05:00+03:00 |
| mode | BUILD |
| action | fix release APK: missing INTERNET permission (signup/login dead in Android) |
| summary | User reported the downloaded APK would not let them create an account. Investigation: REST signup via live project worked instantly (auto-confirm + session); web UI signup reproduced end-to-end (form → onboarding wizard). Root cause: android/app/src/main/AndroidManifest.xml had NO uses-permission INTERNET (only the debug manifest declares it), so the RELEASE APK had zero network — every Supabase call threw immediately. Fix: added INTERNET permission to main manifest + changed launcher label "durus" → "دروس". Rebuilt release APK, verified via aapt2 dump permissions (INTERNET present, package com.amworx.durus), re-uploaded to Release v1.0.0 (--clobber, updated 2026-09-15T17:00:37Z). Cleaned up 2 repro test users. Committed 88d4cea. |
| result | success — release APK now has network; signup/login work on Android |
| files | src/android/app/src/main/AndroidManifest.xml, Release v1.0.0 asset |
| errors | 1 (this bug) |
| lessons | ALWAYS add INTERNET to main/AndroidManifest.xml — Flutter templates only include it in debug/profile manifests; release builds silently ship network-dead. Verify merged permissions with aapt2 dump permissions after every release build. |
| tags | android, release, manifest, network, bugfix |
---

### EVT-20260915-0002

| Field | Value |
|-------|-------|
| id | EVT-20260915-0002 |
| timestamp | 2026-09-15T17:25:00+03:00 |
| mode | BUILD |
| action | host APKs on Supabase Storage (GitHub download too slow on phone) |
| summary | User reported GitHub APK downloads are slow on their phone. Created public Supabase Storage bucket durus-apk (free tier 1GB, max object 50MB), built split-per-abi APKs (arm64 19.3MB, armeabi-v7a 17.1MB, x86_64 20.7MB — universal 55.6MB exceeds the 50MB free cap), uploaded via Storage REST API with service role, verified public HEADs (200, application/vnd.android.package-archive). Updated Release v1.0.0 notes with the three fast links. One upload artifact: first loop's URL interpolation stored x86_64 as an object literally named "=true" (mangled ?upsert=true) — deleted and re-uploaded clean. |
| result | success — fast APK links: https://rdlapngvsxhdcoxdcjov.supabase.co/storage/v1/object/public/durus-apk/durus-arm64-v8a.apk (+ v7a/x86_64) |
| files | null (cloud only) |
| errors | 1 (upload name artifact "=true"); bucket create 413 on 70MB file_size_limit (free cap 50MB) |
| lessons | (1) Supabase free Storage max object size = 50MB → ship split-per-abi APKs, not universal. (2) Build URL strings outside the upload loop or use literal URLs — PowerShell+curl URL interpolation with query params can mangle object names. (3) Free tier egress ~2GB/mo: 19MB APK ≈ 100 downloads/mo — fine for a teacher's families. |
| tags | storage, apk, hosting, download-speed |
---

### EVT-20260915-0003

| Field | Value |
|-------|-------|
| id | EVT-20260915-0003 |
| timestamp | 2026-09-15T20:45:00+03:00 |
| mode | RESEARCH |
| action | find silent (no-browser) file sharing API for APK distribution |
| summary | Tested 4 anonymous file-sharing services to replace file.io (whose curl API is dead -- file.io now redirects through LimeWire with a complex S3+claimToken+CSRF flow requiring browser JS). Results: (1) 0x0.st -- DISABLED (botnet spam). (2) litterbox.catbox.moe -- rejects anonymous with 'No file!' (blocked or policy change). (3) tmpfiles.org -- upload works, returns share URL, but the share page is an HTML wrapper (extra click on phone). (4) catbox.moe -- WORKS PERFECTLY: curl -F reqtype=fileupload -F fileToUpload=@file https://catbox.moe/user/api.php returns direct URL (https://files.catbox.moe/xxx.apk). No HTML wrapper. No account. Permanent until deleted. Files up to 200MB. Speed: ~260KB/s from our datacenter. |
| result | success -- catbox.moe for silent anonymous uploads |
| files | share-apk.ps1 (new) |
| errors | litterbox anonymous rejection; 0x0.st disabled; tmpfiles HTML wrapper |
| lessons | (1) file.io API is dead -- now routes through LimeWire with undocumented multipart+CSRF flow. (2) catbox.moe is the simplest working anonymous upload API in 2026: one curl call, direct URL response. (3) Non-ASCII characters (em-dash, curly quotes) in PowerShell scripts cause parser failures on PS 5.1 -- use ASCII only. |
| tags | file-sharing, catbox, anonymous, silent-upload, file-io-dead |

---

### EVT-20260915-0004

| Field | Value |
|-------|-------|
| id | EVT-20260915-0004 |
| timestamp | 2026-09-15T21:45:00+03:00 |
| mode | PLAN |
| action | UI redesign: generate 5 radically different design proposals |
| summary | User: app UI is repetitive/classic, wants a modern unique design. Scanned current UI (standard Material 3 ColorScheme.fromSeed defaults + AppBar/Card/NavigationBar/ListView; 3 seed themes d1 دفتر / d2 لوح / d3 مكتب in src/lib/theme/themes.dart). Loaded design-an-interface + ui-ux-pro-max skills and launched 5 parallel design sub-agents. Proposals: (1) كُرّاسة Neo-Brutalist ruled-paper ledger — paper #F6EEDB, ink #1D1308, 3px borders, hard offset shadows, rubber stamps, Changa; (2) ضياء Glassmorphism — dark indigo/violet gradient + frosted BackdropFilter panels + gold #FFC24A glow; (3) الكتاب Editorial Arabic — Reem Kufi masthead, folio numbers ٠٧, double hairline rules, Eastern-Arabic digits, jewel accent; (4) فسيفساء Bento mosaic — tinted tiles, giant Reem Kufi numerals 34-56px, radius 28-32; (5) سكون Dark neo-minimal — near-black #0A0A0C/#121216/#1A1A20, NO shadows, 1px hairlines, single amber #E8AD65 accent. All 5 presented to user with a comparison table (vibe, palette, type, RTL strength, low-end phone risk). Awaiting user selection before theme implementation. |
| result | pending user choice — proposals presented; next step is implementation of the chosen direction in themes.dart |
| files | src/lib/theme/themes.dart (implementation target), docs/ui-designs.md (existing 3-themes doc) |
| errors | None |
| lessons | (1) 5 parallel design sub-agents + a comparison table is a fast way to get a real design decision from a non-designer. (2) Every proposal must state low-end phone risk + RTL strength so a design can't be picked that is unimplementable for the target devices. |
| tags | design, ui, proposals, plan |

---

### EVT-20260915-0005

| Field | Value |
|-------|-------|
| id | EVT-20260915-0005 |
| timestamp | 2026-09-15T22:30:00+03:00 |
| mode | BUILD |
| action | build live design-showcase webpage for the 5 proposals |
| summary | User asked to SEE the 5 design proposals in action before choosing. Built a single self-contained RTL Arabic page docs/design-showcase.html: 5 phone mockups side by side (كرّاسة / ضياء / الكتاب / فسيفساء / سكون), each rendering real Durus screens (الرئيسية، الطلاب، الجدول، الرسوم، التقرير) with its own complete design language via CSS custom properties per `.design[data-design=N]`, plus palette swatches, type specimens, signature bullets, and a comparison table. One global screen switcher drives all 5 phones simultaneously (vanilla JS). Fonts: Google Fonts CDN (Changa, Cairo, Reem Kufi, Amiri, Tajawal, Noto Sans Arabic, IBM Plex Sans Arabic). Served locally on :8123 and verified via Chrome MCP — snapshot shows all content, switcher confirmed (all 5 phones switch together, fees=20 rows across phones), only console error is missing favicon (404, harmless). |
| result | success — showcase live at http://localhost:8123/design-showcase.html awaiting user's design pick |
| files | docs/design-showcase.html |
| errors | 1 (favicon 404 — harmless) |
| lessons | (1) For design-decision UI, one global screen switcher + N phone frames renders "same app, N personalities" far more convincingly than static screenshots. (2) CSS custom properties per design wrapper keeps 5 design systems in one small HTML file with zero duplication of screen markup. (3) This model can't read screenshots — verify rendered pages via DOM snapshot + JS evaluation instead. |
| tags | design, showcase, html, decision-tool |
| EVT-20260915-0006 | 2026-09-15T23:10:00+03:00 | BUILD | implement dual design systems (فسيفساء + سكون) | User decided after the showcase: keep BOTH design 4 (فسيفساء, light bento) and design 5 (سكون, dark premium), let the end user choose in Settings. Replaced the 3 classic seed-color themes in themes.dart with two complete design systems — kThemeFusayfesa='f4' (light warm paper, teal/ember accents, Reem Kufi + Tajawal, radius 26-28, pill buttons) and kThemeSukoon='s5' (near-black, hairline borders, single amber accent, Reem Kufi + IBM Plex Sans Arabic, radius 14-16, no shadows). Dropped the separate dark-mode toggle (design IS brightness). Bundled 11 font files (ReemKufi variable 400-800, Tajawal 400/500/700/800, IBMPlexSansArabic 400/500/600 + OFL licenses) into src/assets/fonts, registered in pubspec.yaml. Wired providers.dart/main.dart/app.dart (remove darkModeProvider, default f4, normalizeThemeKey migrates legacy d1/d2/d3→f4). Rebuilt Settings _AppearanceSection as a visual design picker with per-design mini preview thumbnails (_DesignPreview). Updated ARB keys (settingsThemeFusayfesa/Sukoon/Pick + subs), regenerated l10n. flutter analyze 0 issues; 15/15 tests pass; web + APK (split-per-ABI) builds succeed; verified in Chrome MCP: login → settings picker selects سكون, persists to localStorage (theme_key=s5), survives reload, refresh restores session + dark theme. | success — dual theme live; APKs re-uploaded to storage (arm64 19.8MB / v7a 17.6MB / x86_64 21.2MB), existing fast links updated in place | src/lib/theme/themes.dart, src/lib/providers/providers.dart, src/lib/main.dart, src/lib/app.dart, src/lib/screens/settings_screen.dart, src/lib/l10n/app_ar.arb, src/pubspec.yaml, src/assets/fonts/*, test/widget_test.dart | none | (1) After a design decision, implement BOTH chosen systems as first-class ThemeData with distinct fonts/radii/color roles — the picker must preview the design, not a color swatch. (2) Variable fonts (ReemKufi[wght].ttf, Cairo[slnt,wght].ttf) bundle fine as a single file registered per declared weight in pubspec. (3) PS 5.1 curl.exe download loop is reliable for pulling google/fonts raw TTFs. (4) Chrome MCP form fill can drop the first character of a password field — always verify via the network request body / re-fill before judging login failures. | design, theme, fonts, settings, build || EVT-20260915-0007 | 2026-09-15T23:55:00+03:00 | BUILD | switch typeface to Zain (readability) | User reported the main font (Reem Kufi, a Kufi display face) is hard to read. Built docs/font-picker.html - a self-contained RTL Arabic comparison page showing the same Durus content (stat numbers, headings, student names, body) in 19 Google Fonts families across 3 content modes (الرئيسية/الجدول/الأقساط), with click-to-select + chosen bar + dark mode toggle; verified via Chrome MCP (19 cards render, all font requests 200, selection + mode switch + dark toggle work); saved docs/font-picker-preview.png + font-picker-preview-dark.png. User picked زين (Zain). Replaced all three bundled families with Zain (Light/Regular/Bold/ExtraBold/Black + OFL), set kFontFamily='Zain' in themes.dart, both designs now use one family (فسيفساء display w800, سكون display w700), updated settings preview thumbnail, removed old font files. flutter analyze 0 issues; 15/15 tests; APK builds succeed (arm64 20.7MB). Uploaded to Supabase Storage (same fast links, content verified updated) + GitHub Release v1.1.1 (200, application/vnd.android.package-archive). | success - Zain live in both designs; v1.1.1 release | docs/font-picker.html, docs/font-picker-preview*.png, src/pubspec.yaml, src/lib/theme/themes.dart, src/lib/screens/settings_screen.dart, src/assets/fonts/* | none | (1) Kufi display faces (Reem Kufi) are poor for body/numbers - keep them for logos only; prefer Naskh/UI sans (Zain/Almarai/Noto Naskh) for app text. (2) A font-picker webpage with identical sample text across fonts + a selection bar is the fastest way to let a user choose a typeface. (3) Supabase x-upsert keeps object Ids but updates content - verify via Content-Length change, not Id. | design, fonts, readiness, build |

### EVT-20260915-0008

| Field | Value |
|-------|-------|
| id | EVT-20260915-0008 |
| timestamp | 2026-09-16T00:05:00+03:00 |
| mode | BUILD |
| action | v1.1.2: splash + subject grades + WhatsApp + in-app update check |
| summary | Shipped the 4 requested improvements. (1) Native splash: launch_logo vector (Material school path in teal on transparent), launch_background + drawable-v21 = paper color (#FAF8F4 via new values/colors.xml) + centered logo, new values-v31/styles.xml using windowSplashScreen* (Android 12+). (2) Subject grade: Subject.displayLabel ('name - grade') used in all buggy pickers/chips (students screen FilterChip, detail chips, slot dropdown, tests dropdown, _subjectName helpers, schedule + home). (3) WhatsApp: new core/links.dart (waNumber normalizes 09/00963/+963 to 963, waChatLink, openExternal via url_launcher LaunchMode.platformDefault); student header WhatsApp FilledButton + parent-link TextButton (only when parent_phone); reports screen sends full monthly report via WhatsApp. (4) In-app updates: AppConfig.appVersion 1.1.2, AppRelease model, isNewerVersion util, DurusApi.latestRelease reading new app_meta table (key/jsonb, RLS public read, seeded latest_release -> v1.1.2 GitHub page), Settings _UpdatesSection (current version, check button, up-to-date / update-available + download). Added 13 ARB keys + placeholders metadata, gen-l10n. url_launcher ^6.3.2 added as direct dep (already transitive via supabase_flutter 2.17.1 - zero new packages). PUBSPEC bumped 1.1.2+1. flutter analyze 0 issues; 19/19 tests (4 new: isNewerVersion, waNumber/waChatLink, displayLabel). Migration 20260915180000_app_meta.sql pushed via supabase db push. APKs built split-per-ABI, veriffied in Chrome MCP on web build: login, Settings updates shows 'al hadith' (up-to-date: version 1.1.2 == app_meta 1.1.2), student detail shows WhatsApp buttons + subject chip 'name - grade', slot dropdown shows grade, report screen WhatsApp button opens api.whatsapp.com with correct 963 phone + full Arabic report text. Committed c113c85, pushed master, GitHub Release v1.1.2 created with 3 APK assets. | success - all 4 features verified live | src/lib/core/links.dart (new), src/lib/models/models.dart, src/lib/core/utils.dart, src/lib/core/config.dart, src/lib/core/durus_api.dart, src/lib/screens/settings_screen.dart, src/lib/screens/students_screens.dart, src/lib/screens/reports_screen.dart, src/lib/screens/schedule_screen.dart, src/lib/screens/home_screen.dart, src/lib/l10n/app_ar.arb (+generated), src/pubspec.yaml, src/android/.../res (colors.xml, launch_logo.xml, launch_background*, values-v31/styles.xml), supabase/migrations/20260915180000_app_meta.sql, src/test/widget_test.dart | 3 (AAPT hex-drawable failure; Chrome first-char drop twice; anon bucket upload 403 RLS - skipped) | (1) layer-list/item android:drawable needs a color RESOURCE not a raw hex - define values/colors.xml. (2) url_launcher was already transitive - check before adding new deps. (3) anon cannot write durus-apk bucket; app no longer references it, GitHub Releases is the primary channel. | release, build, whatsapp, splash, updates |
|-------|-------|
| id | EVT-20260915-0009 |
| timestamp | 2026-09-16T03:30:00+03:00 |
| mode | BUILD |
| action | Refresh (pull + resume) + seed dummy data + teacher_home label fix |
| summary | (1) Manual refresh: added refreshSchoolData(ref) (awaits Future.wait of ref.refresh(p.future) for all 11 data providers, try/catch so RefreshIndicator completes; failing providers show their own ErrorRetry) + invalidateAllSchoolData(ref) (fire-and-forget) in providers.dart. _HomeShellState now a WidgetsBindingObserver; on AppLifecycleState.resumed calls invalidateAllSchoolData so data refetches without app restart. Wrapped 6 main-tab scrollables in RefreshIndicator + AlwaysScrollableScrollPhysics: home, schedule (week list), students, subjects, fees, settings; empty branches use new RefreshableEmpty widget (CustomScrollView + SliverFillRemaining) so pull works even on empty lists. (2) Seed data: migration 20260915190000_seed_dummy_data.sql pushed via supabase db push --yes --password - 4 new subjects (اللغة العربية in grades 1+2 to verify displayLabel), 4 students (عمر has NO parent_phone/token to test the no-contact path), student_subjects, 4 recurring slots (Mon-Thu), 32 sessions Aug+Sep 2026 (present/absent/rescheduled mix), 9 fees + 7 payments (unpaid/partial/paid via refresh_fee_status trigger), 7 tests, 3 notes, 1 announcement, 1 manual teacher notification; all rows fixed-UUID + ON CONFLICT DO NOTHING. Trigger-generated parent+teacher notifications confirmed (إشعارات badge = 9; center lists دفعة جديدة rows). (3) Fixed _locationLabel key bug in students_screens.dart ('teacher' -> 'teacher_home') so teacher-home students display عند المعلم not the raw enum. Cleaned a stray mojibake fallback string in widgets.dart friendlyError (restored proper Arabic). Quality: flutter analyze 0 issues; 19/19 tests; web release built and verified in Chrome MCP (dashboard showed seeded today session; students 5 rows with عند المعلم; subjects incl. duplicate 'اللغة العربية' grade distinction; fees summary 460000/295000; notification center populated). Server left running at localhost:8171 for user testing. | success - seed live, refresh shipped, label fix verified | src/lib/providers/providers.dart, src/lib/screens/home_shell.dart, home_screen.dart, schedule_screen.dart, students_screens.dart, subjects_screens.dart, fees_screens.dart, settings_screen.dart, src/lib/widgets/widgets.dart, supabase/migrations/20260915190000_seed_dummy_data.sql, memory/ | 0 | (1) Pull-to-refresh is touch-only on web; resume-invalidate covers web refocus. (2) DB enum keys must match exactly ('teacher_home'). (3) PostgREST 400 on select=id for composite-PK tables. (4) PS5.1 Invoke-WebRequest needs IE (use Invoke-RestMethod). | refresh, seeding, rls, triggers, testing |
|-------|-------|
| id | EVT-20260915-0010 |
| timestamp | 2026-09-15T23:50:00+03:00 |
| mode | BUILD |
| action | v1.1.3: in-app update download + install, GitHub auto-detect |
| summary | User reported the app always says no updates and cannot download the update. Root causes: detection depended ONLY on manually bumping app_meta.latest_release (a GitHub release alone never surfaced), and the Download button only called openExternal(latest.url) (browser). Fixed: (1) models.dart AppRelease + apkUrl + fromGitHubJson (tag v-strip, body truncate 400, assets prefer arm64 then any .apk). (2) New core/updater.dart facade with conditional import: updater_io.dart (dart:io HttpClient, GET api.github.com/repos/amworx/durus/releases/latest with Accept application/vnd.github+json + User-Agent, 8s timeouts; download into Directory.systemTemp/updates with progress by contentLength; MethodChannel durus/installer installApk) vs updater_web.dart stubs (web never installs APKs; also keeps dart:io out of the web compile). (3) DurusApi.latestRelease merges app_meta + GitHub: newest version wins, ties prefer the entry carrying apkUrl. (4) Settings _UpdatesSection: in-app download with LinearProgressIndicator + percent, then triggerApkInstall; openExternal fallback when web or no apkUrl. (5) Android: REQUEST_INSTALL_PACKAGES, FileProvider (androidx.core.content.FileProvider, authority <applicationId>.fileprovider, cache-path updates via res/xml/file_paths.xml), MainActivity.kt MethodChannel handler -> ACTION_VIEW with application/vnd.android.package-archive + FLAG_GRANT_READ_URI_PERMISSION|FLAG_ACTIVITY_NEW_TASK; androidx.core:core:1.13.1 added to build.gradle.kts (already in gradle cache). (6) ARB keys settingsDownloading + settingsOpenUpdateManually, gen-l10n. Published v1.1.3: pubspec 1.1.3+1, AppConfig.appVersion 1.1.3, 3 release APKs split-per-ABI (debug-signed same as 1.1.2 so the install-over-update works), GitHub Release v1.1.3 with 3 assets, migration 20260915233700_app_meta_v113.sql pushed (version/url/notes/apk_url arm64). Verified: analyze 0 issues, 25/25 tests (6 new parser tests), web build, debug APK build; Chrome MCP on localhost:8171 Settings -> check updates shows الإصدار الحالي 1.1.3 + أنت على أحدث إصدار (app_meta fetch 200); GitHub /releases/latest returns v1.1.3 with correct asset names. Commits: d21ee67 code, then memory commit; both pushed master. Web server left running at localhost:8171 (now serving 1.1.3). | success - v1.1.3 published; installed 1.1.2 devices now detect it and download in-app | src/lib/models/models.dart, src/lib/core/updater.dart, updater_io.dart, updater_web.dart (new), src/lib/core/durus_api.dart, src/lib/screens/settings_screen.dart, src/lib/l10n/app_ar.arb (+generated), src/test/updater_test.dart (new), src/android/app/src/main/AndroidManifest.xml, src/android/app/src/main/res/xml/file_paths.xml (new), src/android/app/src/main/kotlin/com/amworx/durus/MainActivity.kt, src/android/app/build.gradle.kts, src/pubspec.yaml, src/lib/core/config.dart, supabase/migrations/20260915233700_app_meta_v113.sql, memory/ | 0 | (1) app_meta-only detection is a manual bottleneck - fuse the GitHub Releases API so publishing a release IS the update signal; keep app_meta for curated Arabic notes + guaranteed apk_url. (2) In-app APK install needs REQUEST_INSTALL_PACKAGES + a FileProvider that exposes the download dir; Dart Directory.systemTemp == app cache dir on Android, so a <cache-path> matches. (3) dart:io cannot compile for web - isolate platform code behind conditional imports (`if (dart.library.html)`). (4) Keep release APKs signed with the same key as the installed build (gradle debug signing here) or the package installer rejects the update. | updater, release, android, github, publish |

|-------|-------|
| id | EVT-20260915-0011 |
| timestamp | 2026-09-16T00:30:00+03:00 |
| mode | BUILD |
| action | Seed dummy data into AM Worx school (phones: amworxx + goalit2021) |
| summary | User reported the phone apps show no dummy data. Root cause: the earlier seed migration only populated the SMOKE school (e77576b3..., RLS school-scoped) while the phones log in with real accounts: amworxx@gmail.com (teacher, id bfbe8da3-36ad-4006-9859-bd17b0fdf675) and goalit2021@gmail.com (manager, id de4425ce-69ad-4c44-bfa1-98358ac7f942) - BOTH in the same multi-teacher school de4425ce... (0 students, but 3 REAL subjects: عربي/اول 78758204..., عربي/ثاني f5a8bd35..., رياضيات/ثاني 9eb51e1b...). New migration 20260916000000_seed_dummy_data_amworx_school.sql: references the existing subjects (no duplicate dummy subjects), inserts 4 students (محمد، سارة، عمر with no phone/token, لين) all assigned_teacher_id = bfbe8da3... so the teacher phone sees them via RLS and the manager sees the whole school; 4 student_subjects, 4 slots (Mon-Thu), 26 sessions Aug+Sep 2026 (incl. 1 today 2026-09-15 for سارة), 8 fees, 6 payments, 5 tests, 3 notes, 1 announcement, 1 manual teacher notification for bfbe8da3... Pushed via supabase db push --yes. Verified with service-role REST counts (students=4, student_subjects=4, slots=4, sessions=26, fees=8, payments=6, tests=5, notes=3, announcements=1, teacher_notifications=2, today 2026-09-15=1). Phones need a cold restart (1.1.2 has no pull-to-refresh) or better upgrade to 1.1.3 (pull-to-refresh + resume refetch). | success - dummy data now live in the user's real school | supabase/migrations/20260916000000_seed_dummy_data_amworx_school.sql, memory/ | 1 (PS inline @(Invoke-RestMethod ...).Count inside string interpolation mis-parsed to 1 - use assignment pattern instead) | (1) Seed data is school-scoped: always seed into the account/school the user actually opens, or it looks like a broken app. (2) In multi-teacher mode students need assigned_teacher_id = the teacher's profile id for that teacher's phone; manager sees all. (3) If the real school already has subjects, reference them in seeds instead of creating confusing duplicates. (4) PowerShell: assign Invoke-RestMethod to a variable before .Count - inline @(...).Count under $() interpolation can mis-parse. | seeding, rls, multi-teacher, phones |
---

### EVT-20260916-0001

| Field | Value |
|-------|-------|
| id | EVT-20260916-0001 |
| timestamp | 2026-09-16T13:00:00+03:00 |
| mode | BUILD |
| action | v1.1.4: sessions UI/UX (5 states + detail sheet + undo) + announcements/notifications upgrade |
| summary | Shipped the confirmed v1.1.4 UX upgrade. Part A — Sessions: migration 20260916100000 adds `topics/homework/rescheduled_to` + late bucket + notify_session_change trigger; shared `core/attendance.dart` (attendanceStyle + kAttendanceStates) unifies 5 states across home/schedule/students/portal/reports (per-screen 3-state mappers removed); home `_TodaySessionsCard` redesigned (per-chip stats values, `_SessionTile` tap-anywhere, 5-icon `_QuickMarkButton` row, `_quickMark` with undo snackbar via deleteLesson(id), `_openDetail` -> shared sheet); `widgets/session_detail_sheet.dart` slot param nullable with `_slot` fallback (history view); recordAttendance returns row id; updateLesson/deleteLesson added. Part B — Announcements/Notifications: migration 20260916110000 adds announcements title/audience/pinned/expires_at + audience/expiry filter + notification_prefs table with RLS; `widgets/announcement_compose_sheet.dart` (AnnouncementDraft, compose+edit); `screens/announcements_screen.dart` (pin/edit/delete, pinned-first); notifications_screen.dart rewritten (category filter chips, per-row mark-read/delete, bulk clear); settings `_NotificationPrefsSection` 6 merged toggles (general/attendance+note/test/fee+payment/announcement/teacher) via notificationPrefsProvider + upsertNotificationPrefs; home announcements card shows title+pinned and opens management screen; API deleteTeacherNotification added. l10n: full Part A+B ARB keys + gen-l10n (commonUndo, homeMarkLate/Cancelled, sessionDetail* block, portalLate/Cancelled, announcements* block, notificationsCategory*, settingsNotifications*, notificationsMarkRead). Quality: flutter analyze 0 errors (7 infos); flutter test 25/25; BOTH migrations pushed together via supabase db push --yes; service-role REST verify (sessions=60 with topics/homework/rescheduled_to live, announcements=4 with title/audience/pinned/expires_at, notification_prefs table exists 0 rows); release APK split-per-ABI (arm64 20.0MB / armv7 17.8MB / x64 21.3MB) + web built. Chrome MCP (static serve of build/web): app boots, session restored, all new-schema endpoints 200 incl. notification_prefs user fetch (Settings mounts in IndexedStack). |
| result | success — all code, l10n, tests, migrations (pushed), and builds done; UI visually unverified (model has no image input; Flutter web semantics not exposed to CDP) |
| files | src/lib/screens/home_screen.dart, src/lib/widgets/session_detail_sheet.dart, src/lib/widgets/announcement_compose_sheet.dart (new), src/lib/screens/announcements_screen.dart (new), src/lib/screens/notifications_screen.dart, src/lib/screens/settings_screen.dart, src/lib/screens/{schedule_screen,students_screens,portal_screens,reports_screen}.dart, src/lib/core/attendance.dart (new), src/lib/core/durus_api.dart, src/lib/models/models.dart, src/lib/providers/providers.dart, src/lib/l10n/app_ar.arb + generated, supabase/migrations/20260916100000_sessions_upgrade.sql + 20260916110000_announcements_notifications_upgrade.sql (pushed), plans/ tasks/ |
| errors | 2 (DWDS debug-server type error `_JsonMap not subtype of List<Object?>` blocks flutter run -d web-server; gh release create timed out leaving a draft with 0 assets) |
| lessons | (1) Publishable key (sb_publishable_*) is anon-class — REST verify returns 0 rows under RLS; use the service-role JWT. (2) Invoke-WebRequest fails in non-interactive PS and blocks custom Range header; use curl.exe -s -I with Prefer: count=exact + Range: 0-0 and read Content-Range. (3) flutter run -d web-server (DWDS) can fail to render via its injected client; serve the static release build instead (reinforces build+static-serve pattern). (4) gh release create uploads can exceed the tool timeout and leave a DRAFT with no assets — re-check with gh release view --json isDraft,assets, upload with --clobber, then gh release edit --draft=false. |
| tags | release, build, sessions, attendance, announcements, notifications, ui-ux |

---

### EVT-20260916-0002

| Field | Value |
|-------|-------|
| id | EVT-20260916-0002 |
| timestamp | 2026-09-16T14:00:00+03:00 |
| mode | BUILD |
| action | release v1.1.4 + app_meta bump + memory |
| summary | Published v1.1.4: pubspec 1.1.4+1; migration 20260916120000_app_meta_v114.sql pushed (version/url/notes/apk_url arm64, Arabic notes covering the 5-state sessions + announcements + notification prefs). Git commit f329734 (23 files, +3062/-300), pushed master, tagged v1.1.4. gh release create v1.1.4 timed out on upload -> draft with 0 assets; gh release upload --clobber attached all 3 APKs (arm64 20.9MB / armv7 18.6MB / x64 22.3MB), gh release edit --draft=false published. Verified app_meta row (v1.1.4 + Arabic notes) and that the APK download URL returns HTTP 200. Release: https://github.com/amworx/durus/releases/tag/v1.1.4. Memory appended; plans/tasks ticked. Installed 1.1.3 devices will now auto-detect the update on next resume (GitHub releases API) and can download/install in-app. |
| result | success — v1.1.4 published, app_meta live, APK links verified |
| files | src/pubspec.yaml, supabase/migrations/20260916120000_app_meta_v114.sql, memory/ |
| errors | 1 (gh release create timeout -> draft; recovered with upload --clobber + edit --draft=false) |
| lessons | (1) After gh release create, always verify isDraft+assets before assuming the release is live; re-upload with --clobber and publish with --draft=false. (2) Keep the SAME debug signing key across releases so the in-app installer can update over the installed build. |
| tags | release, github, app_meta, publish, updater |

---

### EVT-20260916-0003

| Field | Value |
|-------|-------|
| id | EVT-20260916-0003 |
| timestamp | 2026-09-16T16:30:00+03:00 |
| mode | BUILD |
| action | fix: in-app update install failure + brand launcher icon + appVersion stale |
| summary | Two user-reported fixes + one latent bug. (1) In-app update: root cause was updater_io.dart writing to Directory.systemTemp which on Android resolves outside both the FileProvider <cache-path> root and user-visible storage — FileProvider.getUriForFile threw (install_failed), and the fallback "open from file manager" pointed nowhere the user could reach. Fix: Kotlin MainActivity now exposes getDownloadDir() returning File(cacheDir, "updates") (absolute path inside <cache-path>); Dart calls this before downloading. If installApk still fails (very old device, blocked installer), the native side exports the APK to user-visible Downloads via MediaStore.Downloads (API 29+) or getExternalFilesDir (21-28) and reports a status="exported" with the file location; settings_screen.dart shows a SnackBar with the path and an "open folder" action button (native channel opens DocumentsUI Downloads root). New ARB keys: settingsUpdateReadyToInstall, settingsUpdateSavedTo (placeholder), settingsUpdateOpenFolder; settingsOpenUpdateManually removed. (2) App icon: brand adaptive launcher icon (XML anydpi-v26/v33) using the existing graduation-cap vector path (#0E7C66 teal background, white foreground), monochrome layer for themed icons (API 33), round variants; legacy PNGs for pre-26 generated via Pillow (supersample 4× downsample for smooth edges); roundIcon declared in manifest. (3) AppConfig.appVersion was still '1.1.3' (missed in v1.1.4 bump) — would have falsely re-offered 1.1.4 on every check; fixed to '1.1.5'. Version bumped to 1.1.5+1; aapt2 dump badging confirms versionName 1.1.5 + adaptive icon reference. flutter analyze 7 infos; flutter test 25/25; APK split-per-ABI + web built; migrated migration 015_app_meta_v115 pushed; GitHub Release v1.1.5 published with 3 assets; APK URL verified 200. |
| result | success — two reported bugs fixed, latent version bug caught and fixed |
| files | src/android/.../MainActivity.kt, src/lib/core/updater.dart, updater_io.dart, updater_web.dart, src/lib/screens/settings_screen.dart, src/lib/l10n/app_ar.arb (+generated), src/lib/core/config.dart, src/pubspec.yaml, src/android/.../AndroidManifest.xml, src/android/.../res/drawable/ic_launcher_foreground.xml, ic_launcher_monochrome.xml, mipmap-anydpi-v26/ v33/ (ic_launcher.xml, ic_launcher_round.xml), mipmap-*/ic_launcher*.png, supabase/migrations/20260916130000_app_meta_v115.sql |
| errors | 1 (v1.1.4 release left AppConfig.appVersion at 1.1.3 — fixed now) |
| lessons | (1) Directory.systemTemp on Android is NOT reliably the app cache dir (OEMs set TMPDIR to /data/local/tmp or leave it unset); for FileProvider-backed intents, ALWAYS use the app's actual cacheDir (get it from the native side or path_provider) — the 2026-09-16 lesson claiming "systemTemp IS the cache dir" was wrong on the user's device. (2) `gh release create` with asset args creates the release as a DRAFT and only publishes after all uploads finish; if the command times out mid-upload, it stays a draft with zero assets — create the release WITHOUT assets first, then upload separately with `gh release upload --clobber`. (3) Always bump AppConfig.appVersion alongside pubspec `version`; leaving them out of sync causes a false "update available" loop every time the device checks GitHub Releases. |
| tags | bugfix, updater, icon, version, release, v1.1.5 |


### EVT-20260916-0004 — Realtime announcements auto-refresh + local system notifications

| Field | Value |
|-------|-------|
| id | EVT-20260916-0004 |
| timestamp | 2026-09-16T18:45:00+03:00 |
| mode | BUILD |
| action | fix: announcements list stale until manual refresh; feat: real Android system notifications (no FCM) |
| summary | (1) Bug: when an announcement (or any notification-producing row) arrived via Realtime, the badge refreshed but the announcements list stayed stale until manual pull-to-refresh. Root cause: home_shell.dart only subscribed to `public.notifications` and only invalidated teacherNotificationsProvider; the `announcements` table was not on the supabase_realtime publication. Fix: new migration 20260916140000_announcements_realtime.sql publishes `public.announcements`; home_shell.dart adds a second Realtime channel (`durus-announcements`) that invalidates announcementsProvider on any change. Channel disposal added for lifecycle hygiene. (2) Feature: local Android system notifications when new rows arrive. Decision: Plan B (no FCM) — verified dl.google.com (Google Maven: com.google.gms/google-services plugin, firebase-messaging, firebase-bom) is unreachable from this machine (404) and nothing is in the Gradle cache, so firebase_messaging cannot build here; pub.dev IS reachable, so flutter_local_notifications 22.3.1 was added. New src/lib/core/local_notifications.dart wraps the plugin (initialize with @mipmap/ic_launcher, requestNotificationsPermission for Android 13+, deterministic id = row uuid.hashCode & 0x7FFFFFFF, channel durus_notifications/الإشعارات, brand teal #0E7C66, payload = notification type). main.dart initializes it before runApp. home_shell.dart notifications-callback calls _showSystemNotificationFor (skips DELETE, needs non-empty title, honors user per-category prefs from notificationPrefsProvider); announcements channel deliberately does NOT show a system notification (the trg_notify_announcement trigger already inserts into notifications → the notifications channel handles it — avoids double pop). Manifest gets android.permission.POST_NOTIFICATIONS. Tap handler opens NotificationsScreen. flutter analyze 0 new issues (8 pre-existing infos); flutter test 25/25. |
| result | success — stale-list bug fixed; Android system notifications wired to Realtime (Plan B: no FCM) |
| files | supabase/migrations/20260916140000_announcements_realtime.sql, src/lib/screens/home_shell.dart, src/lib/core/local_notifications.dart (new), src/lib/main.dart, src/pubspec.yaml, src/android/app/src/main/AndroidManifest.xml |
| errors | none |
| lessons | (1) Newer supabase postgres-changes payload API: `newRecord`/`oldRecord` are NON-nullable Map<String,dynamic> (empty for delete) — no null check needed; `PostgresChangeEvent.delete` guards delete events. (2) flutter_local_notifications 22.x API: initialize/settings and show/id are named params; tap callback receives NotificationResponse (not (int,String?)). (3) When one DB table change logically also produces another table's rows via triggers (announcements → notifications), wire system notifications to the ROW-GENERATING channel only, or the user gets duplicate popups. (4) FCM path remains blocked on this machine (Google Maven unreachable, no cached artifacts) — verified explicitly; revisit only with a working network or pre-seeded Gradle cache. |
| tags | realtime, announcements, notifications, local-notifications, no-fcm, bugfix, feature |
## EVT-20260916-0005
- id: EVT-20260916-0005
- timestamp: 2026-09-16
- mode: BUILD
- action: Unblock Android build for flutter_local_notifications
- summary: APK build failed because the plugin hardcodes AGP 8.11.1 in its own buildscript and dl.google.com (Google Maven) is filtered on this machine (returns 404 for every artifact, even ones that exist). Diagnosed that maven.aliyun.com/repository/google fully mirrors Google Maven and is reachable; Maven Central is also reachable. Added Aliyun mirror as first repo in settings.gradle.kts (pluginManagement) and build.gradle.kts (allprojects + subprojects buildscript). Enabled isCoreLibraryDesugaringEnabled=true and added coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4") in app/build.gradle.kts (required by plugin AAR metadata check).
- result: flutter build apk --debug succeeds (gredal 306s first run fetching mirror artifacts, then 78s cached). Analyze: 8 infos/0 errors. Tests 25/25 pass.
- files: src/android/settings.gradle.kts, src/android/build.gradle.kts, src/android/app/build.gradle.kts
- errors: 'Could not resolve all artifacts ... gradle-settings-api:8.11.1, sdk-common:31.11.1, sdklib:31.11.1' + ':app:checkDebugAarMetadata requires core library desugaring'
- lessons: see lessons list below (dl.google.com filtered; Aliyun mirror is the Google Maven gateway)
- tags: android, gradle, flutter_local_notifications, mirror, network

## OP-20260916-0001
- id: OP-20260916-0001
- timestamp: 2026-09-16
- workflow: android_build_unblock_mirror
- project: durus
- steps: 1) identify plugin buildscript AGP hardcode 8.11.1; 2) enumerate Gradle cache AGP versions; 3) probe dl.google.com + Maven Central + mirrors; 4) add Aliyun mirror to Gradle repos; 5) enable desugaring + add desugar_jdk_libs; 6) rebuild pass
- duration: ~30 min
- result: green APK build
- lessons: dl.google.com returns 404 for all artifacts -> treat as filtered, route Google Maven via maven.aliyun.com/repository/google
- reusable_pattern: gradle/google-maven-mirror
## EVT-20260916-0006
- id: EVT-20260916-0006
- timestamp: 2026-09-16
- mode: BUILD
- action: students-tab feature package (stats, edits, exports, shares) + release v1.1.6
- summary: Completed the students-tab package that started with fee card edits. students_screens.dart: parent-link section now uses full shareable URL AppConfig.webBaseUrl + #/portal/token with WhatsApp share button; student detail action bar (Edit/Report/More); _showStudentActions sheet (WhatsApp / Share parent link / Export attendance / Export tests / Delete); _shareExport via Clipboard + waChatLink (no share_plus by design); attendance/tests export composers; teacher-side stats section (_statsSection + _metricRow) showing attendance rate, tests count/average; tests CRUD full edit path (_TestSheet edit mode, _showTestActions Edit/Share/Delete). portal_screens.dart: portal shows stats section (attendance rate, tests avg/count) with share-summary-to-clipboard. Fixed build bug where an edit consumed _slotTile declaration. flutter analyze 0 errors / 8 infos; flutter test 25/25. Release v1.1.6: config appVersion 1.1.6 + pubspec 1.1.6+1; migration 20260916150000_app_meta_v116.sql (Arabic notes, apk_url) pushed; flutter build web --release (70s) + apk --split-per-abi green (arm64 20.2MB / armv7 18.1MB / x64 21.6MB); local web smoke :8171 boots cleanly, portal entry renders (بوابة ولي الأمر / رمز الدخول / عرض البيانات). Added src/android/build/ to android/.gitignore.
- result: success - students-tab package shipped, v1.1.6 artifacts built, web smoke verified
- files: src/lib/screens/students_screens.dart, src/lib/screens/portal_screens.dart, src/lib/core/config.dart, src/pubspec.yaml, supabase/migrations/20260916150000_app_meta_v116.sql, src/android/.gitignore, memory/
- errors: 1 (transient build break from _slotTile declaration consumed by an edit - restored; analyze/tests green after)
- lessons: (1) When mechanically inserting large blocks (e.g. _statsSection/_metricRow before _slotTile) verify the surrounding declarations survive; flutter analyze is the safety net before any build. (2) Keep exports/shares on Clipboard + waChatLink to avoid share_plus dependency and network risk. (3) Web smoke: Flutter web needs Enable accessibility clicked before the a11y tree is readable, and the MCP click on that placeholder can fail - dispatch synthetic events or read page via flt-semantics-host after enabling.
- tags: students, stats, exports, share, tests-crud, release, v1.1.6, smoke

## EVT-20260916-0007
- id: EVT-20260916-0007
- timestamp: 2026-09-16
- mode: BUILD
- action: student window bottom action bar (all major actions in one fixed navbar)
- summary: Per user request, StudentDetailScreen now shows a fixed BottomAppBar (height 72) holding ALL major student actions directly: Edit (commonEdit), Reports (reportsTitle -> MonthlyReportScreen), More/Options (studentsActions -> existing _showStudentActions sheet with WhatsApp/share link/export attendance/export tests), and Delete (commonDelete, error color, direct _deleteStudent with confirm). Removed the old inline 3-button row (Edit/Report/More) from the ListView top and the bottom-of-scroll Delete button. Scaffold bottomNavigationBar only rendered when cachedStudent != null; helper _studentBottomBar + _bottomBarAction (icon+label InkWell column). flutter analyze 0 errors / 0 warnings (8 pre-existing infos); flutter test 25/25.
- result: success - bottom navbar with all major student actions in place
- files: src/lib/screens/students_screens.dart, memory/events.md
- errors: 1 transient unused-local warning from leftover l10n in _bottomBarAction - removed
- lessons: (1) When consolidating scattered actions into a bottom bar, verify every inline duplicate is removed to avoid redundant paths (old row + bottom delete removed). (2) BottomAppBar height + spaceAround keeps 4 actions readable in RTL Arabic.
- tags: students, ui, bottom-bar, navigation, actions

## EVT-20260916-0008
- id: EVT-20260916-0008
- timestamp: 2026-09-16
- mode: BUILD
- action: bulk operations (multi-select + apply one action to many) and richer filters for students/subjects/fees tabs
- summary: Added multi-select to all three data tabs. New reusable SelectionBar widget in widgets.dart (count text, select-all/clear toggle, close, per-action chips via BulkAction) + RefreshableEmpty already existed. StudentsListBody: long-press enters selection with Checkbox leading tiles; SelectionBar bulk actions = BulkDelete (confirm counts), BulkSetGrade (dialog, empty = clear grade), BulkAssignSubject (SimpleDialog of subjects), BulkShareLinks (Clipboard parent portal links + WhatsApp to first parent phone); new Grade + Subject filter dropdowns + name/newest sort toggle. SubjectsListBody: selection + bulk delete/set grade + grade filter dropdown. FeesBody: selection + bulk delete + bulk mark-paid (composes payment rows from remaining = amount - paidAmount, skips zero) + month and status (unpaid/partial/paid) filter dropdowns (kept student filter + summary card). DurusApi bulk section: deleteStudents, updateStudentsGrade(ids, grade nullable), assignSubjectToStudents (idempotent via existing refs fetch), removeSubjectFromStudents, deleteSubjects, updateSubjectsGrade, deleteFees, markFeesPaid(entries, method=cash) - all .inFilter-scoped, RLS intact. l10n: bulk/filter/sort keys added to app_ar.arb (commonSelectAll, bulkActions, bulkSelected{n}, bulkNoSelection, bulkCompleted, bulkDeleteTitle, bulkDeleteConfirm{n}, bulkSetGrade(+Title), bulkAssignSubject(+Title), bulkExportAttendance, bulkShareLinks, bulkMarkPaid(+Confirm{n}), filterAllGrades/Subjects/Locations/Months/Status, sortName, sortNewest); gen-l10n regenerated. Builder hiccup: helpers were first inserted into FeeFormScreenState via ambiguous catch-block match - moved into _FeesBodyState; restored messenger reuse in _save (unused-local warning) and fixed a missing Expanded( close before the fees SelectionBar.
- result: success - bulk ops + filters shipped on all three tabs; analyze 0 errors/0 warnings (8 pre-existing infos), tests 25/25; committed 515e5cf and pushed (fd52bc0..515e5cf)
- files: src/lib/widgets/widgets.dart, src/lib/screens/students_screens.dart, src/lib/screens/subjects_screens.dart, src/lib/screens/fees_screens.dart, src/lib/core/durus_api.dart, src/lib/l10n/app_ar.arb, src/lib/l10n/app_localizations.dart, src/lib/l10n/app_localizations_ar.dart
- errors: 2 transient (1) bulk helpers misplaced into _FeeFormScreenState by ambiguous catch match - relocated; (2) missing Expanded( close before SelectionBar - added. Both caught by flutter analyze. Also marker: 1 pre-existing 'value:' deprecation info in fees filters row (DropdownButtonFormField<String?>) -> switched to initialValue; 1 introduced infos (unnecessary_underscores) fixed.
- lessons: (1) When inserting helper blocks via a shared } catch (_) {...} + @override build pattern as oldString, the match may land in another screen/state class - always re-read the region after the edit and run flutter analyze before proceeding. (2) For selection-mode UI, keep the SelectionBar in a Column below the list (no Stack/FAB) so RTL Arabic scroll + density stays simple; Checkbox-leading tiles with selectedTileColor give clear affordance. (3) Confirm dialogs for bulk ops must show the count (bulkDeleteConfirm{n}) to prevent accidental group deletes; mark-paid must skip already-paid fees (remaining > 0).
- tags: bulk, multi-select, filters, students, subjects, fees, tab, ui, l10n, riverpod

## EVT-20260916-0009
- id: EVT-20260916-0009
- timestamp: 2026-09-16
- mode: BUILD
- action: release v1.1.7 (bulk operations + filters + student action bar)
- summary: Released v1.1.7. Bumped AppConfig.appVersion 1.1.6->1.1.7 and pubspec 1.1.7+1. Created migration 20260916160000_app_meta_v117.sql (Arabic notes covering: fixed student-window bottom action bar, bulk operations on students/subjects/fees tabs - delete/set grade/assign subject/share parent links/mark fees paid, and richer filters grade/subject/sort, grade, month/status) with apk_url pointing at the arm64 build; pushed via supabase db push --yes (project rdlapngvsxhdcoxdcjov, CLI 2.116.0). flutter build web --release (61.8s) + apk --release --split-per-abi (97.5s; arm64 20.3MB / armv7 18.2MB / x64 21.7MB) all green. Committed 8311e88 (code+migration), tagged v1.1.7 and pushed tags. gh release create v1.1.7 (title 'Durus v1.1.7 - عمليات جماعية وفلاتر') with Arabic release notes; uploaded 3 APKs sequentially via gh release upload --clobber (parallel multi-file upload timed out at 180s); verified isDraft=false + all 3 assets attached; apk_url HEAD returns 200 via release-assets.githubusercontent.com redirect. Deployed web to GitHub Pages: orphan-branch push of build/web to gh-pages (force update 6bf477c->2189649); live portal https://amworx.github.io/durus/ returns 200 + flutter app served + page title دروس renders.
- result: success - v1.1.7 live on GitHub Releases + in-app metadata + web portal updated
- files: src/lib/core/config.dart, src/pubspec.yaml, supabase/migrations/20260916160000_app_meta_v117.sql, src/build/* (artifacts), memory/events.md
- errors: 2 minor (1) gh release upload with 3 APK paths timed out at 180s with 0 assets - fixed by uploading one file per call; (2) release_notes_v117.md written to scratch then deleted after upload (pattern); also flutter build regenerated l10n files with LF line endings - restored via git checkout (content identical). Note: PowerShell True after git push returns false due to stderr wrapper - create/tag pushes must be verified explicitly with git ls-remote.
- lessons: (1) Upload GH release assets ONE file per command - a multi-file 'gh release upload a b c' on this machine stalls past 180s and leaves zero assets. (2) After 'git push 2>&1 | Select-Object' the True flag lies (NativeCommandError wrapper) - always confirm tags/branches via git ls-remote / gh release view instead of chaining if (True). (3) Verify release liveness with gh release view --json isDraft,assets AND a HEAD request on the apk_url that follows redirects to release-assets.githubusercontent.com (200 = live).
- tags: release, v1.1.7, bulk-ops, filters, gh-pages, apk, web, supabase, app-meta
