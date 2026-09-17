/// Data models mirroring the PostgREST API (snake_case keys on the wire,
/// camelCase in Dart).
///
/// Every model exposes a [fromJson] (snake_case -> camelCase) and a [toJson]
/// (camelCase -> snake_case) that includes `school_id` and all NOT-NULL
/// fields. Date-only DB columns (`date`, `paid_at`, `due_date`) travel as
/// `'YYYY-MM-DD'` strings; timestamps (`created_at`, `accepted_at`) are parsed
/// from ISO-8601 into [DateTime]?. Money fields are [double].

library;

DateTime? _parseTs(dynamic v) => v is String ? DateTime.tryParse(v) : null;

List<T> _jsonList<T>(dynamic v, T Function(Map<String, dynamic>) fromJson) =>
    (v as List<dynamic>?)
            ?.map((e) => fromJson(e as Map<String, dynamic>))
            .toList() ??
    const [];

class Profile {
  const Profile({
    required this.id,
    required this.email,
    this.fullName,
    this.role = 'teacher',
    this.isManager = false,
    this.managerId,
    this.schoolId,
    this.onboarded = false,
    this.active = true,
    this.bio,
    this.phone,
    this.avatarTheme = 'fatin-verse',
    this.avatarGender,
    this.avatarSeed,
  });

  final String id;
  final String email;
  final String? fullName;
  final String role;
  final bool isManager;
  final String? managerId;
  final String? schoolId;
  final bool onboarded;

  /// Whether a teacher account is enabled (manager can disable).
  final bool active;

  /// Free-text teacher details, editable by the teacher.
  final String? bio;
  final String? phone;

  /// Avatune style key ('fatin-verse' | 'yanliu' | 'micah').
  final String avatarTheme;

  /// 'm' | 'f' | null (null = neutral style, uses [avatarTheme]).
  final String? avatarGender;

  /// Custom shuffle seed; null falls back to the profile id.
  final String? avatarSeed;

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        id: json['id'] as String,
        email: json['email'] as String,
        fullName: json['full_name'] as String?,
        role: json['role'] as String? ?? 'teacher',
        isManager: json['is_manager'] as bool? ?? false,
        managerId: json['manager_id'] as String?,
        schoolId: json['school_id'] as String?,
        onboarded: json['onboarded'] as bool? ?? false,
        active: json['active'] as bool? ?? true,
        bio: json['bio'] as String?,
        phone: json['phone'] as String?,
        avatarTheme: json['avatar_theme'] as String? ?? 'fatin-verse',
        avatarGender: json['avatar_gender'] as String?,
        avatarSeed: json['avatar_seed'] as String?,
      );

  /// Only the fields the user may update about themselves.
  Map<String, dynamic> toJson() => {
        if (fullName != null) 'full_name': fullName,
      };
}

class Subject {
  const Subject({
    required this.id,
    required this.schoolId,
    required this.name,
    this.grade,
    this.notes,
    this.createdAt,
  });

  final String id;
  final String schoolId;
  final String name;
  final String? grade;
  final String? notes;
  final DateTime? createdAt;

  /// Human label for pickers/lists: the name plus the grade when present.
  /// Same names can exist for different grades (e.g. Arabic 1st vs 2nd), so
  /// surfaces must never show the bare name alone.
  String get displayLabel {
    final g = grade;
    return (g == null || g.isEmpty) ? name : '$name — $g';
  }

  factory Subject.fromJson(Map<String, dynamic> json) => Subject(
        id: json['id'] as String,
        schoolId: json['school_id'] as String,
        name: json['name'] as String,
        grade: json['grade'] as String?,
        notes: json['notes'] as String?,
        createdAt: _parseTs(json['created_at']),
      );

  Map<String, dynamic> toJson() {
    final created = createdAt;
    return {
      'id': id,
      'school_id': schoolId,
      'name': name,
      if (grade != null) 'grade': grade,
      if (notes != null) 'notes': notes,
      if (created != null) 'created_at': created.toIso8601String(),
    };
  }
}

