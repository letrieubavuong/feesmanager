import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tuition2027/app/navigation/ui_keys.dart';
import 'package:sqflite/sqflite.dart';
import 'package:tuition2027/features/classes/presentation/class_detail_page.dart';
import 'package:tuition2027/features/settings/presentation/settings_page.dart';
import 'package:tuition2027/features/students/presentation/student_detail_page.dart';
import 'package:tuition2027/features/students/presentation/student_form_page.dart';
import 'package:tuition2027/main.dart' as app;

Future<void> awaitDataReload(
  WidgetTester tester,
  String text, {
  int maxAttempts = 20,
}) async {
  for (int i = 0; i < maxAttempts; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
    if (find.text(text).evaluate().isNotEmpty) return;
    if (find.textContaining(text).evaluate().isNotEmpty) return;
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 13B Real Android Core Data Entry Flow Integration Test', () {
    testWidgets(
      'Complete workflow: Student -> Class -> Membership -> Tuition Policy -> Search/Edit -> Dirty Form -> L10n/Theme',
      (tester) async {
        // 1. Clear SharedPreferences and clean SQLite DB
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();

        final dbDir = await getDatabasesPath();
        await deleteDatabase(p.join(dbDir, 'tuition_next.db'));

        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // 2. Create Student: 'Nguyễn Văn A'
        await tester.tap(find.byKey(UiKeys.bottomStudents));
        await tester.pumpAndSettle();

        await tester.tap(
          find.byType(FloatingActionButton),
          warnIfMissed: false,
        );
        await tester.pumpAndSettle();

        expect(find.byType(StudentFormPage), findsOneWidget);

        final nameField = find.byKey(const Key('student_form_name_input'));
        await tester.tap(nameField);
        await tester.pumpAndSettle();
        await tester.enterText(nameField, 'Nguyễn Văn A');
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(UiKeys.studentFormSave));
        await tester.pumpAndSettle();
        await awaitDataReload(tester, 'Nguyễn Văn A');

        expect(find.byType(StudentFormPage), findsNothing);
        expect(find.text('Nguyễn Văn A'), findsOneWidget);

        // 3. Open Student Detail & Edit to 'Nguyễn Văn A Prime'
        await tester.tap(find.text('Nguyễn Văn A'));
        await tester.pumpAndSettle();

        expect(find.byType(StudentDetailPage), findsOneWidget);

        // Tap Edit
        await tester.tap(find.byIcon(Icons.edit));
        await tester.pumpAndSettle();

        expect(find.byType(StudentFormPage), findsOneWidget);

        await tester.tap(nameField);
        await tester.pumpAndSettle();
        await tester.enterText(nameField, 'Nguyễn Văn A Prime');
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(UiKeys.studentFormSave));
        await tester.pumpAndSettle();

        expect(find.byType(StudentFormPage), findsNothing);

        await awaitDataReload(tester, 'Nguyễn Văn A Prime');

        // Verify edited name appears on Detail page immediately
        expect(find.text('Nguyễn Văn A Prime'), findsAtLeast(1));

        // Pop back to Students list
        final dynamic widgetsAppState = tester.state(find.byType(WidgetsApp));
        widgetsAppState.didPopRoute();
        await tester.pumpAndSettle(const Duration(seconds: 4));

        expect(find.text('Nguyễn Văn A Prime'), findsOneWidget);

        // 4. Create Class: 'Vật lý 10' via Bottom Sheet
        await tester.tap(find.byKey(UiKeys.bottomClasses));
        await tester.pumpAndSettle();

        await tester.tap(
          find.byType(FloatingActionButton),
          warnIfMissed: false,
        );
        await tester.pumpAndSettle();

        final classNameField = find.byKey(UiKeys.classFormNameInput);
        await tester.tap(classNameField);
        await tester.pumpAndSettle();
        await tester.enterText(classNameField, 'Vật lý 10');
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(UiKeys.classFormSave));
        await tester.pumpAndSettle();
        await awaitDataReload(tester, 'Vật lý 10');

        expect(find.text('Vật lý 10'), findsOneWidget);

        // 5. Open Class Detail & Edit to 'Vật lý 10 Chuyên'
        await tester.tap(find.text('Vật lý 10'));
        await tester.pumpAndSettle();

        expect(find.byType(ClassDetailPage), findsOneWidget);

        // Tap Edit Class
        await tester.tap(find.byIcon(Icons.edit));
        await tester.pumpAndSettle();

        await tester.tap(classNameField);
        await tester.pumpAndSettle();
        await tester.enterText(classNameField, 'Vật lý 10 Chuyên');
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(UiKeys.classFormSave));
        await tester.pumpAndSettle();

        await awaitDataReload(tester, 'Vật lý 10 Chuyên');

        // Verify edited class name on Class Detail page immediately
        expect(find.text('Vật lý 10 Chuyên'), findsAtLeast(1));

        // 6. Enroll 'Nguyễn Văn A Prime' into 'Vật lý 10 Chuyên' via Bottom Sheet
        await tester.tap(find.byIcon(Icons.person_add));
        await tester.pumpAndSettle();

        await tester.tap(find.byType(InputDecorator).first);
        await tester.pumpAndSettle();

        await tester.tap(find.text('Nguyễn Văn A Prime'));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(UiKeys.enrollStudentSubmit));
        await tester.pumpAndSettle();

        await awaitDataReload(tester, 'Nguyễn Văn A Prime');

        expect(find.text('Nguyễn Văn A Prime'), findsAtLeast(1));

        // 7. Create Tuition Policy for 'Vật lý 10 Chuyên' via Bottom Sheet
        await tester.drag(find.byType(TabBar), const Offset(-300, 0));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Học phí'));
        await tester.pumpAndSettle(const Duration(seconds: 1));

        await tester.tap(find.text('Thêm CS'));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(UiKeys.tuitionPolicySave));
        await tester.pumpAndSettle();

        await awaitDataReload(tester, 'Chính sách học phí');

        expect(find.textContaining('Chính sách học phí'), findsAtLeast(1));

        // Pop ClassDetailPage back to ClassList
        widgetsAppState.didPopRoute();
        await tester.pumpAndSettle();

        // 8. Test Dirty Form Global Menu Safety
        if (find.byKey(UiKeys.globalDrawer).evaluate().isEmpty) {
          await tester.tap(find.byKey(UiKeys.globalMenuButton));
          await tester.pumpAndSettle();
        }

        await tester.tap(find.byKey(UiKeys.drawerHome));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(UiKeys.dashboardQuickAddStudent));
        await tester.pumpAndSettle();

        await tester.tap(nameField);
        await tester.pumpAndSettle();
        await tester.enterText(nameField, 'Dirty Student Test B');
        await tester.pumpAndSettle();

        if (find.byKey(UiKeys.globalDrawer).evaluate().isEmpty) {
          await tester.tap(find.byKey(UiKeys.globalMenuButton));
          await tester.pumpAndSettle();
        }

        await tester.tap(find.byKey(UiKeys.drawerTuition));
        await tester.pumpAndSettle();

        // Cancel dirty form leave -> stays on StudentFormPage
        await tester.tap(find.byType(TextButton).last);
        await tester.pumpAndSettle();

        expect(find.byType(StudentFormPage), findsOneWidget);
        expect(find.text('Dirty Student Test B'), findsOneWidget);

        // Discard dirty form leave -> pops StudentFormPage and opens Tuition tab
        if (find.byKey(UiKeys.globalDrawer).evaluate().isEmpty) {
          await tester.tap(find.byKey(UiKeys.globalMenuButton));
          await tester.pumpAndSettle();
        }

        await tester.tap(find.byKey(UiKeys.drawerTuition));
        await tester.pumpAndSettle();

        await tester.tap(find.byType(ElevatedButton).last);
        await tester.pumpAndSettle();

        expect(find.byType(StudentFormPage), findsNothing);

        // 9. Test Settings: Dark mode, Emerald palette, English l10n
        if (find.byKey(UiKeys.globalDrawer).evaluate().isEmpty) {
          await tester.tap(find.byKey(UiKeys.globalMenuButton));
          await tester.pumpAndSettle();
        }

        await tester.tap(find.byKey(UiKeys.drawerSettings));
        await tester.pumpAndSettle();

        expect(find.byType(SettingsPage), findsOneWidget);

        await tester.tap(find.byKey(UiKeys.settingsThemeModeDark));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(UiKeys.settingsPaletteEmerald));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(UiKeys.settingsLanguageEn));
        await tester.pumpAndSettle(const Duration(seconds: 1));

        expect(find.text('Settings'), findsOneWidget);
        expect(find.text('APPEARANCE & THEME'), findsOneWidget);
      },
    );
  });
}
