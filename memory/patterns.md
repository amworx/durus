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