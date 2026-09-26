import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../app/common_widgets/app_feedback.dart';
import '../../../app/navigation/ui_keys.dart';
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
  late TextEditingController _fromController;
  late TextEditingController _feeController;
  late TextEditingController _standardController;
  late TextEditingController _capController;
  late TextEditingController _noteController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final monthStr =
        widget.initialMonth ?? DateFormat('yyyy-MM').format(DateTime.now());
    _fromController = TextEditingController(text: '$monthStr-01');
    _feeController = TextEditingController(text: '50000');
    _standardController = TextEditingController(text: '12');
    _capController = TextEditingController();
    _noteController = TextEditingController();
  }

  @override
  void dispose() {
    _fromController.dispose();
    _feeController.dispose();
    _standardController.dispose();
    _capController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SafeArea(
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
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _fromController,
                  decoration: const InputDecoration(
                    labelText: 'Hiệu lực từ ngày (YYYY-MM-DD) *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? l10n.policyValidationMonth
                      : null,
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
                    if (fee == null || fee < 0) return l10n.policyValidationFee;
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
                  decoration: const InputDecoration(
                    labelText: 'Trần học phí tháng (để trống nếu không có)',
                    border: OutlineInputBorder(),
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
                          : () => Navigator.of(context).pop(),
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
                              child: CircularProgressIndicator(strokeWidth: 2),
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
    );
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final fee = int.parse(_feeController.text.trim());
      final standard = int.parse(_standardController.text.trim());
      final capStr = _capController.text.trim();
      final cap = capStr.isNotEmpty ? int.tryParse(capStr) : null;

      await ref
          .read(tuitionPolicyControllerProvider.notifier)
          .createPolicy(
            classId: widget.classId,
            effectiveFrom: _fromController.text.trim(),
            feePerSession: fee,
            standardSessionsPerMonth: standard,
            monthlyMaxFee: cap,
            note: _noteController.text.trim(),
          );

      if (mounted) {
        setState(() => _isSaving = false);
        AppFeedback.showSuccessSnackBar(
          context,
          'Đã tạo chính sách học phí thành công',
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

Future<bool?> showCreateTuitionPolicyBottomSheet(
  BuildContext context, {
  required int classId,
  String? initialMonth,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => CreateTuitionPolicyBottomSheet(
      classId: classId,
      initialMonth: initialMonth,
    ),
  );
}
