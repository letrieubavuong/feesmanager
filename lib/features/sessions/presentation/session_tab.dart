import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../app/design_system/app_spacing.dart';
import '../../../../app/design_system/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../roster/presentation/session_roster_view.dart';
import '../domain/class_session.dart';
import 'session_controller.dart';
import 'widgets/session_timeline_item.dart';

class SessionTab extends ConsumerStatefulWidget {
  final int classId;
  final bool isArchived;

  const SessionTab({super.key, required this.classId, this.isArchived = false});

  @override
  ConsumerState<SessionTab> createState() => _SessionTabState();
}

class _SessionTabState extends ConsumerState<SessionTab> {
  late DateTime _startDate;
  late DateTime _endDate;
  bool _rangeInitialized = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = now.subtract(const Duration(days: 7));
    _endDate = now.add(const Duration(days: 30));
  }

  int _compareSessionsAscending(ClassSession a, ClassSession b) {
    final dateCompare = a.ngay.compareTo(b.ngay);
    if (dateCompare != 0) return dateCompare;

    final timeCompare = a.gioBatDau.compareTo(b.gioBatDau);
    if (timeCompare != 0) return timeCompare;

    return (a.id ?? 0).compareTo(b.id ?? 0);
  }

  @override
  Widget build(BuildContext context) {
    final sessionsAsync = ref.watch(
      classSessionControllerProvider(widget.classId),
    );
    final l10n = AppLocalizations.of(context)!;
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        child: Column(
          children: [
            // Filter Bar & Action Header
            _buildFilterAndHeaderBar(l10n),

            const SizedBox(height: 6),

            // Timeline Body
            Expanded(
              child: sessionsAsync.when(
                data: (allSessions) {
                  if (allSessions.isEmpty) {
                    return _buildEmptyState(l10n: l10n, isFiltered: false);
                  }

                  // One-time Range Initialization to full history bounds
                  if (!_rangeInitialized) {
                    final sortedAll = List<ClassSession>.from(allSessions)
                      ..sort(_compareSessionsAscending);
                    _startDate = DateTime.parse(sortedAll.first.ngay);
                    _endDate = DateTime.parse(sortedAll.last.ngay);
                    _rangeInitialized = true;
                  }

                  final filtered = allSessions.where((s) {
                    final date = DateTime.parse(s.ngay);
                    final start = DateTime(
                      _startDate.year,
                      _startDate.month,
                      _startDate.day,
                    );
                    final end = DateTime(
                      _endDate.year,
                      _endDate.month,
                      _endDate.day,
                      23,
                      59,
                      59,
                    );
                    return !date.isBefore(start) && !date.isAfter(end);
                  }).toList();

                  // Sort chronologically ASCENDING
                  filtered.sort(_compareSessionsAscending);

                  if (filtered.isEmpty) {
                    return _buildEmptyState(l10n: l10n, isFiltered: true);
                  }

                  // Group by Month YYYY-MM
                  final LinkedHashMap<String, List<ClassSession>> grouped =
                      LinkedHashMap();
                  for (final s in filtered) {
                    final monthKey = s.ngay.substring(0, 7);
                    grouped.putIfAbsent(monthKey, () => []).add(s);
                  }

                  final totalSessions = filtered.length;
                  int globalIndex = 0;

                  return CustomScrollView(
                    slivers: [
                      for (final entry in grouped.entries) ...[
                        SliverToBoxAdapter(
                          child: _buildMonthHeader(entry.key, l10n),
                        ),
                        SliverList(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final session = entry.value[index];
                            final isFirst = globalIndex == 0;
                            final isLast = globalIndex == totalSessions - 1;
                            globalIndex++;

                            return SessionTimelineItem(
                              session: session,
                              isFirst: isFirst,
                              isLast: isLast,
                              isToday: session.ngay == todayStr,
                              isArchived: widget.isArchived,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      SessionRosterView(sessionId: session.id!),
                                ),
                              ),
                              onStatusSelected: (status) =>
                                  _confirmStatusChange(
                                    context,
                                    ref,
                                    session,
                                    status,
                                  ),
                            );
                          }, childCount: entry.value.length),
                        ),
                      ],
                    ],
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
      ),
    );
  }

  Widget _buildFilterAndHeaderBar(AppLocalizations l10n) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_month_outlined,
                    size: 16,
                    color: AppColors.cyanAccent,
                  ),
                  const SizedBox(width: 4),

                  // Start Date Button
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _startDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() {
                          _startDate = picked;
                          if (_endDate.isBefore(_startDate)) {
                            _endDate = _startDate;
                          }
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceHigh,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        dateFormat.format(_startDate),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 2.0),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      size: 12,
                      color: AppColors.textMuted,
                    ),
                  ),

                  // End Date Button
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _endDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() {
                          _endDate = picked;
                          if (_endDate.isBefore(_startDate)) {
                            _startDate = _endDate;
                          }
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceHigh,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        dateFormat.format(_endDate),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Add Session Action Button
          if (!widget.isArchived) ...[
            const SizedBox(width: 4),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () => _showAddSessionActionSheet(context, ref),
              icon: const Icon(Icons.add_rounded, size: 14),
              label: Text(
                l10n.sessionAddAction,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMonthHeader(String monthKey, AppLocalizations l10n) {
    final date = DateTime.parse('$monthKey-01');
    final monthStr = DateFormat('MM/yyyy').format(date);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        children: [
          const Expanded(
            child: Divider(color: AppColors.border, height: 1, thickness: 1),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Text(
              'THÁNG $monthStr',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
          ),
          const Expanded(
            child: Divider(color: AppColors.border, height: 1, thickness: 1),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required AppLocalizations l10n,
    required bool isFiltered,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isFiltered
                  ? Icons.filter_alt_off_outlined
                  : Icons.calendar_today_outlined,
              size: 44,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 12),
            Text(
              isFiltered
                  ? l10n.sessionNoFilteredTitle
                  : l10n.sessionNoSessionsTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (!isFiltered) ...[
              const SizedBox(height: 6),
              Text(
                l10n.sessionNoSessionsSubtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showAddSessionActionSheet(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.auto_awesome,
                    color: AppColors.primary,
                  ),
                  title: Text(
                    l10n.sessionGenerateOption,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showGenerateDialog(context, ref);
                  },
                ),
                const Divider(color: AppColors.border, height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.add_circle_outline,
                    color: AppColors.cyanAccent,
                  ),
                  title: Text(
                    l10n.sessionAddManualOption,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showManualDialog(context, ref);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmStatusChange(
    BuildContext context,
    WidgetRef ref,
    ClassSession session,
    SessionStatus status,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final statusLabel = status == SessionStatus.DU_KIEN
        ? l10n.sessionStatusUpcoming
        : status == SessionStatus.HUY
        ? l10n.sessionStatusCanceled
        : l10n.sessionStatusHoliday;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Đổi trạng thái buổi học',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          'Bạn có chắc chắn muốn chuyển trạng thái buổi học sang "$statusLabel"?',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref
            .read(classSessionControllerProvider(widget.classId).notifier)
            .updateStatus(session.id!, status);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(e.toString())));
        }
      }
    }
  }

  void _showGenerateDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => GenerateSessionsDialog(classId: widget.classId),
    );
  }

  void _showManualDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => ManualSessionDialog(classId: widget.classId),
    );
  }
}

