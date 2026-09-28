import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/common_widgets/app_feedback.dart';
import '../../../app/common_widgets/navy_components.dart';
import '../../../app/common_widgets/student_avatar.dart';
import '../../../app/design_system/app_theme.dart';
import '../../../app/localization/app_formatter.dart';
import '../../../app/navigation/app_global_drawer.dart';
import '../../../l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import '../../roster/domain/roster_member.dart';
import '../../session_adjustments/presentation/session_adjustment_controller.dart';
import '../../session_adjustments/presentation/session_adjustment_dialogs.dart';
import '../../sessions/domain/class_session.dart';
import '../../tuition/presentation/tuition_controller.dart';
import '../domain/attendance_record.dart';
import '../domain/attendance_sheet.dart';
import '../domain/attendance_state.dart';
import 'attendance_controller.dart';
import 'session_correction_audits_controller.dart';

class AttendancePage extends ConsumerStatefulWidget {
  final int sessionId;

  const AttendancePage({super.key, required this.sessionId});

  @override
  ConsumerState<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends ConsumerState<AttendancePage> {
  bool _isCorrectionMode = false;
  String _correctionReason = '';

  bool _canEditRosterStructure(AttendanceSheet sheet) {
    return sheet.isOperationallyValid &&
        sheet.session.trangThai == SessionStatus.DU_KIEN;
  }

  bool _canEditAttendanceState(AttendanceSheet sheet) {
    if (!sheet.isOperationallyValid) return false;
    if (sheet.session.trangThai == SessionStatus.DU_KIEN) return true;
    if (sheet.session.trangThai == SessionStatus.DA_HOC && _isCorrectionMode) {
      return true;
    }
    return false;
  }

  bool _hasDirtyDraft() {
    return ref
        .read(attendanceControllerProvider(widget.sessionId).notifier)
        .hasDirtyDraft;
  }

  void _showDirtyDraftDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Có thay đổi chưa lưu',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          'Danh sách học sinh sắp thay đổi. Vui lòng Lưu nháp hoặc Hoàn tác trước khi tiếp tục.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  bool _ensureDraftClean() {
    if (_hasDirtyDraft()) {
      _showDirtyDraftDialog();
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final sheetAsync = ref.watch(
      attendanceControllerProvider(widget.sessionId),
    );
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const AppGlobalDrawer(),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: const BackButton(),
        title: Text(l10n?.attendanceTitle ?? 'Điểm danh buổi học'),
        actions: [
          const GlobalMenuButton(),
          ...sheetAsync.when(
            data: (sheet) => [
              if (sheet.session.trangThai == SessionStatus.DA_HOC)
                IconButton(
                  icon: const Icon(Icons.history, color: AppColors.cyanAccent),
                  tooltip: 'Lịch sử chỉnh sửa',
                  onPressed: () => _showCorrectionHistoryBottomSheet(sheet),
                ),
              if (_canEditAttendanceState(sheet)) ...[
                if (sheet.session.loai == SessionType.HOC_BU)
                  TextButton.icon(
                    onPressed: () => ref
                        .read(
                          attendanceControllerProvider(
                            widget.sessionId,
                          ).notifier,
                        )
                        .markAllHocBu(),
                    icon: const Icon(
                      Icons.done_all,
                      color: AppColors.cyanAccent,
                      size: 18,
                    ),
                    label: Text(
                      l10n?.attendanceMarkAllMakeup ?? 'Học bù hết',
                      style: const TextStyle(
                        color: AppColors.cyanAccent,
                        fontSize: 13,
                      ),
                    ),
                  )
                else
                  TextButton.icon(
                    onPressed: () => ref
                        .read(
                          attendanceControllerProvider(
                            widget.sessionId,
                          ).notifier,
                        )
                        .markAllPresent(),
                    icon: const Icon(
                      Icons.done_all,
                      color: AppColors.cyanAccent,
                      size: 18,
                    ),
                    label: Text(
                      l10n?.attendanceMarkAllPresent ?? 'Có mặt hết',
                      style: const TextStyle(
                        color: AppColors.cyanAccent,
                        fontSize: 13,
                      ),
                    ),
                  ),
                IconButton(
                  icon: const Icon(Icons.undo, color: AppColors.textSecondary),
                  onPressed: () => ref
                      .read(
                        attendanceControllerProvider(widget.sessionId).notifier,
                      )
                      .undoChanges(),
                  tooltip: l10n?.attendanceUndo ?? 'Hoàn tác',
                ),
              ],
            ],
            loading: () => [],
            error: (_, __) => [],
          ),
        ],
      ),
      body: sheetAsync.when(
        data: (sheet) => _buildContent(sheet),
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
        data: (sheet) => _buildBottomBar(sheet),
        loading: () => null,
        error: (_, __) => null,
      ),
    );
  }

