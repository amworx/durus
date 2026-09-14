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