import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/common_widgets/app_empty_state.dart';
import '../../../app/common_widgets/app_error_state.dart';
import '../../../app/common_widgets/app_loading_state.dart';
import '../../../app/common_widgets/navy_components.dart';
import '../../../app/design_system/app_theme.dart';
import '../../../app/navigation/app_global_drawer.dart';
import '../../../app/navigation/ui_keys.dart';
import '../../../l10n/app_localizations.dart';
import '../../attendance/presentation/attendance_page.dart';
import '../domain/class_filter.dart';
import '../domain/class_list_overview.dart';
import 'class_detail_page.dart';
import 'class_form_bottom_sheet.dart';
import 'class_list_overview_controller.dart';

class ClassListPage extends ConsumerStatefulWidget {
  const ClassListPage({super.key});

  @override
  ConsumerState<ClassListPage> createState() => _ClassListPageState();
}

class _ClassListPageState extends ConsumerState<ClassListPage> {
  ClassFilter _filter = ClassFilter.active;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final overviewAsync = ref.watch(classListOverviewControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const AppGlobalDrawer(),
      appBar: AppBar(
        leading: const GlobalMenuButton(),
        title: Text(l10n.navClasses),
        actions: [
          Tooltip(
            message: _filter == ClassFilter.active
                ? l10n.classFilterActive
                : l10n.classFilterStopped,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _filter == ClassFilter.active
                      ? l10n.classFilterActive
                      : l10n.classFilterStopped,
                  style: const TextStyle(fontSize: 11),
                ),
                Switch.adaptive(
                  key: _filter == ClassFilter.active
                      ? UiKeys.classActiveFilter
                      : UiKeys.classArchivedFilter,
                  value: _filter == ClassFilter.active,
                  onChanged: (active) {
                    final next = active
                        ? ClassFilter.active
                        : ClassFilter.archived;
                    setState(() => _filter = next);
                    ref
                        .read(classListOverviewControllerProvider.notifier)
                        .setFilter(next);
                  },
                ),
              ],
            ),
          ),
          IconButton(
            key: UiKeys.classAddButton,
            icon: const Icon(Icons.add_rounded),
            tooltip: l10n.classFormTitleAdd,
            onPressed: () async {
              await showClassFormBottomSheet(context);
              ref.read(classListOverviewControllerProvider.notifier).refresh();
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (value) {
              if (value == 'refresh') {
                ref
                    .read(classListOverviewControllerProvider.notifier)
                    .refresh();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'refresh',
                child: Row(
                  children: [
                    Icon(
                      Icons.refresh_rounded,
                      size: 18,
                      color: AppColors.textPrimary,
                    ),
                    SizedBox(width: 8),
                    Text('Làm mới'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: overviewAsync.when(
        data: (overview) => RefreshIndicator(
          onRefresh: () =>
              ref.read(classListOverviewControllerProvider.notifier).refresh(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. 2-State Filter Toggle

                // 2. Active Mode KPIs or Archived Mode Header
                if (_filter == ClassFilter.active) ...[
                  _buildKpiGrid(context, l10n, overview),
                  const SizedBox(height: 16),
                ] else ...[
                  _buildArchivedHeader(l10n, overview),
                  const SizedBox(height: 16),
                ],

                // 3. Class List Section Header
                _buildListHeader(l10n, overview),
                const SizedBox(height: 10),

                // 4. Class Cards List or Empty State
                if (overview.rows.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: AppEmptyState(
                      title: _filter == ClassFilter.archived
                          ? l10n.classEmptyStoppedTitle
                          : l10n.classEmptyActiveTitle,
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: overview.rows.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final row = overview.rows[index];
                      final currentGrade = row.classEntity.khoi;
                      final prevGrade = index > 0
                          ? overview.rows[index - 1].classEntity.khoi
                          : -999;
                      final showHeader =
                          index == 0 || prevGrade != currentGrade;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (showHeader)
                            Padding(
                              padding: EdgeInsets.only(
                                top: index == 0 ? 2 : 10,
                                bottom: 6,
                              ),
                              child: Text(
                                currentGrade != null
                                    ? l10n.classGradeHeader(currentGrade)
                                    : l10n.classUnknownGrade,
                                style: const TextStyle(
                                  color: AppColors.cyanAccent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          _buildClassOperationalCard(context, l10n, row),
                        ],
                      );
                    },
                  ),

                // 5. "Cần xử lý" (Business Warnings) Section
                if (_filter == ClassFilter.active &&
                    overview.warnings.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _buildWarningsSection(context, l10n, overview.warnings),
                ],
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
        loading: () => const AppLoadingState(),
        error: (error, stack) => AppErrorState(
          title: l10n.commonError,
          error: error.toString(),
          onRetry: () =>
              ref.read(classListOverviewControllerProvider.notifier).refresh(),
        ),
      ),
    );
  }

  Widget _buildFilterToggle(AppLocalizations l10n) {
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<ClassFilter>(
        segments: [
          ButtonSegment<ClassFilter>(
            value: ClassFilter.active,
            icon: const Icon(Icons.class_outlined, size: 18),
            label: Text(
              l10n.classFilterActive,
              key: UiKeys.classActiveFilter,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          ButtonSegment<ClassFilter>(
            value: ClassFilter.archived,
            icon: const Icon(Icons.archive_outlined, size: 18),
            label: Text(
              l10n.classFilterStopped,
              key: UiKeys.classArchivedFilter,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
        selected: {_filter},
        emptySelectionAllowed: false,
        multiSelectionEnabled: false,
        onSelectionChanged: (newSelection) {
          if (newSelection.isNotEmpty) {
            final selectedVal = newSelection.first;
            setState(() => _filter = selectedVal);
            ref
                .read(classListOverviewControllerProvider.notifier)
                .setFilter(selectedVal);
          }
        },
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.primary;
            }
            return AppColors.surface;
          }),
          foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
            if (states.contains(WidgetState.selected)) {
              return Colors.white;
            }
            return AppColors.textSecondary;
          }),
          iconColor: WidgetStateProperty.resolveWith<Color>((states) {
            if (states.contains(WidgetState.selected)) {
              return Colors.white;
            }
            return AppColors.textSecondary;
          }),
          side: WidgetStateProperty.all(
            const BorderSide(color: AppColors.border),
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }

  Widget _buildKpiGrid(
    BuildContext context,
    AppLocalizations l10n,
    ClassListOverview overview,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 340;
        final kpis = [
          _KpiData(
            label: l10n.classKpiActive,
            value: overview.activeClassCount.toString(),
            icon: Icons.school_outlined,
            accentColor: AppColors.cyanAccent,
          ),
          _KpiData(
            label: l10n.classKpiTodaySessions,
            value: overview.todaySessionCount.toString(),
            icon: Icons.calendar_today_outlined,
            accentColor: AppColors.cyanAccent,
          ),
          _KpiData(
            label: l10n.classKpiPendingAttendance,
            value: overview.pendingAttendanceCount.toString(),
            icon: Icons.fact_check_outlined,
            accentColor: AppColors.warning,
          ),
          _KpiData(
            label: l10n.classKpiMissingTuition,
            value: overview.missingTuitionPolicyCount.toString(),
            icon: Icons.receipt_long_outlined,
            accentColor: AppColors.error,
          ),
        ];

        if (isNarrow) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: _buildKpiCard(kpis[0])),
                  const SizedBox(width: 8),
                  Expanded(child: _buildKpiCard(kpis[1])),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _buildKpiCard(kpis[2])),
                  const SizedBox(width: 8),
                  Expanded(child: _buildKpiCard(kpis[3])),
                ],
              ),
            ],
          );
        } else {
          return Row(
            children: kpis
                .map(
                  (kpi) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: _buildKpiCard(kpi),
                    ),
                  ),
                )
                .toList(),
          );
        }
      },
    );
  }

  Widget _buildKpiCard(_KpiData kpi) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(kpi.icon, size: 18, color: kpi.accentColor),
          const SizedBox(height: 6),
          Text(
            kpi.value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            kpi.label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildArchivedHeader(
    AppLocalizations l10n,
    ClassListOverview overview,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.archive_outlined,
            color: AppColors.textMuted,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            l10n.classCountStopped(overview.rows.length),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListHeader(AppLocalizations l10n, ClassListOverview overview) {
    final countText = _filter == ClassFilter.archived
        ? l10n.classCountStopped(overview.rows.length)
        : l10n.classCountActive(overview.rows.length);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          l10n.classListTitle,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          countText,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildClassOperationalCard(
    BuildContext context,
    AppLocalizations l10n,
    ClassOperationalRow row,
  ) {
    final cls = row.classEntity;
    final isStopped = cls.daLuuTru;
    final iconColor = _getDeterministicClassColor(cls.id ?? 0, cls.tenLop);

    final (statusLabel, statusColor) = _getBadgeDetails(row.status, l10n);

    return AppSectionCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(12),
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ClassDetailPage(classId: cls.id!),
          ),
        );
        if (context.mounted) {
          ref.read(classListOverviewControllerProvider.notifier).refresh();
        }
      },
      child: Row(
        children: [
          // Class icon colored square box
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isStopped
                  ? AppColors.textMuted.withValues(alpha: 0.15)
                  : iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isStopped ? Icons.folder_off_outlined : Icons.school_rounded,
              color: isStopped ? AppColors.textMuted : iconColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),

          // Center details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cls.tenLop,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    decoration: isStopped ? TextDecoration.lineThrough : null,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                if (row.scheduleText.isNotEmpty)
                  Text(
                    row.scheduleText,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 2),
                Text(
                  l10n.classStudentCount(row.activeStudentCount),
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Right status badge & secondary text
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    row.secondaryStatusText,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textMuted,
                    size: 16,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWarningsSection(
    BuildContext context,
    AppLocalizations l10n,
    List<ClassOperationalWarning> warnings,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.warning,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  l10n.classNeedsAction,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            InkWell(
              onTap: () => _showWarningsBottomSheet(context, l10n, warnings),
              child: Text(
                l10n.classSeeAll,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        AppSectionCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Column(
            children: warnings.map((w) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: AppColors.warning,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        w.message,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  void _showWarningsBottomSheet(
    BuildContext context,
    AppLocalizations l10n,
    List<ClassOperationalWarning> warnings,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceHigh,
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
                    Text(
                      l10n.classNeedsAction,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textMuted),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(color: AppColors.border),
                const SizedBox(height: 8),
                ...warnings.map(
                  (w) => ListTile(
                    leading: const Icon(
                      Icons.warning_amber_rounded,
                      color: AppColors.warning,
                    ),
                    title: Text(
                      w.message,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: AppColors.textMuted,
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      if (w.type == ClassWarningType.overdueAttendance &&
                          w.relatedIds != null &&
                          w.relatedIds!.isNotEmpty) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                AttendancePage(sessionId: w.relatedIds!.first),
                          ),
                        );
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
  }

  Color _getDeterministicClassColor(int id, String name) {
    final colors = [
      AppColors.cyanAccent,
      AppColors.primary,
      AppColors.success,
      const Color(0xFF9D4EDD), // Purple
      AppColors.warning,
      const Color(0xFF2A9D8F), // Teal
    ];
    final hash = (id * 31 + name.hashCode).abs();
    return colors[hash % colors.length];
  }

  (String, Color) _getBadgeDetails(
    ClassOperationalStatus status,
    AppLocalizations l10n,
  ) {
    switch (status) {
      case ClassOperationalStatus.needsAttendance:
        return (l10n.classStatusNeedsAttendance, AppColors.warning);
      case ClassOperationalStatus.inProgress:
        return (l10n.classStatusInProgress, AppColors.cyanAccent);
      case ClassOperationalStatus.upcomingToday:
        return (l10n.classStatusUpcoming, AppColors.primary);
      case ClassOperationalStatus.completedToday:
        return (l10n.classStatusCompleted, AppColors.success);
      case ClassOperationalStatus.missingTuitionPolicy:
        return (l10n.classStatusMissingTuition, AppColors.error);
      case ClassOperationalStatus.hasDebt:
        return (l10n.classStatusDebt, AppColors.error);
      case ClassOperationalStatus.archived:
        return (l10n.classFilterStopped, AppColors.textMuted);
      case ClassOperationalStatus.normal:
        return (l10n.classFilterActive, AppColors.primary);
    }
  }
}

class _KpiData {
  final String label;
  final String value;
  final IconData icon;
  final Color accentColor;

  const _KpiData({
    required this.label,
    required this.value,
    required this.icon,
    required this.accentColor,
  });
}
