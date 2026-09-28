import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tuition2027/app/navigation/app_shell.dart';
import 'package:tuition2027/features/classes/domain/class.dart';
import 'package:tuition2027/features/classes/presentation/class_controller.dart';
import 'package:tuition2027/features/dashboard/domain/dashboard_overview.dart';
import 'package:tuition2027/features/dashboard/presentation/dashboard_controller.dart';
import 'package:tuition2027/features/students/domain/student.dart';
import 'package:tuition2027/features/students/presentation/student_controller.dart';
import '../test_helper.dart';

class MockDashboardController extends DashboardController {
  final DashboardOverview mockOverview;
  MockDashboardController(this.mockOverview);

  @override
  FutureOr<DashboardOverview> build() => mockOverview;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  final sampleOverview = DashboardOverview(
    generatedAt: DateTime.now(),
    todaySessionCount: 0,
    pendingAttendanceCount: 0,
    unfinalizedTuitionStudentCount: 0,
    outstandingDebt: 0,
    todaySessions: [],
    tasks: [],
    warnings: [],
    recentActivities: [],
  );

  group('Phase 13A Accessibility & Narrow Screen Viewport Tests', () {
    testWidgets(
      'AppShell renders without RenderFlex overflow on narrow 320px phone viewport',
      (tester) async {
        tester.view.physicalSize = const Size(320, 568);
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
              dashboardControllerProvider.overrideWith(
                () => MockDashboardController(sampleOverview),
              ),
            ],
          ),
        );

        await tester.pumpAndSettle();

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
            data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
            child: createTestApp(
              home: const AppShell(),
              overrides: [
                classListControllerProvider.overrideWith(
                  () => MockClassListController([]),
                ),
                studentListControllerProvider.overrideWith(
                  () => MockStudentListController([]),
                ),
                dashboardControllerProvider.overrideWith(
                  () => MockDashboardController(sampleOverview),
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