class GenerateSessionsDialog extends StatefulWidget {
  final int classId;
  const GenerateSessionsDialog({super.key, required this.classId});

  @override
  State<GenerateSessionsDialog> createState() => _GenerateSessionsDialogState();
}

class _GenerateSessionsDialogState extends State<GenerateSessionsDialog> {
  DateTime _fromDate = DateTime.now();
  DateTime _toDate = DateTime.now().add(const Duration(days: 30));
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text(
        'Sinh buổi học tự động',
        style: TextStyle(color: AppColors.textPrimary),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Sinh các buổi học chính thức dựa trên lịch học định kỳ trong khoảng:',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          ListTile(
            title: const Text(
              'Từ ngày',
              style: TextStyle(color: AppColors.textPrimary),
            ),
            subtitle: Text(
              DateFormat('dd/MM/yyyy').format(_fromDate),
              style: const TextStyle(color: AppColors.cyanAccent),
            ),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _fromDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );
              if (picked != null) setState(() => _fromDate = picked);
            },
          ),
          ListTile(
            title: const Text(
              'Đến ngày',
              style: TextStyle(color: AppColors.textPrimary),
            ),
            subtitle: Text(
              DateFormat('dd/MM/yyyy').format(_toDate),
              style: const TextStyle(color: AppColors.cyanAccent),
            ),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _toDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );
              if (picked != null) setState(() => _toDate = picked);
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        Consumer(
          builder: (context, ref, _) => ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: _loading ? null : () => _submit(ref),
            child: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Sinh buổi học'),
          ),
        ),
      ],
    );
  }

  void _submit(WidgetRef ref) async {
    setState(() => _loading = true);
    try {
      final result = await ref
          .read(classSessionControllerProvider(widget.classId).notifier)
          .generate(fromDate: _fromDate, toDate: _toDate);
      if (mounted) {
        Navigator.pop(context);
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.surface,
            title: const Text(
              'Kết quả sinh buổi học',
              style: TextStyle(color: AppColors.textPrimary),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Đã tạo mới: ${result.createdCount}',
                  style: const TextStyle(color: AppColors.textPrimary),
                ),
                Text(
                  'Đã tồn tại: ${result.existingCount}',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                if (result.conflictCount > 0)
                  Text(
                    'Xung đột: ${result.conflictCount}',
                    style: const TextStyle(
                      color: AppColors.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                if (result.warnings.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Cảnh báo:',
                    style: TextStyle(
                      color: AppColors.warning,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ...result.warnings.map(
                    (w) => Text(
                      '• $w',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Đóng'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

class ManualSessionDialog extends StatefulWidget {
  final int classId;
  const ManualSessionDialog({super.key, required this.classId});

  @override
  State<ManualSessionDialog> createState() => _ManualSessionDialogState();
}

class _ManualSessionDialogState extends State<ManualSessionDialog> {
  DateTime _ngay = DateTime.now();
  TimeOfDay _start = const TimeOfDay(hour: 17, minute: 30);
  TimeOfDay _end = const TimeOfDay(hour: 19, minute: 0);
  SessionType _type = SessionType.HOC_BU;
  final _noteController = TextEditingController();
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text(
        'Thêm buổi học thủ công',
        style: TextStyle(color: AppColors.textPrimary),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<SessionType>(
              initialValue: _type,
              dropdownColor: AppColors.surfaceHigh,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Loại buổi học',
                labelStyle: TextStyle(color: AppColors.textSecondary),
              ),
              items: [
                DropdownMenuItem(
                  value: SessionType.HOC_BU,
                  child: Text(l10n.sessionTypeMakeup),
                ),
                DropdownMenuItem(
                  value: SessionType.PHAT_SINH,
                  child: Text(l10n.sessionTypeExtra),
                ),
              ],
              onChanged: (v) => setState(() => _type = v!),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text(
                'Ngày',
                style: TextStyle(color: AppColors.textPrimary),
              ),
              subtitle: Text(
                DateFormat('dd/MM/yyyy').format(_ngay),
                style: const TextStyle(color: AppColors.cyanAccent),
              ),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _ngay,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (picked != null) setState(() => _ngay = picked);
              },
            ),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    title: const Text(
                      'Bắt đầu',
                      style: TextStyle(color: AppColors.textPrimary),
                    ),
                    subtitle: Text(
                      _start.format(context),
                      style: const TextStyle(color: AppColors.cyanAccent),
                    ),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: _start,
                      );
                      if (picked != null) setState(() => _start = picked);
                    },
                  ),
                ),
                Expanded(
                  child: ListTile(
                    title: const Text(
                      'Kết thúc',
                      style: TextStyle(color: AppColors.textPrimary),
                    ),
                    subtitle: Text(
                      _end.format(context),
                      style: const TextStyle(color: AppColors.cyanAccent),
                    ),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: _end,
                      );
                      if (picked != null) setState(() => _end = picked);
                    },
                  ),
                ),
              ],
            ),
            TextField(
              controller: _noteController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Ghi chú',
                labelStyle: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        Consumer(
          builder: (context, ref, _) => ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: _loading ? null : () => _submit(ref),
            child: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Thêm'),
          ),
        ),
      ],
    );
  }

  void _submit(WidgetRef ref) async {
    setState(() => _loading = true);
    try {
      final session = ClassSession(
        idLop: widget.classId,
        ngay: DateFormat('yyyy-MM-dd').format(_ngay),
        gioBatDau:
            '${_start.hour.toString().padLeft(2, '0')}:${_start.minute.toString().padLeft(2, '0')}',
        gioKetThuc:
            '${_end.hour.toString().padLeft(2, '0')}:${_end.minute.toString().padLeft(2, '0')}',
        loai: _type,
        trangThai: SessionStatus.DU_KIEN,
        ghiChu: _noteController.text,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await ref
          .read(classSessionControllerProvider(widget.classId).notifier)
          .createManual(session);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
