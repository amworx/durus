import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:durus/core/durus_api.dart';
import 'package:durus/core/error_report.dart';
import 'package:durus/core/google_auth.dart';
import 'package:durus/core/links.dart';
import 'package:durus/core/utils.dart';
import 'package:durus/l10n/app_localizations.dart';
import 'package:durus/models/models.dart';
import 'package:durus/screens/intro_screen.dart';
import 'package:durus/widgets/widgets.dart';

void main() {
  group('utils', () {
    test('makeUuid returns a UUID v4', () {
      final u = makeUuid();
      expect(
        u,
        matches(RegExp(
            r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$')),
      );
      expect(u == makeUuid(), isFalse);
    });

    test('monthKey zero-pads year and month', () {
      expect(monthKey(DateTime(2026, 9, 13)), '2026-09');
      expect(monthKey(DateTime(2026, 1, 1)), '2026-01');
    });

    test('gradeOrdinal maps Arabic grades, null on unknown', () {
      expect(gradeOrdinal('الأول'), 1);
      expect(gradeOrdinal('السادس'), 6);
      expect(gradeOrdinal('  الثالث  '), 3);
      expect(gradeOrdinal(null), isNull);
      expect(gradeOrdinal(''), isNull);
      expect(gradeOrdinal('typo'), isNull);
    });

    test('gradesCompatible warns only on known mismatches', () {
      expect(
        gradesCompatible(studentGrade: 'الثالث', subjectGrade: 'الثالث'),
        isTrue,
      );
      expect(
        gradesCompatible(studentGrade: 'الأول', subjectGrade: 'السادس'),
        isFalse,
      );
      expect(
        gradesCompatible(studentGrade: null, subjectGrade: 'السادس'),
        isTrue,
      );
      expect(
        gradesCompatible(studentGrade: 'الثالث', subjectGrade: null),
        isTrue,
      );
      expect(
        gradesCompatible(studentGrade: 'typo', subjectGrade: 'السادس'),
        isTrue,
      );
    });

    test('promoteGrade steps through grades, stops at edges', () {
      expect(promoteGrade('الأول'), 'الثاني');
      expect(promoteGrade('الخامس'), 'السادس');
      expect(promoteGrade('السادس'), isNull);
      expect(promoteGrade('typo'), isNull);
      expect(promoteGrade(''), isNull);
    });

    test('isExcusableDay needs a session or a slot weekday', () {
      expect(
        isExcusableDay(
          iso: '2026-09-14',
          weekday: DateTime.monday,
          sessionDates: {'2026-09-14'},
          slotWeekdays: const {2},
        ),
        isTrue,
      );
      expect(
        isExcusableDay(
          iso: '2026-09-15',
          weekday: DateTime.tuesday,
          sessionDates: const {'2026-09-14'},
          slotWeekdays: const {2},
        ),
        isTrue,
      );
      expect(
        isExcusableDay(
          iso: '2026-09-16',
          weekday: DateTime.wednesday,
          sessionDates: const {'2026-09-14'},
          slotWeekdays: const {2},
        ),
        isFalse,
      );
      expect(
        isExcusableDay(
          iso: '2026-09-16',
          weekday: DateTime.wednesday,
          sessionDates: const {},
          slotWeekdays: const {},
        ),
        isFalse,
      );
    });

    test('waNumber degrades safely on garbage input', () {
      expect(waNumber(''), '');
      expect(waNumber('abc-def'), '');
      expect(waNumber('+963 999 123 456'), '963999123456');
      expect(waNumber('00963999123456'), '963999123456');
      expect(waNumber('0999123456'), '963999123456');
    });

    test('fmtMonthKey never throws, echoes garbage back', () {
      expect(fmtMonthKey('2026-09'), 'سبتمبر 2026');
      expect(fmtMonthKey('junk'), 'junk');
      expect(fmtMonthKey('2026-13'), '2026-13');
      expect(fmtMonthKey(''), '');
      expect(fmtMonthKey('2026-9'), 'سبتمبر 2026');
    });

    test('resolveFamilyId reuses first id else mints uuid', () {
      expect(resolveFamilyId(['f1', 'f2']), 'f1');
      expect(resolveFamilyId([null, '', 'f9']), 'f9');
      final fresh = resolveFamilyId(const [null, null]);
      expect(
        fresh,
        matches(RegExp(
            r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$')),
      );
    });

    test('minutesOfDay and timeFromMinutes', () {
      expect(minutesOfDay(9, 5), 545);
      expect(timeFromMinutes(90), '01:30');
      expect(timeFromMinutes(1440), '24:00');
    });

    test('fmtDate is dd/MM/yyyy', () {
      expect(fmtDate(DateTime(2026, 9, 5)), '05/09/2026');
    });

    test('isoDate zero-pads to yyyy-MM-dd', () {
      expect(isoDate(DateTime(2026, 9, 5)), '2026-09-05');
      expect(isoDate(DateTime(2026, 11, 25)), '2026-11-25');
    });

    test('fmtMonthKey renders Arabic month headers', () {
      expect(fmtMonthKey('2026-09'), 'سبتمبر 2026');
      expect(fmtMonthKey('bad-key'), 'bad-key');
    });

    test('isNewerVersion compares x.y.z parts', () {
      expect(isNewerVersion('1.1.2', '1.1.1'), isTrue);
      expect(isNewerVersion('1.2.0', '1.1.9'), isTrue);
      expect(isNewerVersion('1.1.1', '1.1.2'), isFalse);
      expect(isNewerVersion('1.1.2', '1.1.2'), isFalse);
      expect(isNewerVersion('1.1', '1.1.2'), isFalse);
      expect(isNewerVersion('v2.0.0', '1.9.9'), isTrue);
    });
  });

  group('links', () {
    test('waNumber normalizes Syrian local formats to 963', () {
      expect(waNumber('09 999 99 99'), '96399999999');
      expect(waNumber('+963 999 999 999'), '963999999999');
      expect(waNumber('00963 999 999 999'), '963999999999');
      expect(waNumber(''), '');
      expect(waNumber('abc'), '');
    });

    test('waChatLink builds a wa.me deep link with a prefilled message', () {
      expect(waChatLink('0999999999'), 'https://wa.me/963999999999');
      expect(
        waChatLink('0999999999', text: 'مرحباً'),
        'https://wa.me/963999999999?text=%D9%85%D8%B1%D8%AD%D8%A8%D8%A7%D9%8B',
      );
      expect(waChatLink(''), '');
    });
  });

  group('models', () {
    test('Profile.fromJson maps snake_case and defaults', () {
      final p = Profile.fromJson({
        'id': 'p1',
        'email': 't@durus.app',
        'full_name': 'أحمد',
        'role': 'manager',
        'is_manager': true,
        'manager_id': 'm1',
        'school_id': 's1',
        'onboarded': true,
      });
      expect(p.id, 'p1');
      expect(p.email, 't@durus.app');
      expect(p.fullName, 'أحمد');
      expect(p.isManager, isTrue);
      expect(p.schoolId, 's1');
      expect(p.onboarded, isTrue);
    });

    test('Profile.toJson only exposes editable fields', () {
      const p = Profile(id: 'p1', email: 't@durus.app', fullName: 'أحمد');
      expect(p.toJson(), {'full_name': 'أحمد'});
    });

    test('Profile.active defaults to true and parses a disabled teacher', () {
      final enabled = Profile.fromJson({
        'id': 'p1',
        'email': 't@durus.app',
      });
      expect(enabled.active, isTrue);
      final disabled = Profile.fromJson({
        'id': 'p2',
        'email': 'x@durus.app',
        'active': false,
      });
      expect(disabled.active, isFalse);
    });

    test('Profile.fromJson maps bio/phone/avatar fields with defaults', () {
      final p = Profile.fromJson({
        'id': 'p1',
        'email': 't@durus.app',
        'bio': 'خبرة',
        'phone': '+963',
        'avatar_theme': 'yanliu',
        'avatar_gender': 'f',
        'avatar_seed': 's9',
      });
      expect(p.bio, 'خبرة');
      expect(p.phone, '+963');
      expect(p.avatarTheme, 'yanliu');
      expect(p.avatarGender, 'f');
      expect(p.avatarSeed, 's9');
      final d = Profile.fromJson({'id': 'p2', 'email': 'x@durus.app'});
      expect(d.bio, isNull);
      expect(d.phone, isNull);
      expect(d.avatarTheme, 'fatin-verse');
      expect(d.avatarGender, isNull);
      expect(d.avatarSeed, isNull);
    });

    test('Student.fromJson maps family/relation fields with defaults', () {
      final s = Student.fromJson({
        'id': 's1',
        'school_id': 'sc',
        'name': 'أحمد',
        'assigned_teacher_id': 't1',
        'parent_relation': 'أم',
        'family_id': 'f1',
      });
      expect(s.parentRelation, 'أم');
      expect(s.familyId, 'f1');
      final d = Student.fromJson({
        'id': 's2',
        'school_id': 'sc',
        'name': 'سارة',
        'assigned_teacher_id': 't1',
      });
      expect(d.parentRelation, isNull);
      expect(d.familyId, isNull);
    });

    test('Student status defaults to active', () {
      final d = Student.fromJson({
        'id': 's2',
        'school_id': 'sc',
        'name': 'سارة',
        'assigned_teacher_id': 't1',
      });
      expect(d.status, 'active');
    });

    test('incomeMonthTotals and incomeByMethod aggregate correctly', () {
      const fees = [
        Fee(
            id: 'f1',
            schoolId: 'sc',
            studentId: 's1',
            month: '2026-09',
            amount: 50000,
            paidAmount: 20000),
        Fee(
            id: 'f2',
            schoolId: 'sc',
            studentId: 's1',
            month: '2026-09',
            amount: 30000,
            paidAmount: 30000),
        Fee(
            id: 'f3',
            schoolId: 'sc',
            studentId: 's1',
            month: '2026-10',
            amount: 50000,
            paidAmount: 0),
      ];
      final sep = incomeMonthTotals(fees, '2026-09');
      expect(sep.due, 80000);
      expect(sep.collected, 50000);
      const payments = [
        Payment(
            id: 'p1',
            schoolId: 'sc',
            feeId: 'f1',
            studentId: 's1',
            amount: 20000,
            paidAt: '2026-09-05',
            method: 'cash'),
        Payment(
            id: 'p2',
            schoolId: 'sc',
            feeId: 'f2',
            studentId: 's1',
            amount: 30000,
            paidAt: '2026-09-06',
            method: 'transfer'),
      ];
      final byMethod = incomeByMethod(payments);
      expect(byMethod['cash'], 20000);
      expect(byMethod['transfer'], 30000);
      expect(byMethod.containsKey('other'), isFalse);
    });

    test('Student.fromJson/toJson round-trips', () {
      final s = Student.fromJson({
        'id': 'st1',
        'school_id': 's1',
        'name': 'سلمى',
        'grade': '3',
        'birth_year': 2018,
        'default_location': 'teacher_home',
        'assigned_teacher_id': 't1',
        'parent_name': 'أب سلمى',
        'created_at': '2026-09-01T10:00:00.000Z',
      });
      expect(s.name, 'سلمى');
      expect(s.birthYear, 2018);
      expect(s.defaultLocation, 'teacher_home');
      expect(s.createdAt, isNotNull);
      final json = s.toJson();
      expect(json['name'], 'سلمى');
      expect(json['school_id'], 's1');
      expect(json['birth_year'], 2018);
      expect(json['default_location'], 'teacher_home');
    });

    test('Subject.fromJson maps grade and displayLabel includes it', () {
      final secondGrade = Subject.fromJson({
        'id': 'sub1',
        'school_id': 's1',
        'name': 'اللغة العربية',
        'grade': 'الصف الثاني',
      });
      expect(secondGrade.displayLabel, 'اللغة العربية — الصف الثاني');
      final noGrade = Subject.fromJson({
        'id': 'sub2',
        'school_id': 's1',
        'name': 'الرياضيات',
      });
      expect(noGrade.displayLabel, 'الرياضيات');
    });

    test('MonthlyReport.fromJson parses a full RPC payload', () {
      final report = MonthlyReport.fromJson({
        'student_id': 'st1',
        'student_name': 'أحمد',
        'grade': 'التاسع',
        'month': '2026-09',
        'generated_at': '2026-09-13T12:00:00.000Z',
        'attendance': {
          'total': 12,
          'present': 10,
          'absent': 1,
          'rescheduled': 1,
        },
        'fee': {
          'month': '2026-09',
          'amount': 50000,
          'paid_amount': 20000,
          'status': 'partial',
          'due_date': '2026-09-05',
        },
        'tests': [
          {
            'subject': 'رياضيات',
            'type': 'monthly',
            'date': '2026-09-10',
            'score': 18,
            'max_score': 20,
          },
        ],
        'notes': [
          {'body': 'ممتاز', 'created_at': '2026-09-11T08:00:00.000Z'},
        ],
      });
      expect(report.studentName, 'أحمد');
      expect(report.grade, 'التاسع');
      expect(report.month, '2026-09');
      expect(report.attendance.total, 12);
      expect(report.attendance.presentPercent, closeTo(83.33, 0.01));
      expect(report.fee?.status, 'partial');
      expect(report.fee?.remaining, 30000);
      expect(report.tests, hasLength(1));
      expect(report.tests.first.subject, 'رياضيات');
      expect(report.tests.first.score, 18);
      expect(report.notes.first.body, 'ممتاز');
      expect(report.notes.first.createdAt, isNotNull);
    });

    test('MonthlyReport.fromJson tolerates empty sections', () {
      final report = MonthlyReport.fromJson({
        'student_id': 'st1',
        'student_name': 'سلمى',
        'month': '2026-08',
        'attendance': {},
      });
      expect(report.attendance.total, 0);
      expect(report.attendance.presentPercent, 0);
      expect(report.fee, isNull);
      expect(report.tests, isEmpty);
      expect(report.notes, isEmpty);
    });
  });

  group('widgets', () {
    Widget harness(Widget child) => MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ar'),
          home: Scaffold(body: SingleChildScrollView(child: child)),
        );

    testWidgets('EmptyState renders its message and icon', (tester) async {
      await tester.pumpWidget(harness(
        const EmptyState(icon: Icons.inbox_outlined, message: 'لا يوجد شيء'),
      ));
      expect(find.text('لا يوجد شيء'), findsOneWidget);
      expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
    });

    testWidgets('SectionCard renders title and child', (tester) async {
      await tester.pumpWidget(harness(
        const SectionCard(title: 'العنوان', child: Text('المحتوى')),
      ));
      expect(find.text('العنوان'), findsOneWidget);
      expect(find.text('المحتوى'), findsOneWidget);
    });

    testWidgets('IntroScreen shows first page and skip calls onDone',
        (tester) async {
      var done = false;
      // NOTE: no SingleChildScrollView here — ConcentricPageView needs
      // bounded constraints, exactly like the full-screen real usage.
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ar'),
        home: Scaffold(body: IntroScreen(onDone: () => done = true)),
      ));
      await tester.pump();
      expect(find.text('دروسك الخاصة منظمة'), findsOneWidget);
      expect(find.text('تخطي'), findsOneWidget);
      await tester.tap(find.text('تخطي'));
      await tester.pump();
      expect(done, isTrue);
    });

    testWidgets('auth reset l10n keys resolve to non-empty Arabic text',
        (tester) async {
      late AppLocalizations l10n;
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ar'),
        home: Builder(
          builder: (context) {
            l10n = AppLocalizations.of(context);
            return const SizedBox();
          },
        ),
      ));
      await tester.pumpAndSettle();
      expect(l10n.authForgotPassword, isNotEmpty);
      expect(l10n.authResetDialogTitle, isNotEmpty);
      expect(l10n.authResetSent, isNotEmpty);
      expect(l10n.authResetButton, isNotEmpty);
    });

    testWidgets('google auth l10n keys resolve to non-empty Arabic text',
        (tester) async {
      late AppLocalizations l10n;
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ar'),
        home: Builder(
          builder: (context) {
            l10n = AppLocalizations.of(context);
            return const SizedBox();
          },
        ),
      ));
      await tester.pumpAndSettle();
      expect(l10n.authGoogleButton, isNotEmpty);
      expect(l10n.authGoogleOr, isNotEmpty);
      expect(l10n.authGoogleNotConfigured, isNotEmpty);
    });

    testWidgets('feature-request + owner l10n keys resolve to Arabic text',
        (tester) async {
      late AppLocalizations l10n;
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ar'),
        home: Builder(
          builder: (context) {
            l10n = AppLocalizations.of(context);
            return const SizedBox();
          },
        ),
      ));
      await tester.pumpAndSettle();
      expect(l10n.featReqTitle, isNotEmpty);
      expect(l10n.featReqNew, isNotEmpty);
      expect(l10n.featReqSubject, isNotEmpty);
      expect(l10n.featReqDetails, isNotEmpty);
      expect(l10n.featReqType, isNotEmpty);
      expect(l10n.featReqFeature, isNotEmpty);
      expect(l10n.featReqEdit, isNotEmpty);
      expect(l10n.featReqSend, isNotEmpty);
      expect(l10n.featReqSent, isNotEmpty);
      expect(l10n.featReqEmpty, isNotEmpty);
      expect(l10n.featReqStatusNew, isNotEmpty);
      expect(l10n.featReqStatusReviewing, isNotEmpty);
      expect(l10n.featReqStatusPlanned, isNotEmpty);
      expect(l10n.featReqStatusDone, isNotEmpty);
      expect(l10n.featReqStatusRejected, isNotEmpty);
      expect(l10n.ownerTitle, isNotEmpty);
      expect(l10n.ownerUsers, isNotEmpty);
      expect(l10n.ownerActiveToday, isNotEmpty);
      expect(l10n.ownerActiveWeek, isNotEmpty);
      expect(l10n.ownerVersions, isNotEmpty);
      expect(l10n.ownerSchools, isNotEmpty);
      expect(l10n.ownerDead, isNotEmpty);
      expect(l10n.ownerRequests, isNotEmpty);
      expect(l10n.ownerSignups, isNotEmpty);
      expect(l10n.ownerCollected, isNotEmpty);
      expect(l10n.ownerOutstanding, isNotEmpty);
      expect(l10n.ownerEmpty, isNotEmpty);
      expect(l10n.ownerErrors, isNotEmpty);
    });
  });

  group('google auth', () {
    test('isGoogleClientIdConfigured rejects empty/blank ids', () {
      expect(isGoogleClientIdConfigured(''), isFalse);
      expect(isGoogleClientIdConfigured('   '), isFalse);
      expect(
        isGoogleClientIdConfigured('123-abc.apps.googleusercontent.com'),
        isTrue,
      );
    });

    test('signInWithGoogle fails closed without a client id', () {
      expect(
        DurusApi().signInWithGoogle(googleWebClientId: '  '),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            'google_not_configured',
          ),
        ),
      );
    });

    test('signInWithGoogle cancellation returns false quietly', () async {
      final ok = await DurusApi().signInWithGoogle(
        googleWebClientId: 'test.apps.googleusercontent.com',
        nativeSignIn: (_) async => null,
      );
      expect(ok, isFalse);
    });

    test('showPasswordForm hides the form only for password-less accounts',
        () {
      // Pure Google account — no password to change.
      expect(
        showPasswordForm(identityProviders: const ['google']),
        isFalse,
      );
      // Classic email account.
      expect(
        showPasswordForm(identityProviders: const ['email']),
        isTrue,
      );
      // Linked both ways — a password exists, keep the form.
      expect(
        showPasswordForm(
            identityProviders: const ['google', 'email']),
        isTrue,
      );
      // Missing identity list — fall back to the app metadata provider.
      expect(
        showPasswordForm(
            identityProviders: const [], appProvider: 'google'),
        isFalse,
      );
      expect(
        showPasswordForm(
            identityProviders: const [], appProvider: 'email'),
        isTrue,
      );
      // Unknown state — fail open to the historical behavior.
      expect(showPasswordForm(identityProviders: const []), isTrue);
    });

    test('validateFeatureRequest rejects empty/oversize input', () {
      expect(
        validateFeatureRequest(title: '  ', body: 'x'),
        'required',
      );
      expect(
        validateFeatureRequest(title: 'x' * 151, body: ''),
        'too_long',
      );
      expect(
        validateFeatureRequest(title: 'عنوان', body: 'y' * 2001),
        'too_long',
      );
      expect(
        validateFeatureRequest(title: 'عنوان', body: 'تفاصيل'),
        isNull,
      );
    });

    test('error-report throttle allows first, dedupes repeats', () {
      resetErrorReportThrottle();
      final t0 = DateTime(2026, 9, 18, 12);
      expect(shouldReportError('a', now: t0), isTrue);
      expect(
        shouldReportError('a', now: t0.add(const Duration(minutes: 4))),
        isFalse,
      );
      expect(
        shouldReportError('a', now: t0.add(const Duration(minutes: 6))),
        isTrue,
      );
      expect(shouldReportError('b', now: t0), isTrue);
    });

    test('truncateErrorText caps overlong texts', () {
      expect(truncateErrorText('abc', 5), 'abc');
      expect(truncateErrorText('abcdef', 5).length, 5);
    });
  });
}