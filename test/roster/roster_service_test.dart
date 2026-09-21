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

    test(
      'Single shift class includes all active students (same weekday only)',
      () async {
        await db.insert('lop', {
          'id': 1,
          'ten_lop': 'C1',
          'created_at': now,
          'updated_at': now,
        });

        // Two schedules but on DIFFERENT weekdays
        await db.insert('lich_hoc', {
          'id': 1,
          'id_lop': 1,
          'thu_trong_tuan': 1, // Mon
          'gio_bat_dau': '17:30',
          'gio_ket_thuc': '19:00',
          'hieu_luc_tu': '2026-01-01',
          'created_at': now,
          'updated_at': now,
        });
        await db.insert('lich_hoc', {
          'id': 2,
          'id_lop': 1,
          'thu_trong_tuan': 3, // Wed
          'gio_bat_dau': '17:30',
          'gio_ket_thuc': '19:00',
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
        await db.insert('tham_gia_lop', {
          'id': 1,
          'id_hoc_sinh': 1,
          'id_lop': 1,
          'tu_ngay': '2026-01-01',
          'created_at': now,
          'updated_at': now,
        });

        // Session on Monday 2026-09-07
        await db.insert('buoi_hoc', {
          'id': 10,
          'id_lop': 1,
          'id_lich_hoc': 1,
          'ngay': '2026-09-07',
          'gio_bat_dau': '17:30',
          'gio_ket_thuc': '19:00',
          'loai': 'CHINH',
          'created_at': now,
          'updated_at': now,
        });

        final result = await rosterService.getRosterForSession(10);
        // It's considered single-shift for Monday because only 1 schedule on Mon.
        expect(result.participants.length, 1);
        expect(result.participants.first.student.hoTen, 'An');
        expect(
          result.participants.first.source,
          RosterInclusionSource.SINGLE_SHIFT_MEMBERSHIP,
        );
      },
    );

    test('Multi-shift split logic (same weekday)', () async {
      await db.insert('lop', {
        'id': 1,
        'ten_lop': 'Multi',
        'created_at': now,
        'updated_at': now,
      });
      // Shift 1: Mon 17:30
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
      // Shift 2: Mon 19:00
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

      // Session 1: Mon 17:30
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
      expect(result.participants.length, 1);
      expect(result.participants.first.student.hoTen, 'An');
      expect(result.unassignedMembers.any((s) => s.hoTen == 'Cuong'), isTrue);
    });

    test('Fail closed on schedule outside effective interval', () async {
      await db.insert('lop', {
        'id': 1,
        'ten_lop': 'C',
        'created_at': now,
        'updated_at': now,
      });
      // Schedule effective 01/09 -> 10/09
      await db.insert('lich_hoc', {
        'id': 1,
        'id_lop': 1,
        'thu_trong_tuan': 7, // Sun
        'gio_bat_dau': '08:00',
        'gio_ket_thuc': '10:00',
        'hieu_luc_tu': '2026-09-01',
        'hieu_luc_den': '2026-09-10',
        'created_at': now,
        'updated_at': now,
      });

      // Session on 20/09
      await db.insert('buoi_hoc', {
        'id': 1,
        'id_lop': 1,
        'id_lich_hoc': 1,
        'ngay': '2026-09-20',
        'gio_bat_dau': '08:00',
        'gio_ket_thuc': '10:00',
        'loai': 'CHINH',
        'created_at': now,
        'updated_at': now,
      });

      final result = await rosterService.getRosterForSession(1);
      expect(result.isOperationallyValid, isFalse);
      expect(
        result.issues.any(
          (i) => i.code == RosterIssueCode.SESSION_SCHEDULE_NOT_EFFECTIVE,
        ),
        isTrue,
      );
      expect(result.participants, isEmpty);
    });

    test('Membership pause / resume correct handling', () async {
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

      await db.insert('hoc_sinh', {
        'id': 1,
        'ho_ten': 'S1',
        'created_at': now,
        'updated_at': now,
      });
      // 01/09 -> 10/09
      await db.insert('tham_gia_lop', {
        'id': 1,
        'id_hoc_sinh': 1,
        'id_lop': 1,
        'tu_ngay': '2026-09-01',
        'den_ngay': '2026-09-10',
        'created_at': now,
        'updated_at': now,
      });
      // 20/09 -> NULL
      await db.insert('tham_gia_lop', {
        'id': 2,
        'id_hoc_sinh': 1,
        'id_lop': 1,
        'tu_ngay': '2026-09-20',
        'den_ngay': null,
        'created_at': now,
        'updated_at': now,
      });

      // Session 07/09 (Mon) -> INCLUDED
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
      // Session 14/09 (Mon) -> EXCLUDED
      await db.insert('buoi_hoc', {
        'id': 2,
        'id_lop': 1,
        'id_lich_hoc': 1,
        'ngay': '2026-09-14',
        'gio_bat_dau': '17:30',
        'gio_ket_thuc': '19:00',
        'loai': 'CHINH',
        'created_at': now,
        'updated_at': now,
      });
      // Session 21/09 (Mon) -> INCLUDED
      await db.insert('buoi_hoc', {
        'id': 3,
        'id_lop': 1,
        'id_lich_hoc': 1,
        'ngay': '2026-09-21',
        'gio_bat_dau': '17:30',
        'gio_ket_thuc': '19:00',
        'loai': 'CHINH',
        'created_at': now,
        'updated_at': now,
      });

      expect(
        (await rosterService.getRosterForSession(1)).participants.length,
        1,
      );
      expect(
        (await rosterService.getRosterForSession(2)).participants.length,
        0,
      );
      expect(
        (await rosterService.getRosterForSession(3)).participants.length,
        1,
      );
    });

    test('Valid assignment within membership regression', () async {
      await db.insert('lop', {
        'id': 1,
        'ten_lop': 'Multi',
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
        'ho_ten': 'S1',
        'created_at': now,
        'updated_at': now,
      });
      await db.insert('tham_gia_lop', {
        'id': 1,
        'id_hoc_sinh': 1,
        'id_lop': 1,
        'tu_ngay': '2026-09-01',
        'den_ngay': '2026-09-30',
        'created_at': now,
        'updated_at': now,
      });

      // Assignment: 05/09 -> 20/09
      await db.insert('phan_ca_hoc_sinh', {
        'id': 1,
        'id_hoc_sinh': 1,
        'id_lop': 1,
        'id_lich_hoc': 1,
        'tu_ngay': '2026-09-05',
        'den_ngay': '2026-09-20',
        'created_at': now,
        'updated_at': now,
      });

      // Session 14/09 -> INCLUDED
      await db.insert('buoi_hoc', {
        'id': 1,
        'id_lop': 1,
        'id_lich_hoc': 1,
        'ngay': '2026-09-14',
        'gio_bat_dau': '17:30',
        'gio_ket_thuc': '19:00',
        'loai': 'CHINH',
        'created_at': now,
        'updated_at': now,
      });

      final result = await rosterService.getRosterForSession(1);
      expect(result.participants.length, 1);
      expect(result.issues, isEmpty);
    });

    test('Archived class historical roster support', () async {
      await db.insert('lop', {
        'id': 1,
        'ten_lop': 'C',
        'da_luu_tru': 1, // Archived
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
        'tu_ngay': '2026-01-01',
        'created_at': now,
        'updated_at': now,
      });

      final result = await rosterService.getRosterForSession(10);
      expect(result.participants.length, 1);
    });

    test('HUY and NGHI_LE sessions retain rosters', () async {
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
        'trang_thai': 'HUY',
        'created_at': now,
        'updated_at': now,
      });
      await db.insert('buoi_hoc', {
        'id': 2,
        'id_lop': 1,
        'id_lich_hoc': 1,
        'ngay': '2026-09-14',
        'gio_bat_dau': '17:30',
        'gio_ket_thuc': '19:00',
        'loai': 'CHINH',
        'trang_thai': 'NGHI_LE',
        'created_at': now,
        'updated_at': now,
      });

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
        'tu_ngay': '2026-01-01',
        'created_at': now,
        'updated_at': now,
      });

      expect(
        (await rosterService.getRosterForSession(1)).participants.length,
        1,
      );
      expect(
        (await rosterService.getRosterForSession(2)).participants.length,
        1,
      );
    });

    test(
      'PHAT_SINH returns empty participants with adjustment requirement',
      () async {
        await db.insert('lop', {
          'id': 1,
          'ten_lop': 'C',
          'created_at': now,
          'updated_at': now,
        });
        await db.insert('buoi_hoc', {
          'id': 1,
          'id_lop': 1,
          'id_lich_hoc': null,
          'ngay': '2026-09-10',
          'gio_bat_dau': '08:00',
          'gio_ket_thuc': '10:00',
          'loai': 'PHAT_SINH',
          'created_at': now,
          'updated_at': now,
        });

        final result = await rosterService.getRosterForSession(1);
        expect(result.participants, isEmpty);
        expect(result.requiresOneOffAdjustments, isTrue);
      },
    );

    test(
      'Read purity: getRosterForSession does not mutate any core table',
      () async {
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
          'tu_ngay': '2026-01-01',
          'created_at': now,
          'updated_at': now,
        });

        final tables = [
          'buoi_hoc',
          'tham_gia_lop',
          'phan_ca_hoc_sinh',
          'lich_hoc',
          'hoc_sinh',
        ];
        final beforeStates = <String, List<Map<String, dynamic>>>{};
        for (final table in tables) {
          beforeStates[table] = await db.query(table);
        }

        await rosterService.getRosterForSession(1);
        await rosterService.getRosterForSession(1);

        for (final table in tables) {
          final afterState = await db.query(table);
          expect(
            afterState,
            beforeStates[table],
            reason: 'Table $table was mutated during read',
          );
        }
      },
    );
  });
}
