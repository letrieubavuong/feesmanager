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
                final ordered = [...schedules]
                  ..sort((a, b) {
                    final weekday = a.thuTrongTuan.compareTo(b.thuTrongTuan);
                    return weekday != 0
                        ? weekday
                        : a.gioBatDau.compareTo(b.gioBatDau);
                  });
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 8,
                  ),
                  itemCount: ordered.length,
                  itemBuilder: (context, index) {
                    final s = ordered[index];
                    final isLast = index == ordered.length - 1;
                    final isActive = s.isEffectiveOn(DateTime.now());
                    return IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            width: 18,
                            child: Column(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: const BoxDecoration(
                                    color: AppColors.cyanAccent,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                if (!isLast)
                                  Expanded(
                                    child: Container(
                                      width: 2,
                                      color: AppColors.border,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: AppSectionCard(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: isActive
                                          ? AppColors.primary.withValues(
                                              alpha: 0.2,
                                            )
                                          : AppColors.textMuted.withValues(
                                              alpha: 0.15,
                                            ),
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 4,
                                          crossAxisAlignment:
                                              WrapCrossAlignment.center,
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
                                          _showCloseScheduleDialog(
                                            context,
                                            ref,
                                            s,
                                          );
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
                            ),
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
  final TextEditingController _ghiChuController = TextEditingController();
  int _thu = 1;
  TimeOfDay _start = const TimeOfDay(hour: 14, minute: 0);
  TimeOfDay _end = const TimeOfDay(hour: 15, minute: 30);
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
      _effectiveFrom =
          DateFormat('yyyy-MM-dd').tryParse(s.hieuLucTu) ?? DateTime.now();
      _ghiChuController.text = s.ghiChu ?? '';
    }
  }

  @override
  void dispose() {
    _ghiChuController.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (!_isDirty) {
      setState(() => _isDirty = true);
    }
  }

  String _formatThu(int thu) {
    switch (thu) {
      case 1:
        return 'Thứ Hai';
      case 2:
        return 'Thứ Ba';
      case 3:
        return 'Thứ Tư';
      case 4:
        return 'Thứ Năm';
      case 5:
        return 'Thứ Sáu';
      case 6:
        return 'Thứ Bảy';
      case 7:
        return 'Chủ Nhật';
      default:
        return 'Thứ $thu';
    }
  }

  String _formatTimeOfDay(TimeOfDay tod) {
    final h = tod.hour.toString().padLeft(2, '0');
    final m = tod.minute.toString().padLeft(2, '0');
    return '$h:$m';
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
              color: Color(0xFF1E293B),
            ),
          ),
          if (isRequired)
            const Text(
              ' *',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFFDC2626),
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
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFC7DCFB), width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 48,
              decoration: const BoxDecoration(
                color: Color(0xFFE2EDFE),
                borderRadius: BorderRadius.horizontal(
                  left: Radius.circular(11),
                ),
              ),
              child: Icon(icon, color: const Color(0xFF1D61E7), size: 20),
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
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
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
                            isEdit ? 'Chỉnh sửa lịch học' : 'Thêm lịch học',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F2038),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.close_rounded,
                              color: Color(0xFF1E293B),
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
                      _buildFieldLabel('Thứ trong tuần', isRequired: true),
                      PopupMenuButton<int>(
                        onSelected: (v) {
                          _onChanged();
                          setState(() => _thu = v);
                        },
                        itemBuilder: (context) => List.generate(7, (i) => i + 1)
                            .map(
                              (t) => PopupMenuItem(
                                value: t,
                                child: Text(
                                  _formatThu(t),
                                  style: const TextStyle(fontSize: 15),
                                ),
                              ),
                            )
                            .toList(),
                        child: IgnorePointer(
                          child: _buildCustomInputContainer(
                            icon: Icons.calendar_month_rounded,
                            child: Text(
                              _formatThu(_thu),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            trailing: const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: Color(0xFF1D61E7),
                              size: 24,
                            ),
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
                                  'Giờ bắt đầu',
                                  isRequired: true,
                                ),
                                _buildCustomInputContainer(
                                  icon: Icons.access_time_filled_rounded,
                                  child: Text(
                                    _formatTimeOfDay(_start),
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
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
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel(
                                  'Giờ kết thúc',
                                  isRequired: true,
                                ),
                                _buildCustomInputContainer(
                                  icon: Icons.access_time_filled_rounded,
                                  child: Text(
                                    _formatTimeOfDay(_end),
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
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
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildFieldLabel('Ngày hiệu lực từ', isRequired: true),
                      _buildCustomInputContainer(
                        icon: Icons.calendar_month_rounded,
                        child: Text(
                          DateFormatter.formatDisplayDate(_effectiveFrom),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: Color(0xFF64748B),
                          ),
                          onPressed: () {
                            _onChanged();
                            setState(() => _effectiveFrom = DateTime.now());
                          },
                        ),
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
                      const SizedBox(height: 16),
                      _buildFieldLabel('Ghi chú'),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFC7DCFB),
                            width: 1,
                          ),
                        ),
                        child: TextField(
                          controller: _ghiChuController,
                          maxLines: 2,
                          minLines: 1,
                          onChanged: (_) => _onChanged(),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF0F172A),
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Áp dụng từ tuần này.',
                            hintStyle: TextStyle(
                              color: Color(0xFF94A3B8),
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
                                  color: Color(0xFF1D61E7),
                                  width: 1.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                backgroundColor: Colors.white,
                              ),
                              child: const Text(
                                'Hủy',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isSaving ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0066FF),
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
                                      isEdit ? 'Lưu thay đổi' : 'Lưu',
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
    setState(() {
      _isSaving = true;
      _inlineError = null;
    });

    try {
      final startStr =
          '${_start.hour.toString().padLeft(2, '0')}:${_start.minute.toString().padLeft(2, '0')}';
      final endStr =
          '${_end.hour.toString().padLeft(2, '0')}:${_end.minute.toString().padLeft(2, '0')}';
      final ghiChu = _ghiChuController.text.trim().isEmpty
          ? null
          : _ghiChuController.text.trim();

      if (widget.scheduleToEdit != null) {
        final success = await ref
            .read(classScheduleControllerProvider(widget.classId).notifier)
            .revise(
              scheduleId: widget.scheduleToEdit!.id!,
              thuTrongTuan: _thu,
              gioBatDau: startStr,
              gioKetThuc: endStr,
              effectiveDate: _effectiveFrom,
              ghiChu: ghiChu,
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
          ghiChu: ghiChu,
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
    backgroundColor: Colors.transparent,
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
    backgroundColor: Colors.transparent,
    builder: (_) =>
        ScheduleFormBottomSheet(classId: classId, scheduleToEdit: schedule),
  );
}
