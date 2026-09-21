import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../domain/class_schedule.dart';
import 'schedule_controller.dart';

import 'package:tuition2027/core/utils/date_formatter.dart';

class ScheduleTab extends ConsumerWidget {
  final int classId;
  const ScheduleTab({super.key, required this.classId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schedulesAsync = ref.watch(classScheduleControllerProvider(classId));

    return Scaffold(
      body: schedulesAsync.when(
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
                trailing: isActive
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddScheduleDialog(context, ref),
        mini: true,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddScheduleDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => ScheduleFormDialog(classId: classId),
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

class ScheduleFormDialog extends StatefulWidget {
  final int classId;
  const ScheduleFormDialog({super.key, required this.classId});

  @override
  State<ScheduleFormDialog> createState() => _ScheduleFormDialogState();
}

class _ScheduleFormDialogState extends State<ScheduleFormDialog> {
  int _thu = 1;
  TimeOfDay _start = const TimeOfDay(hour: 17, minute: 30);
  TimeOfDay _end = const TimeOfDay(hour: 19, minute: 0);
  DateTime _effectiveFrom = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Thêm lịch học'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<int>(
              initialValue: _thu,
              decoration: const InputDecoration(labelText: 'Thứ'),
              items: List.generate(7, (i) => i + 1)
                  .map(
                    (t) => DropdownMenuItem(
                      value: t,
                      child: Text('Thứ ${t == 7 ? 'Chủ Nhật' : t + 1}'),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _thu = v!),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Giờ bắt đầu'),
              subtitle: Text(_start.format(context)),
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: _start,
                );
                if (picked != null) setState(() => _start = picked);
              },
            ),
            ListTile(
              title: const Text('Giờ kết thúc'),
              subtitle: Text(_end.format(context)),
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: _end,
                );
                if (picked != null) setState(() => _end = picked);
              },
            ),
            ListTile(
              title: const Text('Hiệu lực từ'),
              subtitle: Text(DateFormat('dd/MM/yyyy').format(_effectiveFrom)),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _effectiveFrom,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (picked != null) setState(() => _effectiveFrom = picked);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        Consumer(
          builder: (context, ref, _) => ElevatedButton(
            onPressed: () => _submit(ref),
            child: const Text('Lưu'),
          ),
        ),
      ],
    );
  }

  void _submit(WidgetRef ref) async {
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
    if (success && mounted) Navigator.pop(context);
  }
}
