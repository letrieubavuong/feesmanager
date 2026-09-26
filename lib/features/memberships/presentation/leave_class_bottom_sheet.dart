import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../app/common_widgets/app_feedback.dart';
import '../../../app/common_widgets/app_page_scaffold.dart';
import '../../../app/common_widgets/dirty_form_scope.dart';
import '../domain/membership_service.dart';

class LeaveClassBottomSheet extends ConsumerStatefulWidget {
  final int studentId;
  final int classId;
  final String studentName;

  const LeaveClassBottomSheet({
    super.key,
    required this.studentId,
    required this.classId,
    required this.studentName,
  });

  @override
  ConsumerState<LeaveClassBottomSheet> createState() =>
      _LeaveClassBottomSheetState();
}

class _LeaveClassBottomSheetState extends ConsumerState<LeaveClassBottomSheet> {
  DateTime _endDate = DateTime.now();
  String _selectedReason = 'NGHI_HOC';
  bool _isDirty = false;
  bool _isSaving = false;

  void _onChanged() {
    if (!_isDirty) {
      setState(() => _isDirty = true);
    }
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
                      Expanded(
                        child: Text(
                          'Cho ${widget.studentName} nghỉ lớp',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
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
                    title: const Text('Ngày nghỉ học'),
                    subtitle: Text(DateFormat('yyyy-MM-dd').format(_endDate)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _endDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        _onChanged();
                        setState(() => _endDate = picked);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedReason,
                    decoration: const InputDecoration(
                      labelText: 'Lý do nghỉ',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'TAM_NGUNG',
                        child: Text('Tạm nghỉ'),
                      ),
                      DropdownMenuItem(
                        value: 'NGHI_HOC',
                        child: Text('Nghỉ hẳn'),
                      ),
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        _onChanged();
                        setState(() => _selectedReason = v);
                      }
                    },
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
                        label: const Text('Xác nhận'),
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
      await service.leaveClass(
        studentId: widget.studentId,
        classId: widget.classId,
        endDate: _endDate,
        reason: _selectedReason,
      );

      if (mounted) {
        setState(() => _isSaving = false);
        _isDirty = false;
        AppFeedback.showSuccessSnackBar(
          context,
          'Đã cập nhật trạng thái nghỉ học',
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

Future<bool?> showLeaveClassBottomSheet(
  BuildContext context, {
  required int studentId,
  required int classId,
  required String studentName,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    useSafeArea: true,
    builder: (_) => LeaveClassBottomSheet(
      studentId: studentId,
      classId: classId,
      studentName: studentName,
    ),
  );
}
