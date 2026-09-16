# Tasks — Sessions & Announcements/Notifications UX (2026-09-16)

## Part A — Sessions
- [ ] A1a Migration: sessions attendance 5 states + topics/homework/rescheduled_to columns
- [ ] A1b Migration: notify_session_change trigger for late/cancelled
- [ ] A1c Migration: generate_report + parent_portal attendance buckets + new fields
- [ ] A2 Model/API: LessonSession fields; recordAttendance/updateLesson/deleteLesson
- [ ] A3 Today tab: summary strip + tile v2 + 5-state quick mark + undo snackbar
- [ ] A4 Session Detail sheet (shared widget)
- [ ] A5 Schedule screen: 5-state styles + tap-to-edit

## Part B — Announcements & Notifications
- [ ] B1a Migration: announcements title/audience/pinned/expires_at
- [ ] B1b Migration: notify_announcement audience+expiry filter; parent_portal announcements
- [ ] B1c Migration: notification_prefs table + RLS
- [ ] B2 Compose screen (title/audience/pin/expiry, edit mode)
- [ ] B3 AnnouncementsScreen management (pin/edit/delete)
- [ ] B4 Notification center: filters + row actions + clear all
- [ ] B5 Settings: notification category toggles + prefs provider filter

## Cross-cutting
- [ ] l10n: add all new ARB keys + gen-l10n
- [ ] Tests: 5-state mapper, deleteLesson undo, detail-sheet save, prefs filter, compose validation
- [ ] flutter analyze + flutter test
- [ ] Push migrations, REST verify (triggers, audience, buckets)
- [ ] Build APK (split) + web; Chrome MCP verify
- [ ] Release v1.1.4 + app_meta + memory events