class Student {
  const Student({
    required this.id,
    required this.schoolId,
    required this.name,
    this.grade,
    this.birthYear,
    this.defaultLocation = 'student_home',
    required this.assignedTeacherId,
    this.parentName,
    this.parentPhone,
    this.parentToken,
    this.parentRelation,
    this.familyId,
    this.status = 'active',
    this.notes,
    this.createdAt,
  });

  final String id;
  final String schoolId;
  final String name;
  final String? grade;
  final int? birthYear;
  final String defaultLocation;
  final String assignedTeacherId;
  final String? parentName;
  final String? parentPhone;
  final String? parentToken;
  /// Guardian kinship (أب/أم/أخ/...), free text from preset labels.
  final String? parentRelation;
  /// Manual family link: siblings share one id; null = unlinked.
  final String? familyId;
  /// Lifecycle: active | paused | dropped | graduated. History is never
  /// touched by status changes — only lists and the schedule filter on it.
  final String status;
  final String? notes;
  final DateTime? createdAt;

  factory Student.fromJson(Map<String, dynamic> json) => Student(
        id: json['id'] as String,
        schoolId: json['school_id'] as String,
        name: json['name'] as String,
        grade: json['grade'] as String?,
        birthYear: json['birth_year'] as int?,
        defaultLocation: json['default_location'] as String? ?? 'student_home',
        assignedTeacherId: json['assigned_teacher_id'] as String,
        parentName: json['parent_name'] as String?,
        parentPhone: json['parent_phone'] as String?,
        parentToken: json['parent_token'] as String?,
        parentRelation: json['parent_relation'] as String?,
        familyId: json['family_id'] as String?,
        status: json['status'] as String? ?? 'active',
        notes: json['notes'] as String?,
        createdAt: _parseTs(json['created_at']),
      );

  Map<String, dynamic> toJson() {
    final created = createdAt;
    return {
      'id': id,
      'school_id': schoolId,
      'name': name,
      if (grade != null) 'grade': grade,
      if (birthYear != null) 'birth_year': birthYear,
      'default_location': defaultLocation,
      'assigned_teacher_id': assignedTeacherId,
      if (parentName != null) 'parent_name': parentName,
      if (parentPhone != null) 'parent_phone': parentPhone,
      if (parentToken != null) 'parent_token': parentToken,
      if (parentRelation != null) 'parent_relation': parentRelation,
      if (familyId != null) 'family_id': familyId,
      'status': status,
      if (notes != null) 'notes': notes,
      if (created != null) 'created_at': created.toIso8601String(),
    };
  }
}

/// Join-table row between a student and a subject (no id column).
class StudentSubjectRef {
  const StudentSubjectRef({required this.studentId, required this.subjectId});

  final String studentId;
  final String subjectId;

  factory StudentSubjectRef.fromJson(Map<String, dynamic> json) =>
      StudentSubjectRef(
        studentId: json['student_id'] as String,
        subjectId: json['subject_id'] as String,
      );

  Map<String, dynamic> toJson() => {
        'student_id': studentId,
        'subject_id': subjectId,
      };
}

class RecurringSlot {
  const RecurringSlot({
    required this.id,
    required this.schoolId,
    required this.studentId,
    this.subjectId,
    required this.dayOfWeek,
    required this.startMinutes,
    required this.endMinutes,
    this.location = 'student_home',
    required this.teacherId,
    this.active = true,
    this.createdAt,
  });

  final String id;
  final String schoolId;
  final String studentId;
  final String? subjectId;
  final int dayOfWeek; // DateTime.weekday: 1 = Mon .. 7 = Sun
  final int startMinutes;
  final int endMinutes;
  final String location;
  final String teacherId;
  final bool active;
  final DateTime? createdAt;

  factory RecurringSlot.fromJson(Map<String, dynamic> json) => RecurringSlot(
        id: json['id'] as String,
        schoolId: json['school_id'] as String,
        studentId: json['student_id'] as String,
        subjectId: json['subject_id'] as String?,
        dayOfWeek: json['day_of_week'] as int,
        startMinutes: json['start_minutes'] as int,
        endMinutes: json['end_minutes'] as int,
        location: json['location'] as String? ?? 'student_home',
        teacherId: json['teacher_id'] as String,
        active: json['active'] as bool? ?? true,
        createdAt: _parseTs(json['created_at']),
      );

