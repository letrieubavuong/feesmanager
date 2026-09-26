import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../app/common_widgets/app_feedback.dart';
import '../../../app/common_widgets/app_page_scaffold.dart';
import '../../../app/common_widgets/dirty_form_scope.dart';
import '../../../app/common_widgets/searchable_selectors.dart';
import '../../../app/navigation/ui_keys.dart';
import '../../../l10n/app_localizations.dart';
import '../../students/domain/student.dart';
import '../../students/domain/student_service.dart';
import '../domain/membership_service.dart';

class EnrollStudentBottomSheet extends ConsumerStatefulWidget {
  final int classId;
  final int? initialStudentId;

  const EnrollStudentBottomSheet({
    super.key,
    required this.classId,
    this.initialStudentId,
  });

  @override
  ConsumerState<EnrollStudentBottomSheet> createState() =>
      _EnrollStudentBottomSheetState();
}

class _EnrollStudentBottomSheetState
    extends ConsumerState<EnrollStudentBottomSheet> {
  Student? _selectedStudent;
  DateTime _joinDate = DateTime.now();
  late TextEditingController _mienGiamController;
  late TextEditingController _ghiChuController;
  bool _isDirty = false;
  bool _isSaving = false;

  void _onChanged() {
    if (!_isDirty) {
      setState(() => _isDirty = true);
    }
  }

  @override
  void initState() {
    super.initState();
    _mienGiamController = TextEditingController(text: '0')
      ..addListener(_onChanged);
    _ghiChuController = TextEditingController()..addListener(_onChanged);
    if (widget.initialStudentId != null) {
      _loadInitialStudent();
    }
  }

  void _loadInitialStudent() async {
    final service = await ref.read(studentServiceProvider.future);
    final s = await service.getStudentById(widget.initialStudentId!);
    if (mounted && s != null) {
      setState(() => _selectedStudent = s);
    }
  }

  @override
  void dispose() {
    _mienGiamController.dispose();
    _ghiChuController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final candidatesAsync = ref.watch(
      enrollmentCandidatesProvider((
        classId: widget.classId,
        joinDate: _joinDate,
      )),
    );

    return PopScope(
      canPop: !_isDirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final canLeave = await AppPageScaffold.confirmCanLeave(
          context,
          isDirty: _isDirty,
        );
        if (canLeave && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: DirtyFormScope(
        isDirty: _isDirty,
        child: SafeArea(
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
                        l10n.actionEnrollStudent,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () async {
                          final canLeave =
                              await AppPageScaffold.confirmCanLeave(
                                context,
                                isDirty: _isDirty,
                              );
                          if (canLeave && context.mounted) {
                            Navigator.of(context).pop();
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  candidatesAsync.when(
                    data: (candidates) => InkWell(
                      key: UiKeys.enrollStudentSelector,
                      onTap: () async {
                        final picked = await showStudentSelectorDialog(
                          context,
                          students: candidates,
                        );
                        if (picked != null) {
                          _onChanged();
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
                          _selectedStudent?.hoTen ??
                              l10n.studentSearchPlaceholder,
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
                    error: (e, st) => Text('ERROR_CANDIDATES: $e'),
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
                      if (picked != null) {
                        _onChanged();
                        setState(() => _joinDate = picked);
                      }
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
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _isSaving
                            ? null
                            : () async {
                                final canLeave =
                                    await AppPageScaffold.confirmCanLeave(
                                      context,
                                      isDirty: _isDirty,
                                    );
                                if (canLeave && context.mounted) {
                                  Navigator.of(context).pop();
                                }
                              },
                        child: Text(l10n.commonCancel),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        key: UiKeys.enrollStudentSubmit,
                        onPressed: (_selectedStudent == null || _isSaving)
                            ? null
                            : _submit,
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
        ),
      ),
    );
  }

  void _submit() async {
    if (_selectedStudent == null) return;

    setState(() => _isSaving = true);

    try {
      final service = await ref.read(membershipServiceProvider.future);
      await service.enrollStudent(
        studentId: _selectedStudent!.id!,
        classId: widget.classId,
        joinDate: _joinDate,
        mienGiam: int.tryParse(_mienGiamController.text.trim()) ?? 0,
        ghiChu: _ghiChuController.text.trim(),
      );

      ref.invalidate(enrollmentCandidatesProvider);
      ref.invalidate(studentListProvider);

      if (mounted) {
        setState(() => _isSaving = false);
        _isDirty = false;
        AppFeedback.showSuccessSnackBar(
          context,
          'Đã thêm ${_selectedStudent!.hoTen} vào lớp',
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        AppFeedback.showErrorSnackBar(
          context,
          e.toString().replaceAll('Exception: ', ''),
        );
      }
    }
  }
}

Future<bool?> showEnrollStudentBottomSheet(
  BuildContext context, {
  required int classId,
  int? initialStudentId,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    useSafeArea: true,
    builder: (_) => EnrollStudentBottomSheet(
      classId: classId,
      initialStudentId: initialStudentId,
    ),
  );
}

typedef EnrollmentCandidateArgs = ({int classId, DateTime joinDate});

final enrollmentCandidatesProvider =
    FutureProvider.family<List<Student>, EnrollmentCandidateArgs>((
      ref,
      arg,
    ) async {
      final studentService = await ref.watch(studentServiceProvider.future);
      final membershipService = await ref.watch(
        membershipServiceProvider.future,
      );

      final allStudents = await studentService.getStudents();
      final candidates = <Student>[];

      for (final student in allStudents) {
        if (student.daLuuTru) continue;
        if (student.id == null) continue;

        final isOverlap = await membershipService.hasOverlappingMembership(
          studentId: student.id!,
          classId: arg.classId,
          joinDate: arg.joinDate,
        );
        if (!isOverlap) {
          candidates.add(student);
        }
      }
      return candidates;
    });

final studentListProvider = FutureProvider<List<Student>>((ref) async {
  final service = await ref.watch(studentServiceProvider.future);
  return service.getStudents();
});
