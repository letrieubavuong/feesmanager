import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../l10n/app_localizations.dart';
import '../../classes/presentation/class_controller.dart';
import '../../students/presentation/student_controller.dart';
import '../domain/report_scope.dart';
import 'report_controller.dart';

class ReportFilterBottomSheet extends ConsumerStatefulWidget {
  const ReportFilterBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const ReportFilterBottomSheet(),
    );
  }

  @override
  ConsumerState<ReportFilterBottomSheet> createState() =>
      _ReportFilterBottomSheetState();
}

class _ReportFilterBottomSheetState
    extends ConsumerState<ReportFilterBottomSheet> {
  late ReportMode _tempMode;
  late String _tempFromDate;
  late String _tempToDate;
  int? _tempClassId;
  int? _tempStudentId;

  bool _isInit = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      final scope = ref.read(reportScopeNotifierProvider);
      _tempMode = scope.mode;
      _tempFromDate = scope.fromDate;
      _tempToDate = scope.toDate;
      _tempClassId = scope.classId;
      _tempStudentId = scope.studentId;
      _isInit = true;
    }
  }

  void _applyFilters() {
    final notifier = ref.read(reportScopeNotifierProvider.notifier);
    if (_tempMode == ReportMode.month) {
      final monthStr = _tempFromDate.substring(0, 7);
      notifier.setMonth(monthStr);
    } else {
      notifier.setCustomRange(_tempFromDate, _tempToDate);
    }
    notifier.setClassFilter(_tempClassId);
    notifier.setStudentFilter(_tempStudentId);

    Navigator.of(context).pop();
  }

  void _resetFilters() {
    final now = DateTime.now();
    final currentMonth = DateFormat('yyyy-MM').format(now);
    final notifier = ref.read(reportScopeNotifierProvider.notifier);
    notifier.setMonth(currentMonth);

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final viewInsets = MediaQuery.of(context).viewInsets;
    final classesAsync = ref.watch(classListControllerProvider);
    final studentsAsync = ref.watch(studentListControllerProvider);

    final now = DateTime.now();
    final months = List.generate(12, (i) {
      final date = DateTime(now.year, now.month - i, 1);
      return DateFormat('yyyy-MM').format(date);
    });

    final currentMonthStr = _tempFromDate.length >= 7
        ? _tempFromDate.substring(0, 7)
        : DateFormat('yyyy-MM').format(now);

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sheet Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.filter_alt_outlined,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.reportsFilterTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 12),

            // Mode Selector
            Text(
              l10n.reportsMode,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<ReportMode>(
                segments: [
                  ButtonSegment(
                    value: ReportMode.month,
                    label: Text(l10n.reportsModeMonth),
                    icon: const Icon(Icons.calendar_month, size: 18),
                  ),
                  ButtonSegment(
                    value: ReportMode.customRange,
                    label: Text(l10n.reportsModeCustomRange),
                    icon: const Icon(Icons.date_range, size: 18),
                  ),
                ],
                selected: {_tempMode},
                onSelectionChanged: (selection) {
                  setState(() {
                    _tempMode = selection.first;
                    if (_tempMode == ReportMode.month) {
                      final monthStr = DateFormat('yyyy-MM').format(now);
                      _tempFromDate = '$monthStr-01';
                      _tempToDate = DateFormat('yyyy-MM-dd').format(now);
                    }
                  });
                },
              ),
            ),

            const SizedBox(height: 16),

            // Date Range Selection
            if (_tempMode == ReportMode.month) ...[
              DropdownButtonFormField<String>(
                initialValue: months.contains(currentMonthStr)
                    ? currentMonthStr
                    : months.first,
                decoration: InputDecoration(
                  labelText: l10n.reportsSelectMonth,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.calendar_today),
                ),
                items: months.map((m) {
                  final parts = m.split('-');
                  final display = '${parts[1]}/${parts[0]}';
                  return DropdownMenuItem<String>(
                    value: m,
                    child: Text('${l10n.reportsModeMonth} $display'),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _tempFromDate = '$val-01';
                      _tempToDate = '$val-28';
                    });
                  }
                },
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.event, size: 18),
                      label: Text(
                        '${l10n.reportsFromDate}: ${DateFormatter.formatDisplayDate(_tempFromDate)}',
                      ),
                      onPressed: () async {
                        final initial =
                            DateFormatter.parseCanonicalDate(_tempFromDate) ??
                            DateTime.now();
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: initial,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          setState(() {
                            _tempFromDate = DateFormatter.formatCanonicalDate(
                              picked,
                            );
                            if (_tempFromDate.compareTo(_tempToDate) > 0) {
                              _tempToDate = _tempFromDate;
                            }
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.event, size: 18),
                      label: Text(
                        '${l10n.reportsToDate}: ${DateFormatter.formatDisplayDate(_tempToDate)}',
                      ),
                      onPressed: () async {
                        final initial =
                            DateFormatter.parseCanonicalDate(_tempToDate) ??
                            DateTime.now();
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: initial,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          setState(() {
                            _tempToDate = DateFormatter.formatCanonicalDate(
                              picked,
                            );
                            if (_tempToDate.compareTo(_tempFromDate) < 0) {
                              _tempFromDate = _tempToDate;
                            }
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 16),

            // Class Filter Dropdown
            classesAsync.when(
              data: (classes) => DropdownButtonFormField<int?>(
                initialValue: _tempClassId,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: l10n.reportsFilterClass,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.class_outlined),
                ),
                items: [
                  DropdownMenuItem<int?>(
                    value: null,
                    child: Text(l10n.reportsAllClasses),
                  ),
                  ...classes.map(
                    (c) => DropdownMenuItem<int?>(
                      value: c.id,
                      child: Text(c.tenLop),
                    ),
                  ),
                ],
                onChanged: (val) {
                  setState(() {
                    _tempClassId = val;
                  });
                },
              ),
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const SizedBox(),
            ),

            const SizedBox(height: 16),

            // Student Filter Dropdown
            studentsAsync.when(
              data: (students) => DropdownButtonFormField<int?>(
                initialValue: _tempStudentId,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: l10n.reportsFilterStudent,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.person_outline),
                ),
                items: [
                  DropdownMenuItem<int?>(
                    value: null,
                    child: Text(l10n.reportsAllStudents),
                  ),
                  ...students.map(
                    (s) => DropdownMenuItem<int?>(
                      value: s.id,
                      child: Text(s.hoTen),
                    ),
                  ),
                ],
                onChanged: (val) {
                  setState(() {
                    _tempStudentId = val;
                  });
                },
              ),
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const SizedBox(),
            ),

            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _resetFilters,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(l10n.reportsClearFilter),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    key: const Key('apply_report_filter_btn'),
                    onPressed: _applyFilters,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      l10n.reportsApplyFilter,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
