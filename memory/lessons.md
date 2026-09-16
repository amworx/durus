# Lessons — Durus

Append-only.

- 2026-09-13 — Western tutoring SaaS assumes online payments (Stripe/PayPal).
  For Syria, payments are cash in person → the app needs a **tracking ledger**
  (who paid / who owes per month), not payment processing. Don't copy the
  billing modules of those products; copy their scheduling/attendance/parent
  UX.
- 2026-09-13 — The "free app" question has two meanings: free SaaS now
  (ClassDojo/TuitionDesk) vs custom build. We chose custom build; still reuse
  SaaS screen patterns as reference during design.
- 2026-09-13 — This machine is network-constrained. Reuse the version pins
  documented in `android/klear-staff/AGENTS.md` before bumping dependencies
  (supabase_flutter 2.17.1 exact; path_provider_android 2.2.23 override).- 2026-09-13 — Config defaults: putting defaultValue in String.fromEnvironment means even lutter build web (no --dart-define) points at the real project — good for demos/smoke tests, just never print the key.
- 2026-09-13 — Prefer build + static-serve over background lutter run for UI verification: lutter build web; python -m http.server 8080 --directory build/web, then drive Chrome via MCP. Background lutter run servers die silently and take ~30s to boot.
- 2026-09-13 — New Flutter screen files need BOTH imports: package:durus/l10n/app_localizations.dart (for the AppLocalizations type) and package:durus/l10n/l10n_ext.dart (for context.l10n). Missing the former yields undefined_class errors.
- 2026-09-13 — Dart 3 record-pattern matching on AsyncValue subtypes doesn't promote reliably; for multiple async providers in one build, nest .when() calls instead of switch ((a, b)).
- 2026-09-14 — `auth.admin_create_user(...)` is **not** a SQL function on Supabase (Admin API only). Creating users from a security-definer RPC requires direct inserts into `auth.users` + `auth.identities`. The earlier `create_teacher_with_credentials` failed with 42883 for this reason.
- 2026-09-14 — Direct-inserted `auth.users` rows MUST set `confirmation_token`, `recovery_token`, `email_change_token_new`, `email_change` to `''` (not NULL), or GoTrue's password grant returns HTTP 500 "Database error querying schema" (it scans them into non-nullable Go strings). Also set `email_confirmed_at` to skip confirmation.
- 2026-09-14 — Newer GoTrue has `auth.identities.provider_id` NOT NULL; detect the column via `information_schema.columns` and branch the identity insert so the RPC works across GoTrue versions.
- 2026-09-14 — PostgREST returns a scalar-returning RPC (e.g. `returns uuid`) as a bare JSON string, not an object keyed by the function name. Don't `as Map<String, dynamic>` it; handle both shapes.
- 2026-09-14 — Never trust a create-account RPC's 200 alone: verify by performing a real password login (auth/v1/token) and, for gating logic, an isolated-context browser login.
- 2026-09-14 — Disabled-account enforcement is app-gate only in v1 (router check on `profile.active`). A determined client could still call the API with the anon key; server-side enforcement (RLS `is_active()` or a GoTrue before-login hook) is future work.- 2026-09-14 — Free deployment for Flutter: GitHub Pages serves the web build
  from a gh-pages branch (auto-enabled on push), GitHub Releases hosts the
  signed APK — USD 0, no card. Play Store is the only non-free piece ().
- 2026-09-14 — PowerDown gotcha: keytool.exe writes progress to stderr, so
  PowerShell $? is false even when it succeeds — gate on Test-Path, not $?.
- 2026-09-14 — shared_preferences_android 2.4.28's lintVital needs
  androidx.datastore:datastore-jvm:1.1.7 which is not resolvable here; disable
  release lint (checkReleaseBuilds=false) for CI-broken lint classpaths.
- 2026-09-14 — Flutter web must be built with --base-href /<repo-name>/ for a
  GitHub Pages project site; a wrong base-href renders blank/404 on assets.
- 2026-09-14 — Verify a Pages deploy by loading the URL and confirming the
  Flutter root title flips to the app name ("دروس"), not just HTTP 200.- 2026-09-14 — Live Supabase can drift from supabase/config.toml: always
  verify via GET /auth/v1/settings (needs apikey header). Fix drift with
  supabase config push --project-ref <ref> --yes after editing config.toml.
