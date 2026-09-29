Warning: Package resolution error when reading "analysis_options.yaml" file for "test/app/settings_ui_test.dart":
Failed to resolve package URI "package:flutter_lints/flutter.yaml" in include at "/workspace/scratch/493f502c6c4f/feesmanager/analysis_options.yaml".
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tuition2027/app/localization/locale_controller.dart';
import 'package:tuition2027/features/settings/presentation/settings_page.dart';

import '../test_helper.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Phase 13A Settings Page Widget Tests', () {
    testWidgets(
      'SettingsPage displays compact controls and teaching reminder options',
      (tester) async {
        tester.view.physicalSize = const Size(600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(createTestApp(home: const SettingsPage()));

        await tester.pumpAndSettle();

        expect(find.text('Cài đặt'), findsOneWidget);
        expect(find.text('GIAO DIỆN & CHỦ ĐỀ'), findsOneWidget);
        expect(find.text('Chế độ hiển thị'), findsOneWidget);
        expect(find.text('NHẮC GIỜ DẠY'), findsOneWidget);
        expect(find.text('5 phút'), findsOneWidget);
        expect(find.text('10 phút'), findsOneWidget);
        expect(find.text('NGÔN NGỮ'), findsAtLeast(1));
        expect(find.text('THÔNG TIN ỨNG DỤNG'), findsOneWidget);
        expect(find.text('Quy tắc tính học phí theo lớp'), findsOneWidget);
        expect(find.text('Tài khoản nhận học phí'), findsOneWidget);
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

      await tester.tap(find.text('EN'));
      await tester.pumpAndSettle();

      expect(
        container.read(localeControllerProvider),
        equals(AppLocaleMode.en),
      );
    });
  });
}
