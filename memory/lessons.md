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
  (supabase_flutter 2.17.1 exact; path_provider_android 2.2.23 override).