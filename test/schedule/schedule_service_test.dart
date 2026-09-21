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
    final membershipService = MembershipService(MembershipRepository(db));
    final classService = ClassService(classRepo, membershipService);
    final studentService = StudentService(StudentRepository(db), membershipService);
    
    service = ScheduleDomainService(scheduleRepo, assignmentRepo, membershipService, classService, studentService);
  });

  tearDown(() async => await db.close());

  group('ScheduleService - Schedule Management', () {
    test('valid schedule creation', () async {
      await classRepo.create(ClassEntity(id: 1, tenLop: 'Class A', createdAt: DateTime.now(), updatedAt: DateTime.now()));
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

    test('reject invalid weekday', () async {
      await classRepo.create(ClassEntity(id: 1, tenLop: 'Class A', createdAt: DateTime.now(), updatedAt: DateTime.now()));
      final schedule = ClassSchedule(
        idLop: 1,
        thuTrongTuan: 8,
        gioBatDau: '17:30',
        gioKetThuc: '19:00',
        hieuLucTu: '2026-09-01',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(() => service.createSchedule(schedule), throwsA(isA<Exception>()));
    });

    test('reject start >= end time', () async {
      await classRepo.create(ClassEntity(id: 1, tenLop: 'Class A', createdAt: DateTime.now(), updatedAt: DateTime.now()));
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
      await classRepo.create(ClassEntity(id: 1, tenLop: 'Class A', daLuuTru: true, createdAt: DateTime.now(), updatedAt: DateTime.now()));
      final schedule = ClassSchedule(
        idLop: 1,
        thuTrongTuan: 1,
        gioBatDau: '17:30',
        gioKetThuc: '19:00',
        hieuLucTu: '2026-09-01',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(() => service.createSchedule(schedule), throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('lớp đã lưu trữ'))));
    });
  });
}
