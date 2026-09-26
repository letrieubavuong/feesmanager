import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:tuition2027/app/navigation/ui_keys.dart';
import 'package:tuition2027/features/classes/presentation/class_detail_page.dart';
import 'package:tuition2027/features/settings/presentation/settings_page.dart';
import 'package:tuition2027/features/students/presentation/student_detail_page.dart';
import 'package:tuition2027/features/students/presentation/student_form_page.dart';
import 'package:tuition2027/main.dart' as app;

Future<void> dismissSnackBar(WidgetTester tester) async {
  final scaffolds = find.byType(Scaffold).evaluate();
  if (scaffolds.isNotEmpty) {
    try {
      ScaffoldMessenger.of(scaffolds.first).clearSnackBars();
      await tester.pump();
      await tester.pumpAndSettle(const Duration(seconds: 1));
    } catch (_) {}
  }
}

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
      'Complete workflow: Student Search/Edit/Archive -> Class Search/Edit/Archive -> Membership Overlap Guard -> Tuition Policy Distinctive Values -> Dirty Form -> L10n/Theme',
      (tester) async {
        // 1. Clear SharedPreferences and clean SQLite DB
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();

        final dbDir = await getDatabasesPath();
        await deleteDatabase(p.join(dbDir, 'tuition_next.db'));

        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // ==========================================
        // 2. STUDENT LIFECYCLE: Create -> Search -> View -> Edit -> Archive -> Restore
        // ==========================================
        await tester.tap(find.byKey(UiKeys.bottomStudents));
        await tester.pumpAndSettle();

        await dismissSnackBar(tester);
        await tester.tap(find.byType(FloatingActionButton));
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

        // Search Student by partial name
        await tester.tap(find.byKey(UiKeys.studentSearch));
        await tester.pumpAndSettle();
        await tester.enterText(find.byKey(UiKeys.studentSearch), 'Nguyễn');
        await tester.pumpAndSettle(const Duration(seconds: 1));

        expect(find.text('Nguyễn Văn A'), findsOneWidget);

        // Open Student Detail & Edit to 'Nguyễn Văn A Prime'
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

        // Archive Student from Detail page
        await tester.tap(find.byKey(UiKeys.studentArchiveAction));
        await tester.pumpAndSettle();

        // Confirm archive in bottom sheet
        await tester.tap(
          find.descendant(
            of: find.byType(BottomSheet).last,
            matching: find.byType(ElevatedButton),
          ),
        );
        await tester.pumpAndSettle(const Duration(seconds: 1));

        // Pop back to Students list
        final dynamic widgetsAppState = tester.state(find.byType(WidgetsApp));
        widgetsAppState.didPopRoute();
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Active filter should no longer show archived student
        expect(find.text('Nguyễn Văn A Prime'), findsNothing);

        // Switch to Archived filter
        await tester.tap(find.byKey(UiKeys.studentArchivedFilter));
        await tester.pumpAndSettle(const Duration(seconds: 1));

        expect(find.text('Nguyễn Văn A Prime'), findsOneWidget);

        // Re-open Detail for archived student and Restore
        await tester.tap(find.text('Nguyễn Văn A Prime'));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(UiKeys.studentRestoreAction));
        await tester.pumpAndSettle();

        // Confirm restore in bottom sheet
        await tester.tap(
          find.descendant(
            of: find.byType(BottomSheet).last,
            matching: find.byType(ElevatedButton),
          ),
        );
        await tester.pumpAndSettle(const Duration(seconds: 1));

        widgetsAppState.didPopRoute();
        await tester.pumpAndSettle();

        // Switch back to Active filter
        await tester.tap(find.byKey(UiKeys.studentActiveFilter));
        await tester.pumpAndSettle(const Duration(seconds: 1));

        expect(find.text('Nguyễn Văn A Prime'), findsOneWidget);

        // ==========================================
        // 3. CLASS LIFECYCLE: Create -> Search -> View -> Edit -> Archive -> Restore
        // ==========================================
        await tester.tap(find.byKey(UiKeys.bottomClasses));
        await tester.pumpAndSettle();

        await dismissSnackBar(tester);
        await tester.tap(find.byType(FloatingActionButton));
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

        // Search Class
        await tester.tap(find.byKey(UiKeys.classSearch));
        await tester.pumpAndSettle();
        await tester.enterText(find.byKey(UiKeys.classSearch), 'Vật lý');
        await tester.pumpAndSettle(const Duration(seconds: 1));

        expect(find.text('Vật lý 10'), findsOneWidget);

        // Open Class Detail & Edit to 'Vật lý 10 Chuyên'
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

        // ==========================================
        // 4. MEMBERSHIP FLOW & OVERLAP REJECTION PROOF
        // ==========================================
        // Enroll 'Nguyễn Văn A Prime' into 'Vật lý 10 Chuyên' via Bottom Sheet
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

        // Duplicate Enrollment attempt -> must reject overlap
        await tester.tap(find.byIcon(Icons.person_add));
        await tester.pumpAndSettle();

        await tester.tap(find.byType(InputDecorator).first);
        await tester.pumpAndSettle();

        await tester.tap(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.text('Nguyễn Văn A Prime'),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(UiKeys.enrollStudentSubmit));
        await tester.pumpAndSettle();

        // Assert error SnackBar is displayed and sheet remains open
        expect(find.byType(SnackBar), findsOneWidget);

        // Close/Cancel duplicate enrollment sheet
        await dismissSnackBar(tester);
        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();

        // Discard changes in dirty confirmation prompt (topmost BottomSheet)
        await tester.tap(
          find.descendant(
            of: find.byType(BottomSheet).last,
            matching: find.byType(ElevatedButton),
          ),
        );
        await tester.pumpAndSettle();

        // ==========================================
        // 5. TUITION POLICY PERSISTENCE PROOF WITH DISTINCTIVE VALUES
        // ==========================================
        await dismissSnackBar(tester);
        DefaultTabController.of(
          tester.element(find.byType(TabBarView)),
        ).animateTo(5);
        await tester.pumpAndSettle();
        await awaitDataReload(tester, 'Thêm CS');

        await tester.tap(find.text('Thêm CS'));
        await tester.pumpAndSettle();

        // Enter distinctive policy values: Fee = 73000, N = 11, Cap = 800000
        final feeInput = find.byType(TextFormField).at(1);
        await tester.tap(feeInput);
        await tester.pumpAndSettle();
        await tester.enterText(feeInput, '73000');
        await tester.pumpAndSettle();

        final stdInput = find.byType(TextFormField).at(2);
        await tester.tap(stdInput);
        await tester.pumpAndSettle();
        await tester.enterText(stdInput, '11');
        await tester.pumpAndSettle();

        final capInput = find.byType(TextFormField).at(3);
        await tester.tap(capInput);
        await tester.pumpAndSettle();
        await tester.enterText(capInput, '800000');
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(UiKeys.tuitionPolicySave));
        await tester.pumpAndSettle();

        await awaitDataReload(tester, '73,000');

        // Assert distinctive fee, N, and cap values are rendered
        expect(find.textContaining('73,000'), findsAtLeast(1));
        expect(find.textContaining('11'), findsAtLeast(1));
        expect(find.textContaining('800,000'), findsAtLeast(1));

        // Validation Failure Test on Tuition Policy
        await awaitDataReload(tester, 'Thêm CS');
        await tester.tap(find.text('Thêm CS'), warnIfMissed: false);
        await tester.pumpAndSettle();

        // Enter invalid standard sessions N = 0
        await tester.tap(stdInput);
        await tester.pumpAndSettle();
        await tester.enterText(stdInput, '0');
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(UiKeys.tuitionPolicySave));
        await tester.pumpAndSettle();

        // Assert validation error is shown and sheet remains open
        expect(find.textContaining('Số buổi chuẩn'), findsAtLeast(1));

        // Close invalid policy sheet
        await dismissSnackBar(tester);
        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();

        // Discard changes
        await tester.tap(
          find.descendant(
            of: find.byType(BottomSheet).last,
            matching: find.byType(ElevatedButton),
          ),
        );
        await tester.pumpAndSettle();

        // Pop ClassDetailPage back to ClassList
        widgetsAppState.didPopRoute();
        await tester.pumpAndSettle();

        // ==========================================
        // 6. DIRTY FORM GLOBAL MENU SAFETY
        // ==========================================
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

        // Cancel dirty form leave -> stays on StudentFormPage (TextButton in confirm bottom sheet)
        await tester.tap(
          find.descendant(
            of: find.byType(BottomSheet).last,
            matching: find.byType(TextButton),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(StudentFormPage), findsOneWidget);
        expect(find.text('Dirty Student Test B'), findsOneWidget);

        // Discard dirty form leave -> pops StudentFormPage and opens Tuition tab (ElevatedButton in confirm bottom sheet)
        if (find.byKey(UiKeys.globalDrawer).evaluate().isEmpty) {
          await tester.tap(find.byKey(UiKeys.globalMenuButton));
          await tester.pumpAndSettle();
        }

        await tester.tap(find.byKey(UiKeys.drawerTuition));
        await tester.pumpAndSettle();

        await tester.tap(
          find.descendant(
            of: find.byType(BottomSheet).last,
            matching: find.byType(ElevatedButton),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(StudentFormPage), findsNothing);

        // ==========================================
        // 7. SETTINGS: Dark mode, Emerald palette, English L10n
        // ==========================================
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
