import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/common_widgets/app_feedback.dart';
import '../../../app/common_widgets/app_page_scaffold.dart';
import '../../../app/common_widgets/dirty_form_scope.dart';
import '../../../app/design_system/app_theme.dart';
import '../../../app/navigation/ui_keys.dart';
import '../../../core/utils/date_formatter.dart';
import '../domain/membership.dart';
import '../domain/membership_service.dart';

class EditMembershipBottomSheet extends ConsumerStatefulWidget {
  final ClassMembership membership;
  final String? studentName;
  final String? className;

  const EditMembershipBottomSheet({
    super.key,
    required this.membership,
    this.studentName,
    this.className,
  });

  @override
  ConsumerState<EditMembershipBottomSheet> createState() =>
      _EditMembershipBottomSheetState();
}

class _EditMembershipBottomSheetState
    extends ConsumerState<EditMembershipBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _joinDate;
  late TextEditingController _mienGiamController;
  late TextEditingController _ghiChuController;
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
    _joinDate = DateTime.tryParse(widget.membership.tuNgay) ?? DateTime.now();
    _mienGiamController = TextEditingController(
      text: widget.membership.mienGiamPhanTram.toString(),
    )..addListener(_onChanged);
    _ghiChuController = TextEditingController(
      text: widget.membership.ghiChu ?? '',
    )..addListener(_onChanged);
  }

  @override
  void dispose() {
    _mienGiamController.dispose();
    _ghiChuController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Sửa thông tin học lớp',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              if (widget.studentName != null)
                                Text(
                                  widget.studentName!,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.cyanAccent,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
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
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _inlineError!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onErrorContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    const Text(
                      'Ngày bắt đầu học',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _joinDate,
                          firstDate: DateTime(2020),
                          lastDate: widget.membership.denNgay != null
                              ? DateTime.parse(widget.membership.denNgay!)
                              : DateTime(2100),
                        );
                        if (picked != null) {
                          _onChanged();
                          setState(() => _joinDate = picked);
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: 48,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceHigh,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_rounded,
                              size: 18,
                              color: AppColors.cyanAccent,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              DateFormatter.formatDisplayDate(_joinDate),
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Miễn giảm học phí (%)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _mienGiamController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        hintText: 'Nhập tỷ lệ miễn giảm 0 - 100',
                        suffixText: '%',
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) {
                        final parsed = int.tryParse(val?.trim() ?? '');
                        if (parsed == null || parsed < 0 || parsed > 100) {
                          return 'Vui lòng nhập tỷ lệ miễn giảm hợp lệ (0 đến 100)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Ghi chú',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _ghiChuController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        hintText: 'Ghi chú thêm về việc tham gia lớp...',
                        border: OutlineInputBorder(),
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
                            child: const Text('Hủy'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            key: UiKeys.enrollStudentSubmit,
                            onPressed: _isSaving ? null : _submit,
                            child: _isSaving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Lưu thay đổi'),
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
    );
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _inlineError = null;
    });

    try {
      final mienGiam = int.parse(_mienGiamController.text.trim());
      final service = await ref.read(membershipServiceProvider.future);

      await service.updateMembership(
        membership: widget.membership,
        joinDate: _joinDate,
        mienGiamPhanTram: mienGiam,
        ghiChu: _ghiChuController.text.trim(),
      );

      if (mounted) {
        setState(() {
          _isSaving = false;
          _isDirty = false;
        });
        AppFeedback.showSuccessSnackBar(
          context,
          'Đã cập nhật thông tin học phí & tham gia lớp',
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

Future<bool?> showEditMembershipBottomSheet(
  BuildContext context, {
  required ClassMembership membership,
  String? studentName,
  String? className,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => EditMembershipBottomSheet(
      membership: membership,
      studentName: studentName,
      className: className,
    ),
  );
}
