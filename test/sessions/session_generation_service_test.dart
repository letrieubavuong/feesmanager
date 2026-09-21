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
    final scheduleService = ScheduleDomainService(
      scheduleRepo,
      assignmentRepo,
      membershipService,
      classService,
      studentService,
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

    test('Respects schedule effective dates', () async {
      final classId = await classRepo.create(
        ClassEntity(
          tenLop: 'Class 1',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      // Effective only from 15th Sept
      await scheduleRepo.create(
        ClassSchedule(
          idLop: classId,
          thuTrongTuan: 1, // Monday
          gioBatDau: '17:30',
          gioKetThuc: '19:00',
          hieuLucTu: '2026-09-15',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      final fromDate = DateTime(2026, 9, 1);
      final toDate = DateTime(2026, 9, 30);

      // Mondays in Sept: 7, 14, 21, 28. Only 21, 28 are >= 15th.
      final result = await genService.generateForClass(
        classId: classId,
        fromDate: fromDate,
        toDate: toDate,
      );
      expect(result.createdCount, 2);
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

        final reloaded = await sessionRepo.getById(session.id!);
        expect(reloaded!.trangThai, SessionStatus.HUY);
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

    test('Archived class cannot generate sessions', () async {
      final classId = await classRepo.create(
        ClassEntity(
          tenLop: 'Archived',
          daLuuTru: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      expect(
        () => genService.generateForClass(
          classId: classId,
          fromDate: DateTime.now(),
          toDate: DateTime.now(),
        ),
        throwsA(predicate((e) => e.toString().contains('đã lưu trữ'))),
      );
    });

    test('Multiple shifts same day generate separately', () async {
      final classId = await classRepo.create(
        ClassEntity(
          tenLop: 'Multi Shift',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      // Shift 1: Mon 17:30
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
      // Shift 2: Mon 19:00
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

      final sessions = await sessionRepo.getByClass(classId);
      expect(sessions.length, 2);
      expect(sessions.any((s) => s.gioBatDau == '17:30'), isTrue);
      expect(sessions.any((s) => s.gioBatDau == '19:00'), isTrue);
    });
  });
}
