import 'package:flutter/material.dart';

import 'package:durus/l10n/app_localizations.dart';

/// Visual identity (label / color / icon) for one attendance state.
class AttendanceStyle {
  const AttendanceStyle({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;
}

/// Single source of truth for the 5 attendance states used by Today, Schedule,
/// Students, the monthly report and the parent portal.
AttendanceStyle attendanceStyle(
  AppLocalizations l10n,
  ColorScheme scheme,
  String attendance,
) {
  return switch (attendance) {
    'present' => AttendanceStyle(
        label: l10n.homeMarkPresent,
        color: const Color(0xFF2E7D32),
        icon: Icons.check_circle_outline,
      ),
    'absent' => AttendanceStyle(
        label: l10n.homeMarkAbsent,
        color: scheme.error,
        icon: Icons.cancel_outlined,
      ),
    'late' => AttendanceStyle(
        label: l10n.homeMarkLate,
        color: const Color(0xFFF9A825),
        icon: Icons.schedule,
      ),
    'rescheduled' => AttendanceStyle(
        label: l10n.homeMarkRescheduled,
        color: const Color(0xFFEF6C00),
        icon: Icons.event_repeat,
      ),
    'cancelled' => AttendanceStyle(
        label: l10n.homeMarkCancelled,
        color: Colors.blueGrey,
        icon: Icons.block,
      ),
    _ => AttendanceStyle(
        label: attendance,
        color: scheme.outline,
        icon: Icons.help_outline,
      ),
  };
}

/// The 5 states in display order (quick-mark rows + detail picker).
const List<String> kAttendanceStates = [
  'present',
  'absent',
  'late',
  'rescheduled',
  'cancelled',
];