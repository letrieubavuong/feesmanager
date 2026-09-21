import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuition2027/features/schedule/presentation/schedule_tab.dart';
import 'package:tuition2027/features/schedule/presentation/assignment_tab.dart';
import 'package:tuition2027/features/schedule/presentation/schedule_controller.dart';
import 'package:tuition2027/features/schedule/presentation/assignment_controller.dart';
import 'package:tuition2027/features/schedule/domain/class_schedule.dart';
import 'package:tuition2027/features/schedule/domain/student_shift_assignment.dart';
import 'package:tuition2027/features/students/presentation/student_detail_page.dart';
import 'package:tuition2027/features/students/domain/student.dart';
import 'package:tuition2027/features/classes/domain/class.dart';
import 'package:tuition2027/features/classes/presentation/class_controller.dart';

void main() {
  final testSchedule = ClassSchedule(
    id: 1,
    idLop: 1,
    thuTrongTuan: 1,
    gioBatDau: '08:00',
    gioKetThuc: '09:00',
    hieuLucTu: '2020-01-01',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  final testStudent = Student(
    id: 1,
    hoTen: 'Test Student',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  final testAssignment = StudentShiftAssignment(
    id: 1,
    idHocSinh: 1,
    idLop: 1,
    idLichHoc: 1,
    tuNgay: '2026-01-01',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  final testClass = ClassEntity(
    id: 1,
    tenLop: 'Test Class',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  testWidgets('ScheduleTab empty state', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          classScheduleControllerProvider(
            1,
          ).overrideWith(() => MockScheduleController([])),
        ],
        child: const MaterialApp(home: Scaffold(body: ScheduleTab(classId: 1))),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Lớp chưa có lịch học nào.'), findsOneWidget);
  });

  testWidgets('ScheduleTab shows multiple shifts', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          classScheduleControllerProvider(
            1,
          ).overrideWith(() => MockScheduleController([testSchedule])),
        ],
        child: const MaterialApp(home: Scaffold(body: ScheduleTab(classId: 1))),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.textContaining('Thứ Hai'), findsOneWidget);
    expect(find.textContaining('08:00 - 09:00'), findsOneWidget);
  });

  testWidgets('AssignmentTab empty state (no schedules)', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          classScheduleControllerProvider(
            1,
          ).overrideWith(() => MockScheduleController([])),
          classAssignmentControllerProvider(
            1,
          ).overrideWith(() => MockAssignmentController([])),
        ],
        child: const MaterialApp(
          home: Scaffold(body: AssignmentTab(classId: 1)),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Cần tạo lịch học trước khi phân ca.'), findsOneWidget);
  });

  testWidgets('AssignmentTab displays assigned students', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          classScheduleControllerProvider(
            1,
          ).overrideWith(() => MockScheduleController([testSchedule])),
          classAssignmentControllerProvider(
            1,
          ).overrideWith(() => MockAssignmentController([testAssignment])),
          studentDetailProvider(1).overrideWith((ref) async => testStudent),
        ],
        child: const MaterialApp(
          home: Scaffold(body: AssignmentTab(classId: 1)),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Tap expansion tile to see children
    await tester.tap(find.textContaining('Thứ Hai'));
    await tester.pumpAndSettle();

    expect(find.text('Test Student'), findsOneWidget);
    expect(find.byIcon(Icons.swap_horiz), findsOneWidget);
    expect(find.byIcon(Icons.close), findsOneWidget);
  });

  testWidgets('AssignmentTab - Open Close Dialog', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          classScheduleControllerProvider(
            1,
          ).overrideWith(() => MockScheduleController([testSchedule])),
          classAssignmentControllerProvider(
            1,
          ).overrideWith(() => MockAssignmentController([testAssignment])),
          studentDetailProvider(1).overrideWith((ref) async => testStudent),
        ],
        child: const MaterialApp(
          home: Scaffold(body: AssignmentTab(classId: 1)),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Thứ Hai'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.text('Kết thúc phân ca'), findsOneWidget);
    expect(find.text('Xác nhận'), findsOneWidget);
  });

  testWidgets('AssignmentTab - Open Assign Dialog', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          classScheduleControllerProvider(
            1,
          ).overrideWith(() => MockScheduleController([testSchedule])),
          classAssignmentControllerProvider(
            1,
          ).overrideWith(() => MockAssignmentController([])),
        ],
        child: const MaterialApp(
          home: Scaffold(body: AssignmentTab(classId: 1)),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Thứ Hai'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Phân học sinh vào ca này'));
    await tester.pumpAndSettle();

    expect(find.text('Phân ca cho học sinh'), findsOneWidget);
  });

  testWidgets('Student Detail shows assigned schedule', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          studentDetailProvider(1).overrideWith((ref) async => testStudent),
          studentScheduleProvider(
            1,
          ).overrideWith((ref) async => [testAssignment]),
          scheduleDetailProvider(1).overrideWith((ref) async => testSchedule),
          classDetailProvider(1).overrideWith((ref) async => testClass),
          studentMembershipHistoryProvider(1).overrideWith((ref) async => []),
        ],
        child: const MaterialApp(
          home: Scaffold(body: StudentDetailPage(studentId: 1)),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Lịch học (Phân ca)'), findsWidgets);
    expect(find.textContaining('Thứ Hai'), findsWidgets);
    expect(find.textContaining('08:00 - 09:00'), findsWidgets);
  });
}

class MockScheduleController extends ClassScheduleController {
  final List<ClassSchedule> data;
  MockScheduleController(this.data);
  @override
  FutureOr<List<ClassSchedule>> build(int classId) => data;
}

class MockAssignmentController extends ClassAssignmentController {
  final List<StudentShiftAssignment> data;
  MockAssignmentController(this.data);
  @override
  FutureOr<List<StudentShiftAssignment>> build(int classId) => data;
}
