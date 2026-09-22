import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:tuition2027/core/database/app_database.dart';
import 'package:tuition2027/features/attendance/data/attendance_repository.dart';
import 'package:tuition2027/features/classes/data/class_repository.dart';
import 'package:tuition2027/features/classes/domain/class_service.dart';
import 'package:tuition2027/features/memberships/data/membership_repository.dart';
import 'package:tuition2027/features/memberships/domain/membership_service.dart';
import 'package:tuition2027/features/payments/data/payment_repository.dart';
import 'package:tuition2027/features/payments/domain/payment_method.dart';
import 'package:tuition2027/features/payments/domain/payment_service.dart';
import 'package:tuition2027/features/roster/domain/roster_service.dart';
import 'package:tuition2027/features/schedule/data/assignment_repository.dart';
import 'package:tuition2027/features/schedule/data/schedule_repository.dart';
import 'package:tuition2027/features/schedule/domain/schedule_service.dart';
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
import 'package:tuition2027/features/tuition/domain/tuition_invoice.dart';
import 'package:tuition2027/features/tuition/domain/tuition_policy_service.dart';
import 'package:tuition2027/features/tuition/domain/tuition_service.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('PaymentService Domain Tests', () {
    late Database db;
    late PaymentService paymentService;
    late InvoiceService invoiceService;
    late TuitionPolicyService policyService;
    late MembershipService membershipService;
    late PaymentRepository paymentRepo;
    late TuitionRepository tuitionRepo;

    setUp(() async {
      final tempDir = await Directory.systemTemp.createTemp('payment_test');
      final dbPath = join(tempDir.path, 'payment_test.db');
      final appDb = AppDatabase(dbName: dbPath);
      db = await appDb.database;

      final studentRepo = StudentRepository(db);
      final classRepo = ClassRepository(db);
      final memberRepo = MembershipRepository(db);
      final scheduleRepo = ScheduleRepository(db);
      final assignRepo = AssignmentRepository(db);
      final sessionRepo = SessionRepository(db);
      final attRepo = AttendanceRepository(db);
      final adjRepo = SessionAdjustmentRepository(db);
      final creditRepo = SessionCreditRepository(db);
      final policyRepo = TuitionPolicyRepository(db);
      tuitionRepo = TuitionRepository(db);
      paymentRepo = PaymentRepository(db);

      membershipService = MembershipService(memberRepo);
      final studentService = StudentService(studentRepo, membershipService);
      final classService = ClassService(classRepo, membershipService);
      policyService = TuitionPolicyService(
        policyRepo,
        classService,
        tuitionRepo,
        creditRepo,
        db,
      );

      final sessionService = SessionService(sessionRepo, classService);
      final scheduleService = ScheduleDomainService(
        scheduleRepo,
        assignRepo,
        membershipService,
        classService,
        studentService,
      );
      final rosterService = RosterService(
        sessionService,
        membershipService,
        scheduleService,
        studentService,
        adjRepo,
      );

      final creditService = SessionCreditService(
        creditRepo,
        sessionService,
        rosterService,
        attRepo,
        studentService,
        classService,
        policyService,
      );

      final tuitionService = TuitionService(
        tuitionRepo,
        policyService,
        creditService,
        membershipService,
        attRepo,
        adjRepo,
        sessionRepo,
      );

      invoiceService = InvoiceService(
        tuitionRepo,
        tuitionService,
        creditService,
        creditRepo,
        membershipService,
        db,
      );

      paymentService = PaymentService(paymentRepo, tuitionRepo, db);

      // Seed Student & Class
      await db.execute('''
        INSERT INTO hoc_sinh (id, ho_ten, sdt_phu_huynh, created_at, updated_at)
        VALUES (1, 'Student 1', '0901234567', '2026-01-01T00:00:00.000', '2026-01-01T00:00:00.000')
      ''');

      await db.execute('''
        INSERT INTO lop (id, ten_lop, created_at, updated_at)
        VALUES (1, 'Class 1', '2026-01-01T00:00:00.000', '2026-01-01T00:00:00.000')
      ''');

      for (int w = 1; w <= 7; w++) {
        await db.insert('lich_hoc', {
          'id': w,
          'id_lop': 1,
          'thu_trong_tuan': w,
          'gio_bat_dau': '17:30',
          'gio_ket_thuc': '19:00',
          'hieu_luc_tu': '2026-01-01',
          'created_at': '2026-01-01T00:00:00.000',
          'updated_at': '2026-01-01T00:00:00.000',
        });
      }

      await membershipService.enrollStudent(
        studentId: 1,
        classId: 1,
        joinDate: DateTime.parse('2026-01-01'),
      );

      await policyService.createPolicy(
        classId: 1,
        effectiveFrom: '2026-01-01',
        feePerSession: 50000,
        standardSessionsPerMonth: 12,
      );

      // Add 12 attended sessions for Sep 2026
      for (int i = 1; i <= 12; i++) {
        final dayStr = i < 10 ? '0$i' : '$i';
        final dateStr = '2026-09-$dayStr';
        final dt = DateTime.parse(dateStr);
        await db.execute('''
          INSERT INTO buoi_hoc (id, id_lop, id_lich_hoc, ngay, gio_bat_dau, gio_ket_thuc, loai, trang_thai, created_at, updated_at)
          VALUES ($i, 1, ${dt.weekday}, '$dateStr', '17:30', '19:00', 'CHINH', 'DA_HOC', '2026-01-01T00:00:00.000', '2026-01-01T00:00:00.000')
        ''');
        await db.execute('''
          INSERT INTO diem_danh (id_buoi_hoc, id_hoc_sinh, id_lop_goc, trang_thai, created_at, updated_at)
          VALUES ($i, 1, 1, 'CO_MAT', '2026-01-01T00:00:00.000', '2026-01-01T00:00:00.000')
        ''');
      }

      // Finalize invoice: 12 sessions * 50,000 = 600,000
      await invoiceService.finalizeStudentInvoice(1, 1, '2026-09');
    });

    tearDown(() async {
      await db.close();
    });

    test('Test A: One full payment settles invoice to DA_THANH_TOAN', () async {
      final payment = await paymentService.recordPayment(
        studentId: 1,
        classId: 1,
        month: '2026-09',
        amount: 600000,
        paymentDate: '2026-09-15',
        method: PaymentMethod.CHUYEN_KHOAN,
        transactionId: 'TX001',
      );

      expect(payment.id, isNotNull);
      expect(payment.amount, 600000);

      final summary = await paymentService.getPaymentSummary(1, 1, '2026-09');
      expect(summary?.totalPaid, 600000);
      expect(summary?.remainingDebt, 0);
      expect(summary?.settlementStatus, TuitionInvoiceStatus.DA_THANH_TOAN);

      final updatedInvoice = await tuitionRepo.getInvoice(1, 1, '2026-09');
      expect(updatedInvoice?.trangThai, TuitionInvoiceStatus.DA_THANH_TOAN);
    });

    test('Test B: Split payments settle invoice correctly', () async {
      // Payment 1: 300k
      await paymentService.recordPayment(
        studentId: 1,
        classId: 1,
        month: '2026-09',
        amount: 300000,
        paymentDate: '2026-09-10',
        method: PaymentMethod.TIEN_MAT,
      );

      var summary = await paymentService.getPaymentSummary(1, 1, '2026-09');
      expect(summary?.totalPaid, 300000);
      expect(summary?.remainingDebt, 300000);
      expect(summary?.settlementStatus, TuitionInvoiceStatus.CON_NO);

      // Payment 2: 200k
      await paymentService.recordPayment(
        studentId: 1,
        classId: 1,
        month: '2026-09',
        amount: 200000,
        paymentDate: '2026-09-15',
        method: PaymentMethod.CHUYEN_KHOAN,
        transactionId: 'TX002',
      );

      summary = await paymentService.getPaymentSummary(1, 1, '2026-09');
      expect(summary?.totalPaid, 500000);
      expect(summary?.remainingDebt, 100000);
      expect(summary?.settlementStatus, TuitionInvoiceStatus.CON_NO);

      // Payment 3: 100k
      await paymentService.recordPayment(
        studentId: 1,
        classId: 1,
        month: '2026-09',
        amount: 100000,
        paymentDate: '2026-09-20',
        method: PaymentMethod.TIEN_MAT,
      );

      summary = await paymentService.getPaymentSummary(1, 1, '2026-09');
      expect(summary?.totalPaid, 600000);
      expect(summary?.remainingDebt, 0);
      expect(summary?.paymentCount, 3);
      expect(summary?.settlementStatus, TuitionInvoiceStatus.DA_THANH_TOAN);
    });

    test('Test D: Duplicate transaction ID is rejected', () async {
      await paymentService.recordPayment(
        studentId: 1,
        classId: 1,
        month: '2026-09',
        amount: 200000,
        paymentDate: '2026-09-10',
        method: PaymentMethod.CHUYEN_KHOAN,
        transactionId: 'BANK_123',
      );

      expect(
        () => paymentService.recordPayment(
          studentId: 1,
          classId: 1,
          month: '2026-09',
          amount: 200000,
          paymentDate: '2026-09-11',
          method: PaymentMethod.CHUYEN_KHOAN,
          transactionId: 'BANK_123',
        ),
        throwsA(isA<Exception>()),
      );

      final summary = await paymentService.getPaymentSummary(1, 1, '2026-09');
      expect(summary?.totalPaid, 200000);
    });

    test(
      'Test E: Overpayment is rejected and existing paid balance remains',
      () async {
        await paymentService.recordPayment(
          studentId: 1,
          classId: 1,
          month: '2026-09',
          amount: 500000,
          paymentDate: '2026-09-10',
          method: PaymentMethod.TIEN_MAT,
        );

        // Attempting 150k on 600k invoice (500k already paid, remaining 100k) is REJECTED!
        expect(
          () => paymentService.recordPayment(
            studentId: 1,
            classId: 1,
            month: '2026-09',
            amount: 150000,
            paymentDate: '2026-09-15',
            method: PaymentMethod.CHUYEN_KHOAN,
          ),
          throwsA(isA<Exception>()),
        );

        final summary = await paymentService.getPaymentSummary(1, 1, '2026-09');
        expect(summary?.totalPaid, 500000);
        expect(summary?.remainingDebt, 100000);
      },
    );

    test('Test F: Payment on NHAP draft invoice is rejected', () async {
      expect(
        () => paymentService.recordPayment(
          studentId: 1,
          classId: 1,
          month: '2026-10', // Draft month without finalized invoice
          amount: 100000,
          paymentDate: '2026-10-01',
          method: PaymentMethod.TIEN_MAT,
        ),
        throwsA(isA<Exception>()),
      );
    });

    test(
      'Test G: Further payment on fully paid DA_THANH_TOAN invoice is rejected',
      () async {
        await paymentService.recordPayment(
          studentId: 1,
          classId: 1,
          month: '2026-09',
          amount: 600000,
          paymentDate: '2026-09-15',
          method: PaymentMethod.CHUYEN_KHOAN,
        );

        expect(
          () => paymentService.recordPayment(
            studentId: 1,
            classId: 1,
            month: '2026-09',
            amount: 50000,
            paymentDate: '2026-09-16',
            method: PaymentMethod.TIEN_MAT,
          ),
          throwsA(isA<Exception>()),
        );
      },
    );

    test(
      'Test K & L: Multiple cash payments with null transaction ID are allowed',
      () async {
        await paymentService.recordPayment(
          studentId: 1,
          classId: 1,
          month: '2026-09',
          amount: 200000,
          paymentDate: '2026-09-10',
          method: PaymentMethod.TIEN_MAT,
          transactionId: null,
        );

        await paymentService.recordPayment(
          studentId: 1,
          classId: 1,
          month: '2026-09',
          amount: 200000,
          paymentDate: '2026-09-11',
          method: PaymentMethod.TIEN_MAT,
          transactionId: '',
        );

        final summary = await paymentService.getPaymentSummary(1, 1, '2026-09');
        expect(summary?.totalPaid, 400000);
        expect(summary?.paymentCount, 2);
      },
    );

    test('Test M & N: Amount <= 0 is rejected', () async {
      expect(
        () => paymentService.recordPayment(
          studentId: 1,
          classId: 1,
          month: '2026-09',
          amount: 0,
          paymentDate: '2026-09-10',
          method: PaymentMethod.TIEN_MAT,
        ),
        throwsA(isA<Exception>()),
      );

      expect(
        () => paymentService.recordPayment(
          studentId: 1,
          classId: 1,
          month: '2026-09',
          amount: -50000,
          paymentDate: '2026-09-10',
          method: PaymentMethod.TIEN_MAT,
        ),
        throwsA(isA<Exception>()),
      );
    });

    test(
      'Test Snapshot Immutability: Payment does not mutate Phase 9 invoice fields',
      () async {
        final beforeInvoice = (await tuitionRepo.getInvoice(1, 1, '2026-09'))!;

        await paymentService.recordPayment(
          studentId: 1,
          classId: 1,
          month: '2026-09',
          amount: 300000,
          paymentDate: '2026-09-15',
          method: PaymentMethod.TIEN_MAT,
        );

        final afterInvoice = (await tuitionRepo.getInvoice(1, 1, '2026-09'))!;

        expect(afterInvoice.idChinhSachHocPhi, beforeInvoice.idChinhSachHocPhi);
        expect(afterInvoice.soBuoiEligible, beforeInvoice.soBuoiEligible);
        expect(afterInvoice.soBuoiTinhPhi, beforeInvoice.soBuoiTinhPhi);
        expect(afterInvoice.creditOpening, beforeInvoice.creditOpening);
        expect(afterInvoice.creditEarned, beforeInvoice.creditEarned);
        expect(afterInvoice.creditUsed, beforeInvoice.creditUsed);
        expect(afterInvoice.creditClosing, beforeInvoice.creditClosing);
        expect(afterInvoice.tongTruocGiam, beforeInvoice.tongTruocGiam);
        expect(afterInvoice.giamPhanTram, beforeInvoice.giamPhanTram);
        expect(afterInvoice.giamSoTien, beforeInvoice.giamSoTien);
        expect(afterInvoice.soTienPhaiThu, beforeInvoice.soTienPhaiThu);
        expect(afterInvoice.chotLuc, beforeInvoice.chotLuc);
        expect(afterInvoice.trangThai, TuitionInvoiceStatus.CON_NO);
      },
    );
  });
}
