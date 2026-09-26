import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuition2027/app/navigation/ui_keys.dart';
import 'package:tuition2027/features/classes/presentation/class_form_bottom_sheet.dart';
import 'package:tuition2027/features/memberships/presentation/enroll_student_bottom_sheet.dart';
import 'package:tuition2027/features/tuition/presentation/create_tuition_policy_bottom_sheet.dart';
import 'package:tuition2027/l10n/app_localizations.dart';

Widget buildTestApp(Widget child) {
  return ProviderScope(
    child: MaterialApp(
      locale: const Locale('vi'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  group('Editable Bottom Sheets Safety & Dirty Form Tests', () {
    testWidgets(
      'ClassFormBottomSheet dirty state protection: Keep Editing vs Discard',
      (tester) async {
        await tester.pumpWidget(
          buildTestApp(
            Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showClassFormBottomSheet(context),
                child: const Text('Open Sheet'),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Open Sheet'));
        await tester.pumpAndSettle();

        expect(find.byType(ClassFormBottomSheet), findsOneWidget);

        // Enter text to mark form dirty
        await tester.enterText(
          find.byKey(UiKeys.classFormNameInput),
          'Toán 12 Dirty',
        );
        await tester.pumpAndSettle();

        // Tap close button X
        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();

        // Assert confirmation bottom sheet prompt appears
        expect(find.text('Tiếp tục chỉnh sửa'), findsOneWidget);
        expect(find.text('Bỏ thay đổi'), findsOneWidget);

        // Choose Keep Editing -> stays on sheet with entered text intact
        await tester.tap(find.text('Tiếp tục chỉnh sửa'));
        await tester.pumpAndSettle();

        expect(find.byType(ClassFormBottomSheet), findsOneWidget);
        expect(find.text('Toán 12 Dirty'), findsOneWidget);

        // Tap Cancel button
        await tester.tap(find.text('Hủy'));
        await tester.pumpAndSettle();

        // Choose Discard -> closes sheet
        await tester.tap(find.text('Bỏ thay đổi'));
        await tester.pumpAndSettle();

        expect(find.byType(ClassFormBottomSheet), findsNothing);
      },
    );

    testWidgets('EnrollStudentBottomSheet dirty state protection', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () =>
                  showEnrollStudentBottomSheet(context, classId: 1),
              child: const Text('Open Enroll Sheet'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Enroll Sheet'));
      await tester.pumpAndSettle();

      expect(find.byType(EnrollStudentBottomSheet), findsOneWidget);

      // Enter discount % to mark dirty
      await tester.enterText(find.byType(TextField).first, '15');
      await tester.pumpAndSettle();

      // Tap close icon
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.text('Tiếp tục chỉnh sửa'), findsOneWidget);

      // Discard
      await tester.tap(find.text('Bỏ thay đổi'));
      await tester.pumpAndSettle();

      expect(find.byType(EnrollStudentBottomSheet), findsNothing);
    });

    testWidgets('CreateTuitionPolicyBottomSheet dirty state protection', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () =>
                  showCreateTuitionPolicyBottomSheet(context, classId: 1),
              child: const Text('Open Policy Sheet'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Policy Sheet'));
      await tester.pumpAndSettle();

      expect(find.byType(CreateTuitionPolicyBottomSheet), findsOneWidget);

      // Enter fee to mark dirty
      await tester.enterText(find.byType(TextFormField).at(1), '85000');
      await tester.pumpAndSettle();

      // Tap Cancel
      await tester.tap(find.text('Hủy'));
      await tester.pumpAndSettle();

      expect(find.text('Tiếp tục chỉnh sửa'), findsOneWidget);

      // Discard
      await tester.tap(find.text('Bỏ thay đổi'));
      await tester.pumpAndSettle();

      expect(find.byType(CreateTuitionPolicyBottomSheet), findsNothing);
    });
  });
}
