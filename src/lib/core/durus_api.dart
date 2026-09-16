import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/models.dart';
import 'db.dart';
import 'updater.dart';
import 'utils.dart';

/// Typed service layer over the shared Supabase client (Auth + PostgREST +
/// RPCs). All mutating methods derive the caller's school from their profile.
class DurusApi {
  SupabaseClient get _c => db;

  // ---------- Auth ----------

  Stream<AuthState> authStream() => _c.auth.onAuthStateChange;

  Future<void> signIn(String email, String password) =>
      _c.auth.signInWithPassword(email: email, password: password);

  Future<void> signUp(String email, String password, String fullName) =>
      _c.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
      );

  /// Sends a password-reset email. GoTrue returns success regardless of
  /// whether the account exists (no user enumeration).
  Future<void> resetPassword(String email) =>
      _c.auth.resetPasswordForEmail(email);

  Future<void> signOut() => _c.auth.signOut();

  // ---------- Profile / school ----------

  Future<Profile?> currentProfile() async {
    final uid = currentUserId();
    if (uid == null) {
      return null;
    }
    final data =
        await _c.from('profiles').select().eq('id', uid).maybeSingle();
    if (data is Map<String, dynamic>) {
      return Profile.fromJson(data);
    }
    return null;
  }

  Future<String?> mySchoolId() async {
    final p = await currentProfile();
    if (p == null) {
      return null;
    }
    return p.isManager ? p.id : p.managerId;
  }

  Future<void> completeOnboarding(String fullName, {required bool isManager}) =>
      _c.rpc(
        'complete_onboarding',
        params: {'p_full_name': fullName, 'p_is_manager': isManager},
      );

  Future<void> acceptInvitation(String token) =>
      _c.rpc('accept_invitation', params: {'p_token': token});

  // ---------- Teachers / invites (manager) ----------

  Future<List<Profile>> teachers() async {
    final school = await _schoolIdOrThrow();
    final uid = currentUserId();
    final filtered = _c
        .from('profiles')
        .select()
        .eq('school_id', school);
    final q = uid != null ? filtered.neq('id', uid) : filtered;
    return _mapList(
      await q.order('full_name', ascending: true),
      Profile.fromJson,
    );
  }

  Future<String> createTeacher(String email, String password, String fullName) async {
    final res = await _c.rpc(
      'create_teacher_with_credentials',
      params: {
        'p_email': email,
        'p_password': password,
        'p_full_name': fullName,
      },
    );
    // A scalar-returning RPC comes back as the raw value; some PostgREST
    // versions wrap it in an object keyed by the function name.
    if (res is String) {
      return res;
    }
    if (res is Map && res['create_teacher_with_credentials'] is String) {
      return res['create_teacher_with_credentials'] as String;
    }
    throw StateError('unexpected_rpc_response');
  }

  Future<Invitation> createInvitation({String? email}) async {
    final school = await _schoolIdOrThrow();
    final data = await _c
        .from('invitations')
        .insert({
          'school_id': school,
          'manager_id': _uidOrThrow(),
          'email': ?email,
        })
        .select()
        .single();
    return Invitation.fromJson(data);
  }

  Future<List<Invitation>> invitations() async => _mapList(
        await _c
            .from('invitations')
            .select()
            .order('created_at', ascending: false),
        Invitation.fromJson,
      );

  Future<void> revokeInvitation(String id) async {
    await _c.from('invitations').delete().eq('id', id);
  }

  /// Manager toggles a teacher's `active` flag via the security-definer RPC.
  Future<void> setTeacherActive(String teacherId, bool active) async {
    await _c.rpc(
      'set_teacher_active',
      params: {'p_teacher': teacherId, 'p_active': active},
    );
  }

  // ---------- Subjects ----------

  Future<List<Subject>> subjects() async => _mapList(
      await _c.from('subjects').select().order('name', ascending: true),
      Subject.fromJson,
    );

  Future<void> createSubject(String name, {String? grade, String? notes}) async {
    final school = await _schoolIdOrThrow();
    await _c.from('subjects').insert({
      'school_id': school,
      'name': name,
      'grade': ?grade,
      'notes': ?notes,
    });
  }

  Future<void> updateSubject(
    String id, {
    required String name,
    String? grade,
    String? notes,
  }) async {
    await _c.from('subjects').update({
      'name': name,
      'grade': ?grade,
      'notes': ?notes,
    }).eq('id', id);
  }

  Future<void> deleteSubject(String id) async {
    await _c.from('subjects').delete().eq('id', id);
  }

  // ---------- Students ----------

  Future<List<Student>> students() async => _mapList(
      await _c.from('students').select().order('name', ascending: true),
      Student.fromJson,
    );

  Future<Student> createStudent({
    required String name,
    String? grade,
    int? birthYear,
    String defaultLocation = 'student_home',
    String? assignedTeacherId,
    String? parentName,
    String? parentPhone,
    String? notes,
  }) async {
    final school = await _schoolIdOrThrow();
    final data = await _c
        .from('students')
        .insert({
          'school_id': school,
          'name': name,
          'grade': ?grade,
          'birth_year': ?birthYear,
          'default_location': defaultLocation,
          'assigned_teacher_id': assignedTeacherId ?? _uidOrThrow(),
          'parent_name': ?parentName,
          'parent_phone': ?parentPhone,
          'notes': ?notes,
        })
        .select()
        .single();
    return Student.fromJson(data);
  }

  Future<void> updateStudent(
    String id, {
    String? name,
    String? grade,
    int? birthYear,
    String? defaultLocation,
    String? assignedTeacherId,
    String? parentName,
    String? parentPhone,
    String? notes,
  }) async {
    await _c.from('students').update({
      'name': ?name,
      'grade': ?grade,
      'birth_year': ?birthYear,
      'default_location': ?defaultLocation,
      'assigned_teacher_id': ?assignedTeacherId,
      'parent_name': ?parentName,
      'parent_phone': ?parentPhone,
      'notes': ?notes,
    }).eq('id', id);
  }

  Future<void> deleteStudent(String id) async {
    await _c.from('students').delete().eq('id', id);
  }

  Future<String> ensureParentToken(String studentId) async {
    final data = await _c
        .from('students')
        .select('parent_token')
        .eq('id', studentId)
        .maybeSingle();
    final existing =
        data is Map<String, dynamic> ? data['parent_token'] as String? : null;
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }
    final token = makeUuid();
    await _c.from('students').update({'parent_token': token}).eq('id', studentId);
    return token;
  }

  Future<List<StudentSubjectRef>> studentSubjectRefs() async => _mapList(
        await _c.from('student_subjects').select(),
        StudentSubjectRef.fromJson,
      );

  Future<void> setStudentSubjects(
    String studentId,
    List<String> subjectIds,
  ) async {
    await _c.from('student_subjects').delete().eq('student_id', studentId);
    if (subjectIds.isEmpty) {
      return;
    }
    await _c.from('student_subjects').insert(
      subjectIds
          .map((id) => {'student_id': studentId, 'subject_id': id})
          .toList(),
    );
  }

  // ---------- Schedule ----------

  Future<List<RecurringSlot>> slots() async => _mapList(
        await _c
            .from('recurring_slots')
            .select()
            .order('day_of_week', ascending: true),
        RecurringSlot.fromJson,
      );

  Future<void> createSlot({
    required String studentId,
    String? subjectId,
    required int dayOfWeek,
    required int startMinutes,
    required int endMinutes,
    String location = 'student_home',
  }) async {
    final school = await _schoolIdOrThrow();
    await _c.from('recurring_slots').insert({
      'school_id': school,
      'student_id': studentId,
      'subject_id': ?subjectId,
      'day_of_week': dayOfWeek,
      'start_minutes': startMinutes,
      'end_minutes': endMinutes,
      'location': location,
      'teacher_id': _uidOrThrow(),
      'active': true,
    });
  }

  Future<void> updateSlot(
    String id, {
    int? dayOfWeek,
    int? startMinutes,
    int? endMinutes,
    String? location,
    String? subjectId,
    bool? active,
  }) async {
    await _c.from('recurring_slots').update({
      'day_of_week': ?dayOfWeek,
      'start_minutes': ?startMinutes,
      'end_minutes': ?endMinutes,
      'location': ?location,
      'subject_id': ?subjectId,
      'active': ?active,
    }).eq('id', id);
  }

  Future<void> deleteSlot(String id) async {
    await _c.from('recurring_slots').delete().eq('id', id);
  }

  // ---------- Sessions / attendance ----------

  Future<List<LessonSession>> lessons() async =>
      _mapList(await _c.from('sessions').select(), LessonSession.fromJson);

  /// Upserts the attendance row and returns its id (used for the undo action).
  Future<String?> recordAttendance({
    required String studentId,
    String? subjectId,
    String? slotId,
    required String date,
    required String attendance,
    String? note,
    String? topics,
    String? homework,
    String? rescheduledTo,
  }) async {
    final school = await _schoolIdOrThrow();
    final res = await _c.from('sessions').upsert({
      'school_id': school,
      'student_id': studentId,
      'subject_id': ?subjectId,
      'slot_id': ?slotId,
      'date': date,
      'attendance': attendance,
      'note': ?note,
      'topics': ?topics,
      'homework': ?homework,
      'rescheduled_to': ?rescheduledTo,
      'recorded_by': _uidOrThrow(),
    }, onConflict: 'student_id,slot_id,date').select('id').maybeSingle();
    if (res is Map<String, dynamic>) {
      return res['id'] as String?;
    }
    return null;
  }

  Future<void> updateLesson(
    String id, {
    String? attendance,
    String? note,
    String? topics,
    String? homework,
    String? rescheduledTo,
  }) async {
    await _c.from('sessions').update({
      if (attendance != null) 'attendance': attendance,
      'note': ?note,
      'topics': ?topics,
      'homework': ?homework,
      'rescheduled_to': ?rescheduledTo,
    }).eq('id', id);
  }

  /// UNDO primitive: removes the recorded attendance row entirely, returning
  /// the session to "not marked yet".
  Future<void> deleteLesson(String id) async {
    await _c.from('sessions').delete().eq('id', id);
  }

  // ---------- Fees / payments ----------

  Future<List<Fee>> fees() async => _mapList(
        await _c.from('fees').select().order('month', ascending: false),
        Fee.fromJson,
      );

  Future<void> createFee({
    required String studentId,
    required String month,
    required double amount,
    String? dueDate,
    String? notes,
  }) async {
    final school = await _schoolIdOrThrow();
    await _c.from('fees').insert({
      'school_id': school,
      'student_id': studentId,
      'month': month,
      'amount': amount,
      'due_date': ?dueDate,
      'notes': ?notes,
    });
  }

  Future<void> updateFee(String id, {double? amount, String? dueDate, String? notes}) async {
    await _c.from('fees').update({
      'amount': ?amount,
      'due_date': ?dueDate,
      'notes': ?notes,
    }).eq('id', id);
  }

  Future<void> deleteFee(String id) async {
    await _c.from('fees').delete().eq('id', id);
  }

  Future<List<Payment>> payments() async =>
      _mapList(await _c.from('payments').select(), Payment.fromJson);

  Future<void> createPayment({
    required String feeId,
    required String studentId,
    required double amount,
    String? paidAt,
    String method = 'cash',
    String? note,
  }) async {
    final school = await _schoolIdOrThrow();
    await _c.from('payments').insert({
      'school_id': school,
      'fee_id': feeId,
      'student_id': studentId,
      'amount': amount,
      'paid_at': paidAt ?? _isoToday(),
      'method': method,
      'note': ?note,
    });
  }

  Future<void> deletePayment(String id) async {
    await _c.from('payments').delete().eq('id', id);
  }

  // ---------- Tests ----------

  Future<List<TestResult>> tests() async =>
      _mapList(await _c.from('tests').select(), TestResult.fromJson);

  Future<void> createTest({
    required String studentId,
    String? subjectId,
    String type = 'monthly',
    String? date,
    double? score,
    double? maxScore,
    String? note,
  }) async {
    final school = await _schoolIdOrThrow();
    await _c.from('tests').insert({
      'school_id': school,
      'student_id': studentId,
      'subject_id': ?subjectId,
      'type': type,
      'date': date ?? _isoToday(),
      'score': ?score,
      'max_score': ?maxScore,
      'note': ?note,
    });
  }

  Future<void> deleteTest(String id) async {
    await _c.from('tests').delete().eq('id', id);
  }

  Future<void> updateTest(
    String id, {
    String? subjectId,
    String? type,
    String? date,
    double? score,
    double? maxScore,
    String? note,
  }) async {
    await _c.from('tests').update({
      'subject_id': ?subjectId,
      if (type != null) 'type': type,
      'date': ?date,
      'score': ?score,
      'max_score': ?maxScore,
      'note': ?note,
    }).eq('id', id);
  }

  // ---------- Notes ----------

  Future<List<LessonNote>> notes() async =>
      _mapList(await _c.from('notes').select(), LessonNote.fromJson);

  Future<void> createNote({
    required String studentId,
    required String body,
    String? sessionId,
  }) async {
    final school = await _schoolIdOrThrow();
    await _c.from('notes').insert({
      'school_id': school,
      'student_id': studentId,
      'author_id': _uidOrThrow(),
      'body': body,
      'session_id': ?sessionId,
    });
  }

  Future<void> deleteNote(String id) async {
    await _c.from('notes').delete().eq('id', id);
  }

  // ---------- Announcements ----------

  Future<List<Announcement>> announcements() async => _mapList(
        await _c
            .from('announcements')
            .select()
            .order('created_at', ascending: false),
        Announcement.fromJson,
      );

  Future<void> createAnnouncement({
    String? title,
    required String body,
    String audience = 'all',
    bool pinned = false,
    String? expiresAt,
  }) async {
    final school = await _schoolIdOrThrow();
    await _c.from('announcements').insert({
      'school_id': school,
      'author_id': _uidOrThrow(),
      'title': ?title,
      'body': body,
      'audience': audience,
      'pinned': pinned,
      'expires_at': ?expiresAt,
    });
  }

  Future<void> updateAnnouncement(
    String id, {
    String? title,
    String? body,
    String? audience,
    bool? pinned,
    String? expiresAt,
  }) async {
    await _c.from('announcements').update({
      if (title != null) 'title': title,
      if (body != null) 'body': body,
      if (audience != null) 'audience': audience,
      if (pinned != null) 'pinned': pinned,
      'expires_at': ?expiresAt,
    }).eq('id', id);
  }

  Future<void> setAnnouncementPinned(String id, bool pinned) async {
    await _c.from('announcements').update({'pinned': pinned}).eq('id', id);
  }

  Future<void> deleteAnnouncement(String id) async {
    await _c.from('announcements').delete().eq('id', id);
  }

  // ---------- Notification prefs ----------

  /// Returns per-category on/off for the current teacher; missing rows
  /// default to on.
  Future<Map<String, bool>> notificationPrefs() async {
    final uid = currentUserId();
    if (uid == null) {
      return _defaultPrefs();
    }
    final data = await _c
        .from('notification_prefs')
        .select()
        .eq('user_id', uid)
        .maybeSingle();
    if (data is! Map<String, dynamic>) {
      return _defaultPrefs();
    }
    return _defaultPrefs()
      ..['attendance'] = data['attendance'] as bool? ?? true
      ..['note'] = data['note'] as bool? ?? true
      ..['test'] = data['test'] as bool? ?? true
      ..['fee'] = data['fee'] as bool? ?? true
      ..['payment'] = data['payment'] as bool? ?? true
      ..['announcement'] = data['announcement'] as bool? ?? true
      ..['teacher'] = data['teacher'] as bool? ?? true
      ..['general'] = data['general'] as bool? ?? true;
  }

  Future<void> upsertNotificationPrefs(Map<String, bool> prefs) async {
    await _c.from('notification_prefs').upsert({
      'user_id': _uidOrThrow(),
      'attendance': prefs['attendance'] ?? true,
      'note': prefs['note'] ?? true,
      'test': prefs['test'] ?? true,
      'fee': prefs['fee'] ?? true,
      'payment': prefs['payment'] ?? true,
      'announcement': prefs['announcement'] ?? true,
      'teacher': prefs['teacher'] ?? true,
      'general': prefs['general'] ?? true,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Map<String, bool> _defaultPrefs() => {
        'attendance': true,
        'note': true,
        'test': true,
        'fee': true,
        'payment': true,
        'announcement': true,
        'teacher': true,
        'general': true,
      };

  // ---------- Notifications ----------

  Future<List<AppNotification>> teacherNotifications() async => _mapList(
        await _c
            .from('notifications')
            .select()
            .eq('recipient_type', 'teacher')
            .order('created_at', ascending: false),
        AppNotification.fromJson,
      );

  Future<void> markTeacherNotificationsRead(List<String> ids) async {
    if (ids.isEmpty) {
      return;
    }
    await _c.from('notifications').update({'is_read': true}).inFilter('id', ids);
  }

  Future<void> deleteTeacherNotification(String id) async {
    await _c.from('notifications').delete().eq('id', id);
  }

  // ---------- Parent portal (token RPCs) ----------

  Future<Map<String, dynamic>> parentPortal(String token) async {
    final res = await _c.rpc('parent_portal', params: {'p_token': token});
    return res as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> parentNotifications(String token) async {
    final res = await _c.rpc('parent_notifications', params: {'p_token': token});
    return res as Map<String, dynamic>;
  }

  Future<void> parentMarkRead(String token, List<String> ids) async {
    await _c.rpc(
      'parent_mark_read',
      params: {'p_token': token, 'p_ids': ids},
    );
  }

  // ---------- Monthly reports ----------

  /// Generates (and persists) a monthly report for a student via the
  /// `generate_report` RPC. Idempotent — recomputes and upserts.
  Future<MonthlyReport> generateReport({
    required String studentId,
    required String month,
  }) async {
    final res = await _c.rpc(
      'generate_report',
      params: {'p_student': studentId, 'p_month': month},
    );
    return MonthlyReport.fromJson(res as Map<String, dynamic>);
  }

  // ---------- App releases (in-app update check) ----------

  /// Latest published release. Primary source is the curated global
  /// `app_meta.latest_release` row; on native platforms it is merged with
  /// the GitHub Releases API so tagging a release on GitHub is enough to
  /// surface an update (no manual metadata bump required).
  ///
  /// Merging rule: the newest version wins; ties prefer the entry that
  /// carries a direct APK url (so the in-app download works).
  Future<AppRelease?> latestRelease() async {
    final meta = await _appMetaRelease();

    AppRelease? gitHub;
    try {
      gitHub = await fetchLatestGitHubRelease();
    } catch (_) {
      // Network/parse failure — the curated metadata is still authoritative.
    }

    if (meta == null) return gitHub;
    if (gitHub == null) return meta;
    if (isNewerVersion(gitHub.version, meta.version)) return gitHub;
    if (isNewerVersion(meta.version, gitHub.version)) return meta;
    return meta.apkUrl != null ? meta : gitHub;
  }

  /// Curated release metadata from the global `app_meta` table. Public app
  /// metadata (not school-scoped); returns null when the row is absent.
  Future<AppRelease?> _appMetaRelease() async {
    final data = await _c
        .from('app_meta')
        .select('value')
        .eq('key', 'latest_release')
        .maybeSingle();
    if (data is Map<String, dynamic> && data['value'] is Map<String, dynamic>) {
      return AppRelease.fromJson(data['value'] as Map<String, dynamic>);
    }
    return null;
  }

  // ---------- Bulk operations ----------

  /// Deletes many students at once (RLS-scoped to the caller's school).
  Future<void> deleteStudents(List<String> ids) async {
    if (ids.isEmpty) return;
    await _c.from('students').delete().inFilter('id', ids);
  }

  /// Updates the grade for many students (null clears the grade).
  Future<void> updateStudentsGrade(List<String> ids, String? grade) async {
    if (ids.isEmpty) return;
    await _c.from('students').update({'grade': grade}).inFilter('id', ids);
  }

  /// Assigns a subject to many students at once (idempotent).
  Future<void> assignSubjectToStudents(
    List<String> studentIds,
    String subjectId,
  ) async {
    if (studentIds.isEmpty) return;
    final existing = await _c
        .from('student_subjects')
        .select('student_id')
        .eq('subject_id', subjectId)
        .inFilter('student_id', studentIds);
    final existingIds = (existing as List<dynamic>)
        .map((e) => (e as Map<String, dynamic>)['student_id'] as String)
        .toSet();
    final missing = studentIds.where((id) => !existingIds.contains(id)).toList();
    if (missing.isEmpty) return;
    await _c.from('student_subjects').insert(
      missing.map((id) => {'student_id': id, 'subject_id': subjectId}).toList(),
    );
  }

  /// Removes a subject from many students at once.
  Future<void> removeSubjectFromStudents(
    List<String> studentIds,
    String subjectId,
  ) async {
    if (studentIds.isEmpty) return;
    await _c
        .from('student_subjects')
        .delete()
        .eq('subject_id', subjectId)
        .inFilter('student_id', studentIds);
  }

  /// Deletes many subjects at once (RLS-scoped to the caller's school).
  Future<void> deleteSubjects(List<String> ids) async {
    if (ids.isEmpty) return;
    await _c.from('subjects').delete().inFilter('id', ids);
  }

  /// Updates the grade for many subjects at once (null clears the grade).
  Future<void> updateSubjectsGrade(List<String> ids, String? grade) async {
    if (ids.isEmpty) return;
    await _c.from('subjects').update({'grade': grade}).inFilter('id', ids);
  }

  /// Deletes many fees at once (RLS-scoped to the caller's school).
  Future<void> deleteFees(List<String> ids) async {
    if (ids.isEmpty) return;
    await _c.from('fees').delete().inFilter('id', ids);
  }

  /// Registers a catch-up payment for the remaining balance of each fee in
  /// [entries]. The `trg_refresh_fee` trigger updates paid_amount/status.
  Future<void> markFeesPaid(
    List<({String feeId, String studentId, double remaining})> entries, {
    String method = 'cash',
  }) async {
    if (entries.isEmpty) return;
    final school = await _schoolIdOrThrow();
    final rows = <Map<String, dynamic>>[
      for (final e in entries)
        if (e.remaining > 0)
          {
            'school_id': school,
            'fee_id': e.feeId,
            'student_id': e.studentId,
            'amount': e.remaining,
            'paid_at': _isoToday(),
            'method': method,
          },
    ];
    if (rows.isEmpty) return;
    await _c.from('payments').insert(rows);
  }

  // ---------- Internal helpers ----------

  List<T> _mapList<T>(dynamic data, T Function(Map<String, dynamic>) fromJson) =>
      (data as List<dynamic>)
          .map((e) => fromJson(e as Map<String, dynamic>))
          .toList();

  String _uidOrThrow() {
    final uid = currentUserId();
    if (uid == null) {
      throw StateError('Not authenticated');
    }
    return uid;
  }

  /// Resolves the caller's school id or throws [StateError] when the profile
  /// or its school cannot be determined. Used by mutating methods.
  Future<String> _schoolIdOrThrow() async {
    final p = await currentProfile();
    if (p == null) {
      throw StateError('No profile');
    }
    final school = p.isManager ? p.id : p.managerId;
    if (school == null) {
      throw StateError('No school');
    }
    return school;
  }

  /// Local 'YYYY-MM-DD' for today (PostgREST date column format).
  String _isoToday() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }
}