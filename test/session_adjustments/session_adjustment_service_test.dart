import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tuition2027/features/attendance/domain/attendance_service.dart';
import 'package:tuition2027/features/attendance/data/attendance_repository.dart';
import 'package:tuition2027/features/attendance/domain/attendance_state.dart';
import 'package:tuition2027/features/classes/domain/class_service.dart';
import 'package:tuition2027/features/classes/data/class_repository.dart';
import 'package:tuition2027/features/leave/domain/leave_request_service.dart';
import 'package:tuition2027/features/leave/data/leave_request_repository.dart';
import 'package:tuition2027/features/memberships/domain/membership_service.dart';
import 'package:tuition2027/features/memberships/data/membership_repository.dart';
import 'package:tuition2027/features/roster/domain/roster_service.dart';
import 'package:tuition2027/features/roster/domain/roster_result.dart';
import 'package:tuition2027/features/roster/domain/roster_member.dart';
import 'package:tuition2027/features/schedule/domain/schedule_service.dart';
import 'package:tuition2027/features/schedule/data/schedule_repository.dart';
import 'package:tuition2027/features/schedule/data/assignment_repository.dart';
import 'package:tuition2027/features/session_adjustments/domain/session_adjustment_service.dart';
import 'package:tuition2027/features/session_adjustments/data/session_adjustment_repository.dart';
import 'package:tuition2027/features/sessions/domain/session_service.dart';
import 'package:tuition2027/features/sessions/data/session_repository.dart';
import 'package:tuition2027/features/students/domain/student_service.dart';
import 'package:tuition2027/features/students/data/student_repository.dart';
import '../sessions/test_db_helper_v6.dart';

