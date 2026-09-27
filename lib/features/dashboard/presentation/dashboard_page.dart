import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../app/common_widgets/app_loading_state.dart';
import '../../../app/design_system/app_semantic_colors.dart';
import '../../../app/navigation/app_destination.dart';
import '../../../app/navigation/app_global_drawer.dart';
import '../../../app/navigation/navigation_controller.dart';
import '../../../app/navigation/ui_keys.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../l10n/app_localizations.dart';
import '../../attendance/presentation/attendance_page.dart';
import '../../classes/domain/class.dart';
import '../../classes/presentation/class_controller.dart';
import '../../classes/presentation/class_detail_page.dart';
import '../../reports/presentation/report_controller.dart';
import '../../reports/presentation/reports_page.dart';
import '../../sessions/domain/class_session.dart';
import '../../sessions/domain/session_service.dart';
import '../../students/domain/student.dart';
import '../../students/presentation/student_controller.dart';
import '../../students/presentation/student_detail_page.dart';

final todaySessionsProvider = FutureProvider<List<ClassSession>>((ref) async {
  final sessionService = await ref.watch(sessionServiceProvider.future);
  final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
  return sessionService.getSessionsInDateRange(
    fromDate: todayStr,
    toDate: todayStr,
  );
});

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final semantics =
        theme.extension<AppSemanticColors>() ?? AppSemanticColors.dark;
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();

    final classesAsync = ref.watch(classListControllerProvider);
    final studentsAsync = ref.watch(studentListControllerProvider);
    final todaySessionsAsync = ref.watch(todaySessionsProvider);
    final reportSummaryAsync = ref.watch(reportSummaryProvider);

    final activeClassesCount = classesAsync.when(
      data: (list) => list.where((c) => !c.daLuuTru).length,
      loading: () => 0,
      error: (_, __) => 0,
    );

    final activeStudentsCount = studentsAsync.when(
      data: (list) => list.where((s) => !s.daLuuTru).length,
      loading: () => 0,
      error: (_, __) => 0,
    );

    return Scaffold(
      drawer: const AppGlobalDrawer(),
      appBar: AppBar(
        leading: const GlobalMenuButton(),
        title: Text(l10n.dashboardTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(todaySessionsProvider);
              ref.invalidate(classListControllerProvider);
              ref.invalidate(studentListControllerProvider);
              ref.invalidate(reportSummaryProvider);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- A. GREETING HEADER ---
            Card(
              color: colorScheme.surfaceContainerHigh,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: colorScheme.primaryContainer,
                      child: Icon(
                        Icons.waving_hand,
                        color: colorScheme.onPrimaryContainer,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Xin chào thầy!',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            DateFormatter.formatDisplayDate(now),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // --- B. GLOBAL SEARCH BAR ---
            TextField(
              key: UiKeys.dashboardSearchInput,
              controller: _searchController,
              decoration: InputDecoration(
                hintText: l10n.dashboardSearchPlaceholder,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
            ),

            if (_searchQuery.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildSearchResults(
                context,
                l10n: l10n,
                query: _searchQuery,
                classes: classesAsync.asData?.value ?? [],
                students: studentsAsync.asData?.value ?? [],
              ),
            ],

            const SizedBox(height: 20),

            // --- C. QUICK ACTIONS ---
            Text(
              'Thao tác nhanh',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildCompactQuickAction(
                  context,
                  icon: Icons.check_circle_outline,
                  label: 'Điểm danh',
                  color: semantics.attendancePresent,
                  onTap: () {
                    ref
                        .read(navigationControllerProvider.notifier)
                        .goTo(AppDestinationId.classes);
                  },
                ),
                _buildCompactQuickAction(
                  context,
                  icon: Icons.people_outline,
                  label: 'Học sinh',
                  color: colorScheme.primary,
                  onTap: () {
                    ref
                        .read(navigationControllerProvider.notifier)
                        .goTo(AppDestinationId.students);
                  },
                ),
                _buildCompactQuickAction(
                  context,
                  icon: Icons.class_outlined,
                  label: 'Lớp học',
                  color: colorScheme.secondary,
                  onTap: () {
                    ref
                        .read(navigationControllerProvider.notifier)
                        .goTo(AppDestinationId.classes);
                  },
                ),
                _buildCompactQuickAction(
                  context,
                  icon: Icons.payments_outlined,
                  label: 'Học phí',
                  color: semantics.tuitionDraft,
                  onTap: () {
                    ref
                        .read(navigationControllerProvider.notifier)
                        .goTo(AppDestinationId.tuition);
                  },
                ),
                _buildCompactQuickAction(
                  context,
                  icon: Icons.bar_chart_outlined,
                  label: 'Báo cáo',
                  color: semantics.warning,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ReportsPage()),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 20),

            // --- D. LỊCH HÔM NAY ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Lịch hôm nay',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  'Lớp học: $activeClassesCount | Học sinh: $activeStudentsCount',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            todaySessionsAsync.when(
              data: (sessions) {
                if (sessions.isEmpty) {
                  return Card(
                    color: colorScheme.surfaceContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Center(
                        child: Text(
                          'Hôm nay không có buổi học nào',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  );
                }

                return Column(
                  children: sessions.map((session) {
                    final isDone = session.trangThai == SessionStatus.DA_HOC;
                    final isCanceled =
                        session.trangThai == SessionStatus.HUY ||
                        session.trangThai == SessionStatus.NGHI_LE;

                    Color statusColor = semantics.warning;
                    String statusLabel = 'Chưa điểm danh';
                    if (isDone) {
                      statusColor = semantics.success;
                      statusLabel = 'Đã chốt';
                    } else if (isCanceled) {
                      statusColor = colorScheme.outline;
                      statusLabel = session.trangThai.name;
                    }

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: statusColor.withValues(alpha: 0.15),
                          child: Icon(
                            Icons.schedule,
                            color: statusColor,
                            size: 20,
                          ),
                        ),
                        title: Consumer(
                          builder: (context, ref, _) {
                            final clsAsync = ref.watch(
                              classDetailProvider(session.idLop),
                            );
                            return clsAsync.when(
                              data: (c) => Text(
                                c?.tenLop ?? 'Lớp #${session.idLop}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              loading: () => Text('Lớp #${session.idLop}'),
                              error: (_, __) => Text('Lớp #${session.idLop}'),
                            );
                          },
                        ),
                        subtitle: Text(
                          '${session.gioBatDau} - ${session.gioKetThuc} • ${session.loai.name}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            statusLabel,
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        onTap: () {
                          if (session.id != null && !isCanceled) {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    AttendancePage(sessionId: session.id!),
                              ),
                            );
                          } else {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    ClassDetailPage(classId: session.idLop),
                              ),
                            );
                          }
                        },
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const AppLoadingState(),
              error: (err, _) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text('Lỗi tải lịch hôm nay: $err'),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // --- E. HỌC PHÍ THÁNG KPI SUMMARY ---
            Text(
              'Học phí tháng này',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 10),
            reportSummaryAsync.when(
              data: (summary) {
                final fmt = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
                return Row(
                  children: [
                    Expanded(
                      child: _buildMetricTile(
                        context,
                        title: 'Phải thu',
                        value: fmt.format(summary.financial.totalInvoiced),
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildMetricTile(
                        context,
                        title: 'Đã thu',
                        value: fmt.format(summary.financial.totalPaid),
                        color: semantics.success,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildMetricTile(
                        context,
                        title: 'Còn nợ',
                        value: fmt.format(
                          summary.financial.totalOutstandingDebt,
                        ),
                        color: semantics.error,
                      ),
                    ),
                  ],
                );
              },
              loading: () => const AppLoadingState(),
              error: (_, __) => Row(
                children: [
                  Expanded(
                    child: _buildMetricTile(
                      context,
                      title: 'Phải thu',
                      value: '0 đ',
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMetricTile(
                      context,
                      title: 'Đã thu',
                      value: '0 đ',
                      color: semantics.success,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMetricTile(
                      context,
                      title: 'Còn nợ',
                      value: '0 đ',
                      color: semantics.error,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactQuickAction(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 64,
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile(
    BuildContext context, {
    required String title,
    required String value,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults(
    BuildContext context, {
    required AppLocalizations l10n,
    required String query,
    required List<ClassEntity> classes,
    required List<Student> students,
  }) {
    final theme = Theme.of(context);
    final lowerQuery = query.toLowerCase();

    final matchedClasses = classes
        .where(
          (c) => !c.daLuuTru && c.tenLop.toLowerCase().contains(lowerQuery),
        )
        .toList();

    final matchedStudents = students
        .where((s) => !s.daLuuTru && s.hoTen.toLowerCase().contains(lowerQuery))
        .toList();

    if (matchedClasses.isEmpty && matchedStudents.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            l10n.searchNoResults,
            style: TextStyle(color: theme.colorScheme.outline),
          ),
        ),
      );
    }

    return Card(
      elevation: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              l10n.searchResults,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(height: 1),
          if (matchedClasses.isNotEmpty) ...[
            ...matchedClasses.map(
              (c) => ListTile(
                leading: const Icon(Icons.class_outlined),
                title: Text(c.tenLop),
                subtitle: Text(l10n.navClasses),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ClassDetailPage(classId: c.id!),
                    ),
                  );
                },
              ),
            ),
          ],
          if (matchedStudents.isNotEmpty) ...[
            ...matchedStudents.map(
              (s) => ListTile(
                leading: const Icon(Icons.person_outline),
                title: Text(s.hoTen),
                subtitle: Text(l10n.navStudents),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => StudentDetailPage(studentId: s.id!),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
