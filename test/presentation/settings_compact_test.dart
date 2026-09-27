import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuition2027/app/localization/locale_controller.dart';
import 'package:tuition2027/features/settings/presentation/settings_page.dart';
import 'package:tuition2027/l10n/app_localizations.dart';

void main() {
  group('Compact Settings Page Dropdown Tests', () {
    testWidgets('Renders Theme, Palette and Language Dropdowns', (
      tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            locale: Locale('vi'),
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: SettingsPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify compact dropdown form fields exist for Theme and Language (Palette dropdown is intentionally omitted for unified Physics Navy identity)
      expect(find.byType(DropdownButtonFormField<ThemeMode>), findsOneWidget);
      expect(
        find.byType(DropdownButtonFormField<AppLocaleMode>),
        findsOneWidget,
      );
    });
  });
}
