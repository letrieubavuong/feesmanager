import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tuition2027/features/roster/domain/roster_service.dart';
import 'package:tuition2027/features/roster/domain/roster_result.dart';
import 'package:tuition2027/features/roster/domain/roster_member.dart';
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
  late SessionService sessionService;
  late MembershipService membershipService;
  late ScheduleDomainService scheduleService;
  late StudentService studentService;
  late ClassService classService;

  final now = DateTime.now().toIso8601String();

  setUp(() async {
    db = await TestDbHelperV6.createLatest();

    final sessionRepo = SessionRepository(db);
    final membershipRepo = MembershipRepository(db);
    final scheduleRepo = ScheduleRepository(db);
    final assignmentRepo = AssignmentRepository(db);
    final studentRepo = StudentRepository(db);
    final classRepo = ClassRepository(db);

    membershipService = MembershipService(membershipRepo);
    classService = ClassService(classRepo, membershipService);
    studentService = StudentService(studentRepo, membershipService);
    sessionService = SessionService(sessionRepo, classService);
    scheduleService = ScheduleDomainService(
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

  group('RosterService Domain Tests', () {
    test('getRosterForSession throws if session not found', () async {
      expect(
        () => rosterService.getRosterForSession(999),
        throwsA(predicate((e) => e.toString().contains('Không tìm thấy'))),
      );
    });

    test('Single shift class includes all active students', () async {
      // 1. Setup Class
      await db.insert('lop', {
        'id': 1,
        'ten_lop': 'Class 1',
        'created_at': now,
        'updated_at': now,
      });

      // 2. Setup Students
      await db.insert('hoc_sinh', {
        'id': 101,
        'ho_ten': 'Student A',
        'created_at': now,
        'updated_at': now,
      });
      await db.insert('hoc_sinh', {
        'id': 102,
        'ho_ten': 'Student B',
        'created_at': now,
        'updated_at': now,
      });

      // 3. Setup Memberships
      await db.insert('tham_gia_lop', {
        'id': 1,
        'id_hoc_sinh': 101,
        'id_lop': 1,
        'tu_ngay': '2026-09-01',
        'created_at': now,
        'updated_at': now,
      });
      await db.insert('tham_gia_lop', {
        'id': 2,
        'id_hoc_sinh': 102,
        'id_lop': 1,
        'tu_ngay': '2026-09-01',
        'created_at': now,
        'updated_at': now,
      });

      // 4. Setup Schedule (Only 1)
      await db.insert('lich_hoc', {
        'id': 1,
        'id_lop': 1,
        'thu_trong_tuan': 1,
        'gio_bat_dau': '17:30',
        'gio_ket_thuc': '19:00',
        'hieu_luc_tu': '2026-09-01',
        'created_at': now,
        'updated_at': now,
      });

      // 5. Setup Session
      await db.insert('buoi_hoc', {
        'id': 1,
        'id_lop': 1,
        'id_lich_hoc': 1,
        'ngay': '2026-09-07',
        'gio_bat_dau': '17:30',
        'gio_ket_thuc': '19:00',
        'loai': 'CHINH',
        'created_at': now,
        'updated_at': now,
      });

      final result = await rosterService.getRosterForSession(1);

      expect(result.participants.length, 2);
      expect(
        result.participants.any((m) => m.student.hoTen == 'Student A'),
        isTrue,
      );
      expect(
        result.participants.any((m) => m.student.hoTen == 'Student B'),
        isTrue,
      );
      expect(
        result.participants.every(
          (m) => m.source == RosterInclusionSource.SINGLE_SHIFT_MEMBERSHIP,
        ),
        isTrue,
      );
    });

    test('Membership boundary test', () async {
      await db.insert('lop', {
        'id': 1,
        'ten_lop': 'C',
        'created_at': now,
        'updated_at': now,
      });
      await db.insert('lich_hoc', {
        'id': 1,
        'id_lop': 1,
        'thu_trong_tuan': 1,
        'gio_bat_dau': '17:30',
        'gio_ket_thuc': '19:00',
        'hieu_luc_tu': '2026-01-01',
        'created_at': now,
        'updated_at': now,
      });

      // Session on 2026-09-07 (Mon)
      await db.insert('buoi_hoc', {
        'id': 1,
        'id_lop': 1,
        'id_lich_hoc': 1,
        'ngay': '2026-09-07',
        'gio_bat_dau': '17:30',
        'gio_ket_thuc': '19:00',
        'loai': 'CHINH',
        'created_at': now,
        'updated_at': now,
      });

      // S1: join on session date -> INCLUDED
      await db.insert('hoc_sinh', {
        'id': 1,
        'ho_ten': 'S1',
        'created_at': now,
        'updated_at': now,
      });
      await db.insert('tham_gia_lop', {
        'id': 1,
        'id_hoc_sinh': 1,
        'id_lop': 1,
        'tu_ngay': '2026-09-07',
        'created_at': now,
        'updated_at': now,
      });

      // S2: end on session date -> INCLUDED
      await db.insert('hoc_sinh', {
        'id': 2,
        'ho_ten': 'S2',
        'created_at': now,
        'updated_at': now,
      });
      await db.insert('tham_gia_lop', {
        'id': 2,
        'id_hoc_sinh': 2,
        'id_lop': 1,
        'tu_ngay': '2026-09-01',
        'den_ngay': '2026-09-07',
        'created_at': now,
        'updated_at': now,
      });

      // S3: join after -> EXCLUDED
      await db.insert('hoc_sinh', {
        'id': 3,
        'ho_ten': 'S3',
        'created_at': now,
        'updated_at': now,
      });
      await db.insert('tham_gia_lop', {
        'id': 3,
        'id_hoc_sinh': 3,
        'id_lop': 1,
        'tu_ngay': '2026-09-08',
        'created_at': now,
        'updated_at': now,
      });

      // S4: end before -> EXCLUDED
      await db.insert('hoc_sinh', {
        'id': 4,
        'ho_ten': 'S4',
        'created_at': now,
        'updated_at': now,
      });
      await db.insert('tham_gia_lop', {
        'id': 4,
        'id_hoc_sinh': 4,
        'id_lop': 1,
        'tu_ngay': '2026-09-01',
        'den_ngay': '2026-09-06',
        'created_at': now,
        'updated_at': now,
      });

      final result = await rosterService.getRosterForSession(1);
      expect(result.participants.length, 2);
      expect(result.participants.any((m) => m.student.hoTen == 'S1'), isTrue);
      expect(result.participants.any((m) => m.student.hoTen == 'S2'), isTrue);
    });

    test('Multi-shift split logic', () async {
      await db.insert('lop', {
        'id': 1,
        'ten_lop': 'Multi',
        'created_at': now,
        'updated_at': now,
      });
      // Shift 1: 17:30
      await db.insert('lich_hoc', {
        'id': 1,
        'id_lop': 1,
        'thu_trong_tuan': 1,
        'gio_bat_dau': '17:30',
        'gio_ket_thuc': '19:00',
        'hieu_luc_tu': '2026-01-01',
        'created_at': now,
        'updated_at': now,
      });
      // Shift 2: 19:00
      await db.insert('lich_hoc', {
        'id': 2,
        'id_lop': 1,
        'thu_trong_tuan': 1,
        'gio_bat_dau': '19:00',
        'gio_ket_thuc': '20:30',
        'hieu_luc_tu': '2026-01-01',
        'created_at': now,
        'updated_at': now,
      });

      await db.insert('hoc_sinh', {
        'id': 1,
        'ho_ten': 'An',
        'created_at': now,
        'updated_at': now,
      });
      await db.insert('hoc_sinh', {
        'id': 2,
        'ho_ten': 'Binh',
        'created_at': now,
        'updated_at': now,
      });
      await db.insert('hoc_sinh', {
        'id': 3,
        'ho_ten': 'Cuong',
        'created_at': now,
        'updated_at': now,
      });

      await db.insert('tham_gia_lop', {
        'id': 1,
        'id_hoc_sinh': 1,
        'id_lop': 1,
        'tu_ngay': '2026-01-01',
        'created_at': now,
        'updated_at': now,
      });
      await db.insert('tham_gia_lop', {
        'id': 2,
        'id_hoc_sinh': 2,
        'id_lop': 1,
        'tu_ngay': '2026-01-01',
        'created_at': now,
        'updated_at': now,
      });
      await db.insert('tham_gia_lop', {
        'id': 3,
        'id_hoc_sinh': 3,
        'id_lop': 1,
        'tu_ngay': '2026-01-01',
        'created_at': now,
        'updated_at': now,
      });

      // Assignments
      await db.insert('phan_ca_hoc_sinh', {
        'id': 1,
        'id_hoc_sinh': 1,
        'id_lop': 1,
        'id_lich_hoc': 1,
        'tu_ngay': '2026-01-01',
        'created_at': now,
        'updated_at': now,
      }); // An -> 17:30
      await db.insert('phan_ca_hoc_sinh', {
        'id': 2,
        'id_hoc_sinh': 2,
        'id_lop': 1,
        'id_lich_hoc': 2,
        'tu_ngay': '2026-01-01',
        'created_at': now,
        'updated_at': now,
      }); // Binh -> 19:00
      // Cuong -> Unassigned

      // Session 1: 17:30
      await db.insert('buoi_hoc', {
        'id': 1,
        'id_lop': 1,
        'id_lich_hoc': 1,
        'ngay': '2026-09-07',
        'gio_bat_dau': '17:30',
        'gio_ket_thuc': '19:00',
        'loai': 'CHINH',
        'created_at': now,
        'updated_at': now,
      });
      // Session 2: 19:00
      await db.insert('buoi_hoc', {
        'id': 2,
        'id_lop': 1,
        'id_lich_hoc': 2,
        'ngay': '2026-09-07',
        'gio_bat_dau': '19:00',
        'gio_ket_thuc': '20:30',
        'loai': 'CHINH',
        'created_at': now,
        'updated_at': now,
      });

      // Roster Session 1 (17:30)
      final res1 = await rosterService.getRosterForSession(1);
      expect(res1.participants.length, 1);
      expect(res1.participants.first.student.hoTen, 'An');
      expect(res1.unassignedMembers.any((s) => s.hoTen == 'Cuong'), isTrue);
      expect(
        res1.issues.any(
          (i) => i.code == RosterIssueCode.UNASSIGNED_IN_MULTI_SHIFT,
        ),
        isTrue,
      );

      // Roster Session 2 (19:00)
      final res2 = await rosterService.getRosterForSession(2);
      expect(res2.participants.length, 1);
      expect(res2.participants.first.student.hoTen, 'Binh');
    });

    test('Historical roster preserves archived students', () async {
      await db.insert('lop', {
        'id': 1,
        'ten_lop': 'C',
        'created_at': now,
        'updated_at': now,
      });
      await db.insert('lich_hoc', {
        'id': 1,
        'id_lop': 1,
        'thu_trong_tuan': 1,
        'gio_bat_dau': '17:30',
        'gio_ket_thuc': '19:00',
        'hieu_luc_tu': '2026-01-01',
        'created_at': now,
        'updated_at': now,
      });
      await db.insert('buoi_hoc', {
        'id': 10,
        'id_lop': 1,
        'id_lich_hoc': 1,
        'ngay': '2026-05-04',
        'gio_bat_dau': '17:30',
        'gio_ket_thuc': '19:00',
        'loai': 'CHINH',
        'created_at': now,
        'updated_at': now,
      });

      // S1 was active in May
      await db.insert('hoc_sinh', {
        'id': 1,
        'ho_ten': 'Old Student',
        'da_luu_tru': 1,
        'created_at': now,
        'updated_at': now,
      });
      await db.insert('tham_gia_lop', {
        'id': 1,
        'id_hoc_sinh': 1,
        'id_lop': 1,
        'tu_ngay': '2026-01-01',
        'den_ngay': '2026-06-01',
        'created_at': now,
        'updated_at': now,
      });

      final result = await rosterService.getRosterForSession(10);
      expect(result.participants.length, 1);
      expect(result.participants.first.student.hoTen, 'Old Student');
    });

    test('Read purity: getRosterForSession does not mutate DB', () async {
      await db.insert('lop', {
        'id': 1,
        'ten_lop': 'C',
        'created_at': now,
        'updated_at': now,
      });
      await db.insert('lich_hoc', {
        'id': 1,
        'id_lop': 1,
        'thu_trong_tuan': 1,
        'gio_bat_dau': '17:30',
        'gio_ket_thuc': '19:00',
        'hieu_luc_tu': '2026-01-01',
        'created_at': now,
        'updated_at': now,
      });
      await db.insert('buoi_hoc', {
        'id': 1,
        'id_lop': 1,
        'id_lich_hoc': 1,
        'ngay': '2026-09-07',
        'gio_bat_dau': '17:30',
        'gio_ket_thuc': '19:00',
        'loai': 'CHINH',
        'created_at': now,
        'updated_at': now,
      });

      final before = await db.rawQuery('SELECT count(*) as cnt FROM buoi_hoc');
      await rosterService.getRosterForSession(1);
      await rosterService.getRosterForSession(1);
      final after = await db.rawQuery('SELECT count(*) as cnt FROM buoi_hoc');

      expect(before, after);
    });

    test(
      'HOC_BU returns empty participants with adjustment requirement',
      () async {
        await db.insert('lop', {
          'id': 1,
          'ten_lop': 'C',
          'created_at': now,
          'updated_at': now,
        });
        await db.insert('buoi_hoc', {
          'id': 50,
          'id_lop': 1,
          'id_lich_hoc': null,
          'ngay': '2026-09-10',
          'gio_bat_dau': '08:00',
          'gio_ket_thuc': '10:00',
          'loai': 'HOC_BU',
          'created_at': now,
          'updated_at': now,
        });

        final result = await rosterService.getRosterForSession(50);
        expect(result.participants, isEmpty);
        expect(result.requiresOneOffAdjustments, isTrue);
      },
    );
  });
}
