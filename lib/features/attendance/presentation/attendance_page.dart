import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/date_formatter.dart';
import '../../sessions/domain/class_session.dart';
import '../domain/attendance_sheet.dart';
import '../domain/attendance_state.dart';
import 'attendance_controller.dart';

class AttendancePage extends ConsumerWidget {
  final int sessionId;

  const AttendancePage({super.key, required this.sessionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sheetAsync = ref.watch(attendanceControllerProvider(sessionId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Điểm danh'),
        actions: sheetAsync.when(
          data: (sheet) => [
            if (_isEditable(sheet)) ...[
              TextButton.icon(
                onPressed: () => ref
                    .read(attendanceControllerProvider(sessionId).notifier)
                    .markAllPresent(),
                icon: const Icon(Icons.done_all, color: Colors.white),
                label: const Text(
                  'Có mặt hết',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.undo),
                onPressed: () => ref
                    .read(attendanceControllerProvider(sessionId).notifier)
                    .undoChanges(),
                tooltip: 'Hoàn tác',
              ),
            ],
          ],
          loading: () => [],
          error: (_, __) => [],
        ),
      ),
      body: sheetAsync.when(
        data: (sheet) => _buildContent(context, ref, sheet),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(err.toString(), textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: sheetAsync.when(
        data: (sheet) =>
            _isEditable(sheet) ? _buildBottomBar(context, ref, sheet) : null,
        loading: () => null,
        error: (_, __) => null,
      ),
    );
  }

  bool _isEditable(AttendanceSheet sheet) {
    return sheet.isOperationallyValid &&
        sheet.session.trangThai == SessionStatus.DU_KIEN &&
        sheet.session.loai == SessionType.CHINH;
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    AttendanceSheet sheet,
  ) {
    return Column(
      children: [
        _buildSessionHeader(context, sheet),
        if (!sheet.isRosterValid)
          Container(
            color: Colors.red.shade50,
            padding: const EdgeInsets.all(16),
            child: const Row(
              children: [
                Icon(Icons.warning, color: Colors.red),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Danh sách lớp (Roster) hiện tại không hợp lệ. Vui lòng kiểm tra lại cấu hình lịch học hoặc phân ca.',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (sheet.issues.isNotEmpty)
          ...sheet.issues.map(
            (issue) => Container(
              color: Colors.orange.shade50,
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.report_problem, color: Colors.orange),
                  const SizedBox(width: 12),
                  Expanded(child: Text(issue.message)),
                ],
              ),
            ),
          ),
        if (sheet.session.trangThai == SessionStatus.HUY ||
            sheet.session.trangThai == SessionStatus.NGHI_LE)
          Container(
            color: Colors.grey.shade200,
            padding: const EdgeInsets.all(16),
            child: Text(
              'Buổi học đang ở trạng thái ${sheet.session.trangThai.name}. Không thể chỉnh sửa điểm danh.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
          ),
        if (sheet.session.loai != SessionType.CHINH)
          Container(
            color: Colors.blue.shade50,
            padding: const EdgeInsets.all(16),
            child: const Text(
              'Danh sách người tham gia buổi học bù/phát sinh cần được xác định ở Phase 7.',
              textAlign: TextAlign.center,
            ),
          ),
        Expanded(
          child: ListView.separated(
            itemCount: sheet.members.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final member = sheet.members[index];
              return _buildStudentRow(context, ref, sheet, member);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSessionHeader(BuildContext context, AttendanceSheet sheet) {
    final session = sheet.session;
    final date = DateTime.parse(session.ngay);
    final weekday = DateFormatter.formatVietnameseWeekday(date.weekday);

    return Container(
      width: double.infinity,
      color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$weekday, ${session.ngay}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            '${session.gioBatDau} - ${session.gioKetThuc} | ${session.loai.name}',
            style: TextStyle(color: Colors.grey.shade700),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildStatChip('Tổng: ${sheet.members.length}', Colors.blue),
              const SizedBox(width: 8),
              _buildStatChip(
                'Chưa điểm danh: ${sheet.unresolvedCount}',
                sheet.unresolvedCount > 0 ? Colors.orange : Colors.green,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStudentRow(
    BuildContext context,
    WidgetRef ref,
    AttendanceSheet sheet,
    AttendanceSheetMember member,
  ) {
    final student = member.rosterMember.student;
    final isEditable = _isEditable(sheet);
    final draftState =
        ref.watch(
          attendanceControllerProvider(sessionId).select(
            (s) => ref
                .read(attendanceControllerProvider(sessionId).notifier)
                .draft[student.id],
          ),
        ) ??
        member.state;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  student.hoTen,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (student.daLuuTru)
                const Card(
                  color: Colors.grey,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Text(
                      'Lưu trữ',
                      style: TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (isEditable)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: AttendanceState.values
                    .where((s) => s != AttendanceState.HOC_BU)
                    .map(
                      (state) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(state.label),
                          selected: draftState == state,
                          onSelected: (selected) {
                            if (selected) {
                              ref
                                  .read(
                                    attendanceControllerProvider(
                                      sessionId,
                                    ).notifier,
                                  )
                                  .updateLocalDraft(student.id!, state);
                            }
                          },
                        ),
                      ),
                    )
                    .toList(),
              ),
            )
          else
            Text(
              'Trạng thái: ${member.state.label}',
              style: TextStyle(
                color: _getStateColor(member.state),
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }

  Color _getStateColor(AttendanceState state) {
    switch (state) {
      case AttendanceState.CHUA_DIEM_DANH:
        return Colors.orange;
      case AttendanceState.CO_MAT:
        return Colors.green;
      case AttendanceState.TRE:
        return Colors.blue;
      case AttendanceState.NGHI_CO_PHEP:
        return Colors.purple;
      case AttendanceState.NGHI_KHONG_PHEP:
        return Colors.red;
      case AttendanceState.HOC_BU:
        return Colors.teal;
    }
  }

  Widget _buildBottomBar(
    BuildContext context,
    WidgetRef ref,
    AttendanceSheet sheet,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => _handleSave(context, ref),
              child: const Text('Lưu nháp'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: () => _handleFinalize(context, ref, sheet),
              child: const Text('Hoàn tất'),
            ),
          ),
        ],
      ),
    );
  }

  void _handleSave(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(attendanceControllerProvider(sessionId).notifier).save();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã lưu dữ liệu điểm danh')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        _showError(context, e.toString());
      }
    }
  }

  void _handleFinalize(
    BuildContext context,
    WidgetRef ref,
    AttendanceSheet sheet,
  ) async {
    try {
      // Check incomplete
      final currentDraft = ref
          .read(attendanceControllerProvider(sessionId).notifier)
          .draft;
      final unresolved = currentDraft.values
          .where((v) => v == AttendanceState.CHUA_DIEM_DANH)
          .length;

      if (unresolved > 0) {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Chưa điểm danh hết'),
            content: Text(
              'Vẫn còn $unresolved học sinh chưa được đánh dấu. Bạn có chắc chắn muốn hoàn tất?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Hủy'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Vẫn hoàn tất'),
              ),
            ],
          ),
        );
        if (confirm != true) return;
      } else {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Hoàn tất buổi học'),
            content: const Text(
              'Sau khi hoàn tất, buổi học sẽ chuyển sang trạng thái ĐÃ HỌC. Bạn có chắc chắn?',
            ),
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
        if (confirm != true) return;
      }

      await ref
          .read(attendanceControllerProvider(sessionId).notifier)
          .finalize(allowIncomplete: true);

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đã hoàn tất buổi học')));
      }
    } catch (e) {
      if (context.mounted) {
        _showError(context, e.toString());
      }
    }
  }

  void _showError(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lỗi'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }
}
