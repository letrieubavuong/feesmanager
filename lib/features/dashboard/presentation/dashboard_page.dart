import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../app/common_widgets/app_loading_state.dart';
import '../../../app/localization/app_formatter.dart';
import '../../../app/navigation/app_destination.dart';
import '../../../app/navigation/app_global_drawer.dart';
import '../../../app/navigation/navigation_controller.dart';
import '../../../app/navigation/ui_keys.dart';
import '../../classes/domain/class.dart';
import '../../classes/presentation/class_controller.dart';
import '../../classes/presentation/class_detail_page.dart';
import '../../reports/presentation/reports_page.dart';
import '../../sessions/domain/class_session.dart';
import '../../sessions/domain/session_service.dart';
import '../../students/domain/student.dart';
import '../../students/presentation/student_controller.dart';
import '../../students/presentation/student_detail_page.dart';
import '../../students/presentation/student_form_page.dart';

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
    final isEn = Localizations.localeOf(context).languageCode == 'en';
    final now = DateTime.now();

    final classesAsync = ref.watch(classListControllerProvider);
    final studentsAsync = ref.watch(studentListControllerProvider);
    final todaySessionsAsync = ref.watch(todaySessionsProvider);

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
        title: Text(isEn ? 'Home' : 'Trang chủ'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- A. HEADER GREETING ---
            Card(
              color: theme.colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: theme.colorScheme.primary,
                      child: Icon(
                        Icons.waving_hand,
                        color: theme.colorScheme.onPrimary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEn ? 'Welcome, Teacher!' : 'Xin chào, Thầy/Cô!',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AppFormatter.formatDate(now, context: context),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer
                                  .withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // --- B. GLOBAL SEARCH BAR ---
            TextField(
              key: UiKeys.dashboardSearchInput,
              controller: _searchController,
              decoration: InputDecoration(
                hintText: isEn
                    ? 'Search students or classes...'
                    : 'Tìm học sinh hoặc lớp học...',
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
                query: _searchQuery,
                classes: classesAsync.asData?.value ?? [],
                students: studentsAsync.asData?.value ?? [],
                isEn: isEn,
              ),
            ],

            const SizedBox(height: 24),

            // --- C. CENTER OVERVIEW / KPIS ---
            Text(
              isEn ? 'Center Overview' : 'Tổng quan trung tâm',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildKpiCard(
                    context,
                    title: isEn ? 'Active Classes' : 'Lớp học đang mở',
                    value: '$activeClassesCount',
                    icon: Icons.class_outlined,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildKpiCard(
                    context,
                    title: isEn ? 'Active Students' : 'Học sinh đang học',
                    value: '$activeStudentsCount',
                    icon: Icons.people_outline,
                    color: theme.colorScheme.secondary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // --- D. QUICK ACTIONS ---
            Text(
              isEn ? 'Quick Actions' : 'Thao tác nhanh',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildQuickActionButton(
                  key: UiKeys.dashboardQuickAddStudent,
                  context: context,
                  icon: Icons.person_add_alt_1_outlined,
                  label: isEn ? 'Add Student' : 'Thêm học sinh',
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const StudentFormPage(),
                      ),
                    );
                    ref.invalidate(studentListControllerProvider);
                  },
                ),
                _buildQuickActionButton(
                  key: UiKeys.dashboardQuickManageClasses,
                  context: context,
                  icon: Icons.class_outlined,
                  label: isEn ? 'Manage Classes' : 'Quản lý lớp học',
                  onTap: () {
                    ref
                        .read(navigationControllerProvider.notifier)
                        .goTo(AppDestinationId.classes);
                  },
                ),
                _buildQuickActionButton(
                  key: UiKeys.dashboardQuickViewTuition,
                  context: context,
                  icon: Icons.payments_outlined,
                  label: isEn ? 'View Tuition' : 'Xem học phí',
                  onTap: () {
                    ref
                        .read(navigationControllerProvider.notifier)
                        .goTo(AppDestinationId.tuition);
                  },
                ),
                _buildQuickActionButton(
                  key: UiKeys.dashboardQuickViewReports,
                  context: context,
                  icon: Icons.bar_chart_outlined,
                  label: isEn ? 'View Reports' : 'Xem báo cáo',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ReportsPage()),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 24),

            // --- E. TODAY'S SCHEDULE ---
            Text(
              isEn ? "Today's Schedule" : 'Lịch học hôm nay',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            todaySessionsAsync.when(
              data: (sessions) {
                if (sessions.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Center(
                        child: Text(
                          isEn
                              ? 'No sessions scheduled for today.'
                              : 'Hôm nay không có buổi học nào.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: sessions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final session = sessions[index];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: theme.colorScheme.primaryContainer,
                          child: Icon(
                            Icons.schedule,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        title: Text(
                          '${isEn ? "Class #" : "Lớp ID "}${session.idLop}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${session.ngay} | ${session.gioBatDau} - ${session.gioKetThuc}',
                        ),
                        trailing: Chip(
                          label: Text(session.trangThai.name),
                          visualDensity: VisualDensity.compact,
                        ),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  ClassDetailPage(classId: session.idLop),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
              loading: () => const AppLoadingState(),
              error: (err, _) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text('Error loading today\'s schedule: $err'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required Key key,
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final width = (MediaQuery.of(context).size.width - 44) / 2;

    return SizedBox(
      width: width > 160 ? width : 160,
      child: OutlinedButton.icon(
        key: key,
        onPressed: onTap,
        icon: Icon(icon, size: 20),
        label: Text(label, overflow: TextOverflow.ellipsis),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          alignment: Alignment.centerLeft,
          side: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
    );
  }

  Widget _buildSearchResults(
    BuildContext context, {
    required String query,
    required List<ClassEntity> classes,
    required List<Student> students,
    required bool isEn,
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
            isEn
                ? 'No students or classes found.'
                : 'Không tìm thấy học sinh hoặc lớp học nào.',
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
              isEn ? 'Search Results' : 'Kết quả tìm kiếm',
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
                subtitle: Text(isEn ? 'Class' : 'Lớp học'),
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
                subtitle: Text(isEn ? 'Student' : 'Học sinh'),
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
