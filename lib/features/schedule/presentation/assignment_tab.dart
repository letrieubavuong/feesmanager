import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/common_widgets/app_feedback.dart';
import '../../../app/common_widgets/navy_components.dart';
import '../../../app/common_widgets/student_avatar.dart';
import '../../../app/design_system/app_theme.dart';
import '../../../core/utils/date_formatter.dart';
import '../../memberships/presentation/membership_providers.dart';
import '../../students/presentation/student_detail_page.dart';
import '../domain/class_schedule.dart';
import '../domain/student_shift_assignment.dart';
import 'assignment_controller.dart';
import 'schedule_controller.dart';
import '../../schedule_conflicts/presentation/schedule_conflict_providers.dart';

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
                  const Text(
                    'Phân ca học sinh',
                    style: TextStyle(
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
                    icon: const Icon(Icons.person_add_outlined, size: 16),
                    label: const Text('Phân ca mới'),
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
                      return const Center(
                        child: Text(
                          'Chưa có lịch học định kỳ nào để phân ca.',
                          style: TextStyle(
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
                                      schedule.thuTrongTuan == 7
                                          ? 'Chủ Nhật'
                                          : 'Thứ ${schedule.thuTrongTuan + 1}',
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
                                    '${shiftAssignments.length} học sinh',
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Divider(color: AppColors.border, height: 1),
                              const SizedBox(height: 8),
                              if (shiftAssignments.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child: Text(
                                    'Chưa có học sinh trong ca này',
                                    style: TextStyle(
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
                      'Lỗi: $e',
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
                  'Lỗi: $e',
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddAssignmentDialog(BuildContext context, WidgetRef ref) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => AddAssignmentBottomSheet(classId: classId),
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
                    s?.hoTen ?? 'Chưa rõ tên',
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
                  error: (_, __) => const Text(
                    'Lỗi',
                    style: TextStyle(color: AppColors.error, fontSize: 13),
                  ),
                ),
                Text(
                  'Từ: ${DateFormatter.formatDisplayDate(assignment.tuNgay)}${assignment.denNgay != null ? ' - ${DateFormatter.formatDisplayDate(assignment.denNgay!)}' : ''}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          AppStatusChip(
            label: isActive ? 'Đang học' : 'Kết thúc',
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
                const PopupMenuItem(
                  value: 'edit_date',
                  child: Row(
                    children: [
                      Icon(
                        Icons.edit_calendar_outlined,
                        size: 18,
                        color: AppColors.cyanAccent,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Sửa ngày bắt đầu',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'change_shift',
                  child: Row(
                    children: [
                      Icon(
                        Icons.published_with_changes,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Chuyển ca',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'close',
                  child: Row(
                    children: [
                      Icon(
                        Icons.stop_circle_outlined,
                        size: 18,
                        color: AppColors.error,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Kết thúc phân ca',
                        style: TextStyle(color: AppColors.error, fontSize: 13),
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
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.parse(assignment.tuNgay),
      lastDate: DateTime(2100),
      helpText: 'CHỌN NGÀY KẾT THÚC PHÂN CA',
    );

    if (pickedDate != null && context.mounted) {
      try {
        await ref
            .read(classAssignmentControllerProvider(classId).notifier)
            .close(assignmentId: assignment.id!, endDate: pickedDate);
        if (context.mounted) {
          AppFeedback.showSuccessSnackBar(
            context,
            'Đã kết thúc phân ca học sinh',
          );
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
  int? _selectedStudentId;
  int? _selectedScheduleId;
  DateTime _startDate = DateTime.now();
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedScheduleId = widget.initialScheduleId;
  }

  @override
  Widget build(BuildContext context) {
    final schedulesAsync = ref.watch(
      classScheduleControllerProvider(widget.classId),
    );
    final rosterAsync = ref.watch(
      classRosterProvider((widget.classId, _startDate)),
    );

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
                'Phân ca học sinh',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
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
              rosterAsync.when(
                data: (memberships) {
                  if (memberships.isEmpty) {
                    return const Text(
                      'Không có học sinh nào đang tham gia lớp.',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontStyle: FontStyle.italic,
                      ),
                    );
                  }
                  return DropdownButtonFormField<int>(
                    initialValue: _selectedStudentId,
                    decoration: const InputDecoration(
                      labelText: 'Chọn học sinh',
                      border: OutlineInputBorder(),
                    ),
                    items: memberships.map((m) {
                      final student = ref
                          .watch(studentDetailProvider(m.idHocSinh))
                          .value;
                      return DropdownMenuItem(
                        value: m.idHocSinh,
                        child: Text(
                          student?.hoTen ?? 'Học sinh #${m.idHocSinh}',
                        ),
                      );
                    }).toList(),
                    onChanged: (v) => setState(() => _selectedStudentId = v),
                  );
                },
                loading: () =>
                    const CircularProgressIndicator(color: AppColors.primary),
                error: (e, _) => Text(
                  'Lỗi: $e',
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
              const SizedBox(height: 16),
              schedulesAsync.when(
                data: (schedules) {
                  final activeSchedules = schedules
                      .where((s) => s.isEffectiveOn(DateTime.now()))
                      .toList();
                  return DropdownButtonFormField<int>(
                    initialValue: _selectedScheduleId,
                    decoration: const InputDecoration(
                      labelText: 'Chọn ca học',
                      border: OutlineInputBorder(),
                    ),
                    items: activeSchedules.map((s) {
                      return DropdownMenuItem(
                        value: s.id!,
                        child: Text(
                          '${DateFormatter.formatVietnameseWeekday(s.thuTrongTuan)}: ${s.gioBatDau}-${s.gioKetThuc}',
                        ),
                      );
                    }).toList(),
                    onChanged: (v) => setState(() => _selectedScheduleId = v),
                  );
                },
                loading: () =>
                    const CircularProgressIndicator(color: AppColors.primary),
                error: (e, _) => Text(
                  'Lỗi: $e',
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Ngày bắt đầu ca'),
                subtitle: Text(DateFormatter.formatDisplayDate(_startDate)),
                trailing: const Icon(
                  Icons.calendar_today,
                  color: AppColors.cyanAccent,
                ),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _startDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setState(() => _startDate = picked);
                },
              ),
              const SizedBox(height: 16),
              _buildConflictPreviewCard(ref),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                    child: const Text('Hủy'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _canSubmit(ref) ? _submit : null,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check),
                    label: const Text('Xác nhận'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _canSubmit(WidgetRef ref) {
    if (_isSaving ||
        _selectedStudentId == null ||
        _selectedScheduleId == null) {
      return false;
    }
    final startDateStr = DateFormatter.formatCanonicalDate(_startDate);
    final previewAsync = ref.watch(
      assignmentConflictPreviewProvider((
        _selectedStudentId!,
        _selectedScheduleId!,
        startDateStr,
        null,
        null,
      )),
    );
    if (previewAsync.isLoading || previewAsync.hasError) return false;
    return previewAsync.value?.canAssign == true;
  }

  Widget _buildConflictPreviewCard(WidgetRef ref) {
    if (_selectedStudentId == null || _selectedScheduleId == null) {
      return const SizedBox.shrink();
    }
    final startDateStr = DateFormatter.formatCanonicalDate(_startDate);
    final previewAsync = ref.watch(
      assignmentConflictPreviewProvider((
        _selectedStudentId!,
        _selectedScheduleId!,
        startDateStr,
        null,
        null,
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

  void _submit() async {
    if (_selectedStudentId == null || _selectedScheduleId == null) {
      setState(() => _error = 'Vui lòng chọn học sinh và ca học');
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final result = await ref
          .read(classAssignmentControllerProvider(widget.classId).notifier)
          .assign(
            studentId: _selectedStudentId!,
            classId: widget.classId,
            scheduleId: _selectedScheduleId!,
            startDate: _startDate,
          );

      if (result.canAssign) {
        if (mounted) {
          AppFeedback.showSuccessSnackBar(
            context,
            'Phân ca học sinh thành công',
          );
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          setState(() {
            _isSaving = false;
            _error =
                result.conflictReason ?? 'Không thể phân ca do xung đột lịch';
          });
        }
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
                    'Sửa ngày bắt đầu phân ca',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Học sinh: ${student?.hoTen ?? 'N/A'}',
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
                    title: const Text('Ngày bắt đầu phân ca mới'),
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
                        child: const Text('Hủy'),
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
                                      'Cập nhật ngày bắt đầu phân ca thành công',
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
                        label: const Text('Lưu thay đổi'),
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

class ChangeShiftBottomSheet extends StatefulWidget {
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
  State<ChangeShiftBottomSheet> createState() => _ChangeShiftBottomSheetState();
}

class _ChangeShiftBottomSheetState extends State<ChangeShiftBottomSheet> {
  int? _newScheduleId;
  DateTime _effectiveDate = DateTime.now();
  bool _isSaving = false;
  String? _error;

  bool _canSubmit(WidgetRef ref) {
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

  Widget _buildConflictPreviewCard(WidgetRef ref) {
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
    final otherSchedules = widget.schedules
        .where(
          (s) =>
              s.id != widget.assignment.idLichHoc &&
              s.isEffectiveOn(_effectiveDate),
        )
        .toList();

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
                    'Chuyển ca học định kỳ',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Học sinh: ${student?.hoTen ?? 'N/A'}',
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
                    initialValue: _newScheduleId,
                    decoration: const InputDecoration(
                      labelText: 'Chọn ca học mới',
                      border: OutlineInputBorder(),
                    ),
                    items: otherSchedules.map((s) {
                      return DropdownMenuItem(
                        value: s.id!,
                        child: Text(
                          '${DateFormatter.formatVietnameseWeekday(s.thuTrongTuan)}: ${s.gioBatDau}-${s.gioKetThuc}',
                        ),
                      );
                    }).toList(),
                    onChanged: (v) => setState(() => _newScheduleId = v),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Ngày áp dụng ca mới'),
                    subtitle: Text(
                      DateFormatter.formatDisplayDate(_effectiveDate),
                    ),
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
                        setState(() => _effectiveDate = picked);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildConflictPreviewCard(ref),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _isSaving
                            ? null
                            : () => Navigator.pop(context),
                        child: const Text('Hủy'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _canSubmit(ref)
                            ? () async {
                                if (_newScheduleId == null) {
                                  setState(
                                    () => _error = 'Vui lòng chọn ca học mới',
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
                                      'Chuyển ca học sinh thành công',
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
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.check),
                        label: const Text('Xác nhận'),
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
