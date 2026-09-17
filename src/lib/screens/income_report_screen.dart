import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:durus/core/utils.dart';
import 'package:durus/l10n/l10n_ext.dart';
import 'package:durus/models/models.dart';
import 'package:durus/providers/providers.dart';
import 'package:durus/widgets/widgets.dart';

/// In-depth income report (teacher only): per-month collection with rates,
/// payment-method breakdown, advance prepayments, waivers, and the
/// outstanding ranking per student.
class IncomeReportScreen extends ConsumerWidget {
  const IncomeReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final feesAsync = ref.watch(feesProvider);
    final paymentsAsync = ref.watch(paymentsProvider);
    final studentsAsync = ref.watch(studentsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.incomeTitle)),
      body: feesAsync.when(
        loading: () => const LoadingView(),
        error: (error, stackTrace) => ErrorRetry(
          message: l10n.commonError,
          onRetry: () => ref.invalidate(feesProvider),
        ),
        data: (fees) {
          if (fees.isEmpty) {
            return EmptyState(
              icon: Icons.receipt_long_outlined,
              message: l10n.commonEmpty,
            );
          }
          final payments = paymentsAsync.value ?? const <Payment>[];
          final students = studentsAsync.value ?? const <Student>[];
          final nowMonth = monthKey(DateTime.now());

          var totalDue = 0.0;
          var totalCollected = 0.0;
          var advance = 0.0;
          for (final f in fees) {
            totalDue += f.amount;
            totalCollected += f.paidAmount;
            if (f.month.compareTo(nowMonth) > 0) advance += f.paidAmount;
          }
          final rate = totalDue <= 0 ? 1.0 : (totalCollected / totalDue).clamp(0.0, 1.0);

          final months = {
            for (final f in fees) f.month,
          }.toList()
            ..sort((a, b) => b.compareTo(a));
          final byMethod = incomeByMethod(payments);
          var waived = 0.0;
          for (final p in payments) {
            if (p.method == 'other' && p.note == l10n.feesWaiveNote) {
              waived += p.amount;
            }
          }
          final debts = <({String name, double remaining})>[];
          for (final s in students) {
            var due = 0.0;
            var paid = 0.0;
            for (final f in fees) {
              if (f.studentId == s.id) {
                due += f.amount;
                paid += f.paidAmount;
              }
            }
            if (due - paid > 0) {
              debts.add((name: s.name, remaining: due - paid));
            }
          }
          debts.sort((a, b) => b.remaining.compareTo(a.remaining));

          String money(num v) =>
              v == v.truncateToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);

          return RefreshIndicator(
            onRefresh: () => refreshSchoolData(ref),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                SectionCard(
                  title: l10n.incomeCollectionRate,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${(rate * 100).round()}%',
                        style: Theme.of(context)
                            .textTheme
                            .displaySmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(value: rate),
                      const SizedBox(height: 12),
                      _row(l10n.feesAmount, money(totalDue)),
                      _row(l10n.feesPaid, money(totalCollected)),
                      _row(l10n.feesRemaining,
                          money(totalDue - totalCollected)),
                      _row(l10n.incomeAdvance, money(advance)),
                      _row(l10n.incomeWaived, money(waived)),
                    ],
                  ),
                ),
                SectionCard(
                  title: l10n.incomeByMonth,
                  child: Column(
                    children: [
                      for (final m in months) ...[
                        _monthRow(context, m, incomeMonthTotals(fees, m)),
                      ],
                    ],
                  ),
                ),
                SectionCard(
                  title: l10n.incomeByMethod,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _methodChip(context, l10n.feesMethodCash,
                          byMethod['cash'] ?? 0, money),
                      _methodChip(context, l10n.feesMethodTransfer,
                          byMethod['transfer'] ?? 0, money),
                      _methodChip(context, l10n.feesMethodOther,
                          byMethod['other'] ?? 0, money),
                    ],
                  ),
                ),
                SectionCard(
                  title: l10n.incomeDebtors,
                  child: debts.isEmpty
                      ? Text(
                          l10n.commonEmpty,
                          style: Theme.of(context).textTheme.bodySmall,
                        )
                      : Column(
                          children: [
                            for (final d in debts)
                              _row(d.name, money(d.remaining)),
                          ],
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _monthRow(
      BuildContext context, String month, ({double due, double collected}) t) {
    final rate = t.due <= 0 ? 1.0 : (t.collected / t.due).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                fmtMonthKey(month),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              Text('${(rate * 100).round()}%'),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(value: rate),
        ],
      ),
    );
  }

  Widget _methodChip(
    BuildContext context,
    String label,
    double value,
    String Function(num) money,
  ) {
    return StatusChip(
      label: '$label: ${money(value)}',
      color: Theme.of(context).colorScheme.primary,
    );
  }
}
