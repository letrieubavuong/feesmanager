import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/common_widgets/app_feedback.dart';
import '../../../app/common_widgets/navy_components.dart';
import '../../../app/common_widgets/student_avatar.dart';
import '../../../app/design_system/app_theme.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../l10n/app_localizations.dart';
import '../../students/domain/student.dart';
import '../../students/presentation/student_detail_page.dart';
import '../domain/bulk_assignment_result.dart';
import '../domain/class_schedule.dart';
import '../domain/student_shift_assignment.dart';
import 'assignment_controller.dart';
import 'schedule_controller.dart';
import '../../schedule_conflicts/presentation/schedule_conflict_providers.dart';

String _formatWeekday(int thu, AppLocalizations l10n) {
  switch (thu) {
    case 1:
      return l10n.weekdayMonday;
    case 2:
      return l10n.weekdayTuesday;
    case 3:
      return l10n.weekdayWednesday;
    case 4:
      return l10n.weekdayThursday;
    case 5:
      return l10n.weekdayFriday;
    case 6:
      return l10n.weekdaySaturday;
    case 7:
      return l10n.weekdaySunday;
    default:
      return '';
  }
}

class AssignmentTab extends ConsumerWidget {
  final int classId;
  final bool isArchived;

  const AssignmentTab({
    super.key,
    required this.classId,
    this.isArchived = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final assignmentsAsync = ref.watch(
      classAssignmentControllerProvider(classId),
    );
    final schedulesAsync = ref.watch(classScheduleControllerProvider(classId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          if (!isArchived)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.assignmentTitle,
                    style: const TextStyle(
                      color: AppColors.cyanAccent,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => _showAddAssignmentDialog(context, ref),
                    icon: const Icon(Icons.group_add_outlined, size: 16),
                    label: Text(l10n.assignmentBulkBtn),
                  ),
                ],
              ),
            ),
          Expanded(
            child: assignmentsAsync.when(
              data: (assignments) {
                return schedulesAsync.when(
                  data: (schedules) {
                    if (schedules.isEmpty) {
                      return Center(
                        child: Text(
                          l10n.assignmentNoSchedules,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      );
                    }

                    final Map<int, List<StudentShiftAssignment>> grouped = {};
                    for (final a in assignments) {
                      grouped.putIfAbsent(a.idLichHoc, () => []).add(a);
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: schedules.length,
                      itemBuilder: (context, index) {
                        final schedule = schedules[index];
                        final shiftAssignments = grouped[schedule.id!] ?? [];
                        final isActiveSchedule = schedule.isEffectiveOn(
                          DateTime.now(),
                        );
                        final todayStr = DateFormatter.formatCanonicalDate(
                          DateTime.now(),
                        );
                        final activeShiftAssignments = shiftAssignments.where((
                          a,
                        ) {
                          return a.tuNgay.compareTo(todayStr) <= 0 &&
                              (a.denNgay == null ||
                                  a.denNgay!.compareTo(todayStr) >= 0);
                        }).toList();

                        return AppSectionCard(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(
                                        alpha: 0.2,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      _formatWeekday(
                                        schedule.thuTrongTuan,
                                        l10n,
                                      ),
                                      style: const TextStyle(
                                        color: AppColors.cyanAccent,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    '${schedule.gioBatDau} - ${schedule.gioKetThuc}',
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    l10n.assignmentStudentCount(
                                      activeShiftAssignments.length,
                                    ),
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                  if (!isArchived && isActiveSchedule) ...[
                                    const SizedBox(width: 8),
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.surfaceHigh,
                                        foregroundColor: AppColors.cyanAccent,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        visualDensity: VisualDensity.compact,
                                      ),
                                      onPressed: () => _showAddAssignmentDialog(
                                        context,
                                        ref,
                                        initialScheduleId: schedule.id!,
                                      ),
                                      icon: const Icon(
                                        Icons.person_add_outlined,
                                        size: 14,
                                      ),
                                      label: Text(
                                        l10n.assignmentAddStudent,
                                        style: const TextStyle(fontSize: 11),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Divider(color: AppColors.border, height: 1),
                              const SizedBox(height: 8),
                              if (shiftAssignments.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  child: Text(
                                    l10n.assignmentNoStudentsInShift,
                                    style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                )
                              else
                                ...shiftAssignments.map(
                                  (a) => _AssignmentRowItem(
                                    assignment: a,
                                    classId: classId,
                                    isArchived: isArchived || !isActiveSchedule,
                                    schedules: schedules,
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                  error: (e, _) => Center(
                    child: Text(
                      '${l10n.commonError}: $e',
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ),
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (e, _) => Center(
                child: Text(
                  '${l10n.commonError}: $e',
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddAssignmentDialog(
    BuildContext context,
    WidgetRef ref, {
    int? initialScheduleId,
  }) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => AddAssignmentBottomSheet(
        classId: classId,
        initialScheduleId: initialScheduleId,
      ),
    );
  }
}

class _AssignmentRowItem extends ConsumerWidget {
  final StudentShiftAssignment assignment;
  final int classId;
  final bool isArchived;
  final List<ClassSchedule> schedules;

  const _AssignmentRowItem({
    required this.assignment,
    required this.classId,
    required this.isArchived,
    required this.schedules,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final studentAsync = ref.watch(studentDetailProvider(assignment.idHocSinh));
    final isActive =
        assignment.denNgay == null ||
        DateTime.parse(assignment.denNgay!).isAfter(DateTime.now());

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          studentAsync.when(
            data: (s) => StudentAvatar(
              gioiTinh: s?.gioiTinh,
              studentName: s?.hoTen,
              radius: 18,
            ),
            loading: () => const CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.surface,
              child: Icon(Icons.person, size: 16),
            ),
            error: (_, __) => const CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.surface,
              child: Icon(Icons.person, size: 16),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                studentAsync.when(
                  data: (s) => Text(
                    s?.hoTen ?? 'N/A',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                  loading: () => const Text(
                    '...',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
                  error: (_, __) => Text(
                    l10n.commonError,
                    style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 13,
                    ),
                  ),
                ),
                Text(
                  '${DateFormatter.formatDisplayDate(assignment.tuNgay)}${assignment.denNgay != null ? ' - ${DateFormatter.formatDisplayDate(assignment.denNgay!)}' : ''}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          AppStatusChip(
            label: isActive
                ? l10n.assignmentStatusActive
                : l10n.assignmentStatusClosed,
            color: isActive ? AppColors.success : AppColors.textMuted,
            compact: true,
          ),
          if (isActive && !isArchived)
            PopupMenuButton<String>(
              icon: const Icon(
                Icons.more_vert,
                color: AppColors.textSecondary,
                size: 18,
              ),
              color: AppColors.surfaceHigh,
              onSelected: (value) {
                if (value == 'edit_date') {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true,
                    builder: (_) => EditAssignmentBottomSheet(
                      assignment: assignment,
                      classId: classId,
                    ),
                  );
                } else if (value == 'change_shift') {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true,
                    builder: (_) => ChangeShiftBottomSheet(
                      assignment: assignment,
                      classId: classId,
                      schedules: schedules,
                    ),
                  );
                } else if (value == 'close') {
                  _showCloseAssignmentDialog(context, ref, assignment);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'edit_date',
                  child: Row(
                    children: [
                      const Icon(
                        Icons.edit_calendar_outlined,
                        size: 18,
                        color: AppColors.cyanAccent,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.assignmentEditStartDate,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'change_shift',
                  child: Row(
                    children: [
                      const Icon(
                        Icons.published_with_changes,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.assignmentChangeShift,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'close',
                  child: Row(
                    children: [
                      const Icon(
                        Icons.stop_circle_outlined,
                        size: 18,
                        color: AppColors.error,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.assignmentCloseShift,
                        style: const TextStyle(
                          color: AppColors.error,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  void _showCloseAssignmentDialog(
    BuildContext context,
    WidgetRef ref,
    StudentShiftAssignment assignment,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.parse(assignment.tuNgay),
      lastDate: DateTime(2100),
      helpText: l10n.assignmentCloseConfirmTitle,
    );

    if (pickedDate != null && context.mounted) {
      try {
        await ref
            .read(classAssignmentControllerProvider(classId).notifier)
            .close(assignmentId: assignment.id!, endDate: pickedDate);
        if (context.mounted) {
          AppFeedback.showSuccessSnackBar(context, l10n.assignmentCloseSuccess);
        }
      } catch (e) {
        if (context.mounted) {
          AppFeedback.showErrorSnackBar(
            context,
            e.toString().replaceAll('Exception: ', ''),
          );
        }
      }
    }
  }
}

class AddAssignmentBottomSheet extends ConsumerStatefulWidget {
  final int classId;
  final int? initialScheduleId;

  const AddAssignmentBottomSheet({
    super.key,
    required this.classId,
    this.initialScheduleId,
  });

  @override
  ConsumerState<AddAssignmentBottomSheet> createState() =>
      _AddAssignmentBottomSheetState();
}

class _AddAssignmentBottomSheetState
    extends ConsumerState<AddAssignmentBottomSheet> {
  int? _selectedScheduleId;
  DateTime _startDate = DateTime.now();
  final Set<int> _selectedStudentIds = <int>{};
  String _searchQuery = '';

  bool _isSaving = false;
  bool _isLoadingCandidates = false;
  List<Student> _candidates = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedScheduleId = widget.initialScheduleId;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadCandidates();
  }

  Future<void> _loadCandidates() async {
    if (_selectedScheduleId == null) {
      setState(() {
        _candidates = [];
        _selectedStudentIds.clear();
      });
      return;
    }

    setState(() {
      _isLoadingCandidates = true;
      _error = null;
    });

    try {
      final candidates = await ref
          .read(classAssignmentControllerProvider(widget.classId).notifier)
          .loadBulkCandidates(
            scheduleId: _selectedScheduleId!,
            startDate: _startDate,
          );

      if (mounted) {
        setState(() {
          _candidates = candidates;
          _isLoadingCandidates = false;
          _selectedStudentIds.retainWhere(
            (id) => candidates.any((c) => c.id == id),
          );
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _candidates = [];
          _isLoadingCandidates = false;
          _error = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  List<Student> get _filteredCandidates {
    if (_searchQuery.trim().isEmpty) return _candidates;
    final query = _searchQuery.trim().toLowerCase();
    return _candidates
        .where((s) => s.hoTen.toLowerCase().contains(query))
        .toList();
  }

  bool get _isAllFilteredSelected {
    final filtered = _filteredCandidates;
    if (filtered.isEmpty) return false;
    return filtered.every((s) => _selectedStudentIds.contains(s.id));
  }

  void _toggleSelectAll() {
    final filtered = _filteredCandidates;
    setState(() {
      if (_isAllFilteredSelected) {
        for (final s in filtered) {
          if (s.id != null) _selectedStudentIds.remove(s.id!);
        }
      } else {
        for (final s in filtered) {
          if (s.id != null) _selectedStudentIds.add(s.id!);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final schedulesAsync = ref.watch(
      classScheduleControllerProvider(widget.classId),
    );
    final filteredList = _filteredCandidates;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.bulkAssignmentSheetTitle,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(color: AppColors.border),
              const SizedBox(height: 12),

              if (_error != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _error!,
                    style: const TextStyle(
                      color: AppColors.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // 1. SELECT SHIFT
              schedulesAsync.when(
                data: (schedules) {
                  final activeSchedules = schedules
                      .where((s) => s.isEffectiveOn(_startDate))
                      .toList();
                  final selectedValue =
                      activeSchedules.any((s) => s.id == _selectedScheduleId)
                      ? _selectedScheduleId
                      : null;

                  return DropdownButtonFormField<int>(
                    initialValue: selectedValue,
                    decoration: InputDecoration(
                      labelText: l10n.bulkAssignmentSelectShift,
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.access_time),
                    ),
                    items: activeSchedules.map((s) {
                      final weekdayName = _formatWeekday(s.thuTrongTuan, l10n);
                      return DropdownMenuItem(
                        value: s.id!,
                        child: Text(
                          '$weekdayName: ${s.gioBatDau}-${s.gioKetThuc}',
                        ),
                      );
                    }).toList(),
                    onChanged: _isSaving
                        ? null
                        : (v) {
                            setState(() {
                              _selectedScheduleId = v;
                            });
                            _loadCandidates();
                          },
                  );
                },
                loading: () =>
                    const CircularProgressIndicator(color: AppColors.primary),
                error: (e, _) => Text(
                  '${l10n.commonError}: $e',
                  style: const TextStyle(color: AppColors.error),
                ),
              ),

              const SizedBox(height: 12),

              // 2. START DATE
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.bulkAssignmentStartDate),
                subtitle: Text(
                  DateFormatter.formatDisplayDate(_startDate),
                  style: const TextStyle(
                    color: AppColors.cyanAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                trailing: const Icon(
                  Icons.calendar_today,
                  color: AppColors.cyanAccent,
                ),
                onTap: _isSaving
                    ? null
                    : () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _startDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          final schedules =
                              ref
                                  .read(
                                    classScheduleControllerProvider(
                                      widget.classId,
                                    ),
                                  )
                                  .value ??
                              [];
                          final activeForPicked = schedules
                              .where((s) => s.isEffectiveOn(picked))
                              .toList();
                          final isStillValid = activeForPicked.any(
                            (s) => s.id == _selectedScheduleId,
                          );

                          setState(() {
                            _startDate = picked;
                            if (!isStillValid) {
                              _selectedScheduleId = null;
                              _selectedStudentIds.clear();
                              _candidates.clear();
                            }
                          });
                          _loadCandidates();
                        }
                      },
              ),

              const SizedBox(height: 12),

              // 3. CANDIDATES LIST HEADER & SEARCH
              if (_selectedScheduleId != null) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.bulkAssignmentCandidateHeader,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '${_selectedStudentIds.length}/${_candidates.length}',
                      style: const TextStyle(
                        color: AppColors.cyanAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                TextField(
                  enabled: !_isSaving,
                  decoration: InputDecoration(
                    hintText: l10n.bulkAssignmentSearchPlaceholder,
                    prefixIcon: const Icon(Icons.search, size: 20),
                    isDense: true,
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
                const SizedBox(height: 8),

                if (_isLoadingCandidates)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                  )
                else if (_candidates.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceHigh,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      l10n.bulkAssignmentAllAssigned,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  )
                else ...[
                  CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      l10n.bulkAssignmentSelectAll(filteredList.length),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    value: _isAllFilteredSelected,
                    onChanged: _isSaving ? null : (_) => _toggleSelectAll(),
                  ),
                  const Divider(color: AppColors.border, height: 1),

                  Container(
                    constraints: const BoxConstraints(maxHeight: 220),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: filteredList.length,
                      separatorBuilder: (_, __) =>
                          const Divider(color: AppColors.border, height: 1),
                      itemBuilder: (ctx, idx) {
                        final student = filteredList[idx];
                        final isSelected = _selectedStudentIds.contains(
                          student.id,
                        );

                        return CheckboxListTile(
                          dense: true,
                          value: isSelected,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 4,
                          ),
                          title: Row(
                            children: [
                              StudentAvatar(
                                gioiTinh: student.gioiTinh,
                                studentName: student.hoTen,
                                radius: 16,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  student.hoTen,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          onChanged: _isSaving
                              ? null
                              : (bool? checked) {
                                  if (student.id == null) return;
                                  setState(() {
                                    if (checked == true) {
                                      _selectedStudentIds.add(student.id!);
                                    } else {
                                      _selectedStudentIds.remove(student.id!);
                                    }
                                  });
                                },
                        );
                      },
                    ),
                  ),
                ],
              ],

              const SizedBox(height: 20),

              // SUBMIT BUTTON
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: (_isSaving || _selectedStudentIds.isEmpty)
                      ? null
                      : _startBulkProcess,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.group_add),
                  label: Text(
                    _isSaving
                        ? l10n.bulkAssignmentProcessing
                        : l10n.bulkAssignmentSubmit(_selectedStudentIds.length),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _startBulkProcess() async {
    if (_selectedScheduleId == null || _selectedStudentIds.isEmpty) return;

    final l10n = AppLocalizations.of(context)!;

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final controller = ref.read(
        classAssignmentControllerProvider(widget.classId).notifier,
      );

      // Step 1: Preview bulk assignment
      final preview = await controller.previewBulk(
        studentIds: _selectedStudentIds.toList(),
        scheduleId: _selectedScheduleId!,
        startDate: _startDate,
      );

      if (!mounted) return;

      if (preview.blocked.isNotEmpty || preview.warnings.isNotEmpty) {
        // Show preview summary before write
        final proceed = await _showPreviewSummarySheet(context, preview, l10n);
        if (proceed != true) {
          setState(() => _isSaving = false);
          return;
        }
      }

      // Step 2: Execute bulk transaction
      final result = await controller.assignBulk(
        studentIds: _selectedStudentIds.toList(),
        scheduleId: _selectedScheduleId!,
        startDate: _startDate,
      );

      if (mounted) {
        setState(() => _isSaving = false);
        AppFeedback.showSuccessSnackBar(
          context,
          l10n.bulkAssignmentSuccess(result.successCount),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _error = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  Future<bool?> _showPreviewSummarySheet(
    BuildContext context,
    BulkAssignmentPreview preview,
    AppLocalizations l10n,
  ) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.bulkAssignmentPreviewTitle,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Divider(color: AppColors.border),
              const SizedBox(height: 8),

              Text(
                l10n.bulkAssignmentPreviewReady(preview.readyStudents.length),
                style: const TextStyle(
                  color: AppColors.success,
                  fontWeight: FontWeight.bold,
                ),
              ),

              if (preview.blocked.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  l10n.bulkAssignmentPreviewBlocked(preview.blocked.length),
                  style: const TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  constraints: const BoxConstraints(maxHeight: 150),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: preview.blocked.length,
                    itemBuilder: (c, i) {
                      final item = preview.blocked[i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          '• ${item.studentName}: ${item.message ?? l10n.commonError}',
                          style: const TextStyle(
                            color: AppColors.error,
                            fontSize: 12,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],

              if (preview.warnings.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  l10n.bulkAssignmentPreviewWarnings(preview.warnings.length),
                  style: const TextStyle(
                    color: AppColors.warning,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  constraints: const BoxConstraints(maxHeight: 120),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: preview.warnings.length,
                    itemBuilder: (c, i) {
                      final item = preview.warnings[i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          '• ${item.studentName}: ${item.message ?? ""}',
                          style: const TextStyle(
                            color: AppColors.warning,
                            fontSize: 12,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],

              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text(l10n.commonCancel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: preview.readyStudents.isNotEmpty
                          ? () => Navigator.pop(ctx, true)
                          : null,
                      child: Text(
                        l10n.bulkAssignmentPreviewConfirmBtn(
                          preview.readyStudents.length,
                        ),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EditAssignmentBottomSheet extends StatefulWidget {
  final StudentShiftAssignment assignment;
  final int classId;

  const EditAssignmentBottomSheet({
    super.key,
    required this.assignment,
    required this.classId,
  });

  @override
  State<EditAssignmentBottomSheet> createState() =>
      _EditAssignmentBottomSheetState();
}

class _EditAssignmentBottomSheetState extends State<EditAssignmentBottomSheet> {
  late DateTime _newStartDate;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _newStartDate =
        DateFormatter.parseCanonicalDate(widget.assignment.tuNgay) ??
        DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Consumer(
      builder: (context, ref, _) {
        final student = ref
            .watch(studentDetailProvider(widget.assignment.idHocSinh))
            .value;
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.editStartDateTitle,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${l10n.creditsHeaderStudent}: ${student?.hoTen ?? 'N/A'}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_error != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _error!,
                        style: const TextStyle(
                          color: AppColors.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.editStartDateNew),
                    subtitle: Text(
                      DateFormatter.formatDisplayDate(_newStartDate),
                    ),
                    trailing: const Icon(
                      Icons.calendar_today,
                      color: AppColors.cyanAccent,
                    ),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _newStartDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() => _newStartDate = picked);
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _isSaving
                            ? null
                            : () => Navigator.pop(context),
                        child: Text(l10n.commonCancel),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _isSaving
                            ? null
                            : () async {
                                setState(() {
                                  _isSaving = true;
                                  _error = null;
                                });
                                try {
                                  await ref
                                      .read(
                                        classAssignmentControllerProvider(
                                          widget.classId,
                                        ).notifier,
                                      )
                                      .updateStartDate(
                                        assignmentId: widget.assignment.id!,
                                        newStartDate: _newStartDate,
                                      );
                                  if (context.mounted) {
                                    AppFeedback.showSuccessSnackBar(
                                      context,
                                      l10n.editStartDateSuccess,
                                    );
                                    Navigator.pop(context);
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    setState(() {
                                      _isSaving = false;
                                      _error = e.toString().replaceAll(
                                        'Exception: ',
                                        '',
                                      );
                                    });
                                  }
                                }
                              },
                        icon: _isSaving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.check),
                        label: Text(l10n.commonSave),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class ChangeShiftBottomSheet extends ConsumerStatefulWidget {
  final StudentShiftAssignment assignment;
  final int classId;
  final List<ClassSchedule> schedules;

  const ChangeShiftBottomSheet({
    super.key,
    required this.assignment,
    required this.classId,
    required this.schedules,
  });

  @override
  ConsumerState<ChangeShiftBottomSheet> createState() =>
      _ChangeShiftBottomSheetState();
}

class _ChangeShiftBottomSheetState
    extends ConsumerState<ChangeShiftBottomSheet> {
  int? _newScheduleId;
  DateTime _effectiveDate = DateTime.now();
  bool _isSaving = false;
  String? _error;

  bool get _canSubmit {
    if (_isSaving || _newScheduleId == null) {
      return false;
    }
    final effectiveDateStr = DateFormatter.formatCanonicalDate(_effectiveDate);
    final previewAsync = ref.watch(
      assignmentConflictPreviewProvider((
        widget.assignment.idHocSinh,
        _newScheduleId!,
        effectiveDateStr,
        null,
        widget.assignment.id,
      )),
    );
    if (previewAsync.isLoading || previewAsync.hasError) return false;
    return previewAsync.value?.canAssign == true;
  }

  Widget _buildConflictPreviewCard() {
    if (_newScheduleId == null) {
      return const SizedBox.shrink();
    }
    final effectiveDateStr = DateFormatter.formatCanonicalDate(_effectiveDate);
    final previewAsync = ref.watch(
      assignmentConflictPreviewProvider((
        widget.assignment.idHocSinh,
        _newScheduleId!,
        effectiveDateStr,
        null,
        widget.assignment.id,
      )),
    );

    return previewAsync.when(
      data: (result) {
        if (result.hasConflicts) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.error_outline, color: AppColors.error, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'XUNG ĐỘT BẮT BUỘC',
                      style: TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  result.hardConflicts.isNotEmpty
                      ? result.hardConflicts.first.message
                      : 'Xung đột lịch học',
                  style: const TextStyle(color: AppColors.error, fontSize: 12),
                ),
              ],
            ),
          );
        } else if (result.hasWarnings) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.warning.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.warning_amber_outlined,
                      color: AppColors.warning,
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'CẢNH BÁO KHÔNG ƯU TIÊN',
                      style: TextStyle(
                        color: AppColors.warning,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  result.softWarnings.first.message,
                  style: const TextStyle(
                    color: AppColors.warning,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        } else {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: AppColors.success,
                  size: 18,
                ),
                SizedBox(width: 8),
                Text(
                  'Lịch học hợp lệ, không có xung đột',
                  style: TextStyle(
                    color: AppColors.success,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }
      },
      loading: () => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(8),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LinearProgressIndicator(
              color: AppColors.primary,
              backgroundColor: AppColors.surface,
            ),
            SizedBox(height: 6),
            Text(
              'Đang kiểm tra trùng lịch...',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
      ),
      error: (e, _) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'Lỗi kiểm tra trùng lịch: $e',
          style: const TextStyle(color: AppColors.error, fontSize: 12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final otherSchedules = widget.schedules
        .where(
          (s) =>
              s.id != widget.assignment.idLichHoc &&
              s.isEffectiveOn(_effectiveDate),
        )
        .toList();

    final student = ref
        .watch(studentDetailProvider(widget.assignment.idHocSinh))
        .value;

    final selectedNewScheduleValue =
        otherSchedules.any((s) => s.id == _newScheduleId)
        ? _newScheduleId
        : null;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.changeShiftTitle,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                '${l10n.creditsHeaderStudent}: ${student?.hoTen ?? 'N/A'}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 16),
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _error!,
                    style: const TextStyle(
                      color: AppColors.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              DropdownButtonFormField<int>(
                initialValue: selectedNewScheduleValue,
                decoration: InputDecoration(
                  labelText: l10n.changeShiftSelectNew,
                  border: const OutlineInputBorder(),
                ),
                items: otherSchedules.map((s) {
                  final weekdayName = _formatWeekday(s.thuTrongTuan, l10n);
                  return DropdownMenuItem(
                    value: s.id!,
                    child: Text('$weekdayName: ${s.gioBatDau}-${s.gioKetThuc}'),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _newScheduleId = v),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.changeShiftEffectiveDate),
                subtitle: Text(DateFormatter.formatDisplayDate(_effectiveDate)),
                trailing: const Icon(
                  Icons.calendar_today,
                  color: AppColors.cyanAccent,
                ),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _effectiveDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    final otherForPicked = widget.schedules
                        .where(
                          (s) =>
                              s.id != widget.assignment.idLichHoc &&
                              s.isEffectiveOn(picked),
                        )
                        .toList();
                    final isStillValid = otherForPicked.any(
                      (s) => s.id == _newScheduleId,
                    );

                    setState(() {
                      _effectiveDate = picked;
                      if (!isStillValid) {
                        _newScheduleId = null;
                      }
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              _buildConflictPreviewCard(),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                    child: Text(l10n.commonCancel),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _canSubmit
                        ? () async {
                            if (_newScheduleId == null) {
                              setState(
                                () => _error = l10n.changeShiftValidationSelect,
                              );
                              return;
                            }
                            setState(() {
                              _isSaving = true;
                              _error = null;
                            });
                            try {
                              await ref
                                  .read(
                                    classAssignmentControllerProvider(
                                      widget.classId,
                                    ).notifier,
                                  )
                                  .changeShift(
                                    studentId: widget.assignment.idHocSinh,
                                    oldAssignmentId: widget.assignment.id!,
                                    newScheduleId: _newScheduleId!,
                                    effectiveDate: _effectiveDate,
                                  );
                              if (context.mounted) {
                                AppFeedback.showSuccessSnackBar(
                                  context,
                                  l10n.changeShiftSuccess,
                                );
                                Navigator.pop(context);
                              }
                            } catch (e) {
                              if (context.mounted) {
                                setState(() {
                                  _isSaving = false;
                                  _error = e.toString().replaceAll(
                                    'Exception: ',
                                    '',
                                  );
                                });
                              }
                            }
                          }
                        : null,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check),
                    label: Text(l10n.commonConfirm),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
