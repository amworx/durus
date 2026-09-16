# Plan — Sessions & Announcements/Notifications UX Upgrade (2026-09-16)

Status: awaiting user confirmation on scope options.
Builds on: v1.1.3 (updater), dual-theme, Zain font, refresh system.

## Part A — Sessions: advanced, flexible, undoable

### Current problems (verified in code)
1. Attendance has exactly 3 states and the Today tab renders them as 3 plain
   buttons (`_MarkButton` present/absent/rescheduled in home_screen.dart).
2. The moment a session is recorded the buttons disappear — no undo, no edit,
   no note editing from Today. (`if (recordedLesson == null)` lock.)
3. Sessions carry only `attendance` + `note`; nothing about what was taught,
   homework, or where a rescheduled session moved to.
4. Schedule/Students screens re-use the same 3-state mapping.

### A1. DB — migration `20260916xxxx_sessions_upgrade.sql`
- Extend `sessions.attendance` check from 3 to 5:
  `('present','absent','late','rescheduled','cancelled')` (حاضر/غائب/متأخر/مؤجّلة/ملغاة).
  Drop the auto-named constraint, re-add as named `sessions_attendance_check`.
- Add columns: `topics text`, `homework text`, `rescheduled_to date`.
- Update `notify_session_change` trigger titles/bodies for `late` + `cancelled`.
- Update `generate_report` attendance JSON with `late` + `cancelled` counts
  (and treat nothing as present: keep distinct buckets).
- Update `parent_portal` attendance JSON: buckets + `rescheduled_to`, `topics`,
  `homework` in the recent list.
- `notes` stays `on delete set null` for sessions; no FK changes needed.

### A2. Model + API
- `LessonSession`: add `topics`, `homework`, `rescheduledTo` (fromJson/toJson).
- `recordAttendance(...)`: accept note/topics/homework/rescheduledTo (upsert).
- `updateLesson(...)`: extend with topics/homework/rescheduledTo.
- New `deleteLesson(id)` — the UNDO primitive (clears the attendance row).

### A3. Today tab (home_screen.dart) — richer tiles + undo
- Summary strip: «اليوم: 4 جلسات • 1 مسجّلة • 3 متبقية».
- `_SessionTile` v2: student avatar initial, name, subject chip, time block,
  location, status chip OR «لم يُسجَّل بعد»; tap anywhere → Session Detail sheet.
- Quick mark row (only while unrecorded): 5 compact icon buttons
  (حاضر/غائب/متأخر/مؤجّلة/ملغاة). After marking: SnackBar «تم التسجيل» with
  action **تراجع** → `deleteLesson` → back to unrecorded.
- Recorded tile: status chip + small edit icon; tap → detail sheet
  (change state, note, topics, homework, undo).

### A4. Session Detail sheet (new shared widget — Today, Schedule, Students)
- Header: student · subject · time · location · date.
- State picker (5 SegmentedButtons with colors).
- If مؤجّلة: date picker → rescheduled_to.
- Fields: الموضوع المُنجز (topics) / الواجب (homework) / ملاحظات (note).
- Primary: حفظ (upsert or update). Secondary: مسح التسجيل (confirm) + إلغاء.

### A5. Schedule screen
- `_attendanceStyle` extended to 5 states (icons/colors).
- Tap a recorded lesson row → same SessionDetailSheet.

## Part B — Announcements & Notifications (الإعلانات والإشعارات)

### Current problems (verified)
1. Announcements: body-only, bottom-sheet compose, no title, no audience, no
   pin, no expiry, no management UI (delete exists only in API).
2. Trigger notifies only non-manager teachers («إعلان جديد»), parents see the
   last 5 via `parent_portal` — no audience control.
3. Notification center: flat list, no filters, no per-row actions, only mark
   read on tap + mark-all-read; no category settings.
4. Notification `type` enum exists (attendance/note/test/fee/payment/announcement/
   teacher/general) but is not filterable/settable.

### B1. DB — migration `20260916xxxx_announcements_notifications_upgrade.sql`
- `announcements` += `title text`, `audience text not null default 'all'
  check (audience in ('all','parents','teachers'))`, `pinned boolean not null
  default false`, `expires_at timestamptz`.
- `notify_announcement` trigger: fire only when audience in ('all','teachers')
  AND (expires_at is null or expires_at > now()).
- `parent_portal` announcements list: audience in ('all','parents') AND not
  expired, pinned first then newest; include title.
- New `notification_prefs` table: user_id uuid pk → profiles, one boolean per
  category (attendance, note, test, fee, payment, announcement, teacher,
  general), updated_at. RLS: own row select/upsert. API: getPreferened async +
  `upsertNotificationPrefs(map)`.

### B2. Announcement compose (full screen, replaces bottom sheet)
- Title (optional) + body (required, min 3).
- Audience segmented: الجميع / أولياء الأمور فقط / المدرّسون فقط.
- Pin toggle «تثبيت في الأعلى».
- Expiry picker (اختياري — بدون انتهاء).
- Edit mode prefills; Save → create/update, invalidate providers.

### B3. Announcements management
- Dedicated `AnnouncementsScreen` (entry: Home card «إدارة» + FAB):
  pinned section first, then newest; each row: title/body, chips (الجمهور,
  مثبَّت, منتهي), date; popup menu: تعديل / حذف (confirm) / تثبيت أو إلغاء.
- Home card footer: «إدارة الإعلانات» instead of bare add.

### B4. Notification center upgrade
- Filter chips: الكل + each type present in the list (client-side).
- Row popup (⋮): تعليم كمقروء / كغير مقروء / حذف (confirm).
- AppBar: تعليم الكل كمقروء + مسح الكل (confirm).
- Badge + refresh preserved; empty state per-filter.

### B5. Notification settings (Settings screen)
- «إعدادات الإشعارات» section: 8 category toggles, persisted to
  notification_prefs; derived provider filters `teacherNotificationsProvider`
  client-side; Home badge + center reflect prefs.

## Validation
- `flutter analyze` 0 issues; `flutter test` (new tests: 5-state mapper,
  undo/deleteLesson, detail-sheet save, prefs filter, compose validation).
- Migration pushed via `supabase db push --yes`; REST smoke for new columns +
  trigger behavior for late/cancelled + announcement audience.
- Build split-per-ABI APK + web; Chrome MCP verify Today tab, undo snackbar,
  session sheet, announcements manage, notif filters/settings.
- Release v1.1.4 + app_meta bump + GitHub Release; memory events.

## Risks / notes
- Changing the attendance enum does NOT touch old rows (all values still valid).
- `select=id` REST on composite-PK tables 400s — use `select=*` when verifying.
- No new packages needed (Material widgets only).
- Schedule/Students screens stay consistent via the shared detail sheet.