  Map<String, dynamic> toJson() {
    final created = createdAt;
    return {
      'id': id,
      'school_id': schoolId,
      'student_id': studentId,
      if (subjectId != null) 'subject_id': subjectId,
      'day_of_week': dayOfWeek,
      'start_minutes': startMinutes,
      'end_minutes': endMinutes,
      'location': location,
      'teacher_id': teacherId,
      'active': active,
      if (created != null) 'created_at': created.toIso8601String(),
    };
  }
}

/// One recorded lesson / attendance row. Named `LessonSession` to avoid the
/// clash with supabase's own `Session`.
class LessonSession {
  const LessonSession({
    required this.id,
    required this.schoolId,
    required this.studentId,
    this.subjectId,
    this.slotId,
    required this.date,
    required this.attendance,
    this.note,
    this.topics,
    this.homework,
    this.rescheduledTo,
    this.recordedBy,
    this.createdAt,
  });

  final String id;
  final String schoolId;
  final String studentId;
  final String? subjectId;
  final String? slotId;
  final String date; // 'YYYY-MM-DD'
  // 'present' | 'absent' | 'late' | 'rescheduled' | 'cancelled'
  final String attendance;
  final String? note;
  final String? topics; // الموضوع المُنجز
  final String? homework; // الواجب
  final String? rescheduledTo; // 'YYYY-MM-DD' when مؤجّلة
  final String? recordedBy;
  final DateTime? createdAt;

  factory LessonSession.fromJson(Map<String, dynamic> json) => LessonSession(
        id: json['id'] as String,
        schoolId: json['school_id'] as String,
        studentId: json['student_id'] as String,
        subjectId: json['subject_id'] as String?,
        slotId: json['slot_id'] as String?,
        date: json['date'] as String,
        attendance: json['attendance'] as String,
        note: json['note'] as String?,
        topics: json['topics'] as String?,
        homework: json['homework'] as String?,
        rescheduledTo: json['rescheduled_to'] as String?,
        recordedBy: json['recorded_by'] as String?,
        createdAt: _parseTs(json['created_at']),
      );

  Map<String, dynamic> toJson() {
    final created = createdAt;
    return {
      'id': id,
      'school_id': schoolId,
      'student_id': studentId,
      if (subjectId != null) 'subject_id': subjectId,
      if (slotId != null) 'slot_id': slotId,
      'date': date,
      'attendance': attendance,
      if (note != null) 'note': note,
      if (topics != null) 'topics': topics,
      if (homework != null) 'homework': homework,
      if (rescheduledTo != null) 'rescheduled_to': rescheduledTo,
      if (recordedBy != null) 'recorded_by': recordedBy,
      if (created != null) 'created_at': created.toIso8601String(),
    };
  }
}

class Fee {
  const Fee({
    required this.id,
    required this.schoolId,
    required this.studentId,
    required this.month,
    this.amount = 0,
    this.paidAmount = 0,
    this.status = 'unpaid',
    this.dueDate,
    this.notes,
    this.createdAt,
  });

  final String id;
  final String schoolId;
  final String studentId;
  final String month; // 'YYYY-MM'
  final double amount;
  final double paidAmount;
  final String status; // 'unpaid' | 'partial' | 'paid'
  final String? dueDate; // 'YYYY-MM-DD'
  final String? notes;
  final DateTime? createdAt;

  factory Fee.fromJson(Map<String, dynamic> json) => Fee(
        id: json['id'] as String,
        schoolId: json['school_id'] as String,
        studentId: json['student_id'] as String,
        month: json['month'] as String,
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        paidAmount: (json['paid_amount'] as num?)?.toDouble() ?? 0,
        status: json['status'] as String? ?? 'unpaid',
        dueDate: json['due_date'] as String?,
        notes: json['notes'] as String?,
        createdAt: _parseTs(json['created_at']),
      );

