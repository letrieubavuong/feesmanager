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
import 'package:tuition2027/features/session_adjustments/domain/session_adjustment.dart';
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

  group('Student-Filtered & Entity-Specific Session Count Tests', () {
    test(
      'Student filter report counts only distinct sessions where selected student was eligible',
      () async {
        final cId = await classRepo.create(
          ClassEntity(
            tenLop: 'Class Alpha',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
        final stX = await studentRepo.create(
          Student(
            hoTen: 'Student X',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
        final stY = await studentRepo.create(
          Student(
            hoTen: 'Student Y',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        // Student Y active full month; Student X membership starts 2026-10-10 (eligible only for sessions on/after Oct 10)
        await membershipRepo.create(
          ClassMembership(
            idHocSinh: stY,
            idLop: cId,
            tuNgay: '2026-01-01',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
        await membershipRepo.create(
          ClassMembership(
            idHocSinh: stX,
            idLop: cId,
            tuNgay: '2026-10-10',
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

        // 2 Sessions before Oct 10 (Student Y only)
        final s1 = await sessionRepo.create(
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
        await attendanceService.saveDraft(s1, {stY: AttendanceState.CO_MAT});

        // 3 Sessions on/after Oct 10 (Both Student Y and Student X)
        final s2 = await sessionRepo.create(
          ClassSession(
            idLop: cId,
            idLichHoc: 10,
            ngay: '2026-10-12',
            gioBatDau: '08:00',
            gioKetThuc: '09:30',
            loai: SessionType.CHINH,
            trangThai: SessionStatus.DA_HOC,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
        final s3 = await sessionRepo.create(
          ClassSession(
            idLop: cId,
            idLichHoc: 10,
            ngay: '2026-10-19',
            gioBatDau: '08:00',
            gioKetThuc: '09:30',
            loai: SessionType.CHINH,
            trangThai: SessionStatus.DA_HOC,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
        final s4 = await sessionRepo.create(
          ClassSession(
            idLop: cId,
            idLichHoc: 10,
            ngay: '2026-10-26',
            gioBatDau: '08:00',
            gioKetThuc: '09:30',
            loai: SessionType.CHINH,
            trangThai: SessionStatus.DA_HOC,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        await attendanceService.saveDraft(s2, {
          stY: AttendanceState.CO_MAT,
          stX: AttendanceState.CO_MAT,
        });
        await attendanceService.saveDraft(s3, {
          stY: AttendanceState.CO_MAT,
          stX: AttendanceState.CO_MAT,
        });
        await attendanceService.saveDraft(s4, {
          stY: AttendanceState.CO_MAT,
          stX: AttendanceState.CO_MAT,
        });

        // Report filtered by Student X -> totalSessions MUST be 3 (not 4)
        final reportScopeX = ReportScope.forMonth(
          month: '2026-10',
          studentId: stX,
        );
        final reportX = await reportService.generateReport(reportScopeX);

        expect(reportX.attendance.totalSessions, equals(3));
        expect(reportX.attendance.totalEligibleParticipations, equals(3));
        expect(
          reportX.studentSummaries.first.attendance.totalSessions,
          equals(3),
        );
      },
    );

    test(
      'Multi-class student transition reflects range-overlapping classes without duplicate totals',
      () async {
        final cA = await classRepo.create(
          ClassEntity(
            tenLop: 'Class A',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
        final cB = await classRepo.create(
          ClassEntity(
            tenLop: 'Class B',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
        final cC = await classRepo.create(
          ClassEntity(
            tenLop: 'Class C (Historical)',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        final stId = await studentRepo.create(
          Student(
            hoTen: 'Student Multi',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        // Membership Class A (until 2026-10-15)
        await membershipRepo.create(
          ClassMembership(
            idHocSinh: stId,
            idLop: cA,
            tuNgay: '2026-01-01',
            denNgay: '2026-10-15',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
        // Membership Class B (from 2026-10-16)
        await membershipRepo.create(
          ClassMembership(
            idHocSinh: stId,
            idLop: cB,
            tuNgay: '2026-10-16',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
        // Membership Class C (expired in 2025 - outside scope!)
        await membershipRepo.create(
          ClassMembership(
            idHocSinh: stId,
            idLop: cC,
            tuNgay: '2025-01-01',
            denNgay: '2025-12-31',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        final report = await reportService.generateReport(
          ReportScope.forMonth(month: '2026-10', studentId: stId),
        );

        final stSummary = report.studentSummaries.first;
        expect(stSummary.enrolledClassNames, contains('Class A'));
        expect(stSummary.enrolledClassNames, contains('Class B'));
        expect(
          stSummary.enrolledClassNames,
          isNot(contains('Class C (Historical)')),
        );
      },
    );
  });

  group('One-Off Adjustments (DOI_CA, HOC_BU, PHAT_SINH) Integration Tests', () {
    test(
      'DOI_CA adjustment reflects attendance in target session without double counting original session',
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
            trangThai: SessionStatus.DA_HOC,
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
            trangThai: SessionStatus.DA_HOC,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        // Create DOI_CA adjustment
        await adjustmentRepo.create(
          SessionAdjustment(
            idHocSinh: stId,
            idLopGoc: cId,
            idBuoiHocGoc: origSession,
            idBuoiHocThamGia: targetSession,
            loai: SessionAdjustmentType.DOI_CA,
            createdAt: DateTime.now(),
          ),
        );

        // Save attendance in target session
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
  });

  group('Financial Cross-Module Settlement & Corruption Fail-Closed Tests', () {
    test(
      'True Cross-Module Consistency: Report financial settlement matches PaymentService settlement',
      () async {
        final cId = await classRepo.create(
          ClassEntity(
            tenLop: 'Class Financial',
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
            hoTen: 'Student Financial',
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

        await paymentService.recordPayment(
          studentId: stId,
          classId: cId,
          month: '2026-10',
          amount: 400000,
          paymentDate: '2026-10-15',
          method: PaymentMethod.TIEN_MAT,
        );

        final directInvoices = await tuitionService
            .getFinalizedInvoicesInMonthRange(
              fromMonth: '2026-10',
              toMonth: '2026-10',
            );
        final directSummaries = await paymentService
            .getPaymentSummariesForInvoices(directInvoices);
        final directDebt = directSummaries.first.remainingDebt;

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
