import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../app/common_widgets/app_error_state.dart';
import '../../../app/common_widgets/app_feedback.dart';
import '../../../app/common_widgets/app_loading_state.dart';
import '../../../app/common_widgets/attendance_status_icon.dart';
import '../../../app/common_widgets/navy_components.dart';
import '../../../app/common_widgets/parent_contact_actions.dart';
import '../../../app/common_widgets/student_avatar.dart';
import '../../../app/design_system/app_theme.dart';
import '../../../app/design_system/app_spacing.dart';
import '../../../app/navigation/app_global_drawer.dart';
import '../../../app/navigation/ui_keys.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../l10n/app_localizations.dart';
import '../../attendance/presentation/attendance_page.dart';
import '../../classes/domain/class_service.dart';
import '../../classes/presentation/class_controller.dart';
import '../../classes/presentation/class_detail_page.dart';
import '../../memberships/presentation/edit_membership_bottom_sheet.dart';
import '../../memberships/presentation/enroll_student_bottom_sheet.dart';
import '../../memberships/presentation/leave_class_bottom_sheet.dart';
import '../../payments/domain/payment_service.dart';
import '../../payments/presentation/record_payment_bottom_sheet.dart';
import '../../schedule_conflicts/domain/schedule_constraint.dart';
import '../../schedule_conflicts/presentation/schedule_constraint_dialogs.dart';
import '../../tuition/domain/tuition_service.dart';
import '../../tuition/presentation/tuition_controller.dart';
import '../domain/student.dart';
import '../domain/student_detail_overview.dart';
import '../domain/student_detail_overview_service.dart';
import '../domain/student_service.dart';
import 'student_controller.dart';
import 'student_form_page.dart';

part 'student_detail_page.g.dart';

@riverpod
Future<Student?> studentDetail(StudentDetailRef ref, int id) async {
  final service = await ref.watch(studentServiceProvider.future);
  return service.getStudentById(id);
}

