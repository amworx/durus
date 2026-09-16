// Durus — monthly report screen (تقرير شهري).
//
// Picks a month, calls the idempotent `generate_report` RPC (which computes
// attendance/fee/tests/notes and persists the result into `reports`), and
// displays the generated summary.
//
// Arabic-only, RTL. All user-facing strings come from `context.l10n`.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:durus/core/durus_api.dart';
import 'package:durus/core/links.dart';
import 'package:durus/core/utils.dart';
import 'package:durus/l10n/app_localizations.dart';
import 'package:durus/l10n/l10n_ext.dart';
import 'package:durus/models/models.dart';
import 'package:durus/providers/providers.dart';
import 'package:durus/widgets/widgets.dart';

class MonthlyReportScreen extends ConsumerStatefulWidget {
  const MonthlyReportScreen({
    super.key,
    required this.studentId,
    required this.studentName,
  });

  final String studentId;
  final String studentName;

  @override
  ConsumerState<MonthlyReportScreen> createState() => _MonthlyReportScreenState();
}

class _MonthlyReportScreenState extends ConsumerState<MonthlyReportScreen> {
  late String _month;
  MonthlyReport? _report;
  bool _loading = false;
  bool _firstLoadScheduled = false;

  @override
  void initState() {
    super.initState();
    _month = monthKey(DateTime.now());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_firstLoadScheduled) {
      _firstLoadScheduled = true;
      _load();
    }
  }

  Future<void> _load() async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _loading = true;
    });
    try {
      final DurusApi api = ref.read(apiProvider);
      final report =
          await api.generateReport(studentId: widget.studentId, month: _month);
      if (mounted) {
        setState(() => _report = report);
      }
    } catch (_) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text(l10n.commonError)));
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final months = _recentMonths();
    final report = _report;

    return Scaffold(
      appBar: AppBar(
        title: Text('${l10n.reportsTitle} — ${widget.studentName}'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _initialIfPresent(months, _month),
                  decoration: InputDecoration(
                    labelText: l10n.reportsMonth,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: [
                    for (final month in months)
                      DropdownMenuItem(
                        value: month,
                        child: Text(fmtMonthKey(month)),
                      ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _month = value);
                    _load();
                  },
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: _loading ? null : _load,
                icon: _loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                label: Text(l10n.commonRetry),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (report == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: LoadingView(),
            )
          else ...[
            _attendanceCard(context, l10n, report),
            const SizedBox(height: 16),
            _feeCard(context, l10n, report),
            const SizedBox(height: 16),
            _testsCard(context, l10n, report),
            const SizedBox(height: 16),
            _notesCard(context, l10n, report),
            const SizedBox(height: 16),
            _whatsappButton(context, l10n, report),
          ],
        ],
      ),
    );
  }

  Widget _attendanceCard(
    BuildContext context,
    AppLocalizations l10n,
    MonthlyReport report,
  ) {
    final attendance = report.attendance;
    final theme = Theme.of(context);
    return SectionCard(
      title: l10n.reportsAttendance,
      child: attendance.total == 0
          ? Text(
              l10n.reportsNoAttendance,
              style: theme.textTheme.bodySmall,
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${attendance.presentPercent.toStringAsFixed(0)}%',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${l10n.portalTotalSessions}: ${attendance.total}',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    StatusChip(
                      label: '${l10n.portalPresent} ${attendance.present}',
                      color: Colors.green,
                    ),
                    StatusChip(
                      label: '${l10n.portalAbsent} ${attendance.absent}',
                      color: Colors.red,
                    ),
                    StatusChip(
                      label: '${l10n.portalLate} ${attendance.late}',
                      color: Colors.orange,
                    ),
                    StatusChip(
                      label:
                          '${l10n.portalRescheduled} ${attendance.rescheduled}',
                      color: Colors.blueGrey,
                    ),
                    StatusChip(
                      label: '${l10n.portalCancelled} ${attendance.cancelled}',
                      color: Colors.grey,
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _feeCard(
    BuildContext context,
    AppLocalizations l10n,
    MonthlyReport report,
  ) {
    final theme = Theme.of(context);
    final fee = report.fee;
    return SectionCard(
      title: l10n.reportsFee,
      child: fee == null
          ? Text(
              l10n.reportsNoFee,
              style: theme.textTheme.bodySmall,
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    StatusChip(
                      label: _feeStatusLabel(l10n, fee.status),
                      color: _feeStatusColor(fee.status),
                    ),
                    const Spacer(),
                    Text(
                      '${l10n.feesMonth}: ${fmtMonthKey(fee.month ?? report.month)}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _summaryRow(l10n, l10n.feesAmount, _numText(fee.amount)),
                _summaryRow(l10n, l10n.feesPaid, _numText(fee.paidAmount)),
                _summaryRow(
                  l10n,
                  l10n.feesRemaining,
                  _numText(fee.remaining),
                ),
              ],
            ),
    );
  }

  Widget _summaryRow(AppLocalizations l10n, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text('$label: ', style: Theme.of(context).textTheme.bodyMedium),
          Text(
            value,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _testsCard(
    BuildContext context,
    AppLocalizations l10n,
    MonthlyReport report,
  ) {
    final theme = Theme.of(context);
    final tests = report.tests;
    return SectionCard(
      title: l10n.reportsTests,
      child: tests.isEmpty
          ? Text(
              l10n.reportsNoTests,
              style: theme.textTheme.bodySmall,
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final test in tests)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.assignment_outlined, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            [
                              if (test.subject.isNotEmpty) test.subject,
                              _testTypeLabel(l10n, test.type),
                            ].join(' • '),
                          ),
                        ),
                        Text(
                          '${_numText(test.score ?? 0)} / '
                          '${_numText(test.maxScore ?? 0)}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _notesCard(
    BuildContext context,
    AppLocalizations l10n,
    MonthlyReport report,
  ) {
    final theme = Theme.of(context);
    final notes = report.notes;
    return SectionCard(
      title: l10n.reportsNotes,
      child: notes.isEmpty
          ? Text(
              l10n.reportsNoNotes,
              style: theme.textTheme.bodySmall,
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final note in notes)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(note.body),
                        if (note.createdAt != null)
                          Text(
                            fmtDate(note.createdAt!),
                            style: theme.textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _whatsappButton(
    BuildContext context,
    AppLocalizations l10n,
    MonthlyReport report,
  ) {
    final students = ref.read(studentsProvider).value ?? const <Student>[];
    Student? student;
    for (final s in students) {
      if (s.id == widget.studentId) {
        student = s;
        break;
      }
    }
    return FilledButton.tonalIcon(
      onPressed: () => _sendWhatsApp(l10n, report, student),
      icon: const Icon(Icons.chat),
      label: Text(l10n.reportsWhatsappSend),
    );
  }

  /// Builds a plain-text summary of the report and opens WhatsApp with it
  /// pre-filled to the parent (requires a parent phone on the student).
  Future<void> _sendWhatsApp(
    AppLocalizations l10n,
    MonthlyReport report,
    Student? student,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final phone = student?.parentPhone;
    if (phone == null || phone.trim().isEmpty) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.studentsNoParentPhone)));
      return;
    }
    final fee = report.fee;
    final lines = <String>[
      l10n.reportsWhatsappIntro(
        student?.name ?? widget.studentName,
        fmtMonthKey(report.month),
      ),
      '',
      '${l10n.portalTotalSessions}: ${report.attendance.total}',
      '${l10n.portalPresent}: ${report.attendance.present}',
      '${l10n.portalAbsent}: ${report.attendance.absent}',
      '${l10n.portalLate}: ${report.attendance.late}',
      '${l10n.portalRescheduled}: ${report.attendance.rescheduled}',
      '${l10n.portalCancelled}: ${report.attendance.cancelled}',
      if (fee != null)
        '${l10n.feesAmount}: ${_numText(fee.amount)} • '
            '${l10n.feesPaid}: ${_numText(fee.paidAmount)} • '
            '${l10n.feesRemaining}: ${_numText(fee.remaining)}',
      if (report.tests.isNotEmpty) ...['', l10n.reportsTests],
      for (final test in report.tests)
        '• ${test.subject} (${_testTypeLabel(l10n, test.type)}): '
            '${_numText(test.score ?? 0)} / ${_numText(test.maxScore ?? 0)}',
    ];
    final ok = await openExternal(
      waChatLink(phone, text: lines.join('\n')),
    );
    if (!ok && mounted) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.commonOpenFailed)));
    }
  }

  // -------------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------------

  List<String> _recentMonths() {
    final now = DateTime.now();
    return List.generate(6, (i) {
      final monthIndex = now.month - i;
      final year = monthIndex <= 0 ? now.year - 1 : now.year;
      final month = monthIndex <= 0 ? monthIndex + 12 : monthIndex;
      return '$year-${month.toString().padLeft(2, '0')}';
    });
  }

  String _numText(num value) {
    if (value == value.truncateToDouble()) return value.toInt().toString();
    return value.toStringAsFixed(2);
  }

  String _feeStatusLabel(AppLocalizations l10n, String status) {
    return switch (status) {
      'paid' => l10n.feesStatusPaid,
      'partial' => l10n.feesStatusPartial,
      _ => l10n.feesStatusUnpaid,
    };
  }

  Color _feeStatusColor(String status) {
    return switch (status) {
      'paid' => Colors.green,
      'partial' => Colors.orange,
      _ => Colors.red,
    };
  }

  String _testTypeLabel(AppLocalizations l10n, String type) {
    return switch (type) {
      'monthly' => l10n.testsTypeMonthly,
      'midterm' => l10n.testsTypeMidterm,
      'final' => l10n.testsTypeFinal,
      'quiz' => l10n.testsTypeQuiz,
      'other' => l10n.testsTypeOther,
      _ => l10n.commonNone,
    };
  }

  T? _initialIfPresent<T>(List<T> items, T? value) {
    if (value == null) return null;
    return items.contains(value) ? value : null;
  }
}