import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../app/common_widgets/app_feedback.dart';
import '../../../app/common_widgets/app_page_scaffold.dart';
import '../../../app/common_widgets/dirty_form_scope.dart';
import '../../../app/design_system/app_theme.dart';
import '../../../app/navigation/ui_keys.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../l10n/app_localizations.dart';
import 'tuition_controller.dart';

class CreateTuitionPolicyBottomSheet extends ConsumerStatefulWidget {
  final int classId;
  final String? initialMonth;

  const CreateTuitionPolicyBottomSheet({
    super.key,
    required this.classId,
    this.initialMonth,
  });

  @override
  ConsumerState<CreateTuitionPolicyBottomSheet> createState() =>
      _CreateTuitionPolicyBottomSheetState();
}

class _CreateTuitionPolicyBottomSheetState
    extends ConsumerState<CreateTuitionPolicyBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _feeController;
  late TextEditingController _standardController;
  late TextEditingController _capController;
  late TextEditingController _noteController;
  late DateTime _effectiveFromDate;
  late String _initialFee;
  late String _initialStandard;
  bool _isDirty = false;
  bool _isSaving = false;
  String? _inlineError;

  void _checkDirty() {
    final monthStr =
        widget.initialMonth ?? DateFormat('yyyy-MM').format(DateTime.now());
    final defaultDate = DateTime.tryParse('$monthStr-01') ?? DateTime.now();

    final isChanged =
        _effectiveFromDate != defaultDate ||
        _feeController.text != _initialFee ||
        _standardController.text != _initialStandard ||
        _capController.text.trim().isNotEmpty ||
        _noteController.text.trim().isNotEmpty;
    if (_isDirty != isChanged) {
      setState(() => _isDirty = isChanged);
    }
  }

  @override
  void initState() {
    super.initState();
    final monthStr =
        widget.initialMonth ?? DateFormat('yyyy-MM').format(DateTime.now());
    _effectiveFromDate = DateTime.tryParse('$monthStr-01') ?? DateTime.now();
    _initialFee = '50000';
    _initialStandard = '12';

    _feeController = TextEditingController(text: _initialFee)
      ..addListener(_checkDirty);
    _standardController = TextEditingController(text: _initialStandard)
      ..addListener(_checkDirty);
    _capController = TextEditingController()..addListener(_checkDirty);
    _noteController = TextEditingController()..addListener(_checkDirty);
  }

  @override
  void dispose() {
    _feeController.dispose();
    _standardController.dispose();
    _capController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

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
                          l10n.actionCreatePolicy,
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
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        l10n.tuitionEffectiveFrom,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      subtitle: Text(
                        DateFormatter.formatDisplayDate(_effectiveFromDate),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.calendar_today,
                        color: AppColors.cyanAccent,
                      ),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _effectiveFromDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() => _effectiveFromDate = picked);
                          _checkDirty();
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _feeController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: l10n.policyFeePerSession,
                        border: const OutlineInputBorder(),
                      ),
                      validator: (v) {
                        final fee = int.tryParse(v?.trim() ?? '');
                        if (fee == null || fee < 0) {
                          return l10n.policyValidationFee;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _standardController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: l10n.policyStandardSessions,
                        border: const OutlineInputBorder(),
                      ),
                      validator: (v) {
                        final std = int.tryParse(v?.trim() ?? '');
                        if (std == null || std <= 0) {
                          return l10n.policyValidationSessions;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _capController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText:
                            '${l10n.tuitionMonthlyCap} (để trống nếu không có)',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _noteController,
                      decoration: InputDecoration(
                        labelText: l10n.studentNotes,
                        border: const OutlineInputBorder(),
                      ),
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
                          key: UiKeys.tuitionPolicySave,
                          onPressed: _isSaving ? null : _submit,
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

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _inlineError = null;
    });

    try {
      final fee = int.parse(_feeController.text.trim());
      final standard = int.parse(_standardController.text.trim());
      final capStr = _capController.text.trim();
      final cap = capStr.isNotEmpty ? int.tryParse(capStr) : null;
      final dateStr = DateFormatter.formatCanonicalDate(_effectiveFromDate);

      await ref
          .read(tuitionPolicyControllerProvider.notifier)
          .createPolicy(
            classId: widget.classId,
            effectiveFrom: dateStr,
            feePerSession: fee,
            standardSessionsPerMonth: standard,
            monthlyMaxFee: cap,
            note: _noteController.text.trim(),
          );

      if (mounted) {
        setState(() => _isSaving = false);
        _isDirty = false;
        AppFeedback.showSuccessSnackBar(
          context,
          'Đã tạo chính sách học phí thành công',
        );
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

Future<bool?> showCreateTuitionPolicyBottomSheet(
  BuildContext context, {
  required int classId,
  String? initialMonth,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    useSafeArea: true,
    builder: (_) => CreateTuitionPolicyBottomSheet(
      classId: classId,
      initialMonth: initialMonth,
    ),
  );
}
