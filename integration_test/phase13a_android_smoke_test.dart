import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:tuition2027/app/navigation/ui_keys.dart';
import 'package:tuition2027/features/reports/presentation/reports_page.dart';
import 'package:tuition2027/features/settings/presentation/settings_page.dart';
import 'package:tuition2027/features/students/presentation/student_form_page.dart';
import 'package:tuition2027/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 13A Real Android App Foundation Smoke Integration Test', () {
    testWidgets(
      'Verify bottom nav, nested global menu, theme/l10n assertions, dirty form safety & auto-reload persistence on Android',
      (tester) async {
        // 1. Clear all SharedPreferences & clean DB before test start
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();

        final dbDir = await getDatabasesPath();
        await deleteDatabase(p.join(dbDir, 'tuition_next.db'));

        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Verify 4 bottom destinations on phone on app launch
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

        // 3. Open Reports from Global Menu -> verify NavigationBar absent
        await tester.tap(find.byKey(UiKeys.globalMenuButton));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(UiKeys.drawerReports));
        await tester.pumpAndSettle();

        expect(find.byType(ReportsPage), findsOneWidget);
        expect(find.byType(NavigationBar), findsNothing);

        // 4. Open Settings from Global Menu -> verify NavigationBar absent
        await tester.tap(find.byKey(UiKeys.globalMenuButton));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(UiKeys.drawerSettings));
        await tester.pumpAndSettle();

        expect(find.byType(SettingsPage), findsOneWidget);
        expect(find.byType(NavigationBar), findsNothing);

        // Capture initial ThemeData
        final initialTheme = Theme.of(
          tester.element(find.byType(SettingsPage)),
        );
        final initialPrimary = initialTheme.colorScheme.primary;

        // 5. Test Theme Mode Dark & assert Theme.brightness == Brightness.dark
        await tester.tap(find.byKey(UiKeys.settingsThemeModeDark));
        await tester.pumpAndSettle();

        final darkTheme = Theme.of(tester.element(find.byType(SettingsPage)));
        expect(darkTheme.brightness, equals(Brightness.dark));

        // 6. Test Emerald Palette & assert colorScheme.primary differs
        await tester.tap(find.byKey(UiKeys.settingsPaletteEmerald));
        await tester.pumpAndSettle();

        final emeraldDarkTheme = Theme.of(
          tester.element(find.byType(SettingsPage)),
        );
        final expectedEmeraldDarkPrimary = emeraldDarkTheme.colorScheme.primary;
        expect(expectedEmeraldDarkPrimary, isNot(equals(initialPrimary)));

        // 7. Test Language Switching explicitly: VI -> EN
        await tester.tap(find.byKey(UiKeys.settingsLanguageVi));
        await tester.pumpAndSettle(const Duration(seconds: 1));

        expect(find.text('Cài đặt'), findsOneWidget);
        expect(find.text('GIAO DIỆN & CHỦ ĐỀ'), findsOneWidget);

        await tester.tap(find.byKey(UiKeys.settingsLanguageEn));
        await tester.pumpAndSettle(const Duration(seconds: 1));

        expect(find.text('Settings'), findsOneWidget);
        expect(find.text('APPEARANCE & THEME'), findsOneWidget);

        // 8. Verify preference values stored in real SharedPreferences
        expect(prefs.getString('pref_theme_mode'), equals('dark'));
        expect(prefs.getString('pref_app_palette'), equals('emerald'));
        expect(prefs.getString('pref_locale_mode'), equals('en'));

        // 9. Real Dirty-Form Global Menu Flow on Android
        // Navigate to Home via drawer
        if (find.byKey(UiKeys.globalDrawer).evaluate().isEmpty) {
          await tester.tap(find.byKey(UiKeys.globalMenuButton));
          await tester.pumpAndSettle();
        }

        await tester.tap(find.byKey(UiKeys.drawerHome));
        await tester.pumpAndSettle();

        // Tap Quick Action 'Add Student' -> opens StudentFormPage
        await tester.tap(find.byKey(UiKeys.dashboardQuickAddStudent));
        await tester.pumpAndSettle();

        expect(find.byType(StudentFormPage), findsOneWidget);

        // Enter text into Full Name field so form becomes DIRTY
        await tester.enterText(
          find.byType(TextFormField).first,
          'Student Dirty Android Test',
        );
        await tester.pumpAndSettle();

        // Open Global Menu -> tap Tuition
        if (find.byKey(UiKeys.globalDrawer).evaluate().isEmpty) {
          await tester.tap(find.byKey(UiKeys.globalMenuButton));
          await tester.pumpAndSettle();
        }

        await tester.tap(find.byKey(UiKeys.drawerTuition));
        await tester.pumpAndSettle();

        // Assert discard confirmation appears
        expect(find.text('Discard changes?'), findsOneWidget);

        // Choose Cancel -> stay on form, entered text preserved
        await tester.tap(find.text('Keep Editing'));
        await tester.pumpAndSettle();

        expect(find.byType(StudentFormPage), findsOneWidget);
        expect(find.text('Student Dirty Android Test'), findsOneWidget);

        // Repeat: Global Menu -> tap Tuition -> choose Discard
        if (find.byKey(UiKeys.globalDrawer).evaluate().isEmpty) {
          await tester.tap(find.byKey(UiKeys.globalMenuButton));
          await tester.pumpAndSettle();
        }

        await tester.tap(find.byKey(UiKeys.drawerTuition));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Discard'));
        await tester.pumpAndSettle();

        // Assert StudentFormPage is gone and Tuition is visible
        expect(find.byType(StudentFormPage), findsNothing);
        expect(find.text('Tuition'), findsAtLeast(1));

        // 10. Android Back Integration Flow on real emulator
        // Re-enter StudentFormPage from Home
        if (find.byKey(UiKeys.globalDrawer).evaluate().isEmpty) {
          await tester.tap(find.byKey(UiKeys.globalMenuButton));
          await tester.pumpAndSettle();
        }

        await tester.tap(find.byKey(UiKeys.drawerHome));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(UiKeys.dashboardQuickAddStudent));
        await tester.pumpAndSettle();

        expect(find.byType(StudentFormPage), findsOneWidget);

        // Clean StudentFormPage -> Android Back returns one level
        final dynamic widgetsAppState = tester.state(find.byType(WidgetsApp));
        widgetsAppState.didPopRoute();
        await tester.pumpAndSettle();

        expect(find.byType(StudentFormPage), findsNothing);

        // 11. Real ProviderScope & Application Widget-Tree Recreation Proof
        // Re-run app.main() to recreate ProviderScope and application widget tree
        // without setting any provider state manually.
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Assert automatically reloaded state from SharedPreferences on disk:
        // - English locale ('Home', 'Classes', 'Students', 'Tuition')
        // - ThemeMode.dark (Brightness.dark)
        // - Emerald palette (expectedEmeraldDarkPrimary)
        expect(find.text('Home'), findsAtLeast(1));
        expect(find.text('Classes'), findsAtLeast(1));
        expect(find.text('Students'), findsAtLeast(1));
        expect(find.text('Tuition'), findsAtLeast(1));

        final reloadedTheme = Theme.of(
          tester.element(find.byType(NavigationBar)),
        );
        expect(reloadedTheme.brightness, equals(Brightness.dark));
        expect(
          reloadedTheme.colorScheme.primary,
          equals(expectedEmeraldDarkPrimary),
        );
      },
    );
  });
}