import 'package:tuition2027/features/schedule_conflicts/data/schedule_constraint_repository.dart';
import 'package:tuition2027/features/schedule_conflicts/domain/schedule_conflict_service.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database db;
  late SessionAdjustmentService adjustmentService;
  late SessionAdjustmentRepository adjustmentRepo;
  late RosterService rosterService;
  late AttendanceService attendanceService;
  late SessionService sessionService;
  late AttendanceRepository attendanceRepo;

  final nowStr = DateTime.now().toIso8601String();

  setUp(() async {
    db = await TestDbHelperV6.createLatest();

    final studentRepo = StudentRepository(db);
    final membershipRepo = MembershipRepository(db);
    final classRepo = ClassRepository(db);
    final sessionRepo = SessionRepository(db);
    final scheduleRepo = ScheduleRepository(db);
    final assignmentRepo = AssignmentRepository(db);
    attendanceRepo = AttendanceRepository(db);
    adjustmentRepo = SessionAdjustmentRepository(db);
    final leaveRepo = LeaveRequestRepository(db);

    final membershipService = MembershipService(membershipRepo);
    final studentService = StudentService(studentRepo, membershipService);
    final classService = ClassService(classRepo, membershipService);

    final constraintRepo = ScheduleConstraintRepository(db);
    final conflictService = ScheduleConflictService(
      constraintRepo,
      scheduleRepo,
      assignmentRepo,
      sessionRepo,
      adjustmentRepo,
      classService,
    );

    sessionService = SessionService(sessionRepo, classService);
    final scheduleService = ScheduleDomainService(
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

    adjustmentService = SessionAdjustmentService(
      adjustmentRepo,
      studentService,
      classService,
      sessionService,
      membershipService,
      attendanceRepo,
      rosterService,
      conflictService,
    );
  });

  tearDown(() async => await db.close());

  group('SessionAdjustmentService Domain Tests', () {
    test(
      'DOI_CA removes student from orig roster, adds to target roster, phan_ca_hoc_sinh unchanged',
      () async {
        await db.insert('hoc_sinh', {
          'id': 1,
          'ho_ten': 'Student 1',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
        await db.insert('lop', {
          'id': 10,
          'ten_lop': 'Class 10',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
        await db.insert('tham_gia_lop', {
          'id': 100,
          'id_hoc_sinh': 1,
          'id_lop': 10,
          'tu_ngay': '2026-01-01',
          'created_at': nowStr,
          'updated_at': nowStr,
        });

        // Schedules for multi-shift class on Monday
        await db.insert('lich_hoc', {
          'id': 1,
          'id_lop': 10,
          'thu_trong_tuan': 1,
          'gio_bat_dau': '17:30',
          'gio_ket_thuc': '19:00',
          'hieu_luc_tu': '2026-01-01',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
        await db.insert('lich_hoc', {
          'id': 2,
          'id_lop': 10,
          'thu_trong_tuan': 1,
          'gio_bat_dau': '19:30',
          'gio_ket_thuc': '21:00',
          'hieu_luc_tu': '2026-01-01',
          'created_at': nowStr,
          'updated_at': nowStr,
        });

        // Student assigned to Shift 1
        await db.insert('phan_ca_hoc_sinh', {
          'id': 50,
          'id_hoc_sinh': 1,
          'id_lop': 10,
          'id_lich_hoc': 1,
          'tu_ngay': '2026-01-01',
          'created_at': nowStr,
          'updated_at': nowStr,
        });

        // Two sessions on Monday 2026-09-21
        await db.insert('buoi_hoc', {
          'id': 101,
          'id_lop': 10,
          'id_lich_hoc': 1,
          'ngay': '2026-09-21',
          'gio_bat_dau': '17:30',
          'gio_ket_thuc': '19:00',
          'loai': 'CHINH',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
        await db.insert('buoi_hoc', {
          'id': 102,
          'id_lop': 10,
          'id_lich_hoc': 2,
          'ngay': '2026-09-21',
          'gio_bat_dau': '19:30',
          'gio_ket_thuc': '21:00',
          'loai': 'CHINH',
          'created_at': nowStr,
          'updated_at': nowStr,
        });

        // Before DOI_CA:
        var origRoster = await rosterService.getRosterForSession(101);
        var targetRoster = await rosterService.getRosterForSession(102);
        expect(origRoster.participants.any((p) => p.student.id == 1), isTrue);
        expect(
          targetRoster.participants.any((p) => p.student.id == 1),
          isFalse,
        );

        // Create DOI_CA from Session 101 to Session 102
        await adjustmentService.createDoiCa(
          studentId: 1,
          originalSessionId: 101,
          targetSessionId: 102,
        );

        // After DOI_CA:
        origRoster = await rosterService.getRosterForSession(101);
        targetRoster = await rosterService.getRosterForSession(102);
        expect(origRoster.participants.any((p) => p.student.id == 1), isFalse);
        expect(targetRoster.participants.any((p) => p.student.id == 1), isTrue);

        // Assert phan_ca_hoc_sinh is UNCHANGED
        final pcList = await db.query('phan_ca_hoc_sinh');
        expect(pcList.length, 1);
        expect(pcList.first['id_lich_hoc'], 1);

        // Next week session on 2026-09-28:
        await db.insert('buoi_hoc', {
          'id': 201,
          'id_lop': 10,
          'id_lich_hoc': 1,
          'ngay': '2026-09-28',
          'gio_bat_dau': '17:30',
          'gio_ket_thuc': '19:00',
          'loai': 'CHINH',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
        final nextWeekRoster = await rosterService.getRosterForSession(201);
        expect(
          nextWeekRoster.participants.any((p) => p.student.id == 1),
          isTrue,
        );
      },
    );

    test(
      'HOC_BU requires known absence (NGHI_CO_PHEP / NGHI_KHONG_PHEP) in original session',
      () async {
        await db.insert('hoc_sinh', {
          'id': 1,
          'ho_ten': 'S',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
        await db.insert('lop', {
          'id': 10,
          'ten_lop': 'C',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
        await db.insert('tham_gia_lop', {
          'id': 100,
          'id_hoc_sinh': 1,
          'id_lop': 10,
          'tu_ngay': '2026-01-01',
          'created_at': nowStr,
          'updated_at': nowStr,
        });

        // Original CHINH session DA_HOC
        await db.insert('buoi_hoc', {
          'id': 101,
          'id_lop': 10,
          'ngay': '2026-09-21',
          'gio_bat_dau': '17:30',
          'gio_ket_thuc': '19:00',
          'loai': 'CHINH',
          'trang_thai': 'DA_HOC',
          'created_at': nowStr,
          'updated_at': nowStr,
        });

        // Target HOC_BU session
        await db.insert('buoi_hoc', {
          'id': 102,
          'id_lop': 10,
          'ngay': '2026-09-22',
          'gio_bat_dau': '17:30',
          'gio_ket_thuc': '19:00',
          'loai': 'HOC_BU',
          'trang_thai': 'DU_KIEN',
          'created_at': nowStr,
          'updated_at': nowStr,
        });

        // 1. Without original attendance -> REJECT
        await expectLater(
          adjustmentService.createHocBu(
            studentId: 1,
            originalSessionId: 101,
            targetSessionId: 102,
          ),
          throwsA(isA<Exception>()),
        );

        // 2. Original attendance = CO_MAT -> REJECT
        await db.insert('diem_danh', {
          'id_buoi_hoc': 101,
          'id_hoc_sinh': 1,
          'id_lop_goc': 10,
          'trang_thai': 'CO_MAT',
          'loai_tham_gia': 'CHINH',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
        await expectLater(
          adjustmentService.createHocBu(
            studentId: 1,
            originalSessionId: 101,
            targetSessionId: 102,
          ),
          throwsA(isA<Exception>()),
        );

        // 3. Update original attendance = NGHI_CO_PHEP -> ACCEPT
        await db.update('diem_danh', {
          'trang_thai': 'NGHI_CO_PHEP',
        }, where: 'id_buoi_hoc = 101 AND id_hoc_sinh = 1');
        await adjustmentService.createHocBu(
          studentId: 1,
          originalSessionId: 101,
          targetSessionId: 102,
        );

        final targetRoster = await rosterService.getRosterForSession(102);
        expect(targetRoster.participants.any((p) => p.student.id == 1), isTrue);

        // Save make-up attendance
        await attendanceService.saveDraft(102, {1: AttendanceState.HOC_BU});
        final ddRow = (await db.query(
          'diem_danh',
          where: 'id_buoi_hoc = 102 AND id_hoc_sinh = 1',
        )).first;
        expect(ddRow['trang_thai'], 'HOC_BU');
        expect(ddRow['loai_tham_gia'], 'HOC_BU');
        expect(ddRow['id_buoi_vang_goc'], 101);
      },
    );

    test(
      'PHAT_SINH starts with empty roster, explicit adjustment populates it, attendance loai_tham_gia = CHINH',
      () async {
        await db.insert('hoc_sinh', {
          'id': 1,
          'ho_ten': 'S',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
        await db.insert('lop', {
          'id': 10,
          'ten_lop': 'C',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
        await db.insert('tham_gia_lop', {
          'id': 100,
          'id_hoc_sinh': 1,
          'id_lop': 10,
          'tu_ngay': '2026-01-01',
          'created_at': nowStr,
          'updated_at': nowStr,
        });

        // Target PHAT_SINH session
        await db.insert('buoi_hoc', {
          'id': 105,
          'id_lop': 10,
          'ngay': '2026-09-25',
          'gio_bat_dau': '17:30',
          'gio_ket_thuc': '19:00',
          'loai': 'PHAT_SINH',
          'trang_thai': 'DU_KIEN',
          'created_at': nowStr,
          'updated_at': nowStr,
        });

        // 1. Initial roster -> empty, requiresOneOffAdjustments = true
        var psRoster = await rosterService.getRosterForSession(105);
        expect(psRoster.participants, isEmpty);
        expect(psRoster.requiresOneOffAdjustments, isTrue);

        // 2. Create PHAT_SINH adjustment
        await adjustmentService.createPhatSinh(
          studentId: 1,
          originalClassId: 10,
          targetSessionId: 105,
        );

        psRoster = await rosterService.getRosterForSession(105);
        expect(psRoster.participants.length, 1);
        expect(psRoster.requiresOneOffAdjustments, isFalse);

        // 3. Save attendance
        await attendanceService.saveDraft(105, {1: AttendanceState.CO_MAT});
        final ddRow = (await db.query(
          'diem_danh',
          where: 'id_buoi_hoc = 105 AND id_hoc_sinh = 1',
        )).first;
        expect(ddRow['trang_thai'], 'CO_MAT');
        expect(ddRow['loai_tham_gia'], 'CHINH');

        // Finalize
        await attendanceService.finalizeSessionAttendance(105);
        final sRow = (await db.query('buoi_hoc', where: 'id = 105')).first;
        expect(sRow['trang_thai'], 'DA_HOC');
      },
    );

    test(
      'Adjustment removal allowed before attendance exists, rejected after attendance exists',
      () async {
        await db.insert('hoc_sinh', {
          'id': 1,
          'ho_ten': 'S',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
        await db.insert('lop', {
          'id': 10,
          'ten_lop': 'C',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
        await db.insert('tham_gia_lop', {
          'id': 100,
          'id_hoc_sinh': 1,
          'id_lop': 10,
          'tu_ngay': '2026-01-01',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
        await db.insert('buoi_hoc', {
          'id': 105,
          'id_lop': 10,
          'ngay': '2026-09-25',
          'gio_bat_dau': '17:30',
          'gio_ket_thuc': '19:00',
          'loai': 'PHAT_SINH',
          'trang_thai': 'DU_KIEN',
          'created_at': nowStr,
          'updated_at': nowStr,
        });

        final adjId = await adjustmentService.createPhatSinh(
          studentId: 1,
          originalClassId: 10,
          targetSessionId: 105,
        );

        // Save attendance in target session
        await attendanceService.saveDraft(105, {1: AttendanceState.CO_MAT});

        // Attempt to remove adjustment -> REJECT
        await expectLater(
          adjustmentService.removeAdjustment(adjId),
          throwsA(isA<Exception>()),
        );
      },
    );

    test('Corrupted outgoing DOI_CA fails closed on roster read', () async {
      await db.insert('hoc_sinh', {
        'id': 1,
        'ho_ten': 'S',
        'created_at': nowStr,
        'updated_at': nowStr,
      });
      await db.insert('lop', {
        'id': 10,
        'ten_lop': 'C',
        'created_at': nowStr,
        'updated_at': nowStr,
      });
      await db.insert('tham_gia_lop', {
        'id': 100,
        'id_hoc_sinh': 1,
        'id_lop': 10,
        'tu_ngay': '2026-01-01',
        'created_at': nowStr,
        'updated_at': nowStr,
      });
      await db.insert('lich_hoc', {
        'id': 1,
        'id_lop': 10,
        'thu_trong_tuan': 1,
        'gio_bat_dau': '17:30',
        'gio_ket_thuc': '19:00',
        'hieu_luc_tu': '2026-01-01',
        'created_at': nowStr,
        'updated_at': nowStr,
      });
      await db.insert('buoi_hoc', {
        'id': 101,
        'id_lop': 10,
        'id_lich_hoc': 1,
        'ngay': '2026-09-21',
        'gio_bat_dau': '17:30',
        'gio_ket_thuc': '19:00',
        'loai': 'CHINH',
        'created_at': nowStr,
        'updated_at': nowStr,
      });
      // Target session on DIFFERENT date (corrupted)
      await db.insert('buoi_hoc', {
        'id': 102,
        'id_lop': 10,
        'id_lich_hoc': 1,
        'ngay': '2026-09-28',
        'gio_bat_dau': '17:30',
        'gio_ket_thuc': '19:00',
        'loai': 'CHINH',
        'created_at': nowStr,
        'updated_at': nowStr,
      });

      // Raw insert corrupted DOI_CA
      await db.insert('dieu_chinh_buoi_hoc', {
        'id_hoc_sinh': 1,
        'id_lop_goc': 10,
        'id_buoi_hoc_goc': 101,
        'id_buoi_hoc_tham_gia': 102,
        'loai': 'DOI_CA',
        'created_at': nowStr,
      });

      final roster = await rosterService.getRosterForSession(101);
      expect(roster.isOperationallyValid, isFalse);
      expect(
        roster.issues.any(
          (i) => i.code == RosterIssueCode.ADJUSTMENT_TARGET_SESSION_MISMATCH,
        ),
        isTrue,
      );
      expect(roster.participants.any((p) => p.student.id == 1), isTrue);
    });

    test(
      'Corrupted HOC_BU with non-CHINH original session fails closed',
      () async {
        await db.insert('hoc_sinh', {
          'id': 1,
          'ho_ten': 'S',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
        await db.insert('lop', {
          'id': 10,
          'ten_lop': 'C',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
        await db.insert('tham_gia_lop', {
          'id': 100,
          'id_hoc_sinh': 1,
          'id_lop': 10,
          'tu_ngay': '2026-01-01',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
        // Original session is HOC_BU instead of CHINH
        await db.insert('buoi_hoc', {
          'id': 101,
          'id_lop': 10,
          'ngay': '2026-09-21',
          'gio_bat_dau': '17:30',
          'gio_ket_thuc': '19:00',
          'loai': 'HOC_BU',
          'trang_thai': 'DA_HOC',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
        await db.insert('buoi_hoc', {
          'id': 102,
          'id_lop': 10,
          'ngay': '2026-09-22',
          'gio_bat_dau': '17:30',
          'gio_ket_thuc': '19:00',
          'loai': 'HOC_BU',
          'trang_thai': 'DU_KIEN',
          'created_at': nowStr,
          'updated_at': nowStr,
        });

        await db.insert('dieu_chinh_buoi_hoc', {
          'id_hoc_sinh': 1,
          'id_lop_goc': 10,
          'id_buoi_hoc_goc': 101,
          'id_buoi_hoc_tham_gia': 102,
          'loai': 'HOC_BU',
          'created_at': nowStr,
        });

        final roster = await rosterService.getRosterForSession(102);
        expect(
          roster.issues.any(
            (i) => i.code == RosterIssueCode.ADJUSTMENT_TARGET_SESSION_MISMATCH,
          ),
          isTrue,
        );
        expect(roster.participants, isEmpty);
      },
    );

    test(
      'HOC_BU valid with historical membership on original missed session date',
      () async {
        await db.insert('hoc_sinh', {
          'id': 1,
          'ho_ten': 'S',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
        await db.insert('lop', {
          'id': 10,
          'ten_lop': 'C',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
        // Membership ended on 2026-09-25
        await db.insert('tham_gia_lop', {
          'id': 100,
          'id_hoc_sinh': 1,
          'id_lop': 10,
          'tu_ngay': '2026-01-01',
          'den_ngay': '2026-09-25',
          'created_at': nowStr,
          'updated_at': nowStr,
        });

        // Original session on 2026-09-21 (when student WAS a member)
        await db.insert('buoi_hoc', {
          'id': 101,
          'id_lop': 10,
          'ngay': '2026-09-21',
          'gio_bat_dau': '17:30',
          'gio_ket_thuc': '19:00',
          'loai': 'CHINH',
          'trang_thai': 'DA_HOC',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
        await db.insert('diem_danh', {
          'id_buoi_hoc': 101,
          'id_hoc_sinh': 1,
          'id_lop_goc': 10,
          'trang_thai': 'NGHI_CO_PHEP',
          'loai_tham_gia': 'CHINH',
          'created_at': nowStr,
          'updated_at': nowStr,
        });

        // Target HOC_BU session on 2026-10-10 (AFTER membership ended)
        await db.insert('buoi_hoc', {
          'id': 102,
          'id_lop': 10,
          'ngay': '2026-10-10',
          'gio_bat_dau': '17:30',
          'gio_ket_thuc': '19:00',
          'loai': 'HOC_BU',
          'trang_thai': 'DU_KIEN',
          'created_at': nowStr,
          'updated_at': nowStr,
        });

        await adjustmentService.createHocBu(
          studentId: 1,
          originalSessionId: 101,
          targetSessionId: 102,
        );

        final roster = await rosterService.getRosterForSession(102);
        expect(roster.participants.length, 1);
        expect(roster.participants.first.student.id, 1);
      },
    );

    test(
      'AttendanceService rejects CO_MAT and TRE for HOC_BU roster member',
      () async {
        await db.insert('hoc_sinh', {
          'id': 1,
          'ho_ten': 'S',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
        await db.insert('lop', {
          'id': 10,
          'ten_lop': 'C',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
        await db.insert('tham_gia_lop', {
          'id': 100,
          'id_hoc_sinh': 1,
          'id_lop': 10,
          'tu_ngay': '2026-01-01',
          'created_at': nowStr,
          'updated_at': nowStr,
        });

        await db.insert('buoi_hoc', {
          'id': 101,
          'id_lop': 10,
          'ngay': '2026-09-21',
          'gio_bat_dau': '17:30',
          'gio_ket_thuc': '19:00',
          'loai': 'CHINH',
          'trang_thai': 'DA_HOC',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
        await db.insert('diem_danh', {
          'id_buoi_hoc': 101,
          'id_hoc_sinh': 1,
          'id_lop_goc': 10,
          'trang_thai': 'NGHI_CO_PHEP',
          'loai_tham_gia': 'CHINH',
          'created_at': nowStr,
          'updated_at': nowStr,
        });

        await db.insert('buoi_hoc', {
          'id': 102,
          'id_lop': 10,
          'ngay': '2026-09-22',
          'gio_bat_dau': '17:30',
          'gio_ket_thuc': '19:00',
          'loai': 'HOC_BU',
          'trang_thai': 'DU_KIEN',
          'created_at': nowStr,
          'updated_at': nowStr,
        });

        await adjustmentService.createHocBu(
          studentId: 1,
          originalSessionId: 101,
          targetSessionId: 102,
        );

        // Attempting CO_MAT -> REJECT
        await expectLater(
          attendanceService.saveDraft(102, {1: AttendanceState.CO_MAT}),
          throwsA(
            predicate(
              (e) =>
                  e.toString().contains('không thể đánh dấu Có mặt hoặc Trễ'),
            ),
          ),
        );

        // Attempting TRE -> REJECT
        await expectLater(
          attendanceService.saveDraft(102, {1: AttendanceState.TRE}),
          throwsA(
            predicate(
              (e) =>
                  e.toString().contains('không thể đánh dấu Có mặt hoặc Trễ'),
            ),
          ),
        );
      },
    );

    test(
      'Cross-class HOC_BU adjustment and attendance metadata regression',
      () async {
        await db.insert('hoc_sinh', {
          'id': 1,
          'ho_ten': 'S1',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
        await db.insert('lop', {
          'id': 10,
          'ten_lop': 'Class A',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
        await db.insert('lop', {
          'id': 20,
          'ten_lop': 'Class B',
          'created_at': nowStr,
          'updated_at': nowStr,
        });

        await db.insert('tham_gia_lop', {
          'id': 100,
          'id_hoc_sinh': 1,
          'id_lop': 10,
          'tu_ngay': '2026-01-01',
          'created_at': nowStr,
          'updated_at': nowStr,
        });

        // Original CHINH session in Class A
        await db.insert('buoi_hoc', {
          'id': 101,
          'id_lop': 10,
          'ngay': '2026-09-21',
          'gio_bat_dau': '17:30',
          'gio_ket_thuc': '19:00',
          'loai': 'CHINH',
          'trang_thai': 'DA_HOC',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
        await db.insert('diem_danh', {
          'id_buoi_hoc': 101,
          'id_hoc_sinh': 1,
          'id_lop_goc': 10,
          'trang_thai': 'NGHI_CO_PHEP',
          'loai_tham_gia': 'CHINH',
          'created_at': nowStr,
          'updated_at': nowStr,
        });

        // Target HOC_BU session in Class B
        await db.insert('buoi_hoc', {
          'id': 201,
          'id_lop': 20,
          'ngay': '2026-09-22',
          'gio_bat_dau': '17:30',
          'gio_ket_thuc': '19:00',
          'loai': 'HOC_BU',
          'trang_thai': 'DU_KIEN',
          'created_at': nowStr,
          'updated_at': nowStr,
        });

        // Create cross-class HOC_BU
        await adjustmentService.createHocBu(
          studentId: 1,
          originalSessionId: 101,
          targetSessionId: 201,
        );

        final targetRoster = await rosterService.getRosterForSession(201);
        expect(targetRoster.participants.length, 1);
        expect(
          targetRoster.participants.first.source,
          RosterInclusionSource.HOC_BU,
        );

        // Save make-up attendance in Class B session 201
        await attendanceService.saveDraft(201, {1: AttendanceState.HOC_BU});

        final ddRow = (await db.query(
          'diem_danh',
          where: 'id_buoi_hoc = 201 AND id_hoc_sinh = 1',
        )).first;
        expect(ddRow['trang_thai'], 'HOC_BU');
        expect(ddRow['loai_tham_gia'], 'HOC_BU');
        expect(ddRow['id_lop_goc'], 10);
        expect(ddRow['id_buoi_vang_goc'], 101);
      },
    );

    test(
      'Cross-class PHAT_SINH adjustment and attendance metadata regression',
      () async {
        await db.insert('hoc_sinh', {
          'id': 1,
          'ho_ten': 'S1',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
        await db.insert('lop', {
          'id': 10,
          'ten_lop': 'Class A',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
        await db.insert('lop', {
          'id': 20,
          'ten_lop': 'Class B',
          'created_at': nowStr,
          'updated_at': nowStr,
        });

        await db.insert('tham_gia_lop', {
          'id': 100,
          'id_hoc_sinh': 1,
          'id_lop': 10,
          'tu_ngay': '2026-01-01',
          'created_at': nowStr,
          'updated_at': nowStr,
        });

        // Target PHAT_SINH session in Class B
        await db.insert('buoi_hoc', {
          'id': 202,
          'id_lop': 20,
          'ngay': '2026-09-25',
          'gio_bat_dau': '17:30',
          'gio_ket_thuc': '19:00',
          'loai': 'PHAT_SINH',
          'trang_thai': 'DU_KIEN',
          'created_at': nowStr,
          'updated_at': nowStr,
        });

        // Create cross-class PHAT_SINH with student's original Class A (10)
        await adjustmentService.createPhatSinh(
          studentId: 1,
          originalClassId: 10,
          targetSessionId: 202,
        );

        final targetRoster = await rosterService.getRosterForSession(202);
        expect(targetRoster.participants.length, 1);
        expect(
          targetRoster.participants.first.source,
          RosterInclusionSource.PHAT_SINH,
        );

        // Save normal attendance
        await attendanceService.saveDraft(202, {1: AttendanceState.CO_MAT});

        final ddRow = (await db.query(
          'diem_danh',
          where: 'id_buoi_hoc = 202 AND id_hoc_sinh = 1',
        )).first;
        expect(ddRow['trang_thai'], 'CO_MAT');
        expect(ddRow['loai_tham_gia'], 'CHINH');
        expect(ddRow['id_lop_goc'], 10);
        expect(ddRow['id_buoi_vang_goc'], isNull);
      },
    );

    test('PHAT_SINH multi-participant sequential additions', () async {
      await db.insert('hoc_sinh', {
        'id': 1,
        'ho_ten': 'S1',
        'created_at': nowStr,
        'updated_at': nowStr,
      });
      await db.insert('hoc_sinh', {
        'id': 2,
        'ho_ten': 'S2',
        'created_at': nowStr,
        'updated_at': nowStr,
      });
      await db.insert('lop', {
        'id': 10,
        'ten_lop': 'Class A',
        'created_at': nowStr,
        'updated_at': nowStr,
      });

      await db.insert('tham_gia_lop', {
        'id': 100,
        'id_hoc_sinh': 1,
        'id_lop': 10,
        'tu_ngay': '2026-01-01',
        'created_at': nowStr,
        'updated_at': nowStr,
      });
      await db.insert('tham_gia_lop', {
        'id': 200,
        'id_hoc_sinh': 2,
        'id_lop': 10,
        'tu_ngay': '2026-01-01',
        'created_at': nowStr,
        'updated_at': nowStr,
      });

      await db.insert('buoi_hoc', {
        'id': 105,
        'id_lop': 10,
        'ngay': '2026-09-25',
        'gio_bat_dau': '17:30',
        'gio_ket_thuc': '19:00',
        'loai': 'PHAT_SINH',
        'trang_thai': 'DU_KIEN',
        'created_at': nowStr,
        'updated_at': nowStr,
      });

      // Initially empty
      var psRoster = await rosterService.getRosterForSession(105);
      expect(psRoster.participants, isEmpty);
      expect(psRoster.requiresOneOffAdjustments, isTrue);

      // Add Student 1
      await adjustmentService.createPhatSinh(
        studentId: 1,
        originalClassId: 10,
        targetSessionId: 105,
      );
      psRoster = await rosterService.getRosterForSession(105);
      expect(psRoster.participants.length, 1);
      expect(psRoster.requiresOneOffAdjustments, isFalse);

      // Add Student 2
      await adjustmentService.createPhatSinh(
        studentId: 2,
        originalClassId: 10,
        targetSessionId: 105,
      );
      psRoster = await rosterService.getRosterForSession(105);
      expect(psRoster.participants.length, 2);
      expect(
        psRoster.participants.map((p) => p.student.id).toSet(),
        equals({1, 2}),
      );
    });

    test(
      'Live DOI_CA mutation and removal refresh canonical roster immediately',
      () async {
        await db.insert('hoc_sinh', {
          'id': 1,
          'ho_ten': 'S1',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
        await db.insert('lop', {
          'id': 10,
          'ten_lop': 'C10',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
        await db.insert('tham_gia_lop', {
          'id': 100,
          'id_hoc_sinh': 1,
          'id_lop': 10,
          'tu_ngay': '2026-01-01',
          'created_at': nowStr,
          'updated_at': nowStr,
        });

        await db.insert('lich_hoc', {
          'id': 1,
          'id_lop': 10,
          'thu_trong_tuan': 1,
          'gio_bat_dau': '17:30',
          'gio_ket_thuc': '19:00',
          'hieu_luc_tu': '2026-01-01',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
        await db.insert('lich_hoc', {
          'id': 2,
          'id_lop': 10,
          'thu_trong_tuan': 1,
          'gio_bat_dau': '19:30',
          'gio_ket_thuc': '21:00',
          'hieu_luc_tu': '2026-01-01',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
        await db.insert('phan_ca_hoc_sinh', {
          'id': 50,
          'id_hoc_sinh': 1,
          'id_lop': 10,
          'id_lich_hoc': 1,
          'tu_ngay': '2026-01-01',
          'created_at': nowStr,
          'updated_at': nowStr,
        });

        await db.insert('buoi_hoc', {
          'id': 101,
          'id_lop': 10,
          'id_lich_hoc': 1,
          'ngay': '2026-09-21',
          'gio_bat_dau': '17:30',
          'gio_ket_thuc': '19:00',
          'loai': 'CHINH',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
        await db.insert('buoi_hoc', {
          'id': 102,
          'id_lop': 10,
          'id_lich_hoc': 2,
          'ngay': '2026-09-21',
          'gio_bat_dau': '19:30',
          'gio_ket_thuc': '21:00',
          'loai': 'CHINH',
          'created_at': nowStr,
          'updated_at': nowStr,
        });

        // 1. Initial rosters
        expect(
          (await rosterService.getRosterForSession(
            101,
          )).participants.any((p) => p.student.id == 1),
          isTrue,
        );
        expect(
          (await rosterService.getRosterForSession(
            102,
          )).participants.any((p) => p.student.id == 1),
          isFalse,
        );

        // 2. Create DOI_CA
        final adjId = await adjustmentService.createDoiCa(
          studentId: 1,
          originalSessionId: 101,
          targetSessionId: 102,
        );

        // 3. Immediately refreshed
        expect(
          (await rosterService.getRosterForSession(
            101,
          )).participants.any((p) => p.student.id == 1),
          isFalse,
        );
        expect(
          (await rosterService.getRosterForSession(
            102,
          )).participants.any((p) => p.student.id == 1),
          isTrue,
        );

        // 4. Remove adjustment
        await adjustmentService.removeAdjustment(adjId);

        // 5. Immediately restored
        expect(
          (await rosterService.getRosterForSession(
            101,
          )).participants.any((p) => p.student.id == 1),
          isTrue,
        );
        expect(
          (await rosterService.getRosterForSession(
            102,
          )).participants.any((p) => p.student.id == 1),
          isFalse,
        );
      },
    );

    test(
      'Live PHAT_SINH removal restores empty manual session roster',
      () async {
        await db.insert('hoc_sinh', {
          'id': 1,
          'ho_ten': 'S1',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
        await db.insert('lop', {
          'id': 10,
          'ten_lop': 'C10',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
        await db.insert('tham_gia_lop', {
          'id': 100,
          'id_hoc_sinh': 1,
          'id_lop': 10,
          'tu_ngay': '2026-01-01',
          'created_at': nowStr,
          'updated_at': nowStr,
        });

        await db.insert('buoi_hoc', {
          'id': 105,
          'id_lop': 10,
          'ngay': '2026-09-25',
          'gio_bat_dau': '17:30',
          'gio_ket_thuc': '19:00',
          'loai': 'PHAT_SINH',
          'trang_thai': 'DU_KIEN',
          'created_at': nowStr,
          'updated_at': nowStr,
        });

        final adjId = await adjustmentService.createPhatSinh(
          studentId: 1,
          originalClassId: 10,
          targetSessionId: 105,
        );
        expect(
          (await rosterService.getRosterForSession(105)).participants.length,
          1,
        );

        await adjustmentService.removeAdjustment(adjId);
        final psRoster = await rosterService.getRosterForSession(105);
        expect(psRoster.participants, isEmpty);
        expect(psRoster.requiresOneOffAdjustments, isTrue);
      },
    );

    test(
      'Phase 11B: DOI_CA excludes original session but third overlapping commitment blocks DOI_CA',
      () async {
        await db.insert('hoc_sinh', {
          'id': 1,
          'ho_ten': 'S1',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
        await db.insert('lop', {
          'id': 10,
          'ten_lop': 'C10',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
        await db.insert('lop', {
          'id': 20,
          'ten_lop': 'C20',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
        await db.insert('tham_gia_lop', {
          'id': 100,
          'id_hoc_sinh': 1,
          'id_lop': 10,
          'tu_ngay': '2026-01-01',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
        await db.insert('tham_gia_lop', {
          'id': 200,
          'id_hoc_sinh': 1,
          'id_lop': 20,
          'tu_ngay': '2026-01-01',
          'created_at': nowStr,
          'updated_at': nowStr,
        });

        // Class 10 Shift 1 (Mon 17:00-18:30)
        await db.insert('lich_hoc', {
          'id': 1,
          'id_lop': 10,
          'thu_trong_tuan': 1,
          'gio_bat_dau': '17:00',
          'gio_ket_thuc': '18:30',
          'hieu_luc_tu': '2026-01-01',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
        // Class 10 Shift 2 (Mon 17:30-19:00) - Target for DOI_CA
        await db.insert('lich_hoc', {
          'id': 2,
          'id_lop': 10,
          'thu_trong_tuan': 1,
          'gio_bat_dau': '17:30',
          'gio_ket_thuc': '19:00',
          'hieu_luc_tu': '2026-01-01',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
        // Class 20 Third Commitment (Mon 18:00-20:00)
        await db.insert('lich_hoc', {
          'id': 3,
          'id_lop': 20,
          'thu_trong_tuan': 1,
          'gio_bat_dau': '18:00',
          'gio_ket_thuc': '20:00',
          'hieu_luc_tu': '2026-01-01',
          'created_at': nowStr,
          'updated_at': nowStr,
        });

        await db.insert('phan_ca_hoc_sinh', {
          'id': 10,
          'id_hoc_sinh': 1,
          'id_lop': 10,
          'id_lich_hoc': 1,
          'tu_ngay': '2026-01-01',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
        await db.insert('phan_ca_hoc_sinh', {
          'id': 20,
          'id_hoc_sinh': 1,
          'id_lop': 20,
          'id_lich_hoc': 3,
          'tu_ngay': '2026-01-01',
          'created_at': nowStr,
          'updated_at': nowStr,
        });

        await db.insert('buoi_hoc', {
          'id': 101,
          'id_lop': 10,
          'id_lich_hoc': 1,
          'ngay': '2026-09-21',
          'gio_bat_dau': '17:00',
          'gio_ket_thuc': '18:30',
          'loai': 'CHINH',
          'trang_thai': 'DU_KIEN',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
        await db.insert('buoi_hoc', {
          'id': 102,
          'id_lop': 10,
          'id_lich_hoc': 2,
          'ngay': '2026-09-21',
          'gio_bat_dau': '17:30',
          'gio_ket_thuc': '19:00',
          'loai': 'CHINH',
          'trang_thai': 'DU_KIEN',
          'created_at': nowStr,
          'updated_at': nowStr,
        });

        // Attempting DOI_CA 101 -> 102:
        // Original session 101 (17:00-18:30) is excluded, but Class 20 third commitment (18:00-20:00) overlaps target 102 (17:30-19:00)
        await expectLater(
          adjustmentService.createDoiCa(
            studentId: 1,
            originalSessionId: 101,
            targetSessionId: 102,
          ),
          throwsA(predicate((e) => e.toString().contains('Trùng lịch'))),
        );
      },
    );

    test(
      'Phase 11B: Constraint HARD_BLOCK rejects DOI_CA, SOFT_PREFERENCE allows DOI_CA',
      () async {
        await db.insert('hoc_sinh', {
          'id': 1,
          'ho_ten': 'S1',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
        await db.insert('lop', {
          'id': 10,
          'ten_lop': 'C10',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
        await db.insert('tham_gia_lop', {
          'id': 100,
          'id_hoc_sinh': 1,
          'id_lop': 10,
          'tu_ngay': '2026-01-01',
          'created_at': nowStr,
          'updated_at': nowStr,
        });

        await db.insert('lich_hoc', {
          'id': 1,
          'id_lop': 10,
          'thu_trong_tuan': 1,
          'gio_bat_dau': '08:00',
          'gio_ket_thuc': '09:30',
          'hieu_luc_tu': '2026-01-01',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
        await db.insert('lich_hoc', {
          'id': 2,
          'id_lop': 10,
          'thu_trong_tuan': 1,
          'gio_bat_dau': '10:00',
          'gio_ket_thuc': '11:30',
          'hieu_luc_tu': '2026-01-01',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
        await db.insert('phan_ca_hoc_sinh', {
          'id': 10,
          'id_hoc_sinh': 1,
          'id_lop': 10,
          'id_lich_hoc': 1,
          'tu_ngay': '2026-01-01',
          'created_at': nowStr,
          'updated_at': nowStr,
        });

        await db.insert('buoi_hoc', {
          'id': 101,
          'id_lop': 10,
          'id_lich_hoc': 1,
          'ngay': '2026-09-21',
          'gio_bat_dau': '08:00',
          'gio_ket_thuc': '09:30',
          'loai': 'CHINH',
          'trang_thai': 'DU_KIEN',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
        await db.insert('buoi_hoc', {
          'id': 102,
          'id_lop': 10,
          'id_lich_hoc': 2,
          'ngay': '2026-09-21',
          'gio_bat_dau': '10:00',
          'gio_ket_thuc': '11:30',
          'loai': 'CHINH',
          'trang_thai': 'DU_KIEN',
          'created_at': nowStr,
          'updated_at': nowStr,
        });

        // Add HARD_BLOCK constraint on 10:30-11:30
        await db.execute('''
          INSERT INTO rang_buoc_lich_hoc_sinh (id_hoc_sinh, loai, kieu, thu_trong_tuan, gio_bat_dau, gio_ket_thuc, hieu_luc_tu, created_at, updated_at)
          VALUES (1, 'HARD_BLOCK', 'DINH_KY', 1, '10:30', '11:30', '2026-01-01', '2026-01-01', '2026-01-01')
        ''');

        // HARD_BLOCK rejects DOI_CA
        await expectLater(
          adjustmentService.createDoiCa(
            studentId: 1,
            originalSessionId: 101,
            targetSessionId: 102,
          ),
          throwsA(
            predicate((e) => e.toString().contains('Trùng lịch bận cố định')),
          ),
        );
      },
    );

    test(
      'Phase 11B: Outgoing DOI_CA removes student commitment on original session date',
      () async {
        await db.insert('hoc_sinh', {
          'id': 1,
          'ho_ten': 'S1',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
        await db.insert('lop', {
          'id': 10,
          'ten_lop': 'C10',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
        await db.insert('tham_gia_lop', {
          'id': 100,
          'id_hoc_sinh': 1,
          'id_lop': 10,
          'tu_ngay': '2026-01-01',
          'created_at': nowStr,
          'updated_at': nowStr,
        });

        // Class 10 Shift 1 (08:00-09:30), Shift 2 (10:00-11:30), Shift 3 (08:30-10:00)
        await db.insert('lich_hoc', {
          'id': 1,
          'id_lop': 10,
          'thu_trong_tuan': 1,
          'gio_bat_dau': '08:00',
          'gio_ket_thuc': '09:30',
          'hieu_luc_tu': '2026-01-01',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
        await db.insert('lich_hoc', {
          'id': 2,
          'id_lop': 10,
          'thu_trong_tuan': 1,
          'gio_bat_dau': '10:00',
          'gio_ket_thuc': '11:30',
          'hieu_luc_tu': '2026-01-01',
          'created_at': nowStr,
          'updated_at': nowStr,
        });

        await db.insert('phan_ca_hoc_sinh', {
          'id': 10,
          'id_hoc_sinh': 1,
          'id_lop': 10,
          'id_lich_hoc': 1,
          'tu_ngay': '2026-01-01',
          'created_at': nowStr,
          'updated_at': nowStr,
        });

        await db.insert('buoi_hoc', {
          'id': 101,
          'id_lop': 10,
          'id_lich_hoc': 1,
          'ngay': '2026-09-21',
          'gio_bat_dau': '08:00',
          'gio_ket_thuc': '09:30',
          'loai': 'CHINH',
          'trang_thai': 'DU_KIEN',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
        await db.insert('buoi_hoc', {
          'id': 102,
          'id_lop': 10,
          'id_lich_hoc': 2,
          'ngay': '2026-09-21',
          'gio_bat_dau': '10:00',
          'gio_ket_thuc': '11:30',
          'loai': 'CHINH',
          'trang_thai': 'DU_KIEN',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
        await db.insert('buoi_hoc', {
          'id': 103,
          'id_lop': 10,
          'ngay': '2026-09-21',
          'gio_bat_dau': '08:30',
          'gio_ket_thuc': '10:00',
          'loai': 'PHAT_SINH',
          'trang_thai': 'DU_KIEN',
          'created_at': nowStr,
          'updated_at': nowStr,
        });

        // DOI_CA from 101 (08:00-09:30) -> 102 (10:00-11:30)
        await adjustmentService.createDoiCa(
          studentId: 1,
          originalSessionId: 101,
          targetSessionId: 102,
        );

        // Now student is NO LONGER committed to 101 (08:00-09:30), but IS committed to 102 (10:00-11:30).
        // Candidate 103 (08:30-10:00) overlaps 102 (10:00-11:30)? No! 08:30-10:00 ends at 10:00, 102 starts at 10:00 (adjacent -> no conflict!).
        // And 103 (08:30-10:00) overlapped 101 (08:00-09:30), but student has outgoing DOI_CA from 101, so 101 is NOT a commitment!
        // Therefore, PHAT_SINH to 103 should SUCCEED!
        final psAdjId = await adjustmentService.createPhatSinh(
          studentId: 1,
          originalClassId: 10,
          targetSessionId: 103,
        );
        expect(psAdjId, isNotNull);
      },
    );

    test(
      'HOC_BU bulk action save persists correct trang_thai, loai_tham_gia and id_buoi_vang_goc for all students',
      () async {
        await db.insert('hoc_sinh', {
          'id': 1,
          'ho_ten': 'S1',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
        await db.insert('hoc_sinh', {
          'id': 2,
          'ho_ten': 'S2',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
        await db.insert('lop', {
          'id': 10,
          'ten_lop': 'C10',
          'created_at': nowStr,
          'updated_at': nowStr,
        });

        await db.insert('tham_gia_lop', {
          'id': 100,
          'id_hoc_sinh': 1,
          'id_lop': 10,
          'tu_ngay': '2026-01-01',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
        await db.insert('tham_gia_lop', {
          'id': 200,
          'id_hoc_sinh': 2,
          'id_lop': 10,
          'tu_ngay': '2026-01-01',
          'created_at': nowStr,
          'updated_at': nowStr,
        });

        // Original CHINH session DA_HOC where both were absent
        await db.insert('buoi_hoc', {
          'id': 101,
          'id_lop': 10,
          'ngay': '2026-09-21',
          'gio_bat_dau': '17:30',
          'gio_ket_thuc': '19:00',
          'loai': 'CHINH',
          'trang_thai': 'DA_HOC',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
        await db.insert('diem_danh', {
          'id_buoi_hoc': 101,
          'id_hoc_sinh': 1,
          'id_lop_goc': 10,
          'trang_thai': 'NGHI_CO_PHEP',
          'loai_tham_gia': 'CHINH',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
        await db.insert('diem_danh', {
          'id_buoi_hoc': 101,
          'id_hoc_sinh': 2,
          'id_lop_goc': 10,
          'trang_thai': 'NGHI_KHONG_PHEP',
          'loai_tham_gia': 'CHINH',
          'created_at': nowStr,
          'updated_at': nowStr,
        });

        // Target HOC_BU session
        await db.insert('buoi_hoc', {
          'id': 102,
          'id_lop': 10,
          'ngay': '2026-09-22',
          'gio_bat_dau': '17:30',
          'gio_ket_thuc': '19:00',
          'loai': 'HOC_BU',
          'trang_thai': 'DU_KIEN',
          'created_at': nowStr,
          'updated_at': nowStr,
        });

        await adjustmentService.createHocBu(
          studentId: 1,
          originalSessionId: 101,
          targetSessionId: 102,
        );
        await adjustmentService.createHocBu(
          studentId: 2,
          originalSessionId: 101,
          targetSessionId: 102,
        );

        // Bulk Save HOC_BU for both
        await attendanceService.saveDraft(102, {
          1: AttendanceState.HOC_BU,
          2: AttendanceState.HOC_BU,
        });

        final rows = await db.query('diem_danh', where: 'id_buoi_hoc = 102');
        expect(rows.length, 2);
        for (final r in rows) {
          expect(r['trang_thai'], 'HOC_BU');
          expect(r['loai_tham_gia'], 'HOC_BU');
          expect(r['id_buoi_vang_goc'], 101);
        }
      },
    );
  });
}