  Widget _buildContent(AttendanceSheet sheet) {
    final l10n = AppLocalizations.of(context);

    return Column(
      children: [
        _buildSessionHeader(sheet),

        _buildStatusMessageBanner(sheet),

        if (sheet.session.loai == SessionType.PHAT_SINH &&
            _canEditRosterStructure(sheet))
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.person_add_alt_1_outlined,
                  color: AppColors.cyanAccent,
                  size: 20,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Buổi học phát sinh',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                  ),
                  onPressed: () {
                    if (!_ensureDraftClean()) return;
                    SessionAdjustmentDialogs.showPhatSinhDialog(
                      context: context,
                      ref: ref,
                      targetSessionId: widget.sessionId,
                    );
                  },
                  icon: const Icon(Icons.person_add, size: 16),
                  label: Text(
                    l10n?.attendanceAddStudent ?? 'Thêm học sinh',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

        if (sheet.session.loai == SessionType.HOC_BU &&
            sheet.requiresOneOffAdjustments)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.warning.withValues(alpha: 0.3),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.warning, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Buổi học bù theo ca riêng: Quản lý học sinh tham gia bằng cách xếp học bù từ buổi gốc.',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),

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

        Expanded(
          child: sheet.members.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.rule_folder_outlined,
                          size: 48,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          sheet.session.loai == SessionType.HOC_BU
                              ? 'Buổi học bù: chưa có học sinh được xếp học bù vào buổi này.'
                              : sheet.session.loai == SessionType.PHAT_SINH
                              ? 'Buổi học phát sinh: chưa có danh sách tham gia. Bấm "Thêm học sinh" để thêm vào danh sách.'
                              : 'Chưa có học sinh nào trong danh sách điểm danh.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
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
                    return _buildStudentRow(sheet, member);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildStatusMessageBanner(AttendanceSheet sheet) {
    final isEditable = sheet.session.trangThai == SessionStatus.DU_KIEN;
    final isFinalized = sheet.session.trangThai == SessionStatus.DA_HOC;

    if (isEditable) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.cyanAccent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          children: [
            Icon(Icons.edit_note, color: AppColors.cyanAccent, size: 16),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Chưa hoàn tất buổi học • Đang dùng bản nháp điểm danh',
                style: TextStyle(
                  color: AppColors.cyanAccent,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    } else if (isFinalized) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _isCorrectionMode
              ? AppColors.warning.withValues(alpha: 0.12)
              : AppColors.success.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              _isCorrectionMode
                  ? Icons.edit_attributes
                  : Icons.check_circle_outline,
              color: _isCorrectionMode ? AppColors.warning : AppColors.success,
              size: 16,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _isCorrectionMode
                    ? 'Chế độ sửa điểm danh đã hoàn tất (Cần nhập lý do)'
                    : 'Đã hoàn tất buổi học (ĐÃ HỌC)',
                style: TextStyle(
                  color: _isCorrectionMode
                      ? AppColors.warning
                      : AppColors.success,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildSessionHeader(AttendanceSheet sheet) {
    final session = sheet.session;
    final date = DateTime.parse(session.ngay);
    final weekday = AppFormatter.formatWeekday(date.weekday, context: context);

    int coMat = 0;
    int tre = 0;
    int nghiCoPhep = 0;
    int nghiKhongPhep = 0;
    int chuaDiemDanh = 0;

    for (final m in sheet.members) {
      final state = ref.watch(
        attendanceControllerProvider(widget.sessionId).select(
          (s) => ref
              .read(attendanceControllerProvider(widget.sessionId).notifier)
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
              Expanded(
                child: Text(
                  '$weekday, ${AppFormatter.formatDate(date, context: context)}',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
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
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _buildMetricBadge(
                'Tổng: ${sheet.members.length}',
                AppColors.primary,
              ),
              _buildMetricBadge('Có mặt: $coMat', AppColors.success),
              _buildMetricBadge('Trễ: $tre', AppColors.warning),
              _buildMetricBadge('Có phép: $nghiCoPhep', AppColors.cyanAccent),
              _buildMetricBadge('Không phép: $nghiKhongPhep', AppColors.error),
              if (chuaDiemDanh > 0)
                _buildMetricBadge(
                  'Chưa điểm danh: $chuaDiemDanh',
                  AppColors.warning,
                ),
            ],
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

  Widget _buildStudentRow(AttendanceSheet sheet, AttendanceSheetMember member) {
    final student = member.rosterMember.student;
    final isEditable = _canEditAttendanceState(sheet);
    final canEditRoster = _canEditRosterStructure(sheet);

    final effectiveState = ref.watch(
      attendanceControllerProvider(widget.sessionId).select(
        (s) => ref
            .read(attendanceControllerProvider(widget.sessionId).notifier)
            .effectiveStateFor(student.id!),
      ),
    );

    final isNormalChinh =
        member.rosterMember.source ==
            RosterInclusionSource.SINGLE_SHIFT_MEMBERSHIP ||
        member.rosterMember.source == RosterInclusionSource.EXPLICIT_ASSIGNMENT;

    final isMissedOriginal =
        sheet.session.loai == SessionType.CHINH &&
        sheet.session.trangThai == SessionStatus.DA_HOC &&
        (member.state == AttendanceState.NGHI_CO_PHEP ||
            member.state == AttendanceState.NGHI_KHONG_PHEP);

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
                      if (sheet.session.trangThai == SessionStatus.DA_HOC &&
                          s == AttendanceState.CHUA_DIEM_DANH) {
                        return false; // Forbidden in correction mode
                      }
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
                                      widget.sessionId,
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

          if (member.suggestedState != null &&
              effectiveState == AttendanceState.CHUA_DIEM_DANH)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.cyanAccent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${member.suggestionReason ?? "Đơn nghỉ đã duyệt"}: '
                      'Đề xuất ${member.suggestedState!.label}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  if (isEditable)
                    TextButton(
                      onPressed: () {
                        ref
                            .read(
                              attendanceControllerProvider(
                                widget.sessionId,
                              ).notifier,
                            )
                            .updateLocalDraft(
                              student.id!,
                              member.suggestedState!,
                            );
                      },
                      child: const Text('Áp dụng'),
                    ),
                ],
              ),
            ),

          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (canEditRoster &&
                  isNormalChinh &&
                  sheet.session.loai == SessionType.CHINH &&
                  member.persistedRecord == null)
                TextButton.icon(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                  ),
                  onPressed: () {
                    if (!_ensureDraftClean()) return;
                    SessionAdjustmentDialogs.showDoiCaDialog(
                      context: context,
                      ref: ref,
                      studentId: student.id!,
                      originalSessionId: widget.sessionId,
                    );
                  },
                  icon: const Icon(
                    Icons.swap_horiz,
                    size: 14,
                    color: AppColors.primary,
                  ),
                  label: const Text(
                    'Đổi ca',
                    style: TextStyle(color: AppColors.primary, fontSize: 11),
                  ),
                ),
              if (isMissedOriginal && !_isCorrectionMode)
                TextButton.icon(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                  ),
                  onPressed: () {
                    if (!_ensureDraftClean()) return;
                    SessionAdjustmentDialogs.showHocBuDialog(
                      context: context,
                      ref: ref,
                      studentId: student.id!,
                      originalSessionId: widget.sessionId,
                    );
                  },
                  icon: const Icon(
                    Icons.event_repeat,
                    size: 14,
                    color: AppColors.cyanAccent,
                  ),
                  label: const Text(
                    'Xếp học bù',
                    style: TextStyle(color: AppColors.cyanAccent, fontSize: 11),
                  ),
                ),
              if (member.rosterMember.adjustment != null &&
                  canEditRoster &&
                  member.persistedRecord == null)
                TextButton.icon(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                  ),
                  onPressed: () async {
                    if (!_ensureDraftClean()) return;
                    final adj = member.rosterMember.adjustment!;
                    final confirm = await AppFeedback.showConfirmBottomSheet(
                      context,
                      title: 'Hủy điều chỉnh',
                      message:
                          'Bạn có chắc chắn muốn hủy bỏ điều chỉnh cho học sinh ${student.hoTen}?',
                      confirmLabel: 'Xác nhận hủy',
                      isDestructive: true,
                    );
                    if (confirm == true) {
                      try {
                        await ref
                            .read(
                              sessionAdjustmentControllerProvider(
                                widget.sessionId,
                              ).notifier,
                            )
                            .removeAdjustment(adj.id!, widget.sessionId);

                        ref.invalidate(
                          attendanceControllerProvider(widget.sessionId),
                        );

                        if (adj.idBuoiHocGoc != null) {
                          ref.invalidate(
                            attendanceControllerProvider(adj.idBuoiHocGoc!),
                          );
                        }

                        if (mounted) {
                          AppFeedback.showSuccessSnackBar(
                            context,
                            'Đã hủy điều chỉnh',
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          AppFeedback.showErrorSnackBar(
                            context,
                            e.toString().replaceAll('Exception: ', ''),
                          );
                        }
                      }
                    }
                  },
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 14,
                    color: AppColors.error,
                  ),
                  label: const Text(
                    'Hủy điều chỉnh',
                    style: TextStyle(color: AppColors.error, fontSize: 11),
                  ),
                ),
            ],
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

  Widget? _buildBottomBar(AttendanceSheet sheet) {
    final l10n = AppLocalizations.of(context);
    final isFinalized = sheet.session.trangThai == SessionStatus.DA_HOC;

    if (isFinalized) {
      if (!_isCorrectionMode) {
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.border, width: 1)),
          ),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warning,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () => _enterCorrectionModeDialog(sheet),
              icon: const Icon(Icons.edit_note, size: 18),
              label: const Text(
                'Sửa điểm danh',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ),
        );
      } else {
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
                  onPressed: () {
                    ref
                        .read(
                          attendanceControllerProvider(
                            widget.sessionId,
                          ).notifier,
                        )
                        .undoChanges();
                    setState(() {
                      _isCorrectionMode = false;
                      _correctionReason = '';
                    });
                  },
                  child: const Text(
                    'Hủy thay đổi',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => _handleSaveCorrection(sheet),
                  icon: const Icon(Icons.save, size: 18),
                  label: const Text(
                    'Lưu chỉnh sửa',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        );
      }
    }

    if (!_canEditRosterStructure(sheet)) return null;

    final hasDirtyDraft = ref.watch(
      attendanceControllerProvider(widget.sessionId).select(
        (s) => ref
            .read(attendanceControllerProvider(widget.sessionId).notifier)
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
                side: BorderSide(
                  color: hasDirtyDraft
                      ? AppColors.cyanAccent
                      : AppColors.border,
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: hasDirtyDraft ? () => _handleSave() : null,
              child: Text(
                l10n?.attendanceDraftSave ?? 'Lưu nháp',
                style: TextStyle(
                  color: hasDirtyDraft
                      ? AppColors.cyanAccent
                      : AppColors.textMuted,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () => _handleFinalize(sheet),
              icon: const Icon(Icons.check_circle_outline, size: 18),
              label: Text(
                l10n?.attendanceFinalizeSession ?? 'Hoàn tất buổi học',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _enterCorrectionModeDialog(AttendanceSheet sheet) {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            top: 20,
            left: 16,
            right: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.edit_note, color: AppColors.warning, size: 24),
                  SizedBox(width: 10),
                  Text(
                    'Sửa điểm danh đã hoàn tất',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Buổi học này đã được hoàn tất.\n'
                'Việc thay đổi điểm danh có thể ảnh hưởng đến học phí, buổi dư và báo cáo.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Lý do sửa *',
                  hintText: 'Nhập nhầm trạng thái học sinh...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Hủy'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.warning,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      final reason = controller.text.trim();
                      if (reason.isEmpty) {
                        AppFeedback.showErrorSnackBar(
                          ctx,
                          'Vui lòng nhập lý do chỉnh sửa.',
                        );
                        return;
                      }
                      Navigator.pop(ctx);
                      setState(() {
                        _correctionReason = reason;
                        _isCorrectionMode = true;
                      });
                    },
                    child: const Text('Bắt đầu chỉnh sửa'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCorrectionHistoryBottomSheet(AttendanceSheet sheet) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Consumer(
              builder: (context, ref, _) {
                final auditsAsync = ref.watch(
                  sessionCorrectionAuditsProvider(widget.sessionId),
                );

                return Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.history,
                            color: AppColors.cyanAccent,
                            size: 24,
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'Lịch sử chỉnh sửa điểm danh',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const Divider(color: AppColors.border),
                      Expanded(
                        child: auditsAsync.when(
                          data: (audits) {
                            if (audits.isEmpty) {
                              return const Center(
                                child: Text(
                                  'Chưa có lịch sử chỉnh sửa điểm danh nào.',
                                  style: TextStyle(
                                    color: AppColors.textMuted,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              );
                            }

                            return ListView.separated(
                              controller: scrollController,
                              itemCount: audits.length,
                              separatorBuilder: (_, __) => const Divider(
                                color: AppColors.border,
                                height: 1,
                              ),
                              itemBuilder: (ctx, idx) {
                                final audit = audits[idx];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            audit.studentName ??
                                                'Học sinh #${audit.idHocSinh}',
                                            style: const TextStyle(
                                              color: AppColors.textPrimary,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                          Text(
                                            DateFormat(
                                              'dd/MM/yyyy HH:mm',
                                            ).format(audit.changedAt),
                                            style: const TextStyle(
                                              color: AppColors.textMuted,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          AppStatusChip(
                                            label: AttendanceState.fromStatus(
                                              _parseStatus(audit.trangThaiCu),
                                            ).label,
                                            color: AppColors.textMuted,
                                            compact: true,
                                          ),
                                          const Padding(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 8,
                                            ),
                                            child: Icon(
                                              Icons.arrow_forward,
                                              size: 14,
                                              color: AppColors.cyanAccent,
                                            ),
                                          ),
                                          AppStatusChip(
                                            label: AttendanceState.fromStatus(
                                              _parseStatus(audit.trangThaiMoi),
                                            ).label,
                                            color: AppColors.success,
                                            compact: true,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Lý do: ${audit.lyDo}',
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                          loading: () => const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                          ),
                          error: (err, _) => Center(
                            child: Text(
                              'Lỗi: $err',
                              style: const TextStyle(color: AppColors.error),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  AttendanceStatus? _parseStatus(String? str) {
    if (str == null) return null;
    try {
      return AttendanceStatus.values.byName(str);
    } catch (_) {
      return null;
    }
  }

  void _handleSave() async {
    try {
      await ref
          .read(attendanceControllerProvider(widget.sessionId).notifier)
          .save();
      if (mounted) {
        AppFeedback.showSuccessSnackBar(context, 'Đã lưu dữ liệu điểm danh');
      }
    } catch (e) {
      if (mounted) {
        AppFeedback.showErrorSnackBar(
          context,
          e.toString().replaceAll('Exception: ', ''),
        );
      }
    }
  }

  void _handleSaveCorrection(AttendanceSheet sheet) async {
    try {
      await ref
          .read(attendanceControllerProvider(widget.sessionId).notifier)
          .saveCorrection(_correctionReason);

      final classId = sheet.session.idLop;
      final month = sheet.session.ngay.substring(0, 7);

      final overview = await ref.read(
        classMonthTuitionOverviewProvider((classId, month)).future,
      );

      final isFinalized = overview.finalizedStudentCount > 0;
      final hasPayments = overview.totalPaid > 0;

      setState(() {
        _isCorrectionMode = false;
        _correctionReason = '';
      });

      if (mounted) {
        AppFeedback.showSuccessSnackBar(
          context,
          'Đã cập nhật chỉnh sửa điểm danh',
        );

        if (isFinalized) {
          if (hasPayments) {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: AppColors.surface,
                title: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: AppColors.warning),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Cảnh báo học phí & thanh toán',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
                content: const Text(
                  'Hóa đơn tháng này đã có thanh toán.\n'
                  'Điểm danh đã được cập nhật nhưng số tiền đã chốt không tự thay đổi.\n\n'
                  'Dữ liệu điểm danh thay đổi có thể ảnh hưởng buổi dư. Vui lòng đối soát credit.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Đã hiểu'),
                  ),
                ],
              ),
            );
          } else {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: AppColors.surface,
                title: const Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.cyanAccent),
                    SizedBox(width: 8),
                    Text(
                      'Thông báo học phí',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                content: const Text(
                  'Điểm danh đã được sửa.\n'
                  'Học phí tháng này đã được chốt. Vui lòng kiểm tra lại học phí.\n\n'
                  'Dữ liệu điểm danh thay đổi có thể ảnh hưởng buổi dư. Vui lòng đối soát credit.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Đã hiểu'),
                  ),
                ],
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        AppFeedback.showErrorSnackBar(
          context,
          e.toString().replaceAll('Exception: ', ''),
        );
      }
    }
  }

  void _handleFinalize(AttendanceSheet sheet) async {
    try {
      final unresolved = ref
          .read(attendanceControllerProvider(widget.sessionId).notifier)
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
              'Sau khi hoàn tất, buổi học sẽ chuyển sang trạng thái ĐÃ HỌC. Hệ thống sẽ tự động cập nhật học phí tạm tính cho lớp.',
          confirmLabel: 'Xác nhận hoàn tất',
          isDestructive: false,
        );
        if (confirm != true) return;
      }

      await ref
          .read(attendanceControllerProvider(widget.sessionId).notifier)
          .finalize(allowIncomplete: true);

      if (mounted) {
        AppFeedback.showSuccessSnackBar(context, 'Đã hoàn tất buổi học');
      }
    } catch (e) {
      if (mounted) {
        AppFeedback.showErrorSnackBar(
          context,
          e.toString().replaceAll('Exception: ', ''),
        );
      }
    }
  }
}
