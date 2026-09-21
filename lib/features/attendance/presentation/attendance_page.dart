import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/date_formatter.dart';
import '../../roster/domain/roster_member.dart';
import '../../roster/domain/roster_result.dart';
import '../../session_adjustments/presentation/session_adjustment_controller.dart';
import '../../session_adjustments/presentation/session_adjustment_dialogs.dart';
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
              if (sheet.session.loai == SessionType.HOC_BU)
                TextButton.icon(
                  onPressed: () => ref
                      .read(attendanceControllerProvider(sessionId).notifier)
                      .markAllHocBu(),
                  icon: const Icon(Icons.done_all, color: Colors.white),
                  label: const Text(
                    'Học bù hết',
                    style: TextStyle(color: Colors.white),
                  ),
                )
              else
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
        !sheet.requiresOneOffAdjustments;
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
            child: Column(
              children: [
                const Row(
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
                if (sheet.rosterIssues.isNotEmpty)
                  ...sheet.rosterIssues.map(
                    (ri) => Padding(
                      padding: const EdgeInsets.only(top: 8.0, left: 36),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 14,
                            color: Colors.red,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              ri.message,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        if (sheet.rosterIssues.any(
          (ri) => ri.code == RosterIssueCode.UNASSIGNED_IN_MULTI_SHIFT,
        ))
          ...sheet.rosterIssues
              .where(
                (ri) => ri.code == RosterIssueCode.UNASSIGNED_IN_MULTI_SHIFT,
              )
              .map(
                (ri) => Container(
                  color: Colors.orange.shade50,
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.orange,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          ri.message,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
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
        if (sheet.session.loai == SessionType.PHAT_SINH &&
            sheet.session.trangThai == SessionStatus.DU_KIEN)
          Container(
            color: Colors.blue.shade50,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    sheet.members.isEmpty
                        ? 'Buổi học phát sinh chưa có danh sách tham gia.'
                        : 'Danh sách học sinh tham gia phát sinh',
                    style: TextStyle(
                      color: Colors.blue.shade900,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () =>
                      SessionAdjustmentDialogs.showThemPhatSinhDialog(
                        context,
                        ref,
                        targetSessionId: sessionId,
                        classId: sheet.session.idLop,
                      ),
                  icon: const Icon(Icons.person_add, size: 18),
                  label: const Text('Thêm học sinh'),
                ),
              ],
            ),
          ),
        if (sheet.session.loai == SessionType.HOC_BU &&
            sheet.requiresOneOffAdjustments)
          Container(
            color: Colors.blue.shade50,
            padding: const EdgeInsets.all(16),
            child: const Text(
              'Buổi học bù này chưa có danh sách học sinh tham gia.',
              textAlign: TextAlign.center,
            ),
          ),
        Expanded(
          child: sheet.members.isEmpty
              ? const Center(
                  child: Text('Chưa có học sinh nào trong danh sách.'),
                )
              : ListView.separated(
                  itemCount: sheet.members.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
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
    final effectiveState = ref.watch(
      attendanceControllerProvider(sessionId).select(
        (s) => ref
            .read(attendanceControllerProvider(sessionId).notifier)
            .effectiveStateFor(student.id!),
      ),
    );

    final isNormalChinh =
        member.rosterMember.source ==
            RosterInclusionSource.SINGLE_SHIFT_MEMBERSHIP ||
        member.rosterMember.source == RosterInclusionSource.EXPLICIT_ASSIGNMENT;

    final isMissedOriginal =
        member.state == AttendanceState.NGHI_CO_PHEP ||
        member.state == AttendanceState.NGHI_KHONG_PHEP;

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
              if (member.rosterMember.source == RosterInclusionSource.DOI_CA)
                const Card(
                  color: Colors.blue,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Text(
                      'Đổi ca',
                      style: TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ),
                ),
              if (member.rosterMember.source == RosterInclusionSource.HOC_BU)
                const Card(
                  color: Colors.teal,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Text(
                      'Học bù',
                      style: TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ),
                ),
              if (member.rosterMember.source == RosterInclusionSource.PHAT_SINH)
                const Card(
                  color: Colors.purple,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Text(
                      'Phát sinh',
                      style: TextStyle(color: Colors.white, fontSize: 11),
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
              if (isEditable &&
                  isNormalChinh &&
                  sheet.session.loai == SessionType.CHINH)
                TextButton(
                  onPressed: () => SessionAdjustmentDialogs.showDoiCaDialog(
                    context,
                    ref,
                    studentId: student.id!,
                    originalSessionId: sessionId,
                    classId: sheet.session.idLop,
                    sessionDate: sheet.session.ngay,
                  ),
                  child: const Text('Đổi ca', style: TextStyle(fontSize: 12)),
                ),
              if (isMissedOriginal && sheet.session.loai == SessionType.CHINH)
                TextButton(
                  onPressed: () => SessionAdjustmentDialogs.showXepHocBuDialog(
                    context,
                    ref,
                    studentId: student.id!,
                    originalSessionId: sessionId,
                    classId: sheet.session.idLop,
                  ),
                  child: const Text(
                    'Xếp học bù',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              if (member.rosterMember.adjustment != null &&
                  isEditable &&
                  member.persistedRecord == null)
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 20,
                    color: Colors.red,
                  ),
                  tooltip: 'Hủy điều chỉnh',
                  onPressed: () async {
                    try {
                      final adj = member.rosterMember.adjustment!;
                      await ref
                          .read(
                            sessionAdjustmentControllerProvider(
                              sessionId,
                            ).notifier,
                          )
                          .removeAdjustment(adj.id!, sessionId);
                      ref.invalidate(attendanceControllerProvider(sessionId));
                      if (adj.idBuoiHocGoc != null) {
                        ref.invalidate(
                          attendanceControllerProvider(adj.idBuoiHocGoc!),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) _showError(context, e.toString());
                    }
                  },
                ),
            ],
          ),
          if (member.suggestedState != null &&
              effectiveState == AttendanceState.CHUA_DIEM_DANH)
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.purple.shade200),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.event_available,
                    size: 16,
                    color: Colors.purple,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${member.suggestionReason}: Đề xuất ${member.suggestedState!.label}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.purple,
                      ),
                    ),
                  ),
                  if (isEditable)
                    TextButton(
                      style: TextButton.styleFrom(padding: EdgeInsets.zero),
                      onPressed: () {
                        ref
                            .read(
                              attendanceControllerProvider(sessionId).notifier,
                            )
                            .updateLocalDraft(
                              student.id!,
                              member.suggestedState!,
                            );
                      },
                      child: const Text(
                        'Áp dụng đề xuất',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          if (isEditable)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: AttendanceState.values
                    .where((s) {
                      if (member.rosterMember.source ==
                          RosterInclusionSource.HOC_BU) {
                        return s != AttendanceState.CO_MAT &&
                            s != AttendanceState.TRE;
                      } else {
                        return s != AttendanceState.HOC_BU;
                      }
                    })
                    .map(
                      (state) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(state.label),
                          selected: effectiveState == state,
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
    final hasDirtyDraft = ref.watch(
      attendanceControllerProvider(sessionId).select(
        (s) => ref
            .read(attendanceControllerProvider(sessionId).notifier)
            .hasDirtyDraft,
      ),
    );

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
              onPressed: hasDirtyDraft ? () => _handleSave(context, ref) : null,
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
      final unresolved = ref
          .read(attendanceControllerProvider(sessionId).notifier)
          .unresolvedCountFromDraft();

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
