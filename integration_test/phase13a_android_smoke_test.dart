import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tuition2027/app/navigation/ui_keys.dart';
import 'package:tuition2027/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Phase 13A Real Android Integration Smoke Test', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const ProviderScope(child: TuitionApp()));
    await tester.pumpAndSettle();

    // 1. Verify Home Dashboard elements
    expect(find.byKey(UiKeys.globalMenuButton), findsOneWidget);
    expect(find.byKey(UiKeys.dashboardSearchInput), findsOneWidget);

    // 2. Verify 4 Bottom Navigation destinations
    expect(find.byKey(UiKeys.bottomHome), findsOneWidget);
    expect(find.byKey(UiKeys.bottomClasses), findsOneWidget);
    expect(find.byKey(UiKeys.bottomStudents), findsOneWidget);
    expect(find.byKey(UiKeys.bottomTuition), findsOneWidget);

    // 3. Tap Classes
    await tester.tap(find.byKey(UiKeys.bottomClasses));
    await tester.pumpAndSettle();
    expect(find.byKey(UiKeys.bottomClasses), findsOneWidget);

    // 4. Tap Students
    await tester.tap(find.byKey(UiKeys.bottomStudents));
    await tester.pumpAndSettle();
    expect(find.byKey(UiKeys.bottomStudents), findsOneWidget);

    // 5. Tap Tuition
    await tester.tap(find.byKey(UiKeys.bottomTuition));
    await tester.pumpAndSettle();
    expect(find.byKey(UiKeys.bottomTuition), findsOneWidget);

    // 6. Return Home
    await tester.tap(find.byKey(UiKeys.bottomHome));
    await tester.pumpAndSettle();

    // 7. Open Global Menu and navigate to Reports
    await tester.tap(find.byKey(UiKeys.globalMenuButton));
    await tester.pumpAndSettle();
    expect(find.byKey(UiKeys.globalDrawer), findsOneWidget);

    await tester.tap(find.byKey(UiKeys.drawerReports));
    await tester.pumpAndSettle();

    // 8. Open Global Menu from nested Reports and navigate to Settings
    await tester.tap(find.byKey(UiKeys.globalMenuButton));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(UiKeys.drawerSettings));
    await tester.pumpAndSettle();

    // 9. Change Theme Mode & Palette in Settings
    await tester.tap(find.byKey(UiKeys.settingsThemeModeDark));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(UiKeys.settingsPaletteEmerald));
    await tester.pumpAndSettle();

    // 10. Change Language in Settings (explicitly to English)
    await tester.tap(find.byKey(UiKeys.settingsLanguageEn));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);

    // 11. Return Home via Drawer
    await tester.tap(find.byKey(UiKeys.globalMenuButton));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(UiKeys.drawerHome));
    await tester.pumpAndSettle();

    expect(find.text('Welcome, Teacher!'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
