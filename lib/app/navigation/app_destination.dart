import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import 'ui_keys.dart';

enum AppDestinationId { home, classes, students, tuition, reports, settings }

class AppDestination {
  final AppDestinationId id;
  final IconData icon;
  final IconData selectedIcon;
  final Key key;
  final Key drawerKey;
  final int? bottomNavIndex; // 0, 1, 2, 3 or null if not in bottom nav
  final bool inGlobalMenu;

  const AppDestination({
    required this.id,
    required this.icon,
    required this.selectedIcon,
    required this.key,
    required this.drawerKey,
    this.bottomNavIndex,
    this.inGlobalMenu = true,
  });

  bool get inBottomNav => bottomNavIndex != null;

  String label(AppLocalizations l10n) {
    switch (id) {
      case AppDestinationId.home:
        return l10n.navHome;
      case AppDestinationId.classes:
        return l10n.navClasses;
      case AppDestinationId.students:
        return l10n.navStudents;
      case AppDestinationId.tuition:
        return l10n.navTuition;
      case AppDestinationId.reports:
        return l10n.navReports;
      case AppDestinationId.settings:
        return l10n.navSettings;
    }
  }

  static const home = AppDestination(
    id: AppDestinationId.home,
    icon: Icons.home_outlined,
    selectedIcon: Icons.home,
    key: UiKeys.bottomHome,
    drawerKey: UiKeys.drawerHome,
    bottomNavIndex: 0,
  );

  static const classes = AppDestination(
    id: AppDestinationId.classes,
    icon: Icons.class_outlined,
    selectedIcon: Icons.class_,
    key: UiKeys.bottomClasses,
    drawerKey: UiKeys.drawerClasses,
    bottomNavIndex: 1,
  );

  static const students = AppDestination(
    id: AppDestinationId.students,
    icon: Icons.people_outline,
    selectedIcon: Icons.people,
    key: UiKeys.bottomStudents,
    drawerKey: UiKeys.drawerStudents,
    bottomNavIndex: 2,
  );

  static const tuition = AppDestination(
    id: AppDestinationId.tuition,
    icon: Icons.payments_outlined,
    selectedIcon: Icons.payments,
    key: UiKeys.bottomTuition,
    drawerKey: UiKeys.drawerTuition,
    bottomNavIndex: 3,
  );

  static const reports = AppDestination(
    id: AppDestinationId.reports,
    icon: Icons.bar_chart_outlined,
    selectedIcon: Icons.bar_chart,
    key: Key('nav_reports'),
    drawerKey: UiKeys.drawerReports,
    bottomNavIndex: null, // Absent from bottom nav!
  );

  static const settings = AppDestination(
    id: AppDestinationId.settings,
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings,
    key: Key('nav_settings'),
    drawerKey: UiKeys.drawerSettings,
    bottomNavIndex: null, // Absent from bottom nav!
  );

  static const List<AppDestination> all = [
    home,
    classes,
    students,
    tuition,
    reports,
    settings,
  ];

  static List<AppDestination> get bottomNavDestinations =>
      all.where((d) => d.inBottomNav).toList()
        ..sort((a, b) => a.bottomNavIndex!.compareTo(b.bottomNavIndex!));

  static List<AppDestination> get globalMenuDestinations =>
      all.where((d) => d.inGlobalMenu).toList();

  static AppDestination fromId(AppDestinationId id) {
    return all.firstWhere((d) => d.id == id, orElse: () => home);
  }
}
