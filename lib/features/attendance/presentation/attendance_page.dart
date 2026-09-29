import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/common_widgets/app_feedback.dart';
import '../../../app/common_widgets/attendance_status_icon.dart';
import '../../../app/common_widgets/navy_components.dart';
import '../../../app/common_widgets/parent_contact_actions.dart';
import '../../../app/common_widgets/student_avatar.dart';
import '../../../app/design_system/app_theme.dart';
import '../../../app/localization/app_formatter.dart';
import '../../../l10n/app_localizations.dart';
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
import 'widgets/attendance_state_selector.dart';
import 'widgets/attendance_summary_metric.dart';
import 'widgets/attendance_ui_summary.dart';
import 'widgets/attendance_visual_spec.dart';

class AttendancePage extends ConsumerStatefulWidget {
  final int sessionId;

  const AttendancePage({super.key, required this.sessionId});

  @override
  ConsumerState<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends ConsumerState<AttendancePage> {
  bool _isCorrectionMode = false;
  String _correctionReason = '';
  bool _isRosterIssuesExpanded = false;

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
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: const BackButton(),
        title: Text(l10n?.attendanceShortTitle ?? 'Điểm danh'),
        actions: [
          ...sheetAsync.when(
            data: (sheet) => [
              if (sheet.session.trangThai == SessionStatus.DA_HOC) ...[
                IconButton(
                  icon: const Icon(Icons.history, color: AppColors.cyanAccent),
                  tooltip: 'Lịch sử chỉnh sửa',
                  onPressed: () => _showCorrectionHistoryBottomSheet(sheet),
                ),
                if (!_isCorrectionMode)
                  IconButton(
                    icon: const Icon(
                      Icons.edit_outlined,
                      color: AppColors.warning,
                    ),
                    tooltip: l10n?.attendanceEdit ?? 'Sửa điểm danh',
                    onPressed: () => _enterCorrectionModeDialog(sheet),
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
                const SizedBox(height: 12),
                const Text(
                  'Không thể tải dữ liệu điểm danh.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => ref.invalidate(
                    attendanceControllerProvider(widget.sessionId),
                  ),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Thử lại'),
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
    final isEditable = _canEditAttendanceState(sheet);

    final attendanceNotifier = ref.read(
      attendanceControllerProvider(widget.sessionId).notifier,
    );

    final summary = AttendanceUiSummary.fromMembers(
      members: sheet.members,
      getEffectiveState: (stId) => attendanceNotifier.effectiveStateFor(stId),
    );

    return Column(
      children: [
        _buildCompactHeaderAndSummary(sheet, summary),
        if (isEditable) _buildActionToolbar(sheet),
        if (_isCorrectionMode)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.warning.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.warning,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n?.attendanceEditingCompleted ??
                        'Đang sửa điểm danh đã hoàn tất',
                    style: const TextStyle(
                      color: AppColors.warning,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (sheet.session.loai == SessionType.PHAT_SINH &&
            _canEditRosterStructure(sheet))
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.person_add_alt_1_outlined,
                  color: AppColors.cyanAccent,
                  size: 18,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Buổi học phát sinh',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () {
                    if (!_ensureDraftClean()) return;
                    SessionAdjustmentDialogs.showPhatSinhDialog(
                      context: context,
                      ref: ref,
                      targetSessionId: widget.sessionId,
                    );
                  },
                  icon: const Icon(Icons.person_add, size: 14),
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
            margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.warning.withValues(alpha: 0.3),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.warning, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Buổi học bù theo ca riêng: Xếp học bù từ buổi gốc.',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (!sheet.isRosterValid) _buildRosterIssuesWidget(sheet),
        _buildSectionHeader(summary.total),
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
                          size: 44,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          sheet.session.loai == SessionType.HOC_BU
                              ? 'Buổi học bù: chưa có học sinh được xếp học bù vào buổi này.'
                              : sheet.session.loai == SessionType.PHAT_SINH
                              ? 'Buổi học phát sinh: chưa có danh sách tham gia. Bấm "Thêm học sinh" để thêm vào danh sách.'
                              : 'Chưa có học sinh nào trong danh sách điểm danh.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
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

  Widget _buildCompactHeaderAndSummary(
    AttendanceSheet sheet,
    AttendanceUiSummary summary,
  ) {
    final session = sheet.session;
    final date = DateTime.parse(session.ngay);
    final weekday = AppFormatter.formatWeekday(date.weekday, context: context);
    final dateStr = AppFormatter.formatDate(date, context: context);
    final l10n = AppLocalizations.of(context)!;

    final isFinalized = session.trangThai == SessionStatus.DA_HOC;

    return AppSectionCard(
      margin: const EdgeInsets.fromLTRB(6, 8, 6, 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '$weekday, $dateStr • ${session.gioBatDau}–${session.gioKetThuc}',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              AppStatusChip(
                label: session.loai.displayName,
                color: AppColors.cyanAccent,
                compact: true,
              ),
              const SizedBox(width: 4),
              AppStatusChip(
                label: isFinalized ? (l10n.attendanceCompleted) : 'Tạm tính',
                color: isFinalized ? AppColors.success : AppColors.warning,
                compact: true,
              ),
            ],
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final metrics = [
                AttendanceSummaryMetric(
                  icon: Icons.groups_2_outlined,
                  count: summary.total,
                  color: AppColors.primary,
                  semanticLabel: 'Tổng số',
                ),
                AttendanceSummaryMetric(
                  icon: Icons.check_rounded,
                  count: summary.present,
                  color: AppColors.success,
                  semanticLabel: l10n.attendancePresent,
                ),
                AttendanceSummaryMetric(
                  icon: Icons.schedule_rounded,
                  count: summary.late,
                  color: AppColors.warning,
                  semanticLabel: l10n.attendanceLate,
                ),
                AttendanceSummaryMetric(
                  icon: Icons.event_busy_outlined,
                  count: summary.excused,
                  color: AppColors.cyanAccent,
                  semanticLabel: l10n.attendanceExcused,
                ),
                AttendanceSummaryMetric(
                  icon: Icons.close_rounded,
                  count: summary.unexcused,
                  color: AppColors.error,
                  semanticLabel: l10n.attendanceUnexcused,
                ),
                if (summary.makeup > 0)
                  AttendanceSummaryMetric(
                    icon: Icons.event_repeat_rounded,
                    count: summary.makeup,
                    color: AppColors.primary,
                    semanticLabel: l10n.attendanceMakeup,
                  ),
                if (summary.unresolved > 0)
                  AttendanceSummaryMetric(
                    icon: Icons.help_outline_rounded,
                    count: summary.unresolved,
                    color: AppColors.textMuted,
                    semanticLabel: l10n.attendanceNotMarked,
                  ),
              ];

              if (constraints.maxWidth >= 340) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: metrics,
                );
              } else {
                return Wrap(spacing: 6, runSpacing: 6, children: metrics);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionToolbar(AttendanceSheet sheet) {
    final l10n = AppLocalizations.of(context);
    final isMakeupSession = sheet.session.loai == SessionType.HOC_BU;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton.icon(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () {
              final notifier = ref.read(
                attendanceControllerProvider(widget.sessionId).notifier,
              );
              if (isMakeupSession) {
                notifier.markAllHocBu();
              } else {
                notifier.markAllPresent();
              }
            },
            icon: const Icon(
              Icons.done_all_rounded,
              color: AppColors.cyanAccent,
              size: 16,
            ),
            label: Text(
              isMakeupSession
                  ? (l10n?.attendanceMarkAllMakeup ?? 'Học bù hết')
                  : (l10n?.attendanceMarkAllPresent ?? 'Có mặt hết'),
              style: const TextStyle(
                color: AppColors.cyanAccent,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.undo_rounded,
              color: AppColors.textSecondary,
              size: 18,
            ),
            onPressed: () => ref
                .read(attendanceControllerProvider(widget.sessionId).notifier)
                .undoChanges(),
            tooltip: l10n?.attendanceUndo ?? 'Hoàn tác',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildRosterIssuesWidget(AttendanceSheet sheet) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: AppColors.error,
                size: 18,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Danh sách lớp không hợp lệ',
                  style: TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              InkWell(
                onTap: () {
                  setState(() {
                    _isRosterIssuesExpanded = !_isRosterIssuesExpanded;
                  });
                },
                child: Row(
                  children: [
                    Text(
                      _isRosterIssuesExpanded ? 'Thu gọn' : 'Xem chi tiết',
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 11,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    Icon(
                      _isRosterIssuesExpanded
                          ? Icons.expand_less
                          : Icons.expand_more,
                      color: AppColors.error,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_isRosterIssuesExpanded && sheet.rosterIssues.isNotEmpty)
            ...sheet.rosterIssues.map(
              (ri) => Padding(
                padding: const EdgeInsets.only(top: 6.0, left: 26),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 12,
                      color: AppColors.error,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        ri.message,
                        style: const TextStyle(
                          color: AppColors.error,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(int totalCount) {
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${l10n?.attendanceStudents ?? 'HỌC SINH'} ($totalCount)',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.info_outline_rounded,
              color: AppColors.textMuted,
              size: 18,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: l10n?.attendanceLegend ?? 'Chú thích điểm danh',
            onPressed: () => _showLegendBottomSheet(context),
          ),
        ],
      ),
    );
  }

  void _showLegendBottomSheet(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.attendanceLegend,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildLegendRow(
                Icons.check_rounded,
                AppColors.success,
                l10n.attendancePresent,
              ),
              _buildLegendRow(
                Icons.schedule_rounded,
                AppColors.warning,
                l10n.attendanceLate,
              ),
              _buildLegendRow(
                Icons.event_busy_outlined,
                AppColors.cyanAccent,
                l10n.attendanceExcused,
              ),
              _buildLegendRow(
                Icons.close_rounded,
                AppColors.error,
                l10n.attendanceUnexcused,
              ),
              _buildLegendRow(
                Icons.event_repeat_rounded,
                AppColors.primary,
                l10n.attendanceMakeup,
              ),
              _buildLegendRow(
                Icons.help_outline_rounded,
                AppColors.textMuted,
                l10n.attendanceNotMarked,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLegendRow(IconData icon, Color color, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentRow(AttendanceSheet sheet, AttendanceSheetMember member) {
    final student = member.rosterMember.student;
    final isEditable = _canEditAttendanceState(sheet);
    final canEditRoster = _canEditRosterStructure(sheet);
    final l10n = AppLocalizations.of(context)!;

    final attendanceNotifier = ref.read(
      attendanceControllerProvider(widget.sessionId).notifier,
    );
    final effectiveState = attendanceNotifier.effectiveStateFor(student.id!);

    final isNormalChinh =
        member.rosterMember.source ==
            RosterInclusionSource.SINGLE_SHIFT_MEMBERSHIP ||
        member.rosterMember.source == RosterInclusionSource.EXPLICIT_ASSIGNMENT;

    final isMissedOriginal =
        sheet.session.loai == SessionType.CHINH &&
        sheet.session.trangThai == SessionStatus.DA_HOC &&
        (member.state == AttendanceState.NGHI_CO_PHEP ||
            member.state == AttendanceState.NGHI_KHONG_PHEP);

    final hasRosterActions =
        (canEditRoster &&
            isNormalChinh &&
            sheet.session.loai == SessionType.CHINH &&
            member.persistedRecord == null) ||
        (isMissedOriginal && !_isCorrectionMode) ||
        (member.rosterMember.adjustment != null &&
            canEditRoster &&
            member.persistedRecord == null);

    final allowedStates = AttendanceState.values.where((s) {
      if (sheet.session.trangThai == SessionStatus.DA_HOC &&
          s == AttendanceState.CHUA_DIEM_DANH) {
        return false;
      }
      if (member.rosterMember.source == RosterInclusionSource.HOC_BU) {
        return s != AttendanceState.CO_MAT && s != AttendanceState.TRE;
      } else {
        return s != AttendanceState.HOC_BU;
      }
    }).toList();

    return AppSectionCard(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StudentAvatar(
                gioiTinh: student.gioiTinh,
                studentName: student.hoTen,
                radius: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        student.hoTen,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (member.rosterMember.source ==
                        RosterInclusionSource.DOI_CA) ...[
                      const SizedBox(width: 4),
                      const Tooltip(
                        message: 'Đổi ca',
                        child: Icon(
                          Icons.swap_horiz_rounded,
                          size: 16,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                    if (member.rosterMember.source ==
                        RosterInclusionSource.HOC_BU) ...[
                      const SizedBox(width: 4),
                      const Tooltip(
                        message: 'Học bù',
                        child: Icon(
                          Icons.event_repeat_rounded,
                          size: 16,
                          color: AppColors.cyanAccent,
                        ),
                      ),
                    ],
                    if (member.rosterMember.source ==
                        RosterInclusionSource.PHAT_SINH) ...[
                      const SizedBox(width: 4),
                      const Tooltip(
                        message: 'Phát sinh',
                        child: Icon(
                          Icons.person_add_alt_1_rounded,
                          size: 16,
                          color: AppColors.warning,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (!isEditable)
                AttendanceStatusIcon(
                  status: _mapStateToStatus(effectiveState),
                  size: 18,
                )
              else
                AttendanceStatusIcon(
                  status: _mapStateToStatus(effectiveState),
                  size: 16,
                ),
              if (hasRosterActions)
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert_rounded,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onSelected: (value) async {
                    if (!_ensureDraftClean()) return;
                    if (value == 'doi_ca') {
                      SessionAdjustmentDialogs.showDoiCaDialog(
                        context: context,
                        ref: ref,
                        studentId: student.id!,
                        originalSessionId: widget.sessionId,
                      );
                    } else if (value == 'hoc_bu') {
                      SessionAdjustmentDialogs.showHocBuDialog(
                        context: context,
                        ref: ref,
                        studentId: student.id!,
                        originalSessionId: widget.sessionId,
                      );
                    } else if (value == 'huy_dieuchinh') {
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
                    }
                  },
                  itemBuilder: (ctx) => [
                    if (canEditRoster &&
                        isNormalChinh &&
                        sheet.session.loai == SessionType.CHINH &&
                        member.persistedRecord == null)
                      const PopupMenuItem(
                        value: 'doi_ca',
                        child: Row(
                          children: [
                            Icon(
                              Icons.swap_horiz,
                              size: 16,
                              color: AppColors.primary,
                            ),
                            SizedBox(width: 8),
                            Text('Đổi ca', style: TextStyle(fontSize: 13)),
                          ],
                        ),
                      ),
                    if (isMissedOriginal && !_isCorrectionMode)
                      const PopupMenuItem(
                        value: 'hoc_bu',
                        child: Row(
                          children: [
                            Icon(
                              Icons.event_repeat,
                              size: 16,
                              color: AppColors.cyanAccent,
                            ),
                            SizedBox(width: 8),
                            Text('Xếp học bù', style: TextStyle(fontSize: 13)),
                          ],
                        ),
                      ),
                    if (member.rosterMember.adjustment != null &&
                        canEditRoster &&
                        member.persistedRecord == null)
                      const PopupMenuItem(
                        value: 'huy_dieuchinh',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline,
                              size: 16,
                              color: AppColors.error,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Hủy điều chỉnh',
                              style: TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
            ],
          ),
          if (student.sdtPhuHuynh?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 6),
            ParentContactActions(phone: student.sdtPhuHuynh),
          ],
          if (isEditable) ...[
            const SizedBox(height: 6),
            AttendanceStateSelector(
              selected: effectiveState,
              allowedStates: allowedStates,
              onChanged: (newState) {
                ref
                    .read(
                      attendanceControllerProvider(widget.sessionId).notifier,
                    )
                    .updateLocalDraft(student.id!, newState);
                setState(() {});
              },
            ),
          ],
          if (member.suggestedState != null &&
              effectiveState == AttendanceState.CHUA_DIEM_DANH)
            Container(
              margin: const EdgeInsets.only(top: 6),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.cyanAccent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.event_available_rounded,
                    size: 14,
                    color: AppColors.cyanAccent,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${member.suggestionReason ?? l10n.attendanceApprovedLeave}: '
                      'Đề xuất ${AttendanceVisualSpec.forState(member.suggestedState!, l10n).label}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isEditable)
                    InkWell(
                      onTap: () {
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
                        setState(() {});
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        child: Text(
                          l10n.attendanceApplySuggestion,
                          style: const TextStyle(
                            color: AppColors.cyanAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  AttendanceStatus? _mapStateToStatus(AttendanceState state) {
    switch (state) {
      case AttendanceState.CHUA_DIEM_DANH:
        return null;
      case AttendanceState.CO_MAT:
        return AttendanceStatus.CO_MAT;
      case AttendanceState.TRE:
        return AttendanceStatus.TRE;
      case AttendanceState.NGHI_CO_PHEP:
        return AttendanceStatus.NGHI_CO_PHEP;
      case AttendanceState.NGHI_KHONG_PHEP:
        return AttendanceStatus.NGHI_KHONG_PHEP;
      case AttendanceState.HOC_BU:
        return AttendanceStatus.HOC_BU;
    }
  }

  Widget? _buildBottomBar(AttendanceSheet sheet) {
    final l10n = AppLocalizations.of(context);
    final isFinalized = sheet.session.trangThai == SessionStatus.DA_HOC;

    if (isFinalized) {
      if (!_isCorrectionMode) {
        return null; // NO bottom bar in read-only DA_HOC mode (Edit icon is in AppBar!)
      } else {
        return SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(
                top: BorderSide(color: AppColors.border, width: 1),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(vertical: 10),
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
                    child: Text(
                      l10n?.attendanceCancelCorrection ?? 'Hủy',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onPressed: () => _handleSaveCorrection(sheet),
                    icon: const Icon(Icons.save, size: 16),
                    label: Text(
                      l10n?.attendanceSaveCorrection ?? 'Lưu chỉnh sửa',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
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

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                  padding: const EdgeInsets.symmetric(vertical: 10),
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
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                onPressed: () => _handleFinalize(sheet),
                icon: const Icon(Icons.check_circle_outline, size: 16),
                label: Text(
                  l10n?.attendanceFinalizeShort ?? 'Hoàn tất',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _enterCorrectionModeDialog(AttendanceSheet sheet) {
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
                      Navigator.pop(ctx);
                      setState(() {
                        _correctionReason = '';
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
