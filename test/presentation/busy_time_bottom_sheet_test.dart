import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuition2027/features/schedule_conflicts/presentation/schedule_constraint_dialogs.dart';
import 'package:tuition2027/l10n/app_localizations.dart';

void main() {
  group('BusyTimeFormBottomSheet Widget & Terminology Tests', () {
    testWidgets('Renders user-visible Giờ bận terminology and form fields', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            locale: const Locale('vi'),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () =>
                      showAddBusyTimeBottomSheet(context, studentId: 1),
                  child: const Text('Open Busy Time Sheet'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Open sheet
      await tester.tap(find.text('Open Busy Time Sheet'));
      await tester.pumpAndSettle();

      // Assert user-visible "Giờ bận" title and labels
      expect(find.text('Thêm giờ bận của học sinh'), findsOneWidget);
      expect(find.text('Loại giờ bận'), findsOneWidget);
      expect(find.text('Lưu giờ bận'), findsOneWidget);
      expect(find.text('Ràng buộc lịch'), findsNothing);
    });
  });
}
