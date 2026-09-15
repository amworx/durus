import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:durus/core/utils.dart';
import 'package:durus/l10n/app_localizations.dart';
import 'package:durus/models/models.dart';
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
  });
}