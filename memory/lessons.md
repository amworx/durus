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