import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../app/common_widgets/app_feedback.dart';
import '../../../app/common_widgets/navy_components.dart';
import '../../../app/common_widgets/app_page_scaffold.dart';
import '../../../app/common_widgets/dirty_form_scope.dart';
import '../../../app/design_system/app_theme.dart';
import '../../../core/utils/date_formatter.dart';
import '../domain/class_schedule.dart';
import 'schedule_controller.dart';

class ScheduleTab extends ConsumerWidget {
  final int classId;
  final bool isArchived;

  const ScheduleTab({
    super.key,
    required this.classId,
    this.isArchived = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schedulesAsync = ref.watch(classScheduleControllerProvider(classId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          if (!isArchived)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Lịch học định kỳ',
                    style: TextStyle(
                      color: AppColors.cyanAccent,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () =>
                        showScheduleFormBottomSheet(context, classId: classId),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Thêm lịch học'),
                  ),
                ],
              ),
            ),
          Expanded(
            child: schedulesAsync.when(
              data: (schedules) {
                if (schedules.isEmpty) {
                  return const Center(
                    child: Text(
                      'Lớp chưa có lịch học nào.',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: schedules.length,
                  itemBuilder: (context, index) {
                    final s = schedules[index];
                    final isActive = s.isEffectiveOn(DateTime.now());
                    return AppSectionCard(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: isActive
                                  ? AppColors.primary.withValues(alpha: 0.2)
                                  : AppColors.textMuted.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                s.thuTrongTuan == 7
                                    ? 'CN'
                                    : 'T${s.thuTrongTuan + 1}',
                                style: TextStyle(
                                  color: isActive
                                      ? AppColors.cyanAccent
                                      : AppColors.textMuted,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${DateFormatter.formatVietnameseWeekday(s.thuTrongTuan)}: ${s.gioBatDau} - ${s.gioKetThuc}',
                                      style: TextStyle(
                                        color: AppColors.textPrimary,
                                        fontWeight: isActive
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        fontSize: 14,
                                      ),
                                    ),
                                    AppStatusChip(
                                      label: isActive
                                          ? 'Đang áp dụng'
                                          : 'Đã kết thúc',
                                      color: isActive
                                          ? AppColors.success
                                          : AppColors.textMuted,
                                      compact: true,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Hiệu lực: ${DateFormatter.formatDisplayDate(s.hieuLucTu)}${s.hieuLucDen != null ? ' đến ${DateFormatter.formatDisplayDate(s.hieuLucDen!)}' : ''}',
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isActive && !isArchived)
                            PopupMenuButton<String>(
                              icon: const Icon(
                                Icons.more_vert,
                                color: AppColors.textSecondary,
                              ),
                              color: AppColors.surfaceHigh,
                              onSelected: (value) {
                                if (value == 'edit') {
                                  showEditScheduleBottomSheet(
                                    context,
                                    classId: classId,
                                    schedule: s,
                                  );
                                } else if (value == 'close') {
                                  _showCloseScheduleDialog(context, ref, s);
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.edit_outlined,
                                        size: 18,
                                        color: AppColors.cyanAccent,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Sửa lịch học',
                                        style: TextStyle(
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'close',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.event_busy,
                                        size: 18,
                                        color: AppColors.error,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Kết thúc lịch',
                                        style: TextStyle(
                                          color: AppColors.error,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (e, _) => Center(
                child: Text(
                  'Lỗi: $e',
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCloseScheduleDialog(
    BuildContext context,
    WidgetRef ref,
    ClassSchedule schedule,
  ) async {
    DateTime endDate = DateTime.now();

    final confirm = await showDatePicker(
      context: context,
      initialDate: endDate,
      firstDate: DateTime.parse(schedule.hieuLucTu),
      lastDate: DateTime(2100),
      helpText: 'CHỌN NGÀY KẾT THÚC LỊCH HỌC',
    );

    if (confirm != null && context.mounted) {
      try {
        final success = await ref
            .read(classScheduleControllerProvider(classId).notifier)
            .close(schedule.id!, confirm);
        if (success && context.mounted) {
          AppFeedback.showSuccessSnackBar(context, 'Đã kết thúc lịch học');
        }
      } catch (e) {
        if (context.mounted) {
          AppFeedback.showErrorSnackBar(
            context,
            e.toString().replaceAll('Exception: ', ''),
          );
        }
      }
    }
  }
}

class ScheduleFormBottomSheet extends ConsumerStatefulWidget {
  final int classId;
  final ClassSchedule? scheduleToEdit;

  const ScheduleFormBottomSheet({
    super.key,
    required this.classId,
    this.scheduleToEdit,
  });

  @override
  ConsumerState<ScheduleFormBottomSheet> createState() =>
      _ScheduleFormBottomSheetState();
}

class _ScheduleFormBottomSheetState
    extends ConsumerState<ScheduleFormBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  int _thu = 1;
  TimeOfDay _start = const TimeOfDay(hour: 17, minute: 30);
  TimeOfDay _end = const TimeOfDay(hour: 19, minute: 0);
  DateTime _effectiveFrom = DateTime.now();
  bool _isDirty = false;
  bool _isSaving = false;
  String? _inlineError;

  @override
  void initState() {
    super.initState();
    if (widget.scheduleToEdit != null) {
      final s = widget.scheduleToEdit!;
      _thu = s.thuTrongTuan;
      final startParts = s.gioBatDau.split(':');
      final endParts = s.gioKetThuc.split(':');
      _start = TimeOfDay(
        hour: int.parse(startParts[0]),
        minute: int.parse(startParts[1]),
      );
      _end = TimeOfDay(
        hour: int.parse(endParts[0]),
        minute: int.parse(endParts[1]),
      );
      _effectiveFrom = DateTime.now();
    }
  }

  void _onChanged() {
    if (!_isDirty) {
      setState(() => _isDirty = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.scheduleToEdit != null;

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
                              ? 'Sửa lịch học định kỳ'
                              : 'Thêm lịch học định kỳ',
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
                    DropdownButtonFormField<int>(
                      initialValue: _thu,
                      decoration: const InputDecoration(
                        labelText: 'Thứ',
                        border: OutlineInputBorder(),
                      ),
                      items: List.generate(7, (i) => i + 1)
                          .map(
                            (t) => DropdownMenuItem(
                              value: t,
                              child: Text('Thứ ${t == 7 ? 'Chủ Nhật' : t + 1}'),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        _onChanged();
                        setState(() => _thu = v!);
                      },
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Giờ bắt đầu'),
                      subtitle: Text(_start.format(context)),
                      trailing: const Icon(Icons.access_time),
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: _start,
                        );
                        if (picked != null) {
                          _onChanged();
                          setState(() => _start = picked);
                        }
                      },
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Giờ kết thúc'),
                      subtitle: Text(_end.format(context)),
                      trailing: const Icon(Icons.access_time),
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: _end,
                        );
                        if (picked != null) {
                          _onChanged();
                          setState(() => _end = picked);
                        }
                      },
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        isEdit
                            ? 'Áp dụng thay đổi từ ngày'
                            : 'Hiệu lực từ ngày',
                      ),
                      subtitle: Text(
                        DateFormatter.formatDisplayDate(_effectiveFrom),
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _effectiveFrom,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          _onChanged();
                          setState(() => _effectiveFrom = picked);
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
                          label: Text(isEdit ? 'Lưu lịch mới' : 'Lưu'),
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
    setState(() {
      _isSaving = true;
      _inlineError = null;
    });

    try {
      final startStr =
          '${_start.hour.toString().padLeft(2, '0')}:${_start.minute.toString().padLeft(2, '0')}';
      final endStr =
          '${_end.hour.toString().padLeft(2, '0')}:${_end.minute.toString().padLeft(2, '0')}';

      if (widget.scheduleToEdit != null) {
        final success = await ref
            .read(classScheduleControllerProvider(widget.classId).notifier)
            .revise(
              scheduleId: widget.scheduleToEdit!.id!,
              thuTrongTuan: _thu,
              gioBatDau: startStr,
              gioKetThuc: endStr,
              effectiveDate: _effectiveFrom,
            );
        if (success) {
          ref.invalidate(classScheduleControllerProvider(widget.classId));
          if (mounted) {
            setState(() => _isSaving = false);
            _isDirty = false;
            AppFeedback.showSuccessSnackBar(
              context,
              'Đã cập nhật lịch học mới',
            );
            Navigator.pop(context, true);
          }
        } else {
          if (mounted) {
            setState(() {
              _isSaving = false;
              _inlineError =
                  'Thay đổi lịch học thất bại. Kiểm tra xung đột lịch.';
            });
          }
        }
      } else {
        final schedule = ClassSchedule(
          idLop: widget.classId,
          thuTrongTuan: _thu,
          gioBatDau: startStr,
          gioKetThuc: endStr,
          hieuLucTu: DateFormat('yyyy-MM-dd').format(_effectiveFrom),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final success = await ref
            .read(classScheduleControllerProvider(widget.classId).notifier)
            .create(schedule);

        if (success) {
          ref.invalidate(classScheduleControllerProvider(widget.classId));
          if (mounted) {
            setState(() => _isSaving = false);
            _isDirty = false;
            AppFeedback.showSuccessSnackBar(context, 'Đã thêm lịch học mới');
            Navigator.pop(context, true);
          }
        } else {
          if (mounted) {
            setState(() {
              _isSaving = false;
              _inlineError =
                  'Tạo lịch học thất bại. Vui lòng kiểm tra xung đột lịch.';
            });
          }
        }
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

Future<bool?> showScheduleFormBottomSheet(
  BuildContext context, {
  required int classId,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    useSafeArea: true,
    builder: (_) => ScheduleFormBottomSheet(classId: classId),
  );
}

Future<bool?> showEditScheduleBottomSheet(
  BuildContext context, {
  required int classId,
  required ClassSchedule schedule,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    useSafeArea: true,
    builder: (_) =>
        ScheduleFormBottomSheet(classId: classId, scheduleToEdit: schedule),
  );
}
