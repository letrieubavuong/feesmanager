import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'schedule_controller.dart';
import 'assignment_controller.dart';
import '../../students/domain/student.dart';
import '../../students/domain/student_service.dart';
import '../../memberships/domain/membership_service.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../students/presentation/student_detail_page.dart';
import '../../students/presentation/student_controller.dart';

class AssignmentTab extends ConsumerWidget {
  final int classId;
  const AssignmentTab({super.key, required this.classId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schedulesAsync = ref.watch(classScheduleControllerProvider(classId));
    final assignmentsAsync = ref.watch(classAssignmentControllerProvider(classId));

    return Scaffold(
      body: assignmentsAsync.when(
        data: (assignments) {
          return schedulesAsync.when(
            data: (schedules) {
               final activeSchedules = schedules.where((s) => s.isEffectiveOn(DateTime.now())).toList();
               if (activeSchedules.isEmpty) {
                 return const Center(child: Text('Cần tạo lịch học trước khi phân ca.'));
               }
               
               return ListView.builder(
                 itemCount: activeSchedules.length,
                 itemBuilder: (context, index) {
                   final s = activeSchedules[index];
                   final shiftAssignments = assignments.where((a) => a.idLichHoc == s.id && (a.denNgay == null)).toList();
                   
                   return ExpansionTile(
                     leading: CircleAvatar(child: Text(s.thuTrongTuan == 7 ? 'CN' : 'T${s.thuTrongTuan + 1}')),
                     title: Text(
                       '${DateFormatter.formatVietnameseWeekday(s.thuTrongTuan)}: ${s.gioBatDau} - ${s.gioKetThuc}',
                     ),
                     subtitle: Text('${shiftAssignments.length} học sinh'),
                     children: [
                        ...shiftAssignments.map((a) => ListTile(
                          leading: const Icon(Icons.person, size: 16),
                          title: Consumer(builder: (context, ref, _) {
                             final studentAsync = ref.watch(studentDetailProvider(a.idHocSinh));
                             return studentAsync.when(
                               data: (st) => Text(st?.hoTen ?? 'Unknown'),
                               loading: () => const Text('...'),
                               error: (_, __) => const Text('Error'),
                             );
                          }),
                          subtitle: Text('Từ: ${a.tuNgay}'),
                        )),
                        ListTile(
                          leading: const Icon(Icons.add, color: Colors.blue),
                          title: const Text('Phân học sinh vào ca này', style: TextStyle(color: Colors.blue)),
                          onTap: () => _showAssignDialog(context, ref, s),
                        )
                     ],
                   );
                 },
               );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Lỗi tải lịch: $e')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi tải phân ca: $e')),
      ),
    );
  }

  void _showAssignDialog(BuildContext context, WidgetRef ref, s) {
    // We reuse student list from Phase 2 but filter for active in class later?
    // Actually, should only show students active in THIS class.
    showDialog(
      context: context,
      builder: (context) => AssignStudentDialog(classId: classId, scheduleId: s.id!),
    );
  }
}

class AssignStudentDialog extends ConsumerStatefulWidget {
  final int classId;
  final int scheduleId;
  const AssignStudentDialog({super.key, required this.classId, required this.scheduleId});

  @override
  ConsumerState<AssignStudentDialog> createState() => _AssignStudentDialogState();
}

class _AssignStudentDialogState extends ConsumerState<AssignStudentDialog> {
  int? _selectedStudentId;
  DateTime _startDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(assignmentCandidateProvider((widget.classId, _startDate)));

    return AlertDialog(
      title: const Text('Phân ca cho học sinh'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          studentsAsync.when(
            data: (students) => DropdownButtonFormField<int>(
              value: _selectedStudentId,
              decoration: const InputDecoration(labelText: 'Chọn học sinh'),
              items: students.map((s) => DropdownMenuItem(value: s.id, child: Text(s.hoTen))).toList(),
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
                 lastDate: DateTime(2100)
               );
               if (picked != null) {
                 setState(() {
                   _startDate = picked;
                   _selectedStudentId = null; // Reset selection as candidate list might change
                 });
               }
            },
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
        ElevatedButton(
          onPressed: _selectedStudentId == null ? null : _submit,
          child: const Text('Xác nhận'),
        ),
      ],
    );
  }

  void _submit() async {
    try {
      final result = await ref.read(classAssignmentControllerProvider(widget.classId).notifier).assign(
        studentId: _selectedStudentId!,
        classId: widget.classId,
        scheduleId: widget.scheduleId,
        startDate: _startDate,
      );

      if (result.canAssign) {
        if (mounted) Navigator.pop(context);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.conflictReason ?? 'Lỗi không xác định')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))));
      }
    }
  }
}

final assignmentCandidateProvider = FutureProvider.family<List<Student>, (int, DateTime)>((ref, arg) async {
  final membershipService = await ref.watch(membershipServiceProvider.future);
  final studentService = await ref.watch(studentServiceProvider.future);
  
  final activeIds = await membershipService.getActiveStudentIdsInClass(arg.$1, arg.$2);
  final allStudents = await studentService.getStudents();
  
  return allStudents.where((s) => activeIds.contains(s.id)).toList();
});
