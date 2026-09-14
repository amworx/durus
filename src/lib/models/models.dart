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
    this.recordedBy,
    this.createdAt,
  });

  final String id;
  final String schoolId;
  final String studentId;
  final String? subjectId;
  final String? slotId;
  final String date; // 'YYYY-MM-DD'
  final String attendance; // 'present' | 'absent' | 'rescheduled'
  final String? note;
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
    required this.body,
    this.createdAt,
  });

  final String id;
  final String schoolId;
  final String? authorId;
  final String body;
  final DateTime? createdAt;

  factory Announcement.fromJson(Map<String, dynamic> json) => Announcement(
        id: json['id'] as String,
        schoolId: json['school_id'] as String,
        authorId: json['author_id'] as String?,
        body: json['body'] as String,
        createdAt: _parseTs(json['created_at']),
      );

  Map<String, dynamic> toJson() {
    final created = createdAt;
    return {
      'id': id,
      'school_id': schoolId,
      if (authorId != null) 'author_id': authorId,
      'body': body,
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
    this.rescheduled = 0,
  });

  final int total;
  final int present;
  final int absent;
  final int rescheduled;

  double get presentPercent => total == 0 ? 0 : (present / total * 100);

  factory AttendanceSummary.fromJson(Map<String, dynamic> json) =>
      AttendanceSummary(
        total: json['total'] as int? ?? 0,
        present: json['present'] as int? ?? 0,
        absent: json['absent'] as int? ?? 0,
        rescheduled: json['rescheduled'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'total': total,
        'present': present,
        'absent': absent,
        'rescheduled': rescheduled,
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