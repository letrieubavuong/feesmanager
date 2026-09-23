import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tuition2027/features/attendance/domain/attendance_service.dart';
import 'package:tuition2027/features/attendance/data/attendance_repository.dart';
import 'package:tuition2027/features/attendance/domain/attendance_state.dart';
import 'package:tuition2027/features/classes/domain/class_service.dart';
import 'package:tuition2027/features/classes/data/class_repository.dart';
import 'package:tuition2027/features/leave/domain/leave_request.dart';
import 'package:tuition2027/features/leave/domain/leave_request_service.dart';
import 'package:tuition2027/features/leave/data/leave_request_repository.dart';
import 'package:tuition2027/features/memberships/domain/membership_service.dart';
import 'package:tuition2027/features/memberships/data/membership_repository.dart';
import 'package:tuition2027/features/roster/domain/roster_service.dart';
import 'package:tuition2027/features/schedule/domain/schedule_service.dart';
import 'package:tuition2027/features/schedule/data/schedule_repository.dart';
import 'package:tuition2027/features/schedule/data/assignment_repository.dart';
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
  late LeaveRequestService leaveService;
  late LeaveRequestRepository leaveRepo;
  late StudentService studentService;
  late ClassService classService;
  late MembershipService membershipService;
  late AttendanceService attendanceService;
  late AttendanceRepository attendanceRepo;
  late RosterService rosterService;
  late SessionService sessionService;
  late ScheduleDomainService scheduleService;
  late SessionAdjustmentRepository adjustmentRepo;

  final nowStr = DateTime.now().toIso8601String();

  setUp(() async {
    db = await TestDbHelperV6.createLatest();

    leaveRepo = LeaveRequestRepository(db);
    final studentRepo = StudentRepository(db);
    final membershipRepo = MembershipRepository(db);
    final classRepo = ClassRepository(db);
    final sessionRepo = SessionRepository(db);
    final scheduleRepo = ScheduleRepository(db);
    final assignmentRepo = AssignmentRepository(db);
    attendanceRepo = AttendanceRepository(db);
    adjustmentRepo = SessionAdjustmentRepository(db);

    membershipService = MembershipService(membershipRepo);
    studentService = StudentService(studentRepo, membershipService);
    classService = ClassService(classRepo, membershipService);
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

    leaveService = LeaveRequestService(
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

  group('LeaveRequestService Domain Tests', () {
    test('Create valid leave request', () async {
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

      final req = LeaveRequest(
        idHocSinh: 1,
        idLop: 10,
        tuNgay: '2026-09-10',
        denNgay: '2026-09-20',
        lyDo: 'Nghỉ gia đình',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final id = await leaveService.createLeaveRequest(req);
      final fetched = await leaveService.getById(id);

      expect(fetched, isNotNull);
      expect(fetched!.trangThai, LeaveRequestStatus.CHO_DUYET);
      expect(fetched.lyDo, 'Nghỉ gia đình');
    });

    test('Invalid date interval rejected', () async {
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

      final req = LeaveRequest(
        idHocSinh: 1,
        idLop: 10,
        tuNgay: '2026-09-20',
        denNgay: '2026-09-10',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(
        () => leaveService.createLeaveRequest(req),
        throwsA(isA<Exception>()),
      );
    });

    test('Overlapping active leave request rejected', () async {
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

      final req1 = LeaveRequest(
        idHocSinh: 1,
        idLop: 10,
        tuNgay: '2026-09-10',
        denNgay: '2026-09-15',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await leaveService.createLeaveRequest(req1);

      final req2 = LeaveRequest(
        idHocSinh: 1,
        idLop: 10,
        tuNgay: '2026-09-12',
        denNgay: '2026-09-18',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(
        () => leaveService.createLeaveRequest(req2),
        throwsA(isA<Exception>()),
      );
    });

    test(
      'Status transitions: CHO_DUYET -> DA_DUYET / TU_CHOI allowed, others rejected',
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

        final req = LeaveRequest(
          idHocSinh: 1,
          idLop: 10,
          tuNgay: '2026-09-10',
          denNgay: '2026-09-15',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        final id = await leaveService.createLeaveRequest(req);

        await leaveService.updateStatus(id, LeaveRequestStatus.DA_DUYET);
        expect(
          (await leaveService.getById(id))!.trangThai,
          LeaveRequestStatus.DA_DUYET,
        );

        expect(
          () => leaveService.updateStatus(id, LeaveRequestStatus.CHO_DUYET),
          throwsA(isA<Exception>()),
        );
        expect(
          () => leaveService.updateStatus(id, LeaveRequestStatus.TU_CHOI),
          throwsA(isA<Exception>()),
        );
      },
    );

    test(
      'Approved leave suggestion in AttendanceService does not mutate DB',
      () async {
        await db.insert('hoc_sinh', {
          'id': 101,
          'ho_ten': 'Student 101',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
        await db.insert('lop', {
          'id': 1,
          'ten_lop': 'Class 1',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
        await db.insert('tham_gia_lop', {
          'id': 1,
          'id_hoc_sinh': 101,
          'id_lop': 1,
          'tu_ngay': '2026-01-01',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
        await db.insert('lich_hoc', {
          'id': 1,
          'id_lop': 1,
          'thu_trong_tuan': 1,
          'gio_bat_dau': '17:30',
          'gio_ket_thuc': '19:00',
          'hieu_luc_tu': '2026-01-01',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
        await db.insert('buoi_hoc', {
          'id': 1,
          'id_lop': 1,
          'id_lich_hoc': 1,
          'ngay': '2026-09-21',
          'gio_bat_dau': '17:30',
          'gio_ket_thuc': '19:00',
          'loai': 'CHINH',
          'created_at': nowStr,
          'updated_at': nowStr,
        });

        // Create & Approve leave request covering 2026-09-21
        final req = LeaveRequest(
          idHocSinh: 101,
          idLop: 1,
          tuNgay: '2026-09-20',
          denNgay: '2026-09-22',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        final reqId = await leaveService.createLeaveRequest(req);
        await leaveService.updateStatus(reqId, LeaveRequestStatus.DA_DUYET);

        // Load attendance sheet
        final sheet = await attendanceService.getAttendanceForSession(1);
        final member = sheet.members.first;

        expect(member.suggestedState, AttendanceState.NGHI_CO_PHEP);
        expect(member.suggestionReason, 'Đơn nghỉ đã duyệt');
        expect(member.state, AttendanceState.CHUA_DIEM_DANH);

        // DB row count for diem_danh remains 0
        final ddRows = await db.query('diem_danh');
        expect(ddRows, isEmpty);
      },
    );

    test(
      'Existing persisted attendance wins over approved leave suggestion',
      () async {
        await db.insert('hoc_sinh', {
          'id': 101,
          'ho_ten': 'Student 101',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
        await db.insert('lop', {
          'id': 1,
          'ten_lop': 'Class 1',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
        await db.insert('tham_gia_lop', {
          'id': 1,
          'id_hoc_sinh': 101,
          'id_lop': 1,
          'tu_ngay': '2026-01-01',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
        await db.insert('lich_hoc', {
          'id': 1,
          'id_lop': 1,
          'thu_trong_tuan': 1,
          'gio_bat_dau': '17:30',
          'gio_ket_thuc': '19:00',
          'hieu_luc_tu': '2026-01-01',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
        await db.insert('buoi_hoc', {
          'id': 1,
          'id_lop': 1,
          'id_lich_hoc': 1,
          'ngay': '2026-09-21',
          'gio_bat_dau': '17:30',
          'gio_ket_thuc': '19:00',
          'loai': 'CHINH',
          'created_at': nowStr,
          'updated_at': nowStr,
        });

        // Mark CO_MAT
        await attendanceService.saveDraft(1, {101: AttendanceState.CO_MAT});

        // Create & Approve leave request
        final req = LeaveRequest(
          idHocSinh: 101,
          idLop: 1,
          tuNgay: '2026-09-20',
          denNgay: '2026-09-22',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        final reqId = await leaveService.createLeaveRequest(req);
        await leaveService.updateStatus(reqId, LeaveRequestStatus.DA_DUYET);

        // Load attendance sheet
        final sheet = await attendanceService.getAttendanceForSession(1);
        final member = sheet.members.first;

        expect(member.state, AttendanceState.CO_MAT);
        expect(member.suggestedState, isNull);
      },
    );

    test('Nonexistent student or class rejected for leave request', () async {
      final req = LeaveRequest(
        idHocSinh: 999,
        idLop: 10,
        tuNgay: '2026-09-10',
        denNgay: '2026-09-15',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await expectLater(
        leaveService.createLeaveRequest(req),
        throwsA(isA<Exception>()),
      );
    });

    test(
      'Student with no membership intersection rejected for leave request',
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
        // Membership was only in January
        await db.insert('tham_gia_lop', {
          'id': 100,
          'id_hoc_sinh': 1,
          'id_lop': 10,
          'tu_ngay': '2026-01-01',
          'den_ngay': '2026-01-31',
          'created_at': nowStr,
          'updated_at': nowStr,
        });

        // Leave requested in September
        final req = LeaveRequest(
          idHocSinh: 1,
          idLop: 10,
          tuNgay: '2026-09-10',
          denNgay: '2026-09-15',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await expectLater(
          leaveService.createLeaveRequest(req),
          throwsA(isA<Exception>()),
        );
      },
    );

    test(
      'Leave boundaries test: inclusive tuNgay/denNgay suggested, outside not suggested',
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

        // Mondays: 2026-09-07, 2026-09-14, 2026-09-21, 2026-09-28
        for (final date in [
          '2026-09-07',
          '2026-09-14',
          '2026-09-21',
          '2026-09-28',
        ]) {
          final id = int.parse(date.replaceAll('-', ''));
          await db.insert('buoi_hoc', {
            'id': id,
            'id_lop': 10,
            'id_lich_hoc': 1,
            'ngay': date,
            'gio_bat_dau': '17:30',
            'gio_ket_thuc': '19:00',
            'loai': 'CHINH',
            'created_at': nowStr,
            'updated_at': nowStr,
          });
        }

        // Approved leave 2026-09-14 to 2026-09-21
        final req = LeaveRequest(
          idHocSinh: 1,
          idLop: 10,
          tuNgay: '2026-09-14',
          denNgay: '2026-09-21',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        final reqId = await leaveService.createLeaveRequest(req);
        await leaveService.updateStatus(reqId, LeaveRequestStatus.DA_DUYET);

        // 09-07 (outside) -> no suggestion
        final sheet07 = await attendanceService.getAttendanceForSession(
          20260907,
        );
        expect(sheet07.members.first.suggestedState, isNull);

        // 09-14 (tuNgay boundary) -> suggestion
        final sheet14 = await attendanceService.getAttendanceForSession(
          20260914,
        );
        expect(
          sheet14.members.first.suggestedState,
          AttendanceState.NGHI_CO_PHEP,
        );

        // 09-21 (denNgay boundary) -> suggestion
        final sheet21 = await attendanceService.getAttendanceForSession(
          20260921,
        );
        expect(
          sheet21.members.first.suggestedState,
          AttendanceState.NGHI_CO_PHEP,
        );

        // 09-28 (outside) -> no suggestion
        final sheet28 = await attendanceService.getAttendanceForSession(
          20260928,
        );
        expect(sheet28.members.first.suggestedState, isNull);
      },
    );

    test(
      'CHO_DUYET and TU_CHOI leave requests do not produce suggestions',
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
          'id': 1,
          'id_lop': 10,
          'id_lich_hoc': 1,
          'ngay': '2026-09-14',
          'gio_bat_dau': '17:30',
          'gio_ket_thuc': '19:00',
          'loai': 'CHINH',
          'created_at': nowStr,
          'updated_at': nowStr,
        });

        // CHO_DUYET leave
        final req1 = LeaveRequest(
          idHocSinh: 1,
          idLop: 10,
          tuNgay: '2026-09-14',
          denNgay: '2026-09-14',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await leaveService.createLeaveRequest(req1);

        var sheet = await attendanceService.getAttendanceForSession(1);
        expect(sheet.members.first.suggestedState, isNull);
      },
    );

    test('Approved leave does not add paused student to roster', () async {
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
      // Membership ended on 2026-08-31
      await db.insert('tham_gia_lop', {
        'id': 100,
        'id_hoc_sinh': 1,
        'id_lop': 10,
        'tu_ngay': '2026-01-01',
        'den_ngay': '2026-08-31',
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
        'id': 1,
        'id_lop': 10,
        'id_lich_hoc': 1,
        'ngay': '2026-09-14',
        'gio_bat_dau': '17:30',
        'gio_ket_thuc': '19:00',
        'loai': 'CHINH',
        'created_at': nowStr,
        'updated_at': nowStr,
      });

      final sheet = await attendanceService.getAttendanceForSession(1);
      expect(sheet.members, isEmpty);
    });

    test(
      'Late leave approval does not alter historical finalized attendance',
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
          'id': 1,
          'id_lop': 10,
          'id_lich_hoc': 1,
          'ngay': '2026-09-14',
          'gio_bat_dau': '17:30',
          'gio_ket_thuc': '19:00',
          'loai': 'CHINH',
          'trang_thai': 'DA_HOC',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
        await db.insert('diem_danh', {
          'id_buoi_hoc': 1,
          'id_hoc_sinh': 1,
          'id_lop_goc': 10,
          'trang_thai': 'NGHI_KHONG_PHEP',
          'loai_tham_gia': 'CHINH',
          'created_at': nowStr,
          'updated_at': nowStr,
        });

        final req = LeaveRequest(
          idHocSinh: 1,
          idLop: 10,
          tuNgay: '2026-09-14',
          denNgay: '2026-09-14',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        final reqId = await leaveService.createLeaveRequest(req);
        await leaveService.updateStatus(reqId, LeaveRequestStatus.DA_DUYET);

        final sheet = await attendanceService.getAttendanceForSession(1);
        expect(sheet.members.first.state, AttendanceState.NGHI_KHONG_PHEP);
      },
    );
  });
}
