import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/common_widgets/app_feedback.dart';
import '../../../app/common_widgets/app_page_scaffold.dart';
import '../../../app/common_widgets/dirty_form_scope.dart';
import '../../../app/navigation/app_global_drawer.dart';
import '../../../app/navigation/ui_keys.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../l10n/app_localizations.dart';
import '../../settings/presentation/school_catalog_provider.dart';
import '../domain/student.dart';
import 'student_controller.dart';
import 'student_detail_page.dart';

class StudentFormPage extends ConsumerStatefulWidget {
  final Student? student;
  final bool asSheet;
  const StudentFormPage({super.key, this.student, this.asSheet = false});

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
  bool _isSaving = false;

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

    final content = SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.asSheet) ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.student == null
                          ? l10n.studentFormTitleAdd
                          : l10n.studentFormTitleEdit,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _isSaving ? null : _closeSheet,
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            _buildFields(context, l10n),
            if (widget.asSheet) ...[
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: UiKeys.studentFormSave,
                  onPressed: _isSaving ? null : _save,
                  icon: const Icon(Icons.check),
                  label: Text(l10n.commonSave),
                ),
              ),
            ],
          ],
        ),
      ),
    );

    return DirtyFormScope(
      isDirty: _isDirty,
      title: l10n.dirtyFormTitle,
      message: l10n.dirtyFormMessage,
      child: widget.asSheet
          ? SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: content,
              ),
            )
          : Scaffold(
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
                    onPressed: _isSaving ? null : _save,
                  ),
                ],
              ),
              body: content,
            ),
    );
  }

  Widget _buildFields(BuildContext context, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          key: const Key('student_form_name_input'),
          controller: _hoTenController,
          decoration: InputDecoration(
            labelText: l10n.studentFullName,
            prefixIcon: const Icon(Icons.person_outline),
            border: const OutlineInputBorder(),
          ),
          validator: (value) => (value == null || value.trim().isEmpty)
              ? l10n.studentValidationName
              : null,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<int>(
          initialValue: _khoi,
          decoration: InputDecoration(
            labelText: l10n.studentGrade,
            prefixIcon: const Icon(Icons.stairs_outlined),
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
        const SizedBox(height: 12),
        Text(l10n.studentGender),
        Wrap(
          spacing: 8,
          children:
              [
                    ('NAM', l10n.studentGenderMale),
                    ('NU', l10n.studentGenderFemale),
                    ('KHAC', l10n.studentGenderOther),
                  ]
                  .map(
                    (option) => ChoiceChip(
                      label: Text(option.$2),
                      selected: _gioiTinh == option.$1,
                      onSelected: (_) {
                        _onChanged();
                        setState(() => _gioiTinh = option.$1);
                      },
                    ),
                  )
                  .toList(),
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: () async {
            final initialDate =
                DateFormatter.parseCanonicalDate(_ngaySinhController.text) ??
                DateTime(2010);
            final picked = await showDatePicker(
              context: context,
              initialDate: initialDate,
              firstDate: DateTime(1990),
              lastDate: DateTime.now(),
            );
            if (picked != null) {
              _onChanged();
              setState(() {
                _ngaySinhController.text = DateFormatter.formatCanonicalDate(
                  picked,
                );
              });
            }
          },
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Ngày sinh',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.cake_outlined),
            ),
            child: Text(
              _ngaySinhController.text.isNotEmpty
                  ? DateFormatter.formatDisplayDate(_ngaySinhController.text)
                  : 'Chọn ngày sinh',
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildSchoolField(l10n),
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
            prefixIcon: const Icon(Icons.family_restroom_outlined),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _sdtPhuHuynhController,
          decoration: InputDecoration(
            labelText: l10n.studentParentPhone,
            prefixIcon: const Icon(Icons.phone_outlined),
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
            prefixIcon: const Icon(Icons.smartphone_outlined),
            border: const OutlineInputBorder(),
          ),
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _emailController,
          decoration: InputDecoration(
            labelText: l10n.studentEmail,
            prefixIcon: const Icon(Icons.email_outlined),
            border: const OutlineInputBorder(),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _diaChiController,
          decoration: InputDecoration(
            labelText: l10n.studentAddress,
            prefixIcon: const Icon(Icons.location_on_outlined),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _facebookController,
          decoration: InputDecoration(
            labelText: l10n.studentFacebook,
            prefixIcon: const Icon(Icons.link_outlined),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _ghiChuController,
          decoration: InputDecoration(
            labelText: l10n.studentNotes,
            prefixIcon: const Icon(Icons.notes_outlined),
            border: const OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
      ],
    );
  }

  Future<void> _closeSheet() async {
    final canLeave = await AppPageScaffold.confirmCanLeave(
      context,
      isDirty: _isDirty,
    );
    if (!canLeave || !mounted) return;
    setState(() => _isDirty = false);
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) Navigator.of(context).pop();
  }

  Widget _buildSchoolField(AppLocalizations l10n) {
    final schools =
        ref.watch(schoolCatalogProvider).valueOrNull ?? const <String>[];
    final current = _truongController.text.trim();
    final options = {...schools, if (current.isNotEmpty) current}.toList()
      ..sort();
    return DropdownButtonFormField<String>(
      key: ValueKey(current),
      initialValue: current.isEmpty ? null : current,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: l10n.studentSchool,
        prefixIcon: const Icon(Icons.school_outlined),
        border: const OutlineInputBorder(),
      ),
      items: [
        const DropdownMenuItem<String>(
          value: '',
          child: Text('Chưa chọn trường'),
        ),
        ...options.map(
          (name) => DropdownMenuItem(
            value: name,
            child: Text(name, overflow: TextOverflow.ellipsis),
          ),
        ),
      ],
      onChanged: (value) {
        _truongController.text = value ?? '';
        _onChanged();
        setState(() {});
      },
    );
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSaving) return;
    setState(() => _isSaving = true);

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
      if (mounted) setState(() => _isDirty = false);
      ref.read(studentListControllerProvider.notifier).refresh();
      if (widget.student?.id != null) {
        ref.invalidate(studentDetailProvider(widget.student!.id!));
      }
      if (mounted) {
        AppFeedback.showSuccessSnackBar(context, 'Đã lưu thông tin học sinh');
        await WidgetsBinding.instance.endOfFrame;
        if (mounted) Navigator.of(context).pop(true);
      }
    } catch (e, st) {
      debugPrint('STUDENT SAVE ERROR: $e\n$st');
      if (mounted) {
        AppFeedback.showErrorSnackBar(
          context,
          e.toString().replaceAll('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

Future<bool?> showStudentFormBottomSheet(
  BuildContext context, {
  Student? student,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    useSafeArea: true,
    builder: (_) => StudentFormPage(student: student, asSheet: true),
  );
}
