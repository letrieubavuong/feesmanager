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
import '../domain/tuition_policy.dart';
import 'tuition_controller.dart';

class CreateTuitionPolicyBottomSheet extends ConsumerStatefulWidget {
  final int classId;
  final String? initialMonth;
  final TuitionPolicy? previousPolicy;

  const CreateTuitionPolicyBottomSheet({
    super.key,
    required this.classId,
    this.initialMonth,
    this.previousPolicy,
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
  late String _initialCap;
  late String _initialNote;
  bool _isDirty = false;
  bool _isSaving = false;
  ExcusedAbsenceFeeRule _excusedRule = ExcusedAbsenceFeeRule.buTruBuoiDu;
  String? _inlineError;

  void _checkDirty() {
    final monthStr =
        widget.initialMonth ?? DateFormat('yyyy-MM').format(DateTime.now());
    final defaultDate = DateTime.tryParse('$monthStr-01') ?? DateTime.now();

    final isChanged =
        _effectiveFromDate != defaultDate ||
        _feeController.text != _initialFee ||
        _standardController.text != _initialStandard ||
        _excusedRule !=
            (widget.previousPolicy?.quyTacNghiCoPhep ??
                ExcusedAbsenceFeeRule.buTruBuoiDu) ||
        _capController.text != _initialCap ||
        _noteController.text != _initialNote;
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
    _initialFee = (widget.previousPolicy?.hocPhiMoiBuoi ?? 50000).toString();
    _initialStandard = (widget.previousPolicy?.soBuoiChuanThang ?? 12)
        .toString();
    _initialCap = widget.previousPolicy?.hocPhiThangToiDa?.toString() ?? '';
    _initialNote = widget.previousPolicy?.ghiChu ?? '';
    _excusedRule =
        widget.previousPolicy?.quyTacNghiCoPhep ??
        ExcusedAbsenceFeeRule.buTruBuoiDu;

    _feeController = TextEditingController(text: _initialFee)
      ..addListener(_checkDirty);
    _standardController = TextEditingController(text: _initialStandard)
      ..addListener(_checkDirty);
    _capController = TextEditingController(text: _initialCap)
      ..addListener(_checkDirty);
    _noteController = TextEditingController(text: _initialNote)
      ..addListener(_checkDirty);
  }

  @override
  void dispose() {
    _feeController.dispose();
    _standardController.dispose();
    _capController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Widget _buildFieldLabel(String label, {bool isRequired = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          if (isRequired)
            const Text(
              ' *',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.error,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCustomInputContainer({
    required IconData icon,
    required Widget child,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 48,
              decoration: const BoxDecoration(
                color: AppColors.surfaceSelected,
                borderRadius: BorderRadius.horizontal(
                  left: Radius.circular(11),
                ),
              ),
              child: Icon(icon, color: AppColors.cyanAccent, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(child: child),
            if (trailing != null) ...[trailing, const SizedBox(width: 8)],
          ],
        ),
      ),
    );
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
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
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
                            widget.previousPolicy == null
                                ? l10n.actionCreatePolicy
                                : 'Thay đổi mức học phí',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.close_rounded,
                              color: AppColors.textPrimary,
                              size: 22,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
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
                      if (widget.previousPolicy != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceHigh,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Đang áp dụng: ${NumberFormat('#,###').format(widget.previousPolicy!.hocPhiMoiBuoi)}đ/buổi • ${widget.previousPolicy!.soBuoiChuanThang} buổi chuẩn. Chính sách mới bắt đầu từ tháng được chọn; tháng trước đó giữ nguyên.',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (_inlineError != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(10),
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
                      _buildFieldLabel(
                        l10n.policyFeePerSession,
                        isRequired: true,
                      ),
                      _buildCustomInputContainer(
                        icon: Icons.payments_rounded,
                        child: TextFormField(
                          controller: _feeController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 12),
                            isDense: true,
                          ),
                          validator: (v) {
                            final fee = int.tryParse(v?.trim() ?? '');
                            if (fee == null || fee < 0) {
                              return l10n.policyValidationFee;
                            }
                            return null;
                          },
                        ),
                        trailing: const Text(
                          'VND',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel(
                                  l10n.policyStandardSessions,
                                  isRequired: true,
                                ),
                                _buildCustomInputContainer(
                                  icon: Icons.tag_rounded,
                                  child: TextFormField(
                                    controller: _standardController,
                                    keyboardType: TextInputType.number,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textPrimary,
                                    ),
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      isDense: true,
                                    ),
                                    validator: (v) {
                                      final std = int.tryParse(v?.trim() ?? '');
                                      if (std == null || std <= 0) {
                                        return l10n.policyValidationSessions;
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel(l10n.tuitionMonthlyCap),
                                _buildCustomInputContainer(
                                  icon: Icons.savings_rounded,
                                  child: TextFormField(
                                    controller: _capController,
                                    keyboardType: TextInputType.number,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textPrimary,
                                    ),
                                    decoration: const InputDecoration(
                                      hintText: 'Tùy chọn',
                                      hintStyle: TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 14,
                                      ),
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      isDense: true,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildFieldLabel('Nghỉ học có phép'),
                      DropdownButtonFormField<ExcusedAbsenceFeeRule>(
                        initialValue: _excusedRule,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.event_busy_outlined),
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: ExcusedAbsenceFeeRule.buTruBuoiDu,
                            child: Text('Bù buổi / buổi dư; còn lại không thu'),
                          ),
                          DropdownMenuItem(
                            value: ExcusedAbsenceFeeRule.tinhPhi,
                            child: Text('Có tính học phí'),
                          ),
                          DropdownMenuItem(
                            value: ExcusedAbsenceFeeRule.khongTinhPhi,
                            child: Text('Không tính học phí'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _excusedRule = value);
                          _checkDirty();
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildFieldLabel(
                        l10n.tuitionEffectiveFrom,
                        isRequired: true,
                      ),
                      _buildCustomInputContainer(
                        icon: Icons.calendar_month_rounded,
                        child: Text(
                          DateFormatter.formatDisplayDate(_effectiveFromDate),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: AppColors.textSecondary,
                          ),
                          onPressed: () {
                            setState(
                              () => _effectiveFromDate = DateTime(
                                DateTime.now().year,
                                DateTime.now().month,
                                1,
                              ),
                            );
                            _checkDirty();
                          },
                        ),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _effectiveFromDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            final normalized = DateTime(
                              picked.year,
                              picked.month,
                              1,
                            );
                            setState(() => _effectiveFromDate = normalized);
                            _checkDirty();
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildFieldLabel(l10n.studentNotes),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.surfaceHigh,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border, width: 1),
                        ),
                        child: TextField(
                          controller: _noteController,
                          maxLines: 2,
                          minLines: 1,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Ghi chú về chính sách học phí...',
                            hintStyle: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 14,
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
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
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: AppColors.cyanAccent,
                                  width: 1.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                backgroundColor: AppColors.surface,
                              ),
                              child: Text(
                                l10n.commonCancel,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              key: UiKeys.tuitionPolicySave,
                              onPressed: _isSaving ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                              child: _isSaving
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      l10n.commonSave,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
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
      ),
    );
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final fee = int.parse(_feeController.text.trim());
    final standard = int.parse(_standardController.text.trim());
    final capStr = _capController.text.trim();
    final cap = capStr.isNotEmpty ? int.tryParse(capStr) : null;
    if (capStr.isNotEmpty && (cap == null || cap < 0)) {
      setState(
        () => _inlineError = 'Trần học phí phải là một số tiền không âm.',
      );
      return;
    }
    final dateStr = DateFormatter.formatCanonicalDate(_effectiveFromDate);
    final previous = widget.previousPolicy;
    if (previous != null &&
        previous.hocPhiMoiBuoi == fee &&
        previous.soBuoiChuanThang == standard &&
        previous.hocPhiThangToiDa == cap &&
        previous.quyTacNghiCoPhep == _excusedRule &&
        (previous.ghiChu ?? '') == _noteController.text.trim()) {
      setState(
        () => _inlineError =
            'Mức học phí và quy tắc vẫn giống chính sách đang áp dụng. Hãy nhập giá trị cần thay đổi.',
      );
      return;
    }
    if (widget.previousPolicy != null &&
        dateStr.compareTo(widget.previousPolicy!.hieuLucTu) <= 0) {
      setState(
        () => _inlineError =
            'Mức cũ bắt đầu từ ${DateFormatter.formatDisplayDate(widget.previousPolicy!.hieuLucTu)}. Để giữ lịch sử, hãy chọn tháng sau tháng bắt đầu của chính sách này.',
      );
      return;
    }
    if (widget.previousPolicy != null) {
      final confirmed = await showModalBottomSheet<bool>(
        context: context,
        backgroundColor: AppColors.surface,
        builder: (sheetContext) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Xác nhận thay đổi học phí',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Mức cũ: ${NumberFormat('#,###').format(widget.previousPolicy!.hocPhiMoiBuoi)}đ/buổi. Mức mới: ${NumberFormat('#,###').format(fee)}đ/buổi. Hiệu lực từ tháng ${DateFormat('MM/yyyy').format(_effectiveFromDate)}.',
                  style: const TextStyle(color: AppColors.textPrimary),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Các tháng trước giữ nguyên. Nếu khoảng thời gian này đã có hóa đơn chốt hoặc xung đột chính sách, ứng dụng sẽ từ chối và giải thích ngay trên biểu mẫu.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(sheetContext, false),
                      child: const Text('Xem lại'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(sheetContext, true),
                      child: const Text('Xác nhận lưu'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
      if (confirmed != true || !mounted) return;
    }

    setState(() {
      _isSaving = true;
      _inlineError = null;
    });

    try {
      await ref
          .read(tuitionPolicyControllerProvider.notifier)
          .createPolicy(
            classId: widget.classId,
            effectiveFrom: dateStr,
            feePerSession: fee,
            standardSessionsPerMonth: standard,
            monthlyMaxFee: cap,
            excusedAbsenceFeeRule: _excusedRule,
            note: _noteController.text.trim(),
          );

      if (mounted) {
        setState(() => _isSaving = false);
        _isDirty = false;
        await WidgetsBinding.instance.endOfFrame;
        if (!mounted) return;
        AppFeedback.showSuccessSnackBar(
          context,
          widget.previousPolicy == null
              ? 'Đã tạo chính sách học phí thành công'
              : 'Đã cập nhật mức học phí từ tháng ${DateFormat('MM/yyyy').format(_effectiveFromDate)}',
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
  TuitionPolicy? previousPolicy,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => CreateTuitionPolicyBottomSheet(
      classId: classId,
      initialMonth: initialMonth,
      previousPolicy: previousPolicy,
    ),
  );
}
