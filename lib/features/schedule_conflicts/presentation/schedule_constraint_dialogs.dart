import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/common_widgets/app_feedback.dart';
import '../../../app/common_widgets/app_page_scaffold.dart';
import '../../../app/common_widgets/dirty_form_scope.dart';
import '../../../core/utils/date_and_time_validators.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../l10n/app_localizations.dart';
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
                          l10n.busyTimeTitle,
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
                      decoration: InputDecoration(
                        labelText: l10n.busyTimeType,
                        border: const OutlineInputBorder(),
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
                      decoration: InputDecoration(
                        labelText: l10n.busyTimeFrequency,
                        border: const OutlineInputBorder(),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: OccurrenceType.DINH_KY,
                          child: Text(l10n.busyTimeWeekly),
                        ),
                        DropdownMenuItem(
                          value: OccurrenceType.MOT_LAN,
                          child: Text(l10n.busyTimeOneTime),
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
                        decoration: InputDecoration(
                          labelText: l10n.busyTimeDayOfWeek,
                          border: const OutlineInputBorder(),
                        ),
                        items: List.generate(7, (i) => i + 1)
                            .map(
                              (w) => DropdownMenuItem(
                                value: w,
                                child: Text(
                                  DateFormatter.formatVietnameseWeekday(w),
                                ),
                              ),
                            )
                            .toList(),
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
                        title: Text(l10n.busyTimeEffectiveFrom),
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
                        title: Text(l10n.busyTimeEffectiveTo),
                        subtitle: Text(
                          _effectiveTo != null
                              ? DateFormatter.formatDisplayDate(_effectiveTo!)
                              : l10n.filterAll,
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
                        title: Text(l10n.busyTimeDate),
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
                            title: Text(l10n.busyTimeStartTime),
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
                            title: Text(l10n.busyTimeEndTime),
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
                        decoration: InputDecoration(
                          labelText: l10n.studentSchool,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _bufferController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Thời gian di chuyển (phút)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _noteController,
                      decoration: InputDecoration(
                        labelText: l10n.studentNotes,
                        border: const OutlineInputBorder(),
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
                          child: Text(l10n.commonCancel),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: _isSaving ? null : () => _submit(l10n),
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
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
        ),
      ),
    );
  }

  void _submit(AppLocalizations l10n) async {
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

      final rawBufferStr = _bufferController.text.trim();
      final bufferMins = int.tryParse(rawBufferStr) ?? 0;

      String? effFromStr;
      String? effToStr;
      String? specDateStr;

      if (_selectedOccurrence == OccurrenceType.DINH_KY) {
        effFromStr = DateFormatter.formatCanonicalDate(_effectiveFrom);
        if (_effectiveTo != null) {
          effToStr = DateFormatter.formatCanonicalDate(_effectiveTo!);
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
        AppFeedback.showSuccessSnackBar(context, l10n.commonSave);
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _inlineError =
              '${l10n.commonError}: ${e.toString().replaceAll('FormatException: ', '').replaceAll('Exception: ', '')}';
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
