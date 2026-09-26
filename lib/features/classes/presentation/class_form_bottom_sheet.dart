import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/common_widgets/app_feedback.dart';
import '../../../app/common_widgets/app_page_scaffold.dart';
import '../../../app/common_widgets/dirty_form_scope.dart';
import '../../../app/navigation/ui_keys.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/class.dart';
import 'class_controller.dart';

class ClassFormBottomSheet extends ConsumerStatefulWidget {
  final ClassEntity? cls;
  const ClassFormBottomSheet({super.key, this.cls});

  @override
  ConsumerState<ClassFormBottomSheet> createState() =>
      _ClassFormBottomSheetState();
}

class _ClassFormBottomSheetState extends ConsumerState<ClassFormBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _tenLopController;
  late TextEditingController _monHocController;
  late TextEditingController _siSoToiDaController;
  late TextEditingController _ghiChuController;
  int? _khoi;
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
    final c = widget.cls;
    _tenLopController = TextEditingController(text: c?.tenLop)
      ..addListener(_onChanged);
    _monHocController = TextEditingController(text: c?.monHoc)
      ..addListener(_onChanged);
    _siSoToiDaController = TextEditingController(text: c?.siSoToiDa?.toString())
      ..addListener(_onChanged);
    _ghiChuController = TextEditingController(text: c?.ghiChu)
      ..addListener(_onChanged);
    _khoi = c?.khoi;
  }

  @override
  void dispose() {
    _tenLopController.dispose();
    _monHocController.dispose();
    _siSoToiDaController.dispose();
    _ghiChuController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isEdit = widget.cls != null;

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
                          isEdit
                              ? l10n.classFormTitleEdit
                              : l10n.classFormTitleAdd,
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
                    const SizedBox(height: 16),
                    TextFormField(
                      key: UiKeys.classFormNameInput,
                      controller: _tenLopController,
                      decoration: InputDecoration(
                        labelText: l10n.className,
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          (value == null || value.trim().isEmpty)
                          ? l10n.classValidationName
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
                          child: TextFormField(
                            controller: _siSoToiDaController,
                            decoration: InputDecoration(
                              labelText: l10n.classMaxStudents,
                              border: const OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _monHocController,
                      decoration: InputDecoration(
                        labelText: l10n.classSubject,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _ghiChuController,
                      decoration: InputDecoration(
                        labelText: l10n.classNotes,
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
                          key: UiKeys.classFormSave,
                          onPressed: _isSaving ? null : _save,
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

  void _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final classEntity =
        (widget.cls ??
                ClassEntity(
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                  tenLop: '',
                ))
            .copyWith(
              tenLop: _tenLopController.text.trim(),
              monHoc: _monHocController.text.trim(),
              siSoToiDa: int.tryParse(_siSoToiDaController.text.trim()),
              khoi: _khoi,
              ghiChu: _ghiChuController.text.trim(),
            );

    try {
      await ref.read(classFormControllerProvider.notifier).save(classEntity);
      _isDirty = false;
      ref.read(classListControllerProvider.notifier).refresh();
      if (widget.cls?.id != null) {
        ref.invalidate(classDetailProvider(widget.cls!.id!));
      }
      if (mounted) {
        setState(() => _isSaving = false);
        AppFeedback.showSuccessSnackBar(context, 'Đã lưu thông tin lớp học');
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

Future<bool?> showClassFormBottomSheet(
  BuildContext context, {
  ClassEntity? cls,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    useSafeArea: true,
    builder: (_) => ClassFormBottomSheet(cls: cls),
  );
}
