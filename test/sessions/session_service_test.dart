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
          id: 1,
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

    test('Manual creation of PHAT_SINH is allowed', () async {
      final classId = await classRepo.create(
        ClassEntity(
          id: 1,
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

      await service.createManualSession(session);
      final list = await sessionRepo.getByClass(classId);
      expect(list.length, 1);
      expect(list.first.loai, SessionType.PHAT_SINH);
    });

    test('Manual creation of CHINH is rejected', () async {
      final classId = await classRepo.create(
        ClassEntity(
          id: 1,
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

    test('Manual creation with idLichHoc is rejected', () async {
      final classId = await classRepo.create(
        ClassEntity(
          id: 1,
          tenLop: 'Class 1',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      final session = ClassSession(
        idLop: classId,
        idLichHoc: 1,
        ngay: '2026-09-10',
        gioBatDau: '08:00',
        gioKetThuc: '09:00',
        loai: SessionType.HOC_BU,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(
        () => service.createManualSession(session),
        throwsA(predicate((e) => e.toString().contains('không được gắn'))),
      );
    });

    test('Status update to DA_HOC is rejected (Phase 4)', () async {
      final classId = await classRepo.create(
        ClassEntity(
          id: 1,
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
    });

    test('Status update for session ALREADY DA_HOC is rejected', () async {
      final classId = await classRepo.create(
        ClassEntity(
          id: 1,
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
        trangThai: SessionStatus.DA_HOC,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await sessionRepo.create(session);
      final created = (await sessionRepo.getByClass(classId)).first;

      expect(
        () => service.updateStatus(created.id!, SessionStatus.DU_KIEN),
        throwsA(predicate((e) => e.toString().contains('đã hoàn tất'))),
      );
      expect(
        () => service.updateStatus(created.id!, SessionStatus.HUY),
        throwsA(predicate((e) => e.toString().contains('đã hoàn tất'))),
      );
      expect(
        () => service.updateStatus(created.id!, SessionStatus.NGHI_LE),
        throwsA(predicate((e) => e.toString().contains('đã hoàn tất'))),
      );
    });

    test('markTaughtFromAttendance behavior', () async {
      final classId = await classRepo.create(
        ClassEntity(
          id: 1,
          tenLop: 'Class 1',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      // 1. DU_KIEN CHINH -> Allowed
      final session1 = ClassSession(
        idLop: classId,
        ngay: '2026-09-10',
        gioBatDau: '08:00',
        gioKetThuc: '09:00',
        loai: SessionType.CHINH,
        trangThai: SessionStatus.DU_KIEN,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final id1 = await sessionRepo.create(session1);
      await service.markTaughtFromAttendance(id1);
      expect((await sessionRepo.getById(id1))!.trangThai, SessionStatus.DA_HOC);

      // 2. Already DA_HOC -> Safe No-op
      await service.markTaughtFromAttendance(id1);
      expect((await sessionRepo.getById(id1))!.trangThai, SessionStatus.DA_HOC);

      // 3. HUY / NGHI_LE -> Rejected
      final sessionHuy = ClassSession(
        idLop: classId,
        ngay: '2026-09-11',
        gioBatDau: '08:00',
        gioKetThuc: '09:00',
        loai: SessionType.CHINH,
        trangThai: SessionStatus.HUY,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final idHuy = await sessionRepo.create(sessionHuy);
      expect(
        () => service.markTaughtFromAttendance(idHuy),
        throwsA(isA<Exception>()),
      );

      // 4. HOC_BU / PHAT_SINH -> Rejected in Phase 6
      final sessionHB = ClassSession(
        idLop: classId,
        ngay: '2026-09-12',
        gioBatDau: '08:00',
        gioKetThuc: '09:00',
        loai: SessionType.HOC_BU,
        trangThai: SessionStatus.DU_KIEN,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final idHB = await sessionRepo.create(sessionHB);
      expect(
        () => service.markTaughtFromAttendance(idHB),
        throwsA(isA<Exception>()),
      );
    });

    test('Status transitions: DU_KIEN <-> HUY / NGHI_LE', () async {
      final classId = await classRepo.create(
        ClassEntity(
          id: 1,
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
      final s = (await sessionRepo.getByClass(classId)).first;

      // To HUY
      await service.updateStatus(s.id!, SessionStatus.HUY);
      expect((await sessionRepo.getById(s.id!))!.trangThai, SessionStatus.HUY);

      // To NGHI_LE
      await service.updateStatus(s.id!, SessionStatus.NGHI_LE);
      expect(
        (await sessionRepo.getById(s.id!))!.trangThai,
        SessionStatus.NGHI_LE,
      );

      // Back to DU_KIEN
      await service.updateStatus(s.id!, SessionStatus.DU_KIEN);
      expect(
        (await sessionRepo.getById(s.id!))!.trangThai,
        SessionStatus.DU_KIEN,
      );
    });

    test('Archived class rejected for manual session', () async {
      final classId = await classRepo.create(
        ClassEntity(
          id: 1,
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

    test('Validation: strict date validation rejected', () async {
      final classId = await classRepo.create(
        ClassEntity(
          id: 1,
          tenLop: 'Class 1',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      final base = ClassSession(
        idLop: classId,
        ngay: '2026-02-30', // Impossible date
        gioBatDau: '08:00',
        gioKetThuc: '09:00',
        loai: SessionType.HOC_BU,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Impossible Feb 30 rejected
      expect(
        () => service.createManualSession(base),
        throwsA(predicate((e) => e.toString().contains('không hợp lệ'))),
      );

      // Month 13 rejected
      expect(
        () => service.createManualSession(base.copyWith(ngay: '2026-13-01')),
        throwsA(predicate((e) => e.toString().contains('không hợp lệ'))),
      );

      // April 31 rejected
      expect(
        () => service.createManualSession(base.copyWith(ngay: '2026-04-31')),
        throwsA(predicate((e) => e.toString().contains('không hợp lệ'))),
      );

      // Valid leap day accepted
      final leapSession = base.copyWith(ngay: '2028-02-29');
      await service.createManualSession(leapSession);
      expect((await sessionRepo.getByClass(classId)).length, 1);
    });

    test('Validation: Invalid date string rejected', () async {
      final classId = await classRepo.create(
        ClassEntity(
          id: 1,
          tenLop: 'Class 1',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      final session = ClassSession(
        idLop: classId,
        ngay: '2026/09/10', // Wrong format
        gioBatDau: '08:00',
        gioKetThuc: '09:00',
        loai: SessionType.HOC_BU,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(
        () => service.createManualSession(session),
        throwsA(predicate((e) => e.toString().contains('không hợp lệ'))),
      );
    });

    test('Validation: Malformed time rejected', () async {
      final classId = await classRepo.create(
        ClassEntity(
          id: 1,
          tenLop: 'Class 1',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      final base = ClassSession(
        idLop: classId,
        ngay: '2026-09-10',
        gioBatDau: '08:00',
        gioKetThuc: '09:00',
        loai: SessionType.HOC_BU,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(
        () => service.createManualSession(base.copyWith(gioBatDau: '8:00')),
        throwsA(predicate((e) => e.toString().contains('giờ bắt đầu'))),
      );
      expect(
        () => service.createManualSession(base.copyWith(gioBatDau: '25:00')),
        throwsA(predicate((e) => e.toString().contains('giờ bắt đầu'))),
      );
    });

    test('Validation: end <= start rejected', () async {
      final classId = await classRepo.create(
        ClassEntity(
          id: 1,
          tenLop: 'Class 1',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      final base = ClassSession(
        idLop: classId,
        ngay: '2026-09-10',
        gioBatDau: '08:00',
        gioKetThuc: '08:00',
        loai: SessionType.HOC_BU,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(
        () => service.createManualSession(base),
        throwsA(predicate((e) => e.toString().contains('sau giờ bắt đầu'))),
      );
      expect(
        () => service.createManualSession(base.copyWith(gioKetThuc: '07:00')),
        throwsA(predicate((e) => e.toString().contains('sau giờ bắt đầu'))),
      );
    });

    test('Validation: Duplicate identity rejected', () async {
      final classId = await classRepo.create(
        ClassEntity(
          id: 1,
          tenLop: 'C',
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
      await sessionRepo.create(session);

      expect(
        () => service.createManualSession(session),
        throwsA(predicate((e) => e.toString().contains('Đã tồn tại'))),
      );
    });
  });
}