  Map<String, dynamic> toJson() {
    final created = createdAt;
    return {
      'id': id,
      'school_id': schoolId,
      'student_id': studentId,
      'month': month,
      'amount': amount,
      'paid_amount': paidAmount,
      'status': status,
      if (dueDate != null) 'due_date': dueDate,
      if (notes != null) 'notes': notes,
      if (created != null) 'created_at': created.toIso8601String(),
    };
  }
}

class Payment {
  const Payment({
    required this.id,
    required this.schoolId,
    required this.feeId,
    required this.studentId,
    required this.amount,
    required this.paidAt,
    this.method = 'cash',
    this.note,
    this.createdAt,
  });

  final String id;
  final String schoolId;
  final String feeId;
  final String studentId;
  final double amount;
  final String paidAt; // 'YYYY-MM-DD'
  final String method; // 'cash' | 'transfer' | 'other'
  final String? note;
  final DateTime? createdAt;

  factory Payment.fromJson(Map<String, dynamic> json) => Payment(
        id: json['id'] as String,
        schoolId: json['school_id'] as String,
        feeId: json['fee_id'] as String,
        studentId: json['student_id'] as String,
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        paidAt: json['paid_at'] as String,
        method: json['method'] as String? ?? 'cash',
        note: json['note'] as String?,
        createdAt: _parseTs(json['created_at']),
      );

  Map<String, dynamic> toJson() {
    final created = createdAt;
    return {
      'id': id,
      'school_id': schoolId,
      'fee_id': feeId,
      'student_id': studentId,
      'amount': amount,
      'paid_at': paidAt,
      'method': method,
      if (note != null) 'note': note,
      if (created != null) 'created_at': created.toIso8601String(),
    };
  }
}

/// Latest published release for the in-app update check (version compared
/// against `AppConfig.appVersion`).
///
/// Sources: the global `app_meta.latest_release` row (curated, primary) and
/// the GitHub Releases API (auto-detected). [apkUrl] points at a concrete APK
/// asset when one is known; on Android it enables in-app download + install.
class AppRelease {
  const AppRelease({
    required this.version,
    required this.url,
    this.notes = '',
    this.apkUrl,
  });

  final String version;
  final String url;
  final String notes;
  final String? apkUrl;

  factory AppRelease.fromJson(Map<String, dynamic> json) => AppRelease(
        version: json['version'] as String? ?? '',
        url: json['url'] as String? ?? '',
        notes: json['notes'] as String? ?? '',
        apkUrl: json['apk_url'] as String?,
      );

  /// Parses a GitHub Releases API object (`/releases/latest`). The tag becomes
  /// the version (leading `v` stripped), the release page becomes [url], and
  /// the APK asset (arm64 preferred, then any `.apk`) becomes [apkUrl].
  /// Long release notes are truncated so they stay readable in Settings.
  factory AppRelease.fromGitHubJson(Map<String, dynamic> json) {
    final tag = json['tag_name'] as String? ?? '';
    final version = tag.startsWith('v') ? tag.substring(1) : tag;
    final url = json['html_url'] as String? ?? '';
    final body = ((json['body'] as String?) ?? '').trim();
    final notes = body.length <= 400 ? body : '${body.substring(0, 400)}…';

    String? apkUrl;
    final assets = json['assets'] as List<dynamic>? ?? const [];
    for (final asset in assets) {
      if (asset is! Map<String, dynamic>) continue;
      final name = asset['name'] as String? ?? '';
      final downloadUrl = asset['browser_download_url'] as String? ?? '';
      if (!name.endsWith('.apk') || downloadUrl.isEmpty) continue;
      if (name.contains('arm64')) {
        apkUrl = downloadUrl;
        break;
      }
      apkUrl ??= downloadUrl;
    }

    return AppRelease(
      version: version,
      url: url,
      notes: notes,
      apkUrl: apkUrl,
    );
  }
}

