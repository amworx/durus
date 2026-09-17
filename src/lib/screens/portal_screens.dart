import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:durus/core/utils.dart';
import 'package:durus/l10n/l10n_ext.dart';
import 'package:durus/providers/providers.dart';
import 'package:durus/widgets/widgets.dart';

/// Parent portal entry: the parent pastes the PIN link token and is taken to
/// `/portal/<token>`. Works on any screen (responsive web-first).
class PortalEntryScreen extends ConsumerStatefulWidget {
  const PortalEntryScreen({super.key});

  @override
  ConsumerState<PortalEntryScreen> createState() =>
      _PortalEntryScreenState();
}

class _PortalEntryScreenState extends ConsumerState<PortalEntryScreen> {
  final _tokenController = TextEditingController();

  static final _tokenPattern = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    caseSensitive: false,
  );

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!mounted) return;
    final token = _tokenController.text.trim();
    if (token.isEmpty) return;
    if (!_tokenPattern.hasMatch(token)) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(context.l10n.portalInvalid)));
      return;
    }
    context.go('/portal/$token');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Icon(Icons.school, size: 48, color: scheme.primary),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.portalTitle,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.portalNotificationsHint,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _tokenController,
                      textAlign: TextAlign.center,
                      autocorrect: false,
                      enableSuggestions: false,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        letterSpacing: 1.2,
                      ),
                      decoration: InputDecoration(
                        labelText: l10n.portalTokenLabel,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.key),
                      ),
                      onSubmitted: (_) => _submit(),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _submit,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(l10n.portalEnter),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Parent portal home for a single student. Fetches the aggregated portal map
/// plus recent notifications for the token. Pull-to-refresh re-fetches both.
class PortalHomeScreen extends ConsumerStatefulWidget {
  const PortalHomeScreen({super.key, required this.token});

  final String token;

  @override
  ConsumerState<PortalHomeScreen> createState() => _PortalHomeScreenState();
}

