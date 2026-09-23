import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tuition2027/features/sessions/domain/session_generation_service.dart';
import 'package:tuition2027/features/sessions/data/session_repository.dart';
import 'package:tuition2027/features/sessions/domain/class_session.dart';
import 'package:tuition2027/features/schedule/data/schedule_repository.dart';
import 'package:tuition2027/features/schedule/domain/schedule_service.dart';
import 'package:tuition2027/features/schedule/data/assignment_repository.dart';
import 'package:tuition2027/features/classes/data/class_repository.dart';
import 'package:tuition2027/features/classes/domain/class_service.dart';
import 'package:tuition2027/features/memberships/domain/membership_service.dart';
import 'package:tuition2027/features/memberships/data/membership_repository.dart';
import 'package:tuition2027/features/students/domain/student_service.dart';
import 'package:tuition2027/features/students/data/student_repository.dart';
import 'package:tuition2027/features/classes/domain/class.dart';
import 'package:tuition2027/features/schedule/domain/class_schedule.dart';
import 'test_db_helper_v6.dart';

import 'package:tuition2027/features/schedule_conflicts/data/schedule_constraint_repository.dart';
import 'package:tuition2027/features/schedule_conflicts/domain/schedule_conflict_service.dart';
import 'package:tuition2027/features/session_adjustments/data/session_adjustment_repository.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database db;
  late SessionGenerationService genService;
  late SessionRepository sessionRepo;
  late ClassRepository classRepo;
  late ScheduleRepository scheduleRepo;

  setUp(() async {
    db = await TestDbHelperV6.createLatest();
    sessionRepo = SessionRepository(db);
    classRepo = ClassRepository(db);
    scheduleRepo = ScheduleRepository(db);
    final assignmentRepo = AssignmentRepository(db);
    final membershipService = MembershipService(MembershipRepository(db));
    final classService = ClassService(classRepo, membershipService);
    final studentService = StudentService(
      StudentRepository(db),
      membershipService,
    );
    final constraintRepo = ScheduleConstraintRepository(db);
    final adjustmentRepo = SessionAdjustmentRepository(db);
    final conflictService = ScheduleConflictService(
      constraintRepo,
      scheduleRepo,
      assignmentRepo,
      sessionRepo,
      adjustmentRepo,
      classService,
    );

    final scheduleService = ScheduleDomainService(
      scheduleRepo,
      assignmentRepo,
      membershipService,
      classService,
      studentService,
      conflictService,
    );

    genService = SessionGenerationService(
      sessionRepo,
      scheduleService,
      classService,
    );
  });

  tearDown(() async => await db.close());

  group('SessionGenerationService Tests', () {
    test('Idempotency: Generate twice creates no duplicates', () async {
      final classId = await classRepo.create(
        ClassEntity(
          tenLop: 'Class 1',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      await scheduleRepo.create(
        ClassSchedule(
          idLop: classId,
          thuTrongTuan: 1, // Monday
          gioBatDau: '17:30',
          gioKetThuc: '19:00',
          hieuLucTu: '2026-09-01',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      final fromDate = DateTime(2026, 9, 1);
      final toDate = DateTime(2026, 9, 30);

      // Run 1: Should create 4 sessions (Mondays: 7, 14, 21, 28)
      final result1 = await genService.generateForClass(
        classId: classId,
        fromDate: fromDate,
        toDate: toDate,
      );
      expect(result1.createdCount, 4);
      expect(result1.existingCount, 0);

      // Run 2: Should create 0 sessions, find 4 existing
      final result2 = await genService.generateForClass(
        classId: classId,
        fromDate: fromDate,
        toDate: toDate,
      );
      expect(result2.createdCount, 0);
      expect(result2.existingCount, 4);

      final totalCount = (await sessionRepo.getByClass(classId)).length;
      expect(totalCount, 4);
    });

    test('Respects schedule effective boundaries', () async {
      final classId = await classRepo.create(
        ClassEntity(
          tenLop: 'Class 1',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      // Effective from 15th Sept to 25th Sept
      await scheduleRepo.create(
        ClassSchedule(
          idLop: classId,
          thuTrongTuan: 1, // Monday
          gioBatDau: '17:30',
          gioKetThuc: '19:00',
          hieuLucTu: '2026-09-15',
          hieuLucDen: '2026-09-25',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      final fromDate = DateTime(2026, 9, 1);
      final toDate = DateTime(2026, 9, 30);

      // Mondays in Sept: 7, 14, 21, 28.
      // Only 21st is between 15th and 25th.
      final result = await genService.generateForClass(
        classId: classId,
        fromDate: fromDate,
        toDate: toDate,
      );
      expect(result.createdCount, 1);
      final sessions = await sessionRepo.getByClass(classId);
      expect(sessions.first.ngay, '2026-09-21');
    });

    test('Sunday schedule (weekday 7) works', () async {
      final classId = await classRepo.create(
        ClassEntity(
          tenLop: 'Class 1',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      await scheduleRepo.create(
        ClassSchedule(
          idLop: classId,
          thuTrongTuan: 7, // Sunday
          gioBatDau: '08:00',
          gioKetThuc: '10:00',
          hieuLucTu: '2026-09-01',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      // Sept 2026 Sundays: 6, 13, 20, 27
      final result = await genService.generateForClass(
        classId: classId,
        fromDate: DateTime(2026, 9, 1),
        toDate: DateTime(2026, 9, 30),
      );
      expect(result.createdCount, 4);
    });

    test(
      'Status preservation: Rerunning generation does not reset status',
      () async {
        final classId = await classRepo.create(
          ClassEntity(
            tenLop: 'Class 1',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
        await scheduleRepo.create(
          ClassSchedule(
            idLop: classId,
            thuTrongTuan: 1,
            gioBatDau: '17:30',
            gioKetThuc: '19:00',
            hieuLucTu: '2026-09-01',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        await genService.generateForClass(
          classId: classId,
          fromDate: DateTime(2026, 9, 7),
          toDate: DateTime(2026, 9, 7),
        );
        final sessions = await sessionRepo.getByClass(classId);
        final session = sessions.first;

        // Mark as HUY
        await sessionRepo.update(
          session.copyWith(trangThai: SessionStatus.HUY),
        );
        // Rerun generation
        await genService.generateForClass(
          classId: classId,
          fromDate: DateTime(2026, 9, 7),
          toDate: DateTime(2026, 9, 7),
        );
        expect(
          (await sessionRepo.getById(session.id!))!.trangThai,
          SessionStatus.HUY,
        );

        // Mark as NGHI_LE
        await sessionRepo.update(
          session.copyWith(trangThai: SessionStatus.NGHI_LE),
        );
        // Rerun generation
        await genService.generateForClass(
          classId: classId,
          fromDate: DateTime(2026, 9, 7),
          toDate: DateTime(2026, 9, 7),
        );
        expect(
          (await sessionRepo.getById(session.id!))!.trangThai,
          SessionStatus.NGHI_LE,
        );
      },
    );

    test('Conflict: Existing manual session with different details', () async {
      final classId = await classRepo.create(
        ClassEntity(
          tenLop: 'Class 1',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      // Existing manual session at same time but different type
      await sessionRepo.create(
        ClassSession(
          idLop: classId,
          ngay: '2026-09-07',
          gioBatDau: '17:30',
          gioKetThuc: '19:00',
          loai: SessionType.HOC_BU,
          trangThai: SessionStatus.DU_KIEN,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      // Schedule for Monday (Sept 7 is Monday)
      await scheduleRepo.create(
        ClassSchedule(
          idLop: classId,
          thuTrongTuan: 1,
          gioBatDau: '17:30',
          gioKetThuc: '19:00',
          hieuLucTu: '2026-09-01',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      final result = await genService.generateForClass(
        classId: classId,
        fromDate: DateTime(2026, 9, 7),
        toDate: DateTime(2026, 9, 7),
      );
      expect(result.conflictCount, 1);
      expect(result.createdCount, 0);

      final sessions = await sessionRepo.getByClass(classId);
      expect(sessions.length, 1);
      expect(sessions.first.loai, SessionType.HOC_BU); // Preserved
    });

    test('Schedule change mid-range uses correct schedules', () async {
      final classId = await classRepo.create(
        ClassEntity(
          tenLop: 'Class 1',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      // Old schedule: Mon 17:30 (Ends 15th)
      final s1Id = await scheduleRepo.create(
        ClassSchedule(
          idLop: classId,
          thuTrongTuan: 1,
          gioBatDau: '17:30',
          gioKetThuc: '19:00',
          hieuLucTu: '2026-09-01',
          hieuLucDen: '2026-09-15',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      // New schedule: Mon 19:00 (Starts 16th)
      final s2Id = await scheduleRepo.create(
        ClassSchedule(
          idLop: classId,
          thuTrongTuan: 1,
          gioBatDau: '19:00',
          gioKetThuc: '20:30',
          hieuLucTu: '2026-09-16',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      // Mondays: 7, 14 (Old), 21, 28 (New)
      final result = await genService.generateForClass(
        classId: classId,
        fromDate: DateTime(2026, 9, 1),
        toDate: DateTime(2026, 9, 30),
      );
      expect(result.createdCount, 4);

      final sessions = await sessionRepo.getByClass(classId);
      final s7 = sessions.firstWhere((s) => s.ngay == '2026-09-07');
      final s21 = sessions.firstWhere((s) => s.ngay == '2026-09-21');

      expect(s7.idLichHoc, s1Id);
      expect(s7.gioBatDau, '17:30');

      expect(s21.idLichHoc, s2Id);
      expect(s21.gioBatDau, '19:00');
    });

    test(
      'Snapshot: Generated session keeps old time after schedule change',
      () async {
        final classId = await classRepo.create(
          ClassEntity(
            tenLop: 'Class 1',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
        final sId = await scheduleRepo.create(
          ClassSchedule(
            idLop: classId,
            thuTrongTuan: 1,
            gioBatDau: '17:30',
            gioKetThuc: '19:00',
            hieuLucTu: '2026-09-01',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        // Generate for Sept 7
        await genService.generateForClass(
          classId: classId,
          fromDate: DateTime(2026, 9, 7),
          toDate: DateTime(2026, 9, 7),
        );

        // 1. "Close" the old schedule
        final oldSchedule = await scheduleRepo.getById(sId);
        await scheduleRepo.update(
          oldSchedule!.copyWith(
            hieuLucDen: '2026-09-10',
            updatedAt: DateTime.now(),
          ),
        );

        // 2. "Create" a new schedule replacing it
        await scheduleRepo.create(
          ClassSchedule(
            idLop: classId,
            thuTrongTuan: 1,
            gioBatDau: '18:00',
            gioKetThuc: '19:30',
            hieuLucTu: '2026-09-11',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        // Regeneration should not change existing session's time
        await genService.generateForClass(
          classId: classId,
          fromDate: DateTime(2026, 9, 1),
          toDate: DateTime(2026, 9, 30),
        );

        final sessions = await sessionRepo.getByClass(classId);
        final s7 = sessions.firstWhere((s) => s.ngay == '2026-09-07');
        expect(s7.gioBatDau, '17:30'); // Snapshotted
      },
    );

    test('Multiple shifts same date works', () async {
      final classId = await classRepo.create(
        ClassEntity(
          tenLop: 'Class 1',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      await scheduleRepo.create(
        ClassSchedule(
          idLop: classId,
          thuTrongTuan: 1,
          gioBatDau: '17:30',
          gioKetThuc: '19:00',
          hieuLucTu: '2026-09-01',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      await scheduleRepo.create(
        ClassSchedule(
          idLop: classId,
          thuTrongTuan: 1,
          gioBatDau: '19:00',
          gioKetThuc: '20:30',
          hieuLucTu: '2026-09-01',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      final result = await genService.generateForClass(
        classId: classId,
        fromDate: DateTime(2026, 9, 7),
        toDate: DateTime(2026, 9, 7),
      );
      expect(result.createdCount, 2);
    });

    test('Rejected if from > to', () async {
      expect(
        () => genService.generateForClass(
          classId: 1,
          fromDate: DateTime(2026, 10, 1),
          toDate: DateTime(2026, 9, 1),
        ),
        throwsA(predicate((e) => e.toString().contains('không được trước'))),
      );
    });
  });
}
