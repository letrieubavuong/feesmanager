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
import 'package:tuition2027/features/students/presentation/student_form_page.dart';
import '../test_helper.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Phase 13A Dirty Form Protection Widget Tests', () {
    testWidgets(
      'StudentFormPage tracks edits and prompts discard warning on back pop',
      (tester) async {
        await tester.pumpWidget(createTestApp(home: const StudentFormPage()));

        await tester.pumpAndSettle();

        // Enter text into Full Name field -> makes form dirty
        await tester.enterText(
          find.byType(TextFormField).first,
          'Nguyễn Văn Test',
        );
        await tester.pumpAndSettle();

        // Attempt Android Back / Pop -> triggers PopScope confirmation dialog
        final dynamic widgetsAppState = tester.state(find.byType(WidgetsApp));
        widgetsAppState.didPopRoute();
        await tester.pumpAndSettle();

        expect(find.text('Rời khỏi trang?'), findsOneWidget);
        expect(find.text('Bỏ thay đổi'), findsOneWidget);
        expect(find.text('Tiếp tục chỉnh sửa'), findsOneWidget);

        // Tap 'Tiếp tục chỉnh sửa' -> keeps user on StudentFormPage
        await tester.tap(find.text('Tiếp tục chỉnh sửa'));
        await tester.pumpAndSettle();

        expect(find.byType(StudentFormPage), findsOneWidget);
      },
    );

    testWidgets(
      'StudentFormPage prompt allows discarding changes and leaving page',
      (tester) async {
        await tester.pumpWidget(
          createTestApp(home: const Scaffold(body: StudentFormPage())),
        );

        await tester.pumpAndSettle();

        await tester.enterText(
          find.byType(TextFormField).first,
          'Nguyễn Văn Test',
        );
        await tester.pumpAndSettle();

        // Pop route
        final dynamic widgetsAppState = tester.state(find.byType(WidgetsApp));
        widgetsAppState.didPopRoute();
        await tester.pumpAndSettle();

        // Tap 'Bỏ thay đổi' -> discards and pops route
        await tester.tap(find.text('Bỏ thay đổi'));
        await tester.pumpAndSettle();

        expect(find.byType(StudentFormPage), findsNothing);
      },
    );

    testWidgets(
      'Dirty StudentFormPage prompts warning when navigating via Global Menu; Cancel keeps form and entered text',
      (tester) async {
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

        // Tap Quick Action 'Thêm học sinh' -> opens StudentFormPage
        await tester.tap(find.byKey(UiKeys.dashboardQuickAddStudent));
        await tester.pumpAndSettle();

        expect(find.byType(StudentFormPage), findsOneWidget);

        // Enter text into Full Name -> form becomes dirty
        await tester.enterText(
          find.byType(TextFormField).first,
          'Học Sinh Dirty Test',
        );
        await tester.pumpAndSettle();

        // Tap Global Menu button -> drawer opens
        await tester.tap(find.byKey(UiKeys.globalMenuButton));
        await tester.pumpAndSettle();

        expect(find.byKey(UiKeys.globalDrawer), findsOneWidget);

        // Tap 'Học phí' in drawer -> triggers unsaved changes confirmation dialog
        await tester.tap(find.byKey(UiKeys.drawerTuition));
        await tester.pumpAndSettle();

        expect(find.text('Rời khỏi trang?'), findsOneWidget);
        expect(find.text('Bỏ thay đổi'), findsOneWidget);
        expect(find.text('Tiếp tục chỉnh sửa'), findsOneWidget);

        // Tap 'Tiếp tục chỉnh sửa' (Cancel) -> stays on StudentFormPage with typed text intact
        await tester.tap(find.text('Tiếp tục chỉnh sửa'));
        await tester.pumpAndSettle();

        expect(find.byType(StudentFormPage), findsOneWidget);
        expect(find.text('Học Sinh Dirty Test'), findsOneWidget);
        expect(
          container.read(navigationControllerProvider),
          equals(AppDestinationId.home),
        );
      },
    );

    testWidgets(
      'Dirty StudentFormPage prompt allows Discarding changes when leaving via Global Menu',
      (tester) async {
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

        await tester.tap(find.byKey(UiKeys.dashboardQuickAddStudent));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byType(TextFormField).first,
          'Học Sinh Dirty Test',
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(UiKeys.globalMenuButton));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(UiKeys.drawerTuition));
        await tester.pumpAndSettle();

        // Tap 'Bỏ thay đổi' (Discard) -> closes form and switches destination to Tuition
        await tester.tap(find.text('Bỏ thay đổi'));
        await tester.pumpAndSettle();

        expect(find.byType(StudentFormPage), findsNothing);
        expect(
          container.read(navigationControllerProvider),
          equals(AppDestinationId.tuition),
        );
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
