// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Tuition2027';

  @override
  String get navHome => 'Home';

  @override
  String get navClasses => 'Classes';

  @override
  String get navStudents => 'Students';

  @override
  String get navTuition => 'Tuition';

  @override
  String get navReports => 'Reports';

  @override
  String get navSettings => 'Settings';

  @override
  String get globalMenu => 'Global Menu';

  @override
  String get menuTitle => 'Navigation Menu';

  @override
  String get menuSubtitle => 'Tuition Management System';

  @override
  String get palettePhysicsBlue => 'Physics Blue';

  @override
  String get paletteEmerald => 'Emerald Green';

  @override
  String get paletteIndigo => 'Indigo';

  @override
  String get paletteAmber => 'Amber';

  @override
  String get paletteSlate => 'Slate Grey';

  @override
  String get paletteOceanCyan => 'Ocean Cyan';

  @override
  String get paletteBurgundy => 'Burgundy Rose';

  @override
  String get paletteHighContrast => 'High Contrast';

  @override
  String get dashboardTitle => 'Home';

  @override
  String get dashboardGreeting => 'Welcome, Teacher!';

  @override
  String get dashboardToday => 'Today\'s Schedule';

  @override
  String get dashboardQuickActions => 'Quick Actions';

  @override
  String get dashboardOverview => 'Center Overview';

  @override
  String get dashboardSearchPlaceholder => 'Search students or classes...';

  @override
  String get dashboardNoSessionsToday => 'No sessions scheduled for today.';

  @override
  String get dashboardActiveClasses => 'Active Classes';

  @override
  String get dashboardActiveStudents => 'Active Students';

  @override
  String get actionAddStudent => 'Add Student';

  @override
  String get actionManageClasses => 'Manage Classes';

  @override
  String get actionViewTuition => 'View Tuition';

  @override
  String get actionViewReports => 'View Reports';

  @override
  String get searchResults => 'Search Results';

  @override
  String get searchNoResults => 'No students or classes found.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsAppearance => 'APPEARANCE & THEME';

  @override
  String get settingsThemeMode => 'Theme Mode';

  @override
  String get themeSystem => 'System Default';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get settingsPalette => 'Color Palette';

  @override
  String get settingsLanguage => 'LANGUAGE';

  @override
  String get langSystem => 'System Default';

  @override
  String get langVietnamese => 'Tiếng Việt';

  @override
  String get langEnglish => 'English';

  @override
  String get settingsAppInfo => 'APPLICATION INFO';

  @override
  String get appVersion => 'Version: 1.0.0+1';

  @override
  String get dbVersion => 'Database: v13';

  @override
  String get studentFormTitleAdd => 'Add Student';

  @override
  String get studentFormTitleEdit => 'Edit Student';

  @override
  String get studentFullName => 'Full Name *';

  @override
  String get studentGrade => 'Grade';

  @override
  String studentGradeItem(Object grade) {
    return 'Grade $grade';
  }

  @override
  String get studentGender => 'Gender';

  @override
  String get studentGenderMale => 'Male';

  @override
  String get studentGenderFemale => 'Female';

  @override
  String get studentGenderOther => 'Other';

  @override
  String get studentSchool => 'School';

  @override
  String get studentParentSection => 'Parent Information';

  @override
  String get studentParentName => 'Parent Name';

  @override
  String get studentParentPhone => 'Parent Phone';

  @override
  String get studentOtherContactSection => 'Other Contacts';

  @override
  String get studentPhone => 'Student Phone';

  @override
  String get studentEmail => 'Email';

  @override
  String get studentAddress => 'Address';

  @override
  String get studentFacebook => 'Facebook';

  @override
  String get studentNotes => 'Notes';

  @override
  String get studentValidationName => 'Please enter full name';

  @override
  String get commonLoading => 'Loading data...';

  @override
  String get commonEmpty => 'No data available.';

  @override
  String get commonError => 'An error occurred';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonConfirm => 'Confirm';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonSave => 'Save';

  @override
  String get dirtyFormTitle => 'Discard changes?';

  @override
  String get dirtyFormMessage =>
      'You have unsaved changes. Are you sure you want to discard them and leave?';

  @override
  String get dirtyFormDiscard => 'Discard';

  @override
  String get dirtyFormKeepEditing => 'Keep Editing';
}
