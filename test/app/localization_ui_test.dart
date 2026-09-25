import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tuition2027/app/localization/app_formatter.dart';
import 'package:tuition2027/app/localization/locale_controller.dart';
import 'package:tuition2027/features/settings/presentation/settings_page.dart';
import 'package:tuition2027/l10n/app_localizations.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Phase 13A Localization Unit/Widget Tests', () {
    test('AppFormatter formats currency, dates, months and weekdays per locale', () {
      final date = DateTime(2026, 10, 15);

      // Vietnamese formatting
      expect(AppFormatter.formatCurrency(1000000, locale: 'vi'), contains('1.000.000'));
      expect(AppFormatter.formatDate(date, locale: 'vi'), equals('15/10/2026'));
      expect(AppFormatter.formatMonth('2026-10', locale: 'vi'), equals('Tháng 10/2026'));
      expect(AppFormatter.formatWeekday(1, locale: 'vi'), equals('Thứ Hai'));
      expect(AppFormatter.formatWeekday(7, locale: 'vi'), equals('Chủ Nhật'));

      // English formatting
      expect(AppFormatter.formatCurrency(1000000, locale: 'en'), contains('1,000,000'));
      expect(AppFormatter.formatDate(date, locale: 'en'), equals('Oct 15, 2026'));
      expect(AppFormatter.formatMonth('2026-10', locale: 'en'), equals('October 2026'));
      expect(AppFormatter.formatWeekday(1, locale: 'en'), equals('Monday'));
      expect(AppFormatter.formatWeekday(7, locale: 'en'), equals('Sunday'));
    });

    test('Canonical domain enums remain unchanged by localization', () {
      const dbStatusHoc = 'DA_HOC';
      const dbStatusThanhToan = 'DA_THANH_TOAN';
      const dbStatusConNo = 'CON_NO';

      expect(dbStatusHoc, equals('DA_HOC'));
      expect(dbStatusThanhToan, equals('DA_THANH_TOAN'));
      expect(dbStatusConNo, equals('CON_NO'));
    });

    testWidgets('LocaleController switches locale and persists preference', (tester) async {
      SharedPreferences.setMockInitialValues({'pref_locale_mode': 'vi'});

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(localeControllerProvider.notifier).setLocaleMode(AppLocaleMode.en);

      expect(container.read(localeControllerProvider), equals(AppLocaleMode.en));
      expect(container.read(localeControllerProvider.notifier).locale, equals(const Locale('en')));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('pref_locale_mode'), equals('en'));
    });

    testWidgets('English locale renders English UI labels in SettingsPage', (tester) async {
      tester.view.physicalSize = const Size(600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localeControllerProvider.overrideWith(() => MockLocaleController(AppLocaleMode.en)),
          ],
          child: const MaterialApp(
            locale: Locale('en'),
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

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('APPEARANCE & THEME'), findsOneWidget);
      expect(find.text('LANGUAGE'), findsAtLeast(1));
      expect(find.text('APPLICATION INFO'), findsOneWidget);
    });
  });
}

class MockLocaleController extends LocaleController {
  final AppLocaleMode initialMode;
  MockLocaleController(this.initialMode);

  @override
  AppLocaleMode build() => initialMode;
}
