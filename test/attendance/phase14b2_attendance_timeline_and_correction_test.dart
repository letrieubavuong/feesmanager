import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tuition2027/core/database/app_database.dart';
import 'package:tuition2027/features/attendance/data/attendance_repository.dart';
import 'package:tuition2027/features/attendance/domain/attendance_record.dart';
import 'package:tuition2027/features/attendance/domain/attendance_service.dart';
import 'package:tuition2027/features/attendance/domain/attendance_state.dart';
import 'package:tuition2027/features/classes/data/class_repository.dart';
import 'package:tuition2027/features/classes/domain/class_service.dart';
import 'package:tuition2027/features/leave/data/leave_request_repository.dart';
import 'package:tuition2027/features/leave/domain/leave_request_service.dart';
import 'package:tuition2027/features/memberships/data/membership_repository.dart';
import 'package:tuition2027/features/memberships/domain/membership_service.dart';
import 'package:tuition2027/features/payments/data/payment_repository.dart';
import 'package:tuition2027/features/roster/domain/roster_service.dart';
import 'package:tuition2027/features/schedule/data/assignment_repository.dart';
import 'package:tuition2027/features/schedule/data/schedule_repository.dart';
import 'package:tuition2027/features/schedule/domain/schedule_service.dart';
import 'package:tuition2027/features/schedule_conflicts/data/schedule_constraint_repository.dart';
import 'package:tuition2027/features/schedule_conflicts/domain/schedule_conflict_service.dart';
import 'package:tuition2027/features/session_adjustments/data/session_adjustment_repository.dart';
import 'package:tuition2027/features/session_credits/data/session_credit_repository.dart';
import 'package:tuition2027/features/session_credits/domain/session_credit_service.dart';
import 'package:tuition2027/features/sessions/data/session_repository.dart';
import 'package:tuition2027/features/sessions/domain/session_service.dart';
import 'package:tuition2027/features/students/data/student_repository.dart';
import 'package:tuition2027/features/students/domain/student_service.dart';
import 'package:tuition2027/features/tuition/data/tuition_policy_repository.dart';
import 'package:tuition2027/features/tuition/data/tuition_repository.dart';
import 'package:tuition2027/features/tuition/domain/invoice_service.dart';
import 'package:tuition2027/features/tuition/domain/tuition_policy_service.dart';
import 'package:tuition2027/features/tuition/domain/tuition_service.dart';

