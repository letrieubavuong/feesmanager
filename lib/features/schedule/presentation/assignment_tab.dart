import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/date_formatter.dart';
import '../../schedule_conflicts/presentation/schedule_conflict_banner.dart';
import '../../schedule_conflicts/presentation/schedule_conflict_providers.dart';
import '../../students/domain/student.dart';
import '../../students/presentation/student_detail_page.dart';
import '../domain/class_schedule.dart';
import '../domain/schedule_service.dart';
import '../domain/student_shift_assignment.dart';
import 'assignment_controller.dart';
import 'schedule_controller.dart';

class AssignmentTab extends ConsumerWidget {
  final int classId;

  const AssignmentTab({super.key, required this.classId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schedulesAsync = ref.watch(classScheduleControllerProvider(classId));
    final assignmentsAsync = ref.watch(
      classAssignmentControllerProvider(classId),
    );

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
              context,
              'Các ca học của lớp',
              'Quản lý học sinh phân ca theo từng ca học định kỳ',
            ),
            const SizedBox(height: 16),
            schedulesAsync.when(
              data: (schedules) {
                if (schedules.isEmpty) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Lớp chưa có lịch học định kỳ. Vui lòng tạo lịch học ở tab Lịch học trước.',
                      ),
                    ),
                  );
                }

                return Column(
                  children: schedules.map((schedule) {
                    return _buildScheduleAssignmentCard(
                      context,
                      ref,
                      schedule,
                      assignmentsAsync,
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Lỗi tải lịch học: $e'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    String subtitle,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildScheduleAssignmentCard(
    BuildContext context,
    WidgetRef ref,
    ClassSchedule schedule,
    AsyncValue<List<StudentShiftAssignment>> assignmentsAsync,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.access_time, color: Colors.teal),
                    const SizedBox(width: 8),
                    Text(
                      '${DateFormatter.formatVietnameseWeekday(schedule.thuTrongTuan)}: ${schedule.gioBatDau} - ${schedule.gioKetThuc}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AssignStudentDialog(
                        classId: classId,
                        scheduleId: schedule.id!,
                      ),
                    );
                  },
                  icon: const Icon(Icons.person_add, size: 16),
                  label: const Text('Phân ca HS'),
                ),
              ],
            ),
            const Divider(height: 24),
            assignmentsAsync.when(
              data: (assignments) {
                final activeAssignmentsForThisSchedule = assignments
                    .where(
                      (a) =>
                          a.idLichHoc == schedule.id &&
                          a.isActiveOn(DateTime.now()),
                    )
                    .toList();

                if (activeAssignmentsForThisSchedule.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Chưa có học sinh nào phân ca ở khung giờ này.',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: activeAssignmentsForThisSchedule.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final assignment = activeAssignmentsForThisSchedule[index];
                    return _buildStudentAssignmentTile(
                      context,
                      ref,
                      assignment,
                      schedule,
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Lỗi tải danh sách phân ca: $e'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentAssignmentTile(
    BuildContext context,
    WidgetRef ref,
    StudentShiftAssignment a,
    ClassSchedule currentSchedule,
  ) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: Colors.teal.shade50,
        child: const Icon(Icons.person, color: Colors.teal),
      ),
      title: Consumer(
        builder: (context, ref, _) {
          final studentAsync = ref.watch(studentDetailProvider(a.idHocSinh));
          return studentAsync.when(
            data: (s) => Text(
              s?.hoTen ?? 'Chưa rõ tên',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            loading: () => const Text('Đang tải...'),
            error: (_, __) => const Text('Lỗi'),
          );
        },
      ),
      subtitle: Text(
        'Áp dụng từ: ${a.tuNgay}${a.denNgay != null ? ' - ${a.denNgay}' : ''}',
        style: const TextStyle(fontSize: 12),
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (value) {
          if (value == 'change_shift') {
            _showChangeShiftDialog(context, ref, a, currentSchedule);
          } else if (value == 'close_assignment') {
            _showCloseAssignmentDialog(context, ref, a);
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'change_shift',
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.swap_horiz, size: 18),
                SizedBox(width: 8),
                Flexible(
                  child: Text('Chuyển ca', overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'close_assignment',
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.stop_circle_outlined, size: 18, color: Colors.red),
                SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Kết thúc phân ca',
                    style: TextStyle(color: Colors.red),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showChangeShiftDialog(
    BuildContext context,
    WidgetRef ref,
    StudentShiftAssignment a,
    ClassSchedule currentSchedule,
  ) {
    int? selectedScheduleId;
    DateTime effectiveDate = DateTime.now();

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Chuyển ca học định kỳ'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Ngày bắt đầu ca mới'),
                subtitle: Text(DateFormat('dd/MM/yyyy').format(effectiveDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: effectiveDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    setDialogState(() => effectiveDate = picked);
                  }
                },
              ),
              const SizedBox(height: 16),
              Consumer(
                builder: (context, ref, _) {
                  final schedulesAsync = ref.watch(
                    classScheduleControllerProvider(classId),
                  );
                  return schedulesAsync.when(
                    data: (schedules) => DropdownButtonFormField<int>(
                      initialValue: selectedScheduleId,
                      decoration: const InputDecoration(
                        labelText: 'Chọn ca mới',
                      ),
                      items: schedules
                          .where(
                            (s) =>
                                s.id != currentSchedule.id &&
                                s.isEffectiveOn(effectiveDate),
                          )
                          .map(
                            (s) => DropdownMenuItem(
                              value: s.id,
                              child: Text(
                                '${DateFormatter.formatVietnameseWeekday(s.thuTrongTuan)}: ${s.gioBatDau}-${s.gioKetThuc}',
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) =>
                          setDialogState(() => selectedScheduleId = v),
                    ),
                    loading: () => const CircularProgressIndicator(),
                    error: (e, _) => Text('Lỗi tải lịch: $e'),
                  );
                },
              ),
              if (selectedScheduleId != null) ...[
                const SizedBox(height: 12),
                Consumer(
                  builder: (context, ref, _) {
                    final previewAsync = ref.watch(
                      assignmentConflictPreviewProvider((
                        a.idHocSinh,
                        selectedScheduleId!,
                        DateFormat('yyyy-MM-dd').format(effectiveDate),
                        null,
                        a.id,
                      )),
                    );
                    return previewAsync.when(
                      data: (res) => ScheduleConflictBanner(result: res),
                      loading: () => const LinearProgressIndicator(),
                      error: (e, _) => Text('Lỗi kiểm tra trùng lịch: $e'),
                    );
                  },
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            Consumer(
              builder: (context, ref, _) {
                bool isBlocked = false;
                if (selectedScheduleId != null) {
                  final previewAsync = ref.watch(
                    assignmentConflictPreviewProvider((
                      a.idHocSinh,
                      selectedScheduleId!,
                      DateFormat('yyyy-MM-dd').format(effectiveDate),
                      null,
                      a.id,
                    )),
                  );
                  isBlocked = previewAsync.when(
                    data: (res) => !res.canAssign,
                    loading: () => true,
                    error: (_, __) => true,
                  );
                }

                return ElevatedButton(
                  onPressed: (selectedScheduleId == null || isBlocked)
                      ? null
                      : () async {
                          try {
                            await ref
                                .read(
                                  classAssignmentControllerProvider(
                                    classId,
                                  ).notifier,
                                )
                                .changeShift(
                                  studentId: a.idHocSinh,
                                  oldAssignmentId: a.id!,
                                  newScheduleId: selectedScheduleId!,
                                  effectiveDate: effectiveDate,
                                );
                            if (context.mounted) Navigator.pop(context);
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    e.toString().replaceAll('Exception: ', ''),
                                  ),
                                ),
                              );
                            }
                          }
                        },
                  child: const Text('Xác nhận'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCloseAssignmentDialog(
    BuildContext context,
    WidgetRef ref,
    StudentShiftAssignment a,
  ) {
    DateTime endDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Kết thúc phân ca'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Học sinh sẽ không còn học ca này từ ngày kết thúc.'),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Ngày kết thúc'),
                subtitle: Text(DateFormat('dd/MM/yyyy').format(endDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: endDate,
                    firstDate: DateTime.parse(a.tuNgay),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    setDialogState(() => endDate = picked);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await ref
                      .read(classAssignmentControllerProvider(classId).notifier)
                      .close(assignmentId: a.id!, endDate: endDate);
                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          e.toString().replaceAll('Exception: ', ''),
                        ),
                      ),
                    );
                  }
                }
              },
              child: const Text('Xác nhận kết thúc'),
            ),
          ],
        ),
      ),
    );
  }
}

