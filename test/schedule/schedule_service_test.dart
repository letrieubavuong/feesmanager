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
import 'test_db_helper.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database db;
  late ScheduleDomainService service;
  late ClassRepository classRepo;

  setUp(() async {
    db = await TestDbHelper.createLatest();
    classRepo = ClassRepository(db);
    final scheduleRepo = ScheduleRepository(db);
    final assignmentRepo = AssignmentRepository(db);
    final constraintRepo = ScheduleConstraintRepository(db);
    final sessionRepo = SessionRepository(db);
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
  });

  tearDown(() async => await db.close());

  group('ScheduleDomainService - Schedule Management', () {
    test('valid schedule creation', () async {
      await classRepo.create(
        ClassEntity(
          id: 1,
          tenLop: 'Class A',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      final schedule = ClassSchedule(
        idLop: 1,
        thuTrongTuan: 1,
        gioBatDau: '17:30',
        gioKetThuc: '19:00',
        hieuLucTu: '2026-09-01',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await service.createSchedule(schedule);
      final list = await service.getSchedulesForClass(1);
      expect(list.length, 1);
    });

    test('weekday boundaries (1-7)', () async {
      await classRepo.create(
        ClassEntity(
          id: 1,
          tenLop: 'C',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      final base = ClassSchedule(
        idLop: 1,
        thuTrongTuan: 1,
        gioBatDau: '08:00',
        gioKetThuc: '09:00',
        hieuLucTu: '2026-01-01',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await service.createSchedule(base.copyWith(thuTrongTuan: 1)); // Mon
      await service.createSchedule(base.copyWith(thuTrongTuan: 7)); // Sun

      expect(
        () => service.createSchedule(base.copyWith(thuTrongTuan: 0)),
        throwsA(isA<Exception>()),
      );
      expect(
        () => service.createSchedule(base.copyWith(thuTrongTuan: 8)),
        throwsA(isA<Exception>()),
      );
    });

    test('reject start >= end time', () async {
      await classRepo.create(
        ClassEntity(
          id: 1,
          tenLop: 'Class A',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      final schedule = ClassSchedule(
        idLop: 1,
        thuTrongTuan: 1,
        gioBatDau: '19:00',
        gioKetThuc: '17:30',
        hieuLucTu: '2026-09-01',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(() => service.createSchedule(schedule), throwsA(isA<Exception>()));
    });

    test('reject creation for archived class', () async {
      await classRepo.create(
        ClassEntity(
          id: 1,
          tenLop: 'Class A',
          daLuuTru: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      final schedule = ClassSchedule(
        idLop: 1,
        thuTrongTuan: 1,
        gioBatDau: '17:30',
        gioKetThuc: '19:00',
        hieuLucTu: '2026-09-01',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(
        () => service.createSchedule(schedule),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('lớp đã lưu trữ'),
          ),
        ),
      );
    });

    test('block close schedule if assignments outlive end date', () async {
      // Setup: Class -> Membership -> Schedule -> Assignment (open-ended)
      await db.insert('lop', {
        'id': 1,
        'ten_lop': 'C1',
        'da_luu_tru': 0,
        'created_at': '2026-01-01T00:00:00.000',
        'updated_at': '2026-01-01T00:00:00.000',
      });
      await db.insert('hoc_sinh', {
        'id': 1,
        'ho_ten': 'S1',
        'da_luu_tru': 0,
        'created_at': '2026-01-01T00:00:00.000',
        'updated_at': '2026-01-01T00:00:00.000',
      });
      await db.insert('tham_gia_lop', {
        'id': 1,
        'id_hoc_sinh': 1,
        'id_lop': 1,
        'tu_ngay': '2026-01-01',
        'mien_giam_phan_tram': 0,
        'created_at': '2026-01-01T00:00:00.000',
        'updated_at': '2026-01-01T00:00:00.000',
      });
      await db.insert('lich_hoc', {
        'id': 1,
        'id_lop': 1,
        'thu_trong_tuan': 1,
        'gio_bat_dau': '08:00',
        'gio_ket_thuc': '09:00',
        'hieu_luc_tu': '2026-01-01',
        'created_at': '2026-01-01T00:00:00.000',
        'updated_at': '2026-01-01T00:00:00.000',
      });
      await db.insert('phan_ca_hoc_sinh', {
        'id': 1,
        'id_hoc_sinh': 1,
        'id_lop': 1,
        'id_lich_hoc': 1,
        'tu_ngay': '2026-01-01',
        'created_at': '2026-01-01T00:00:00.000',
        'updated_at': '2026-01-01T00:00:00.000',
      });

      // Attempt to close schedule at 2026-06-01 while assignment is open
      await expectLater(
        service.closeSchedule(1, DateTime(2026, 6, 1)),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('vượt quá ngày kết thúc'),
          ),
        ),
      );
    });
  });
}
