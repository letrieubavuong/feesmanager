import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../app/common_widgets/app_page_scaffold.dart';
import '../../../app/common_widgets/dirty_form_scope.dart';
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
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  ElevatedButton.icon(
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
                  return const Center(child: Text('Lớp chưa có lịch học nào.'));
                }
                return ListView.builder(
                  itemCount: schedules.length,
                  itemBuilder: (context, index) {
                    final s = schedules[index];
                    final isActive = s.isEffectiveOn(DateTime.now());
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isActive
                            ? Colors.blue.shade100
                            : Colors.grey.shade200,
                        child: Text(
                          s.thuTrongTuan == 7 ? 'CN' : 'T${s.thuTrongTuan + 1}',
                        ),
                      ),
                      title: Text(
                        '${DateFormatter.formatVietnameseWeekday(s.thuTrongTuan)}: ${s.gioBatDau} - ${s.gioKetThuc}',
                        style: TextStyle(
                          fontWeight: isActive ? FontWeight.bold : null,
                        ),
                      ),
                      subtitle: Text(
                        'Hiệu lực: ${DateFormatter.formatShortDate(s.hieuLucTu)}${s.hieuLucDen != null ? ' đến ${DateFormatter.formatShortDate(s.hieuLucDen)}' : ''}',
                      ),
                      trailing: (isActive && !isArchived)
                          ? IconButton(
                              icon: const Icon(Icons.event_busy),
                              onPressed: () =>
                                  _showCloseScheduleDialog(context, ref, s),
                            )
                          : const Icon(Icons.history, size: 16),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Lỗi: $e')),
            ),
          ),
        ],
      ),
      floatingActionButton: isArchived
          ? null
          : FloatingActionButton(
              onPressed: () =>
                  showScheduleFormBottomSheet(context, classId: classId),
              mini: true,
              child: const Icon(Icons.add),
            ),
    );
  }

  void _showCloseScheduleDialog(
    BuildContext context,
    WidgetRef ref,
    ClassSchedule schedule,
  ) {
    DateTime endDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Kết thúc lịch học'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Ngày kết thúc'),
                subtitle: Text(DateFormat('dd/MM/yyyy').format(endDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: endDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setDialogState(() => endDate = picked);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  final success = await ref
                      .read(classScheduleControllerProvider(classId).notifier)
                      .close(schedule.id!, endDate);
                  if (success && context.mounted) Navigator.pop(context);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          e.toString().replaceAll('Exception: ', ''),
                        ),
                      ),
                    );
                  }
                }
              },
              child: const Text('Xác nhận'),
            ),
          ],
        ),
      ),
    );
  }
}

class ScheduleFormBottomSheet extends ConsumerStatefulWidget {
  final int classId;

  const ScheduleFormBottomSheet({super.key, required this.classId});

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
                          'Thêm lịch học',
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
                      title: const Text('Hiệu lực từ'),
                      subtitle: Text(
                        DateFormat('dd/MM/yyyy').format(_effectiveFrom),
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
      ),
    );
  }

  void _submit() async {
    setState(() {
      _isSaving = true;
      _inlineError = null;
    });

    try {
      final schedule = ClassSchedule(
        idLop: widget.classId,
        thuTrongTuan: _thu,
        gioBatDau:
            '${_start.hour.toString().padLeft(2, '0')}:${_start.minute.toString().padLeft(2, '0')}',
        gioKetThuc:
            '${_end.hour.toString().padLeft(2, '0')}:${_end.minute.toString().padLeft(2, '0')}',
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