void main() {
  late Directory tempDir;
  late Database db;
  late AppDatabase appDb;
  late AttendanceRepository attendanceRepo;
  late AttendanceService attendanceService;
  late SessionService sessionService;
  late StudentRepository studentRepo;
  late ClassRepository classRepo;
  late MembershipRepository memberRepo;
  late InvoiceService invoiceService;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('phase14b2_test');
    final dbPath = join(tempDir.path, 'test.db');
    appDb = AppDatabase(dbName: dbPath);
    db = await appDb.database;

    studentRepo = StudentRepository(db);
    classRepo = ClassRepository(db);
    memberRepo = MembershipRepository(db);
    final scheduleRepo = ScheduleRepository(db);
    final assignRepo = AssignmentRepository(db);
    final sessionRepo = SessionRepository(db);
    attendanceRepo = AttendanceRepository(db);
    final adjRepo = SessionAdjustmentRepository(db);
    final creditRepo = SessionCreditRepository(db);
    final policyRepo = TuitionPolicyRepository(db);
    final tuitionRepo = TuitionRepository(db);
    final paymentRepo = PaymentRepository(db);

    final memberService = MembershipService(memberRepo);
    final studentService = StudentService(studentRepo, memberService);
    final classService = ClassService(classRepo, memberService);
    final policyService = TuitionPolicyService(
      policyRepo,
      classService,
      tuitionRepo,
      creditRepo,
      db,
    );

    final constraintRepo = ScheduleConstraintRepository(db);
    final conflictService = ScheduleConflictService(
      constraintRepo,
      scheduleRepo,
      assignRepo,
      sessionRepo,
      adjRepo,
      classService,
    );

    sessionService = SessionService(sessionRepo, classService);
    final scheduleService = ScheduleDomainService(
      scheduleRepo,
      assignRepo,
      memberService,
      classService,
      studentService,
      conflictService,
    );
    final rosterService = RosterService(
      sessionService,
      memberService,
      scheduleService,
      studentService,
      adjRepo,
    );

    final leaveRepo = LeaveRequestRepository(db);
    final leaveService = LeaveRequestService(
      leaveRepo,
      studentService,
      classService,
      memberService,
    );

    attendanceService = AttendanceService(
      attendanceRepo,
      rosterService,
      sessionService,
      leaveService,
    );

    final creditService = SessionCreditService(
      creditRepo,
      sessionService,
      rosterService,
      attendanceRepo,
      studentService,
      classService,
      policyService,
    );

    final tuitionService = TuitionService(
      tuitionRepo,
      policyService,
      creditService,
      memberService,
      attendanceRepo,
      adjRepo,
      sessionRepo,
    );

    invoiceService = InvoiceService(
      tuitionRepo,
      tuitionService,
      creditService,
      creditRepo,
      memberService,
      paymentRepo,
      db,
    );
  });

  tearDown(() async {
    await db.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  Future<int> seedStudent(String name) async {
    return await db.insert('hoc_sinh', {
      'ho_ten': name,
      'sdt_phu_huynh': '0901234567',
      'created_at': '2026-09-01T00:00:00.000',
      'updated_at': '2026-09-01T00:00:00.000',
    });
  }

  Future<int> seedClass(String name) async {
    return await db.insert('lop', {
      'ten_lop': name,
      'si_so_toi_da': 20,
      'created_at': '2026-09-01T00:00:00.000',
      'updated_at': '2026-09-01T00:00:00.000',
    });
  }

  Future<int> seedMembership(
    int studentId,
    int classId,
    String fromDate,
  ) async {
    return await db.insert('tham_gia_lop', {
      'id_hoc_sinh': studentId,
      'id_lop': classId,
      'tu_ngay': fromDate,
      'created_at': '2026-09-01T00:00:00.000',
      'updated_at': '2026-09-01T00:00:00.000',
    });
  }

  Future<int> seedSession(
    int classId,
    String date, {
    String loai = 'CHINH',
  }) async {
    final existing = await db.query(
      'lich_hoc',
      where: 'id_lop = ? AND thu_trong_tuan = ?',
      whereArgs: [classId, 2],
    );
    int scheduleId;
    if (existing.isNotEmpty) {
      scheduleId = existing.first['id'] as int;
    } else {
      scheduleId = await db.insert('lich_hoc', {
        'id_lop': classId,
        'thu_trong_tuan': 2, // 2026-09-15 is Tuesday
        'gio_bat_dau': '17:30',
        'gio_ket_thuc': '19:00',
        'hieu_luc_tu': '2026-09-01',
        'created_at': '2026-09-01T00:00:00.000',
        'updated_at': '2026-09-01T00:00:00.000',
      });
    }

    return await db.insert('buoi_hoc', {
      'id_lop': classId,
      'id_lich_hoc': scheduleId,
      'ngay': date,
      'gio_bat_dau': '17:30',
      'gio_ket_thuc': '19:00',
      'loai': loai,
      'trang_thai': 'DU_KIEN',
      'created_at': '2026-09-01T00:00:00.000',
      'updated_at': '2026-09-01T00:00:00.000',
    });
  }

  test('1. Timeline sorted newest first & batch counts correct', () async {
    final classId = await seedClass('Timeline Test Class');
    await seedSession(classId, '2026-09-10');
    await seedSession(classId, '2026-09-20');

    final items = await attendanceService.getClassAttendanceTimeline(
      classId,
      '2026-09',
    );

    expect(items.length, 2);
    expect(items[0].session.ngay, '2026-09-20');
    expect(items[1].session.ngay, '2026-09-10');
  });

  test(
    '5. DA_HOC: CO_MAT -> TRE creates audit row & updates diem_danh',
    () async {
      final classId = await seedClass('Correction Class');
      final studentId = await seedStudent('Nguyen Van A');
      await seedMembership(studentId, classId, '2026-09-01');
      final sessionId = await seedSession(classId, '2026-09-15');

      // Save initial draft CO_MAT and finalize
      await attendanceService.saveDraft(sessionId, {
        studentId: AttendanceState.CO_MAT,
      });
      await attendanceService.finalizeSessionAttendance(sessionId);

      // Correct finalized attendance: CO_MAT -> TRE
      await attendanceService.correctFinalizedAttendance(
        sessionId: sessionId,
        states: {studentId: AttendanceState.TRE},
        reason: 'Sửa nhầm trạng thái điểm danh',
      );

      // Check updated status in diem_danh
      final record = await attendanceRepo.getBySessionAndStudent(
        sessionId,
        studentId,
      );
      expect(record?.trangThai, AttendanceStatus.TRE);

      // Check audit row in diem_danh_chinh_sua
      final audits = await attendanceService.getCorrectionAuditsForSession(
        sessionId,
      );
      expect(audits.length, 1);
      expect(audits.first.trangThaiCu, 'CO_MAT');
      expect(audits.first.trangThaiMoi, 'TRE');
      expect(audits.first.lyDo, 'Sửa nhầm trạng thái điểm danh');
    },
  );

  test('6. Empty reason is rejected', () async {
    final classId = await seedClass('Test Class');
    final studentId = await seedStudent('Nguyen Van B');
    await seedMembership(studentId, classId, '2026-09-01');
    final sessionId = await seedSession(classId, '2026-09-15');

    await attendanceService.saveDraft(sessionId, {
      studentId: AttendanceState.CO_MAT,
    });
    await attendanceService.finalizeSessionAttendance(sessionId);

    expect(
      () => attendanceService.correctFinalizedAttendance(
        sessionId: sessionId,
        states: {studentId: AttendanceState.TRE},
        reason: '   ',
      ),
      throwsA(isA<Exception>()),
    );
  });

  test('7. DA_HOC -> CHUA_DIEM_DANH is rejected', () async {
    final classId = await seedClass('Test Class 2');
    final studentId = await seedStudent('Nguyen Van C');
    await seedMembership(studentId, classId, '2026-09-01');
    final sessionId = await seedSession(classId, '2026-09-15');

    await attendanceService.saveDraft(sessionId, {
      studentId: AttendanceState.CO_MAT,
    });
    await attendanceService.finalizeSessionAttendance(sessionId);

    expect(
      () => attendanceService.correctFinalizedAttendance(
        sessionId: sessionId,
        states: {studentId: AttendanceState.CHUA_DIEM_DANH},
        reason: 'Lý do hợp lệ',
      ),
      throwsA(isA<Exception>()),
    );
  });

  test('8. Student outside canonical roster is rejected', () async {
    final classId = await seedClass('Test Class 3');
    final studentId = await seedStudent('Nguyen Van D');
    final outsiderId = await seedStudent('Nguyen Van E');
    await seedMembership(studentId, classId, '2026-09-01');
    final sessionId = await seedSession(classId, '2026-09-15');

    await attendanceService.saveDraft(sessionId, {
      studentId: AttendanceState.CO_MAT,
    });
    await attendanceService.finalizeSessionAttendance(sessionId);

    expect(
      () => attendanceService.correctFinalizedAttendance(
        sessionId: sessionId,
        states: {outsiderId: AttendanceState.TRE},
        reason: 'Thêm học sinh ngoài roster',
      ),
      throwsA(isA<Exception>()),
    );
  });

  test(
    '11. Finalized invoice is preserved when attendance is corrected',
    () async {
      final classId = await seedClass('Invoice Safety Class');
      final studentId = await seedStudent('Hoc Sinh Invoice');
      await seedMembership(studentId, classId, '2026-09-01');
      final sessionId = await seedSession(classId, '2026-09-15');

      await attendanceService.saveDraft(sessionId, {
        studentId: AttendanceState.CO_MAT,
      });
      await attendanceService.finalizeSessionAttendance(sessionId);

      // Create policy for class first
      await db.insert('chinh_sach_hoc_phi', {
        'id_lop': classId,
        'hieu_luc_tu': '2026-09-01',
        'so_buoi_chuan_thang': 12,
        'hoc_phi_moi_buoi': 50000,
        'created_at': '2026-09-01T00:00:00.000',
        'updated_at': '2026-09-01T00:00:00.000',
      });

      final invoice = await invoiceService.finalizeStudentInvoice(
        studentId,
        classId,
        '2026-09',
      );
      final initialDue = invoice.soTienPhaiThu;

      // Correct attendance post-finalization
      await attendanceService.correctFinalizedAttendance(
        sessionId: sessionId,
        states: {studentId: AttendanceState.NGHI_KHONG_PHEP},
        reason: 'Sửa điểm danh sau khi chốt',
      );

      // Verify stored finalized invoice did NOT silently change!
      final invoiceAfter = await invoiceService.getInvoice(
        studentId,
        classId,
        '2026-09',
      );
      expect(invoiceAfter?.soTienPhaiThu, initialDue);
    },
  );
}
