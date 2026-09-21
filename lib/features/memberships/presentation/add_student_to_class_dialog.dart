import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../students/domain/student_service.dart';
import '../../students/domain/student.dart';
import '../domain/membership_service.dart';

class AddStudentToClassDialog extends ConsumerStatefulWidget {
  final int classId;
  final VoidCallback onSuccess;
  const AddStudentToClassDialog({super.key, required this.classId, required this.onSuccess});

  @override
  ConsumerState<AddStudentToClassDialog> createState() => _AddStudentToClassDialogState();
}

class _AddStudentToClassDialogState extends ConsumerState<AddStudentToClassDialog> {
  Student? _selectedStudent;
  final _joinDateController = TextEditingController(text: DateFormat('yyyy-MM-dd').format(DateTime.now()));
  final _mienGiamController = TextEditingController(text: '0');
  final _ghiChuController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(studentListProvider);

    return AlertDialog(
      title: const Text('Thêm học sinh vào lớp'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            studentsAsync.when(
              data: (students) => DropdownButtonFormField<Student>(
                value: _selectedStudent,
                decoration: const InputDecoration(labelText: 'Chọn học sinh', border: OutlineInputBorder()),
                items: students.map((s) => DropdownMenuItem(value: s, child: Text(s.hoTen))).toList(),
                onChanged: (v) => setState(() => _selectedStudent = v),
              ),
              loading: () => const CircularProgressIndicator(),
              error: (e, _) => Text('Lỗi tải HS: $e'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _joinDateController,
              decoration: const InputDecoration(labelText: 'Ngày bắt đầu (YYYY-MM-DD)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _mienGiamController,
              decoration: const InputDecoration(labelText: 'Miễn giảm (%)', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _ghiChuController,
              decoration: const InputDecoration(labelText: 'Ghi chú', border: OutlineInputBorder()),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
        ElevatedButton(
          onPressed: _selectedStudent == null ? null : _submit,
          child: const Text('Thêm'),
        ),
      ],
    );
  }

  void _submit() async {
    try {
      final service = await ref.read(membershipServiceProvider.future);
      await service.enrollStudent(
        studentId: _selectedStudent!.id!,
        classId: widget.classId,
        joinDate: DateTime.parse(_joinDateController.text),
        mienGiam: int.tryParse(_mienGiamController.text) ?? 0,
        ghiChu: _ghiChuController.text,
      );
      widget.onSuccess();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }
}

// Simple provider for student list in dropdown
final studentListProvider = FutureProvider<List<Student>>((ref) async {
  final service = await ref.watch(studentServiceProvider.future);
  return service.getStudents();
});