class AssignStudentDialog extends ConsumerStatefulWidget {
  final int classId;
  final int scheduleId;
  const AssignStudentDialog({
    super.key,
    required this.classId,
    required this.scheduleId,
  });

  @override
  ConsumerState<AssignStudentDialog> createState() =>
      _AssignStudentDialogState();
}

class _AssignStudentDialogState extends ConsumerState<AssignStudentDialog> {
  int? _selectedStudentId;
  DateTime _startDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(
      assignmentCandidateProvider((widget.classId, _startDate)),
    );

    return AlertDialog(
      title: const Text('Phân ca cho học sinh'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            studentsAsync.when(
              data: (students) => DropdownButtonFormField<int>(
                initialValue: _selectedStudentId,
                decoration: const InputDecoration(labelText: 'Chọn học sinh'),
                items: students
                    .map(
                      (s) =>
                          DropdownMenuItem(value: s.id, child: Text(s.hoTen)),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _selectedStudentId = v),
              ),
              loading: () => const CircularProgressIndicator(),
              error: (e, _) => Text('Lỗi: $e'),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Ngày bắt đầu áp dụng'),
              subtitle: Text(DateFormat('dd/MM/yyyy').format(_startDate)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _startDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (picked != null) {
                  setState(() {
                    _startDate = picked;
                    _selectedStudentId = null;
                  });
                }
              },
            ),
            if (_selectedStudentId != null) ...[
              const SizedBox(height: 12),
              Consumer(
                builder: (context, ref, _) {
                  final previewAsync = ref.watch(
                    assignmentConflictPreviewProvider((
                      _selectedStudentId!,
                      widget.scheduleId,
                      DateFormat('yyyy-MM-dd').format(_startDate),
                      null,
                      null,
                    )),
                  );
                  return previewAsync.when(
                    data: (res) => ScheduleConflictBanner(result: res),
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) => Text('Lỗi kiểm tra trùng lịch: $e'),
                  );
                },
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        Consumer(
          builder: (context, ref, _) {
            bool isBlocked = false;
            if (_selectedStudentId != null) {
              final previewAsync = ref.watch(
                assignmentConflictPreviewProvider((
                  _selectedStudentId!,
                  widget.scheduleId,
                  DateFormat('yyyy-MM-dd').format(_startDate),
                  null,
                  null,
                )),
              );
              isBlocked = previewAsync.when(
                data: (res) => !res.canAssign,
                loading: () => true,
                error: (_, __) => true,
              );
            }

            return ElevatedButton(
              onPressed: (_selectedStudentId == null || isBlocked)
                  ? null
                  : _submit,
              child: const Text('Xác nhận'),
            );
          },
        ),
      ],
    );
  }

  void _submit() async {
    try {
      final result = await ref
          .read(classAssignmentControllerProvider(widget.classId).notifier)
          .assign(
            studentId: _selectedStudentId!,
            classId: widget.classId,
            scheduleId: widget.scheduleId,
            startDate: _startDate,
          );

      if (result.canAssign) {
        if (mounted) Navigator.pop(context);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.conflictReason ?? 'Lỗi không xác định'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }
}

final assignmentCandidateProvider =
    FutureProvider.family<List<Student>, (int, DateTime)>((ref, arg) async {
      final service = await ref.watch(classScheduleServiceProvider.future);
      return service.getAssignmentCandidates(arg.$1, arg.$2);
    });
