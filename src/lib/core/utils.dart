import 'dart:math';

/// Cryptographically random UUID v4 string (RFC 4122, version 4, variant 10).
String makeUuid() {
  final r = Random.secure();
  final bytes = List<int>.generate(16, (_) => r.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40; // version 4
  bytes[8] = (bytes[8] & 0x3f) | 0x80; // variant 10
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}

/// 'yyyy-MM' key for a month, zero-padded (e.g. '2026-09').
String monthKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}';

/// Picks the family id when linking students: reuses the first existing
/// family id (implicitly merging families), else mints a fresh one.
String resolveFamilyId(List<String?> existing) {
  for (final id in existing) {
    if (id != null && id.isNotEmpty) return id;
  }
  return makeUuid();
}

/// Portal excuse rule: a date is excusable only if the student has a
/// recorded session on it or an active slot on its weekday. Pure so the
/// date picker and the (mirrored) server guard stay in sync by design.
bool isExcusableDay({
  required String iso,
  required int weekday,
  required Set<String> sessionDates,
  required Set<int> slotWeekdays,
}) {
  if (sessionDates.contains(iso)) return true;
  return slotWeekdays.contains(weekday);
}

/// September-rollover helper: next school grade, or null when the grade
/// is unknown (typo) or terminal (السادس graduates manually, never auto).
String? promoteGrade(String grade) {
  const order = ['الأول', 'الثاني', 'الثالث', 'الرابع', 'الخامس', 'السادس'];
  final i = order.indexOf(grade.trim());
  if (i < 0 || i >= order.length - 1) return null;
  return order[i + 1];
}

/// Arabic school-grade ordinal (الأول=1 .. السادس=6), or null when the
/// grade is empty/unknown. Shared by promotion and cross-grade checks.
int? gradeOrdinal(String? grade) {
  if (grade == null) return null;
  const order = ['الأول', 'الثاني', 'الثالث', 'الرابع', 'الخامس', 'السادس'];
  final i = order.indexOf(grade.trim());
  return i < 0 ? null : i + 1;
}

/// True when a subject fits a student's grade. Either side unknown means
/// "can't judge" (allowed — the caller warns only on known mismatches so
/// legitimate cross-grade revision still works with confirmation).
bool gradesCompatible({String? studentGrade, String? subjectGrade}) {
  final s = gradeOrdinal(studentGrade);
  final g = gradeOrdinal(subjectGrade);
  if (s == null || g == null) return true;
  return s == g;
}

/// 'yyyy-MM-dd' for a DateTime (PostgREST date column format).
String isoDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

int minutesOfDay(int hour, int minute) => hour * 60 + minute;

/// 'HH:mm' from minutes since midnight (1440 -> '24:00').
String timeFromMinutes(int m) {
  final h = (m ~/ 60).toString().padLeft(2, '0');
  final min = (m % 60).toString().padLeft(2, '0');
  return '$h:$min';
}

const List<String> arabicMonths = [
  'يناير',
  'فبراير',
  'مارس',
  'أبريل',
  'مايو',
  'يونيو',
  'يوليو',
  'أغسطس',
  'سبتمبر',
  'أكتوبر',
  'نوفمبر',
  'ديسمبر',
];

/// Indexed by `DateTime.weekday - 1` (1 = Monday).
const List<String> arabicWeekdays = [
  'الاثنين',
  'الثلاثاء',
  'الأربعاء',
  'الخميس',
  'الجمعة',
  'السبت',
  'الأحد',
];

/// 'dd/MM/yyyy'.
String fmtDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

/// 'yyyy-MM' -> 'سبتمبر 2026'; returns the input unchanged if unparseable.
String fmtMonthKey(String key) {
  final parts = key.split('-');
  if (parts.length != 2) {
    return key;
  }
  final year = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  if (year == null || month == null || month < 1 || month > 12) {
    return key;
  }
  return '${arabicMonths[month - 1]} $year';
}

/// True when [latest] is a newer semantic version (x.y.z) than [current].
/// Non-numeric segments are ignored; missing segments count as 0.
bool isNewerVersion(String latest, String current) {
  List<int> parts(String v) => v
      .split('.')
      .map((p) => int.tryParse(p.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0)
      .toList();
  final l = parts(latest);
  final c = parts(current);
  final maxLen = l.length > c.length ? l.length : c.length;
  for (var i = 0; i < maxLen; i++) {
    final a = i < l.length ? l[i] : 0;
    final b = i < c.length ? c[i] : 0;
    if (a != b) return a > b;
  }
  return false;
}