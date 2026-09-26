import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/common_widgets/app_feedback.dart';
import '../../../app/common_widgets/dirty_form_scope.dart';
import '../../../app/navigation/app_global_drawer.dart';
import '../../../app/navigation/ui_keys.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/student.dart';
import 'student_controller.dart';
import 'student_detail_page.dart';

class StudentFormPage extends ConsumerStatefulWidget {
  final Student? student;
  const StudentFormPage({super.key, this.student});

  @override
  ConsumerState<StudentFormPage> createState() => _StudentFormPageState();
}

class _StudentFormPageState extends ConsumerState<StudentFormPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _hoTenController;
  late TextEditingController _ngaySinhController;
  late TextEditingController _tenPhuHuynhController;
  late TextEditingController _sdtPhuHuynhController;
  late TextEditingController _sdtHocSinhController;
  late TextEditingController _emailController;
  late TextEditingController _truongController;
  late TextEditingController _diaChiController;
  late TextEditingController _facebookController;
  late TextEditingController _ghiChuController;

  int? _khoi;
  String? _gioiTinh;
  bool _isDirty = false;

  void _onChanged() {
    if (!_isDirty) {
      setState(() {
        _isDirty = true;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    final s = widget.student;
    _hoTenController = TextEditingController(text: s?.hoTen)
      ..addListener(_onChanged);
    _ngaySinhController = TextEditingController(text: s?.ngaySinh)
      ..addListener(_onChanged);
    _tenPhuHuynhController = TextEditingController(text: s?.tenPhuHuynh)
      ..addListener(_onChanged);
    _sdtPhuHuynhController = TextEditingController(text: s?.sdtPhuHuynh)
      ..addListener(_onChanged);
    _sdtHocSinhController = TextEditingController(text: s?.sdtHocSinh)
      ..addListener(_onChanged);
    _emailController = TextEditingController(text: s?.email)
      ..addListener(_onChanged);
    _truongController = TextEditingController(text: s?.truongDangHoc)
      ..addListener(_onChanged);
    _diaChiController = TextEditingController(text: s?.diaChi)
      ..addListener(_onChanged);
    _facebookController = TextEditingController(text: s?.facebook)
      ..addListener(_onChanged);
    _ghiChuController = TextEditingController(text: s?.ghiChu)
      ..addListener(_onChanged);
    _khoi = s?.khoi;
    _gioiTinh = s?.gioiTinh;
  }

  @override
  void dispose() {
    _hoTenController.dispose();
    _ngaySinhController.dispose();
    _tenPhuHuynhController.dispose();
    _sdtPhuHuynhController.dispose();
    _sdtHocSinhController.dispose();
    _emailController.dispose();
    _truongController.dispose();
    _diaChiController.dispose();
    _facebookController.dispose();
    _ghiChuController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return DirtyFormScope(
      isDirty: _isDirty,
      title: l10n.dirtyFormTitle,
      message: l10n.dirtyFormMessage,
      child: Scaffold(
        drawer: const AppGlobalDrawer(),
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: const BackButton(),
          title: Text(
            widget.student == null
                ? l10n.studentFormTitleAdd
                : l10n.studentFormTitleEdit,
          ),
          actions: [
            const GlobalMenuButton(),
            IconButton(
              key: UiKeys.studentFormSave,
              icon: const Icon(Icons.check),
              onPressed: _save,
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  key: const Key('student_form_name_input'),
                  controller: _hoTenController,
                  decoration: InputDecoration(
                    labelText: l10n.studentFullName,
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? l10n.studentValidationName
                      : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: _khoi,
                        decoration: InputDecoration(
                          labelText: l10n.studentGrade,
                          border: const OutlineInputBorder(),
                        ),
                        items: List.generate(12, (index) => index + 1)
                            .map(
                              (k) => DropdownMenuItem(
                                value: k,
                                child: Text(l10n.studentGradeItem(k)),
                              ),
                            )
                            .toList(),
                        onChanged: (v) {
                          _onChanged();
                          setState(() => _khoi = v);
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _gioiTinh,
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
                          setState(() => _gioiTinh = v);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _truongController,
                  decoration: InputDecoration(
                    labelText: l10n.studentSchool,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(),
                Text(
                  l10n.studentParentSection,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _tenPhuHuynhController,
                  decoration: InputDecoration(
                    labelText: l10n.studentParentName,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _sdtPhuHuynhController,
                  decoration: InputDecoration(
                    labelText: l10n.studentParentPhone,
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                const Divider(),
                Text(
                  l10n.studentOtherContactSection,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _sdtHocSinhController,
                  decoration: InputDecoration(
                    labelText: l10n.studentPhone,
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: l10n.studentEmail,
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _diaChiController,
                  decoration: InputDecoration(
                    labelText: l10n.studentAddress,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _facebookController,
                  decoration: InputDecoration(
                    labelText: l10n.studentFacebook,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _ghiChuController,
                  decoration: InputDecoration(
                    labelText: l10n.studentNotes,
                    border: const OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;

    String? nullIfEmpty(String text) {
      final trimmed = text.trim();
      return trimmed.isEmpty ? null : trimmed;
    }

    final student =
        (widget.student ??
                Student(
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                  hoTen: '',
                ))
            .copyWith(
              hoTen: _hoTenController.text.trim(),
              ngaySinh: nullIfEmpty(_ngaySinhController.text),
              tenPhuHuynh: nullIfEmpty(_tenPhuHuynhController.text),
              sdtPhuHuynh: nullIfEmpty(_sdtPhuHuynhController.text),
              sdtHocSinh: nullIfEmpty(_sdtHocSinhController.text),
              email: nullIfEmpty(_emailController.text),
              truongDangHoc: nullIfEmpty(_truongController.text),
              khoi: _khoi,
              gioiTinh: _gioiTinh,
              diaChi: nullIfEmpty(_diaChiController.text),
              facebook: nullIfEmpty(_facebookController.text),
              ghiChu: nullIfEmpty(_ghiChuController.text),
            );

    try {
      await ref.read(studentFormControllerProvider.notifier).save(student);
      _isDirty = false;
      ref.read(studentListControllerProvider.notifier).refresh();
      if (widget.student?.id != null) {
        ref.invalidate(studentDetailProvider(widget.student!.id!));
      }
      if (mounted) {
        AppFeedback.showSuccessSnackBar(context, 'Đã lưu thông tin học sinh');
        Navigator.of(context).pop();
      }
    } catch (e, st) {
      debugPrint('STUDENT SAVE ERROR: $e\n$st');
      if (mounted) {
        AppFeedback.showErrorSnackBar(
          context,
          e.toString().replaceAll('Exception: ', ''),
        );
      }
    }
  }
}
