import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:tuition2027/core/database/app_database.dart';
import 'package:tuition2027/core/database/database_provider.dart';
import 'package:tuition2027/features/classes/domain/class.dart';
import 'package:tuition2027/features/classes/presentation/class_controller.dart';
import 'package:tuition2027/features/schedule/domain/class_schedule.dart';
import 'package:tuition2027/features/schedule/domain/student_shift_assignment.dart';
import 'package:tuition2027/features/schedule/presentation/assignment_controller.dart';
import 'package:tuition2027/features/schedule/presentation/assignment_tab.dart';
import 'package:tuition2027/features/schedule/presentation/schedule_controller.dart';
import 'package:tuition2027/features/schedule_conflicts/presentation/schedule_conflict_providers.dart';
import 'package:tuition2027/features/memberships/domain/membership.dart';
import 'package:tuition2027/features/students/domain/student_detail_overview.dart';
import 'package:tuition2027/features/students/domain/student_detail_overview_service.dart';
import 'package:tuition2027/features/students/domain/student.dart';
import 'package:tuition2027/features/students/presentation/student_detail_page.dart';

class MockScheduleController extends ClassScheduleController {
  final List<ClassSchedule> schedules;
  MockScheduleController(this.schedules);

  @override
  Future<List<ClassSchedule>> build(int classId) async {
    return schedules;
  }
}

class MockAssignmentController extends ClassAssignmentController {
  final List<StudentShiftAssignment> assignments;
  MockAssignmentController(this.assignments);

  @override
  Future<List<StudentShiftAssignment>> build(int classId) async {
    return assignments;
  }
}

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  final testClass = ClassEntity(
    id: 1,
    tenLop: 'Test Class',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  final testSchedule = ClassSchedule(
    id: 1,
    idLop: 1,
    thuTrongTuan: 1,
    gioBatDau: '08:00',
    gioKetThuc: '09:00',
    hieuLucTu: '2026-01-01',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  final testStudent = Student(
    id: 1,
    hoTen: 'Test Student',
    sdtPhuHuynh: '0901234567',
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

  late Database db;

  setUp(() async {
    final tempDir = await Directory.systemTemp.createTemp('schedule_ui_test');
    final dbPath = join(tempDir.path, 'schedule_ui_test.db');
    final appDb = AppDatabase(dbName: dbPath);
    db = await appDb.database;
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets('AssignmentTab displays schedule list', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWith((ref) async => db),
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
    expect(find.textContaining('Thứ'), findsOneWidget);
    expect(find.textContaining('08:00 - 09:00'), findsOneWidget);
  });

  testWidgets('AssignmentTab empty state (no schedules)', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWith((ref) async => db),
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
    expect(find.textContaining('Chưa có lịch học định kỳ nào'), findsOneWidget);
  });

  testWidgets('AssignmentTab displays assigned students', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWith((ref) async => db),
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

    expect(find.text('Test Student'), findsOneWidget);
    expect(find.byType(PopupMenuButton<String>), findsOneWidget);
  });

  testWidgets('AssignmentTab - Open Close Dialog', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWith((ref) async => db),
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

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Kết thúc phân ca'));
    await tester.pumpAndSettle();

    expect(find.text('CHỌN NGÀY KẾT THÚC PHÂN CA'), findsOneWidget);
  });

  testWidgets('AssignmentTab - Open Assign Dialog', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWith((ref) async => db),
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

    await tester.tap(find.text('Phân ca mới'));
    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.text('Phân ca học sinh'), findsWidgets);
  });

  testWidgets('Student Detail shows assigned schedule', (tester) async {
    final overview = StudentDetailOverview(
      student: testStudent,
      activeClasses: [
        StudentActiveClassSummary(
          classEntity: testClass,
          membership: ClassMembership(
            id: 1,
            idHocSinh: 1,
            idLop: 1,
            tuNgay: '2026-09-08',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          shiftText: '17:30–19:00 • Thứ Hai',
        ),
      ],
      firstActiveMembershipDate: DateTime.now(),
      financial: const StudentMonthFinancialSummary(
        month: '2026-09',
        finalizedDue: 0,
        totalPaid: 0,
        remainingDebt: 0,
        finalizedInvoiceCount: 0,
        unfinalizedClassCount: 1,
        previewUnfinalizedAmount: 0,
        state: StudentFinancialDisplayState.noFinalizedInvoices,
      ),
      recentAttendance: const [],
      activeBusyTimes: const [],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWith((ref) async => db),
          studentDetailOverviewProvider(1).overrideWith((ref) async => overview),
        ],
        child: const MaterialApp(
          home: Scaffold(body: StudentDetailPage(studentId: 1)),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Test Student'), findsOneWidget);
    expect(find.textContaining('Thứ Hai'), findsOneWidget);
  });
}
