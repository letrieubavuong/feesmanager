import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tuition2027/core/database/app_database.dart';
import 'package:tuition2027/features/classes/data/class_repository.dart';
import 'package:tuition2027/features/classes/domain/class_service.dart';
import 'package:tuition2027/features/memberships/data/membership_repository.dart';
import 'package:tuition2027/features/memberships/domain/membership_service.dart';
import 'package:tuition2027/features/schedule/data/assignment_repository.dart';
import 'package:tuition2027/features/schedule/data/schedule_repository.dart';
import 'package:tuition2027/features/schedule/domain/bulk_assignment_result.dart';
import 'package:tuition2027/features/schedule/domain/schedule_service.dart';
import 'package:tuition2027/features/schedule_conflicts/data/schedule_constraint_repository.dart';
import 'package:tuition2027/features/schedule_conflicts/domain/schedule_conflict_service.dart';
import 'package:tuition2027/features/session_adjustments/data/session_adjustment_repository.dart';
import 'package:tuition2027/features/sessions/data/session_repository.dart';
import 'package:tuition2027/features/students/data/student_repository.dart';
import 'package:tuition2027/features/students/domain/student_service.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database db;
  late ScheduleDomainService scheduleService;

  Future<Database> createTestDb() async {
    final tempDir = await Directory.systemTemp.createTemp('bulk_assignment_test');
    final dbPath = p.join(
      tempDir.path,
      'test_${DateTime.now().microsecondsSinceEpoch}.db',
    );
    final appDb = AppDatabase(dbName: dbPath);
    return await appDb.database;
  }

  setUp(() async {
    db = await createTestDb();
    final scheduleRepo = ScheduleRepository(db);
    final assignmentRepo = AssignmentRepository(db);
    final membershipRepo = MembershipRepository(db);
    final classRepo = ClassRepository(db);
    final studentRepo = StudentRepository(db);
    final constraintRepo = ScheduleConstraintRepository(db);
    final sessionRepo = SessionRepository(db);
    final adjustmentRepo = SessionAdjustmentRepository(db);

    final membershipService = MembershipService(membershipRepo);
    final classService = ClassService(classRepo, membershipService);
    final studentService = StudentService(studentRepo, membershipService);
    final conflictService = ScheduleConflictService(
      constraintRepo,
      scheduleRepo,
      assignmentRepo,
      sessionRepo,
      adjustmentRepo,
      classService,
    );

    scheduleService = ScheduleDomainService(
      scheduleRepo,
      assignmentRepo,
      membershipService,
      classService,
      studentService,
      conflictService,
    );

    // Setup Class 1 with Schedule A
    final nowStr = DateTime.now().toIso8601String();
    await db.insert('lop', {
      'id': 1,
      'ten_lop': 'Lớp Vật Lý 12',
      'da_luu_tru': 0,
      'created_at': nowStr,
      'updated_at': nowStr,
    });

    await db.insert('lich_hoc', {
      'id': 100,
      'id_lop': 1,
      'thu_trong_tuan': 1,
      'gio_bat_dau': '17:30',
      'gio_ket_thuc': '19:00',
      'hieu_luc_tu': '2026-09-01',
      'created_at': nowStr,
      'updated_at': nowStr,
    });

    // Create 50 students enrolled in Class 1
    for (int i = 1; i <= 50; i++) {
      await db.insert('hoc_sinh', {
        'id': i,
        'ho_ten': 'Học Sinh ${i.toString().padLeft(2, '0')}',
        'da_luu_tru': 0,
        'created_at': nowStr,
        'updated_at': nowStr,
      });

      await db.insert('tham_gia_lop', {
        'id': i,
        'id_hoc_sinh': i,
        'id_lop': 1,
        'tu_ngay': '2026-09-01',
        'created_at': nowStr,
        'updated_at': nowStr,
      });
    }

    // Assign 20 students (1 to 20) to Schedule 100
    for (int i = 1; i <= 20; i++) {
      await db.insert('phan_ca_hoc_sinh', {
        'id': i,
        'id_hoc_sinh': i,
        'id_lop': 1,
        'id_lich_hoc': 100,
        'tu_ngay': '2026-09-01',
        'created_at': nowStr,
        'updated_at': nowStr,
      });
    }
  });

  tearDown(() async {
    await db.close();
  });

  group('Bulk Student Shift Assignment Domain Tests', () {
    test('getBulkAssignmentCandidates excludes already assigned 20 students', () async {
      final candidates = await scheduleService.getBulkAssignmentCandidates(
        classId: 1,
        scheduleId: 100,
        startDate: DateTime(2026, 9, 15),
      );

      // Total 50 students - 20 already assigned = 30 candidates
      expect(candidates.length, equals(30));

      // Candidates should be students 21 to 50
      final candidateIds = candidates.map((s) => s.id).toSet();
      expect(candidateIds.contains(1), isFalse);
      expect(candidateIds.contains(20), isFalse);
      expect(candidateIds.contains(21), isTrue);
      expect(candidateIds.contains(50), isTrue);
    });

    test('previewBulkAssignment separates valid vs blocked students', () async {
      // Preview with student 1 (already assigned) and student 21 (ready)
      final preview = await scheduleService.previewBulkAssignment(
        studentIds: [1, 21, 22, 23],
        classId: 1,
        scheduleId: 100,
        startDate: DateTime(2026, 9, 15),
      );

      expect(preview.readyStudents.length, equals(3));
      expect(preview.blocked.length, equals(1));
      expect(preview.blocked.first.studentId, equals(1));
      expect(preview.blocked.first.status, equals(BulkAssignmentStatus.alreadyAssigned));
    });

    test('assignStudentsBulk executes in ONE transaction and persists assignments', () async {
      final result = await scheduleService.assignStudentsBulk(
        studentIds: [21, 22, 23, 24, 25, 26, 27, 28, 29, 30],
        classId: 1,
        scheduleId: 100,
        startDate: DateTime(2026, 9, 15),
      );

      expect(result.totalAttempted, equals(10));
      expect(result.successCount, equals(10));

      // Re-query candidates -> 30 candidates - 10 new assignments = 20 candidates left
      final candidatesAfter = await scheduleService.getBulkAssignmentCandidates(
        classId: 1,
        scheduleId: 100,
        startDate: DateTime(2026, 9, 15),
      );

      expect(candidatesAfter.length, equals(20));
    });

    test('Expired old assignment allows student to be candidate for new date', () async {
      // Student 1's assignment was closed on 2026-09-10
      await db.update(
        'phan_ca_hoc_sinh',
        {'den_ngay': '2026-09-10'},
        where: 'id = ?',
        whereArgs: [1],
      );

      // Candidate query for startDate = 2026-10-01
      final candidates = await scheduleService.getBulkAssignmentCandidates(
        classId: 1,
        scheduleId: 100,
        startDate: DateTime(2026, 10, 1),
      );

      // Student 1's old assignment ended 2026-09-10 -> DOES NOT OVERLAP with 2026-10-01
      // Student 1 IS NOW A VALID CANDIDATE AGAIN!
      final candidateIds = candidates.map((s) => s.id).toSet();
      expect(candidateIds.contains(1), isTrue);
    });
  });
}
