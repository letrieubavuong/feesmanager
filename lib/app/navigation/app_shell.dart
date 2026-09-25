import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/classes/presentation/class_list_page.dart';
import '../../features/dashboard/presentation/dashboard_page.dart';
import '../../features/reports/presentation/reports_page.dart';
import '../../features/settings/presentation/settings_page.dart';
import '../../features/students/presentation/student_list_page.dart';
import '../../features/tuition/presentation/global_tuition_page.dart';
import 'app_destination.dart';
import 'app_global_drawer.dart';
import 'navigation_controller.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentDestId = ref.watch(navigationControllerProvider);
    final width = MediaQuery.of(context).size.width;
    final useSidebar = width >= 600;
    final isEn = Localizations.localeOf(context).languageCode == 'en';

    final bottomDestinations = AppDestination.bottomNavDestinations;

    // Active content widget based on active destination ID
    Widget content;
    switch (currentDestId) {
      case AppDestinationId.home:
        content = const DashboardPage();
        break;
      case AppDestinationId.classes:
        content = const ClassListPage();
        break;
      case AppDestinationId.students:
        content = const StudentListPage();
        break;
      case AppDestinationId.tuition:
        content = const GlobalTuitionPage();
        break;
      case AppDestinationId.reports:
        content = const ReportsPage();
        break;
      case AppDestinationId.settings:
        content = const SettingsPage();
        break;
    }

    // Active bottom navigation index
    final currentDest = AppDestination.fromId(currentDestId);
    final selectedBottomIndex = currentDest.bottomNavIndex ?? 0;

    return Scaffold(
      drawer: const AppGlobalDrawer(),
      body: Row(
        children: [
          if (useSidebar)
            NavigationRail(
              extended: width >= 800,
              selectedIndex: selectedBottomIndex,
              onDestinationSelected: (index) {
                ref
                    .read(navigationControllerProvider.notifier)
                    .goToBottomIndex(index);
              },
              labelType: width >= 800
                  ? NavigationRailLabelType.none
                  : NavigationRailLabelType.all,
              destinations: bottomDestinations.map((dest) {
                final label = isEn ? dest.enLabel : dest.viLabel;
                return NavigationRailDestination(
                  icon: Icon(dest.icon, key: dest.key),
                  selectedIcon: Icon(dest.selectedIcon),
                  label: Text(label),
                );
              }).toList(),
            ),
          if (useSidebar) const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: content),
        ],
      ),
      bottomNavigationBar: useSidebar
          ? null
          : NavigationBar(
              selectedIndex: selectedBottomIndex,
              onDestinationSelected: (index) {
                ref
                    .read(navigationControllerProvider.notifier)
                    .goToBottomIndex(index);
              },
              destinations: bottomDestinations.map((dest) {
                final label = isEn ? dest.enLabel : dest.viLabel;
                return NavigationDestination(
                  key: dest.key,
                  icon: Icon(dest.icon),
                  selectedIcon: Icon(dest.selectedIcon),
                  label: label,
                );
              }).toList(),
            ),
    );
  }
}
