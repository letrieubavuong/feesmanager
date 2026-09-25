import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' hide equals;
import 'package:tuition2027/core/database/app_database.dart';
import 'package:tuition2027/features/attendance/data/attendance_repository.dart';
import 'package:tuition2027/features/attendance/domain/attendance_service.dart';
import 'package:tuition2027/features/attendance/domain/attendance_state.dart';
import 'package:tuition2027/features/classes/data/class_repository.dart';
import 'package:tuition2027/features/classes/domain/class.dart';
import 'package:tuition2027/features/classes/domain/class_service.dart';
import 'package:tuition2027/features/leave/data/leave_request_repository.dart';
import 'package:tuition2027/features/leave/domain/leave_request_service.dart';
import 'package:tuition2027/features/memberships/data/membership_repository.dart';
import 'package:tuition2027/features/memberships/domain/membership.dart';
import 'package:tuition2027/features/memberships/domain/membership_service.dart';
import 'package:tuition2027/features/payments/data/payment_repository.dart';
import 'package:tuition2027/features/payments/domain/payment.dart';
import 'package:tuition2027/features/payments/domain/payment_method.dart';
import 'package:tuition2027/features/payments/domain/payment_service.dart';
import 'package:tuition2027/features/reports/domain/report_scope.dart';
import 'package:tuition2027/features/reports/domain/report_service.dart';
import 'package:tuition2027/features/roster/domain/roster_service.dart';
import 'package:tuition2027/features/schedule/data/assignment_repository.dart';
import 'package:tuition2027/features/schedule/data/schedule_repository.dart';
import 'package:tuition2027/features/schedule/domain/schedule_service.dart';
import 'package:tuition2027/features/schedule_conflicts/data/schedule_constraint_repository.dart';
import 'package:tuition2027/features/schedule_conflicts/domain/schedule_conflict_service.dart';
import 'package:tuition2027/features/session_adjustments/data/session_adjustment_repository.dart';
import 'package:tuition2027/features/session_adjustments/domain/session_adjustment_service.dart';
import 'package:tuition2027/features/session_credits/data/session_credit_repository.dart';
import 'package:tuition2027/features/session_credits/domain/session_credit_service.dart';
import 'package:tuition2027/features/sessions/data/session_repository.dart';
import 'package:tuition2027/features/sessions/domain/class_session.dart';
import 'package:tuition2027/features/sessions/domain/session_service.dart';
import 'package:tuition2027/features/students/data/student_repository.dart';
import 'package:tuition2027/features/students/domain/student.dart';
import 'package:tuition2027/features/students/domain/student_service.dart';
import 'package:tuition2027/features/tuition/data/tuition_policy_repository.dart';
import 'package:tuition2027/features/tuition/data/tuition_repository.dart';
import 'package:tuition2027/features/tuition/domain/tuition_invoice.dart';
import 'package:tuition2027/features/tuition/domain/tuition_policy_service.dart';
import 'package:tuition2027/features/tuition/domain/tuition_service.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database db;
  late ReportService reportService;
  late AttendanceService attendanceService;
  late PaymentService paymentService;
  late TuitionService tuitionService;
  late SessionAdjustmentService adjustmentService;
  late ClassRepository classRepo;
  late StudentRepository studentRepo;
  late MembershipRepository membershipRepo;
  late SessionRepository sessionRepo;
  late AttendanceRepository attendanceRepo;
  late TuitionRepository tuitionRepo;
  late PaymentRepository paymentRepo;
  late SessionAdjustmentRepository adjustmentRepo;
  late String nowStr;

  setUp(() async {
    nowStr = DateTime.now().toIso8601String();
    final tempDir = await Directory.systemTemp.createTemp('report_test');
    final dbPath = join(
      tempDir.path,
      'test_${DateTime.now().microsecondsSinceEpoch}.db',
    );
    final appDb = AppDatabase(dbName: dbPath);
    db = await appDb.database;

    classRepo = ClassRepository(db);
    studentRepo = StudentRepository(db);
    membershipRepo = MembershipRepository(db);
    sessionRepo = SessionRepository(db);
    attendanceRepo = AttendanceRepository(db);
    tuitionRepo = TuitionRepository(db);
    paymentRepo = PaymentRepository(db);
    adjustmentRepo = SessionAdjustmentRepository(db);

    final membershipService = MembershipService(membershipRepo);
    final classService = ClassService(classRepo, membershipService);
    final studentService = StudentService(studentRepo, membershipService);
    final sessionService = SessionService(sessionRepo, classService);
    final scheduleRepo = ScheduleRepository(db);
    final assignmentRepo = AssignmentRepository(db);

    final constraintRepo = ScheduleConstraintRepository(db);
    final conflictService = ScheduleConflictService(
      constraintRepo,
      scheduleRepo,
      assignmentRepo,
      sessionRepo,
      adjustmentRepo,
      classService,
    );
    final scheduleDomainService = ScheduleDomainService(
      scheduleRepo,
      assignmentRepo,
      membershipService,
      classService,
      studentService,
      conflictService,
    );

    final rosterService = RosterService(
      sessionService,
      membershipService,
      scheduleDomainService,
      studentService,
      adjustmentRepo,
    );

    final leaveRepo = LeaveRequestRepository(db);
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

    paymentService = PaymentService(paymentRepo, tuitionRepo, db);

    final policyRepo = TuitionPolicyRepository(db);
    final creditRepo = SessionCreditRepository(db);
    final policyService = TuitionPolicyService(
      policyRepo,
      classService,
      tuitionRepo,
      creditRepo,
      db,
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

    tuitionService = TuitionService(
      tuitionRepo,
      policyService,
      creditService,
      membershipService,
      attendanceRepo,
      adjustmentRepo,
      sessionRepo,
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

    reportService = ReportService(
      classService,
      studentService,
      membershipService,
      sessionService,
      attendanceService,
      tuitionService,
      paymentService,
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('ReportScope Strict Validation & Date Matrix Tests', () {
    test('ReportScope accepts valid leap-day 2028-02-29 and month bounds', () {
      final leapScope = ReportScope.customRange(
        fromDate: '2028-02-01',
        toDate: '2028-02-29',
      );
      expect(leapScope.fromDate, equals('2028-02-01'));
      expect(leapScope.toDate, equals('2028-02-29'));

      final janScope = ReportScope.forMonth(month: '2026-01');
      expect(janScope.fromDate, equals('2026-01-01'));
      expect(janScope.toDate, equals('2026-01-31'));

      final decScope = ReportScope.forMonth(month: '2026-12');
      expect(decScope.fromDate, equals('2026-12-01'));
      expect(decScope.toDate, equals('2026-12-31'));
    });

    test(
      'ReportScope rejects invalid month string formats (e.g. 2026-13, 2026-00, 26-09)',
      () {
        expect(
          () => ReportScope.forMonth(month: '2026-13'),
          throwsArgumentError,
        );
        expect(
          () => ReportScope.forMonth(month: '2026-00'),
          throwsArgumentError,
        );
        expect(() => ReportScope.forMonth(month: '26-09'), throwsArgumentError);
        expect(() => ReportScope.forMonth(month: 'abc'), throwsArgumentError);
      },
    );

    test(
      'ReportScope rejects invalid date string formats (e.g. 2026-02-30, 2026-2-01, abc)',
      () {
        expect(
          () => ReportScope.customRange(
            fromDate: '2026-02-30',
            toDate: '2026-03-01',
          ),
          throwsArgumentError,
        );
        expect(
          () => ReportScope.customRange(
            fromDate: '2026-2-01',
            toDate: '2026-03-01',
          ),
          throwsArgumentError,
        );
        expect(
          () => ReportScope.customRange(fromDate: 'abc', toDate: '2026-03-01'),
          throwsArgumentError,
        );
      },
    );

    test('ReportScope rejects fromDate > toDate', () {
      expect(
        () => ReportScope.customRange(
          fromDate: '2026-10-15',
          toDate: '2026-10-10',
        ),
        throwsArgumentError,
      );
    });
  });

  group('Completed Session Filtering & 4-Status Matrix Tests', () {
    test(
      'ReportService includes only DA_HOC completed sessions and excludes DU_KIEN, HUY, NGHI_LE',
      () async {
        final cId = await classRepo.create(
          ClassEntity(
            tenLop: 'Class Alpha',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
        final stId = await studentRepo.create(
          Student(
            hoTen: 'Student A',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
        await membershipRepo.create(
          ClassMembership(
            idHocSinh: stId,
            idLop: cId,
            tuNgay: '2026-01-01',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        final schedId = await db.insert('lich_hoc', {
          'id_lop': cId,
          'thu_trong_tuan': 1, // Monday
          'gio_bat_dau': '08:00',
          'gio_ket_thuc': '09:30',
          'hieu_luc_tu': '2026-01-01',
          'created_at': nowStr,
          'updated_at': nowStr,
        });

        // 1. DA_HOC session -> INCLUDED
        final sCompleted = await sessionRepo.create(
          ClassSession(
            idLop: cId,
            idLichHoc: schedId,
            ngay: '2026-10-05',
            gioBatDau: '08:00',
            gioKetThuc: '09:30',
            loai: SessionType.CHINH,
            trangThai: SessionStatus.DA_HOC,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        // 2. DU_KIEN session -> EXCLUDED
        await sessionRepo.create(
          ClassSession(
            idLop: cId,
            idLichHoc: schedId,
            ngay: '2026-10-12',
            gioBatDau: '08:00',
            gioKetThuc: '09:30',
            loai: SessionType.CHINH,
            trangThai: SessionStatus.DU_KIEN,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        // 3. HUY session -> EXCLUDED
        await sessionRepo.create(
          ClassSession(
            idLop: cId,
            idLichHoc: schedId,
            ngay: '2026-10-19',
            gioBatDau: '08:00',
            gioKetThuc: '09:30',
            loai: SessionType.CHINH,
            trangThai: SessionStatus.HUY,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        // 4. NGHI_LE session -> EXCLUDED
        await sessionRepo.create(
          ClassSession(
            idLop: cId,
            idLichHoc: schedId,
            ngay: '2026-10-26',
            gioBatDau: '08:00',
            gioKetThuc: '09:30',
            loai: SessionType.CHINH,
            trangThai: SessionStatus.NGHI_LE,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        await attendanceService.saveDraft(
          sCompleted,
          {stId: AttendanceState.TRE}, // Late attendance
        );

        final scope = ReportScope.forMonth(month: '2026-10');
        final report = await reportService.generateReport(scope);

        // Verify only DA_HOC contributed (totalSessions == 1, totalLate == 1, totalPresent == 1)
        expect(report.attendance.totalSessions, equals(1));
        expect(report.attendance.totalEligibleParticipations, equals(1));
        expect(report.attendance.totalPresent, equals(1));
        expect(report.attendance.totalLate, equals(1));
      },
    );

    test(
      'True Cross-Module Consistency: Report attendance facts match direct AttendanceService sheet facts',
      () async {
        final cId = await classRepo.create(
          ClassEntity(
            tenLop: 'Class Beta',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
        final stId = await studentRepo.create(
          Student(
            hoTen: 'Student B',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
        await membershipRepo.create(
          ClassMembership(
            idHocSinh: stId,
            idLop: cId,
            tuNgay: '2026-01-01',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        final schedId = await db.insert('lich_hoc', {
          'id_lop': cId,
          'thu_trong_tuan': 1,
          'gio_bat_dau': '08:00',
          'gio_ket_thuc': '09:30',
          'hieu_luc_tu': '2026-01-01',
          'created_at': nowStr,
          'updated_at': nowStr,
        });

        final s1 = await sessionRepo.create(
          ClassSession(
            idLop: cId,
            idLichHoc: schedId,
            ngay: '2026-10-05',
            gioBatDau: '08:00',
            gioKetThuc: '09:30',
            loai: SessionType.CHINH,
            trangThai: SessionStatus.DA_HOC,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        await attendanceService.saveDraft(s1, {stId: AttendanceState.CO_MAT});

        final directSheet = await attendanceService.getAttendanceForSession(s1);
        final memberState = directSheet.members.first.state;

        final report = await reportService.generateReport(
          ReportScope.forMonth(month: '2026-10'),
        );

        expect(memberState.countsAsPresent, isTrue);
        expect(report.attendance.totalPresent, equals(1));
        expect(
          report.attendance.totalEligibleParticipations,
          equals(directSheet.members.length),
        );
      },
    );
  });

  group('Canonical Adjustments (DOI_CA, HOC_BU, PHAT_SINH) Integration Tests', () {
    test(
      'DOI_CA adjustment via SessionAdjustmentService reflects target participation without double counting',
      () async {
        final cId = await classRepo.create(
          ClassEntity(
            tenLop: 'Class DoiCa',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
        final stId = await studentRepo.create(
          Student(
            hoTen: 'Student DoiCa',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        await membershipRepo.create(
          ClassMembership(
            idHocSinh: stId,
            idLop: cId,
            tuNgay: '2026-01-01',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        final sched1Id = await db.insert('lich_hoc', {
          'id_lop': cId,
          'thu_trong_tuan': 1,
          'gio_bat_dau': '08:00',
          'gio_ket_thuc': '09:30',
          'hieu_luc_tu': '2026-01-01',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
        final sched2Id = await db.insert('lich_hoc', {
          'id_lop': cId,
          'thu_trong_tuan': 1,
          'gio_bat_dau': '10:00',
          'gio_ket_thuc': '11:30',
          'hieu_luc_tu': '2026-01-01',
          'created_at': nowStr,
          'updated_at': nowStr,
        });

        // Assign student to schedule 1
        await db.insert('phan_ca_hoc_sinh', {
          'id_hoc_sinh': stId,
          'id_lop': cId,
          'id_lich_hoc': sched1Id,
          'tu_ngay': '2026-01-01',
          'created_at': nowStr,
          'updated_at': nowStr,
        });

        final origSession = await sessionRepo.create(
          ClassSession(
            idLop: cId,
            idLichHoc: sched1Id,
            ngay: '2026-10-05',
            gioBatDau: '08:00',
            gioKetThuc: '09:30',
            loai: SessionType.CHINH,
            trangThai: SessionStatus.DU_KIEN,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
        final targetSession = await sessionRepo.create(
          ClassSession(
            idLop: cId,
            idLichHoc: sched2Id,
            ngay: '2026-10-05',
            gioBatDau: '10:00',
            gioKetThuc: '11:30',
            loai: SessionType.CHINH,
            trangThai: SessionStatus.DU_KIEN,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        // Create DOI_CA adjustment
        await adjustmentService.createDoiCa(
          studentId: stId,
          originalSessionId: origSession,
          targetSessionId: targetSession,
        );

        // Mark target session as completed (DA_HOC) and save CO_MAT attendance
        await db.update(
          'buoi_hoc',
          {'trang_thai': 'DA_HOC'},
          where: 'id = ?',
          whereArgs: [targetSession],
        );
        await attendanceService.saveDraft(targetSession, {
          stId: AttendanceState.CO_MAT,
        });

        final report = await reportService.generateReport(
          ReportScope.forMonth(month: '2026-10'),
        );

        // Verify student participated only in target session (1 participation, 1 present, 0 double count)
        expect(report.attendance.totalEligibleParticipations, equals(1));
        expect(report.attendance.totalPresent, equals(1));
      },
    );

    test(
      'HOC_BU adjustment via SessionAdjustmentService counts make-up attendance correctly',
      () async {
        final c1 = await classRepo.create(
          ClassEntity(
            tenLop: 'Class 1 Orig',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
        final c2 = await classRepo.create(
          ClassEntity(
            tenLop: 'Class 2 Target',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        final stId = await studentRepo.create(
          Student(
            hoTen: 'Student HocBu',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        await membershipRepo.create(
          ClassMembership(
            idHocSinh: stId,
            idLop: c1,
            tuNgay: '2026-01-01',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        final sched1 = await db.insert('lich_hoc', {
          'id_lop': c1,
          'thu_trong_tuan': 1,
          'gio_bat_dau': '08:00',
          'gio_ket_thuc': '09:30',
          'hieu_luc_tu': '2026-01-01',
          'created_at': nowStr,
          'updated_at': nowStr,
        });

        // Original session DA_HOC where student was absent (NGHI_CO_PHEP)
        final origSession = await sessionRepo.create(
          ClassSession(
            idLop: c1,
            idLichHoc: sched1,
            ngay: '2026-10-05',
            gioBatDau: '08:00',
            gioKetThuc: '09:30',
            loai: SessionType.CHINH,
            trangThai: SessionStatus.DA_HOC,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
        await attendanceService.saveDraft(origSession, {
          stId: AttendanceState.NGHI_CO_PHEP,
        });

        // Target HOC_BU session
        final targetSession = await sessionRepo.create(
          ClassSession(
            idLop: c2,
            ngay: '2026-10-10',
            gioBatDau: '17:30',
            gioKetThuc: '19:00',
            loai: SessionType.HOC_BU,
            trangThai: SessionStatus.DU_KIEN,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        // Create HOC_BU adjustment
        await adjustmentService.createHocBu(
          studentId: stId,
          originalSessionId: origSession,
          targetSessionId: targetSession,
        );

        // Mark target session as completed (DA_HOC) and save HOC_BU attendance
        await db.update(
          'buoi_hoc',
          {'trang_thai': 'DA_HOC'},
          where: 'id = ?',
          whereArgs: [targetSession],
        );
        await attendanceService.saveDraft(targetSession, {
          stId: AttendanceState.HOC_BU,
        });

        final report = await reportService.generateReport(
          ReportScope.forMonth(month: '2026-10'),
        );

        // Total participations: 1 orig (NGHI_CO_PHEP) + 1 target (HOC_BU counts as present)
        expect(report.attendance.totalEligibleParticipations, equals(2));
        expect(report.attendance.totalPresent, equals(1));
        expect(report.attendance.totalExcusedAbsence, equals(1));
      },
    );

    test(
      'PHAT_SINH adjustment via SessionAdjustmentService includes student in target session roster',
      () async {
        final c1 = await classRepo.create(
          ClassEntity(
            tenLop: 'Class 1 Home',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
        final c2 = await classRepo.create(
          ClassEntity(
            tenLop: 'Class 2 Target',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        final stId = await studentRepo.create(
          Student(
            hoTen: 'Student PhatSinh',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        await membershipRepo.create(
          ClassMembership(
            idHocSinh: stId,
            idLop: c1,
            tuNgay: '2026-01-01',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        // Target PHAT_SINH session in Class 2
        final targetSession = await sessionRepo.create(
          ClassSession(
            idLop: c2,
            ngay: '2026-10-15',
            gioBatDau: '17:30',
            gioKetThuc: '19:00',
            loai: SessionType.PHAT_SINH,
            trangThai: SessionStatus.DU_KIEN,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        // Create PHAT_SINH adjustment
        await adjustmentService.createPhatSinh(
          studentId: stId,
          originalClassId: c1,
          targetSessionId: targetSession,
        );

        // Mark target session as completed (DA_HOC) and save CO_MAT attendance
        await db.update(
          'buoi_hoc',
          {'trang_thai': 'DA_HOC'},
          where: 'id = ?',
          whereArgs: [targetSession],
        );
        await attendanceService.saveDraft(targetSession, {
          stId: AttendanceState.CO_MAT,
        });

        final report = await reportService.generateReport(
          ReportScope.forMonth(month: '2026-10'),
        );

        expect(report.attendance.totalEligibleParticipations, equals(1));
        expect(report.attendance.totalPresent, equals(1));
      },
    );
  });

  group('Payment Timing Regression & Financial Invariants Tests', () {
    test(
      'Payment timing assertion: Month A invoice paid in Month B reflects obligation in A and cash revenue in B',
      () async {
        final cId = await classRepo.create(
          ClassEntity(
            tenLop: 'Class Gamma',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
        await db.insert('chinh_sach_hoc_phi', {
          'id': cId,
          'id_lop': cId,
          'hieu_luc_tu': '2026-01-01',
          'so_buoi_chuan_thang': 12,
          'hoc_phi_moi_buoi': 100000,
          'created_at': nowStr,
          'updated_at': nowStr,
        });
        final stId = await studentRepo.create(
          Student(
            hoTen: 'Student C',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
        await membershipRepo.create(
          ClassMembership(
            idHocSinh: stId,
            idLop: cId,
            tuNgay: '2026-01-01',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        await tuitionRepo.insertInvoice(
          TuitionInvoice(
            idHocSinh: stId,
            idLop: cId,
            thang: '2026-10',
            idChinhSachHocPhi: cId,
            soBuoiEligible: 4,
            soBuoiTinhPhi: 4,
            creditOpening: 0,
            creditEarned: 0,
            creditUsed: 0,
            creditClosing: 0,
            tongTruocGiam: 1000000,
            giamPhanTram: 0,
            giamSoTien: 0,
            soTienPhaiThu: 1000000,
            trangThai: TuitionInvoiceStatus.DA_CHOT,
            chotLuc: DateTime.now(),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        // Record payment in Month B (2026-11-05) for 1,000,000 VND
        await paymentService.recordPayment(
          studentId: stId,
          classId: cId,
          month: '2026-10',
          amount: 1000000,
          paymentDate: '2026-11-05',
          method: PaymentMethod.TIEN_MAT,
        );

        // October Report: Obligation = 1,000,000, Revenue = 0 (paid in Nov), Debt = 0 (invoice paid)
        final reportOct = await reportService.generateReport(
          ReportScope.forMonth(month: '2026-10'),
        );
        expect(reportOct.financial.totalInvoiced, equals(1000000));
        expect(reportOct.financial.totalPaid, equals(0));
        expect(reportOct.financial.totalOutstandingDebt, equals(0));

        // November Report: Obligation = 0, Revenue = 1,000,000 (cash received in Nov), Debt = 0
        final reportNov = await reportService.generateReport(
          ReportScope.forMonth(month: '2026-11'),
        );
        expect(reportNov.financial.totalInvoiced, equals(0));
        expect(reportNov.financial.totalPaid, equals(1000000));
        expect(reportNov.financial.totalOutstandingDebt, equals(0));
      },
    );

    test(
      'Sum of Class Summaries equals total overall Summary (Invariants test)',
      () async {
        final c1 = await classRepo.create(
          ClassEntity(
            tenLop: 'Class 1',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
        final c2 = await classRepo.create(
          ClassEntity(
            tenLop: 'Class 2',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        await db.insert('chinh_sach_hoc_phi', {
          'id': c1,
          'id_lop': c1,
          'hieu_luc_tu': '2026-01-01',
          'so_buoi_chuan_thang': 12,
          'hoc_phi_moi_buoi': 100000,
          'created_at': nowStr,
          'updated_at': nowStr,
        });
        await db.insert('chinh_sach_hoc_phi', {
          'id': c2,
          'id_lop': c2,
          'hieu_luc_tu': '2026-01-01',
          'so_buoi_chuan_thang': 12,
          'hoc_phi_moi_buoi': 100000,
          'created_at': nowStr,
          'updated_at': nowStr,
        });

        final st1 = await studentRepo.create(
          Student(
            hoTen: 'Student 1',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
        final st2 = await studentRepo.create(
          Student(
            hoTen: 'Student 2',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        await membershipRepo.create(
          ClassMembership(
            idHocSinh: st1,
            idLop: c1,
            tuNgay: '2026-01-01',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
        await membershipRepo.create(
          ClassMembership(
            idHocSinh: st2,
            idLop: c2,
            tuNgay: '2026-01-01',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        await tuitionRepo.insertInvoice(
          TuitionInvoice(
            idHocSinh: st1,
            idLop: c1,
            thang: '2026-10',
            idChinhSachHocPhi: c1,
            soBuoiEligible: 4,
            soBuoiTinhPhi: 4,
            creditOpening: 0,
            creditEarned: 0,
            creditUsed: 0,
            creditClosing: 0,
            tongTruocGiam: 500000,
            giamPhanTram: 0,
            giamSoTien: 0,
            soTienPhaiThu: 500000,
            trangThai: TuitionInvoiceStatus.DA_CHOT,
            chotLuc: DateTime.now(),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        await tuitionRepo.insertInvoice(
          TuitionInvoice(
            idHocSinh: st2,
            idLop: c2,
            thang: '2026-10',
            idChinhSachHocPhi: c2,
            soBuoiEligible: 4,
            soBuoiTinhPhi: 4,
            creditOpening: 0,
            creditEarned: 0,
            creditUsed: 0,
            creditClosing: 0,
            tongTruocGiam: 800000,
            giamPhanTram: 0,
            giamSoTien: 0,
            soTienPhaiThu: 800000,
            trangThai: TuitionInvoiceStatus.DA_CHOT,
            chotLuc: DateTime.now(),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        await paymentService.recordPayment(
          studentId: st1,
          classId: c1,
          month: '2026-10',
          amount: 300000,
          paymentDate: '2026-10-15',
          method: PaymentMethod.TIEN_MAT,
        );

        final report = await reportService.generateReport(
          ReportScope.forMonth(month: '2026-10'),
        );

        final sumInvoiced = report.classSummaries.fold(
          0,
          (sum, c) => sum + c.financial.totalInvoiced,
        );
        final sumPaid = report.classSummaries.fold(
          0,
          (sum, c) => sum + c.financial.totalPaid,
        );
        final sumDebt = report.classSummaries.fold(
          0,
          (sum, c) => sum + c.financial.totalOutstandingDebt,
        );

        expect(report.financial.totalInvoiced, equals(sumInvoiced));
        expect(report.financial.totalPaid, equals(sumPaid));
        expect(report.financial.totalOutstandingDebt, equals(sumDebt));
      },
    );
  });

  group('Financial Corruption Matrix Tests', () {
    test(
      'Missing Invoice Corruption: Payment referencing non-existing invoice ID throws Exception in ReportService',
      () async {
        await db.execute('PRAGMA foreign_keys = OFF');
        await paymentRepo.insert(
          Payment(
            invoiceId: 99999, // Non-existent invoice ID
            studentId: 1,
            classId: 1,
            month: '2026-10',
            amount: 500000,
            paymentDate: '2026-10-15',
            method: PaymentMethod.TIEN_MAT,
            createdAt: DateTime.now(),
          ),
        );
        await db.execute('PRAGMA foreign_keys = ON');

        expect(
          () => reportService.generateReport(
            ReportScope.forMonth(month: '2026-10'),
          ),
          throwsException,
        );
      },
    );

    test(
      'Relationship Mismatch Corruption: Payment classId does not match invoice classId throws Exception',
      () async {
        final cId = await classRepo.create(
          ClassEntity(
            tenLop: 'Class Real',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
        await db.insert('chinh_sach_hoc_phi', {
          'id': cId,
          'id_lop': cId,
          'hieu_luc_tu': '2026-01-01',
          'so_buoi_chuan_thang': 12,
          'hoc_phi_moi_buoi': 100000,
          'created_at': nowStr,
          'updated_at': nowStr,
        });
        final stId = await studentRepo.create(
          Student(
            hoTen: 'Student Real',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        final invId = await tuitionRepo.insertInvoice(
          TuitionInvoice(
            idHocSinh: stId,
            idLop: cId,
            thang: '2026-10',
            idChinhSachHocPhi: cId,
            soBuoiEligible: 4,
            soBuoiTinhPhi: 4,
            creditOpening: 0,
            creditEarned: 0,
            creditUsed: 0,
            creditClosing: 0,
            tongTruocGiam: 500000,
            giamPhanTram: 0,
            giamSoTien: 0,
            soTienPhaiThu: 500000,
            trangThai: TuitionInvoiceStatus.DA_CHOT,
            chotLuc: DateTime.now(),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        await db.execute('PRAGMA foreign_keys = OFF');
        await paymentRepo.insert(
          Payment(
            invoiceId: invId,
            studentId: stId,
            classId: 9999, // Wrong classId!
            month: '2026-10',
            amount: 500000,
            paymentDate: '2026-10-15',
            method: PaymentMethod.TIEN_MAT,
            createdAt: DateTime.now(),
          ),
        );
        await db.execute('PRAGMA foreign_keys = ON');

        expect(
          () => reportService.generateReport(
            ReportScope.forMonth(month: '2026-10'),
          ),
          throwsException,
        );
      },
    );

    test(
      'Financial corruption fail-closed: Corrupted invoice status throws exception in ReportService',
      () async {
        final cId = await classRepo.create(
          ClassEntity(
            tenLop: 'Class Delta',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
        await db.insert('chinh_sach_hoc_phi', {
          'id': cId,
          'id_lop': cId,
          'hieu_luc_tu': '2026-01-01',
          'so_buoi_chuan_thang': 12,
          'hoc_phi_moi_buoi': 100000,
          'created_at': nowStr,
          'updated_at': nowStr,
        });
        final stId = await studentRepo.create(
          Student(
            hoTen: 'Student D',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
        await membershipRepo.create(
          ClassMembership(
            idHocSinh: stId,
            idLop: cId,
            tuNgay: '2026-01-01',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        final invId = await tuitionRepo.insertInvoice(
          TuitionInvoice(
            idHocSinh: stId,
            idLop: cId,
            thang: '2026-10',
            idChinhSachHocPhi: cId,
            soBuoiEligible: 4,
            soBuoiTinhPhi: 4,
            creditOpening: 0,
            creditEarned: 0,
            creditUsed: 0,
            creditClosing: 0,
            tongTruocGiam: 1000000,
            giamPhanTram: 0,
            giamSoTien: 0,
            soTienPhaiThu: 1000000,
            trangThai:
                TuitionInvoiceStatus.DA_CHOT, // Status says DA_CHOT (unpaid)
            chotLuc: DateTime.now(),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        await paymentRepo.insert(
          Payment(
            invoiceId: invId,
            studentId: stId,
            classId: cId,
            month: '2026-10',
            amount: 1000000, // Fully paid!
            paymentDate: '2026-10-15',
            method: PaymentMethod.TIEN_MAT,
            createdAt: DateTime.now(),
          ),
        );

        expect(
          () => reportService.generateReport(
            ReportScope.forMonth(month: '2026-10'),
          ),
          throwsException,
        );
      },
    );
  });

  group('Historical Archived Entity Filtering Tests', () {
    test(
      'Relevant archived entities with scope activity ARE included, unrelated archived entities WITHOUT activity ARE excluded',
      () async {
        // Archived Class 1 with activity
        final cActiveArchived = await classRepo.create(
          ClassEntity(
            tenLop: 'Archived Class Active',
            daLuuTru: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
        // Archived Class 2 with NO activity
        await classRepo.create(
          ClassEntity(
            tenLop: 'Archived Class Unrelated',
            daLuuTru: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        // Archived Student 1 with activity
        final stActiveArchived = await studentRepo.create(
          Student(
            hoTen: 'Archived Student Active',
            daLuuTru: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
        // Archived Student 2 with NO activity
        await studentRepo.create(
          Student(
            hoTen: 'Archived Student Unrelated',
            daLuuTru: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        await membershipRepo.create(
          ClassMembership(
            idHocSinh: stActiveArchived,
            idLop: cActiveArchived,
            tuNgay: '2026-01-01',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        await db.insert('chinh_sach_hoc_phi', {
          'id': cActiveArchived,
          'id_lop': cActiveArchived,
          'hieu_luc_tu': '2026-01-01',
          'so_buoi_chuan_thang': 12,
          'hoc_phi_moi_buoi': 100000,
          'created_at': nowStr,
          'updated_at': nowStr,
        });

        await tuitionRepo.insertInvoice(
          TuitionInvoice(
            idHocSinh: stActiveArchived,
            idLop: cActiveArchived,
            thang: '2026-10',
            idChinhSachHocPhi: cActiveArchived,
            soBuoiEligible: 4,
            soBuoiTinhPhi: 4,
            creditOpening: 0,
            creditEarned: 0,
            creditUsed: 0,
            creditClosing: 0,
            tongTruocGiam: 600000,
            giamPhanTram: 0,
            giamSoTien: 0,
            soTienPhaiThu: 600000,
            trangThai: TuitionInvoiceStatus.DA_CHOT,
            chotLuc: DateTime.now(),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        final report = await reportService.generateReport(
          ReportScope.forMonth(month: '2026-10'),
        );

        // Assert active archived class and student are INCLUDED
        expect(
          report.classSummaries.any(
            (c) => c.className == 'Archived Class Active',
          ),
          isTrue,
        );
        expect(
          report.studentSummaries.any(
            (s) => s.studentName == 'Archived Student Active',
          ),
          isTrue,
        );

        // Assert unrelated archived class and student without activity are EXCLUDED
        expect(
          report.classSummaries.any(
            (c) => c.className == 'Archived Class Unrelated',
          ),
          isFalse,
        );
        expect(
          report.studentSummaries.any(
            (s) => s.studentName == 'Archived Student Unrelated',
          ),
          isFalse,
        );
      },
    );
  });
}
