import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tuition2027/features/sessions/domain/session_service.dart';
import 'package:tuition2027/features/sessions/data/session_repository.dart';
import 'package:tuition2027/features/sessions/domain/class_session.dart';
import 'package:tuition2027/features/classes/data/class_repository.dart';
import 'package:tuition2027/features/classes/domain/class_service.dart';
import 'package:tuition2027/features/memberships/domain/membership_service.dart';
import 'package:tuition2027/features/memberships/data/membership_repository.dart';
import 'package:tuition2027/features/classes/domain/class.dart';
import 'test_db_helper_v6.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database db;
  late SessionService service;
  late SessionRepository sessionRepo;
  late ClassRepository classRepo;

  setUp(() async {
    db = await TestDbHelperV6.createLatest();
    sessionRepo = SessionRepository(db);
    classRepo = ClassRepository(db);
    final membershipService = MembershipService(MembershipRepository(db));
    final classService = ClassService(classRepo, membershipService);
    service = SessionService(sessionRepo, classService);
  });

  tearDown(() async => await db.close());

  group('SessionService Tests', () {
    test('Manual creation of HOC_BU is allowed', () async {
      final classId = await classRepo.create(
        ClassEntity(
          tenLop: 'Class 1',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      final session = ClassSession(
        idLop: classId,
        ngay: '2026-09-10',
        gioBatDau: '08:00',
        gioKetThuc: '09:00',
        loai: SessionType.HOC_BU,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await service.createManualSession(session);
      final list = await sessionRepo.getByClass(classId);
      expect(list.length, 1);
      expect(list.first.loai, SessionType.HOC_BU);
    });

    test('Manual creation of CHINH is rejected', () async {
      final classId = await classRepo.create(
        ClassEntity(
          tenLop: 'Class 1',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      final session = ClassSession(
        idLop: classId,
        ngay: '2026-09-10',
        gioBatDau: '08:00',
        gioKetThuc: '09:00',
        loai: SessionType.CHINH,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(
        () => service.createManualSession(session),
        throwsA(predicate((e) => e.toString().contains('Sinh buổi học'))),
      );
    });

    test(
      'Status update to DA_HOC is rejected (reserved for attendance)',
      () async {
        final classId = await classRepo.create(
          ClassEntity(
            tenLop: 'Class 1',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
        final session = ClassSession(
          idLop: classId,
          ngay: '2026-09-10',
          gioBatDau: '08:00',
          gioKetThuc: '09:00',
          loai: SessionType.PHAT_SINH,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await sessionRepo.create(session);
        final created = (await sessionRepo.getByClass(classId)).first;

        expect(
          () => service.updateStatus(created.id!, SessionStatus.DA_HOC),
          throwsA(predicate((e) => e.toString().contains('điểm danh'))),
        );
      },
    );

    test('Archived class blocked from manual session', () async {
      final classId = await classRepo.create(
        ClassEntity(
          tenLop: 'Archived',
          daLuuTru: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      final session = ClassSession(
        idLop: classId,
        ngay: '2026-09-10',
        gioBatDau: '08:00',
        gioKetThuc: '09:00',
        loai: SessionType.PHAT_SINH,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(
        () => service.createManualSession(session),
        throwsA(predicate((e) => e.toString().contains('lớp đã lưu trữ'))),
      );
    });
  });
}
