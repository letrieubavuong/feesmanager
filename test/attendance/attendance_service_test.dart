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
import 'package:tuition2027/features/leave/domain/leave_request_service.dart';
import 'package:tuition2027/features/leave/data/leave_request_repository.dart';
import 'package:tuition2027/features/session_adjustments/data/session_adjustment_repository.dart';
import '../sessions/test_db_helper_v6.dart';

import 'package:tuition2027/features/schedule_conflicts/data/schedule_constraint_repository.dart';
import 'package:tuition2027/features/schedule_conflicts/domain/schedule_conflict_service.dart';

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

    final sessionRepo = SessionRepository(db);
    final membershipRepo = MembershipRepository(db);
    final scheduleRepo = ScheduleRepository(db);
    final assignmentRepo = AssignmentRepository(db);
    final studentRepo = StudentRepository(db);
    final classRepo = ClassRepository(db);
    final leaveRepo = LeaveRequestRepository(db);
    final adjustmentRepo = SessionAdjustmentRepository(db);
    attendanceRepo = AttendanceRepository(db);

    membershipService = MembershipService(membershipRepo);
    classService = ClassService(classRepo, membershipService);
    studentService = StudentService(studentRepo, membershipService);
    sessionService = SessionService(sessionRepo, classService);

    final constraintRepo = ScheduleConstraintRepository(db);
    final conflictService = ScheduleConflictService(
      constraintRepo,
      scheduleRepo,
      assignmentRepo,
      sessionRepo,
      adjustmentRepo,
      classService,
    );

    scheduleService = ScheduleDomainService(
      scheduleRepo,
      assignmentRepo,
      membershipService,
      classService,
      studentService,
      conflictService,
    );
    rosterService = RosterService(
      sessionService,
      membershipService,
      scheduleService,
      studentService,
      adjustmentRepo,
    );

    final leaveService = LeaveRequestService(
      leaveRepo,
      studentService,
      classService,
      membershipService,
    );

    attendanceService = AttendanceService(
      attendanceRepo,
      rosterService,
      sessionService,
      leaveService,
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
        attendanceService.saveDraft(1, {}),
        throwsA(predicate((e) => e.toString().contains('chưa có danh sách'))),
      );

      await db.update('buoi_hoc', {'loai': 'PHAT_SINH'}, where: 'id = 1');
      expect(
        attendanceService.saveDraft(1, {}),
        throwsA(predicate((e) => e.toString().contains('chưa có danh sách'))),
      );
    });

    test(
      'finalizeSessionAttendance blocks HOC_BU and PHAT_SINH sessions',
      () async {
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
          attendanceService.finalizeSessionAttendance(1),
          throwsA(predicate((e) => e.toString().contains('chưa có danh sách'))),
        );

        var session = (await db.query('buoi_hoc', where: 'id = 1')).first;
        expect(session['trang_thai'], 'DU_KIEN');

        await db.update('buoi_hoc', {'loai': 'PHAT_SINH'}, where: 'id = 1');
        expect(
          attendanceService.finalizeSessionAttendance(1),
          throwsA(predicate((e) => e.toString().contains('chưa có danh sách'))),
        );

        session = (await db.query('buoi_hoc', where: 'id = 1')).first;
        expect(session['trang_thai'], 'DU_KIEN');
        expect(await db.query('diem_danh'), isEmpty);
      },
    );

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

    test('HUY and NGHI_LE sessions block save and finalize', () async {
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
        'trang_thai': 'HUY',
        'created_at': now,
        'updated_at': now,
      });

      expect(() => attendanceService.saveDraft(1, {}), throwsException);
      expect(
        () => attendanceService.finalizeSessionAttendance(1),
        throwsException,
      );

      await db.update('buoi_hoc', {'trang_thai': 'NGHI_LE'}, where: 'id = 1');
      expect(() => attendanceService.saveDraft(1, {}), throwsException);
      expect(
        () => attendanceService.finalizeSessionAttendance(1),
        throwsException,
      );
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
      expect(
        () => sessionService.updateStatus(1, SessionStatus.HUY),
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

    test(
      'No-edit finalize does not rewrite attendance rows or update timestamps',
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

        // Save initial attendance
        await attendanceService.saveDraft(1, {101: AttendanceState.CO_MAT});
        final rowBefore = (await db.query('diem_danh')).first;

        // Load sheet (no edit) and finalize
        await attendanceService.getAttendanceForSession(1);
        await attendanceService.finalizeSessionAttendance(1);

        final rowAfter = (await db.query('diem_danh')).first;
        expect(rowAfter['id'], rowBefore['id']);
        expect(rowAfter['created_at'], rowBefore['created_at']);
        expect(rowAfter['updated_at'], rowBefore['updated_at']);
        expect(rowAfter['trang_thai'], rowBefore['trang_thai']);
      },
    );

    test(
      'Incomplete finalize default rejects and explicit override preserves missing rows',
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

        // 1. Finalize without allowIncomplete -> throws
        expect(
          () => attendanceService.finalizeSessionAttendance(
            1,
            allowIncomplete: false,
          ),
          throwsA(predicate((e) => e.toString().contains('chưa điểm danh'))),
        );

        var rows = await db.query('diem_danh');
        expect(rows, isEmpty);
        var session = (await db.query('buoi_hoc', where: 'id = 1')).first;
        expect(session['trang_thai'], 'DU_KIEN');

        // 2. Finalize with allowIncomplete -> session becomes DA_HOC, missing row stays missing (no CO_MAT auto-created)
        await attendanceService.finalizeSessionAttendance(
          1,
          allowIncomplete: true,
        );
        rows = await db.query('diem_danh');
        expect(rows, isEmpty);

        session = (await db.query('buoi_hoc', where: 'id = 1')).first;
        expect(session['trang_thai'], 'DA_HOC');
        final sessionUpdatedAt = session['updated_at'];

        // 3. Finalize again -> safe no-op, session updated_at unchanged
        await attendanceService.finalizeSessionAttendance(
          1,
          allowIncomplete: true,
        );
        session = (await db.query('buoi_hoc', where: 'id = 1')).first;
        expect(session['trang_thai'], 'DA_HOC');
        expect(session['updated_at'], sessionUpdatedAt);
      },
    );

    test('Upsert created_at regression', () async {
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

      // 1. First save: CO_MAT
      await attendanceService.saveDraft(1, {101: AttendanceState.CO_MAT});

      var rows = await db.query('diem_danh');
      expect(rows.length, 1);
      expect(rows.first['trang_thai'], 'CO_MAT');

      final firstId = rows.first['id'];
      final createdAt = rows.first['created_at'];

      // 2. Save same student/session: TRE
      await attendanceService.saveDraft(1, {101: AttendanceState.TRE});

      rows = await db.query('diem_danh');
      expect(rows.length, 1);
      expect(rows.first['id'], firstId);
      expect(rows.first['trang_thai'], 'TRE');
      expect(rows.first['created_at'], createdAt);
    });
  });
}
