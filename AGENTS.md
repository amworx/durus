# Durus (دروس) — Project AGENTS.md

Inherits the global doctrine in `~/.config/opencode/AGENTS.md` (orchestrator,
memory system, UI Design Playbook) and the container rules in
`code_repo/AGENTS.md`. Project-specific rules below. This file may NOT override
memory/event/safety rules, model priority, package-install rules, or global UI
design rules.

---

## Identity

**Durus (دروس)** — private-lessons management for one teacher or a small
teaching team. Covers students, subjects, weekly schedule, attendance,
variable monthly fees, tests/results, notes, monthly reports, and parent
follow-up.

- **Audience:** Arabic only, RTL. Primary grades 1–6 (age ~7–12).
- **Lesson locations:** teacher's home or student's home (per-student setting).
- **Parents** follow up via a **link / PIN portal** (responsive web, no install).

## Roles

- **Manager (مدير)** — full admin control. Exists only in multi-teacher mode.
- **Teacher (مدرّس)** — manages own students only (RLS-scoped).
- **Parent (ولي أمر)** — link/PIN portal, sees only own child. No accounts in v1.
- **First-launch wizard** asks single vs multi:
  - **Single** → the one teacher IS the manager; no user management.
  - **Multi** → creator becomes manager; other teachers join via invitation
    link OR manager-created credentials (shared with the teacher).

## Stack

- **Flutter 3.44.9 / Dart 3.12.2** (`C:\flutter`), ONE codebase:
  Android app (teacher/manager) + responsive web (parents portal + admin
  dashboard). Flutter project lives at `src/` (Klear layout).
- State: **Riverpod 2** · Routing: **go_router** ·
  Localization: `flutter_localizations` + **`.arb` (Arabic only)**.
- Backend: **Supabase** — Postgres + Auth + RLS + Realtime, free tier, ONE
  project. No hardcoded secrets; keys passed via `--dart-define` / env config.

## Non-negotiable rules

- **Arabic only** — every user-facing string goes through `.arb`
  (`app_ar.arb` is the template). Never hardcode strings. RTL required.
- **RLS is the security boundary** — never embed service-role keys.
  Teacher↔student scoping is enforced in Postgres (`assigned_teacher`), NOT in
  the UI.
- **Parents get PIN links, not accounts** (v1).
- **Fees are variable and teacher-controlled** — flexible amount per
  student/month recorded in a ledger; never bake a fixed pricing model into
  code.
- **Multi-teacher is data-scoped** — the UI is identical in single and multi
  modes; the wizard only decides whether the manager role exists.
- **Full CRUD everywhere** (students, subjects, fees, tests, notes) — the
  teacher controls everything; no fixed enums for subjects or fees.

## Structure

```
durus/
  AGENTS.md
  src/                 Flutter app (pubspec.yaml here — Klear layout)
  supabase/            SQL migrations / schema (created in Phase 1)
  docs/  plans/  tasks/  memory/
```

## Commands

Run from `durus/src/`:

```powershell
flutter analyze
flutter test
flutter build apk --debug --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_PUBLISHABLE_KEY=...
flutter build web   # parents portal + admin dashboard (responsive web)
```

## Machine notes (this machine)

- Network-constrained: prefer exact version pins that avoid fetching missing
  SDK artifacts. Known pins/jni issue documented in
  `android/klear-staff/AGENTS.md` (`supabase_flutter: 2.17.1` exact,
  `path_provider_android: 2.2.23` override) — reuse before bumping versions.
- Flutter stable at `C:\flutter`; Android SDK at
  `C:\Users\HP\AppData\Local\Android\Sdk` (android-36); `cmdline-tools/
  sdkmanager` missing — revisit only when Play Store signing/config requires it.

## UI

Every UI generation/edit must load `ui-design.md` (global UI Design Playbook)
first.

## Override boundary

May override: project structure, naming conventions, workflows, technology
stack. May NOT override: memory/event system, failure handling, safety rules,
model priority, package installation rules, global UI rules.