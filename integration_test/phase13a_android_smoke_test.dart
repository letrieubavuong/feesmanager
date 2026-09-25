import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tuition2027/app/navigation/ui_keys.dart';
import 'package:tuition2027/features/settings/presentation/settings_page.dart';
import 'package:tuition2027/features/students/presentation/student_form_page.dart';
import 'package:tuition2027/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 13A Real Android App Foundation Smoke Integration Test', () {
    testWidgets('Verify bottom nav, nested global menu, theme/l10n persistence on Android', (tester) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // 1. Verify 4 bottom destinations on phone on app launch
      expect(find.byKey(UiKeys.bottomHome), findsOneWidget);
      expect(find.byKey(UiKeys.bottomClasses), findsOneWidget);
      expect(find.byKey(UiKeys.bottomStudents), findsOneWidget);
      expect(find.byKey(UiKeys.bottomTuition), findsOneWidget);

      // 2. Navigate all 4 bottom tabs
      await tester.tap(find.byKey(UiKeys.bottomClasses));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(UiKeys.bottomStudents));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(UiKeys.bottomTuition));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(UiKeys.bottomHome));
      await tester.pumpAndSettle();

      // 3. Open Global Menu and navigate to Settings
      await tester.tap(find.byKey(UiKeys.globalMenuButton));
      await tester.pumpAndSettle();

      expect(find.byKey(UiKeys.globalDrawer), findsOneWidget);

      await tester.tap(find.byKey(UiKeys.drawerSettings));
      await tester.pumpAndSettle();

      expect(find.byType(SettingsPage), findsOneWidget);
      // Verify BottomNavigationBar is NOT shown on Settings (no false Home highlight!)
      expect(find.byType(NavigationBar), findsNothing);

      // 4. Test Language Switching explicitly
      await tester.tap(find.byKey(UiKeys.settingsLanguageVi));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      await tester.tap(find.byKey(UiKeys.settingsLanguageEn));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Verify UI text in English
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('APPEARANCE & THEME'), findsOneWidget);

      // 5. Change Theme Mode to Dark & Palette to Emerald Green
      await tester.tap(find.byKey(UiKeys.settingsThemeModeDark));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(UiKeys.settingsPaletteEmerald));
      await tester.pumpAndSettle();

      // 6. Verify preference values stored in real SharedPreferences
      expect(prefs.getString('pref_theme_mode'), equals('dark'));
      expect(prefs.getString('pref_app_palette'), equals('emerald'));
      expect(prefs.getString('pref_locale_mode'), equals('en'));

      // 7. Enter a REAL nested flow: Home -> Add Student (StudentFormPage)
      // Navigate to Home via drawer
      await tester.tap(find.byKey(UiKeys.globalMenuButton));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(UiKeys.drawerHome));
      await tester.pumpAndSettle();

      // Tap Quick Action 'Add Student' -> opens nested StudentFormPage
      await tester.tap(find.byKey(UiKeys.dashboardQuickAddStudent));
      await tester.pumpAndSettle();

      expect(find.byType(StudentFormPage), findsOneWidget);

      // Verify both Back button and Global Menu button are present in AppBar
      expect(find.byType(BackButton), findsOneWidget);
      expect(find.byKey(UiKeys.globalMenuButton), findsOneWidget);

      // Open Global Menu from nested StudentFormPage and navigate to Tuition
      await tester.tap(find.byKey(UiKeys.globalMenuButton));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(UiKeys.drawerTuition));
      await tester.pumpAndSettle();

      // Verify returned cleanly to Tuition tab on root AppShell (StudentFormPage popped)
      expect(find.byType(StudentFormPage), findsNothing);
      expect(find.text('Tuition'), findsAtLeast(1));
    });
  });
}
