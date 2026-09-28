import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuition2027/app/navigation/ui_keys.dart';
import 'package:tuition2027/features/classes/domain/class.dart';
import 'package:tuition2027/features/classes/domain/class_filter.dart';
import 'package:tuition2027/features/classes/presentation/class_controller.dart';
import 'package:tuition2027/features/classes/presentation/class_list_page.dart';
import 'package:tuition2027/features/memberships/presentation/membership_providers.dart';
import 'package:tuition2027/features/students/domain/student.dart';
import 'package:tuition2027/features/students/presentation/student_controller.dart';
import 'package:tuition2027/features/students/presentation/student_list_page.dart';
import '../test_helper.dart';

class MockStudentListController extends StudentListController {
  final List<Student> activeList;
  final List<Student> archivedList;
  bool? currentFilter = false;
  String currentQuery = '';

  MockStudentListController({
    required this.activeList,
    required this.archivedList,
  });

  @override
  FutureOr<List<Student>> build() {
    List<Student> base = [];
    if (currentFilter == false) {
      base = activeList;
    } else if (currentFilter == true) {
      base = archivedList;
    } else {
      base = [...activeList, ...archivedList];
    }
    if (currentQuery.isNotEmpty) {
      return base.where((s) => s.hoTen.contains(currentQuery)).toList();
    }
    return base;
  }

  @override
  void setFilter(bool? showArchived) {
    currentFilter = showArchived;
    ref.invalidateSelf();
  }

  @override
  Future<void> search(String query) async {
    currentQuery = query;
    ref.invalidateSelf();
  }
}

class MockClassListController extends ClassListController {
  final List<ClassEntity> activeList;
  final List<ClassEntity> archivedList;
  ClassFilter currentFilter = ClassFilter.active;
  String currentQuery = '';

  MockClassListController({
    required this.activeList,
    required this.archivedList,
  });

  @override
  FutureOr<List<ClassEntity>> build() {
    List<ClassEntity> base = [];
    if (currentFilter == ClassFilter.active) {
      base = activeList;
    } else if (currentFilter == ClassFilter.archived) {
      base = archivedList;
    } else {
      base = [...activeList, ...archivedList];
    }
    if (currentQuery.isNotEmpty) {
      return base.where((c) => c.tenLop.contains(currentQuery)).toList();
    }
    return base;
  }

  @override
  void setFilter(ClassFilter filter) {
    currentFilter = filter;
    ref.invalidateSelf();
  }

  @override
  Future<void> search(String query) async {
    currentQuery = query;
    ref.invalidateSelf();
  }
}

void main() {
  final now = DateTime.now();
  final studentActive = Student(
    id: 1,
    hoTen: 'Nguyễn Văn Active',
    daLuuTru: false,
    createdAt: now,
    updatedAt: now,
  );
  final studentStopped = Student(
    id: 2,
    hoTen: 'Trần Thị Stopped',
    daLuuTru: true,
    createdAt: now,
    updatedAt: now,
  );

  final classActive = ClassEntity(
    id: 10,
    tenLop: 'Lớp Toán Active',
    daLuuTru: false,
    createdAt: now,
    updatedAt: now,
  );
  final classStopped = ClassEntity(
    id: 20,
    tenLop: 'Lớp Lý Stopped',
    daLuuTru: true,
    createdAt: now,
    updatedAt: now,
  );

  group('Phase 14B.1.1 2-State Filter Tests', () {
    testWidgets(
      'StudentListPage has 2-state toggle without "Tất cả" and preserves search',
      (tester) async {
        final controller = MockStudentListController(
          activeList: [studentActive],
          archivedList: [studentStopped],
        );

        await tester.pumpWidget(
          createTestApp(
            home: const StudentListPage(),
            overrides: [
              studentListControllerProvider.overrideWith(() => controller),
            ],
          ),
        );
        await tester.pumpAndSettle();

        // No "Tất cả" option anywhere
        expect(find.text('Tất cả'), findsNothing);

        // Default: Active student shown
        expect(find.text('Nguyễn Văn Active'), findsOneWidget);
        expect(find.text('Trần Thị Stopped'), findsNothing);

        // Type search
        await tester.enterText(find.byKey(UiKeys.studentSearch), 'Nguyễn');
        await tester.pumpAndSettle();

        // Switch to Ngừng học
        await tester.tap(find.byKey(UiKeys.studentArchivedFilter));
        await tester.pumpAndSettle();

        // Search text remains 'Nguyễn'
        expect(find.widgetWithText(TextField, 'Nguyễn'), findsOneWidget);

        // Switch back to Đang học
        await tester.tap(find.byKey(UiKeys.studentActiveFilter));
        await tester.pumpAndSettle();

        expect(find.text('Nguyễn Văn Active'), findsOneWidget);
      },
    );

    testWidgets('ClassListPage has 2-state toggle without "Tất cả"', (
      tester,
    ) async {
      final controller = MockClassListController(
        activeList: [classActive],
        archivedList: [classStopped],
      );

      await tester.pumpWidget(
        createTestApp(
          home: const ClassListPage(),
          overrides: [
            classListControllerProvider.overrideWith(() => controller),
            classSizeProvider.overrideWith((ref, id) => 10),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // No "Tất cả" option
      expect(find.text('Tất cả'), findsNothing);

      // Default: Active class shown
      expect(find.text('Lớp Toán Active'), findsOneWidget);
      expect(find.text('Lớp Lý Stopped'), findsNothing);

      // Switch to Ngừng hoạt động
      await tester.tap(find.byKey(UiKeys.classArchivedFilter));
      await tester.pumpAndSettle();

      expect(find.text('Lớp Lý Stopped'), findsOneWidget);
      expect(find.text('Lớp Toán Active'), findsNothing);
    });
  });
}
