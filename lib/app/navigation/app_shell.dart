import 'package:flutter/material.dart';
import '../../features/students/presentation/student_list_page.dart';
import '../../features/classes/presentation/class_list_page.dart';
import '../../features/tuition/presentation/global_tuition_page.dart';
import '../../features/reports/presentation/reports_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  static const List<NavigationItem> _items = [
    NavigationItem(
      label: 'Trang chủ',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
      content: Center(child: Text('Trang chủ - Dashboard Placeholder')),
    ),
    NavigationItem(
      label: 'Học sinh',
      icon: Icons.people_outline,
      selectedIcon: Icons.people,
      content: StudentListPage(),
    ),
    NavigationItem(
      label: 'Lớp học',
      icon: Icons.class_outlined,
      selectedIcon: Icons.class_,
      content: ClassListPage(),
    ),
    NavigationItem(
      label: 'Lịch học',
      icon: Icons.calendar_today_outlined,
      selectedIcon: Icons.calendar_today,
      content: PlaceholderPage(title: 'Lịch học'),
    ),
    NavigationItem(
      label: 'Điểm danh',
      icon: Icons.how_to_reg_outlined,
      selectedIcon: Icons.how_to_reg,
      content: PlaceholderPage(title: 'Điểm danh'),
    ),
    NavigationItem(
      label: 'Học phí',
      icon: Icons.payments_outlined,
      selectedIcon: Icons.payments,
      content: GlobalTuitionPage(),
    ),
    NavigationItem(
      label: 'Báo cáo',
      icon: Icons.bar_chart_outlined,
      selectedIcon: Icons.bar_chart,
      content: ReportsPage(),
    ),
    NavigationItem(
      label: 'Cài đặt',
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
      content: PlaceholderPage(title: 'Cài đặt'),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final useSidebar = width >= 600;

    return Scaffold(
      body: Row(
        children: [
          if (useSidebar)
            NavigationRail(
              extended: width >= 800,
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) =>
                  setState(() => _selectedIndex = index),
              labelType: width >= 800
                  ? NavigationRailLabelType.none
                  : NavigationRailLabelType.all,
              destinations: _items
                  .map(
                    (item) => NavigationRailDestination(
                      icon: Icon(item.icon),
                      selectedIcon: Icon(item.selectedIcon),
                      label: Text(item.label),
                    ),
                  )
                  .toList(),
            ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: _items[_selectedIndex].content),
        ],
      ),
      bottomNavigationBar: useSidebar
          ? null
          : NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) =>
                  setState(() => _selectedIndex = index),
              destinations: _items
                  .map(
                    (item) => NavigationDestination(
                      icon: Icon(item.icon),
                      selectedIcon: Icon(item.selectedIcon),
                      label: item.label,
                    ),
                  )
                  .toList(),
            ),
    );
  }
}

class NavigationItem {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Widget content;

  const NavigationItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.content,
  });
}

class PlaceholderPage extends StatelessWidget {
  final String title;
  const PlaceholderPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.construction,
              size: 64,
              color: Theme.of(context).disabledColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Chức năng $title',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text('Sẽ được triển khai ở phase tiếp theo.'),
          ],
        ),
      ),
    );
  }
}
