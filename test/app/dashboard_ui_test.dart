import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tuition2027/app/navigation/app_destination.dart';
import 'package:tuition2027/app/navigation/navigation_controller.dart';
import 'package:tuition2027/app/navigation/ui_keys.dart';
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

  group('Phase 13A Dashboard UI Widget Tests', () {
    testWidgets('DashboardPage renders header, search, quick actions and KPIs', (tester) async {
      final testClass = ClassEntity(
        id: 1,
        tenLop: 'Lớp Luyện Thi A1',
        daLuuTru: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final testStudent = Student(
        id: 1,
        hoTen: 'Nguyễn Văn An',
        daLuuTru: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        createTestApp(
          home: const DashboardPage(),
          overrides: [
            classListControllerProvider.overrideWith(() => MockClassListController([testClass])),
            studentListControllerProvider.overrideWith(() => MockStudentListController([testStudent])),
            todaySessionsProvider.overrideWith((ref) async => <ClassSession>[]),
          ],
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Xin chào, Thầy/Cô!'), findsOneWidget);
      expect(find.byKey(UiKeys.dashboardSearchInput), findsOneWidget);
      expect(find.text('Thao tác nhanh'), findsOneWidget);
      expect(find.byKey(UiKeys.dashboardQuickAddStudent), findsOneWidget);
      expect(find.byKey(UiKeys.dashboardQuickManageClasses), findsOneWidget);
      expect(find.byKey(UiKeys.dashboardQuickViewTuition), findsOneWidget);
      expect(find.byKey(UiKeys.dashboardQuickViewReports), findsOneWidget);

      expect(find.text('Lớp học đang mở'), findsOneWidget);
      expect(find.text('Học sinh đang học'), findsOneWidget);
    });

    testWidgets('Global Search filters students and classes in DashboardPage', (tester) async {
      final testClass = ClassEntity(
        id: 10,
        tenLop: 'Lớp Toán 12A',
        daLuuTru: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final testStudent = Student(
        id: 20,
        hoTen: 'Trần Thị Bình',
        daLuuTru: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        createTestApp(
          home: const DashboardPage(),
          overrides: [
            classListControllerProvider.overrideWith(() => MockClassListController([testClass])),
            studentListControllerProvider.overrideWith(() => MockStudentListController([testStudent])),
            todaySessionsProvider.overrideWith((ref) async => <ClassSession>[]),
          ],
        ),
      );

      await tester.pumpAndSettle();

      // Search for 'Toán'
      await tester.enterText(find.byKey(UiKeys.dashboardSearchInput), 'Toán');
      await tester.pumpAndSettle();

      expect(find.text('Lớp Toán 12A'), findsOneWidget);

      // Search for 'Bình'
      await tester.enterText(find.byKey(UiKeys.dashboardSearchInput), 'Bình');
      await tester.pumpAndSettle();

      expect(find.text('Trần Thị Bình'), findsOneWidget);
    });

    testWidgets('Quick Actions navigate to target canonical domains', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: createTestApp(
            home: const DashboardPage(),
            overrides: [
              classListControllerProvider.overrideWith(() => MockClassListController([])),
              studentListControllerProvider.overrideWith(() => MockStudentListController([])),
              todaySessionsProvider.overrideWith((ref) async => <ClassSession>[]),
            ],
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap 'Quản lý lớp học' quick action -> navigates navigationControllerProvider to classes
      await tester.tap(find.byKey(UiKeys.dashboardQuickManageClasses));
      await tester.pumpAndSettle();

      expect(container.read(navigationControllerProvider), equals(AppDestinationId.classes));
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
