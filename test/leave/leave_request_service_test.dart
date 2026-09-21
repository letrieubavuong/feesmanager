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
  });
}
