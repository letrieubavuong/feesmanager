import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/common_widgets/app_feedback.dart';
import '../../../app/common_widgets/app_page_scaffold.dart';
import '../../../app/common_widgets/dirty_form_scope.dart';
import '../../../core/utils/date_and_time_validators.dart';
import '../../../core/utils/date_formatter.dart';
import '../domain/schedule_constraint.dart';
import 'schedule_conflict_providers.dart';

class BusyTimeFormBottomSheet extends ConsumerStatefulWidget {
  final int studentId;

  const BusyTimeFormBottomSheet({super.key, required this.studentId});

  @override
  ConsumerState<BusyTimeFormBottomSheet> createState() =>
      _BusyTimeFormBottomSheetState();
}

class _BusyTimeFormBottomSheetState
    extends ConsumerState<BusyTimeFormBottomSheet> {
  final _formKey = GlobalKey<FormState>();

  ConstraintType _selectedType = ConstraintType.HARD_BLOCK;
  OccurrenceType _selectedOccurrence = OccurrenceType.DINH_KY;
  int _selectedWeekday = 1;

  DateTime _specificDate = DateTime.now();
  DateTime _effectiveFrom = DateTime.now();
  DateTime? _effectiveTo;

  TimeOfDay _startTime = const TimeOfDay(hour: 17, minute: 30);
  TimeOfDay _endTime = const TimeOfDay(hour: 19, minute: 0);

  late TextEditingController _bufferController;
  late TextEditingController _sourceController;
  late TextEditingController _noteController;

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
    _bufferController = TextEditingController(text: '0')
      ..addListener(_onChanged);
    _sourceController = TextEditingController()..addListener(_onChanged);
    _noteController = TextEditingController()..addListener(_onChanged);
  }

  @override
  void dispose() {
    _bufferController.dispose();
    _sourceController.dispose();
    _noteController.dispose();
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
                        Text(
                          'Thêm giờ bận của học sinh',
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
                    DropdownButtonFormField<ConstraintType>(
                      initialValue: _selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Loại giờ bận',
                        border: OutlineInputBorder(),
                      ),
                      items: ConstraintType.values
                          .map(
                            (t) => DropdownMenuItem(
                              value: t,
                              child: Text(t.displayName),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          _onChanged();
                          setState(() => _selectedType = val);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<OccurrenceType>(
                      initialValue: _selectedOccurrence,
                      decoration: const InputDecoration(
                        labelText: 'Lặp lại',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: OccurrenceType.DINH_KY,
                          child: Text('Hằng tuần (Định kỳ)'),
                        ),
                        DropdownMenuItem(
                          value: OccurrenceType.MOT_LAN,
                          child: Text('Một lần'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          _onChanged();
                          setState(() => _selectedOccurrence = val);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    if (_selectedOccurrence == OccurrenceType.DINH_KY) ...[
                      DropdownButtonFormField<int>(
                        initialValue: _selectedWeekday,
                        decoration: const InputDecoration(
                          labelText: 'Thứ trong tuần',
                          border: OutlineInputBorder(),
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
                          if (val != null) {
                            _onChanged();
                            setState(() => _selectedWeekday = val);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Hiệu lực từ ngày'),
                        subtitle: Text(
                          DateFormatter.formatDisplayDate(_effectiveFrom),
                        ),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _effectiveFrom,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) {
                            _onChanged();
                            setState(() => _effectiveFrom = picked);
                          }
                        },
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Hiệu lực đến ngày'),
                        subtitle: Text(
                          _effectiveTo != null
                              ? DateFormatter.formatDisplayDate(_effectiveTo!)
                              : 'Không giới hạn',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_effectiveTo != null)
                              IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _onChanged();
                                  setState(() => _effectiveTo = null);
                                },
                              ),
                            const Icon(Icons.calendar_today),
                          ],
                        ),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _effectiveTo ?? _effectiveFrom,
                            firstDate: _effectiveFrom,
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) {
                            _onChanged();
                            setState(() => _effectiveTo = picked);
                          }
                        },
                      ),
                    ] else ...[
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Ngày bận'),
                        subtitle: Text(
                          DateFormatter.formatDisplayDate(_specificDate),
                        ),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _specificDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) {
                            _onChanged();
                            setState(() => _specificDate = picked);
                          }
                        },
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Từ giờ'),
                            subtitle: Text(_startTime.format(context)),
                            trailing: const Icon(Icons.access_time),
                            onTap: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: _startTime,
                              );
                              if (picked != null) {
                                _onChanged();
                                setState(() => _startTime = picked);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Đến giờ'),
                            subtitle: Text(_endTime.format(context)),
                            trailing: const Icon(Icons.access_time),
                            onTap: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: _endTime,
                              );
                              if (picked != null) {
                                _onChanged();
                                setState(() => _endTime = picked);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    if (_selectedType == ConstraintType.OTHER_CENTER) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _sourceController,
                        decoration: const InputDecoration(
                          labelText: 'Tên trường / trung tâm khác',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _bufferController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Thời gian di chuyển cần thiết (phút)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _noteController,
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
                          label: const Text('Lưu giờ bận'),
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
          '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}';
      final endStr =
          '${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}';

      DateAndTimeValidators.validateTimeOrder(
        startStr,
        endStr,
        'startTime',
        'endTime',
      );

      final bufferMins = int.tryParse(_bufferController.text.trim()) ?? 0;

      if (_selectedType == ConstraintType.OTHER_CENTER &&
          _sourceController.text.trim().isEmpty) {
        throw const FormatException(
          'Trường / trung tâm khác không được để trống',
        );
      }

      String? effFromStr;
      String? effToStr;
      String? specDateStr;

      if (_selectedOccurrence == OccurrenceType.DINH_KY) {
        effFromStr = DateFormatter.formatCanonicalDate(_effectiveFrom);
        if (_effectiveTo != null) {
          effToStr = DateFormatter.formatCanonicalDate(_effectiveTo!);
          if (_effectiveTo!.isBefore(_effectiveFrom)) {
            throw const FormatException(
              'Hiệu lực đến ngày không được trước hiệu lực từ ngày',
            );
          }
        }
      } else {
        specDateStr = DateFormatter.formatCanonicalDate(_specificDate);
      }

      final constraint = ScheduleConstraint(
        studentId: widget.studentId,
        type: _selectedType,
        occurrenceType: _selectedOccurrence,
        weekday: _selectedOccurrence == OccurrenceType.DINH_KY
            ? _selectedWeekday
            : null,
        specificDate: specDateStr,
        startTime: startStr,
        endTime: endStr,
        effectiveFrom: effFromStr,
        effectiveTo: effToStr,
        travelBufferMinutes: bufferMins,
        sourceName: _sourceController.text.trim().isNotEmpty
            ? _sourceController.text.trim()
            : null,
        note: _noteController.text.trim().isNotEmpty
            ? _noteController.text.trim()
            : null,
      );

      await ref
          .read(scheduleConstraintControllerProvider.notifier)
          .createConstraint(constraint);

      if (mounted) {
        setState(() => _isSaving = false);
        _isDirty = false;
        AppFeedback.showSuccessSnackBar(context, 'Đã thêm giờ bận thành công');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _inlineError = e
              .toString()
              .replaceAll('FormatException: ', '')
              .replaceAll('Exception: ', '');
        });
      }
    }
  }
}

Future<bool?> showAddBusyTimeBottomSheet(
  BuildContext context, {
  required int studentId,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    useSafeArea: true,
    builder: (_) => BusyTimeFormBottomSheet(studentId: studentId),
  );
}

void showAddConstraintDialog(
  BuildContext context,
  WidgetRef ref,
  int studentId,
) {
  showAddBusyTimeBottomSheet(context, studentId: studentId);
}