/// A test result. Named `TestResult` to avoid clashing with `flutter_test`.
class TestResult {
  const TestResult({
    required this.id,
    required this.schoolId,
    required this.studentId,
    this.subjectId,
    this.type = 'monthly',
    required this.date,
    this.score,
    this.maxScore,
    this.note,
    this.createdAt,
  });

  final String id;
  final String schoolId;
  final String studentId;
  final String? subjectId;
  final String type; // 'monthly' | 'midterm' | 'final' | 'quiz' | 'other'
  final String date; // 'YYYY-MM-DD'
  final double? score;
  final double? maxScore;
  final String? note;
  final DateTime? createdAt;

  factory TestResult.fromJson(Map<String, dynamic> json) => TestResult(
        id: json['id'] as String,
        schoolId: json['school_id'] as String,
        studentId: json['student_id'] as String,
        subjectId: json['subject_id'] as String?,
        type: json['type'] as String? ?? 'monthly',
        date: json['date'] as String,
        score: (json['score'] as num?)?.toDouble(),
        maxScore: (json['max_score'] as num?)?.toDouble(),
        note: json['note'] as String?,
        createdAt: _parseTs(json['created_at']),
      );

  Map<String, dynamic> toJson() {
    final created = createdAt;
    return {
      'id': id,
      'school_id': schoolId,
      'student_id': studentId,
      if (subjectId != null) 'subject_id': subjectId,
      'type': type,
      'date': date,
      if (score != null) 'score': score,
      if (maxScore != null) 'max_score': maxScore,
      if (note != null) 'note': note,
      if (created != null) 'created_at': created.toIso8601String(),
    };
  }
}

class LessonNote {
  const LessonNote({
    required this.id,
    required this.schoolId,
    required this.studentId,
    this.authorId,
    required this.body,
    this.sessionId,
    this.createdAt,
  });

  final String id;
  final String schoolId;
  final String studentId;
  final String? authorId;
  final String body;
  final String? sessionId;
  final DateTime? createdAt;

  factory LessonNote.fromJson(Map<String, dynamic> json) => LessonNote(
        id: json['id'] as String,
        schoolId: json['school_id'] as String,
        studentId: json['student_id'] as String,
        authorId: json['author_id'] as String?,
        body: json['body'] as String,
        sessionId: json['session_id'] as String?,
        createdAt: _parseTs(json['created_at']),
      );

  Map<String, dynamic> toJson() {
    final created = createdAt;
    return {
      'id': id,
      'school_id': schoolId,
      'student_id': studentId,
      if (authorId != null) 'author_id': authorId,
      'body': body,
      if (sessionId != null) 'session_id': sessionId,
      if (created != null) 'created_at': created.toIso8601String(),
    };
  }
}

class Announcement {
  const Announcement({
    required this.id,
    required this.schoolId,
    this.authorId,
    this.title,
    required this.body,
    this.audience = 'all',
    this.pinned = false,
    this.expiresAt,
    this.createdAt,
  });

  final String id;
  final String schoolId;
  final String? authorId;
  final String? title;
  final String body;
  final String audience; // 'all' | 'parents' | 'teachers'
  final bool pinned;
  final DateTime? expiresAt;
  final DateTime? createdAt;

  factory Announcement.fromJson(Map<String, dynamic> json) => Announcement(
        id: json['id'] as String,
        schoolId: json['school_id'] as String,
        authorId: json['author_id'] as String?,
        title: json['title'] as String?,
        body: json['body'] as String,
        audience: json['audience'] as String? ?? 'all',
        pinned: json['pinned'] as bool? ?? false,
        expiresAt: _parseTs(json['expires_at']),
        createdAt: _parseTs(json['created_at']),
      );

  Map<String, dynamic> toJson() {
    final created = createdAt;
    final expires = expiresAt;
    return {
      'id': id,
      'school_id': schoolId,
      if (authorId != null) 'author_id': authorId,
      if (title != null) 'title': title,
      'body': body,
      'audience': audience,
      'pinned': pinned,
      if (expires != null) 'expires_at': expires.toIso8601String(),
      if (created != null) 'created_at': created.toIso8601String(),
    };
  }
}

