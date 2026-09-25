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
  late ClassRepository classRepo;
  late StudentRepository studentRepo;
  late MembershipRepository membershipRepo;
  late SessionRepository sessionRepo;
  late AttendanceRepository attendanceRepo;
  late TuitionRepository tuitionRepo;
  late PaymentRepository paymentRepo;
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

    final membershipService = MembershipService(membershipRepo);
    final classService = ClassService(classRepo, membershipService);
    final studentService = StudentService(studentRepo, membershipService);
    final sessionService = SessionService(sessionRepo, classService);
    final scheduleRepo = ScheduleRepository(db);
    final assignmentRepo = AssignmentRepository(db);
    final adjustmentRepo = SessionAdjustmentRepository(db);

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

    reportService = ReportService(
      classService,
      studentService,
      membershipService,
      sessionService,
      rosterService,
      attendanceService,
      tuitionService,
      paymentService,
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('ReportScope Strict Validation Tests', () {
    test(
      'ReportScope.forMonth generates correct explicit date bounds for YYYY-MM',
      () {
        final scope = ReportScope.forMonth(month: '2026-10');
        expect(scope.mode, equals(ReportMode.month));
        expect(scope.fromDate, equals('2026-10-01'));
        expect(scope.toDate, equals('2026-10-31'));
      },
    );

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

  group('Completed Session Filtering & Attendance Canonical Consistency Tests', () {
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

        await db.insert('lich_hoc', {
          'id': 10,
          'id_lop': cId,
          'thu_trong_tuan': 1, // Monday
          'gio_bat_dau': '08:00',
          'gio_ket_thuc': '09:30',
          'hieu_luc_tu': '2026-01-01',
          'created_at': nowStr,
          'updated_at': nowStr,
        });

        // 1. DA_HOC Completed session -> INCLUDED
        final sCompleted = await sessionRepo.create(
          ClassSession(
            idLop: cId,
            idLichHoc: 10,
            ngay: '2026-10-05',
            gioBatDau: '08:00',
            gioKetThuc: '09:30',
            loai: SessionType.CHINH,
            trangThai: SessionStatus.DA_HOC,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        // 2. DU_KIEN session -> EXCLUDED from completed attendance opportunities
        await sessionRepo.create(
          ClassSession(
            idLop: cId,
            idLichHoc: 10,
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
            idLichHoc: 10,
            ngay: '2026-10-19',
            gioBatDau: '08:00',
            gioKetThuc: '09:30',
            loai: SessionType.CHINH,
            trangThai: SessionStatus.HUY,
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

        // Verify totalSessions == 1 (only DA_HOC), totalLate == 1, totalPresent == 1
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

        await db.insert('lich_hoc', {
          'id': 20,
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
            idLichHoc: 20,
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

        // Call canonical AttendanceService directly to get expected sheet facts
        final directSheet = await attendanceService.getAttendanceForSession(s1);
        final memberState = directSheet.members.first.state;

        // Call ReportService to get report summary facts
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

  group('Financial Cross-Module Settlement & Corruption Fail-Closed Tests', () {
    test(
      'True Cross-Module Consistency: Report financial settlement matches PaymentService settlement',
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

        // Record payment via canonical PaymentService
        await paymentService.recordPayment(
          studentId: stId,
          classId: cId,
          month: '2026-10',
          amount: 400000,
          paymentDate: '2026-10-15',
          method: PaymentMethod.TIEN_MAT,
        );

        // Call direct PaymentService settlement summary
        final directInvoices = await tuitionService
            .getFinalizedInvoicesInMonthRange(
              fromMonth: '2026-10',
              toMonth: '2026-10',
            );
        final directSummaries = await paymentService
            .getPaymentSummariesForInvoices(directInvoices);
        final directDebt = directSummaries.first.remainingDebt;

        // Call ReportService
        final report = await reportService.generateReport(
          ReportScope.forMonth(month: '2026-10'),
        );

        expect(
          report.financial.totalInvoiced,
          equals(directSummaries.first.amountDue),
        );
        expect(report.financial.totalPaid, equals(400000));
        expect(report.financial.totalOutstandingDebt, equals(directDebt));
        expect(report.financial.totalOutstandingDebt, equals(600000));
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

        // Insert invoice with status DA_CHOT (0 paid), but insert FULL payment directly in DB without updating invoice status (corrupted state!)
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

        // ReportService MUST fail closed by throwing Exception on corrupted status
        expect(
          () => reportService.generateReport(
            ReportScope.forMonth(month: '2026-10'),
          ),
          throwsException,
        );
      },
    );

    test(
      'Historical archived class and archived student with scope activity ARE included in report summaries',
      () async {
        // Create archived class with historical activity
        final cArchivedId = await classRepo.create(
          ClassEntity(
            tenLop: 'Archived Class 101',
            daLuuTru: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
        await db.insert('chinh_sach_hoc_phi', {
          'id': cArchivedId,
          'id_lop': cArchivedId,
          'hieu_luc_tu': '2026-01-01',
          'so_buoi_chuan_thang': 12,
          'hoc_phi_moi_buoi': 100000,
          'created_at': nowStr,
          'updated_at': nowStr,
        });

        // Create archived student with historical activity
        final stArchivedId = await studentRepo.create(
          Student(
            hoTen: 'Archived Student X',
            daLuuTru: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        await membershipRepo.create(
          ClassMembership(
            idHocSinh: stArchivedId,
            idLop: cArchivedId,
            tuNgay: '2026-01-01',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        await tuitionRepo.insertInvoice(
          TuitionInvoice(
            idHocSinh: stArchivedId,
            idLop: cArchivedId,
            thang: '2026-10',
            idChinhSachHocPhi: cArchivedId,
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

        // Assert archived class and archived student appear in report summaries
        expect(
          report.classSummaries.any((c) => c.className == 'Archived Class 101'),
          isTrue,
        );
        expect(
          report.studentSummaries.any(
            (s) => s.studentName == 'Archived Student X',
          ),
          isTrue,
        );
        expect(report.financial.totalInvoiced, equals(600000));
      },
    );
  });
}
