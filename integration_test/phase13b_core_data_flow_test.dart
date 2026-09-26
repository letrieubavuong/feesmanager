import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tuition2027/app/navigation/ui_keys.dart';
import 'package:tuition2027/features/classes/presentation/class_detail_page.dart';
import 'package:tuition2027/features/classes/presentation/class_form_page.dart';
import 'package:tuition2027/features/settings/presentation/settings_page.dart';
import 'package:tuition2027/features/students/presentation/student_detail_page.dart';
import 'package:tuition2027/features/students/presentation/student_form_page.dart';
import 'package:tuition2027/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 13B Real Android Core Data Entry Flow Integration Test', () {
    testWidgets(
      'Complete workflow: Student -> Class -> Membership -> Tuition Policy -> Dirty Form -> Theme & L10n',
      (tester) async {
        // 1. Clear SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();

        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // 2. Create Student: 'Nguyễn Văn A'
        // Navigate to Students tab
        await tester.tap(find.byKey(UiKeys.bottomStudents));
        await tester.pumpAndSettle();

        // Tap FAB / Add Student
        await tester.tap(find.byType(FloatingActionButton));
        await tester.pumpAndSettle();

        expect(find.byType(StudentFormPage), findsOneWidget);

        // Enter Student Full Name
        await tester.enterText(
          find.byType(TextFormField).first,
          'Nguyễn Văn A',
        );
        await tester.pumpAndSettle();

        // Save Student
        await tester.tap(find.byIcon(Icons.check));
        await tester.pumpAndSettle();

        expect(find.byType(StudentFormPage), findsNothing);
        expect(find.text('Nguyễn Văn A'), findsOneWidget);

        // Open Student Detail for 'Nguyễn Văn A'
        await tester.tap(find.text('Nguyễn Văn A'));
        await tester.pumpAndSettle();

        expect(find.byType(StudentDetailPage), findsOneWidget);

        // Pop back to Students list
        final dynamic widgetsAppState = tester.state(find.byType(WidgetsApp));
        widgetsAppState.didPopRoute();
        await tester.pumpAndSettle();

        // 3. Create Class: 'Vật lý 10'
        // Navigate to Classes tab
        await tester.tap(find.byKey(UiKeys.bottomClasses));
        await tester.pumpAndSettle();

        // Tap FAB / Add Class
        await tester.tap(find.byType(FloatingActionButton));
        await tester.pumpAndSettle();

        expect(find.byType(ClassFormPage), findsOneWidget);

        // Enter Class Name
        await tester.enterText(find.byType(TextFormField).first, 'Vật lý 10');
        await tester.pumpAndSettle();

        // Save Class
        await tester.tap(find.byIcon(Icons.check));
        await tester.pumpAndSettle();

        expect(find.byType(ClassFormPage), findsNothing);
        expect(find.text('Vật lý 10'), findsOneWidget);

        // Open Class Detail
        await tester.tap(find.text('Vật lý 10'));
        await tester.pumpAndSettle();

        expect(find.byType(ClassDetailPage), findsOneWidget);

        // 4. Enroll 'Nguyễn Văn A' into 'Vật lý 10'
        // Tap FAB / Add Student to Class
        await tester.tap(find.byIcon(Icons.person_add));
        await tester.pumpAndSettle();

        // Tap Student selector decorator
        await tester.tap(find.byType(InputDecorator).first);
        await tester.pumpAndSettle();

        // Pick 'Nguyễn Văn A' in selector dialog
        await tester.tap(find.text('Nguyễn Văn A'));
        await tester.pumpAndSettle();

        // Tap Enroll / Save button
        await tester.tap(find.byType(ElevatedButton).last);
        await tester.pumpAndSettle();

        // Verify membership on Class Detail roster
        expect(find.text('Nguyễn Văn A'), findsOneWidget);

        // 5. Create Tuition Policy for 'Vật lý 10'
        // Drag TabBar left to reveal 'Học phí' tab
        await tester.drag(find.byType(TabBar), const Offset(-300, 0));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Học phí'));
        await tester.pumpAndSettle(const Duration(seconds: 1));

        // Tap 'Thêm CS' button
        await tester.tap(find.text('Thêm CS'));
        await tester.pumpAndSettle();

        // Tap 'Lưu chính sách' / Save Policy
        await tester.tap(find.byType(ElevatedButton).last);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Pop ClassDetailPage back to ClassList
        widgetsAppState.didPopRoute();
        await tester.pumpAndSettle();

        // 6. Test Dirty Form Global Menu Safety
        // Return to Home via Global Menu
        if (find.byKey(UiKeys.globalDrawer).evaluate().isEmpty) {
          await tester.tap(find.byKey(UiKeys.globalMenuButton));
          await tester.pumpAndSettle();
        }

        await tester.tap(find.byKey(UiKeys.drawerHome));
        await tester.pumpAndSettle();

        // Open Add Student form
        await tester.tap(find.byKey(UiKeys.dashboardQuickAddStudent));
        await tester.pumpAndSettle();

        // Enter text so form becomes dirty
        await tester.enterText(
          find.byType(TextFormField).first,
          'Dirty Student Test B',
        );
        await tester.pumpAndSettle();

        // Open Global Menu -> tap Tuition
        if (find.byKey(UiKeys.globalDrawer).evaluate().isEmpty) {
          await tester.tap(find.byKey(UiKeys.globalMenuButton));
          await tester.pumpAndSettle();
        }

        await tester.tap(find.byKey(UiKeys.drawerTuition));
        await tester.pumpAndSettle();

        // Assert discard prompt appears
        expect(find.byType(AlertDialog), findsOneWidget);

        // Choose Cancel -> stay on form with typed text intact
        await tester.tap(find.byType(TextButton).last);
        await tester.pumpAndSettle();

        expect(find.byType(StudentFormPage), findsOneWidget);
        expect(find.text('Dirty Student Test B'), findsOneWidget);

        // Repeat: Global Menu -> Tuition -> Discard
        if (find.byKey(UiKeys.globalDrawer).evaluate().isEmpty) {
          await tester.tap(find.byKey(UiKeys.globalMenuButton));
          await tester.pumpAndSettle();
        }

        await tester.tap(find.byKey(UiKeys.drawerTuition));
        await tester.pumpAndSettle();

        // Discard is the ElevatedButton in the confirm dialog
        await tester.tap(find.byType(ElevatedButton).last);
        await tester.pumpAndSettle();

        expect(find.byType(StudentFormPage), findsNothing);

        // 7. Test Settings: Dark mode & Emerald palette & English l10n
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
