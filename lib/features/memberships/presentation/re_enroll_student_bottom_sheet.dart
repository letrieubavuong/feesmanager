import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../app/common_widgets/app_feedback.dart';
import '../../../app/common_widgets/app_page_scaffold.dart';
import '../../../app/common_widgets/dirty_form_scope.dart';
import '../../../app/navigation/ui_keys.dart';
import '../domain/membership_service.dart';

class ReEnrollStudentBottomSheet extends ConsumerStatefulWidget {
  final int studentId;
  final int classId;
  final int defaultDiscount;

  const ReEnrollStudentBottomSheet({
    super.key,
    required this.studentId,
    required this.classId,
    this.defaultDiscount = 0,
  });

  @override
  ConsumerState<ReEnrollStudentBottomSheet> createState() =>
      _ReEnrollStudentBottomSheetState();
}

class _ReEnrollStudentBottomSheetState
    extends ConsumerState<ReEnrollStudentBottomSheet> {
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
    _mienGiamController = TextEditingController(
      text: widget.defaultDiscount.toString(),
    )..addListener(_onChanged);
    _ghiChuController = TextEditingController()..addListener(_onChanged);
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Học sinh học lại',
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
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Ngày học lại'),
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
                    decoration: const InputDecoration(
                      labelText: 'Ghi chú',
                      border: OutlineInputBorder(),
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
                        child: const Text('Hủy'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        key: UiKeys.enrollStudentSubmit,
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
                        label: const Text('Lưu'),
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
    setState(() => _isSaving = true);

    try {
      final service = await ref.read(membershipServiceProvider.future);
      await service.enrollStudent(
        studentId: widget.studentId,
        classId: widget.classId,
        joinDate: _joinDate,
        mienGiam: int.tryParse(_mienGiamController.text.trim()) ?? 0,
        ghiChu: _ghiChuController.text.trim(),
      );

      if (mounted) {
        setState(() => _isSaving = false);
        _isDirty = false;
        AppFeedback.showSuccessSnackBar(
          context,
          'Đã đăng ký học lại thành công',
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

Future<bool?> showReEnrollStudentBottomSheet(
  BuildContext context, {
  required int studentId,
  required int classId,
  int defaultDiscount = 0,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    useSafeArea: true,
    builder: (_) => ReEnrollStudentBottomSheet(
      studentId: studentId,
      classId: classId,
      defaultDiscount: defaultDiscount,
    ),
  );
}