- 2026-09-14 — Free-tier auth email quota is 2/hour (config [auth.rate_limit]
  email_sent=2) and it ALSO blocks confirmation/OTP/password-reset emails;
  auto-confirm (enable_confirmations=false) removes the signup blocker only.
- 2026-09-14 — Invoke-RestMethod mangles JSON bodies on some Supabase auth
  endpoints; prefer curl.exe with --data-binary @tempfile (ASCII) for auth/REST
  verification calls.- 2026-09-14 — Twilio/SendGrid blocks Syria (HTTP 451 geo-legal); use Gmail
  SMTP instead for Supabase auth email: smtp.gmail.com:587, user = gmail
  address, pass = App Password (requires 2-Step Verification ON).
- 2026-09-14 — supabase/config.toml secrets: use pass = "env(VAR)" so the
  committed file is secret-free; the CLI resolves at supabase config push
  and redacts the value (shows hash) in its diff output.- 2026-09-14 — After publishing a Flutter web build, verify on a fresh tab
  with cache-bypass reload (ignoreCache:true): the service worker keeps
  serving the previous main.dart.js to returning tabs.- 2026-09-15 — Android release builds: Flutter's template puts INTERNET
  permission only in src/debug/AndroidManifest.xml. Every release APK must
  declare it in main/AndroidManifest.xml or ALL network calls fail silently.
  Verify with: aapt2 dump permissions app-release.apk.- 2026-09-15 — Supabase free Storage: max 50MB per object; use
  flutter build apk --release --split-per-abi (arm64 ~19MB) instead of the
  universal APK for free hosting. Upload with the Storage REST API
  (POST /storage/v1/object/<bucket>/<name>?upsert=true, bearer service key).
- 2026-09-15 — Keep the URL literal or build it in a variable before the
  upload call; string interpolation with query params inside a curl call in a
  PowerShell loop created an object literally named "=true".- 2026-09-15 -- Silent anonymous upload: catbox.moe wins. API:
  curl -F reqtype=fileupload -F fileToUpload=@file https://catbox.moe/user/api.php
  Returns: direct URL (files.catbox.moe/xxx). Permanent until deleted. Up to 200MB.
  Use share-apk.ps1 in project root for one-command uploads.
- 2026-09-15 -- file.io's curl API is dead (redirects to www.file.io, then
  LimeWire's undocumented claim-token+CSRF flow). The Developers page on
  file.io is stale. Do not use for programmatic uploads.
- 2026-09-15 -- 0x0.st is disabled (botnet spam). litterbox rejects anonymous.
  tmpfiles.org works but returns an HTML wrapper page (not a direct URL).
- 2026-09-15 -- PowerShell 5.1 parser chokes on non-ASCII chars (em-dash,
  curly quotes) in script files. Use only ASCII in .ps1 files.
- 2026-09-15 -- To redesign UI "too classic" apps: run 5 parallel design
  sub-agents (design-an-interface + ui-ux-pro-max skills), each with a
  radically different direction (neo-brutalist / glassmorphism / editorial-
  print / bento / dark-minimal), then present all 5 with a comparison table
  (vibe, palette, type, RTL strength, low-end phone risk) and let the user
  pick. Implement only after selection.
- 2026-09-15 -- Chosen design will likely need bundled Google Fonts (Reem
  Kufi, Changa, Cairo, Amiri, Tajawal, Noto Sans Arabic, IBM Plex Sans
  Arabic). On this network-constrained machine, download font files once from
  the google/fonts GitHub repo, commit them, and register in pubspec.yaml —
  do NOT use google_fonts runtime fetch.
- 2026-09-15 -- A user may pick TWO sibling designs (here فسيفساء light +
  سكون dark) instead of one. Implement both as full ThemeData design systems
  and let the end user choose in Settings; when the two designs are literally
  the light/dark split, the design IS the brightness — drop the separate
  dark-mode toggle (fewer settings, no conflicting state).
