# Patterns — Durus

Append-only. Reusable patterns extracted from successes.

- **First-launch role wizard (reusable):** ask the single/multi question once,
  persist the answer, and branch only on role/permissions — never on UI. The
  app behaves identically; RLS handles scoping. (Used for Durus teacher mode;
  also applicable to any multi-tenant "solo vs team" product.)
- **PIN-based external sharing (reusable):** give non-technical stakeholders a
  hashed-PIN link instead of an account. Zero signup friction; revocable.
  (Durus parent portal; based on TutorHive/ClassDojo model.)
- **Design proposal generation (reusable):** for any "make my UI unique/
  modern" request, load design-an-interface + ui-ux-pro-max, launch 5 parallel
  sub-agents each with a radically different direction, then present all 5
  with a comparison table covering vibe/palette/typography/RTL/assets risk and
  let the user pick before implementing. (Used for Durus redesign; applicable
  to any app or web project.)
- **In-app update check (reusable):** keep a single global `app_meta` table
  (key text pk, value jsonb, updated_at) with an `latest_release` row
  {version, url, notes}; RLS permits public select only (writes stay
  service-role/SQL). App stores its version in one constant and semver-
  compares against the row; on newer -> open the release page. This replaces
  "re-send the APK" workflows for single-device and small-team apps.
- **Branded native splash (reusable):** one vector drawable logo + a
  `values/colors.xml` background color, referenced by launch_background
  (drawable + drawable-v21) and a dedicated `values-v31/styles.xml` with
  `windowSplashScreenBackground/AnimatedIcon` for Android 12+. No generated
  images, no extra deps, works on the old splash path too.
- **First-class chat affordance (reusable):** when a product is used by
  non-technical users on thin networks, put the platform chat deep link
  (wa.me with normalized phone + prefilled localized message) directly on the
  main entity screen instead of building an in-app chat. Low cost, huge
  familiarity win.
- **Pull-to-refresh on Riverpod FutureProvider screens (reusable):** a single
  refreshSchoolData(WidgetRef) helper awaits Future.wait of ref.refresh(p.future)
  across all data providers (errors swallowed - each provider renders its own
  ErrorRetry); plus a fire-and-forget invalidateAllSchoolData(WidgetRef) for
  lifecycle events. Screens wrap their scrollable in RefreshIndicator +
  AlwaysScrollableScrollPhysics; empty branches use RefreshableEmpty
  (CustomScrollView + SliverFillRemaining). The shell adds WidgetsBindingObserver
  so returning to the foreground refetches everything without a restart. Keeps
  Riverpod caches warm and avoids per-screen boilerplate.
- **Idempotent SQL seed migration (reusable):** fixed UUID PKs for every row +
  ON CONFLICT DO NOTHING so the file can be re-pushed safely; push with
  `supabase db push --yes --password <db_pass>`. Derive-not-invent: insert base
  tables only and let DB triggers create notifications / recompute fee status,
  giving instant realistic test data that also validates the trigger paths.
- **GitHub-auto-detected in-app updater (reusable):** AppRelease carries the
  version/url/notes/apkUrl. The API service merges curated app_meta with
  GET /repos/<owner>/<repo>/releases/latest (Accept application/vnd.github+json,
  User-Agent, 8s timeout, try/catch -> metadata fallback); newest wins, ties
  prefer the entry with apkUrl. Parse assets: prefer arm64-v8a, then any .apk;
  strip a leading v from tag_name; truncate long notes. On Android download
  into Directory.systemTemp/updates (== cache dir; expose with a FileProvider
  <cache-path>), report progress from contentLength, then a MethodChannel
  launches ACTION_VIEW on the FileProvider URI. Keep the web build green with
  a conditional-import stub (updater_web.dart) so dart:io never reaches the
  web compiler.

- **Seed real-account demo data (reusable):** when the user tests on their own phones, seed INTO their actual school (not the smoke school) and attach dummy students to the teacher they log in as (assigned_teacher_id = that teacher's profile id) so both the teacher phone (RLS: own students) and the manager phone (RLS: whole school) show it. Reference the school's existing subjects rather than creating duplicate dummy subjects named like the real ones. Keep fixed-UUID + ON CONFLICT DO NOTHING, let DB triggers fan out notifications/fee status, and verify with service-role REST counts (in PS 5.1 assign the response to a variable before .Count).