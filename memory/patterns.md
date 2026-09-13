# Patterns — Durus

Append-only. Reusable patterns extracted from successes.

- **First-launch role wizard (reusable):** ask the single/multi question once,
  persist the answer, and branch only on role/permissions — never on UI. The
  app behaves identically; RLS handles scoping. (Used for Durus teacher mode;
  also applicable to any multi-tenant "solo vs team" product.)
- **PIN-based external sharing (reusable):** give non-technical stakeholders a
  hashed-PIN link instead of an account. Zero signup friction; revocable.
  (Durus parent portal; based on TutorHive/ClassDojo model.)