- 2026-09-15 -- Variable fonts (ReemKufi[wght].ttf, Cairo[slnt,wght].ttf) can
  be bundled as ONE downloaded file registered once per declared weight in
  pubspec.yaml (each weight entry points at the same file), saving 4 downloads
  per family.
- 2026-09-15 -- Chrome MCP form fill (Flutter web, CanvasKit) can drop the
  FIRST character of a text field value (password showed `stPass123!` for
  `TestPass123!`). Always confirm the submitted payload in the network request
  body before concluding auth failed, and re-fill using select-all + type_text.
- 2026-09-15 -- Kufi-style display faces (Reem Kufi) are hard to read for
  body text and numbers on a phone. For an app full of amounts/schedules,
  prefer a screen-tuned UI sans (Zain / Almarai / Noto Sans Arabic) or a Naskh
  face (Noto Naskh Arabic). User picked **Zain** for Durus — one family for
  display + body + numerals in both designs.
- 2026-09-15 -- Supabase Storage `x-upsert: true` keeps the same object `Id`
  for a path even when content changes. Verify an upload really replaced the
  file by comparing `Content-Length` (or Last-Modified), never the returned Id.
- 2026-09-15 -- A font-picker webpage (identical sample text per card, one
  content-mode switcher, click-to-select with a sticky chosen bar) is a fast,
  reliable way to let a user choose a typeface — adapted from the
  design-showcase pattern and preferred over asking for font names blindly.
