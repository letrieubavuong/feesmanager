import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/common_widgets/app_error_state.dart';
import '../../../app/common_widgets/app_loading_state.dart';
import '../../../app/common_widgets/navy_components.dart';
import '../../../app/design_system/app_theme.dart';
import '../../../app/navigation/app_destination.dart';
import '../../../app/navigation/app_global_drawer.dart';
import '../../../app/navigation/navigation_controller.dart';
import '../../../app/navigation/ui_keys.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../l10n/app_localizations.dart';
import '../../attendance/presentation/attendance_page.dart';
import '../../classes/domain/class.dart';
import '../../classes/presentation/class_controller.dart';
import '../../reports/domain/report_scope.dart';
import '../../reports/domain/report_service.dart';
import '../../reports/export/report_pdf_exporter.dart';
import '../../sessions/domain/class_session.dart';
import '../../sessions/domain/session_generation_service.dart';
import '../../tuition/domain/invoice_service.dart';
import '../../tuition/domain/class_month_tuition_overview.dart';
import '../../tuition/domain/class_month_tuition_overview_service.dart';
import '../domain/dashboard_overview.dart';
import 'dashboard_controller.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final dashboardAsync = ref.watch(dashboardControllerProvider);
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const AppGlobalDrawer(),
      appBar: AppBar(
        leading: const GlobalMenuButton(),
        title: Text(l10n.dashboardTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Làm mới',
            onPressed: () {
              ref.invalidate(dashboardControllerProvider);
            },
          ),
        ],
      ),
      body: dashboardAsync.when(
        data: (overview) {
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(dashboardControllerProvider);
              await ref.read(dashboardControllerProvider.future);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. GREETING BANNER
                  _buildGreetingCard(context, l10n, now),

                  const SizedBox(height: 16),

                  // 2. 4 KPI CARDS
                  _buildKpiGrid(l10n, overview),

                  const SizedBox(height: 20),

                  // 3. BUSINESS QUICK ACTIONS
                  _buildSectionHeader(l10n.dashboardTasks, Icons.task_alt),
                  const SizedBox(height: 10),
                  _buildQuickActionGrid(context, ref, l10n, overview),

                  const SizedBox(height: 20),

                  // 4. TODAY SCHEDULE TIMELINE
                  _buildSectionHeader(
                    l10n.dashboardTodaySchedule,
                    Icons.calendar_today_outlined,
                    trailing: Text(
                      '${overview.todaySessions.length} buổi',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildTodaySchedule(context, l10n, overview.todaySessions),

                  const SizedBox(height: 20),

                  // 5. BUSINESS WARNINGS
                  _buildSectionHeader(
                    l10n.dashboardWarnings,
                    Icons.warning_amber_rounded,
                    color: AppColors.warning,
                  ),
                  const SizedBox(height: 10),
                  _buildWarningsList(context, ref, l10n, overview.warnings),

                  const SizedBox(height: 20),

                  // 6. RECENT ACTIVITIES EXPANDER
                  DashboardRecentActivitiesExpander(
                    activities: overview.recentActivities,
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
        loading: () => const AppLoadingState(),
        error: (error, stack) => AppErrorState(
          title: l10n.commonError,
          error: error.toString(),
          onRetry: () => ref.invalidate(dashboardControllerProvider),
        ),
      ),
    );
  }

  Widget _buildGreetingCard(
    BuildContext context,
    AppLocalizations l10n,
    DateTime now,
  ) {
    final dateFormatted = DateFormatter.formatDisplayDate(now);

    return AppSectionCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0A84FF), Color(0xFF0066FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.waving_hand_outlined,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.dashboardGreeting,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      dateFormatted,
                      style: const TextStyle(
                        color: AppColors.cyanAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.dashboardGreetingSubtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiGrid(AppLocalizations l10n, DashboardOverview overview) {
    final fmt = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return Row(
      children: [
        Expanded(
          child: _buildKpiTile(
            title: l10n.dashboardUnfinalizedTuition,
            value: '${overview.unfinalizedTuitionStudentCount}',
            icon: Icons.fact_check_outlined,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildKpiTile(
            title:
                'Chưa thu tháng ${DateFormat('MM/yyyy').format(DateTime.now())}',
            value: fmt.format(overview.outstandingDebt),
            icon: Icons.account_balance_wallet_outlined,
            color: overview.outstandingDebt > 0
                ? AppColors.error
                : AppColors.success,
          ),
        ),
      ],
    );
  }

  Widget _buildKpiTile({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Icon(icon, color: color, size: 16),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
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

  Widget _buildQuickActionGrid(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    DashboardOverview overview,
  ) {
    final tasksMap = {for (var task in overview.tasks) task.type: task};
    final taskAttendance = tasksMap[DashboardTaskType.attendanceNow];
    final taskGenerate = tasksMap[DashboardTaskType.generateSessions];
    final taskFinalize = tasksMap[DashboardTaskType.finalizeTuition];
    final taskReport = tasksMap[DashboardTaskType.exportReportPdf];

    return Column(
      children: [
        _buildActionRow(
          key: UiKeys.dashboardQuickAddStudent,
          title: taskAttendance?.title ?? l10n.dashboardAttendanceNow,
          subtitle: taskAttendance?.subtitle ?? '',
          icon: Icons.task_alt,
          color: AppColors.cyanAccent,
          onTap: () => _handleAttendanceNow(context, ref, overview),
        ),
        const Divider(height: 1, color: AppColors.border),
        _buildActionRow(
          key: UiKeys.dashboardQuickManageClasses,
          title: taskGenerate?.title ?? l10n.dashboardGenerateSessions,
          subtitle:
              taskGenerate?.subtitle ?? l10n.dashboardGenerateSessionsSubtitle,
          icon: Icons.auto_mode,
          color: AppColors.success,
          onTap: () => _showGenerateSessionsBottomSheet(context, ref),
        ),
        const Divider(height: 1, color: AppColors.border),
        _buildActionRow(
          key: UiKeys.dashboardQuickViewTuition,
          title: taskFinalize?.title ?? l10n.dashboardFinalizeTuition,
          subtitle: taskFinalize?.subtitle ?? '',
          icon: Icons.fact_check_outlined,
          color: AppColors.warning,
          onTap: () => _showFinalizeTuitionBottomSheet(context, ref),
        ),
        const Divider(height: 1, color: AppColors.border),
        _buildActionRow(
          key: UiKeys.dashboardQuickViewReports,
          title: taskReport?.title ?? l10n.dashboardExportReport,
          subtitle: taskReport?.subtitle ?? l10n.dashboardExportReportSubtitle,
          icon: Icons.picture_as_pdf_outlined,
          color: const Color(0xFF8B5CF6),
          onTap: () => _handleExportReportPdf(context, ref),
        ),
      ],
    );
  }

  Widget _buildActionRow({
    Key? key,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      key: key,
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right,
              color: AppColors.textMuted,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodaySchedule(
    BuildContext context,
    AppLocalizations l10n,
    List<DashboardTodaySession> sessions,
  ) {
    if (sessions.isEmpty) {
      return AppSectionCard(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Text(
            l10n.dashboardNoSessions,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ),
      );
    }

    final now = DateTime.now();
    final currentTimeStr = DateFormat('HH:mm').format(now);

    return AppSectionCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: sessions.length,
        itemBuilder: (context, index) {
          final item = sessions[index];
          final s = item.session;

          Color statusColor;
          String statusText;

          if (s.trangThai == SessionStatus.DA_HOC) {
            statusColor = AppColors.success;
            statusText = l10n.dashboardDone;
          } else if (s.trangThai == SessionStatus.HUY) {
            statusColor = AppColors.textMuted;
            statusText = l10n.dashboardCanceled;
          } else if (s.trangThai == SessionStatus.NGHI_LE) {
            statusColor = AppColors.textMuted;
            statusText = l10n.dashboardHoliday;
          } else if (s.gioKetThuc.compareTo(currentTimeStr) < 0) {
            statusColor = AppColors.error;
            statusText = l10n.dashboardNeedsAttendance;
          } else if (s.gioBatDau.compareTo(currentTimeStr) <= 0 &&
              s.gioKetThuc.compareTo(currentTimeStr) >= 0) {
            statusColor = AppColors.warning;
            statusText = l10n.dashboardInProgress;
          } else {
            statusColor = AppColors.cyanAccent;
            statusText = l10n.dashboardUpcoming;
          }

          final canTap =
              s.id != null &&
              s.trangThai != SessionStatus.HUY &&
              s.trangThai != SessionStatus.NGHI_LE;

          return DashboardTodayTimelineItem(
            item: item,
            isFirst: index == 0,
            isLast: index == sessions.length - 1,
            statusText: statusText,
            statusColor: statusColor,
            onTap: canTap
                ? () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AttendancePage(sessionId: s.id!),
                      ),
                    );
                  }
                : null,
          );
        },
      ),
    );
  }

  Widget _buildWarningsList(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    List<DashboardWarning> warnings,
  ) {
    if (warnings.isEmpty) {
      return AppSectionCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: AppColors.success,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.dashboardNoWarnings,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: warnings.map((w) {
        return AppSectionCard(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          onTap: () => _handleWarningTap(context, ref, w),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.warning,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      w.title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      w.description,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppColors.textMuted,
                size: 18,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // --- HANDLERS & BOTTOM SHEETS ---

  void _handleAttendanceNow(
    BuildContext context,
    WidgetRef ref,
    DashboardOverview overview,
  ) {
    final pendingSessions = overview.todaySessions
        .where((s) => s.session.trangThai == SessionStatus.DU_KIEN)
        .toList();

    if (pendingSessions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hôm nay không có buổi cần điểm danh.')),
      );
      return;
    }

    if (pendingSessions.length == 1) {
      final sId = pendingSessions.first.session.id;
      if (sId != null) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => AttendancePage(sessionId: sId)),
        );
      }
    } else {
      _showPendingAttendanceBottomSheet(context, ref, overview);
    }
  }

  void _showPendingAttendanceBottomSheet(
    BuildContext context,
    WidgetRef ref,
    DashboardOverview overview,
  ) {
    final pendingSessions = overview.todaySessions
        .where((s) => s.session.trangThai == SessionStatus.DU_KIEN)
        .toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'BUỔI HỌC CẦN ĐIỂM DANH HÔM NAY',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textMuted),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const Divider(color: AppColors.border),
                if (pendingSessions.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: Text(
                        'Không có buổi học nào cần điểm danh.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: pendingSessions.length,
                      separatorBuilder: (_, __) =>
                          const Divider(color: AppColors.border, height: 1),
                      itemBuilder: (context, index) {
                        final item = pendingSessions[index];
                        final s = item.session;
                        return ListTile(
                          title: Text(
                            item.className,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            'Giờ: ${s.gioBatDau}–${s.gioKetThuc} • Loạ: ${s.loai.name}',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          trailing: const Icon(
                            Icons.chevron_right,
                            color: AppColors.textMuted,
                          ),
                          onTap: () {
                            Navigator.of(context).pop();
                            if (s.id != null) {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      AttendancePage(sessionId: s.id!),
                                ),
                              );
                            }
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showGenerateSessionsBottomSheet(BuildContext context, WidgetRef ref) {
    DateTime fromDate = DateTime.now();
    DateTime toDate = DateTime.now().add(const Duration(days: 14));
    ClassEntity? selectedClass;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Consumer(
              builder: (context, ref, _) {
                final classesAsync = ref.watch(classListControllerProvider);

                return SafeArea(
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: 16,
                      bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'SINH BUỔI HỌC TỪ LỊCH ĐỊNH KỲ',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: AppColors.textMuted,
                              ),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ],
                        ),
                        const Divider(color: AppColors.border),
                        const SizedBox(height: 8),
                        const Text(
                          'Chọn lớp học *',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        classesAsync.when(
                          data: (classes) {
                            final activeClasses = classes
                                .where((c) => !c.daLuuTru)
                                .toList();
                            return DropdownButtonFormField<ClassEntity>(
                              initialValue: selectedClass,
                              hint: const Text('Chọn lớp học...'),
                              items: activeClasses.map((c) {
                                return DropdownMenuItem(
                                  value: c,
                                  child: Text(c.tenLop),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setState(() => selectedClass = val);
                              },
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                              ),
                            );
                          },
                          loading: () => const AppLoadingState(),
                          error: (e, _) => Text('Lỗi: $e'),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Từ ngày',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  OutlinedButton.icon(
                                    icon: const Icon(
                                      Icons.calendar_today,
                                      size: 14,
                                    ),
                                    label: Text(
                                      DateFormat('yyyy-MM-dd').format(fromDate),
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    onPressed: () async {
                                      final picked = await showDatePicker(
                                        context: context,
                                        initialDate: fromDate,
                                        firstDate: DateTime(2020),
                                        lastDate: DateTime(2030),
                                      );
                                      if (picked != null) {
                                        setState(() => fromDate = picked);
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
                                  const Text(
                                    'Đến ngày',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  OutlinedButton.icon(
                                    icon: const Icon(
                                      Icons.calendar_today,
                                      size: 14,
                                    ),
                                    label: Text(
                                      DateFormat('yyyy-MM-dd').format(toDate),
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    onPressed: () async {
                                      final picked = await showDatePicker(
                                        context: context,
                                        initialDate: toDate,
                                        firstDate: DateTime(2020),
                                        lastDate: DateTime(2030),
                                      );
                                      if (picked != null) {
                                        setState(() => toDate = picked);
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            icon: const Icon(Icons.bolt, color: Colors.white),
                            label: const Text(
                              'Sinh buổi học',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onPressed: selectedClass == null
                                ? null
                                : () async {
                                    try {
                                      final genService = await ref.read(
                                        sessionGenerationServiceProvider.future,
                                      );
                                      final res = await genService
                                          .generateForClass(
                                            classId: selectedClass!.id!,
                                            fromDate: fromDate,
                                            toDate: toDate,
                                          );

                                      if (context.mounted) {
                                        Navigator.of(context).pop();
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Đã sinh ${res.createdCount} buổi học mới cho ${selectedClass!.tenLop}',
                                            ),
                                          ),
                                        );
                                        ref.invalidate(
                                          dashboardControllerProvider,
                                        );
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(content: Text('Lỗi: $e')),
                                        );
                                      }
                                    }
                                  },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _showFinalizeTuitionBottomSheet(BuildContext context, WidgetRef ref) {
    final monthStr = DateFormat('yyyy-MM').format(DateTime.now());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Consumer(
              builder: (context, ref, _) {
                final classesAsync = ref.watch(classListControllerProvider);

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'CHỐT HỌC PHÍ THÁNG $monthStr',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: AppColors.textMuted,
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const Divider(color: AppColors.border),
                    classesAsync.when(
                      data: (classes) {
                        final activeClasses = classes
                            .where((c) => !c.daLuuTru)
                            .toList();
                        if (activeClasses.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(
                              child: Text('Không có lớp học đang hoạt động.'),
                            ),
                          );
                        }

                        return Flexible(
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: activeClasses.length,
                            separatorBuilder: (_, __) => const Divider(
                              color: AppColors.border,
                              height: 1,
                            ),
                            itemBuilder: (context, index) {
                              final cls = activeClasses[index];
                              return ListTile(
                                title: Text(
                                  cls.tenLop,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  'Môn ${cls.monHoc ?? "—"} • Khối ${cls.khoi ?? "—"}',
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                                trailing: const Icon(
                                  Icons.arrow_forward_ios,
                                  size: 14,
                                  color: AppColors.textMuted,
                                ),
                                onTap: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (dlgCtx) => AlertDialog(
                                      title: const Text(
                                        'Xác nhận chốt học phí',
                                      ),
                                      content: Text(
                                        'Bạn có chắc muốn chốt học phí tháng $monthStr cho cả lớp ${cls.tenLop}?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(dlgCtx).pop(false),
                                          child: const Text('Hủy'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () =>
                                              Navigator.of(dlgCtx).pop(true),
                                          child: const Text('Chốt ngay'),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirm == true && context.mounted) {
                                    try {
                                      final invoiceService = await ref.read(
                                        invoiceServiceProvider.future,
                                      );
                                      final overviewService = await ref.read(
                                        classMonthTuitionOverviewServiceProvider
                                            .future,
                                      );
                                      final tuitionOverview =
                                          await overviewService.getOverview(
                                            cls.id!,
                                            monthStr,
                                          );
                                      final readyIds = tuitionOverview
                                          .studentRows
                                          .where(
                                            (row) =>
                                                row.state ==
                                                ClassStudentTuitionState
                                                    .PREVIEW_READY,
                                          )
                                          .map((row) => row.student.id!)
                                          .toSet();
                                      if (readyIds.isEmpty) {
                                        throw Exception(
                                          'Chưa có học sinh đủ điều kiện chốt. Hãy hoàn tất điểm danh và kiểm tra học phí trong lớp.',
                                        );
                                      }
                                      final invoices = await invoiceService
                                          .finalizeClassInvoices(
                                            cls.id!,
                                            monthStr,
                                            studentIdsToFinalize: readyIds,
                                          );

                                      if (context.mounted) {
                                        Navigator.of(context).pop();
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Đã chốt ${invoices.length} hóa đơn học phí cho lớp ${cls.tenLop}',
                                            ),
                                          ),
                                        );
                                        ref.invalidate(
                                          dashboardControllerProvider,
                                        );
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Không thể chốt: ${e.toString().replaceAll("Exception: ", "")}',
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  }
                                },
                              );
                            },
                          ),
                        );
                      },
                      loading: () => const AppLoadingState(),
                      error: (e, _) => Text('Lỗi: $e'),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _handleExportReportPdf(BuildContext context, WidgetRef ref) async {
    final now = DateTime.now();
    final monthStr = DateFormat('yyyy-MM').format(now);
    final scope = ReportScope.forMonth(month: monthStr);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đang tạo báo cáo PDF tháng $monthStr...')),
    );

    try {
      final reportService = await ref.read(reportServiceProvider.future);
      final summary = await reportService.generateReport(scope);
      final pdfExporter = ref.read(reportPdfExporterProvider);

      await pdfExporter.export(summary);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi xuất PDF: $e')));
      }
    }
  }

  void _handleWarningTap(
    BuildContext context,
    WidgetRef ref,
    DashboardWarning warning,
  ) {
    switch (warning.type) {
      case DashboardWarningType.unassignedStudents:
        ref
            .read(navigationControllerProvider.notifier)
            .goTo(AppDestinationId.classes);
        break;
      case DashboardWarningType.overdueAttendance:
        final overviewAsync = ref.read(dashboardControllerProvider);
        if (overviewAsync.hasValue) {
          _showPendingAttendanceBottomSheet(context, ref, overviewAsync.value!);
        }
        break;
      case DashboardWarningType.missingTuitionPolicy:
        ref
            .read(navigationControllerProvider.notifier)
            .goTo(AppDestinationId.classes);
        break;
    }
  }
}

class DashboardTodayTimelineItem extends StatelessWidget {
  final DashboardTodaySession item;
  final bool isFirst;
  final bool isLast;
  final String statusText;
  final Color statusColor;
  final VoidCallback? onTap;

  const DashboardTodayTimelineItem({
    super.key,
    required this.item,
    required this.isFirst,
    required this.isLast,
    required this.statusText,
    required this.statusColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final s = item.session;

    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 46),
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            // Left Rail Timeline Column
            SizedBox(
              width: 24,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: Column(
                      children: [
                        Expanded(
                          child: Container(
                            width: isFirst ? 0 : 2,
                            color: AppColors.border,
                          ),
                        ),
                        Expanded(
                          child: Container(
                            width: isLast ? 0 : 2,
                            color: AppColors.border,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Time Column
            SizedBox(
              width: 78,
              child: Text(
                '${s.gioBatDau}–${s.gioKetThuc}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Class Name
            Expanded(
              child: Text(
                item.className,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),

            // Status Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
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
          ],
        ),
      ),
    );
  }
}

class DashboardRecentActivitiesExpander extends StatefulWidget {
  final List<DashboardActivity> activities;

  const DashboardRecentActivitiesExpander({
    super.key,
    required this.activities,
  });

  @override
  State<DashboardRecentActivitiesExpander> createState() =>
      _DashboardRecentActivitiesExpanderState();
}

class _DashboardRecentActivitiesExpanderState
    extends State<DashboardRecentActivitiesExpander> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final activities = widget.activities;

    if (activities.isEmpty) {
      return AppSectionCard(
        padding: const EdgeInsets.all(14),
        child: Center(
          child: Text(
            l10n.dashboardNoActivity,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ),
      );
    }

    final latestStr = DateFormat(
      'HH:mm • dd/MM',
    ).format(activities.first.timestamp);
    final displayedActivities = activities.take(8).toList();

    return AppSectionCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Row(
              children: [
                const Icon(
                  Icons.history,
                  size: 18,
                  color: AppColors.cyanAccent,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.dashboardRecentActivity,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (!_isExpanded)
                        Text(
                          l10n.dashboardLatestActivity(latestStr),
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSelected,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    '${activities.length}',
                    style: const TextStyle(
                      color: AppColors.cyanAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  _isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: AppColors.cyanAccent,
                  size: 20,
                ),
              ],
            ),
          ),

          // Expanded Content
          if (_isExpanded) ...[
            const SizedBox(height: 8),
            const Divider(color: AppColors.border, height: 1),
            const SizedBox(height: 4),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: displayedActivities.length,
              separatorBuilder: (_, __) =>
                  const Divider(color: AppColors.border, height: 1),
              itemBuilder: (context, index) {
                final act = displayedActivities[index];

                IconData icon;
                Color color;

                switch (act.type) {
                  case DashboardActivityType.paymentRecorded:
                    icon = Icons.payments_outlined;
                    color = AppColors.success;
                    break;
                  case DashboardActivityType.paymentCorrection:
                    icon = Icons.edit_note;
                    color = AppColors.warning;
                    break;
                  case DashboardActivityType.sessionCompleted:
                    icon = Icons.task_alt;
                    color = AppColors.cyanAccent;
                    break;
                  case DashboardActivityType.tuitionFinalized:
                    icon = Icons.fact_check_outlined;
                    color = AppColors.primary;
                    break;
                  case DashboardActivityType.attendanceCorrection:
                    icon = Icons.edit_calendar;
                    color = AppColors.warning;
                    break;
                }

                final timeStr = DateFormat('HH:mm dd/MM').format(act.timestamp);

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(icon, color: color, size: 16),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              act.title,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (act.subtitle.isNotEmpty)
                              Text(
                                act.subtitle,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        timeStr,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
