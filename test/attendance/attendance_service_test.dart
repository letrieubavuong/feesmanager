import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tuition2027/features/attendance/domain/attendance_service.dart';
import 'package:tuition2027/features/attendance/data/attendance_repository.dart';
import 'package:tuition2027/features/attendance/domain/attendance_state.dart';
import 'package:tuition2027/features/roster/domain/roster_service.dart';
import 'package:tuition2027/features/sessions/domain/session_service.dart';
import 'package:tuition2027/features/sessions/data/session_repository.dart';
import 'package:tuition2027/features/sessions/domain/class_session.dart';
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
  late AttendanceService attendanceService;
  late AttendanceRepository attendanceRepo;
  late RosterService rosterService;
  late SessionService sessionService;
  late MembershipService membershipService;
  late ScheduleDomainService scheduleService;
  late StudentService studentService;
  late ClassService classService;

  final now = DateTime.now().toIso8601String();

  setUp(() async {
    db = await TestDbHelperV6.createLatest();
    // Manual v7 migration for test
    await db.execute('''
      CREATE TABLE diem_danh (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        id_buoi_hoc INTEGER NOT NULL,
        id_hoc_sinh INTEGER NOT NULL,
        id_lop_goc INTEGER NOT NULL,
        trang_thai TEXT NOT NULL,
        loai_tham_gia TEXT NOT NULL DEFAULT 'CHINH',
        id_buoi_vang_goc INTEGER NULL,
        ghi_chu TEXT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (id_buoi_hoc) REFERENCES buoi_hoc (id),
        FOREIGN KEY (id_hoc_sinh) REFERENCES hoc_sinh (id),
        FOREIGN KEY (id_lop_goc) REFERENCES lop (id),
        FOREIGN KEY (id_buoi_vang_goc) REFERENCES buoi_hoc (id),
        UNIQUE(id_buoi_hoc, id_hoc_sinh),
        CHECK (trang_thai IN ('CO_MAT', 'TRE', 'NGHI_CO_PHEP', 'NGHI_KHONG_PHEP', 'HOC_BU')),
        CHECK (loai_tham_gia IN ('CHINH', 'DOI_CA', 'HOC_BU'))
      )
    ''');

    final sessionRepo = SessionRepository(db);
    final membershipRepo = MembershipRepository(db);
    final scheduleRepo = ScheduleRepository(db);
    final assignmentRepo = AssignmentRepository(db);
    final studentRepo = StudentRepository(db);
    final classRepo = ClassRepository(db);
    attendanceRepo = AttendanceRepository(db);

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

    attendanceService = AttendanceService(
      attendanceRepo,
      rosterService,
      sessionService,
    );
  });

  tearDown(() async => await db.close());

  group('AttendanceService Domain Tests', () {
    test(
      'getAttendanceForSession returns members with CHUA_DIEM_DANH by default',
      () async {
        await db.insert('lop', {
          'id': 1,
          'ten_lop': 'C1',
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
          'ngay': '2026-09-21',
          'gio_bat_dau': '17:30',
          'gio_ket_thuc': '19:00',
          'loai': 'CHINH',
          'created_at': now,
          'updated_at': now,
        });
        await db.insert('hoc_sinh', {
          'id': 101,
          'ho_ten': 'Student A',
          'created_at': now,
          'updated_at': now,
        });
        await db.insert('tham_gia_lop', {
          'id': 1,
          'id_hoc_sinh': 101,
          'id_lop': 1,
          'tu_ngay': '2026-01-01',
          'created_at': now,
          'updated_at': now,
        });

        final sheet = await attendanceService.getAttendanceForSession(1);
        expect(sheet.members.length, 1);
        expect(sheet.members.first.rosterMember.student.hoTen, 'Student A');
        expect(sheet.members.first.state, AttendanceState.CHUA_DIEM_DANH);
        expect(sheet.isComplete, isFalse);
      },
    );

    test(
      'saveDraft persists attendance and clear to CHUA deletes row',
      () async {
        await db.insert('lop', {
          'id': 1,
          'ten_lop': 'C1',
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
          'ngay': '2026-09-21',
          'gio_bat_dau': '17:30',
          'gio_ket_thuc': '19:00',
          'loai': 'CHINH',
          'created_at': now,
          'updated_at': now,
        });
        await db.insert('hoc_sinh', {
          'id': 101,
          'ho_ten': 'Student A',
          'created_at': now,
          'updated_at': now,
        });
        await db.insert('tham_gia_lop', {
          'id': 1,
          'id_hoc_sinh': 101,
          'id_lop': 1,
          'tu_ngay': '2026-01-01',
          'created_at': now,
          'updated_at': now,
        });

        // 1. Mark CO_MAT
        await attendanceService.saveDraft(1, {101: AttendanceState.CO_MAT});

        var row = await db.query(
          'diem_danh',
          where: 'id_buoi_hoc = 1 AND id_hoc_sinh = 101',
        );
        expect(row.length, 1);
        expect(row.first['trang_thai'], 'CO_MAT');

        // 2. Clear to CHUA_DIEM_DANH
        await attendanceService.saveDraft(1, {
          101: AttendanceState.CHUA_DIEM_DANH,
        });
        row = await db.query(
          'diem_danh',
          where: 'id_buoi_hoc = 1 AND id_hoc_sinh = 101',
        );
        expect(row.length, 0);
      },
    );

    test('saveDraft blocks when attendance outside roster exists', () async {
      await db.insert('lop', {
        'id': 1,
        'ten_lop': 'C1',
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
        'ngay': '2026-09-21',
        'gio_bat_dau': '17:30',
        'gio_ket_thuc': '19:00',
        'loai': 'CHINH',
        'created_at': now,
        'updated_at': now,
      });
      await db.insert('hoc_sinh', {
        'id': 101,
        'ho_ten': 'Student A',
        'created_at': now,
        'updated_at': now,
      });
      await db.insert('tham_gia_lop', {
        'id': 1,
        'id_hoc_sinh': 101,
        'id_lop': 1,
        'tu_ngay': '2026-01-01',
        'created_at': now,
        'updated_at': now,
      });

      // Inject row for non-roster student
      await db.insert('hoc_sinh', {
        'id': 999,
        'ho_ten': 'Stranger',
        'created_at': now,
        'updated_at': now,
      });
      await db.insert('diem_danh', {
        'id_buoi_hoc': 1,
        'id_hoc_sinh': 999,
        'id_lop_goc': 1,
        'trang_thai': 'CO_MAT',
        'loai_tham_gia': 'CHINH',
        'created_at': now,
        'updated_at': now,
      });

      // Saving should be blocked because of corruption
      expect(
        () => attendanceService.saveDraft(1, {101: AttendanceState.CO_MAT}),
        throwsA(predicate((e) => e.toString().contains('không hợp lệ'))),
      );
    });

    test('saveDraft blocks HOC_BU/PHAT_SINH sessions in Phase 6', () async {
      await db.insert('lop', {
        'id': 1,
        'ten_lop': 'C1',
        'created_at': now,
        'updated_at': now,
      });
      await db.insert('buoi_hoc', {
        'id': 1,
        'id_lop': 1,
        'ngay': '2026-09-21',
        'gio_bat_dau': '17:30',
        'gio_ket_thuc': '19:00',
        'loai': 'HOC_BU',
        'created_at': now,
        'updated_at': now,
      });

      expect(
        () => attendanceService.saveDraft(1, {}),
        throwsA(predicate((e) => e.toString().contains('Phase 6'))),
      );
    });

    test(
      'finalizeSessionAttendance changes session status to DA_HOC',
      () async {
        await db.insert('lop', {
          'id': 1,
          'ten_lop': 'C1',
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
          'ngay': '2026-09-21',
          'gio_bat_dau': '17:30',
          'gio_ket_thuc': '19:00',
          'loai': 'CHINH',
          'created_at': now,
          'updated_at': now,
        });
        await db.insert('hoc_sinh', {
          'id': 101,
          'ho_ten': 'Student A',
          'created_at': now,
          'updated_at': now,
        });
        await db.insert('tham_gia_lop', {
          'id': 1,
          'id_hoc_sinh': 101,
          'id_lop': 1,
          'tu_ngay': '2026-01-01',
          'created_at': now,
          'updated_at': now,
        });

        await attendanceService.saveDraft(1, {101: AttendanceState.CO_MAT});
        await attendanceService.finalizeSessionAttendance(1);

        final session = await db.query('buoi_hoc', where: 'id = 1');
        expect(session.first['trang_thai'], 'DA_HOC');
      },
    );

    test('finalizeSessionAttendance is idempotent', () async {
      await db.insert('lop', {
        'id': 1,
        'ten_lop': 'C1',
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
        'ngay': '2026-09-21',
        'gio_bat_dau': '17:30',
        'gio_ket_thuc': '19:00',
        'loai': 'CHINH',
        'created_at': now,
        'updated_at': now,
      });
      await db.insert('hoc_sinh', {
        'id': 101,
        'ho_ten': 'Student A',
        'created_at': now,
        'updated_at': now,
      });
      await db.insert('tham_gia_lop', {
        'id': 1,
        'id_hoc_sinh': 101,
        'id_lop': 1,
        'tu_ngay': '2026-01-01',
        'created_at': now,
        'updated_at': now,
      });

      await attendanceService.saveDraft(1, {101: AttendanceState.CO_MAT});
      await attendanceService.finalizeSessionAttendance(1);
      final updatedAt = (await db.query(
        'buoi_hoc',
        where: 'id = 1',
      )).first['updated_at'];

      // Call again
      await attendanceService.finalizeSessionAttendance(1);
      final updatedAtAfter = (await db.query(
        'buoi_hoc',
        where: 'id = 1',
      )).first['updated_at'];

      expect(updatedAtAfter, updatedAt);
    });

    test('DA_HOC session is protected from generic status updates', () async {
      await db.insert('lop', {
        'id': 1,
        'ten_lop': 'C1',
        'created_at': now,
        'updated_at': now,
      });
      await db.insert('buoi_hoc', {
        'id': 1,
        'id_lop': 1,
        'ngay': '2026-09-21',
        'gio_bat_dau': '17:30',
        'gio_ket_thuc': '19:00',
        'loai': 'CHINH',
        'trang_thai': 'DA_HOC',
        'created_at': now,
        'updated_at': now,
      });

      expect(
        () => sessionService.updateStatus(1, SessionStatus.DU_KIEN),
        throwsA(predicate((e) => e.toString().contains('đã hoàn tất'))),
      );
    });

    test('Read purity: getAttendanceForSession does not mutate DB', () async {
      await db.insert('lop', {
        'id': 1,
        'ten_lop': 'C1',
        'created_at': now,
        'updated_at': now,
      });
      await db.insert('buoi_hoc', {
        'id': 1,
        'id_lop': 1,
        'ngay': '2026-09-21',
        'gio_bat_dau': '17:30',
        'gio_ket_thuc': '19:00',
        'loai': 'CHINH',
        'created_at': now,
        'updated_at': now,
      });

      final tables = [
        'buoi_hoc',
        'tham_gia_lop',
        'phan_ca_hoc_sinh',
        'lich_hoc',
        'hoc_sinh',
        'diem_danh',
      ];
      final beforeStates = <String, List<Map<String, dynamic>>>{};
      for (final table in tables) {
        beforeStates[table] = await db.query(table);
      }

      await attendanceService.getAttendanceForSession(1);
      await attendanceService.getAttendanceForSession(1);

      for (final table in tables) {
        expect(await db.query(table), beforeStates[table]);
      }
    });

    test('Upsert preserves created_at', () async {
      await db.insert('lop', {
        'id': 1,
        'ten_lop': 'C1',
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
        'ngay': '2026-09-21',
        'gio_bat_dau': '17:30',
        'gio_ket_thuc': '19:00',
        'loai': 'CHINH',
        'created_at': now,
        'updated_at': now,
      });
      await db.insert('hoc_sinh', {
        'id': 1,
        'ho_ten': 'S',
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

      await attendanceService.saveDraft(1, {1: AttendanceState.CO_MAT});
      final createdAt =
          (await db.query('diem_danh')).first['created_at'] as String;

      // Update after some time
      await attendanceService.saveDraft(1, {1: AttendanceState.TRE});
      final rowAfter = (await db.query('diem_danh')).first;
      expect(rowAfter['created_at'], createdAt);
      expect(rowAfter['trang_thai'], 'TRE');
    });
  });
}