- 2026-09-16 -- A layer-list `<item android:drawable="...">` rejects a raw
  hex color literal in AAPT ("'#FAF8F4' is incompatible with attribute
  drawable"). Always define the color in `values/colors.xml` and reference
  `@color/...`. Hex literals are fine for color-TYPED attributes
  (`windowSplashScreenBackground`) but not drawable-typed ones.
- 2026-09-16 -- Before adding a new package on this network-constrained
  machine, check whether it is already a TRANSITIVE dependency: url_launcher
  was already pulled in by supabase_flutter 2.17.1 (exact pin), so adding it
  as a direct dep (`^6.3.2`) downloaded zero new packages. `flutter pub add`
  still resolves to what the existing pins allow.
- 2026-09-16 -- Supabase Storage bucket `durus-apk` rejects anon writes
  (RLS access denied). Since the app now points users to GitHub Releases
  (app_meta.latest_release.url), the bucket is legacy — don't attempt bucket
  uploads without a service-role credential.
- 2026-09-16 -- RefreshIndicator is a real gesture only on touch/trackpad
  (mobile/web-touch). On desktop web the pull gesture does nothing; the
  WidgetsBindingObserver resume path (invalidateAllSchoolData) is what keeps
  web fresh on tab refocus (visibilitychange -> AppLifecycleState.resumed).
- 2026-09-16 -- Always add AlwaysScrollableScrollPhysics when wrapping in
  RefreshIndicator or short/empty lists aren't pullable. Empty states need a
  scrollable too: reuse RefreshableEmpty (RefreshIndicator + CustomScrollView +
  SliverFillRemaining) instead of a bare EmptyState.
- 2026-09-16 -- The students-list location label had switch key 'teacher'
  instead of the DB value 'teacher_home', so teacher-home students showed the
  raw enum in the list. DB switch keys must match column values verbatim;
  this bug sat unnoticed until a teacher_home student existed.
- 2026-09-16 -- PostgREST returns HTTP 400 for `select=id` on tables with a
  composite primary key (student_subjects). Use `select=*` for those tables.
- 2026-09-16 -- PowerShell 5.1 Invoke-WebRequest fails in non-interactive
  shells ("Read and Prompt functionality is not available") because it parses
  responses with the IE engine. Use Invoke-RestMethod and derive counts from
  the array Count (PostgREST caps at 1000 rows) instead of Content-Range.
- 2026-09-16 -- Seed migrations are idempotent when every row carries a fixed
  UUID and uses ON CONFLICT DO NOTHING. Let the DB triggers fan derived rows
  out (notifications for sessions/tests/notes/fees/payments, fee status
  updates) - seeding base tables only keeps the migration small and exercises
  the real flows.
- 2026-09-16 -- Version detection must not depend on a manually edited
  metadata row alone: merge the GitHub Releases API (public, no auth,
  GET /repos/:owner/:repo/releases/latest) so publishing a release
  auto-surfaces the update. Keep app_meta for curated Arabic notes and a
  guaranteed apk_url; newest version wins, ties prefer the entry with apkUrl.
- 2026-09-16 -- Android in-app APK update needs three pieces: the
  REQUEST_INSTALL_PACKAGES permission, a FileProvider that exposes the
  download directory (Dart's Directory.systemTemp IS the app cache dir, so a
  <cache-path> entry matches), and a MethodChannel that starts ACTION_VIEW
  with FLAG_GRANT_READ_URI_PERMISSION | FLAG_ACTIVITY_NEW_TASK.
- 2026-09-16 -- dart:io code breaks the web compile; gate native-only logic
  behind conditional imports (updater_io.dart vs updater_web.dart with
  `if (dart.library.html)`). Also keep release APKs signed with the same key
  as the installed build (this project's gradle signs release with the debug
  key) or the system installer rejects the update as a signature mismatch.

- 2026-09-16 -- Demo/seed data is SCHOOL-scoped (RLS). The smoke-school seed was invisible to the user's real accounts; seed INTO the school the user actually opens. In multi-teacher schools the teacher phone only sees students with assigned_teacher_id = their own profile id (manager sees the whole school). If the school already has subjects, reference them in the seed instead of inserting duplicate dummy subjects.
- 2026-09-16 -- PowerShell 5.1: @(Invoke-RestMethod ...).Count inside $"..." string interpolation can mis-parse and report 1; assign the response to a variable first ($r = Invoke-RestMethod ...) then use $r.Count.
- 2026-09-16 -- The SUPA publishable key (sb_publishable_*) is anon-class: REST verification against RLS-protected tables returns 0 rows. Use the service-role JWT for data verification.
- 2026-09-16 -- PowerShell 5.1 Invoke-WebRequest fails in non-interactive shells AND blocks a custom Range header. For PostgREST counts use curl.exe -s -I with `Prefer: count=exact` + `Range: 0-0` and read the Content-Range header.
- 2026-09-16 -- `flutter run -d web-server` (DWDS/devtools injected client) can throw `_JsonMap is not a subtype of List<Object?>` and never render the app. Reuse the proven "flutter build web + python -m http.server" static-serve flow for verification.
- 2026-09-16 -- gh release create can time out mid-asset-upload and leave the release as a DRAFT with zero assets. After creating, check `gh release view <tag> --json isDraft,assets`; if incomplete, `gh release upload <tag> <files> --clobber`, then `gh release edit <tag> --draft=false`.
- 2026-09-16 -- New Flutter 3.44 screens that use AppLocalizations need BOTH generated imports: app_localizations.dart (type) and the project l10n_ext.dart (context.l10n); `static const` lists must become `static final` when they embed values like AppLocalizations lookups.

- 2026-09-16 -- Directory.systemTemp on Android is NOT reliably the app cache
  dir. OEMs may set TMPDIR to /data/local/tmp or leave it unset. For
  FileProvider-backed intents (APK install), ALWAYS resolve the target from
  the actual cacheDir (e.g., via a Kotlin channel method returning
  File(cacheDir, "updates").absolutePath). The earlier assumption that
  systemTemp == cacheDir was wrong on the user's device and caused the
  v1.1.4 "cannot update / cannot find the APK" bug.
- 2026-09-16 -- Always bump AppConfig.appVersion alongside pubspec `version`.
  The two values are compared against the latest GitHub release to decide
  whether an update is available; leaving them out of sync causes a false
  "update available" loop on every resume.
- 2026-09-16 -- `gh release create` creates the release as a DRAFT and only
  publishes after all asset uploads complete. If the command is killed
  (timeout / manual) mid-upload, the release remains a draft with zero assets.
  Safe pattern: `gh release create <tag> --title ... --notes ...` (no assets)
  first, then `gh release upload <tag> <files> --clobber` separately.
- 2026-09-16 -- To generate legacy Android launcher icons without external
  asset tools: use Python + Pillow to draw the brand mark as filled polygons
  (the Material "school" icon path is all line segments) with 4× supersample
  + LANCZOS downsample for smooth edges, then write mipmap-{mdpi..xxxhdpi}/
  ic_launcher.png directly into the res/ tree. Teal (#0E7C66) square +
  white polygons = consistent with splash and adaptive foreground vector.
- 2026-09-16 -- Android 10+ public Downloads visibility requires
  MediaStore.Downloads insert (IS_PENDING flag while writing, then clear it);
  on API < 29 the file goes to getExternalFilesDir(DIRECTORY_DOWNLOADS)
  which is browsable by file managers on those versions without runtime
  permissions. Pair this with a DocumentsUI intent
  (content://com.android.externalstorage.documents/root/downloads) to let
  the user open the Downloads folder directly from the app.
- 2026-09-16 -- Announcement stale-list bug: when a DB trigger creates rows in
  table B (notifications) as a side effect of a change in table A
  (announcements), subscribing ONLY to B leaves the A-driven UI stale. Either
  publish A on realtime too and subscribe, or invalidate the A provider from
  the B callback — but only show system notifications from ONE channel to
  avoid duplicate popups (the trigger already inserts into notifications, so
  let the notifications channel own the system popup).
- 2026-09-16 -- FCM is NOT buildable on this machine: dl.google.com (Google
  Maven: com.google.gms google-services plugin, com.google.firebase/*,
  firebase-bom) returns 404 from here and none of those artifacts are in the
  Gradle cache. pub.dev IS reachable. For "push-like" behavior without FCM,
  use flutter_local_notifications + existing Supabase Realtime channels —
  real system banners/sound with zero cloud dependencies.
- 2026-09-16 -- supabase postgres-changes payload API (supabase 2.16 /
  realtime_client 2.13): `newRecord`/`oldRecord` are NON-nullable
  Map<String,dynamic> (empty for DELETE) — no null guard needed. New
  flutter_local_notifications 22.x API uses named params for
  initialize(settings:) and show(id:), and the tap callback passes a
  NotificationResponse object, not (int, String?).
## Lesson: dl.google.com (Google Maven) is FILTERED, not just missing artifacts — use Aliyun mirror
- problem: AGP 8.11.1 + transitive artifacts unresolved; dl.google.com returned 404 for artifacts that verifiably exist (e.g. gradle-9.0.1.pom, desugar_jdk_libs).
- root cause: network filter/proxy intercepts dl.google.com and answers 404 for everything.
- attempted fixes: (a) downgrade flutter_local_notifications to versions with older AGP (17/18 use 7.3.1, 19/20 use 8.6.0 — none cached/available); (b) skip plugin.
- successful fix: prepend `maven { url = uri("https://maven.aliyun.com/repository/google") }` to ALL repository lists (pluginManagement, allprojects, and subprojects buildscript block); enable core library desugaring.
- lesson: any future Android Gradle dependency fetch failure on this machine => check dl.google.com treat as 404-filter and use the mirror; do not downgrade packages first.
- reusable pattern: gradle/google-maven-mirror

## Lesson: plugins with own buildscript hardcoded AGP need repo injection at subprojects buildscript level
- problem: flutter_local_notifications android/build.gradle declares buildscript { classpath 'com.android.tools.build:gradle:8.11.1' } and own google() repo; app-level allprojects repos do NOT cover subproject buildscript resolution.
- fix: in root android/build.gradle.kts add `subprojects { buildscript { repositories { maven { url = uri(mirror) } } } }`.
- lesson: new Flutter plugins that hardcode AGP in buildscript require the mirror in BOTH pluginManagement/settings and subprojects-buildscript.
- reusable pattern: gradle/google-maven-mirror

## Lesson: flutter_local_notifications requires core library desugaring in the app module
- problem: after fixing repos, :app:checkDebugAarMetadata failed 'Dependency :flutter_local_notifications requires core library desugaring to be enabled for :app'.
- fix: compileOptions { isCoreLibraryDesugaringEnabled = true } + dependencies { coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4") } in app/build.gradle.kts.
- lesson: any Android plugin using java.time backport (local notifications, crashlytics) will demand desugaring; desugar_jdk_libs 2.1.4 is available from the Aliyun mirror.
- reusable pattern: android-core-library-desugaring