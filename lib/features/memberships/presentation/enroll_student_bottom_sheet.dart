import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/common_widgets/app_feedback.dart';
import '../../../app/common_widgets/app_page_scaffold.dart';
import '../../../app/common_widgets/dirty_form_scope.dart';
import '../../../app/common_widgets/searchable_selectors.dart';
import '../../../app/navigation/ui_keys.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../l10n/app_localizations.dart';
import '../../students/domain/student.dart';
import '../../students/domain/student_service.dart';
import '../../students/presentation/student_controller.dart';
import '../domain/membership_service.dart';

enum EnrollMode { existing, newStudent }

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
  final _formKey = GlobalKey<FormState>();
  EnrollMode _mode = EnrollMode.existing;
  Student? _selectedStudent;
  DateTime _joinDate = DateTime.now();
  late TextEditingController _mienGiamController;
  late TextEditingController _ghiChuController;

  // New Student Controllers
  late TextEditingController _newHoTenController;
  late TextEditingController _newSdtController;
  DateTime? _newNgaySinh;
  String? _newGioiTinh;
  int? _newKhoi;

  bool _isDirty = false;
  bool _isSaving = false;
  String? _inlineError;

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
    _newHoTenController = TextEditingController()..addListener(_onChanged);
    _newSdtController = TextEditingController()..addListener(_onChanged);

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
    _newHoTenController.dispose();
    _newSdtController.dispose();
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
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.enrollStudentTitle,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
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
                    const SizedBox(height: 12),
                    SegmentedButton<EnrollMode>(
                      segments: [
                        ButtonSegment(
                          value: EnrollMode.existing,
                          label: Text(l10n.enrollOptionExisting),
                          icon: const Icon(Icons.person_search),
                        ),
                        ButtonSegment(
                          value: EnrollMode.newStudent,
                          label: Text(l10n.enrollOptionNew),
                          icon: const Icon(Icons.person_add_alt_1),
                        ),
                      ],
                      selected: {_mode},
                      onSelectionChanged: (val) {
                        _onChanged();
                        setState(() => _mode = val.first);
                      },
                    ),
                    const SizedBox(height: 16),
                    if (_inlineError != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _inlineError!,
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onErrorContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    if (_mode == EnrollMode.existing) ...[
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
                        error: (e, _) => Text('${l10n.commonError}: $e'),
                      ),
                    ] else ...[
                      TextFormField(
                        controller: _newHoTenController,
                        decoration: InputDecoration(
                          labelText: l10n.studentFullName,
                          border: const OutlineInputBorder(),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? l10n.studentValidationName
                            : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              initialValue: _newKhoi,
                              decoration: InputDecoration(
                                labelText: l10n.studentGrade,
                                border: const OutlineInputBorder(),
                              ),
                              items: List.generate(12, (i) => i + 1)
                                  .map(
                                    (k) => DropdownMenuItem(
                                      value: k,
                                      child: Text(l10n.studentGradeItem(k)),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) {
                                _onChanged();
                                setState(() => _newKhoi = v);
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _newGioiTinh,
                              decoration: InputDecoration(
                                labelText: l10n.studentGender,
                                border: const OutlineInputBorder(),
                              ),
                              items: [
                                DropdownMenuItem(
                                  value: 'NAM',
                                  child: Text(l10n.studentGenderMale),
                                ),
                                DropdownMenuItem(
                                  value: 'NU',
                                  child: Text(l10n.studentGenderFemale),
                                ),
                                DropdownMenuItem(
                                  value: 'KHAC',
                                  child: Text(l10n.studentGenderOther),
                                ),
                              ],
                              onChanged: (v) {
                                _onChanged();
                                setState(() => _newGioiTinh = v);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _newSdtController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: l10n.studentParentPhone,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.enrollJoinDate),
                      subtitle: Text(
                        DateFormatter.formatDisplayDate(_joinDate),
                      ),
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
                    const SizedBox(height: 12),
                    TextField(
                      controller: _mienGiamController,
                      decoration: InputDecoration(
                        labelText: l10n.enrollDiscount,
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
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
                          onPressed: _isSaving ? null : () => _submit(l10n),
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
      ),
    );
  }

  void _submit(AppLocalizations l10n) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _inlineError = null;
    });

    try {
      final membershipService = await ref.read(
        membershipServiceProvider.future,
      );
      int studentIdToEnroll;

      if (_mode == EnrollMode.existing) {
        if (_selectedStudent == null) {
          setState(() {
            _isSaving = false;
            _inlineError = l10n.selectStudent;
          });
          return;
        }
        studentIdToEnroll = _selectedStudent!.id!;
      } else {
        // Option B: Create new student profile first
        final studentService = await ref.read(studentServiceProvider.future);
        final newStudent = Student(
          hoTen: _newHoTenController.text.trim(),
          sdtPhuHuynh: _newSdtController.text.trim().isNotEmpty
              ? _newSdtController.text.trim()
              : null,
          khoi: _newKhoi,
          gioiTinh: _newGioiTinh,
          ngaySinh: _newNgaySinh != null
              ? DateFormatter.formatCanonicalDate(_newNgaySinh!)
              : null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        studentIdToEnroll = await studentService.saveStudent(newStudent);
        ref.invalidate(studentListControllerProvider);
      }

      // Enroll student
      await membershipService.enrollStudent(
        studentId: studentIdToEnroll,
        classId: widget.classId,
        joinDate: _joinDate,
        mienGiam: int.tryParse(_mienGiamController.text.trim()) ?? 0,
        ghiChu: _ghiChuController.text.trim(),
      );

      ref.invalidate(
        enrollmentCandidatesProvider((
          classId: widget.classId,
          joinDate: _joinDate,
        )),
      );
      ref.invalidate(studentListProvider);

      if (mounted) {
        setState(() {
          _isSaving = false;
          _isDirty = false;
        });
        AppFeedback.showSuccessSnackBar(context, l10n.membershipActive);
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _inlineError = e.toString().replaceAll('Exception: ', '');
        });
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
