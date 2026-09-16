// Durus — fees screens (list / form / payments sheet).
//
// Arabic-only, RTL. All user-facing strings come from `context.l10n`.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:durus/core/durus_api.dart';
import 'package:durus/core/utils.dart';
import 'package:durus/l10n/app_localizations.dart';
import 'package:durus/l10n/l10n_ext.dart';
import 'package:durus/models/models.dart';
import 'package:durus/providers/providers.dart';
import 'package:durus/widgets/durus_top_bar.dart';
import 'package:durus/widgets/widgets.dart';

// ---------------------------------------------------------------------------
// Fees list
// ---------------------------------------------------------------------------

class FeesScreen extends ConsumerWidget {
  const FeesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: DurusTopBar(
        title: l10n.feesTitle,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: l10n.feesAddFee,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const FeeFormScreen()),
            ),
          ),
        ],
      ),
      body: const _FeesBody(),
    );
  }
}

class _FeesBody extends ConsumerStatefulWidget {
  const _FeesBody();

  @override
  ConsumerState<_FeesBody> createState() => _FeesBodyState();
}

class _FeesBodyState extends ConsumerState<_FeesBody> {
  static const String _allStudents = '_all';
  static const String _allStatuses = '_all';
  String? _filterStudentId = _allStudents;
  String? _filterMonth;   // null = all
  String _filterStatus = _allStatuses; // '_all' | 'unpaid' | 'partial' | 'paid'
  final Set<String> _selected = {};
  bool get _selecting => _selected.isNotEmpty;

  void _openFeeForm(Fee fee) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => FeeFormScreen(fee: fee)),
    );
  }

  void _openPayments(Fee fee) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => PaymentsSheet(fee: fee),
    );
  }

  Future<void> _deleteFee(Fee fee) async {
    final l10n = context.l10n;
    final confirmed = await confirmDialog(
      context,
      title: l10n.commonDelete,
      message: l10n.commonConfirmDelete,
    );
    if (!confirmed || !mounted) return;
    try {
      final DurusApi api = ref.read(apiProvider);
      await api.deleteFee(fee.id);
      ref.invalidate(feesProvider);
      ref.invalidate(paymentsProvider);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.commonError)),
        );
      }
    }
  }

  void _toggle(String id) => setState(() {
        if (_selected.contains(id)) {
          _selected.remove(id);
        } else {
          _selected.add(id);
        }
      });

  void _selectAll(List<Fee> ids) => setState(() {
        if (_selected.length == ids.length) {
          _selected.clear();
        } else {
          _selected.addAll(ids.map((f) => f.id));
        }
      });

  Future<void> _bulkDelete() async {
    final l10n = context.l10n;
    final confirmed = await confirmDialog(
      context,
      title: l10n.bulkDeleteTitle,
      message: l10n.bulkDeleteConfirm(_selected.length),
    );
    if (!confirmed || !mounted) return;
    try {
      final DurusApi api = ref.read(apiProvider);
      await api.deleteFees(_selected.toList());
      _selected.clear();
      ref.invalidate(feesProvider);
      ref.invalidate(paymentsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.bulkCompleted)),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.commonError)),
        );
      }
    }
  }

  Future<void> _bulkMarkPaid(List<Fee> allFees) async {
    final l10n = context.l10n;
    final entries = <({String feeId, String studentId, double remaining})>[];
    for (final fee in allFees.where((f) => _selected.contains(f.id))) {
      final rem = fee.amount - fee.paidAmount;
      if (rem > 0) {
        entries.add((
          feeId: fee.id,
          studentId: fee.studentId,
          remaining: rem,
        ));
      }
    }
    if (entries.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.bulkNoSelection)),
        );
      }
      return;
    }
    final confirmed = await confirmDialog(
      context,
      title: l10n.bulkMarkPaid,
      message: l10n.bulkMarkPaidConfirm(entries.length),
    );
    if (!confirmed || !mounted) return;
    try {
      final DurusApi api = ref.read(apiProvider);
      await api.markFeesPaid(entries);
      _selected.clear();
      ref.invalidate(feesProvider);
      ref.invalidate(paymentsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.bulkCompleted)),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.commonError)),
        );
      }
    }
  }

  List<String> _monthsOf(List<Fee> fees) {
    final set = <String>{};
    for (final fee in fees) {
      final m = fee.month;
      if (m.isNotEmpty) set.add(m);
    }
    return set.toList()..sort();
  }

