import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' hide equals;
import 'package:tuition2027/core/database/app_database.dart';
import 'package:tuition2027/features/classes/data/class_repository.dart';
import 'package:tuition2027/features/classes/domain/class_service.dart';
import 'package:tuition2027/features/memberships/data/membership_repository.dart';
import 'package:tuition2027/features/memberships/domain/membership_service.dart';
import 'package:tuition2027/features/schedule/data/assignment_repository.dart';
import 'package:tuition2027/features/schedule/data/schedule_repository.dart';
import 'package:tuition2027/features/schedule/domain/class_schedule.dart';
import 'package:tuition2027/features/schedule/domain/schedule_service.dart';
import 'package:tuition2027/features/schedule_conflicts/data/schedule_constraint_repository.dart';
import 'package:tuition2027/features/schedule_conflicts/domain/schedule_conflict_reason_code.dart';
import 'package:tuition2027/features/schedule_conflicts/domain/schedule_conflict_service.dart';
import 'package:tuition2027/features/schedule_conflicts/domain/schedule_constraint.dart';
import 'package:tuition2027/features/session_adjustments/data/session_adjustment_repository.dart';
import 'package:tuition2027/features/sessions/data/session_repository.dart';
import 'package:tuition2027/features/students/data/student_repository.dart';
import 'package:tuition2027/features/students/domain/student_service.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('ScheduleConflictService Exhaustive Domain Tests', () {
    late Database db;
    late ScheduleConstraintRepository constraintRepo;
    late ScheduleRepository scheduleRepo;
    late AssignmentRepository assignmentRepo;
    late SessionRepository sessionRepo;
    late SessionAdjustmentRepository adjustmentRepo;
    late ClassRepository classRepo;
    late ClassService classService;
    late ScheduleConflictService conflictService;
    late ScheduleDomainService scheduleDomainService;
    late MembershipService membershipService;

    setUp(() async {
      final tempDir = await Directory.systemTemp.createTemp('conflict_test');
      final dbPath = join(tempDir.path, 'conflict_test.db');
      final appDb = AppDatabase(dbName: dbPath);
      db = await appDb.database;

      constraintRepo = ScheduleConstraintRepository(db);
      scheduleRepo = ScheduleRepository(db);
      assignmentRepo = AssignmentRepository(db);
      sessionRepo = SessionRepository(db);
      adjustmentRepo = SessionAdjustmentRepository(db);
      classRepo = ClassRepository(db);

      final memberRepo = MembershipRepository(db);
      membershipService = MembershipService(memberRepo);
      classService = ClassService(classRepo, membershipService);
      final studentRepo = StudentRepository(db);
      final studentService = StudentService(studentRepo, membershipService);

      conflictService = ScheduleConflictService(
        constraintRepo,
        scheduleRepo,
        assignmentRepo,
        sessionRepo,
        adjustmentRepo,
        classService,
      );

      scheduleDomainService = ScheduleDomainService(
        scheduleRepo,
        assignmentRepo,
        membershipService,
        classService,
        studentService,
        conflictService,
      );

      // Seed Student 1 & Class 1
      await db.execute('''
        INSERT INTO hoc_sinh (id, ho_ten, sdt_phu_huynh, created_at, updated_at)
        VALUES (1, 'Student 1', '0901234567', '2026-01-01T00:00:00.000', '2026-01-01T00:00:00.000')
      ''');

      await db.execute('''
        INSERT INTO lop (id, ten_lop, created_at, updated_at)
        VALUES (1, 'Class 1', '2026-01-01T00:00:00.000', '2026-01-01T00:00:00.000')
      ''');

      await db.execute('''
        INSERT INTO lop (id, ten_lop, created_at, updated_at)
        VALUES (2, 'Class 2', '2026-01-01T00:00:00.000', '2026-01-01T00:00:00.000')
      ''');

      await membershipService.enrollStudent(
        studentId: 1,
        classId: 1,
        joinDate: DateTime.parse('2026-01-01'),
      );

      await membershipService.enrollStudent(
        studentId: 1,
        classId: 2,
        joinDate: DateTime.parse('2026-01-01'),
      );
    });

    tearDown(() async {
      await db.close();
    });

    // --- TESTS A..G: Overlap Classifications ---

    test('Test A: Exact Overlap -> EXACT_OVERLAP hard conflict', () async {
      // Existing schedule: Mon 08:00-09:00
      final s1 = await scheduleRepo.create(
        ClassSchedule(
          idLop: 1,
          thuTrongTuan: 1,
          gioBatDau: '08:00',
          gioKetThuc: '09:00',
          hieuLucTu: '2026-01-01',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      await scheduleDomainService.assignStudent(
        studentId: 1,
        classId: 1,
        scheduleId: s1,
        startDate: DateTime(2026, 1, 1),
      );

      // Target candidate schedule for Class 2: Mon 08:00-09:00
      final s2 = await scheduleRepo.create(
        ClassSchedule(
          idLop: 2,
          thuTrongTuan: 1,
          gioBatDau: '08:00',
          gioKetThuc: '09:00',
          hieuLucTu: '2026-01-01',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      final res = await conflictService.evaluateCandidateAssignment(
        studentId: 1,
        targetScheduleId: s2,
        startDate: '2026-01-01',
      );

      expect(res.canAssign, isFalse);
      expect(
        res.hardConflicts.first.reasonCode,
        ScheduleConflictReasonCode.EXACT_OVERLAP,
      );
    });

    test(
      'Test B: Candidate starts inside existing -> PARTIAL_OVERLAP hard conflict',
      () async {
        final s1 = await scheduleRepo.create(
          ClassSchedule(
            idLop: 1,
            thuTrongTuan: 1,
            gioBatDau: '08:00',
            gioKetThuc: '10:00',
            hieuLucTu: '2026-01-01',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        await scheduleDomainService.assignStudent(
          studentId: 1,
          classId: 1,
          scheduleId: s1,
          startDate: DateTime(2026, 1, 1),
        );

        final s2 = await scheduleRepo.create(
          ClassSchedule(
            idLop: 2,
            thuTrongTuan: 1,
            gioBatDau: '08:30',
            gioKetThuc: '10:30',
            hieuLucTu: '2026-01-01',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        final res = await conflictService.evaluateCandidateAssignment(
          studentId: 1,
          targetScheduleId: s2,
          startDate: '2026-01-01',
        );

        expect(res.canAssign, isFalse);
        expect(
          res.hardConflicts.first.reasonCode,
          ScheduleConflictReasonCode.PARTIAL_OVERLAP,
        );
      },
    );

    test(
      'Test D: Candidate contains existing -> CONTAINED_OVERLAP hard conflict',
      () async {
        final s1 = await scheduleRepo.create(
          ClassSchedule(
            idLop: 1,
            thuTrongTuan: 1,
            gioBatDau: '08:30',
            gioKetThuc: '09:30',
            hieuLucTu: '2026-01-01',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        await scheduleDomainService.assignStudent(
          studentId: 1,
          classId: 1,
          scheduleId: s1,
          startDate: DateTime(2026, 1, 1),
        );

        final s2 = await scheduleRepo.create(
          ClassSchedule(
            idLop: 2,
            thuTrongTuan: 1,
            gioBatDau: '08:00',
            gioKetThuc: '10:00',
            hieuLucTu: '2026-01-01',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        final res = await conflictService.evaluateCandidateAssignment(
          studentId: 1,
          targetScheduleId: s2,
          startDate: '2026-01-01',
        );

        expect(res.canAssign, isFalse);
        expect(
          res.hardConflicts.first.reasonCode,
          ScheduleConflictReasonCode.CONTAINED_OVERLAP,
        );
      },
    );

    test(
      'Test F: Adjacent time intervals (end == next start) -> NO conflict',
      () async {
        final s1 = await scheduleRepo.create(
          ClassSchedule(
            idLop: 1,
            thuTrongTuan: 1,
            gioBatDau: '08:00',
            gioKetThuc: '09:00',
            hieuLucTu: '2026-01-01',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        await scheduleDomainService.assignStudent(
          studentId: 1,
          classId: 1,
          scheduleId: s1,
          startDate: DateTime(2026, 1, 1),
        );

        final s2 = await scheduleRepo.create(
          ClassSchedule(
            idLop: 2,
            thuTrongTuan: 1,
            gioBatDau: '09:00',
            gioKetThuc: '10:00',
            hieuLucTu: '2026-01-01',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        final res = await conflictService.evaluateCandidateAssignment(
          studentId: 1,
          targetScheduleId: s2,
          startDate: '2026-01-01',
        );

        expect(res.canAssign, isTrue);
        expect(res.hardConflicts, isEmpty);
      },
    );

    // --- TESTS H..K: Date & Weekday Matching ---

    test('Test H: Same time, different weekday -> NO conflict', () async {
      final s1 = await scheduleRepo.create(
        ClassSchedule(
          idLop: 1,
          thuTrongTuan: 1, // Mon
          gioBatDau: '08:00',
          gioKetThuc: '09:00',
          hieuLucTu: '2026-01-01',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      await scheduleDomainService.assignStudent(
        studentId: 1,
        classId: 1,
        scheduleId: s1,
        startDate: DateTime(2026, 1, 1),
      );

      final s2 = await scheduleRepo.create(
        ClassSchedule(
          idLop: 2,
          thuTrongTuan: 2, // Tue
          gioBatDau: '08:00',
          gioKetThuc: '09:00',
          hieuLucTu: '2026-01-01',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      final res = await conflictService.evaluateCandidateAssignment(
        studentId: 1,
        targetScheduleId: s2,
        startDate: '2026-01-01',
      );

      expect(res.canAssign, isTrue);
    });

    test(
      'Test I: Same weekday/time, non-intersecting effective ranges -> NO conflict',
      () async {
        final s1 = await scheduleRepo.create(
          ClassSchedule(
            idLop: 1,
            thuTrongTuan: 1,
            gioBatDau: '08:00',
            gioKetThuc: '09:00',
            hieuLucTu: '2026-01-01',
            hieuLucDen: '2026-03-31',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        await scheduleDomainService.assignStudent(
          studentId: 1,
          classId: 1,
          scheduleId: s1,
          startDate: DateTime(2026, 1, 1),
          endDate: DateTime(2026, 3, 31),
        );

        final s2 = await scheduleRepo.create(
          ClassSchedule(
            idLop: 2,
            thuTrongTuan: 1,
            gioBatDau: '08:00',
            gioKetThuc: '09:00',
            hieuLucTu: '2026-04-01',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        final res = await conflictService.evaluateCandidateAssignment(
          studentId: 1,
          targetScheduleId: s2,
          startDate: '2026-04-01',
        );

        expect(res.canAssign, isTrue);
      },
    );

    // --- TESTS L..N: Hard Block vs Soft Preference ---

    test('Test L: HARD_BLOCK constraint -> canAssign = false', () async {
      await constraintRepo.createConstraint(
        ScheduleConstraint(
          studentId: 1,
          type: ConstraintType.HARD_BLOCK,
          occurrenceType: OccurrenceType.DINH_KY,
          weekday: 1,
          startTime: '17:00',
          endTime: '19:00',
          effectiveFrom: '2026-01-01',
        ),
      );

      final s1 = await scheduleRepo.create(
        ClassSchedule(
          idLop: 1,
          thuTrongTuan: 1,
          gioBatDau: '17:30',
          gioKetThuc: '19:00',
          hieuLucTu: '2026-01-01',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      final res = await conflictService.evaluateCandidateAssignment(
        studentId: 1,
        targetScheduleId: s1,
        startDate: '2026-01-01',
      );

      expect(res.canAssign, isFalse);
      expect(
        res.hardConflicts.first.reasonCode,
        ScheduleConflictReasonCode.HARD_BLOCK,
      );
    });

    test(
      'Test N: SOFT_PREFERENCE constraint -> canAssign = true, softWarnings nonempty',
      () async {
        await constraintRepo.createConstraint(
          ScheduleConstraint(
            studentId: 1,
            type: ConstraintType.SOFT_PREFERENCE,
            occurrenceType: OccurrenceType.DINH_KY,
            weekday: 1,
            startTime: '17:00',
            endTime: '19:00',
            effectiveFrom: '2026-01-01',
          ),
        );

        final s1 = await scheduleRepo.create(
          ClassSchedule(
            idLop: 1,
            thuTrongTuan: 1,
            gioBatDau: '17:30',
            gioKetThuc: '19:00',
            hieuLucTu: '2026-01-01',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        final res = await conflictService.evaluateCandidateAssignment(
          studentId: 1,
          targetScheduleId: s1,
          startDate: '2026-01-01',
        );

        expect(res.canAssign, isTrue);
        expect(res.softWarnings, isNotEmpty);
        expect(
          res.softWarnings.first.reasonCode,
          ScheduleConflictReasonCode.SOFT_PREFERENCE,
        );
      },
    );

    // --- TESTS O..S: Other Center & Travel Buffer ---

    test(
      'Test O & P: OTHER_CENTER actual overlap -> HARD, insufficient buffer -> SOFT_WARNING',
      () async {
        // OTHER_CENTER 08:00-09:00, buffer 30 mins
        await constraintRepo.createConstraint(
          ScheduleConstraint(
            studentId: 1,
            type: ConstraintType.OTHER_CENTER,
            occurrenceType: OccurrenceType.DINH_KY,
            weekday: 1,
            startTime: '08:00',
            endTime: '09:00',
            effectiveFrom: '2026-01-01',
            travelBufferMinutes: 30,
            sourceName: 'Center B',
          ),
        );

        // Candidate 1: 08:30-10:00 (overlaps) -> HARD CONFLICT
        final s1 = await scheduleRepo.create(
          ClassSchedule(
            idLop: 1,
            thuTrongTuan: 1,
            gioBatDau: '08:30',
            gioKetThuc: '10:00',
            hieuLucTu: '2026-01-01',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        var res = await conflictService.evaluateCandidateAssignment(
          studentId: 1,
          targetScheduleId: s1,
          startDate: '2026-01-01',
        );
        expect(res.canAssign, isFalse);
        expect(
          res.hardConflicts.first.reasonCode,
          ScheduleConflictReasonCode.OTHER_CENTER_CLASS,
        );

        // Candidate 2: 09:15-10:15 (gap = 15 mins < 30 mins buffer) -> SOFT WARNING
        final s2 = await scheduleRepo.create(
          ClassSchedule(
            idLop: 2,
            thuTrongTuan: 1,
            gioBatDau: '09:15',
            gioKetThuc: '10:15',
            hieuLucTu: '2026-01-01',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        res = await conflictService.evaluateCandidateAssignment(
          studentId: 1,
          targetScheduleId: s2,
          startDate: '2026-01-01',
        );
        expect(res.canAssign, isTrue);
        expect(res.softWarnings, isNotEmpty);
        expect(
          res.softWarnings.first.reasonCode,
          ScheduleConflictReasonCode.TRAVEL_BUFFER,
        );

        // Candidate 3: 09:30-10:30 (gap = 30 mins == buffer) -> CLEAR
        final s3 = await scheduleRepo.create(
          ClassSchedule(
            idLop: 2,
            thuTrongTuan: 1,
            gioBatDau: '09:30',
            gioKetThuc: '10:30',
            hieuLucTu: '2026-01-01',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        res = await conflictService.evaluateCandidateAssignment(
          studentId: 1,
          targetScheduleId: s3,
          startDate: '2026-01-01',
        );
        expect(res.canAssign, isTrue);
        expect(res.softWarnings, isEmpty);
      },
    );

    // --- TESTS T..W: One-Off Interactions ---

    test(
      'Test T: Recurring candidate intersects one-off HARD_BLOCK -> hard conflict',
      () async {
        // One-off hard block on Mon 2026-10-12 17:30-19:00
        await constraintRepo.createConstraint(
          ScheduleConstraint(
            studentId: 1,
            type: ConstraintType.HARD_BLOCK,
            occurrenceType: OccurrenceType.MOT_LAN,
            specificDate: '2026-10-12', // Mon
            startTime: '17:30',
            endTime: '19:00',
          ),
        );

        final s1 = await scheduleRepo.create(
          ClassSchedule(
            idLop: 1,
            thuTrongTuan: 1,
            gioBatDau: '17:30',
            gioKetThuc: '19:00',
            hieuLucTu: '2026-10-01',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        final res = await conflictService.evaluateCandidateAssignment(
          studentId: 1,
          targetScheduleId: s1,
          startDate: '2026-10-01',
        );

        expect(res.canAssign, isFalse);
        expect(
          res.hardConflicts.first.reasonCode,
          ScheduleConflictReasonCode.HARD_BLOCK,
        );
      },
    );

    test(
      'Test U & V: One-off candidate intersects recurring HARD_BLOCK or center class -> hard conflict',
      () async {
        // Recurring hard block Mon 17:30-19:00
        await constraintRepo.createConstraint(
          ScheduleConstraint(
            studentId: 1,
            type: ConstraintType.HARD_BLOCK,
            occurrenceType: OccurrenceType.DINH_KY,
            weekday: 1,
            startTime: '17:30',
            endTime: '19:00',
            effectiveFrom: '2026-01-01',
          ),
        );

        // Evaluate one-off candidate on Mon 2026-10-12 at 18:00-19:30
        final res = await conflictService.evaluateOneOffCandidate(
          studentId: 1,
          targetDate: '2026-10-12',
          startTime: '18:00',
          endTime: '19:30',
        );

        expect(res.canAssign, isFalse);
        expect(
          res.hardConflicts.first.reasonCode,
          ScheduleConflictReasonCode.HARD_BLOCK,
        );
      },
    );

    test(
      'Phase 3 Regression: assignStudent with overlapping recurring schedule is rejected',
      () async {
        final s1 = await scheduleRepo.create(
          ClassSchedule(
            idLop: 1,
            thuTrongTuan: 1,
            gioBatDau: '17:30',
            gioKetThuc: '19:00',
            hieuLucTu: '2026-01-01',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        await scheduleDomainService.assignStudent(
          studentId: 1,
          classId: 1,
          scheduleId: s1,
          startDate: DateTime(2026, 1, 1),
        );

        final s2 = await scheduleRepo.create(
          ClassSchedule(
            idLop: 2,
            thuTrongTuan: 1,
            gioBatDau: '18:00',
            gioKetThuc: '19:30',
            hieuLucTu: '2026-01-01',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        final assignResult = await scheduleDomainService.assignStudent(
          studentId: 1,
          classId: 2,
          scheduleId: s2,
          startDate: DateTime(2026, 1, 1),
        );

        expect(assignResult.canAssign, isFalse);
        expect(assignResult.conflictReason, contains('Trùng lịch'));
      },
    );

    test('Test 7: Single-day boundary overlap -> conflict', () async {
      final s1 = await scheduleRepo.create(
        ClassSchedule(
          idLop: 1,
          thuTrongTuan: 1,
          gioBatDau: '14:00',
          gioKetThuc: '16:00',
          hieuLucTu: '2026-05-15',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      await scheduleDomainService.assignStudent(
        studentId: 1,
        classId: 1,
        scheduleId: s1,
        startDate: DateTime(2026, 5, 15),
        endDate: DateTime(2026, 5, 15),
      );

      final s2 = await scheduleRepo.create(
        ClassSchedule(
          idLop: 2,
          thuTrongTuan: 1,
          gioBatDau: '15:00',
          gioKetThuc: '17:00',
          hieuLucTu: '2026-05-15',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      final res = await conflictService.evaluateCandidateAssignment(
        studentId: 1,
        targetScheduleId: s2,
        startDate: '2026-05-15',
        endDate: '2026-05-15',
      );

      expect(res.canAssign, isFalse);
      expect(res.hardConflicts, isNotEmpty);
    });

    test('Test 8: Open-ended interval matching', () async {
      final s1 = await scheduleRepo.create(
        ClassSchedule(
          idLop: 1,
          thuTrongTuan: 1,
          gioBatDau: '08:00',
          gioKetThuc: '10:00',
          hieuLucTu: '2026-01-01',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      await scheduleDomainService.assignStudent(
        studentId: 1,
        classId: 1,
        scheduleId: s1,
        startDate: DateTime(2026, 1, 1), // null end date
      );

      final s2 = await scheduleRepo.create(
        ClassSchedule(
          idLop: 2,
          thuTrongTuan: 1,
          gioBatDau: '09:00',
          gioKetThuc: '11:00',
          hieuLucTu: '2026-06-01',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      final res = await conflictService.evaluateCandidateAssignment(
        studentId: 1,
        targetScheduleId: s2,
        startDate: '2026-06-01', // also open ended
      );

      expect(res.canAssign, isFalse);
      expect(res.hardConflicts, isNotEmpty);
    });

    test(
      'Test 15: Travel buffer = 0 -> no warning for adjacent schedules',
      () async {
        await constraintRepo.createConstraint(
          ScheduleConstraint(
            studentId: 1,
            type: ConstraintType.OTHER_CENTER,
            occurrenceType: OccurrenceType.DINH_KY,
            weekday: 1,
            startTime: '08:00',
            endTime: '09:00',
            effectiveFrom: '2026-01-01',
            travelBufferMinutes: 0,
            sourceName: 'Center C',
          ),
        );

        final s1 = await scheduleRepo.create(
          ClassSchedule(
            idLop: 1,
            thuTrongTuan: 1,
            gioBatDau: '09:05',
            gioKetThuc: '10:05',
            hieuLucTu: '2026-01-01',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        final res = await conflictService.evaluateCandidateAssignment(
          studentId: 1,
          targetScheduleId: s1,
          startDate: '2026-01-01',
        );

        expect(res.canAssign, isTrue);
        expect(res.softWarnings, isEmpty);
      },
    );

    test('Test 17: changeRecurringShift excludes old assignment', () async {
      final s1 = await scheduleRepo.create(
        ClassSchedule(
          idLop: 1,
          thuTrongTuan: 1,
          gioBatDau: '08:00',
          gioKetThuc: '10:00',
          hieuLucTu: '2026-01-01',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      final oldAssignmentId = await scheduleDomainService.assignStudent(
        studentId: 1,
        classId: 1,
        scheduleId: s1,
        startDate: DateTime(2026, 1, 1),
      );

      final s2 = await scheduleRepo.create(
        ClassSchedule(
          idLop: 1,
          thuTrongTuan: 1,
          gioBatDau: '08:30',
          gioKetThuc: '10:30',
          hieuLucTu: '2026-01-01',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      // Evaluate candidate excluding old assignment
      final res = await conflictService.evaluateCandidateAssignment(
        studentId: 1,
        targetScheduleId: s2,
        startDate: '2026-06-01',
        excludeAssignmentId: oldAssignmentId.assignmentId,
      );

      expect(res.canAssign, isTrue);
      expect(res.hardConflicts, isEmpty);
    });

    test(
      'Test 18: Rollback preserves old assignment if mutation fails',
      () async {
        final s1 = await scheduleRepo.create(
          ClassSchedule(
            idLop: 1,
            thuTrongTuan: 1,
            gioBatDau: '08:00',
            gioKetThuc: '10:00',
            hieuLucTu: '2026-01-01',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        final oldAssignRes = await scheduleDomainService.assignStudent(
          studentId: 1,
          classId: 1,
          scheduleId: s1,
          startDate: DateTime(2026, 1, 1),
        );

        // Try change shift to invalid non-existent schedule id -> fails
        expect(
          () async => await scheduleDomainService.changeRecurringShift(
            studentId: 1,
            classId: 1,
            oldAssignmentId: oldAssignRes.assignmentId!,
            newScheduleId: 9999,
            effectiveDate: DateTime(2026, 6, 1),
          ),
          throwsA(isA<Exception>()),
        );

        // Verify old assignment is still active (den_ngay is null)
        final studentAssignments = await assignmentRepo.getByStudent(1);
        final active = studentAssignments.firstWhere(
          (a) => a.id == oldAssignRes.assignmentId,
        );
        expect(active, isNotNull);
        expect(active.denNgay, isNull);
      },
    );

    test('Fail Closed: Missing schedule reference throws StateError', () async {
      // Temporarily disable FKs to insert corrupt row with non-existent schedule ID 9999
      await db.execute('PRAGMA foreign_keys = OFF;');
      await db.execute('''
        INSERT INTO phan_ca_hoc_sinh (id_hoc_sinh, id_lop, id_lich_hoc, tu_ngay, created_at, updated_at)
        VALUES (1, 1, 9999, '2026-01-01', '2026-01-01', '2026-01-01')
      ''');
      await db.execute('PRAGMA foreign_keys = ON;');

      final s1 = await scheduleRepo.create(
        ClassSchedule(
          idLop: 2,
          thuTrongTuan: 1,
          gioBatDau: '08:00',
          gioKetThuc: '10:00',
          hieuLucTu: '2026-01-01',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      expect(
        () async => await conflictService.evaluateCandidateAssignment(
          studentId: 1,
          targetScheduleId: s1,
          startDate: '2026-01-01',
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('Fail Closed: Invalid time format throws FormatException', () async {
      // '99:99' passes string comparison '99:99' > '08:00' but fails hour/minute parsing in _timeToMinutes
      final s1 = await scheduleRepo.create(
        ClassSchedule(
          idLop: 1,
          thuTrongTuan: 1,
          gioBatDau: '08:00',
          gioKetThuc: '99:99',
          hieuLucTu: '2026-01-01',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      await db.execute('''
        INSERT INTO phan_ca_hoc_sinh (id_hoc_sinh, id_lop, id_lich_hoc, tu_ngay, created_at, updated_at)
        VALUES (1, 1, $s1, '2026-01-01', '2026-01-01', '2026-01-01')
      ''');

      final s2 = await scheduleRepo.create(
        ClassSchedule(
          idLop: 2,
          thuTrongTuan: 1,
          gioBatDau: '08:00',
          gioKetThuc: '10:00',
          hieuLucTu: '2026-01-01',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      expect(
        () async => await conflictService.evaluateCandidateAssignment(
          studentId: 1,
          targetScheduleId: s2,
          startDate: '2026-01-01',
        ),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
