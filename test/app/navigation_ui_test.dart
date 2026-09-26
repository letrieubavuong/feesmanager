import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tuition2027/app/navigation/app_destination.dart';
import 'package:tuition2027/app/navigation/app_shell.dart';
import 'package:tuition2027/app/navigation/navigation_controller.dart';
import 'package:tuition2027/app/navigation/ui_keys.dart';
import 'package:tuition2027/features/classes/domain/class.dart';
import 'package:tuition2027/features/classes/presentation/class_controller.dart';
import 'package:tuition2027/features/students/domain/student.dart';
import 'package:tuition2027/features/students/presentation/student_controller.dart';
import 'package:tuition2027/features/students/presentation/student_detail_page.dart';
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

        // Assert exact 4 bottom nav items
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

    testWidgets(
      'Non-bottom global destinations (Reports/Settings) do NOT falsely highlight Home',
      (tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final container = ProviderContainer();
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: createTestApp(
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
          ),
        );

        await tester.pumpAndSettle();

        // Navigate to Settings
        container
            .read(navigationControllerProvider.notifier)
            .goTo(AppDestinationId.settings);
        await tester.pumpAndSettle();

        // Verify BottomNavigationBar is hidden on non-bottom global pages (no false Home selection!)
        expect(find.byType(NavigationBar), findsNothing);
      },
    );

    testWidgets(
      'Global Menu drawer opens from nested StudentDetailPage and navigates directly to Tuition',
      (tester) async {
        tester.view.physicalSize = const Size(600, 1000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final container = ProviderContainer();
        addTearDown(container.dispose);

        final testStudent = Student(
          id: 1,
          hoTen: 'Student Test',
          daLuuTru: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: createTestApp(
              home: const AppShell(),
              overrides: [
                classListControllerProvider.overrideWith(
                  () => MockClassListController([]),
                ),
                studentListControllerProvider.overrideWith(
                  () => MockStudentListController([testStudent]),
                ),
                studentDetailProvider(
                  1,
                ).overrideWith((ref) async => testStudent),
              ],
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Navigate to Students tab -> open StudentDetailPage
        container
            .read(navigationControllerProvider.notifier)
            .goTo(AppDestinationId.students);
        await tester.pumpAndSettle();

        await tester.tap(find.text('Student Test'));
        await tester.pumpAndSettle();

        expect(find.byType(StudentDetailPage), findsOneWidget);

        // Tap Global Menu button from nested StudentDetailPage
        await tester.tap(find.byKey(UiKeys.globalMenuButton));
        await tester.pumpAndSettle();

        expect(find.byKey(UiKeys.globalDrawer), findsOneWidget);

        // Tap Tuition in drawer -> clears nested routes and switches to Tuition tab
        await tester.tap(find.byKey(UiKeys.drawerTuition));
        await tester.pumpAndSettle();

        expect(find.byType(StudentDetailPage), findsNothing);
        expect(
          container.read(navigationControllerProvider),
          equals(AppDestinationId.tuition),
        );
      },
    );

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