class Invitation {
  const Invitation({
    required this.id,
    required this.schoolId,
    required this.managerId,
    required this.token,
    this.email,
    this.status = 'pending',
    this.expiresAt,
    this.acceptedAt,
    this.createdAt,
  });

  final String id;
  final String schoolId;
  final String managerId;
  final String token;
  final String? email;
  final String status; // 'pending' | 'accepted' | 'revoked'
  final String? expiresAt; // ISO-8601 string as returned by PostgREST
  final DateTime? acceptedAt;
  final DateTime? createdAt;

  factory Invitation.fromJson(Map<String, dynamic> json) => Invitation(
        id: json['id'] as String,
        schoolId: json['school_id'] as String,
        managerId: json['manager_id'] as String,
        token: json['token'] as String,
        email: json['email'] as String?,
        status: json['status'] as String? ?? 'pending',
        expiresAt: json['expires_at'] as String?,
        acceptedAt: _parseTs(json['accepted_at']),
        createdAt: _parseTs(json['created_at']),
      );

  Map<String, dynamic> toJson() {
    final created = createdAt;
    final accepted = acceptedAt;
    return {
      'id': id,
      'school_id': schoolId,
      'manager_id': managerId,
      'token': token,
      if (email != null) 'email': email,
      'status': status,
      if (expiresAt != null) 'expires_at': expiresAt,
      if (accepted != null) 'accepted_at': accepted.toIso8601String(),
      if (created != null) 'created_at': created.toIso8601String(),
    };
  }
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.schoolId,
    required this.recipientType,
    required this.recipientId,
    required this.type,
    required this.title,
    this.body,
    this.isRead = false,
    this.createdAt,
  });

  final String id;
  final String schoolId;
  final String recipientType; // 'parent' | 'teacher'
  final String recipientId;
  final String type; // 'general' | 'attendance' | 'note' | 'test' | ...
  final String title;
  final String? body;
  final bool isRead;
  final DateTime? createdAt;

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: json['id'] as String,
        schoolId: json['school_id'] as String,
        recipientType: json['recipient_type'] as String,
        recipientId: json['recipient_id'] as String,
        type: json['type'] as String? ?? 'general',
        title: json['title'] as String,
        body: json['body'] as String?,
        isRead: json['is_read'] as bool? ?? false,
        createdAt: _parseTs(json['created_at']),
      );

  Map<String, dynamic> toJson() {
    final created = createdAt;
    return {
      'id': id,
      'school_id': schoolId,
      'recipient_type': recipientType,
      'recipient_id': recipientId,
      'type': type,
      'title': title,
      if (body != null) 'body': body,
      'is_read': isRead,
      if (created != null) 'created_at': created.toIso8601String(),
    };
  }
}

/// Attendance totals inside a monthly report.
class AttendanceSummary {
  const AttendanceSummary({
    this.total = 0,
    this.present = 0,
    this.absent = 0,
    this.late = 0,
    this.rescheduled = 0,
    this.cancelled = 0,
  });

  final int total;
  final int present;
  final int absent;
  final int late;
  final int rescheduled;
  final int cancelled;

  double get presentPercent => total == 0 ? 0 : (present / total * 100);

  factory AttendanceSummary.fromJson(Map<String, dynamic> json) =>
      AttendanceSummary(
        total: json['total'] as int? ?? 0,
        present: json['present'] as int? ?? 0,
        absent: json['absent'] as int? ?? 0,
        late: json['late'] as int? ?? 0,
        rescheduled: json['rescheduled'] as int? ?? 0,
        cancelled: json['cancelled'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'total': total,
        'present': present,
        'absent': absent,
        'late': late,
        'rescheduled': rescheduled,
        'cancelled': cancelled,
      };
}

/// Fee summary inside a monthly report (no row id — computed by the RPC).
class ReportFee {
  const ReportFee({
    this.month,
    this.amount = 0,
    this.paidAmount = 0,
    this.status = 'unpaid',
    this.dueDate,
  });

  final String? month;
  final double amount;
  final double paidAmount;
  final String status; // 'unpaid' | 'partial' | 'paid'
  final String? dueDate; // 'YYYY-MM-DD'