class StudentDetailPage extends ConsumerWidget {
  final int studentId;
  const StudentDetailPage({super.key, required this.studentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final overviewAsync = ref.watch(studentDetailOverviewProvider(studentId));

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const AppGlobalDrawer(),
      appBar: AppBar(
        leading: const BackButton(),
        title: Text(l10n.studentDetailTitle),
        actions: [
          const GlobalMenuButton(),
          overviewAsync.when(
            data: (overview) {
              final student = overview.student;
              final isStopped = student.daLuuTru;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: l10n.studentEditProfile,
                    onPressed: () async {
                      await showStudentFormBottomSheet(
                        context,
                        student: student,
                      );
                      ref.invalidate(studentDetailOverviewProvider(studentId));
                    },
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) {
                      if (value == 'toggle_status') {
                        _toggleArchiveStatus(context, ref, student);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        key: isStopped
                            ? UiKeys.studentRestoreAction
                            : UiKeys.studentArchiveAction,
                        value: 'toggle_status',
                        child: Row(
                          children: [
                            Icon(
                              isStopped
                                  ? Icons.restore_rounded
                                  : Icons.person_off_outlined,
                              color: isStopped
                                  ? AppColors.success
                                  : AppColors.error,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isStopped
                                  ? 'Cho hoạt động lại'
                                  : l10n.studentStatusStopped,
                              style: TextStyle(
                                color: isStopped
                                    ? AppColors.success
                                    : AppColors.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: overviewAsync.when(
        data: (overview) {
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(studentDetailOverviewProvider(studentId));
              await ref.read(studentDetailOverviewProvider(studentId).future);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. STUDENT IDENTITY HEADER
                  _buildHeader(context, overview),

                  const SizedBox(height: AppSpacing.sectionGap),

                  // 2. 2 KPI CARDS
                  _buildKpiSection(context, l10n, overview),

                  const SizedBox(height: AppSpacing.sectionGap),

                  // 3. 4 BUSINESS ACTIONS
                  _buildBusinessActions(context, ref, l10n, overview),

                  const SizedBox(height: AppSpacing.sectionGap),

                  // 4. LỚP ĐANG THAM GIA
                  _buildActiveClassesSection(context, ref, l10n, overview),

                  const SizedBox(height: AppSpacing.sectionGap),

                  // 5. HỌC PHÍ THÁNG
                  _buildTuitionSection(context, ref, l10n, overview),

                  const SizedBox(height: AppSpacing.sectionGap),

                  // 6. ĐIỂM DANH GẦN ĐÂY & GIỜ BẬN
                  _buildAttendanceAndBusyTimesSection(
                    context,
                    ref,
                    l10n,
                    overview,
                  ),

                  // 7. GHI CHÚ
                  if (overview.student.ghiChu != null &&
                      overview.student.ghiChu!.trim().isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _buildNotesSection(context, l10n, overview.student),
                  ],

                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
        loading: () => const AppLoadingState(),
        error: (error, stack) => AppErrorState(
          title: l10n.commonError,
          error: l10n.studentLoadDetailError,
          onRetry: () =>
              ref.invalidate(studentDetailOverviewProvider(studentId)),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, StudentDetailOverview overview) {
    final s = overview.student;
    final isStopped = s.daLuuTru;

    return AppSectionCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          StudentAvatar(gioiTinh: s.gioiTinh, studentName: s.hoTen, radius: 30),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        s.hoTen,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    AppStatusChip(
                      label: isStopped ? 'Ngừng học' : 'Đang học',
                      color: isStopped
                          ? AppColors.textMuted
                          : AppColors.success,
                      compact: true,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (s.gioiTinh != null && s.gioiTinh!.isNotEmpty) ...[
                      Icon(
                        s.gioiTinh == 'NAM' ? Icons.male : Icons.female,
                        size: 14,
                        color: s.gioiTinh == 'NAM'
                            ? AppColors.primary
                            : Colors.pinkAccent,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        s.gioiTinh == 'NAM' ? 'Nam' : 'Nữ',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    if (s.sdtPhuHuynh != null && s.sdtPhuHuynh!.isNotEmpty) ...[
                      const Icon(
                        Icons.phone_outlined,
                        size: 14,
                        color: AppColors.cyanAccent,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          '${s.sdtPhuHuynh} (PH)',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.cyanAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (s.sdtPhuHuynh?.trim().isNotEmpty == true) ...[
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ParentContactActions(phone: s.sdtPhuHuynh),
                  ),
                ],
                if (overview.firstActiveMembershipDate != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.event_outlined,
                        size: 14,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Tham gia từ: ${DateFormatter.formatDisplayDate(overview.firstActiveMembershipDate!)}',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiSection(
    BuildContext context,
    AppLocalizations l10n,
    StudentDetailOverview overview,
  ) {
    final fmt = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final activeCount = overview.activeClasses.length;
    final debt = overview.financial.remainingDebt;

    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.cyanAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.school_outlined,
                    color: AppColors.cyanAccent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.studentActiveClassesCount(activeCount),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (debt > 0 ? AppColors.error : AppColors.success)
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.account_balance_wallet_outlined,
                    color: debt > 0 ? AppColors.error : AppColors.success,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Chưa thanh toán: ${fmt.format(debt)}',
                        style: TextStyle(
                          color: debt > 0 ? AppColors.error : AppColors.success,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBusinessActions(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    StudentDetailOverview overview,
  ) {
    final isStopped = overview.student.daLuuTru;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 2.1,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      children: [
        _buildActionCard(
          context,
          title: l10n.studentEditProfile,
          icon: Icons.edit_note_outlined,
          color: AppColors.primary,
          onTap: () async {
            await showStudentFormBottomSheet(
              context,
              student: overview.student,
            );
            ref.invalidate(studentDetailOverviewProvider(studentId));
          },
        ),
        _buildActionCard(
          context,
          title: l10n.studentAddToClass,
          icon: Icons.group_add_outlined,
          color: AppColors.success,
          enabled: !isStopped,
          onTap: () =>
              _showSelectClassForEnrollment(context, ref, overview.student.id!),
        ),
        _buildActionCard(
          context,
          title: l10n.studentBusyTime,
          icon: Icons.schedule_outlined,
          color: AppColors.warning,
          onTap: () async {
            await showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              useSafeArea: true,
              builder: (_) =>
                  BusyTimeFormBottomSheet(studentId: overview.student.id!),
            );
            ref.invalidate(studentDetailOverviewProvider(studentId));
          },
        ),
        _buildActionCard(
          context,
          title: l10n.studentRecordPayment,
          icon: Icons.payments_outlined,
          color: const Color(0xFF8B5CF6),
          onTap: () => _handleRecordPayment(context, ref, overview),
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    bool enabled = true,
    required VoidCallback onTap,
  }) {
    final opacity = enabled ? 1.0 : 0.4;
    return AppSectionCard(
      padding: const EdgeInsets.all(10),
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: opacity,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.textMuted,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveClassesSection(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    StudentDetailOverview overview,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(l10n.studentActiveClasses, Icons.school_outlined),
        const SizedBox(height: 10),
        if (overview.activeClasses.isEmpty)
          AppSectionCard(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Text(
                l10n.studentNoActiveClasses,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ),
          )
        else
          Column(
            children: overview.activeClasses.map((item) {
              return AppSectionCard(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                onTap: () {
                  if (item.classEntity.id != null) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            ClassDetailPage(classId: item.classEntity.id!),
                      ),
                    );
                  }
                },
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.class_outlined,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                item.classEntity.tenLop,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (item.membership.mienGiamPhanTram > 0) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withValues(
                                      alpha: 0.15,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Giảm ${item.membership.mienGiamPhanTram}%',
                                    style: const TextStyle(
                                      color: AppColors.success,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (item.shiftText.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              item.shiftText,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      tooltip: 'Tùy chọn tham gia lớp',
                      onSelected: (action) async {
                        if (action == 'leave') {
                          await showModalBottomSheet<void>(
                            context: context,
                            isScrollControlled: true,
                            builder: (_) => LeaveClassBottomSheet(
                              studentId: overview.student.id!,
                              classId: item.classEntity.id!,
                              studentName: overview.student.hoTen,
                            ),
                          );
                          ref.invalidate(
                            studentDetailOverviewProvider(overview.student.id!),
                          );
                        } else if (action == 'edit') {
                          final success = await showEditMembershipBottomSheet(
                            context,
                            membership: item.membership,
                            studentName: overview.student.hoTen,
                            className: item.classEntity.tenLop,
                          );
                          if (success == true) {
                            ref.invalidate(
                              studentDetailOverviewProvider(
                                overview.student.id!,
                              ),
                            );
                            ref.invalidate(
                              classMonthTuitionOverviewProvider((
                                item.classEntity.id!,
                                DateFormat('yyyy-MM').format(DateTime.now()),
                              )),
                            );
                          }
                        }
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              const Icon(Icons.edit_outlined, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                'Sửa miễn giảm (${item.membership.mienGiamPhanTram}%) & tham gia',
                              ),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'leave',
                          child: Row(
                            children: [
                              Icon(
                                Icons.logout,
                                size: 18,
                                color: AppColors.error,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Cho nghỉ lớp',
                                style: TextStyle(color: AppColors.error),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.chevron_right,
                      color: AppColors.textMuted,
                      size: 18,
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildTuitionSection(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    StudentDetailOverview overview,
  ) {
    final fmt = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final fin = overview.financial;

    String statusText;
    Color statusColor;

    switch (fin.state) {
      case StudentFinancialDisplayState.fullyPaid:
        statusText = l10n.studentTuitionPaid;
        statusColor = AppColors.success;
        break;
      case StudentFinancialDisplayState.partiallyPaid:
        statusText = l10n.studentTuitionPartiallyPaid;
        statusColor = AppColors.warning;
        break;
      case StudentFinancialDisplayState.unpaid:
        statusText = l10n.studentTuitionUnpaid;
        statusColor = AppColors.error;
        break;
      case StudentFinancialDisplayState.hasUnfinalizedClasses:
        statusText = l10n.studentTuitionPendingFinalization;
        statusColor = AppColors.cyanAccent;
        break;
      case StudentFinancialDisplayState.noFinalizedInvoices:
        statusText = l10n.dashboardUnfinalizedTuition;
        statusColor = AppColors.textMuted;
        break;
    }

    final monthFormatted = fin.month.length == 7
        ? '${fin.month.substring(5)}/${fin.month.substring(0, 4)}'
        : fin.month;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          'Học phí tháng $monthFormatted',
          Icons.account_balance_wallet_outlined,
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              statusText,
              style: TextStyle(
                color: statusColor,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        AppSectionCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildFinancialMetricCol(
                    l10n.studentFinalizedDue,
                    fmt.format(fin.finalizedDue),
                    AppColors.textPrimary,
                  ),
                  Container(height: 30, width: 1, color: AppColors.border),
                  _buildFinancialMetricCol(
                    l10n.studentPaid,
                    fmt.format(fin.totalPaid),
                    AppColors.success,
                  ),
                  Container(height: 30, width: 1, color: AppColors.border),
                  _buildFinancialMetricCol(
                    l10n.studentDebt,
                    fmt.format(fin.remainingDebt),
                    fin.remainingDebt > 0 ? AppColors.error : AppColors.success,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(color: AppColors.border, height: 1),
              const SizedBox(height: 10),
              if (fin.latestPayment != null)
                InkWell(
                  onTap: () {
                    // Open payment history / details
                  },
                  child: Row(
                    children: [
                      const Icon(
                        Icons.payments_outlined,
                        color: AppColors.success,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${l10n.studentLatestPayment}: ${fmt.format(fin.latestPayment!.amount)} • ${DateFormatter.formatDisplayDate(fin.latestPayment!.paymentDate)}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        color: AppColors.textMuted,
                        size: 16,
                      ),
                    ],
                  ),
                )
              else
                Text(
                  l10n.studentNoPayment,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFinancialMetricCol(
    String label,
    String value,
    Color valueColor,
  ) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceAndBusyTimesSection(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    StudentDetailOverview overview,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 360;

        final attendancePanel = _buildRecentAttendanceCard(
          context,
          l10n,
          overview.recentAttendance,
        );
        final busyTimesPanel = _buildBusyTimesCard(
          context,
          ref,
          l10n,
          overview.activeBusyTimes,
        );

        if (isNarrow) {
          return Column(
            children: [
              attendancePanel,
              const SizedBox(height: 16),
              busyTimesPanel,
            ],
          );
        } else {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: attendancePanel),
              const SizedBox(width: 12),
              Expanded(child: busyTimesPanel),
            ],
          );
        }
      },
    );
  }

  Widget _buildRecentAttendanceCard(
    BuildContext context,
    AppLocalizations l10n,
    List<StudentRecentAttendanceItem> items,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          l10n.studentRecentAttendance,
          Icons.fact_check_outlined,
        ),
        const SizedBox(height: 8),
        AppSectionCard(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: items.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Center(
                    child: Text(
                      'Chưa có dữ liệu điểm danh',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.length,
                  separatorBuilder: (_, __) =>
                      const Divider(color: AppColors.border, height: 1),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final dateStr = DateFormatter.formatDisplayDate(
                      item.session.ngay,
                    );
                    final shortDate = dateStr.length >= 5
                        ? dateStr.substring(0, 5)
                        : dateStr;

                    return InkWell(
                      onTap: () {
                        if (item.session.id != null) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  AttendancePage(sessionId: item.session.id!),
                            ),
                          );
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Text(
                              shortDate,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                item.classEntity.tenLop,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            AttendanceStatusIcon(
                              status: item.attendance.trangThai,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildBusyTimesCard(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    List<ScheduleConstraint> constraints,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          l10n.studentBusyTimes,
          Icons.schedule_outlined,
          color: AppColors.warning,
        ),
        const SizedBox(height: 8),
        AppSectionCard(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: constraints.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Center(
                    child: Text(
                      'Không có giờ bận',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: constraints.take(3).length,
                  separatorBuilder: (_, __) =>
                      const Divider(color: AppColors.border, height: 1),
                  itemBuilder: (context, index) {
                    final c = constraints[index];
                    String titleStr = '';
                    if (c.occurrenceType == OccurrenceType.DINH_KY &&
                        c.weekday != null) {
                      titleStr = _formatWeekday(c.weekday);
                    } else if (c.specificDate != null) {
                      titleStr = DateFormatter.formatDisplayDate(
                        c.specificDate!,
                      );
                    }

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.schedule,
                            color: AppColors.warning,
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  titleStr,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${c.startTime}–${c.endTime}',
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildNotesSection(
    BuildContext context,
    AppLocalizations l10n,
    Student student,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(l10n.studentNotes, Icons.notes_outlined),
        const SizedBox(height: 8),
        AppSectionCard(
          padding: const EdgeInsets.all(12),
          child: Text(
            student.ghiChu!,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(
    String title,
    IconData icon, {
    Color? color,
    Widget? trailing,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Icon(icon, size: 18, color: color ?? AppColors.cyanAccent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 8), trailing],
      ],
    );
  }

  String _formatWeekday(int? thu) {
    switch (thu) {
      case 1:
        return 'Thứ 2';
      case 2:
        return 'Thứ 3';
      case 3:
        return 'Thứ 4';
      case 4:
        return 'Thứ 5';
      case 5:
        return 'Thứ 6';
      case 6:
        return 'Thứ 7';
      case 7:
        return 'Chủ Nhật';
      default:
        return '';
    }
  }

  Future<void> _showSelectClassForEnrollment(
    BuildContext context,
    WidgetRef ref,
    int studentId,
  ) async {
    final classesAsync = ref.read(classListControllerProvider);
    final classes = classesAsync.value ?? [];
    final activeClasses = classes.where((c) => !c.daLuuTru).toList();

    if (activeClasses.isEmpty) {
      AppFeedback.showWarningSnackBar(
        context,
        'Không có lớp học đang hoạt động.',
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Chọn lớp học để ghi danh',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: activeClasses.length,
                separatorBuilder: (_, __) =>
                    const Divider(color: AppColors.border, height: 1),
                itemBuilder: (context, index) {
                  final c = activeClasses[index];
                  return ListTile(
                    title: Text(
                      c.tenLop,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: AppColors.cyanAccent,
                    ),
                    onTap: () async {
                      Navigator.pop(context);
                      await showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        useSafeArea: true,
                        builder: (_) => EnrollStudentBottomSheet(
                          classId: c.id!,
                          initialStudentId: studentId,
                        ),
                      );
                      ref.invalidate(studentDetailOverviewProvider(studentId));
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleRecordPayment(
    BuildContext context,
    WidgetRef ref,
    StudentDetailOverview overview,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final tuitionRepo = await ref.read(tuitionRepositoryProvider.future);
    final paymentService = await ref.read(paymentServiceProvider.future);
    final classService = await ref.read(classServiceProvider.future);

    final invoices = await tuitionRepo.getInvoicesInMonthRange(
      fromMonth: overview.financial.month,
      toMonth: overview.financial.month,
      studentId: overview.student.id!,
    );

    final summaries = await paymentService.getPaymentSummariesForInvoices(
      invoices,
    );
    final debtSummaries = summaries.where((s) => s.remainingDebt > 0).toList();

    if (debtSummaries.isEmpty) {
      if (!context.mounted) return;
      AppFeedback.showWarningSnackBar(context, l10n.studentNoDebtToRecord);
      return;
    }

    if (debtSummaries.length == 1) {
      final summary = debtSummaries.first;
      if (!context.mounted) return;
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => RecordPaymentBottomSheet(
          studentId: overview.student.id!,
          classId: summary.invoice.idLop,
          month: summary.invoice.thang,
          suggestedAmount: summary.remainingDebt,
        ),
      );
      ref.invalidate(studentDetailOverviewProvider(overview.student.id!));
    } else {
      final classIds = debtSummaries.map((s) => s.invoice.idLop).toList();
      final classes = await classService.getClassesByIds(classIds);
      final classMap = {for (final c in classes) c.id!: c.tenLop};

      if (!context.mounted) return;
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.studentSelectTuitionInvoice,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ListView.separated(
                shrinkWrap: true,
                itemCount: debtSummaries.length,
                separatorBuilder: (_, __) =>
                    const Divider(color: AppColors.border, height: 1),
                itemBuilder: (context, index) {
                  final summary = debtSummaries[index];
                  final className =
                      classMap[summary.invoice.idLop] ??
                      'Lớp ${summary.invoice.idLop}';
                  final due = summary.remainingDebt;

                  return ListTile(
                    title: Text(
                      className,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      'Chưa thanh toán: ${NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(due)}',
                    ),
                    onTap: () async {
                      Navigator.pop(context);
                      await showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        useSafeArea: true,
                        builder: (_) => RecordPaymentBottomSheet(
                          studentId: overview.student.id!,
                          classId: summary.invoice.idLop,
                          month: summary.invoice.thang,
                          suggestedAmount: due,
                        ),
                      );
                      ref.invalidate(
                        studentDetailOverviewProvider(overview.student.id!),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      );
    }
  }

  Future<void> _toggleArchiveStatus(
    BuildContext context,
    WidgetRef ref,
    Student student,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final isStopped = student.daLuuTru;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          isStopped ? 'Cho hoạt động lại' : l10n.studentStatusStopped,
        ),
        content: Text(
          isStopped
              ? 'Bạn có chắc muốn cho học sinh "${student.hoTen}" hoạt động lại?'
              : 'Bạn có chắc muốn đánh dấu học sinh "${student.hoTen}" ngừng học?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.commonCancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isStopped ? AppColors.success : AppColors.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.commonConfirm),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        if (isStopped) {
          await ref
              .read(studentListControllerProvider.notifier)
              .restore(student.id!);
        } else {
          await ref
              .read(studentListControllerProvider.notifier)
              .archive(student.id!);
        }
        ref.invalidate(studentDetailOverviewProvider(student.id!));
        ref.invalidate(studentDetailProvider(student.id!));
        if (context.mounted) {
          AppFeedback.showSuccessSnackBar(
            context,
            isStopped
                ? 'Đã cho học sinh hoạt động lại'
                : 'Đã đánh dấu học sinh ngừng học',
          );
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
