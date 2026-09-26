import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tuition2027/app/navigation/app_shell.dart';
import 'package:tuition2027/features/classes/domain/class.dart';
import 'package:tuition2027/features/classes/presentation/class_controller.dart';
import 'package:tuition2027/features/dashboard/presentation/dashboard_page.dart';
import 'package:tuition2027/features/sessions/domain/class_session.dart';
import 'package:tuition2027/features/students/domain/student.dart';
import 'package:tuition2027/features/students/presentation/student_controller.dart';
import '../test_helper.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Phase 13A Accessibility & Narrow Screen Viewport Tests', () {
    testWidgets(
      'AppShell renders without RenderFlex overflow on narrow 320px phone viewport',
      (tester) async {
        tester.view.physicalSize = const Size(
          320,
          568,
        ); // Narrow iPhone SE size
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
              todaySessionsProvider.overrideWith(
                (ref) async => <ClassSession>[],
              ),
            ],
          ),
        );

        await tester.pumpAndSettle();

        // Verify no overflow errors occurred during build or layout
        expect(tester.takeException(), isNull);
        expect(find.byType(NavigationBar), findsOneWidget);
      },
    );

    testWidgets(
      'AppShell handles high text scale factor (1.5x) without critical layout exceptions',
      (tester) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(
              textScaler: TextScaler.linear(1.5), // High text scale
            ),
            child: createTestApp(
              home: const AppShell(),
              overrides: [
                classListControllerProvider.overrideWith(
                  () => MockClassListController([]),
                ),
                studentListControllerProvider.overrideWith(
                  () => MockStudentListController([]),
                ),
                todaySessionsProvider.overrideWith(
                  (ref) async => <ClassSession>[],
                ),
              ],
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      },
    );
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