class _PortalHomeScreenState extends ConsumerState<PortalHomeScreen> {
  Map<String, dynamic>? _data;
  Map<String, dynamic> _notifMap = const {};
  List<Map<String, dynamic>> _family = const [];
  List<Map<String, dynamic>> _excuses = const [];
  Set<String> _receiptKeys = const {};
  DateTime _excuseDate = DateTime.now().add(const Duration(days: 1));
  final TextEditingController _excuseReasonCtrl = TextEditingController();
  bool _sendingExcuse = false;
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    _excuseDate = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);
    _load();
  }

  @override
  void dispose() {
    _excuseReasonCtrl.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(PortalHomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Child switcher navigates to the same route with another token —
    // reload everything instead of showing stale data.
    if (oldWidget.token != widget.token) {
      _data = null;
      _notifMap = const {};
      _family = const [];
      _excuses = const [];
      _receiptKeys = const {};
      _load();
    }
  }

  Future<void> _load() async {
    final api = ref.read(apiProvider);
    if (_data == null) {
      setState(() {
        _loading = true;
        _error = false;
      });
    }
    try {
      final data = await api.parentPortal(widget.token);
      if (!mounted) return;
      setState(() {
        _data = data;
        _loading = false;
        _error = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = true;
      });
      return;
    }
    try {
      final notifMap = await api.parentNotifications(widget.token);
      if (!mounted) return;
      setState(() => _notifMap = notifMap);
    } catch (_) {
      // Notifications are auxiliary — the portal data stays visible.
    }
    try {
      final family = await api.parentFamily(widget.token);
      if (!mounted) return;
      setState(() => _family = family);
    } catch (_) {
      // Unlinked students simply show no switcher.
    }
    try {
      final excuses = await api.parentExcuses(widget.token);
      if (!mounted) return;
      setState(() => _excuses = excuses);
    } catch (_) {
      // Excuse history is auxiliary.
    }
    try {
      final receipts = await api.parentReceipts(widget.token);
      if (!mounted) return;
      setState(() => _receiptKeys = receipts);
    } catch (_) {
      // Confirm states default to unconfirmed.
    }
  }

  // ---------- helpers for the portal jsonb map ----------

  Map<String, dynamic> _mapOf(dynamic value) =>
      value is Map<String, dynamic> ? value : const <String, dynamic>{};

  List<dynamic> _listOf(dynamic value) =>
      value is List<dynamic> ? value : const <dynamic>[];

  List<String> _stringsOf(dynamic value) => [
        for (final e in _listOf(value))
          if (e is String) e,
      ];

  String _stringOf(dynamic value) => value is String ? value : '';

  String _numLabel(dynamic value) {
    if (value is int) return value.toString();
    if (value is double) {
      return value == value.roundToDouble()
          ? value.toInt().toString()
          : value.toString();
    }
    return '';
  }

  String _dateLabel(dynamic value) {
    if (value is! String) return '';
    final date = DateTime.tryParse(value);
    if (date == null) return '';
    return fmtDate(date.toLocal());
  }

  /// Attendance recent rows carry a date-only string; tests too.
  List<dynamic> get _notifItems =>
      _notifMap['items'] is List<dynamic>
          ? _notifMap['items'] as List<dynamic>
          : const <dynamic>[];

  int get _notifUnread {
    final unread = _notifMap['unread'];
    return unread is int ? unread : 0;
  }

  String _studentNameOf(Map<String, dynamic> data) {
    final student = _mapOf(data['student']);
    return _stringOf(student['name']);
  }

  void _backToEntry() {
    context.go('/portal');
  }

  // ---------- actions ----------

  Future<void> _markParentItemRead(Map<String, dynamic> item) async {
    final id = item['id'];
    if (id is! String) return;
    final api = ref.read(apiProvider);
    await api.parentMarkRead(widget.token, [id]);
    if (!mounted) return;
    setState(() {
      final items = _listOf(_notifMap['items']);
      for (final it in items) {
        if (it is Map<String, dynamic> && it['id'] == id) {
          it['is_read'] = true;
        }
      }
      final unread = _notifUnread;
      if (unread > 0) {
        _notifMap['unread'] = unread - 1;
      }
    });
  }

  Future<void> _markAllParentRead() async {
    final items = [
      for (final it in _notifItems)
        if (it is Map<String, dynamic>) it,
    ];
    final ids = <String>[
      for (final it in items)
        if (it['id'] case final String id) id,
    ];
    if (ids.isEmpty) return;
    final api = ref.read(apiProvider);
    await api.parentMarkRead(widget.token, ids);
    if (!mounted) return;
    setState(() {
      for (final it in items) {
        it['is_read'] = true;
      }
      _notifMap['unread'] = 0;
    });
  }

  /// Absence excuse form + sent history. Reporting notifies the assigned
  /// teacher immediately; the unique (student, date) constraint prevents
  /// double-sending the same day.
  Widget _absenceSection(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return _sectionCard(
      context,
      l10n.portalAbsenceTitle,
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${l10n.portalAbsenceDate}: ${fmtDate(_excuseDate)}',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              TextButton.icon(
                onPressed: _pickExcuseDate,
                icon: const Icon(Icons.event_outlined),
                label: Text(l10n.portalAbsenceChange),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _excuseReasonCtrl,
            maxLength: 200,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: l10n.portalAbsenceReason,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _sendingExcuse ? null : _sendExcuse,
            child: Text(l10n.portalAbsenceSend),
          ),
          if (_excuses.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              l10n.portalAbsenceHistory,
              style: theme.textTheme.labelLarge,
            ),
            const SizedBox(height: 4),
            for (final e in _excuses)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  '${_dateLabel(e['date'])} • ${_stringOf(e['reason'])}',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
          ],
        ],
      ),
    );
  }

  Future<void> _pickExcuseDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _excuseDate,
      firstDate: today.subtract(const Duration(days: 30)),
      lastDate: today.add(const Duration(days: 90)),
    );
    if (picked != null && mounted) {
      setState(
        () => _excuseDate = DateTime(picked.year, picked.month, picked.day),
      );
    }
  }

  Future<void> _sendExcuse() async {
    final l10n = context.l10n;
    final reason = _excuseReasonCtrl.text.trim();
    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.portalAbsenceRequired)),
      );
      return;
    }
    setState(() => _sendingExcuse = true);
    try {
      await ref.read(apiProvider).parentReportAbsence(
            token: widget.token,
            date: isoDate(_excuseDate),
            reason: reason,
          );
      if (!mounted) return;
      _excuseReasonCtrl.clear();
      setState(() => _sendingExcuse = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.portalAbsenceSent)),
      );
      try {
        final excuses = await ref.read(apiProvider).parentExcuses(widget.token);
        if (!mounted) return;
        setState(() => _excuses = excuses);
      } catch (_) {
        // List refreshes on next load.
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _sendingExcuse = false);
      final msg = e.toString().contains('already_exists')
          ? l10n.portalAbsenceExists
          : l10n.portalActionFailed;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  // ---------- labels ----------

  String _attendanceStatusLabel(BuildContext context, String status) {
    final l10n = context.l10n;
    return switch (status) {
      'present' => l10n.portalPresent,
      'absent' => l10n.portalAbsent,
      'late' => l10n.portalLate,
      'rescheduled' => l10n.portalRescheduled,
      'cancelled' => l10n.portalCancelled,
      _ => status,
    };
  }

  Color _attendanceStatusColor(ColorScheme scheme, String status) {
    return switch (status) {
      'present' => scheme.primaryContainer,
      'absent' => scheme.errorContainer,
      'late' => scheme.tertiaryContainer,
      'rescheduled' => scheme.tertiaryContainer,
      'cancelled' => scheme.surfaceContainerHighest,
      _ => scheme.surfaceContainerHighest,
    };
  }

  String _locationLabel(BuildContext context, String location) {
    final l10n = context.l10n;
    return switch (location) {
      'student_home' => l10n.studentsLocationHome,
      'teacher_home' => l10n.studentsLocationTeacher,
      _ => location,
    };
  }

  String _feeStatusLabel(BuildContext context, String status) {
    final l10n = context.l10n;
    return switch (status) {
      'paid' => l10n.feesStatusPaid,
      'partial' => l10n.feesStatusPartial,
      'unpaid' => l10n.feesStatusUnpaid,
      _ => status,
    };
  }

  Color _feeStatusColor(ColorScheme scheme, String status) {
    return switch (status) {
      'paid' => scheme.primaryContainer,
      'partial' => scheme.tertiaryContainer,
      'unpaid' => scheme.errorContainer,
      _ => scheme.surfaceContainerHighest,
    };
  }

  String _testTypeLabel(BuildContext context, String type) {
    final l10n = context.l10n;
    return switch (type) {
      'monthly' => l10n.testsTypeMonthly,
      'midterm' => l10n.testsTypeMidterm,
      'final' => l10n.testsTypeFinal,
      'quiz' => l10n.testsTypeQuiz,
      'other' => l10n.testsTypeOther,
      _ => type,
    };
  }

  int _attendancePercent(dynamic total, dynamic present) {
    if (total is! num || present is! num || total <= 0) return 0;
    return ((present / total) * 100).round();
  }

  /// ClassDojo-style child switcher for linked siblings. Each child keeps
  /// its own token (no privilege change) — tapping navigates to that
  /// child's portal view, which reloads via didUpdateWidget.
  Widget _familySwitcher(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.portalFamilyChildren,
            style: theme.textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final sib in _family) _familyChip(context, sib),
            ],
          ),
        ],
      ),
    );
  }

  Widget _familyChip(BuildContext context, Map<String, dynamic> sib) {
    final token = sib['token'];
    final selected = token is String && token == widget.token;
    final name = _stringOf(sib['name']);
    final grade = _stringOf(sib['grade']);
    return ChoiceChip(
      label: Text(grade.isEmpty ? name : '$name • $grade'),
      selected: selected,
      avatar: CircleAvatar(
        child: Text(name.isEmpty ? '?' : name.characters.first),
      ),
      onSelected: (_) {
        if (token is String && token.isNotEmpty && !selected) {
          context.go('/portal/$token');
        }
      },
    );
  }

  // ---------- build ----------

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final data = _data;

    if (_error) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.portalTitle)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                EmptyState(icon: Icons.link_off, message: l10n.portalInvalid),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _backToEntry,
                  child: Text(l10n.portalEnter),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_loading || data == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.portalTitle)),
        body: const LoadingView(),
      );
    }

    final studentName = _studentNameOf(data);
    final attendance = _mapOf(data['attendance']);
    final schedule = _listOf(data['schedule']);
    final fee = _mapOf(data['fee']);
    final tests = _listOf(data['tests']);
    final notes = _listOf(data['notes']);
    final announcements = _listOf(data['announcements']);

    return Scaffold(
      appBar: AppBar(
        title: Text(studentName.isEmpty ? l10n.portalTitle : studentName),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_family.length > 1) _familySwitcher(context),
                    _headerSection(context, data),
                    _notificationsSection(context),
                    _absenceSection(context),
                    _attendanceSection(context, attendance),
                    _scheduleSection(context, schedule),
                    _feeSection(context, fee),
                    _statsSection(context, attendance, tests),
                    _testsSection(context, tests),
                    _notesSection(context, notes),
                    _announcementsSection(context, announcements),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard(BuildContext context, String title, Widget child) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: SectionCard(title: title, child: child),
    );
  }

  Widget _metricRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: theme.textTheme.bodyMedium),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyBlock(BuildContext context, String message) {
    final theme = Theme.of(context);
    return Text(
      message,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _divider() => const Divider(height: 24);

  // ---------- sections ----------

  Widget _headerSection(BuildContext context, Map<String, dynamic> data) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final student = _mapOf(data['student']);
    final name = _stringOf(student['name']);
    final grade = _stringOf(student['grade']);
    final subjects = _stringsOf(data['subjects']);

    return _sectionCard(
      context,
      l10n.portalStudentName,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name.isEmpty ? l10n.portalNoData : name,
            style: theme.textTheme.headlineSmall,
          ),
          if (grade.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              '${l10n.portalGrade}: $grade',
              style: theme.textTheme.bodyMedium,
            ),
          ],
          const SizedBox(height: 16),
          Text(l10n.portalSubjects, style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          if (subjects.isEmpty)
            _emptyBlock(context, l10n.portalNoData)
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [for (final s in subjects) Chip(label: Text(s))],
            ),
        ],
      ),
    );
  }

  Widget _notificationsSection(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final items = [
      for (final it in _notifItems)
        if (it is Map<String, dynamic>) it,
    ];
    final unread = _notifUnread;

    return _sectionCard(
      context,
      l10n.portalNotifications,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.notificationsLatest,
                  style: theme.textTheme.titleSmall,
                ),
              ),
              if (unread > 0) ...[
                StatusChip(label: '$unread', color: scheme.primaryContainer),
                const SizedBox(width: 4),
              ],
              TextButton(
                onPressed: items.isEmpty ? null : _markAllParentRead,
                child: Text(l10n.notificationsMarkAll),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: _emptyBlock(context, l10n.portalNoData),
            )
          else
            for (var i = 0; i < items.length; i++) ...[
              _notificationTile(context, items[i]),
              if (i < items.length - 1) _divider(),
            ],
        ],
      ),
    );
  }

  Widget _notificationTile(BuildContext context, Map<String, dynamic> item) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isRead = item['is_read'] == true;
    final title = _stringOf(item['title']);
    final body = _stringOf(item['body']);
    final date = _dateLabel(item['created_at']);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: isRead ? null : () async => _markParentItemRead(item),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 12),
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isRead ? Colors.transparent : scheme.primary,
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight:
                          isRead ? FontWeight.normal : FontWeight.bold,
                    ),
                  ),
                  if (body.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(body, style: theme.textTheme.bodyMedium),
                  ],
                  if (date.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      date,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _attendanceSection(
    BuildContext context,
    Map<String, dynamic> attendance,
  ) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final recent = _listOf(attendance['recent']);
    final total = attendance['total'];
    final hasData = total is num && total > 0;

    return _sectionCard(
      context,
      l10n.portalAttendance,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!hasData)
            _emptyBlock(context, l10n.portalNoData)
          else ...[
            Text(
              '${_attendancePercent(total, attendance['present'])}%',
              style: theme.textTheme.displayMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: scheme.primary,
              ),
            ),
            Text(
              l10n.portalAttendancePercent,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            _metricRow(
              context,
              l10n.portalTotalSessions,
              _numLabel(total),
            ),
            _metricRow(
              context,
              l10n.portalPresent,
              _numLabel(attendance['present']),
            ),
            _metricRow(
              context,
              l10n.portalAbsent,
              _numLabel(attendance['absent']),
            ),
            _metricRow(
              context,
              l10n.portalLate,
              _numLabel(attendance['late']),
            ),
            _metricRow(
              context,
              l10n.portalRescheduled,
              _numLabel(attendance['rescheduled']),
            ),
            _metricRow(
              context,
              l10n.portalCancelled,
              _numLabel(attendance['cancelled']),
            ),
            if (recent.isNotEmpty) ...[
              const SizedBox(height: 8),
              _divider(),
              for (var i = 0; i < recent.length; i++) ...[
                _attendanceRecentRow(context, recent[i]),
                if (i < recent.length - 1) _divider(),
              ],
            ],
          ],
        ],
      ),
    );
  }

  Widget _attendanceRecentRow(BuildContext context, dynamic entry) {
    if (entry is! Map<String, dynamic>) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final status = _stringOf(entry['status']);
    final statusLabel = _attendanceStatusLabel(context, status);
    final date = _dateLabel(entry['date']);
    final subject = _stringOf(entry['subject']);
    final note = _stringOf(entry['note']);
    final detail = [date, if (note.isNotEmpty) note].join(' · ');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subject.isEmpty ? date : subject,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (detail.isNotEmpty)
                  Text(
                    detail,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          StatusChip(
            label: statusLabel,
            color: _attendanceStatusColor(theme.colorScheme, status),
          ),
        ],
      ),
    );
  }

  Widget _scheduleSection(BuildContext context, List<dynamic> schedule) {
    final l10n = context.l10n;

    return _sectionCard(
      context,
      l10n.portalSchedule,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (schedule.isEmpty)
            _emptyBlock(context, l10n.portalNoData)
          else
            for (var i = 0; i < schedule.length; i++) ...[
              _scheduleRow(context, schedule[i]),
              if (i < schedule.length - 1) _divider(),
            ],
        ],
      ),
    );
  }

  Widget _scheduleRow(BuildContext context, dynamic slot) {
    if (slot is! Map<String, dynamic>) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dayOfWeek = slot['day_of_week'];
    final start = slot['start_minutes'];
    final end = slot['end_minutes'];
    final subject = _stringOf(slot['subject']);
    final location = _locationLabel(context, _stringOf(slot['location']));

    final day = dayOfWeek is int && dayOfWeek >= 1 && dayOfWeek <= 7
        ? arabicWeekdays[dayOfWeek - 1]
        : '';
    final time = start is int && end is int
        ? '${timeFromMinutes(start)} - ${timeFromMinutes(end)}'
        : '';
    final detail = [if (time.isNotEmpty) time, if (location.isNotEmpty) location]
        .join(' · ');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(
              day,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subject.isEmpty ? time : subject,
                  style: theme.textTheme.bodyMedium,
                ),
                if (detail.isNotEmpty)
                  Text(
                    detail,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _feeSection(BuildContext context, Map<String, dynamic> fee) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isEmpty = fee.isEmpty;
    final month = _stringOf(fee['month']);
    final amount = _numLabel(fee['amount']);
    final paid = _numLabel(fee['paid_amount']);
    final status = _stringOf(fee['status']);

    return _sectionCard(
      context,
      l10n.portalLatestFee,
      isEmpty
          ? _emptyBlock(context, l10n.portalNoData)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        month.isEmpty ? l10n.portalNoData : fmtMonthKey(month),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    StatusChip(
                      label: _feeStatusLabel(context, status),
                      color: _feeStatusColor(theme.colorScheme, status),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _metricRow(context, l10n.feesAmount, amount),
                _metricRow(context, l10n.feesPaid, paid),
              ],
            ),
    );
  }

  Widget _statsSection(
    BuildContext context,
    Map<String, dynamic> attendance,
    List<dynamic> tests,
  ) {
    final l10n = context.l10n;

    final total = attendance['total'];
    final present = attendance['present'];
    final rate = _attendancePercent(total, present);

    double? averagePct;
    var scored = 0;
    for (final item in tests) {
      if (item is! Map<String, dynamic>) continue;
      final score = item['score'];
      final maxScore = item['max_score'];
      if (score is num && maxScore is num && maxScore > 0) {
        averagePct = (averagePct ?? 0) + (score / maxScore) * 100;
        scored++;
      }
    }
    if (scored > 0) averagePct = (averagePct ?? 0) / scored;

    final rows = <Widget>[
      _metricRow(context, l10n.portalAttendancePercent, total is num && total > 0 ? '$rate%' : l10n.portalNoData),
      _metricRow(context, l10n.portalRecentTests, '${tests.length}'),
      _metricRow(
        context,
        l10n.studentsStatsTestsAverage,
        averagePct == null ? l10n.portalNoData : '${_numLabel(averagePct)}%',
      ),
    ];

    final summary = <String>[
      l10n.portalStatsTitle,
      '${l10n.portalAttendancePercent}: ${total is num && total > 0 ? '$rate%' : l10n.portalNoData}',
      '${l10n.portalRecentTests}: ${tests.length}',
      if (averagePct == null)
        l10n.studentsStatsNoTests
      else
        '${l10n.studentsStatsTestsAverage}: ${_numLabel(averagePct)}%',
    ];

    return _sectionCard(
      context,
      l10n.portalStatsTitle,
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final row in rows) row,
          const SizedBox(height: 8),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton.icon(
              onPressed: () async {
                await Clipboard.setData(
                  ClipboardData(text: summary.join('\n')),
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.portalStatsExportHint)),
                  );
                }
              },
              icon: const Icon(Icons.ios_share),
              label: Text(l10n.portalStatsShare),
            ),
          ),
        ],
      ),
    );
  }

  Widget _testsSection(BuildContext context, List<dynamic> tests) {
    final l10n = context.l10n;

    return _sectionCard(
      context,
      l10n.portalRecentTests,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (tests.isEmpty)
            _emptyBlock(context, l10n.portalNoData)
          else
            for (var i = 0; i < tests.length; i++) ...[
              _testRow(context, tests[i]),
              if (i < tests.length - 1) _divider(),
            ],
        ],
      ),
    );
  }

  Widget _testRow(BuildContext context, dynamic item) {
    if (item is! Map<String, dynamic>) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final subject = _stringOf(item['subject']);
    final type = _testTypeLabel(context, _stringOf(item['type']));
    final date = _dateLabel(item['date']);
    final score = _numLabel(item['score']);
    final maxScore = _numLabel(item['max_score']);
    final detail = [
      if (date.isNotEmpty) date,
      '${score.isEmpty ? '-' : score} / ${maxScore.isEmpty ? '-' : maxScore}',
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  subject.isEmpty ? type : subject,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              StatusChip(
                label: type,
                color: scheme.secondaryContainer,
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            detail,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _notesSection(BuildContext context, List<dynamic> notes) {
    return _textListSection(
      context,
      context.l10n.portalNotes,
      notes,
      confirmKind: 'note',
    );
  }

  Widget _announcementsSection(
    BuildContext context,
    List<dynamic> announcements,
  ) {
    return _textListSection(
      context,
      context.l10n.portalAnnouncements,
      announcements,
      confirmKind: 'announcement',
    );
  }

  Widget _textListSection(
    BuildContext context,
    String title,
    List<dynamic> entries, {
    String? confirmKind,
  }) {
    return _sectionCard(
      context,
      title,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (entries.isEmpty)
            _emptyBlock(context, context.l10n.portalNoData)
          else
            for (var i = 0; i < entries.length; i++) ...[
              _textEntryRow(context, entries[i], confirmKind),
              if (i < entries.length - 1) _divider(),
            ],
        ],
      ),
    );
  }

  Widget _textEntryRow(
    BuildContext context,
    dynamic entry, [
    String? confirmKind,
  ]) {
    if (entry is! Map<String, dynamic>) return const SizedBox.shrink();
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final body = _stringOf(entry['body']);
    final date = _dateLabel(entry['created_at']);
    final id = _stringOf(entry['id']);
    final confirmed = confirmKind != null &&
        id.isNotEmpty &&
        _receiptKeys.contains('$confirmKind:$id');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(body, style: theme.textTheme.bodyMedium),
          if (date.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              date,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          if (confirmKind != null && id.isNotEmpty) ...[
            const SizedBox(height: 6),
            if (confirmed)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.done_all,
                    size: 14,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    l10n.portalReadDone,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              )
            else
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: OutlinedButton(
                  onPressed: () => _confirmRead(confirmKind, id),
                  child: Text(l10n.portalConfirmRead),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmRead(String kind, String id) async {
    try {
      await ref.read(apiProvider).parentConfirmRead(
            token: widget.token,
            kind: kind,
            itemId: id,
          );
      if (!mounted) return;
      setState(() => _receiptKeys = {..._receiptKeys, '$kind:$id'});
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.portalActionFailed)),
      );
    }
  }
}