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
import 'package:tuition2027/features/students/domain/student.dart';
import 'package:tuition2027/features/schedule_conflicts/data/schedule_constraint_repository.dart';
import 'package:tuition2027/features/schedule_conflicts/domain/schedule_conflict_service.dart';
import 'package:tuition2027/features/session_adjustments/data/session_adjustment_repository.dart';
import 'package:tuition2027/features/sessions/data/session_repository.dart';
import 'test_db_helper.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database db;
  late ScheduleDomainService service;
  late ClassRepository classRepo;
  late StudentRepository studentRepo;

  setUp(() async {
    db = await TestDbHelper.createLatest();
    classRepo = ClassRepository(db);
    studentRepo = StudentRepository(db);
    final scheduleRepo = ScheduleRepository(db);
    final assignmentRepo = AssignmentRepository(db);
    final constraintRepo = ScheduleConstraintRepository(db);
    final sessionRepo = SessionRepository(db);
    final adjustmentRepo = SessionAdjustmentRepository(db);
    final membershipService = MembershipService(MembershipRepository(db));
    final classService = ClassService(classRepo, membershipService);
    final studentService = StudentService(
      studentRepo,
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
  });

  tearDown(() async => await db.close());

  group('Phase 2 - Schedule Revision and Conflict Audit', () {
    test('1. Create schedule with start/end date and open-ended schedule', () async {
      await classRepo.create(
        ClassEntity(id: 1, tenLop: 'Math 101', createdAt: DateTime.now(), updatedAt: DateTime.now()),
      );

      // Bounded schedule
      final bounded = await service.createSchedule(
        ClassSchedule(
          idLop: 1,
          thuTrongTuan: 1,
          gioBatDau: '17:00',
          gioKetThuc: '18:30',
          hieuLucTu: '2026-07-01',
          hieuLucDen: '2026-12-31',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      expect(bounded.hieuLucDen, '2026-12-31');

      // Open-ended schedule
      final openEnded = await service.createSchedule(
        ClassSchedule(
          idLop: 1,
          thuTrongTuan: 3,
          gioBatDau: '17:00',
          gioKetThuc: '18:30',
          hieuLucTu: '2026-07-01',
          hieuLucDen: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      expect(openEnded.hieuLucDen, isNull);

      final list = await service.getSchedulesForClass(1);
      expect(list.length, 2);
    });

    test('2. Direct edit of unused schedule (01/07 -> 02/08)', () async {
      await classRepo.create(
        ClassEntity(id: 1, tenLop: 'Math 101', createdAt: DateTime.now(), updatedAt: DateTime.now()),
      );

      final s = await service.createSchedule(
        ClassSchedule(
          idLop: 1,
          thuTrongTuan: 1,
          gioBatDau: '17:00',
          gioKetThuc: '18:30',
          hieuLucTu: '2026-07-01',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      final plan = await service.previewScheduleChange(
        scheduleId: s.id!,
        newWeekday: 1,
        newStart: '17:00',
        newEnd: '18:30',
        newEffectiveFrom: '2026-08-02',
      );

      expect(plan.isDirectEdit, isTrue);
      expect(plan.protectedSessions, isEmpty);

      await service.applyScheduleChange(plan: plan);

      final updated = await service.getScheduleById(s.id!);
      expect(updated!.hieuLucTu, '2026-08-02');
    });

    test('3. Edit schedule with attendance protects history and creates new version', () async {
      await classRepo.create(
        ClassEntity(id: 1, tenLop: 'Math 101', createdAt: DateTime.now(), updatedAt: DateTime.now()),
      );

      final s = await service.createSchedule(
        ClassSchedule(
          idLop: 1,
          thuTrongTuan: 1, // Mon
          gioBatDau: '17:00',
          gioKetThuc: '18:30',
          hieuLucTu: '2026-07-01',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      // Create student & membership & attendance on 2026-07-06 (Mon)
      await studentRepo.create(
        Student(id: 10, hoTen: 'Nguyen Van A', createdAt: DateTime.now(), updatedAt: DateTime.now()),
      );
      await db.insert('tham_gia_lop', {
        'id_hoc_sinh': 10,
        'id_lop': 1,
        'tu_ngay': '2026-07-01',
        'mien_giam_phan_tram': 0,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      final sessionId = await db.insert('buoi_hoc', {
        'id_lop': 1,
        'id_lich_hoc': s.id,
        'ngay': '2026-07-06',
        'gio_bat_dau': '17:00',
        'gio_ket_thuc': '18:30',
        'loai': 'CHINH',
        'trang_thai': 'DA_HOC',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      await db.insert('diem_danh', {
        'id_buoi_hoc': sessionId,
        'id_hoc_sinh': 10,
        'id_lop_goc': 1,
        'trang_thai': 'CO_MAT',
        'loai_tham_gia': 'CHINH',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      final plan = await service.previewScheduleChange(
        scheduleId: s.id!,
        newWeekday: 2, // Tue
        newStart: '17:30',
        newEnd: '19:00',
        newEffectiveFrom: '2026-08-01',
      );

      expect(plan.isDirectEdit, isFalse);
      expect(plan.protectedSessions, isNotEmpty);
      expect(plan.protectedSessions.first, contains('2026-07-06'));

      await service.applyScheduleChange(plan: plan);

      final oldS = await service.getScheduleById(s.id!);
      expect(oldS!.hieuLucDen, '2026-07-31');

      final schedules = await service.getSchedulesForClass(1);
      expect(schedules.length, 2);

      // Verify historical attended session is intact
      final attSession = await db.query('buoi_hoc', where: 'id = ?', whereArgs: [sessionId]);
      expect(attSession.first['trang_thai'], 'DA_HOC');
    });

    test('4. Student joined class 01/07, shift assignment starting 02/08 is valid', () async {
      await classRepo.create(
        ClassEntity(id: 1, tenLop: 'Math 101', createdAt: DateTime.now(), updatedAt: DateTime.now()),
      );
      final s = await service.createSchedule(
        ClassSchedule(
          idLop: 1,
          thuTrongTuan: 1,
          gioBatDau: '17:00',
          gioKetThuc: '18:30',
          hieuLucTu: '2026-07-01',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      await studentRepo.create(
        Student(id: 1, hoTen: 'Tran Van B', createdAt: DateTime.now(), updatedAt: DateTime.now()),
      );
      await db.insert('tham_gia_lop', {
        'id_hoc_sinh': 1,
        'id_lop': 1,
        'tu_ngay': '2026-07-01',
        'mien_giam_phan_tram': 0,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      // Assignment start 2026-08-02 is later than membership join date 2026-07-01
      final result = await service.assignStudent(
        studentId: 1,
        classId: 1,
        scheduleId: s.id!,
        startDate: DateTime(2026, 8, 2),
      );

      expect(result.canAssign, isTrue);
      expect(result.assignmentId, isNotNull);
    });

    test('5. Two schedules with same time but non-overlapping effective dates do NOT report conflict', () async {
      await classRepo.create(
        ClassEntity(id: 1, tenLop: 'Math A', createdAt: DateTime.now(), updatedAt: DateTime.now()),
      );
      await classRepo.create(
        ClassEntity(id: 2, tenLop: 'Math B', createdAt: DateTime.now(), updatedAt: DateTime.now()),
      );

      final s1 = await service.createSchedule(
        ClassSchedule(
          idLop: 1,
          thuTrongTuan: 1,
          gioBatDau: '17:00',
          gioKetThuc: '18:30',
          hieuLucTu: '2026-07-01',
          hieuLucDen: '2026-07-31',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      final s2 = await service.createSchedule(
        ClassSchedule(
          idLop: 2,
          thuTrongTuan: 1,
          gioBatDau: '17:00',
          gioKetThuc: '18:30',
          hieuLucTu: '2026-08-01',
          hieuLucDen: '2026-08-31',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      await studentRepo.create(
        Student(id: 5, hoTen: 'Le Van C', createdAt: DateTime.now(), updatedAt: DateTime.now()),
      );
      await db.insert('tham_gia_lop', {
        'id_hoc_sinh': 5,
        'id_lop': 1,
        'tu_ngay': '2026-07-01',
        'mien_giam_phan_tram': 0,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      await db.insert('tham_gia_lop', {
        'id_hoc_sinh': 5,
        'id_lop': 2,
        'tu_ngay': '2026-08-01',
        'mien_giam_phan_tram': 0,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      // Assign to s1 in July
      await service.assignStudent(
        studentId: 5,
        classId: 1,
        scheduleId: s1.id!,
        startDate: DateTime(2026, 7, 1),
        endDate: DateTime(2026, 7, 31),
      );

      // Assign to s2 in August - should NOT conflict because date ranges do not overlap
      final res = await service.assignStudent(
        studentId: 5,
        classId: 2,
        scheduleId: s2.id!,
        startDate: DateTime(2026, 8, 1),
        endDate: DateTime(2026, 8, 31),
      );

      expect(res.canAssign, isTrue);
    });

    test('6. Real overlap reports detailed conflict message', () async {
      await classRepo.create(
        ClassEntity(id: 1, tenLop: 'Toan A', createdAt: DateTime.now(), updatedAt: DateTime.now()),
      );
      await classRepo.create(
        ClassEntity(id: 2, tenLop: 'Toan B', createdAt: DateTime.now(), updatedAt: DateTime.now()),
      );

      final s1 = await service.createSchedule(
        ClassSchedule(
          idLop: 1,
          thuTrongTuan: 1, // Mon
          gioBatDau: '17:00',
          gioKetThuc: '18:30',
          hieuLucTu: '2026-07-01',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      final s2 = await service.createSchedule(
        ClassSchedule(
          idLop: 2,
          thuTrongTuan: 1, // Mon
          gioBatDau: '17:30',
          gioKetThuc: '19:00',
          hieuLucTu: '2026-07-01',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      await studentRepo.create(
        Student(id: 1, hoTen: 'Nguyen Van A', createdAt: DateTime.now(), updatedAt: DateTime.now()),
      );
      await db.insert('tham_gia_lop', {
        'id_hoc_sinh': 1,
        'id_lop': 1,
        'tu_ngay': '2026-07-01',
        'mien_giam_phan_tram': 0,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      await db.insert('tham_gia_lop', {
        'id_hoc_sinh': 1,
        'id_lop': 2,
        'tu_ngay': '2026-07-01',
        'mien_giam_phan_tram': 0,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      await service.assignStudent(
        studentId: 1,
        classId: 1,
        scheduleId: s1.id!,
        startDate: DateTime(2026, 7, 1),
      );

      final res = await service.assignStudent(
        studentId: 1,
        classId: 2,
        scheduleId: s2.id!,
        startDate: DateTime(2026, 7, 1),
      );

      expect(res.canAssign, isFalse);
      expect(res.conflictReason, isNotNull);
      expect(res.conflictReason, contains('Nguyen Van A'));
      expect(res.conflictReason, contains('Toan A'));
      expect(res.conflictReason, contains('17:00–18:30'));
    });
  });
}
