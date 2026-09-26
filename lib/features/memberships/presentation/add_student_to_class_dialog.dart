import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../app/common_widgets/searchable_selectors.dart';
import '../../../l10n/app_localizations.dart';
import '../../students/domain/student.dart';
import '../../students/domain/student_service.dart';
import '../domain/membership_service.dart';

class AddStudentToClassDialog extends ConsumerStatefulWidget {
  final int classId;
  final VoidCallback onSuccess;
  const AddStudentToClassDialog({
    super.key,
    required this.classId,
    required this.onSuccess,
  });

  @override
  ConsumerState<AddStudentToClassDialog> createState() =>
      _AddStudentToClassDialogState();
}

class _AddStudentToClassDialogState
    extends ConsumerState<AddStudentToClassDialog> {
  Student? _selectedStudent;
  DateTime _joinDate = DateTime.now();
  final _mienGiamController = TextEditingController(text: '0');
  final _ghiChuController = TextEditingController();

  @override
  void dispose() {
    _mienGiamController.dispose();
    _ghiChuController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final studentsAsync = ref.watch(studentListProvider);

    return AlertDialog(
      title: Text(l10n.actionEnrollStudent),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            studentsAsync.when(
              data: (students) => InkWell(
                onTap: () async {
                  final picked = await showStudentSelectorDialog(
                    context,
                    students: students.where((s) => !s.daLuuTru).toList(),
                  );
                  if (picked != null) {
                    setState(() => _selectedStudent = picked);
                  }
                },
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: l10n.selectStudent,
                    border: const OutlineInputBorder(),
                    suffixIcon: const Icon(Icons.search),
                  ),
                  child: Text(
                    _selectedStudent?.hoTen ?? l10n.studentSearchPlaceholder,
                    style: TextStyle(
                      color: _selectedStudent == null
                          ? Theme.of(context).hintColor
                          : null,
                      fontWeight: _selectedStudent != null
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ),
              loading: () => const CircularProgressIndicator(),
              error: (e, _) => Text('${l10n.commonError}: $e'),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.membershipStartDate),
              subtitle: Text(DateFormat('yyyy-MM-dd').format(_joinDate)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _joinDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (picked != null) setState(() => _joinDate = picked);
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _mienGiamController,
              decoration: const InputDecoration(
                labelText: 'Miễn giảm (%)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _ghiChuController,
              decoration: InputDecoration(
                labelText: l10n.studentNotes,
                border: const OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.commonCancel),
        ),
        ElevatedButton(
          onPressed: _selectedStudent == null ? null : _submit,
          child: Text(l10n.commonSave),
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
        joinDate: _joinDate,
        mienGiam: int.tryParse(_mienGiamController.text) ?? 0,
        ghiChu: _ghiChuController.text,
      );
      widget.onSuccess();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }
}

final studentListProvider = FutureProvider<List<Student>>((ref) async {
  final service = await ref.watch(studentServiceProvider.future);
  return service.getStudents();
});
