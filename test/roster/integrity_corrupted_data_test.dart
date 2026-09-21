import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tuition2027/features/roster/domain/roster_service.dart';
import 'package:tuition2027/features/roster/domain/roster_result.dart';
import 'package:tuition2027/features/sessions/domain/session_service.dart';
import 'package:tuition2027/features/sessions/data/session_repository.dart';
import 'package:tuition2027/features/memberships/domain/membership_service.dart';
import 'package:tuition2027/features/memberships/data/membership_repository.dart';
import 'package:tuition2027/features/schedule/domain/schedule_service.dart';
import 'package:tuition2027/features/schedule/data/schedule_repository.dart';
import 'package:tuition2027/features/schedule/data/assignment_repository.dart';
import 'package:tuition2027/features/students/domain/student_service.dart';
import 'package:tuition2027/features/students/data/student_repository.dart';
import 'package:tuition2027/features/classes/domain/class_service.dart';
import 'package:tuition2027/features/classes/data/class_repository.dart';
import '../sessions/test_db_helper_v6.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database db;
  late RosterService rosterService;

  final now = DateTime.now().toIso8601String();

  setUp(() async {
    db = await TestDbHelperV6.createLatest();

    final sessionRepo = SessionRepository(db);
    final membershipRepo = MembershipRepository(db);
    final scheduleRepo = ScheduleRepository(db);
    final assignmentRepo = AssignmentRepository(db);
    final studentRepo = StudentRepository(db);
    final classRepo = ClassRepository(db);

    final membershipService = MembershipService(membershipRepo);
    final classService = ClassService(classRepo, membershipService);
    final studentService = StudentService(studentRepo, membershipService);
    final sessionService = SessionService(sessionRepo, classService);
    final scheduleService = ScheduleDomainService(
      scheduleRepo,
      assignmentRepo,
      membershipService,
      classService,
      studentService,
    );

    rosterService = RosterService(
      sessionService,
      membershipService,
      scheduleService,
      studentService,
    );
  });

  tearDown(() async => await db.close());

  group('RosterService Integrity Hardening (Corrupted Data)', () {
    test('Inject multiple active assignments same session date', () async {
      await db.insert('lop',
          {'id': 1, 'ten_lop': 'Multi', 'created_at': now, 'updated_at': now});
      await db.insert('lich_hoc', {
        'id': 1,
        'id_lop': 1,
        'thu_trong_tuan': 1,
        'gio_bat_dau': '17:30',
        'gio_ket_thuc': '19:00',
        'hieu_luc_tu': '2026-01-01',
        'created_at': now,
        'updated_at': now
      });
      await db.insert('lich_hoc', {
        'id': 2,
        'id_lop': 1,
        'thu_trong_tuan': 1,
        'gio_bat_dau': '19:00',
        'gio_ket_thuc': '20:30',
        'hieu_luc_tu': '2026-01-01',
        'created_at': now,
        'updated_at': now
      });

      await db.insert('hoc_sinh',
          {'id': 1, 'ho_ten': 'S1', 'created_at': now, 'updated_at': now});
      await db.insert('tham_gia_lop', {
        'id': 1,
        'id_hoc_sinh': 1,
        'id_lop': 1,
        'tu_ngay': '2026-01-01',
        'created_at': now,
        'updated_at': now
      });

      // Inject CORRUPTED data: same student, same class, overlapping dates for different schedules
      await db.insert('phan_ca_hoc_sinh', {
        'id': 1,
        'id_hoc_sinh': 1,
        'id_lop': 1,
        'id_lich_hoc': 1,
        'tu_ngay': '2026-09-01',
        'created_at': now,
        'updated_at': now
      });
      await db.insert('phan_ca_hoc_sinh', {
        'id': 2,
        'id_hoc_sinh': 1,
        'id_lop': 1,
        'id_lich_hoc': 2,
        'tu_ngay': '2026-09-01',
        'created_at': now,
        'updated_at': now
      });

      // Session Mon 17:30
      await db.insert('buoi_hoc', {
        'id': 1,
        'id_lop': 1,
        'id_lich_hoc': 1,
        'ngay': '2026-09-07',
        'gio_bat_dau': '17:30',
        'gio_ket_thuc': '19:00',
        'loai': 'CHINH',
        'created_at': now,
        'updated_at': now
      });

      final result = await rosterService.getRosterForSession(1);

      expect(result.participants, isEmpty);
      expect(
          result.issues.any(
              (i) => i.code == RosterIssueCode.MULTIPLE_ACTIVE_ASSIGNMENTS),
          isTrue);
      expect(result.isOperationallyValid, isFalse);
    });

    test('Inject assignment starting BEFORE membership', () async {
      await db.insert('lop', {'id': 1, 'ten_lop': 'M', 'created_at': now, 'updated_at': now});
      await db.insert('lich_hoc', {'id': 1, 'id_lop': 1, 'thu_trong_tuan': 1, 'gio_bat_dau': '17:30', 'gio_ket_thuc': '19:00', 'hieu_luc_tu': '2026-01-01', 'created_at': now, 'updated_at': now});
      // Another schedule to force multi-shift
      await db.insert('lich_hoc', {'id': 2, 'id_lop': 1, 'thu_trong_tuan': 1, 'gio_bat_dau': '19:00', 'gio_ket_thuc': '20:30', 'hieu_luc_tu': '2026-01-01', 'created_at': now, 'updated_at': now});
      
      await db.insert('hoc_sinh', {'id': 1, 'ho_ten': 'S1', 'created_at': now, 'updated_at': now});
      
      // Membership starts 10/09
      await db.insert('tham_gia_lop', {'id': 1, 'id_hoc_sinh': 1, 'id_lop': 1, 'tu_ngay': '2026-09-10', 'created_at': now, 'updated_at': now});
      
      // Assignment starts 01/09 (BEFORE membership)
      await db.insert('phan_ca_hoc_sinh', {'id': 1, 'id_hoc_sinh': 1, 'id_lop': 1, 'id_lich_hoc': 1, 'tu_ngay': '2026-09-01', 'created_at': now, 'updated_at': now});

      // Session 14/09 (Mon)
      await db.insert('buoi_hoc', {'id': 1, 'id_lop': 1, 'id_lich_hoc': 1, 'ngay': '2026-09-14', 'gio_bat_dau': '17:30', 'gio_ket_thuc': '19:00', 'loai': 'CHINH', 'created_at': now, 'updated_at': now});

      final result = await rosterService.getRosterForSession(1);
      expect(result.participants, isEmpty);
      expect(result.issues.any((i) => i.code == RosterIssueCode.INVALID_ASSIGNMENT), isTrue);
    });

    test('Inject assignment ending AFTER membership', () async {
      await db.insert('lop', {'id': 1, 'ten_lop': 'M', 'created_at': now, 'updated_at': now});
      await db.insert('lich_hoc', {'id': 1, 'id_lop': 1, 'thu_trong_tuan': 1, 'gio_bat_dau': '17:30', 'gio_ket_thuc': '19:00', 'hieu_luc_tu': '2026-01-01', 'created_at': now, 'updated_at': now});
      await db.insert('lich_hoc', {'id': 2, 'id_lop': 1, 'thu_trong_tuan': 1, 'gio_bat_dau': '19:00', 'gio_ket_thuc': '20:30', 'hieu_luc_tu': '2026-01-01', 'created_at': now, 'updated_at': now});

      await db.insert('hoc_sinh', {'id': 1, 'ho_ten': 'S1', 'created_at': now, 'updated_at': now});
      
      // Membership 01/09 -> 20/09
      await db.insert('tham_gia_lop', {'id': 1, 'id_hoc_sinh': 1, 'id_lop': 1, 'tu_ngay': '2026-09-01', 'den_ngay': '2026-09-20', 'created_at': now, 'updated_at': now});
      
      // Assignment 01/09 -> 30/09 (AFTER membership end)
      await db.insert('phan_ca_hoc_sinh', {'id': 1, 'id_hoc_sinh': 1, 'id_lop': 1, 'id_lich_hoc': 1, 'tu_ngay': '2026-09-01', 'den_ngay': '2026-09-30', 'created_at': now, 'updated_at': now});

      // Session 14/09 (Mon) - Both membership and assignment are active on this date, but interval is invalid
      await db.insert('buoi_hoc', {'id': 1, 'id_lop': 1, 'id_lich_hoc': 1, 'ngay': '2026-09-14', 'gio_bat_dau': '17:30', 'gio_ket_thuc': '19:00', 'loai': 'CHINH', 'created_at': now, 'updated_at': now});

      final result = await rosterService.getRosterForSession(1);
      expect(result.participants, isEmpty);
      expect(result.issues.any((i) => i.code == RosterIssueCode.INVALID_ASSIGNMENT), isTrue);
    });

    test('Inject OPEN assignment with CLOSED membership', () async {
      await db.insert('lop', {'id': 1, 'ten_lop': 'M', 'created_at': now, 'updated_at': now});
      await db.insert('lich_hoc', {'id': 1, 'id_lop': 1, 'thu_trong_tuan': 1, 'gio_bat_dau': '17:30', 'gio_ket_thuc': '19:00', 'hieu_luc_tu': '2026-01-01', 'created_at': now, 'updated_at': now});
      await db.insert('lich_hoc', {'id': 2, 'id_lop': 1, 'thu_trong_tuan': 1, 'gio_bat_dau': '19:00', 'gio_ket_thuc': '20:30', 'hieu_luc_tu': '2026-01-01', 'created_at': now, 'updated_at': now});

      await db.insert('hoc_sinh', {'id': 1, 'ho_ten': 'S1', 'created_at': now, 'updated_at': now});
      
      // Membership 01/09 -> 20/09
      await db.insert('tham_gia_lop', {'id': 1, 'id_hoc_sinh': 1, 'id_lop': 1, 'tu_ngay': '2026-09-01', 'den_ngay': '2026-09-20', 'created_at': now, 'updated_at': now});
      
      // Assignment 01/09 -> NULL (Open assignment with closed membership)
      await db.insert('phan_ca_hoc_sinh', {'id': 1, 'id_hoc_sinh': 1, 'id_lop': 1, 'id_lich_hoc': 1, 'tu_ngay': '2026-09-01', 'den_ngay': null, 'created_at': now, 'updated_at': now});

      // Session 14/09
      await db.insert('buoi_hoc', {'id': 1, 'id_lop': 1, 'id_lich_hoc': 1, 'ngay': '2026-09-14', 'gio_bat_dau': '17:30', 'gio_ket_thuc': '19:00', 'loai': 'CHINH', 'created_at': now, 'updated_at': now});

      final result = await rosterService.getRosterForSession(1);
      expect(result.participants, isEmpty);
      expect(result.issues.any((i) => i.code == RosterIssueCode.INVALID_ASSIGNMENT), isTrue);
    });
  });
}
