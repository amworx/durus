# Tasks — Sessions & Announcements/Notifications UX (2026-09-16)

## Part A — Sessions
- [x] A1a Migration: sessions attendance 5 states + topics/homework/rescheduled_to columns
- [x] A1b Migration: notify_session_change trigger for late/cancelled
- [x] A1c Migration: generate_report + parent_portal attendance buckets + new fields
- [x] A2 Model/API: LessonSession fields; recordAttendance/updateLesson/deleteLesson
- [x] A3 Today tab: summary strip + tile v2 + 5-state quick mark + undo snackbar
- [x] A4 Session Detail sheet (shared widget)
- [x] A5 Schedule screen: 5-state styles + tap-to-edit

## Part B — Announcements & Notifications
- [x] B1a Migration: announcements title/audience/pinned/expires_at
- [x] B1b Migration: notify_announcement audience+expiry filter; parent_portal announcements
- [x] B1c Migration: notification_prefs table + RLS
- [x] B2 Compose screen (title/audience/pin/expiry, edit mode)
- [x] B3 AnnouncementsScreen management (pin/edit/delete)
- [x] B4 Notification center: filters + row actions + clear all
- [x] B5 Settings: notification category toggles + prefs provider filter

## Cross-cutting
- [x] l10n: add all new ARB keys + gen-l10n
- [x] Tests: flutter analyze 0 errors/warnings; flutter test 25/25 (existing suite — no NEW unit tests added for the new features)
- [x] flutter analyze + flutter test
- [x] Push migrations, REST verify (triggers, audience, buckets)
- [x] Build APK (split) + web; Chrome MCP verify (network-level: all endpoints 200 incl. notification_prefs; visual not possible — no image input)
- [x] Release v1.1.4 + app_meta + memory events