  double get remaining => amount - paidAmount;

  factory ReportFee.fromJson(Map<String, dynamic> json) => ReportFee(
        month: json['month'] as String?,
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        paidAmount: (json['paid_amount'] as num?)?.toDouble() ?? 0,
        status: json['status'] as String? ?? 'unpaid',
        dueDate: json['due_date'] as String?,
      );

  Map<String, dynamic> toJson() => {
        if (month != null) 'month': month,
        'amount': amount,
        'paid_amount': paidAmount,
        'status': status,
        if (dueDate != null) 'due_date': dueDate,
      };
}

/// A test row enriched with the subject name (report payloads).
class ReportTest {
  const ReportTest({
    this.subject = '',
    this.type = 'monthly',
    this.date,
    this.score,
    this.maxScore,
    this.note,
  });

  final String subject;
  final String type;
  final String? date; // 'YYYY-MM-DD'
  final double? score;
  final double? maxScore;
  final String? note;

  factory ReportTest.fromJson(Map<String, dynamic> json) => ReportTest(
        subject: json['subject'] as String? ?? '',
        type: json['type'] as String? ?? 'monthly',
        date: json['date'] as String?,
        score: (json['score'] as num?)?.toDouble(),
        maxScore: (json['max_score'] as num?)?.toDouble(),
        note: json['note'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'subject': subject,
        'type': type,
        if (date != null) 'date': date,
        if (score != null) 'score': score,
        if (maxScore != null) 'max_score': maxScore,
        if (note != null) 'note': note,
      };
}

/// A note row inside a monthly report (body + author date only).
class ReportNote {
  const ReportNote({required this.body, this.createdAt});

  final String body;
  final DateTime? createdAt;

  factory ReportNote.fromJson(Map<String, dynamic> json) => ReportNote(
        body: json['body'] as String? ?? '',
        createdAt: _parseTs(json['created_at']),
      );

  Map<String, dynamic> toJson() => {
        'body': body,
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      };
}

/// Monthly report generated server-side by the `generate_report` RPC.
class MonthlyReport {
  const MonthlyReport({
    this.studentId = '',
    this.studentName = '',
    this.grade = '',
    this.month = '',
    this.generatedAt,
    this.attendance = const AttendanceSummary(),
    this.fee,
    this.tests = const [],
    this.notes = const [],
  });

  final String studentId;
  final String studentName;
  final String grade;
  final String month; // 'YYYY-MM'
  final DateTime? generatedAt;
  final AttendanceSummary attendance;
  final ReportFee? fee;
  final List<ReportTest> tests;
  final List<ReportNote> notes;

  factory MonthlyReport.fromJson(Map<String, dynamic> json) => MonthlyReport(
        studentId: json['student_id'] as String? ?? '',
        studentName: json['student_name'] as String? ?? '',
        grade: json['grade'] as String? ?? '',
        month: json['month'] as String? ?? '',
        generatedAt: _parseTs(json['generated_at']),
        attendance: json['attendance'] is Map<String, dynamic>
            ? AttendanceSummary.fromJson(json['attendance'] as Map<String, dynamic>)
            : const AttendanceSummary(),
        fee: (json['fee'] is Map<String, dynamic> &&
                (json['fee'] as Map<String, dynamic>).isNotEmpty)
            ? ReportFee.fromJson(json['fee'] as Map<String, dynamic>)
            : null,
        tests: _jsonList(json['tests'], ReportTest.fromJson),
        notes: _jsonList(json['notes'], ReportNote.fromJson),
      );

  Map<String, dynamic> toJson() => {
        'student_id': studentId,
        'student_name': studentName,
        'grade': grade,
        'month': month,
        if (generatedAt != null) 'generated_at': generatedAt!.toIso8601String(),
        'attendance': attendance.toJson(),
        if (fee != null) 'fee': fee!.toJson(),
        'tests': tests.map((t) => t.toJson()).toList(),
        'notes': notes.map((n) => n.toJson()).toList(),
      };
}