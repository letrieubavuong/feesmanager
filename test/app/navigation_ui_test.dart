import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tuition2027/app/navigation/app_destination.dart';
import 'package:tuition2027/app/navigation/app_shell.dart';
import 'package:tuition2027/app/navigation/ui_keys.dart';
import 'package:tuition2027/features/classes/domain/class.dart';
import 'package:tuition2027/features/classes/presentation/class_controller.dart';
import 'package:tuition2027/features/students/domain/student.dart';
import 'package:tuition2027/features/students/presentation/student_controller.dart';
import '../test_helper.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Phase 13A Navigation UI Widget Tests', () {
    testWidgets(
      'Phone Bottom Navigation contains EXACTLY 4 destinations in order',
      (tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          createTestApp(
            home: const AppShell(),
            overrides: [
              classListControllerProvider.overrideWith(
                () => MockClassListController([]),
              ),
              studentListControllerProvider.overrideWith(
                () => MockStudentListController([]),
              ),
            ],
          ),
        );

        await tester.pumpAndSettle();

        final navBarFinder = find.byType(NavigationBar);
        expect(navBarFinder, findsOneWidget);

        final navBar = tester.widget<NavigationBar>(navBarFinder);
        expect(navBar.destinations.length, equals(4));

        // Assert exact 4 bottom nav items and keys
        expect(find.byKey(UiKeys.bottomHome), findsOneWidget);
        expect(find.byKey(UiKeys.bottomClasses), findsOneWidget);
        expect(find.byKey(UiKeys.bottomStudents), findsOneWidget);
        expect(find.byKey(UiKeys.bottomTuition), findsOneWidget);

        // Assert Attendance, Reports, Settings are ABSENT from bottom nav
        expect(find.text('Điểm danh'), findsNothing);
        expect(find.text('Báo cáo'), findsNothing);
        expect(find.text('Cài đặt'), findsNothing);
      },
    );

    testWidgets('Global Menu drawer opens and navigates to all destinations', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          home: const AppShell(),
          overrides: [
            classListControllerProvider.overrideWith(
              () => MockClassListController([]),
            ),
            studentListControllerProvider.overrideWith(
              () => MockStudentListController([]),
            ),
          ],
        ),
      );

      await tester.pumpAndSettle();

      // Open drawer via menu button
      await tester.tap(find.byKey(UiKeys.globalMenuButton));
      await tester.pumpAndSettle();

      expect(find.byKey(UiKeys.globalDrawer), findsOneWidget);

      // Drawer contains Home, Classes, Students, Tuition, Reports, Settings
      expect(find.byKey(UiKeys.drawerHome), findsOneWidget);
      expect(find.byKey(UiKeys.drawerClasses), findsOneWidget);
      expect(find.byKey(UiKeys.drawerStudents), findsOneWidget);
      expect(find.byKey(UiKeys.drawerTuition), findsOneWidget);
      expect(find.byKey(UiKeys.drawerReports), findsOneWidget);
      expect(find.byKey(UiKeys.drawerSettings), findsOneWidget);

      // Navigate to Settings
      await tester.tap(find.byKey(UiKeys.drawerSettings));
      await tester.pumpAndSettle();

      expect(find.text('GIAO DIỆN & CHỦ ĐỀ'), findsOneWidget);

      // Open drawer from Settings and navigate back to Home
      await tester.tap(find.byKey(UiKeys.globalMenuButton));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(UiKeys.drawerHome));
      await tester.pumpAndSettle();

      expect(find.text('Xin chào, Thầy/Cô!'), findsOneWidget);
    });

    test('AppDestination model metadata consistency', () {
      final bottomDests = AppDestination.bottomNavDestinations;
      expect(bottomDests.length, equals(4));
      expect(bottomDests[0].id, equals(AppDestinationId.home));
      expect(bottomDests[1].id, equals(AppDestinationId.classes));
      expect(bottomDests[2].id, equals(AppDestinationId.students));
      expect(bottomDests[3].id, equals(AppDestinationId.tuition));

      final globalDests = AppDestination.globalMenuDestinations;
      expect(globalDests.length, equals(6));
    });
  });
}

class MockClassListController extends ClassListController {
  final List<ClassEntity> data;
  MockClassListController(this.data);
  @override
  FutureOr<List<ClassEntity>> build() => data;
}

class MockStudentListController extends StudentListController {
  final List<Student> data;
  MockStudentListController(this.data);
  @override
  FutureOr<List<Student>> build() => data;
}
