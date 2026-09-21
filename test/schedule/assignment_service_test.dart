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
import 'test_db_helper.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database db;
  late ScheduleDomainService service;
  late MembershipService membershipService;
  late StudentRepository studentRepo;
  late ClassRepository classRepo;
  late ScheduleRepository scheduleRepo;

  setUp(() async {
    db = await TestDbHelper.createLatest();
    classRepo = ClassRepository(db);
    studentRepo = StudentRepository(db);
    scheduleRepo = ScheduleRepository(db);
    membershipService = MembershipService(MembershipRepository(db));
    final classService = ClassService(classRepo, membershipService);
    final studentService = StudentService(studentRepo, membershipService);

    service = ScheduleDomainService(
      scheduleRepo,
      AssignmentRepository(db),
      membershipService,
      classService,
      studentService,
    );
  });

  tearDown(() async => await db.close());

  group('ScheduleService - Assignment Management', () {
    test('valid assignment', () async {
      final sId = await studentRepo.create(
        Student(
          id: 1,
          hoTen: 'Student A',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      final cId = await classRepo.create(
        ClassEntity(
          id: 1,
          tenLop: 'Class A',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      final lId = await scheduleRepo.create(
        ClassSchedule(
          id: 1,
          idLop: cId,
          thuTrongTuan: 1,
          gioBatDau: '16:30',
          gioKetThuc: '18:00',
          hieuLucTu: '2026-09-01',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      await membershipService.enrollStudent(
        studentId: sId,
        classId: cId,
        joinDate: DateTime(2026, 9, 1),
      );

      final result = await service.assignStudent(
        studentId: sId,
        classId: cId,
        scheduleId: lId,
        startDate: DateTime(2026, 9, 10),
      );

      expect(result.canAssign, isTrue);
    });

    test('reject assignment outside membership boundary', () async {
      final sId = await studentRepo.create(
        Student(
          id: 1,
          hoTen: 'Student A',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      final cId = await classRepo.create(
        ClassEntity(
          id: 1,
          tenLop: 'Class A',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      final lId = await scheduleRepo.create(
        ClassSchedule(
          id: 1,
          idLop: cId,
          thuTrongTuan: 1,
          gioBatDau: '16:30',
          gioKetThuc: '18:00',
          hieuLucTu: '2026-09-01',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      await membershipService.enrollStudent(
        studentId: sId,
        classId: cId,
        joinDate: DateTime(2026, 9, 1),
      );
      await membershipService.leaveClass(
        studentId: sId,
        classId: cId,
        endDate: DateTime(2026, 9, 30),
      );

      expect(
        () => service.assignStudent(
          studentId: sId,
          classId: cId,
          scheduleId: lId,
          startDate: DateTime(2026, 10, 1),
        ),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Membership'),
          ),
        ),
      );
    });

    test('reject open-ended assignment with finite membership', () async {
      final sId = await studentRepo.create(
        Student(
          id: 1,
          hoTen: 'Student A',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      final cId = await classRepo.create(
        ClassEntity(
          id: 1,
          tenLop: 'Class A',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      final lId = await scheduleRepo.create(
        ClassSchedule(
          id: 1,
          idLop: cId,
          thuTrongTuan: 1,
          gioBatDau: '16:30',
          gioKetThuc: '18:00',
          hieuLucTu: '2026-09-01',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      await membershipService.enrollStudent(
        studentId: sId,
        classId: cId,
        joinDate: DateTime(2026, 9, 1),
      );
      await membershipService.leaveClass(
        studentId: sId,
        classId: cId,
        endDate: DateTime(2026, 9, 30),
      );

      expect(
        () => service.assignStudent(
          studentId: sId,
          classId: cId,
          scheduleId: lId,
          startDate: DateTime(2026, 9, 10),
          endDate: null,
        ),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('không có ngày kết thúc'),
          ),
        ),
      );
    });

    test('close assignment works and prevents extension', () async {
      final sId = await studentRepo.create(
        Student(
          id: 1,
          hoTen: 'S1',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      final cId = await classRepo.create(
        ClassEntity(
          id: 1,
          tenLop: 'C1',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      final lId = await scheduleRepo.create(
        ClassSchedule(
          id: 1,
          idLop: cId,
          thuTrongTuan: 1,
          gioBatDau: '16:30',
          gioKetThuc: '18:00',
          hieuLucTu: '2026-09-01',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      await membershipService.enrollStudent(
        studentId: sId,
        classId: cId,
        joinDate: DateTime(2026, 9, 1),
      );

      await service.assignStudent(
        studentId: sId,
        classId: cId,
        scheduleId: lId,
        startDate: DateTime(2026, 9, 1),
      );
      final assignments = await service.getAssignmentsForStudent(sId);
      final aId = assignments.first.id!;

      await service.closeAssignment(aId, DateTime(2026, 9, 15));
      final closed = await service.getAssignmentsForStudent(sId);
      expect(closed.first.denNgay, '2026-09-15');
    });

    test(
      'change recurring shift requires active assignment day before',
      () async {
        final sId = await studentRepo.create(
          Student(
            id: 1,
            hoTen: 'S1',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
        final cId = await classRepo.create(
          ClassEntity(
            id: 1,
            tenLop: 'C1',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
        final l1Id = await scheduleRepo.create(
          ClassSchedule(
            id: 1,
            idLop: cId,
            thuTrongTuan: 1,
            gioBatDau: '17:30',
            gioKetThuc: '19:00',
            hieuLucTu: '2026-09-01',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
        final l2Id = await scheduleRepo.create(
          ClassSchedule(
            id: 2,
            idLop: cId,
            thuTrongTuan: 2,
            gioBatDau: '17:30',
            gioKetThuc: '19:00',
            hieuLucTu: '2026-09-01',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
        await membershipService.enrollStudent(
          studentId: sId,
          classId: cId,
          joinDate: DateTime(2026, 9, 1),
        );

        await service.assignStudent(
          studentId: sId,
          classId: cId,
          scheduleId: l1Id,
          startDate: DateTime(2026, 9, 1),
        );
        final aId = (await service.getAssignmentsForStudent(sId)).first.id!;

        // Change on 2026-09-10
        await service.changeRecurringShift(
          studentId: sId,
          classId: cId,
          oldAssignmentId: aId,
          newScheduleId: l2Id,
          effectiveDate: DateTime(2026, 9, 10),
        );

        final history = await service.getAssignmentsForStudent(sId);
        expect(history.length, 2);
        expect(
          history.any((a) => a.id == aId && a.denNgay == '2026-09-09'),
          isTrue,
        );
        expect(
          history.any((a) => a.idLichHoc == l2Id && a.tuNgay == '2026-09-10'),
          isTrue,
        );
      },
    );

    test('atomic shift change rollback on conflict with OTHER class', () async {
      final sId = await studentRepo.create(
        Student(
          id: 1,
          hoTen: 'Student A',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      final c1Id = await classRepo.create(
        ClassEntity(
          id: 1,
          tenLop: 'Class A',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      final c2Id = await classRepo.create(
        ClassEntity(
          id: 2,
          tenLop: 'Class B',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      // Class A - Schedule 1: Mon 17:30
      final l1Id = await scheduleRepo.create(
        ClassSchedule(
          id: 1,
          idLop: c1Id,
          thuTrongTuan: 1,
          gioBatDau: '16:30',
          gioKetThuc: '18:00',
          hieuLucTu: '2026-09-01',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      // Class A - Schedule 2: Mon 19:00
      final l2Id = await scheduleRepo.create(
        ClassSchedule(
          id: 2,
          idLop: c1Id,
          thuTrongTuan: 1,
          gioBatDau: '19:00',
          gioKetThuc: '20:30',
          hieuLucTu: '2026-09-01',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      // Class B - Schedule 3: Mon 18:30-20:00 (Conflict with Schedule 2)
      final l3Id = await scheduleRepo.create(
        ClassSchedule(
          id: 3,
          idLop: c2Id,
          thuTrongTuan: 1,
          gioBatDau: '18:30',
          gioKetThuc: '20:00',
          hieuLucTu: '2026-09-01',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      await membershipService.enrollStudent(
        studentId: sId,
        classId: c1Id,
        joinDate: DateTime(2026, 9, 1),
      );
      await membershipService.enrollStudent(
        studentId: sId,
        classId: c2Id,
        joinDate: DateTime(2026, 9, 1),
      );

      // Assign student to Class B Schedule 3 (18:30-20:00)
      await service.assignStudent(
        studentId: sId,
        classId: c2Id,
        scheduleId: l3Id,
        startDate: DateTime(2026, 9, 1),
      );

      // Assign student to Class A Schedule 1 (17:30-19:00)
      await service.assignStudent(
        studentId: sId,
        classId: c1Id,
        scheduleId: l1Id,
        startDate: DateTime(2026, 9, 1),
      );
      final assignments = await service.getAssignmentsForStudent(sId);
      final oldAssignmentId = assignments
          .firstWhere((a) => a.idLichHoc == l1Id)
          .id!;

      // Attempt shift change in Class A from l1 to l2 (19:00-20:30).
      // l2 (19:00-20:30) conflicts with already assigned Class B l3 (18:30-20:00).

      await expectLater(
        service.changeRecurringShift(
          studentId: sId,
          classId: c1Id,
          oldAssignmentId: oldAssignmentId,
          newScheduleId: l2Id,
          effectiveDate: DateTime(2026, 9, 10),
        ),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Trùng lịch'),
          ),
        ),
      );

      // Verify Class A Schedule 1 assignment still open-ended
      final finalAssignments = await service.getAssignmentsForStudent(sId);
      final originalA = finalAssignments.firstWhere(
        (a) => a.id == oldAssignmentId,
      );
      expect(originalA.denNgay, isNull);
    });

    test(
      'closeAssignment rejects any modification to already closed assignment',
      () async {
        final sId = await studentRepo.create(
          Student(
            id: 1,
            hoTen: 'S1',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
        final cId = await classRepo.create(
          ClassEntity(
            id: 1,
            tenLop: 'C1',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
        final lId = await scheduleRepo.create(
          ClassSchedule(
            id: 1,
            idLop: cId,
            thuTrongTuan: 1,
            gioBatDau: '17:30',
            gioKetThuc: '19:00',
            hieuLucTu: '2026-09-01',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
        await membershipService.enrollStudent(
          studentId: sId,
          classId: cId,
          joinDate: DateTime(2026, 9, 1),
        );

        await service.assignStudent(
          studentId: sId,
          classId: cId,
          scheduleId: lId,
          startDate: DateTime(2026, 9, 1),
        );
        final aId = (await service.getAssignmentsForStudent(sId)).first.id!;

        // Close it at 2026-09-15
        await service.closeAssignment(aId, DateTime(2026, 9, 15));

        // Idempotent close
        await service.closeAssignment(aId, DateTime(2026, 9, 15));

        // Try to "truncate" it to 2026-09-10 -> REJECT
        await expectLater(
          service.closeAssignment(aId, DateTime(2026, 9, 10)),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Không thể sửa đổi'),
            ),
          ),
        );

        // Try to "extend" it to 2026-09-20 -> REJECT
        await expectLater(
          service.closeAssignment(aId, DateTime(2026, 9, 20)),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Không thể sửa đổi'),
            ),
          ),
        );

        // Verify still 2026-09-15
        final finalAssignments = await service.getAssignmentsForStudent(sId);
        expect(finalAssignments.first.denNgay, '2026-09-15');
      },
    );
  });
}
