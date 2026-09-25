import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:tuition2027/core/utils/date_and_time_validators.dart';
import '../domain/schedule_constraint.dart';
import 'schedule_conflict_providers.dart';

void showAddConstraintDialog(
  BuildContext context,
  WidgetRef ref,
  int studentId,
) {
  ConstraintType selectedType = ConstraintType.HARD_BLOCK;
  OccurrenceType selectedOccurrence = OccurrenceType.DINH_KY;
  int selectedWeekday = 1;
  final dateController = TextEditingController(
    text: DateFormat('yyyy-MM-dd').format(DateTime.now()),
  );
  final startController = TextEditingController(text: '17:30');
  final endController = TextEditingController(text: '19:00');
  final effectiveFromController = TextEditingController(
    text: DateFormat('yyyy-MM-dd').format(DateTime.now()),
  );
  final effectiveToController = TextEditingController();
  final bufferController = TextEditingController(text: '0');
  final sourceController = TextEditingController();
  final noteController = TextEditingController();

  showDialog(
    context: context,
    builder: (dialogCtx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: const Text('Thêm ràng buộc lịch học sinh'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<ConstraintType>(
                initialValue: selectedType,
                decoration: const InputDecoration(labelText: 'Loại ràng buộc'),
                items: ConstraintType.values
                    .map(
                      (t) => DropdownMenuItem(
                        value: t,
                        child: Text(t.displayName),
                      ),
                    )
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => selectedType = val);
                },
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<OccurrenceType>(
                initialValue: selectedOccurrence,
                decoration: const InputDecoration(labelText: 'Tần suất'),
                items: OccurrenceType.values
                    .map(
                      (o) => DropdownMenuItem(
                        value: o,
                        child: Text(o.displayName),
                      ),
                    )
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => selectedOccurrence = val);
                },
              ),
              const SizedBox(height: 8),
              if (selectedOccurrence == OccurrenceType.DINH_KY) ...[
                DropdownButtonFormField<int>(
                  initialValue: selectedWeekday,
                  decoration: const InputDecoration(
                    labelText: 'Thứ trong tuần',
                  ),
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('Thứ Hai')),
                    DropdownMenuItem(value: 2, child: Text('Thứ Ba')),
                    DropdownMenuItem(value: 3, child: Text('Thứ Tư')),
                    DropdownMenuItem(value: 4, child: Text('Thứ Năm')),
                    DropdownMenuItem(value: 5, child: Text('Thứ Sáu')),
                    DropdownMenuItem(value: 6, child: Text('Thứ Bảy')),
                    DropdownMenuItem(value: 7, child: Text('Chủ Nhật')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => selectedWeekday = val);
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: effectiveFromController,
                        decoration: const InputDecoration(
                          labelText: 'Hiệu lực từ ngày (YYYY-MM-DD)',
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: dialogCtx,
                          initialDate:
                              DateTime.tryParse(effectiveFromController.text) ??
                              DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          effectiveFromController.text = DateFormat(
                            'yyyy-MM-dd',
                          ).format(picked);
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: effectiveToController,
                  decoration: const InputDecoration(
                    labelText: 'Hiệu lực đến ngày (để trống nếu vô hạn)',
                  ),
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: dateController,
                        decoration: const InputDecoration(
                          labelText: 'Ngày cụ thể (YYYY-MM-DD)',
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: dialogCtx,
                          initialDate:
                              DateTime.tryParse(dateController.text) ??
                              DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          dateController.text = DateFormat(
                            'yyyy-MM-dd',
                          ).format(picked);
                        }
                      },
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: startController,
                      decoration: const InputDecoration(
                        labelText: 'Giờ bắt đầu (HH:mm)',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: endController,
                      decoration: const InputDecoration(
                        labelText: 'Giờ kết thúc (HH:mm)',
                      ),
                    ),
                  ),
                ],
              ),
              if (selectedType == ConstraintType.OTHER_CENTER) ...[
                const SizedBox(height: 8),
                TextField(
                  controller: sourceController,
                  decoration: const InputDecoration(
                    labelText: 'Tên trường / trung tâm khác',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: bufferController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Thời gian di chuyển cần thiết (phút)',
                  ),
                ),
              ],
              const SizedBox(height: 8),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(labelText: 'Ghi chú'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final startTime = startController.text.trim();
                final endTime = endController.text.trim();

                DateAndTimeValidators.validateTimeOrder(
                  startTime,
                  endTime,
                  'startTime',
                  'endTime',
                );

                final bufferMins =
                    int.tryParse(bufferController.text.trim()) ?? -1;
                if (bufferMins < 0) {
                  throw const FormatException(
                    'Thời gian di chuyển phải là số nguyên lớn hơn hoặc bằng 0',
                  );
                }

                if (selectedType == ConstraintType.OTHER_CENTER &&
                    sourceController.text.trim().isEmpty) {
                  throw const FormatException(
                    'Trường / trung tâm khác không được để trống',
                  );
                }

                if (selectedOccurrence == OccurrenceType.DINH_KY) {
                  final effFrom = effectiveFromController.text.trim();
                  DateAndTimeValidators.validateDateStr(
                    effFrom,
                    'effectiveFrom',
                  );
                  final effTo = effectiveToController.text.trim();
                  if (effTo.isNotEmpty) {
                    DateAndTimeValidators.validateDateStr(effTo, 'effectiveTo');
                    if (effTo.compareTo(effFrom) < 0) {
                      throw const FormatException(
                        'Hiệu lực đến ngày không được trước hiệu lực từ ngày',
                      );
                    }
                  }
                } else {
                  final specDate = dateController.text.trim();
                  DateAndTimeValidators.validateDateStr(
                    specDate,
                    'specificDate',
                  );
                }

                final constraint = ScheduleConstraint(
                  studentId: studentId,
                  type: selectedType,
                  occurrenceType: selectedOccurrence,
                  weekday: selectedOccurrence == OccurrenceType.DINH_KY
                      ? selectedWeekday
                      : null,
                  specificDate: selectedOccurrence == OccurrenceType.MOT_LAN
                      ? dateController.text.trim()
                      : null,
                  startTime: startTime,
                  endTime: endTime,
                  effectiveFrom: selectedOccurrence == OccurrenceType.DINH_KY
                      ? effectiveFromController.text.trim()
                      : null,
                  effectiveTo:
                      selectedOccurrence == OccurrenceType.DINH_KY &&
                          effectiveToController.text.trim().isNotEmpty
                      ? effectiveToController.text.trim()
                      : null,
                  travelBufferMinutes: bufferMins,
                  sourceName: sourceController.text.trim().isNotEmpty
                      ? sourceController.text.trim()
                      : null,
                  note: noteController.text.trim().isNotEmpty
                      ? noteController.text.trim()
                      : null,
                );

                await ref
                    .read(scheduleConstraintControllerProvider.notifier)
                    .createConstraint(constraint);

                if (dialogCtx.mounted) {
                  Navigator.pop(dialogCtx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Thêm ràng buộc lịch thành công!'),
                    ),
                  );
                }
              } catch (e) {
                if (dialogCtx.mounted) {
                  ScaffoldMessenger.of(dialogCtx).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Lỗi: ${e.toString().replaceAll("FormatException: ", "").replaceAll("Exception: ", "")}',
                      ),
                    ),
                  );
                }
              }
            },
            child: const Text('Lưu ràng buộc'),
          ),
        ],
      ),
    ),
  );
}
