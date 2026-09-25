import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tuition2027/app/design_system/app_palettes.dart';
import 'package:tuition2027/app/design_system/app_semantic_colors.dart';
import 'package:tuition2027/app/design_system/app_theme.dart';
import 'package:tuition2027/app/design_system/theme_controller.dart';
import 'package:tuition2027/app/navigation/ui_keys.dart';
import 'package:tuition2027/features/settings/presentation/settings_page.dart';
import '../test_helper.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Phase 13A Multi-Theme & Design System Unit/Widget Tests', () {
    test(
      'All 8 curated palettes create valid ThemeData for Light and Dark modes',
      () {
        for (final info in AppPaletteInfo.all) {
          final lightTheme = AppTheme.createTheme(
            palette: info.palette,
            brightness: Brightness.light,
          );
          final darkTheme = AppTheme.createTheme(
            palette: info.palette,
            brightness: Brightness.dark,
          );

          expect(lightTheme, isNotNull);
          expect(darkTheme, isNotNull);

          final lightSemantic = lightTheme.extension<AppSemanticColors>();
          final darkSemantic = darkTheme.extension<AppSemanticColors>();

          expect(lightSemantic, isNotNull);
          expect(darkSemantic, isNotNull);

          // Verify semantic color roles exist
          expect(lightSemantic!.attendancePresent, isNotNull);
          expect(lightSemantic.tuitionPaid, isNotNull);
          expect(lightSemantic.scheduleHardConflict, isNotNull);
        }
      },
    );

    testWidgets(
      'ThemeController switches mode, palette and persists preference',
      (tester) async {
        SharedPreferences.setMockInitialValues({
          'pref_theme_mode': 'dark',
          'pref_app_palette': 'emerald',
        });

        final container = ProviderContainer();
        addTearDown(container.dispose);

        await container
            .read(themeControllerProvider.notifier)
            .setThemeMode(ThemeMode.dark);
        await container
            .read(themeControllerProvider.notifier)
            .setPalette(AppPalette.emerald);

        final updatedTheme = container.read(themeControllerProvider);
        expect(updatedTheme.themeMode, equals(ThemeMode.dark));
        expect(updatedTheme.palette, equals(AppPalette.emerald));

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('pref_theme_mode'), equals('dark'));
        expect(prefs.getString('pref_app_palette'), equals('emerald'));
      },
    );

    testWidgets('SettingsPage allows changing theme mode and palette', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestApp(home: const SettingsPage()));

      await tester.pumpAndSettle();

      // Tap Dark Theme Mode
      await tester.tap(find.byKey(UiKeys.settingsThemeModeDark));
      await tester.pumpAndSettle();

      // Tap Emerald Palette
      await tester.tap(find.byKey(UiKeys.settingsPaletteEmerald));
      await tester.pumpAndSettle();

      expect(find.text('Xanh Ngọc Emerald'), findsOneWidget);
    });
  });
}
