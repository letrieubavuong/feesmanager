import 'package:flutter/material.dart';

class UiKeys {
  UiKeys._();

  // Bottom Navigation
  static const Key bottomHome = Key('bottom_nav_home');
  static const Key bottomClasses = Key('bottom_nav_classes');
  static const Key bottomStudents = Key('bottom_nav_students');
  static const Key bottomTuition = Key('bottom_nav_tuition');

  // Global Menu / Drawer
  static const Key globalMenuButton = Key('global_menu_button');
  static const Key globalDrawer = Key('global_drawer');
  static const Key drawerHome = Key('drawer_home');
  static const Key drawerClasses = Key('drawer_classes');
  static const Key drawerStudents = Key('drawer_students');
  static const Key drawerTuition = Key('drawer_tuition');
  static const Key drawerReports = Key('drawer_reports');
  static const Key drawerSettings = Key('drawer_settings');

  // Dashboard
  static const Key dashboardSearchInput = Key('dashboard_search_input');
  static const Key dashboardQuickAddStudent = Key(
    'dashboard_quick_add_student',
  );
  static const Key dashboardQuickManageClasses = Key(
    'dashboard_quick_manage_classes',
  );
  static const Key dashboardQuickViewTuition = Key(
    'dashboard_quick_view_tuition',
  );
  static const Key dashboardQuickViewReports = Key(
    'dashboard_quick_view_reports',
  );

  // Settings
  static const Key settingsThemeModeSystem = Key('settings_theme_mode_system');
  static const Key settingsThemeModeLight = Key('settings_theme_mode_light');
  static const Key settingsThemeModeDark = Key('settings_theme_mode_dark');
  static const Key settingsPalettePhysicsBlue = Key(
    'settings_palette_physics_blue',
  );
  static const Key settingsPaletteEmerald = Key('settings_palette_emerald');
  static const Key settingsLanguageSystem = Key('settings_language_system');
  static const Key settingsLanguageVi = Key('settings_language_vi');
  static const Key settingsLanguageEn = Key('settings_language_en');

  // Phase 13B Forms, Filters & Actions
  static const Key studentFormSave = Key('student_form_save');
  static const Key classFormNameInput = Key('class_form_name_input');
  static const Key classFormSave = Key('class_form_save');
  static const Key enrollStudentSubmit = Key('enroll_student_submit');
  static const Key tuitionPolicySave = Key('tuition_policy_save');

  static const Key studentSearch = Key('student_search_input');
  static const Key classSearch = Key('class_search_input');
  static const Key studentActiveFilter = Key('student_active_filter');
  static const Key studentArchivedFilter = Key('student_archived_filter');
  static const Key classActiveFilter = Key('class_active_filter');
  static const Key classArchivedFilter = Key('class_archived_filter');
  static const Key studentArchiveAction = Key('student_archive_action');
  static const Key studentRestoreAction = Key('student_restore_action');
  static const Key classArchiveAction = Key('class_archive_action');
  static const Key classRestoreAction = Key('class_restore_action');
}
