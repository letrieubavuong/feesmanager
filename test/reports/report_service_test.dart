import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' hide equals;
import 'package:tuition2027/core/database/app_database.dart';
import 'package:tuition2027/features/attendance/data/attendance_repository.dart';
import 'package:tuition2027/features/attendance/domain/attendance_record.dart';
import 'package:tuition2027/features/classes/data/class_repository.dart';
import 'package:tuition2027/features/classes/domain/class.dart';
import 'package:tuition2027/features/classes/domain/class_service.dart';
import 'package:tuition2027/features/memberships/data/membership_repository.dart';
import 'package:tuition2027/features/memberships/domain/membership.dart';
import 'package:tuition2027/features/memberships/domain/membership_service.dart';
import 'package:tuition2027/features/payments/data/payment_repository.dart';
import 'package:tuition2027/features/payments/domain/payment.dart';
import 'package:tuition2027/features/payments/domain/payment_method.dart';
import 'package:tuition2027/features/reports/domain/report_scope.dart';
import 'package:tuition2027/features/reports/domain/report_service.dart';
import 'package:tuition2027/features/roster/domain/roster_service.dart';
import 'package:tuition2027/features/schedule/data/assignment_repository.dart';
import 'package:tuition2027/features/schedule/data/schedule_repository.dart';
import 'package:tuition2027/features/schedule/domain/schedule_service.dart';
import 'package:tuition2027/features/schedule_conflicts/data/schedule_constraint_repository.dart';
import 'package:tuition2027/features/schedule_conflicts/domain/schedule_conflict_service.dart';
import 'package:tuition2027/features/session_adjustments/data/session_adjustment_repository.dart';
import 'package:tuition2027/features/sessions/data/session_repository.dart';
import 'package:tuition2027/features/sessions/domain/class_session.dart';
import 'package:tuition2027/features/sessions/domain/session_service.dart';
import 'package:tuition2027/features/students/data/student_repository.dart';
import 'package:tuition2027/features/students/domain/student.dart';
import 'package:tuition2027/features/students/domain/student_service.dart';
import 'package:tuition2027/features/tuition/data/tuition_repository.dart';
import 'package:tuition2027/features/tuition/domain/tuition_invoice.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database db;
  late ReportService reportService;
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

    reportService = ReportService(
      classService,
      studentService,
      membershipService,
      sessionRepo,
      rosterService,
      attendanceRepo,
      tuitionRepo,
      paymentRepo,
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('ReportScope Domain Validation & Equivalence Tests', () {
    test('ReportScope.forMonth generates correct explicit date bounds', () {
      final scope = ReportScope.forMonth(month: '2026-10');
      expect(scope.mode, equals(ReportMode.month));
      expect(scope.fromDate, equals('2026-10-01'));
      expect(scope.toDate, equals('2026-10-31'));
    });

    test('ReportScope rejects fromDate > toDate', () {
      expect(
        () => ReportScope.customRange(
          fromDate: '2026-10-15',
          toDate: '2026-10-10',
        ),
        throwsArgumentError,
      );
    });

    test(
      'Month scope and equivalent custom range produce identical report outputs',
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

        final monthScope = ReportScope.forMonth(month: '2026-10');
        final customScope = ReportScope.customRange(
          fromDate: '2026-10-01',
          toDate: '2026-10-31',
        );

        final monthReport = await reportService.generateReport(monthScope);
        final customReport = await reportService.generateReport(customScope);

        expect(
          monthReport.attendance.totalEligibleSessions,
          equals(customReport.attendance.totalEligibleSessions),
        );
        expect(
          monthReport.financial.totalInvoiced,
          equals(customReport.financial.totalInvoiced),
        );
        expect(
          monthReport.financial.totalPaid,
          equals(customReport.financial.totalPaid),
        );
        expect(
          monthReport.financial.totalOutstandingDebt,
          equals(customReport.financial.totalOutstandingDebt),
        );
      },
    );
  });

  group('Canonical Cross-Module Consistency & Financial Invariant Tests', () {
    test(
      'Boundary test: events exactly on fromDate/toDate included, before/after excluded',
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

        // Create schedule & assignment for single shift membership roster
        await db.insert('lich_hoc', {
          'id': 10,
          'id_lop': cId,
          'thu_trong_tuan': 1,
          'gio_bat_dau': '08:00',
          'gio_ket_thuc': '09:30',
          'hieu_luc_tu': '2026-01-01',
          'created_at': nowStr,
          'updated_at': nowStr,
        });

        // Session 1: exactly on fromDate 2026-10-05 -> INCLUDED
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
        // Session 2: exactly on toDate 2026-10-19 -> INCLUDED
        final s2 = await sessionRepo.create(
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
        // Session 3: before fromDate 2026-10-01 -> EXCLUDED
        await sessionRepo.create(
          ClassSession(
            idLop: cId,
            idLichHoc: 10,
            ngay: '2026-10-01',
            gioBatDau: '08:00',
            gioKetThuc: '09:30',
            loai: SessionType.CHINH,
            trangThai: SessionStatus.DA_HOC,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
        // Session 4: after toDate 2026-10-25 -> EXCLUDED
        await sessionRepo.create(
          ClassSession(
            idLop: cId,
            idLichHoc: 10,
            ngay: '2026-10-25',
            gioBatDau: '08:00',
            gioKetThuc: '09:30',
            loai: SessionType.CHINH,
            trangThai: SessionStatus.DA_HOC,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        await attendanceRepo.upsert(
          AttendanceRecord(
            idBuoiHoc: s1,
            idHocSinh: stId,
            idLopGoc: cId,
            trangThai: AttendanceStatus.CO_MAT,
            loaiThamGia: AttendanceParticipationType.CHINH,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
        await attendanceRepo.upsert(
          AttendanceRecord(
            idBuoiHoc: s2,
            idHocSinh: stId,
            idLopGoc: cId,
            trangThai: AttendanceStatus.NGHI_CO_PHEP,
            loaiThamGia: AttendanceParticipationType.CHINH,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        final scope = ReportScope.customRange(
          fromDate: '2026-10-05',
          toDate: '2026-10-19',
        );

        final report = await reportService.generateReport(scope);
        expect(report.attendance.totalEligibleSessions, equals(2));
        expect(report.attendance.totalPresent, equals(1));
        expect(report.attendance.totalExcusedAbsence, equals(1));
        expect(report.attendance.totalUnexcusedAbsence, equals(0));
      },
    );

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

        // Finalized Invoice in Month A (2026-10) for 1,000,000 VND
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
            trangThai: TuitionInvoiceStatus.DA_CHOT,
            chotLuc: DateTime.now(),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        // Payment recorded in Month B (2026-11-05) for 1,000,000 VND
        await paymentRepo.insert(
          Payment(
            invoiceId: invId,
            studentId: stId,
            classId: cId,
            month: '2026-10',
            amount: 1000000,
            paymentDate: '2026-11-05',
            method: PaymentMethod.TIEN_MAT,
            createdAt: DateTime.now(),
          ),
        );

        // Report for Month A (2026-10): Invoiced = 1,000,000, Revenue = 0 (paid in B), Outstanding Debt = 0 (invoice is paid)
        final reportA = await reportService.generateReport(
          ReportScope.forMonth(month: '2026-10'),
        );
        expect(reportA.financial.totalInvoiced, equals(1000000));
        expect(
          reportA.financial.totalPaid,
          equals(0),
        ); // Cash revenue received in Oct = 0
        expect(
          reportA.financial.totalOutstandingDebt,
          equals(0),
        ); // Inv paid in Nov so remaining debt = 0

        // Report for Month B (2026-11): Invoiced = 0, Revenue = 1,000,000 (cash received in Nov), Outstanding Debt = 0
        final reportB = await reportService.generateReport(
          ReportScope.forMonth(month: '2026-11'),
        );
        expect(reportB.financial.totalInvoiced, equals(0));
        expect(
          reportB.financial.totalPaid,
          equals(1000000),
        ); // Cash revenue received in Nov = 1,000,000
        expect(reportB.financial.totalOutstandingDebt, equals(0));
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

        final inv1 = await tuitionRepo.insertInvoice(
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

        await paymentRepo.insert(
          Payment(
            invoiceId: inv1,
            studentId: st1,
            classId: c1,
            month: '2026-10',
            amount: 300000,
            paymentDate: '2026-10-15',
            method: PaymentMethod.TIEN_MAT,
            createdAt: DateTime.now(),
          ),
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
}
