import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/common_widgets/app_feedback.dart';
import '../../../app/common_widgets/navy_components.dart';
import '../../../app/common_widgets/student_avatar.dart';
import '../../../app/design_system/app_theme.dart';
import '../../../app/navigation/app_global_drawer.dart';
import '../../../core/utils/date_formatter.dart';
import '../../roster/domain/roster_member.dart';
import '../../roster/domain/roster_result.dart';
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
      backgroundColor: AppColors.background,
      drawer: const AppGlobalDrawer(),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: const BackButton(),
        title: const Text('Điểm danh buổi học'),
        actions: [
          const GlobalMenuButton(),
          ...sheetAsync.when(
            data: (sheet) => [
              if (_isEditable(sheet)) ...[
                if (sheet.session.loai == SessionType.HOC_BU)
                  TextButton.icon(
                    onPressed: () => ref
                        .read(attendanceControllerProvider(sessionId).notifier)
                        .markAllHocBu(),
                    icon: const Icon(
                      Icons.done_all,
                      color: AppColors.cyanAccent,
                      size: 18,
                    ),
                    label: const Text(
                      'Học bù hết',
                      style: TextStyle(
                        color: AppColors.cyanAccent,
                        fontSize: 13,
                      ),
                    ),
                  )
                else
                  TextButton.icon(
                    onPressed: () => ref
                        .read(attendanceControllerProvider(sessionId).notifier)
                        .markAllPresent(),
                    icon: const Icon(
                      Icons.done_all,
                      color: AppColors.cyanAccent,
                      size: 18,
                    ),
                    label: const Text(
                      'Có mặt hết',
                      style: TextStyle(
                        color: AppColors.cyanAccent,
                        fontSize: 13,
                      ),
                    ),
                  ),
                IconButton(
                  icon: const Icon(Icons.undo, color: AppColors.textSecondary),
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
        ],
      ),
      body: sheetAsync.when(
        data: (sheet) => _buildContent(context, ref, sheet),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 48,
                  color: AppColors.error,
                ),
                const SizedBox(height: 16),
                Text(
                  err.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textPrimary),
                ),
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
        _buildSessionHeader(context, ref, sheet),
        if (!sheet.isRosterValid)
          Container(
            color: AppColors.error.withValues(alpha: 0.15),
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: AppColors.error),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Danh sách lớp (Roster) hiện tại không hợp lệ. Vui lòng kiểm tra lại cấu hình lịch học hoặc phân ca.',
                        style: TextStyle(
                          color: AppColors.error,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
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
                            color: AppColors.error,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              ri.message,
                              style: const TextStyle(
                                color: AppColors.error,
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
                  color: AppColors.warning.withValues(alpha: 0.15),
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          ri.message,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        if (sheet.issues.isNotEmpty)
          ...sheet.issues.map(
            (issue) => Container(
              color: AppColors.warning.withValues(alpha: 0.15),
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.report_problem, color: AppColors.warning),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      issue.message,
                      style: const TextStyle(color: AppColors.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (sheet.session.trangThai == SessionStatus.HUY ||
            sheet.session.trangThai == SessionStatus.NGHI_LE)
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.all(14),
            child: Text(
              'Buổi học đang ở trạng thái ${sheet.session.trangThai.name}. Không thể chỉnh sửa điểm danh.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        Expanded(
          child: sheet.members.isEmpty
              ? const Center(
                  child: Text(
                    'Chưa có học sinh nào trong danh sách điểm danh.',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: sheet.members.length,
                  itemBuilder: (context, index) {
                    final member = sheet.members[index];
                    return _buildStudentRow(context, ref, sheet, member);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSessionHeader(
    BuildContext context,
    WidgetRef ref,
    AttendanceSheet sheet,
  ) {
    final session = sheet.session;
    final date = DateTime.parse(session.ngay);
    final weekday = DateFormatter.formatVietnameseWeekday(date.weekday);

    int coMat = 0;
    int tre = 0;
    int nghiCoPhep = 0;
    int nghiKhongPhep = 0;
    int chuaDiemDanh = 0;

    for (final m in sheet.members) {
      final state = ref.watch(
        attendanceControllerProvider(sessionId).select(
          (s) => ref
              .read(attendanceControllerProvider(sessionId).notifier)
              .effectiveStateFor(m.rosterMember.student.id!),
        ),
      );

      switch (state) {
        case AttendanceState.CO_MAT:
          coMat++;
          break;
        case AttendanceState.TRE:
          tre++;
          break;
        case AttendanceState.NGHI_CO_PHEP:
          nghiCoPhep++;
          break;
        case AttendanceState.NGHI_KHONG_PHEP:
          nghiKhongPhep++;
          break;
        case AttendanceState.HOC_BU:
          coMat++;
          break;
        case AttendanceState.CHUA_DIEM_DANH:
          chuaDiemDanh++;
          break;
      }
    }

    return AppSectionCard(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$weekday, ${DateFormatter.formatDisplayDate(session.ngay)}',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              AppStatusChip(
                label: session.loai.displayName,
                color: AppColors.cyanAccent,
                compact: true,
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'Giờ học: ${session.gioBatDau} - ${session.gioKetThuc}',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 10),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildMetricBadge(
                  'Tổng: ${sheet.members.length}',
                  AppColors.primary,
                ),
                const SizedBox(width: 6),
                _buildMetricBadge('Có mặt: $coMat', AppColors.success),
                const SizedBox(width: 6),
                _buildMetricBadge('Trễ: $tre', AppColors.warning),
                const SizedBox(width: 6),
                _buildMetricBadge('Có phép: $nghiCoPhep', AppColors.cyanAccent),
                const SizedBox(width: 6),
                _buildMetricBadge(
                  'Không phép: $nghiKhongPhep',
                  AppColors.error,
                ),
                if (chuaDiemDanh > 0) ...[
                  const SizedBox(width: 6),
                  _buildMetricBadge(
                    'Chưa điểm danh: $chuaDiemDanh',
                    AppColors.warning,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
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

    return AppSectionCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StudentAvatar(
                gioiTinh: student.gioiTinh,
                studentName: student.hoTen,
                radius: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  student.hoTen,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (member.rosterMember.source == RosterInclusionSource.DOI_CA)
                const AppStatusChip(
                  label: 'Đổi ca',
                  color: AppColors.primary,
                  compact: true,
                ),
              if (member.rosterMember.source == RosterInclusionSource.HOC_BU)
                const AppStatusChip(
                  label: 'Học bù',
                  color: AppColors.cyanAccent,
                  compact: true,
                ),
              if (member.rosterMember.source == RosterInclusionSource.PHAT_SINH)
                const AppStatusChip(
                  label: 'Phát sinh',
                  color: AppColors.warning,
                  compact: true,
                ),
            ],
          ),
          const SizedBox(height: 10),
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
                    .map((state) {
                      final isSelected = effectiveState == state;
                      Color color;
                      switch (state) {
                        case AttendanceState.CO_MAT:
                          color = AppColors.success;
                          break;
                        case AttendanceState.TRE:
                          color = AppColors.warning;
                          break;
                        case AttendanceState.NGHI_CO_PHEP:
                          color = AppColors.cyanAccent;
                          break;
                        case AttendanceState.NGHI_KHONG_PHEP:
                          color = AppColors.error;
                          break;
                        case AttendanceState.HOC_BU:
                          color = AppColors.primary;
                          break;
                        case AttendanceState.CHUA_DIEM_DANH:
                          color = AppColors.textMuted;
                          break;
                      }

                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(state.label),
                          selected: isSelected,
                          selectedColor: color,
                          backgroundColor: AppColors.surfaceHigh,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
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
                      );
                    })
                    .toList(),
              ),
            )
          else
            AppStatusChip(
              label: member.state.label,
              color: _getStateColor(member.state),
            ),
        ],
      ),
    );
  }

  Color _getStateColor(AttendanceState state) {
    switch (state) {
      case AttendanceState.CHUA_DIEM_DANH:
        return AppColors.textMuted;
      case AttendanceState.CO_MAT:
        return AppColors.success;
      case AttendanceState.TRE:
        return AppColors.warning;
      case AttendanceState.NGHI_CO_PHEP:
        return AppColors.cyanAccent;
      case AttendanceState.NGHI_KHONG_PHEP:
        return AppColors.error;
      case AttendanceState.HOC_BU:
        return AppColors.primary;
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
      padding: const EdgeInsets.all(14),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.border),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: hasDirtyDraft ? () => _handleSave(context, ref) : null,
              child: const Text(
                'Lưu nháp',
                style: TextStyle(color: AppColors.cyanAccent),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () => _handleFinalize(context, ref, sheet),
              child: const Text('Hoàn tất buổi học'),
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
        AppFeedback.showSuccessSnackBar(context, 'Đã lưu dữ liệu điểm danh');
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

  void _handleFinalize(
    BuildContext context,
    WidgetRef ref,
    AttendanceSheet sheet,
  ) async {
    try {
      final unresolved = ref
          .read(attendanceControllerProvider(sessionId).notifier)
          .unresolvedCountFromDraft();

      if (unresolved > 0) {
        final confirm = await AppFeedback.showConfirmBottomSheet(
          context,
          title: 'Chưa điểm danh hết',
          message:
              'Vẫn còn $unresolved học sinh chưa được đánh dấu. Bạn có chắc chắn muốn hoàn tất?',
          confirmLabel: 'Vẫn hoàn tất',
          isDestructive: false,
        );
        if (confirm != true) return;
      } else {
        final confirm = await AppFeedback.showConfirmBottomSheet(
          context,
          title: 'Hoàn tất buổi học',
          message:
              'Sau khi hoàn tất, buổi học sẽ chuyển sang trạng thái ĐÃ HỌC. Bạn có chắc chắn?',
          confirmLabel: 'Xác nhận hoàn tất',
          isDestructive: false,
        );
        if (confirm != true) return;
      }

      await ref
          .read(attendanceControllerProvider(sessionId).notifier)
          .finalize(allowIncomplete: true);

      if (context.mounted) {
        AppFeedback.showSuccessSnackBar(context, 'Đã hoàn tất buổi học');
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
