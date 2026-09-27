import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tuition2027/features/schedule/data/schedule_repository.dart';
import 'package:tuition2027/features/schedule/data/assignment_repository.dart';
import 'package:tuition2027/features/schedule/domain/schedule_service.dart';
import 'package:tuition2027/features/schedule/domain/class_schedule.dart';
import 'package:tuition2027/features/classes/domain/class_service.dart';
import 'package:tuition2027/features/classes/data/class_repository.dart';
import 'package:tuition2027/features/classes/domain/class.dart';
import 'package:tuition2027/features/memberships/domain/membership_service.dart';
import 'package:tuition2027/features/memberships/data/membership_repository.dart';
import 'package:tuition2027/features/students/domain/student_service.dart';
import 'package:tuition2027/features/students/data/student_repository.dart';
import 'package:tuition2027/features/schedule_conflicts/data/schedule_constraint_repository.dart';
import 'package:tuition2027/features/schedule_conflicts/domain/schedule_conflict_service.dart';
import 'package:tuition2027/features/session_adjustments/data/session_adjustment_repository.dart';
import 'package:tuition2027/features/sessions/data/session_repository.dart';
import 'package:tuition2027/features/sessions/domain/session_generation_service.dart';
import 'package:tuition2027/features/sessions/domain/class_session.dart';
import 'test_db_helper.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database db;
  late ScheduleDomainService service;
  late SessionGenerationService genService;
  late ClassRepository classRepo;
  late SessionRepository sessionRepo;

  setUp(() async {
    db = await TestDbHelper.createLatest();
    classRepo = ClassRepository(db);
    final scheduleRepo = ScheduleRepository(db);
    final assignmentRepo = AssignmentRepository(db);
    final constraintRepo = ScheduleConstraintRepository(db);
    sessionRepo = SessionRepository(db);
    final adjustmentRepo = SessionAdjustmentRepository(db);
    final membershipService = MembershipService(MembershipRepository(db));
    final classService = ClassService(classRepo, membershipService);
    final studentService = StudentService(
      StudentRepository(db),
      membershipService,
    );
    final conflictService = ScheduleConflictService(
      constraintRepo,
      scheduleRepo,
      assignmentRepo,
      sessionRepo,
      adjustmentRepo,
      classService,
    );

    service = ScheduleDomainService(
      scheduleRepo,
      assignmentRepo,
      membershipService,
      classService,
      studentService,
      conflictService,
    );

    genService = SessionGenerationService(sessionRepo, service, classService);
  });

  tearDown(() async => await db.close());

  group('Schedule Revision Historical Safety', () {
    test('1. revision with no generated sessions', () async {
      await classRepo.create(
        ClassEntity(
          id: 1,
          tenLop: 'Class A',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      final sched = await service.createSchedule(
        ClassSchedule(
          idLop: 1,
          thuTrongTuan: 1, // Mon
          gioBatDau: '17:30',
          gioKetThuc: '19:00',
          hieuLucTu: '2026-09-01',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      await service.reviseSchedule(
        scheduleId: sched.id!,
        thuTrongTuan: 1,
        gioBatDau: '18:00',
        gioKetThuc: '19:30',
        effectiveDate: DateTime(2026, 10, 1),
      );

      final schedules = await service.getSchedulesForClass(1);
      expect(schedules.length, 2);
      final oldSched = schedules.firstWhere((s) => s.id == sched.id);
      expect(oldSched.hieuLucDen, '2026-09-30');

      final newSched = schedules.firstWhere((s) => s.id != sched.id);
      expect(newSched.hieuLucTu, '2026-10-01');
      expect(newSched.gioBatDau, '18:00');
    });

    test(
      '2 & 6. revision with future untouched DU_KIEN sessions deletes stale and prevents duplicate after generation',
      () async {
        await classRepo.create(
          ClassEntity(
            id: 1,
            tenLop: 'Class A',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
        final sched = await service.createSchedule(
          ClassSchedule(
            idLop: 1,
            thuTrongTuan: 1, // Monday
            gioBatDau: '17:30',
            gioKetThuc: '19:00',
            hieuLucTu: '2026-09-01',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        // Generate future sessions for Oct 2026 (Oct 5, 12, 19, 26 are Mondays)
        await genService.generateForClass(
          classId: 1,
          fromDate: DateTime(2026, 10, 1),
          toDate: DateTime(2026, 10, 31),
        );

        final initialSessions = await sessionRepo.getByClass(1);
        expect(initialSessions.isNotEmpty, true);
        expect(initialSessions.first.gioBatDau, '17:30');

        // Revise starting Oct 1, 2026 to 18:00-19:30
        await service.reviseSchedule(
          scheduleId: sched.id!,
          thuTrongTuan: 1,
          gioBatDau: '18:00',
          gioKetThuc: '19:30',
          effectiveDate: DateTime(2026, 10, 1),
        );

        // Regenerate sessions for Oct 2026
        await genService.generateForClass(
          classId: 1,
          fromDate: DateTime(2026, 10, 1),
          toDate: DateTime(2026, 10, 31),
        );

        final newSessions = await sessionRepo.getByClass(1);
        // All Oct 2026 sessions must now have 18:00 start time, no duplicates
        for (final s in newSessions) {
          expect(s.gioBatDau, '18:00');
          expect(s.gioKetThuc, '19:30');
        }
      },
    );

    test('3. historical DA_HOC remains unchanged on revision', () async {
      await classRepo.create(
        ClassEntity(
          id: 1,
          tenLop: 'Class A',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      final sched = await service.createSchedule(
        ClassSchedule(
          idLop: 1,
          thuTrongTuan: 1,
          gioBatDau: '17:30',
          gioKetThuc: '19:00',
          hieuLucTu: '2026-09-01',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      // Insert historical session on 2026-09-07 as DA_HOC
      await sessionRepo.create(
        ClassSession(
          idLop: 1,
          idLichHoc: sched.id,
          ngay: '2026-09-07',
          gioBatDau: '17:30',
          gioKetThuc: '19:00',
          loai: SessionType.CHINH,
          trangThai: SessionStatus.DA_HOC,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      // Revise schedule from 2026-10-01
      await service.reviseSchedule(
        scheduleId: sched.id!,
        thuTrongTuan: 1,
        gioBatDau: '18:00',
        gioKetThuc: '19:30',
        effectiveDate: DateTime(2026, 10, 1),
      );

      final historicalSession = await sessionRepo.findByClassDateStart(
        1,
        '2026-09-07',
        '17:30',
      );
      expect(historicalSession, isNotNull);
      expect(historicalSession!.trangThai, SessionStatus.DA_HOC);
      expect(historicalSession.gioBatDau, '17:30');
    });

    test('4. future session with attendance blocks unsafe revision', () async {
      await classRepo.create(
        ClassEntity(
          id: 1,
          tenLop: 'Class A',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      final sched = await service.createSchedule(
        ClassSchedule(
          idLop: 1,
          thuTrongTuan: 1,
          gioBatDau: '17:30',
          gioKetThuc: '19:00',
          hieuLucTu: '2026-09-01',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      final session = ClassSession(
        idLop: 1,
        idLichHoc: sched.id,
        ngay: '2026-10-05',
        gioBatDau: '17:30',
        gioKetThuc: '19:00',
        loai: SessionType.CHINH,
        trangThai: SessionStatus.DU_KIEN,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final sessionId = await sessionRepo.create(session);

      await db.insert('hoc_sinh', {
        'id': 100,
        'ho_ten': 'Student 100',
        'da_luu_tru': 0,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      // Add attendance record to future session
      await db.insert('diem_danh', {
        'id_buoi_hoc': sessionId,
        'id_hoc_sinh': 100,
        'trang_thai': 'CO_MAT',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      // Attempt to revise schedule effective 2026-10-01
      await expectLater(
        service.reviseSchedule(
          scheduleId: sched.id!,
          thuTrongTuan: 1,
          gioBatDau: '18:00',
          gioKetThuc: '19:30',
          effectiveDate: DateTime(2026, 10, 1),
        ),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('đã ghi nhận dữ liệu'),
          ),
        ),
      );
    });

    test('7. assignment migration remains valid after revision', () async {
      await classRepo.create(
        ClassEntity(
          id: 1,
          tenLop: 'Class A',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      await db.insert('hoc_sinh', {
        'id': 1,
        'ho_ten': 'Student 1',
        'da_luu_tru': 0,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      await db.insert('tham_gia_lop', {
        'id': 1,
        'id_hoc_sinh': 1,
        'id_lop': 1,
        'tu_ngay': '2026-09-01',
        'mien_giam_phan_tram': 0,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      final sched = await service.createSchedule(
        ClassSchedule(
          idLop: 1,
          thuTrongTuan: 1,
          gioBatDau: '17:30',
          gioKetThuc: '19:00',
          hieuLucTu: '2026-09-01',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      await service.assignStudent(
        studentId: 1,
        classId: 1,
        scheduleId: sched.id!,
        startDate: DateTime(2026, 9, 1),
      );

      await service.reviseSchedule(
        scheduleId: sched.id!,
        thuTrongTuan: 1,
        gioBatDau: '18:00',
        gioKetThuc: '19:30',
        effectiveDate: DateTime(2026, 10, 1),
      );

      final assignments = await service.getAssignmentsForStudent(1);
      expect(assignments.length, 2);
      final oldAssignment = assignments.firstWhere(
        (a) => a.idLichHoc == sched.id,
      );
      expect(oldAssignment.denNgay, '2026-09-30');

      final newAssignment = assignments.firstWhere(
        (a) => a.idLichHoc != sched.id,
      );
      expect(newAssignment.tuNgay, '2026-10-01');
      expect(newAssignment.denNgay, isNull);
    });
  });

  group('Assignment Start Date Historical Safety', () {
    test(
      '1 & 8. future unused assignment can safely change start date',
      () async {
        await classRepo.create(
          ClassEntity(
            id: 1,
            tenLop: 'Class A',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
        await db.insert('hoc_sinh', {
          'id': 1,
          'ho_ten': 'Student 1',
          'da_luu_tru': 0,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
        await db.insert('tham_gia_lop', {
          'id': 1,
          'id_hoc_sinh': 1,
          'id_lop': 1,
          'tu_ngay': '2026-09-01',
          'mien_giam_phan_tram': 0,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
        final sched = await service.createSchedule(
          ClassSchedule(
            idLop: 1,
            thuTrongTuan: 1,
            gioBatDau: '17:30',
            gioKetThuc: '19:00',
            hieuLucTu: '2026-09-01',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
        final res = await service.assignStudent(
          studentId: 1,
          classId: 1,
          scheduleId: sched.id!,
          startDate: DateTime(2026, 10, 1),
        );

        // Safe update to 2026-10-15
        await service.updateAssignmentStartDate(
          assignmentId: res.assignmentId!,
          newStartDate: DateTime(2026, 10, 15),
        );

        final assignments = await service.getAssignmentsForStudent(1);
        expect(assignments.single.tuNgay, '2026-10-15');
      },
    );

    test('2. new date before membership is blocked', () async {
      await classRepo.create(
        ClassEntity(
          id: 1,
          tenLop: 'Class A',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      await db.insert('hoc_sinh', {
        'id': 1,
        'ho_ten': 'Student 1',
        'da_luu_tru': 0,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      await db.insert('tham_gia_lop', {
        'id': 1,
        'id_hoc_sinh': 1,
        'id_lop': 1,
        'tu_ngay': '2026-09-10',
        'mien_giam_phan_tram': 0,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      final sched = await service.createSchedule(
        ClassSchedule(
          idLop: 1,
          thuTrongTuan: 1,
          gioBatDau: '17:30',
          gioKetThuc: '19:00',
          hieuLucTu: '2026-09-01',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      final res = await service.assignStudent(
        studentId: 1,
        classId: 1,
        scheduleId: sched.id!,
        startDate: DateTime(2026, 9, 15),
      );

      // Attempt to move start date to 2026-09-01 (before membership start 2026-09-10)
      await expectLater(
        service.updateAssignmentStartDate(
          assignmentId: res.assignmentId!,
          newStartDate: DateTime(2026, 9, 1),
        ),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('không có tham gia lớp hợp lệ'),
          ),
        ),
      );
    });

    test(
      '6 & 7. historical completed session or attendance affected blocks assignment start date change',
      () async {
        await classRepo.create(
          ClassEntity(
            id: 1,
            tenLop: 'Class A',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
        await db.insert('hoc_sinh', {
          'id': 1,
          'ho_ten': 'Student 1',
          'da_luu_tru': 0,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
        await db.insert('tham_gia_lop', {
          'id': 1,
          'id_hoc_sinh': 1,
          'id_lop': 1,
          'tu_ngay': '2026-09-01',
          'mien_giam_phan_tram': 0,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
        final sched = await service.createSchedule(
          ClassSchedule(
            idLop: 1,
            thuTrongTuan: 1,
            gioBatDau: '17:30',
            gioKetThuc: '19:00',
            hieuLucTu: '2026-09-01',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
        final res = await service.assignStudent(
          studentId: 1,
          classId: 1,
          scheduleId: sched.id!,
          startDate: DateTime(2026, 9, 1),
        );

        // Create completed session on 2026-09-07
        final sessionId = await sessionRepo.create(
          ClassSession(
            idLop: 1,
            idLichHoc: sched.id,
            ngay: '2026-09-07',
            gioBatDau: '17:30',
            gioKetThuc: '19:00',
            loai: SessionType.CHINH,
            trangThai: SessionStatus.DA_HOC,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
        await db.insert('diem_danh', {
          'id_buoi_hoc': sessionId,
          'id_hoc_sinh': 1,
          'trang_thai': 'CO_MAT',
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });

        // Attempt to move start date to 2026-09-15 (after completed session on 2026-09-07)
        await expectLater(
          service.updateAssignmentStartDate(
            assignmentId: res.assignmentId!,
            newStartDate: DateTime(2026, 9, 15),
          ),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('đã ảnh hưởng đến các buổi học/điểm danh trong lịch sử'),
            ),
          ),
        );
      },
    );
  });
}
