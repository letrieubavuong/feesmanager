import 'package:flutter/material.dart';
import '../../features/classes/domain/class.dart';
import '../../features/students/domain/student.dart';
import '../../l10n/app_localizations.dart';

class StudentSelectorDialog extends StatefulWidget {
  final List<Student> students;
  final String? title;

  const StudentSelectorDialog({super.key, required this.students, this.title});

  @override
  State<StudentSelectorDialog> createState() => _StudentSelectorDialogState();
}

class _StudentSelectorDialogState extends State<StudentSelectorDialog> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final filtered = widget.students.where((s) {
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return s.hoTen.toLowerCase().contains(q) ||
          (s.sdtHocSinh?.contains(q) ?? false) ||
          (s.sdtPhuHuynh?.contains(q) ?? false);
    }).toList();

    return AlertDialog(
      title: Text(widget.title ?? l10n.selectStudent),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: l10n.studentSearchPlaceholder,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _query = v.trim()),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: filtered.isEmpty
                  ? Center(child: Text(l10n.noStudentsFound))
                  : ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final student = filtered[index];
                        return ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.person),
                          ),
                          title: Text(student.hoTen),
                          subtitle: Text(
                            student.truongDangHoc ??
                                (student.sdtHocSinh != null
                                    ? 'SĐT: ${student.sdtHocSinh}'
                                    : 'ID: ${student.id}'),
                          ),
                          onTap: () => Navigator.of(context).pop(student),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
      ],
    );
  }
}

class ClassSelectorDialog extends StatefulWidget {
  final List<ClassEntity> classes;
  final String? title;

  const ClassSelectorDialog({super.key, required this.classes, this.title});

  @override
  State<ClassSelectorDialog> createState() => _ClassSelectorDialogState();
}

class _ClassSelectorDialogState extends State<ClassSelectorDialog> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final filtered = widget.classes.where((c) {
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return c.tenLop.toLowerCase().contains(q) ||
          (c.monHoc?.toLowerCase().contains(q) ?? false);
    }).toList();

    return AlertDialog(
      title: Text(widget.title ?? l10n.selectClass),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: l10n.classSearchPlaceholder,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _query = v.trim()),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: filtered.isEmpty
                  ? Center(child: Text(l10n.noClassesFound))
                  : ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final cls = filtered[index];
                        return ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.class_outlined),
                          ),
                          title: Text(cls.tenLop),
                          subtitle: Text(
                            cls.monHoc != null && cls.monHoc!.isNotEmpty
                                ? 'Môn: ${cls.monHoc}'
                                : 'ID: ${cls.id}',
                          ),
                          onTap: () => Navigator.of(context).pop(cls),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
      ],
    );
  }
}

Future<Student?> showStudentSelectorDialog(
  BuildContext context, {
  required List<Student> students,
  String? title,
}) {
  return showDialog<Student>(
    context: context,
    builder: (_) => StudentSelectorDialog(students: students, title: title),
  );
}

Future<ClassEntity?> showClassSelectorDialog(
  BuildContext context, {
  required List<ClassEntity> classes,
  String? title,
}) {
  return showDialog<ClassEntity>(
    context: context,
    builder: (_) => ClassSelectorDialog(classes: classes, title: title),
  );
}