// ── filter sheet (compact button + modal bottom sheet) ──

  int get _activeFilterCount =>
      (_filterStudentId != _allStudents ? 1 : 0) +
      (_filterMonth != null ? 1 : 0) +
      (_filterStatus != _allStatuses ? 1 : 0);

  Future<void> _openFilterSheet() async {
    final l10n = context.l10n;
    final students = ref.read(studentsProvider).value ?? const <Student>[];
    final fees = ref.read(feesProvider).value ?? const <Fee>[];
    final result = await showFilterSheet(
      context,
      title: l10n.filterTitle,
      sections: [
        FilterSheetSection(
          id: 'student',
          label: l10n.homeStudent,
          current: _filterStudentId,
          choices: [
            FilterChoice(_allStudents, l10n.scheduleAllStudents),
            for (final student in students)
              FilterChoice(student.id, student.name),
          ],
        ),
        FilterSheetSection(
          id: 'month',
          label: l10n.feesMonth,
          current: _filterMonth,
          choices: [
            FilterChoice(null, l10n.filterAllMonths),
            for (final m in _monthsOf(fees))
              FilterChoice(m, fmtMonthKey(m)),
          ],
        ),
        FilterSheetSection(
          id: 'status',
          label: l10n.feesStatus,
          current: _filterStatus,
          choices: [
            FilterChoice(_allStatuses, l10n.filterAllStatus),
            for (final status in const ['unpaid', 'partial', 'paid'])
              FilterChoice(status, _feeStatus(l10n, status).label),
          ],
        ),
      ],
    );
    if (result == null || !mounted) return;
    setState(() {
      _filterStudentId = result['student'] ?? _allStudents;
      _filterMonth = result['month'];
      _filterStatus = result['status'] ?? _allStatuses;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final feesAsync = ref.watch(feesProvider);
    final studentsAsync = ref.watch(studentsProvider);
    final students = studentsAsync.value ?? const <Student>[];
    final fees = feesAsync.value ?? const <Fee>[];
    final filterId = _filterStudentId;
    final filtered = fees.where((f) {
      if (filterId != null && filterId != _allStudents && f.studentId != filterId) {
        return false;
      }
      if (_filterMonth != null && f.month != _filterMonth) return false;
      if (_filterStatus != _allStatuses && f.status != _filterStatus) return false;
      return true;
    }).toList();

    num totalAmount = 0;
    num totalPaid = 0;
    for (final fee in filtered) {
      totalAmount += fee.amount;
      totalPaid += fee.paidAmount;
    }
    final remaining = totalAmount - totalPaid;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                children: [
                  _summaryItem(
                    context,
                    l10n.feesAmount,
                    _fmtAmount(totalAmount),
                    scheme.primary,
                  ),
                  _summaryItem(
                    context,
                    l10n.feesPaid,
                    _fmtAmount(totalPaid),
                    Colors.green.shade700,
                  ),
                  _summaryItem(
                    context,
                    l10n.feesRemaining,
                    _fmtAmount(remaining),
                    remaining > 0 ? scheme.error : Colors.green.shade700,
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.filterTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                ),
              ),
              FilterButton(
                activeCount: _activeFilterCount,
                onPressed: _openFilterSheet,
              ),
            ],
          ),
        ),
        Expanded(
          child: feesAsync.when(
            loading: () => const LoadingView(),
            error: (error, stackTrace) => ErrorRetry(
              message: l10n.commonError,
              onRetry: () => ref.invalidate(feesProvider),
            ),
            data: (_) {
              if (filtered.isEmpty) {
                return RefreshableEmpty(
                  onRefresh: () => refreshSchoolData(ref),
                  empty: EmptyState(
                    icon: Icons.receipt_long_outlined,
                    message: fees.isEmpty ? l10n.feesEmpty : l10n.commonEmpty,
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: () => refreshSchoolData(ref),
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
                  itemCount: filtered.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
itemBuilder: (context, index) {
                  final fee = filtered[index];
                  final studentName = _studentName(students, fee.studentId);
                  final status = _feeStatus(l10n, fee.status);
                  final isSelected = _selected.contains(fee.id);
                  return ListTile(
                    leading: _selecting
                        ? Checkbox(
                            value: isSelected,
                            onChanged: (_) => _toggle(fee.id),
                          )
                        : null,
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            studentName.isEmpty ? l10n.commonNone : studentName,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        StatusChip(label: status.label, color: status.color),
                      ],
                    ),
                    subtitle: Text(
                      '${fmtMonthKey(fee.month)} • '
                      '${l10n.feesAmount}: ${_fmtAmount(fee.amount)} • '
                      '${l10n.feesPaid}: ${_fmtAmount(fee.paidAmount)}',
                    ),
                    trailing: _selecting
                        ? null
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.receipt_long_outlined),
                                tooltip: l10n.feesAddPayment,
                                onPressed: () => _openPayments(fee),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                tooltip: l10n.commonEdit,
                                onPressed: () => _openFeeForm(fee),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                tooltip: l10n.commonDelete,
                                onPressed: () => _deleteFee(fee),
                              ),
                            ],
                          ),
                    selected: isSelected,
                    selectedTileColor: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.25),
                    onTap: _selecting
                        ? () => _toggle(fee.id)
                        : () => _openPayments(fee),
                    onLongPress: _selecting ? null : () => _toggle(fee.id),
                  );
                },
              ),
            );
          },
        ),
        ),
        if (_selecting)
          SelectionBar(
            count: _selected.length,
            total: filtered.length,
            onClose: () => setState(() => _selected.clear()),
            onSelectAll: () => _selectAll(filtered),
            actions: [
              BulkAction(
                icon: Icons.check_circle_outline,
                label: l10n.bulkMarkPaid,
                onTap: () => _bulkMarkPaid(fees),
              ),
              BulkAction(
                icon: Icons.delete_outline,
                label: l10n.commonDelete,
                color: Theme.of(context).colorScheme.error,
                onTap: _bulkDelete,
              ),
            ],
          ),
      ],
    );
  }

  Widget _summaryItem(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Fee form (create / edit)
// ---------------------------------------------------------------------------

class FeeFormScreen extends ConsumerStatefulWidget {
  const FeeFormScreen({super.key, this.fee});

  final Fee? fee;

  @override
  ConsumerState<FeeFormScreen> createState() => _FeeFormScreenState();
}

class _FeeFormScreenState extends ConsumerState<FeeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _monthController;
  late final TextEditingController _amountController;
  late final TextEditingController _dueDateController;
  late final TextEditingController _notesController;
  String? _selectedStudentId;
  DateTime? _dueDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final fee = widget.fee;
    final due = fee?.dueDate;
    if (due != null && due.isNotEmpty) {
      _dueDate = DateTime.tryParse(due);
    }
    _monthController = TextEditingController(
      text: fee?.month ?? monthKey(DateTime.now()),
    );
    _amountController = TextEditingController(
      text: fee == null ? '' : _fmtAmount(fee.amount),
    );
    final parsedDue = _dueDate;
    _dueDateController = TextEditingController(
      text: parsedDue == null ? '' : fmtDate(parsedDue),
    );
    _notesController = TextEditingController(text: fee?.notes ?? '');
    _selectedStudentId = fee?.studentId;
  }

  @override
  void dispose() {
    _monthController.dispose();
    _amountController.dispose();
    _dueDateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final initial = _dueDate ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) {
      setState(() {
        _dueDate = picked;
        _dueDateController.text = fmtDate(picked);
      });
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final fee = widget.fee;
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null) return;
    final monthText = _monthController.text.trim();
    final notesText = _notesController.text.trim();
    final due = _dueDate;
    setState(() => _saving = true);
    try {
      final DurusApi api = ref.read(apiProvider);
      if (fee == null) {
        final studentId = _selectedStudentId;
        if (studentId == null) return;
        await api.createFee(
          studentId: studentId,
          month: monthText.isEmpty ? monthKey(DateTime.now()) : monthText,
          amount: amount,
          dueDate: due == null ? null : _isoDate(due),
          notes: notesText.isEmpty ? null : notesText,
        );
      } else {
        await api.updateFee(
          fee.id,
          amount: amount,
          dueDate: due == null ? null : _isoDate(due),
          notes: notesText.isEmpty ? null : notesText,
        );
      }
      ref.invalidate(feesProvider);
      ref.invalidate(paymentsProvider);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text(l10n.commonError)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fee = widget.fee;
    final isEdit = fee != null;
    final studentsAsync = ref.watch(studentsProvider);
    final students = studentsAsync.value ?? const <Student>[];

    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? l10n.commonEdit : l10n.feesAddFee)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (!isEdit) ...[
              DropdownButtonFormField<String>(
                initialValue: _selectedStudentId,
                decoration: InputDecoration(
                  labelText: l10n.feesSelectStudent,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: [
                  for (final student in students)
                    DropdownMenuItem(value: student.id, child: Text(student.name)),
                ],
                onChanged: (value) => setState(() => _selectedStudentId = value),
                validator: (value) =>
                    value == null ? l10n.commonRequired : null,
              ),
              const SizedBox(height: 16),
            ],
            TextFormField(
              controller: _monthController,
              readOnly: isEdit,
              keyboardType: TextInputType.datetime,
              onTap: () {
                if (isEdit) return;
                _monthController.selection = TextSelection(
                  baseOffset: 0,
                  extentOffset: _monthController.text.length,
                );
              },
              decoration: InputDecoration(
                labelText: l10n.feesMonth,
                helperText: 'YYYY-MM',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.commonRequired;
                }
                return RegExp(r'^\d{4}-(0[1-9]|1[0-2])$').hasMatch(value.trim())
                    ? null
                    : l10n.feesMonthInvalid;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: l10n.feesAmount,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.commonRequired;
                }
                return double.tryParse(value.trim()) == null
                    ? l10n.commonError
                    : null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _dueDateController,
              readOnly: true,
              onTap: _pickDueDate,
              decoration: InputDecoration(
                labelText: l10n.feesDueDate,
                suffixIcon: const Icon(Icons.calendar_today),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: l10n.commonNotes,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.commonSave),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Payments sheet (per fee)
// ---------------------------------------------------------------------------

class PaymentsSheet extends ConsumerStatefulWidget {
  const PaymentsSheet({super.key, required this.fee});

  final Fee fee;

  @override
  ConsumerState<PaymentsSheet> createState() => _PaymentsSheetState();
}

class _PaymentsSheetState extends ConsumerState<PaymentsSheet> {
  final _amountController = TextEditingController();
  String _method = 'cash';
  bool _saving = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _addPayment() async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.commonError)));
      return;
    }
    setState(() => _saving = true);
    try {
      final DurusApi api = ref.read(apiProvider);
      final fee = widget.fee;
      await api.createPayment(
        feeId: fee.id,
        studentId: fee.studentId,
        amount: amount,
        method: _method,
      );
      ref.invalidate(paymentsProvider);
      ref.invalidate(feesProvider);
      if (mounted) {
        _amountController.clear();
        setState(() => _saving = false);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        messenger.showSnackBar(SnackBar(content: Text(l10n.commonError)));
      }
    }
  }

  Future<void> _deletePayment(Payment payment) async {
    final l10n = context.l10n;
    final confirmed = await confirmDialog(
      context,
      title: l10n.commonDelete,
      message: l10n.commonConfirmDelete,
    );
    if (!confirmed || !mounted) return;
    try {
      final DurusApi api = ref.read(apiProvider);
      await api.deletePayment(payment.id);
      ref.invalidate(paymentsProvider);
      ref.invalidate(feesProvider);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.commonError)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final paymentsAsync = ref.watch(paymentsProvider);
    final payments = paymentsAsync.value ?? const <Payment>[];
    final feePayments = payments
        .where((p) => p.feeId == widget.fee.id)
        .toList()
      ..sort((a, b) => b.paidAt.compareTo(a.paidAt));

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.75,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.feesAddPayment,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: l10n.commonClose,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (paymentsAsync.isLoading)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (paymentsAsync.hasError)
                  ErrorRetry(
                    message: l10n.commonError,
                    onRetry: () => ref.invalidate(paymentsProvider),
                  )
                else if (feePayments.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(l10n.commonEmpty, textAlign: TextAlign.center),
                  )
                else
                  for (final payment in feePayments)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      leading: const Icon(Icons.payments_outlined),
                      title: Text(
                        '${_fmtAmount(payment.amount)} • '
                        '${_paymentMethodLabel(l10n, payment.method)}',
                      ),
                      subtitle: () {
                        final note = payment.note;
                        return Text(
                          note == null || note.isEmpty
                              ? payment.paidAt
                              : '${payment.paidAt} • $note',
                        );
                      }(),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        tooltip: l10n.commonDelete,
                        onPressed: () => _deletePayment(payment),
                      ),
                    ),
                const Divider(height: 32),
                TextField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: l10n.feesAmount,
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _method,
                  decoration: InputDecoration(
                    labelText: l10n.feesPaymentMethod,
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: [
                    DropdownMenuItem(value: 'cash', child: Text(l10n.feesMethodCash)),
                    DropdownMenuItem(value: 'transfer', child: Text(l10n.feesMethodTransfer)),
                    DropdownMenuItem(value: 'other', child: Text(l10n.feesMethodOther)),
                  ],
                  onChanged: (value) =>
                      setState(() => _method = value ?? 'cash'),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _saving ? null : _addPayment,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add),
                  label: Text(l10n.commonAdd),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

String _fmtAmount(num value) {
  if (value == value.truncateToDouble()) return value.toInt().toString();
  return value.toStringAsFixed(2);
}

String _isoDate(DateTime date) {
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

String _studentName(List<Student> students, String id) {
  for (final student in students) {
    if (student.id == id) return student.name;
  }
  return '';
}

({String label, Color color}) _feeStatus(
  AppLocalizations l10n,
  String? status,
) {
  return switch (status) {
    'paid' => (label: l10n.feesStatusPaid, color: Colors.green),
    'partial' => (label: l10n.feesStatusPartial, color: Colors.amber),
    'unpaid' => (label: l10n.feesStatusUnpaid, color: Colors.red),
    _ => (label: l10n.commonNone, color: Colors.grey),
  };
}

String _paymentMethodLabel(AppLocalizations l10n, String? method) {
  return switch (method) {
    'cash' => l10n.feesMethodCash,
    'transfer' => l10n.feesMethodTransfer,
    'other' => l10n.feesMethodOther,
    _ => l10n.commonNone,
  };
}