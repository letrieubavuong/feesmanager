import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tuition2027/app/localization/locale_controller.dart';
import 'package:tuition2027/app/navigation/ui_keys.dart';
import 'package:tuition2027/features/settings/presentation/settings_page.dart';
import '../test_helper.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Phase 13A Settings Page Widget Tests', () {
    testWidgets(
      'SettingsPage displays theme, palette, language and info sections',
      (tester) async {
        tester.view.physicalSize = const Size(600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(createTestApp(home: const SettingsPage()));

        await tester.pumpAndSettle();

        expect(find.text('Cài đặt'), findsOneWidget);
        expect(find.text('GIAO DIỆN & CHỦ ĐỀ'), findsOneWidget);
        expect(find.text('Chế độ hiển thị'), findsOneWidget);
        expect(find.text('Tông màu ứng dụng'), findsOneWidget);
        expect(find.text('NGÔN NGỮ'), findsOneWidget);
        expect(find.text('Ngôn ngữ hiển thị'), findsOneWidget);
        expect(find.text('THÔNG TIN ỨNG DỤNG'), findsOneWidget);
        expect(find.text('Phiên bản'), findsOneWidget);
        expect(find.text('1.0.0+1'), findsOneWidget);
        expect(find.text('Cơ sở dữ liệu'), findsOneWidget);
        expect(find.text('v13 (SQLite)'), findsOneWidget);
      },
    );

    testWidgets('SettingsPage allows changing language mode', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: createTestApp(home: const SettingsPage()),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.byKey(UiKeys.settingsLanguageEn));
      await tester.pumpAndSettle();

      expect(
        container.read(localeControllerProvider),
        equals(AppLocaleMode.en),
      );
    });
  });
}
