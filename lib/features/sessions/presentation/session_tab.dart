import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../domain/class_session.dart';
import 'session_controller.dart';
import '../../../core/utils/date_formatter.dart';

class SessionTab extends ConsumerStatefulWidget {
  final int classId;
  const SessionTab({super.key, required this.classId});

  @override
  ConsumerState<SessionTab> createState() => _SessionTabState();
}

class _SessionTabState extends ConsumerState<SessionTab> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));

  @override
  Widget build(BuildContext context) {
    final sessionsAsync = ref.watch(classSessionControllerProvider(widget.classId));

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Text('Từ: '),
              TextButton(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _startDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setState(() => _startDate = picked);
                },
                child: Text(DateFormat('dd/MM/yyyy').format(_startDate)),
              ),
              const Text(' - Đến: '),
              TextButton(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _endDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setState(() => _endDate = picked);
                },
                child: Text(DateFormat('dd/MM/yyyy').format(_endDate)),
              ),
            ],
          ),
        ),
      ),
      body: sessionsAsync.when(
        data: (allSessions) {
          final sessions = allSessions.where((s) {
            final date = DateTime.parse(s.ngay);
            final start = DateTime(_startDate.year, _startDate.month, _startDate.day);
            final end = DateTime(_endDate.year, _endDate.month, _endDate.day);
            return !date.isBefore(start) && !date.isAfter(end);
          }).toList();

          if (sessions.isEmpty) {
            return const Center(child: Text('Không có buổi học nào trong khoảng này.'));
          }
          return ListView.builder(
            itemCount: sessions.length,
            itemBuilder: (context, index) {
              final s = sessions[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getStatusColor(s.trangThai),
                  child: Text(
                    s.loai == SessionType.CHINH ? 'C' : 'B',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(
                  '${_formatDateWithWeekday(s.ngay)}: ${s.gioBatDau} - ${s.gioKetThuc}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Loại: ${_getTypeLabel(s.loai)} | Trạng thái: ${_getStatusLabel(s.trangThai)}',
                ),
                trailing: PopupMenuButton<SessionStatus>(
                  onSelected: (status) =>
                      _confirmStatusChange(context, ref, s, status),
                  itemBuilder: (context) => [
                    if (s.trangThai != SessionStatus.DU_KIEN)
                      const PopupMenuItem(
                        value: SessionStatus.DU_KIEN,
                        child: Text('Đánh dấu: DỰ KIẾN'),
                      ),
                    if (s.trangThai != SessionStatus.HUY)
                      const PopupMenuItem(
                        value: SessionStatus.HUY,
                        child: Text('Đánh dấu: HỦY'),
                      ),
                    if (s.trangThai != SessionStatus.NGHI_LE)
                      const PopupMenuItem(
                        value: SessionStatus.NGHI_LE,
                        child: Text('Đánh dấu: NGHỈ LỄ'),
                      ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'gen_sessions',
            onPressed: () => _showGenerateDialog(context, ref),
            tooltip: 'Sinh buổi học',
            child: const Icon(Icons.auto_awesome),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.small(
            heroTag: 'add_manual_session',
            onPressed: () => _showManualDialog(context, ref),
            tooltip: 'Thêm buổi học bù/phát sinh',
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }

  String _formatDateWithWeekday(String dateStr) {
    final date = DateTime.parse(dateStr);
    final weekday = DateFormatter.formatVietnameseWeekday(date.weekday);
    final formattedDate = DateFormat('dd/MM/yyyy').format(date);
    return '$weekday, $formattedDate';
  }

  String _getTypeLabel(SessionType type) {
    switch (type) {
      case SessionType.CHINH:
        return 'Chính thức';
      case SessionType.HOC_BU:
        return 'Học bù';
      case SessionType.PHAT_SINH:
        return 'Phát sinh';
    }
  }

  String _getStatusLabel(SessionStatus status) {
    switch (status) {
      case SessionStatus.DU_KIEN:
        return 'Dự kiến';
      case SessionStatus.DA_HOC:
        return 'Đã học';
      case SessionStatus.HUY:
        return 'Hủy';
      case SessionStatus.NGHI_LE:
        return 'Nghỉ lễ';
    }
  }

  Color _getStatusColor(SessionStatus status) {
    switch (status) {
      case SessionStatus.DU_KIEN:
        return Colors.blue;
      case SessionStatus.DA_HOC:
        return Colors.green;
      case SessionStatus.HUY:
        return Colors.red;
      case SessionStatus.NGHI_LE:
        return Colors.orange;
    }
  }

  void _confirmStatusChange(
    BuildContext context,
    WidgetRef ref,
    ClassSession session,
    SessionStatus status,
  ) async {
    final label = _getStatusLabel(status).toUpperCase();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận thay đổi'),
        content: Text('Bạn có chắc chắn muốn đánh dấu buổi học này là $label?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
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
      title: const Text('Sinh buổi học tự động'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Sinh các buổi học chính thức dựa trên lịch học định kỳ trong khoảng:',
          ),
          const SizedBox(height: 16),
          ListTile(
            title: const Text('Từ ngày'),
            subtitle: Text(DateFormat('dd/MM/yyyy').format(_fromDate)),
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
            title: const Text('Đến ngày'),
            subtitle: Text(DateFormat('dd/MM/yyyy').format(_toDate)),
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
            onPressed: _loading ? null : () => _submit(ref),
            child: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
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
            title: const Text('Kết quả sinh buổi học'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Đã tạo mới: ${result.createdCount}'),
                Text('Đã tồn tại: ${result.existingCount}'),
                if (result.conflictCount > 0)
                  Text(
                    'Xung đột: ${result.conflictCount}',
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                if (result.warnings.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Cảnh báo:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  ...result.warnings.map(
                    (w) => Text('• $w', style: const TextStyle(fontSize: 12)),
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
    return AlertDialog(
      title: const Text('Thêm buổi học thủ công'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<SessionType>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Loại buổi học'),
              items: const [
                DropdownMenuItem(
                  value: SessionType.HOC_BU,
                  child: Text('Học bù'),
                ),
                DropdownMenuItem(
                  value: SessionType.PHAT_SINH,
                  child: Text('Phát sinh'),
                ),
              ],
              onChanged: (v) => setState(() => _type = v!),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Ngày'),
              subtitle: Text(DateFormat('dd/MM/yyyy').format(_ngay)),
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
                    title: const Text('Bắt đầu'),
                    subtitle: Text(_start.format(context)),
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
                    title: const Text('Kết thúc'),
                    subtitle: Text(_end.format(context)),
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
              decoration: const InputDecoration(labelText: 'Ghi chú'),
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
            onPressed: _loading ? null : () => _submit(ref),
            child: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
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
