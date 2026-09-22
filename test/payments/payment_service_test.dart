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

  group('PaymentService Hardened Domain Tests', () {
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

      // Verify persisted status on disk
      final updatedInvoice = await tuitionRepo.getInvoice(1, 1, '2026-09');
      expect(updatedInvoice?.trangThai, TuitionInvoiceStatus.DA_THANH_TOAN);
    });

    test(
      'Test B: Split payments settle invoice correctly and verify persisted status',
      () async {
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
        expect(
          (await tuitionRepo.getInvoice(1, 1, '2026-09'))?.trangThai,
          TuitionInvoiceStatus.CON_NO,
        );

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
        expect(
          (await tuitionRepo.getInvoice(1, 1, '2026-09'))?.trangThai,
          TuitionInvoiceStatus.CON_NO,
        );

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
        expect(
          (await tuitionRepo.getInvoice(1, 1, '2026-09'))?.trangThai,
          TuitionInvoiceStatus.DA_THANH_TOAN,
        );
      },
    );

    test(
      'Real Concurrent Payment Test: 400k + 400k on 600k invoice with Future.wait',
      () async {
        // Launch truly concurrent payment requests using Future.wait
        int successCount = 0;
        int errorCount = 0;

        await Future.wait([
          paymentService
              .recordPayment(
                studentId: 1,
                classId: 1,
                month: '2026-09',
                amount: 400000,
                paymentDate: '2026-09-10',
                method: PaymentMethod.TIEN_MAT,
              )
              .then((_) => successCount++)
              .catchError((_) => errorCount++),
          paymentService
              .recordPayment(
                studentId: 1,
                classId: 1,
                month: '2026-09',
                amount: 400000,
                paymentDate: '2026-09-10',
                method: PaymentMethod.TIEN_MAT,
              )
              .then((_) => successCount++)
              .catchError((_) => errorCount++),
        ]);

        expect(successCount, 1);
        expect(errorCount, 1);

        final summary = await paymentService.getPaymentSummary(1, 1, '2026-09');
        expect(summary?.totalPaid, 400000);
        expect(summary?.remainingDebt, 200000);
        expect(summary?.settlementStatus, TuitionInvoiceStatus.CON_NO);
        expect(
          (await tuitionRepo.getInvoice(1, 1, '2026-09'))?.trangThai,
          TuitionInvoiceStatus.CON_NO,
        );
      },
    );

    test(
      'Real Concurrent Payment Test: 300k + 300k on 600k invoice with Future.wait',
      () async {
        await Future.wait([
          paymentService.recordPayment(
            studentId: 1,
            classId: 1,
            month: '2026-09',
            amount: 300000,
            paymentDate: '2026-09-10',
            method: PaymentMethod.TIEN_MAT,
          ),
          paymentService.recordPayment(
            studentId: 1,
            classId: 1,
            month: '2026-09',
            amount: 300000,
            paymentDate: '2026-09-10',
            method: PaymentMethod.CHUYEN_KHOAN,
          ),
        ]);

        final summary = await paymentService.getPaymentSummary(1, 1, '2026-09');
        expect(summary?.totalPaid, 600000);
        expect(summary?.remainingDebt, 0);
        expect(summary?.paymentCount, 2);
        expect(summary?.settlementStatus, TuitionInvoiceStatus.DA_THANH_TOAN);
        expect(
          (await tuitionRepo.getInvoice(1, 1, '2026-09'))?.trangThai,
          TuitionInvoiceStatus.DA_THANH_TOAN,
        );
      },
    );

    test(
      'Real Concurrent Duplicate Transaction ID Test with Future.wait',
      () async {
        int successCount = 0;
        int errorCount = 0;

        await Future.wait([
          paymentService
              .recordPayment(
                studentId: 1,
                classId: 1,
                month: '2026-09',
                amount: 200000,
                paymentDate: '2026-09-10',
                method: PaymentMethod.CHUYEN_KHOAN,
                transactionId: 'BANK_DUP_001',
              )
              .then((_) => successCount++)
              .catchError((_) => errorCount++),
          paymentService
              .recordPayment(
                studentId: 1,
                classId: 1,
                month: '2026-09',
                amount: 200000,
                paymentDate: '2026-09-10',
                method: PaymentMethod.CHUYEN_KHOAN,
                transactionId: 'BANK_DUP_001',
              )
              .then((_) => successCount++)
              .catchError((_) => errorCount++),
        ]);

        expect(successCount, 1);
        expect(errorCount, 1);

        final summary = await paymentService.getPaymentSummary(1, 1, '2026-09');
        expect(summary?.totalPaid, 200000);
        expect(summary?.paymentCount, 1);
      },
    );

    test('Deliberate Rollback Test using SQLite Trigger', () async {
      await db.execute('''
        CREATE TRIGGER force_rollback_test
        BEFORE UPDATE ON hoc_phi_thang
        BEGIN
          SELECT RAISE(ABORT, 'forced payment rollback');
        END;
      ''');

      expect(
        () => paymentService.recordPayment(
          studentId: 1,
          classId: 1,
          month: '2026-09',
          amount: 300000,
          paymentDate: '2026-09-15',
          method: PaymentMethod.TIEN_MAT,
        ),
        throwsA(isA<DatabaseException>()),
      );

      // Verify payment row was NOT persisted
      final payments = await paymentRepo.getPaymentsForInvoice(1);
      expect(payments, isEmpty);

      // Verify invoice status remains DA_CHOT
      final invoice = await tuitionRepo.getInvoice(1, 1, '2026-09');
      expect(invoice?.trangThai, TuitionInvoiceStatus.DA_CHOT);
    });

    test(
      'Fail Closed on Corrupt Overpayment: 700k payments on 600k invoice throws exception',
      () async {
        await db.execute('''
        INSERT INTO thanh_toan (id_hoc_sinh, id_lop, id_hoc_phi_thang, thang, so_tien, ngay_thanh_toan, phuong_thuc, created_at)
        VALUES (1, 1, 1, '2026-09', 700000, '2026-09-15', 'TIEN_MAT', '2026-09-15T10:00:00')
      ''');

        expect(
          () => paymentService.getPaymentSummary(1, 1, '2026-09'),
          throwsA(isA<Exception>()),
        );
      },
    );

    test(
      'Fail Closed on Mismatched Student/Class/Month in Payment Row',
      () async {
        // Seed Student 2 so FK passes
        await db.execute('''
        INSERT INTO hoc_sinh (id, ho_ten, sdt_phu_huynh, created_at, updated_at)
        VALUES (2, 'Student 2', '0901234568', '2026-01-01T00:00:00.000', '2026-01-01T00:00:00.000')
      ''');

        // Direct raw DB insertion of payment linked to invoice 1 but with mismatched student ID 2
        await db.execute('''
        INSERT INTO thanh_toan (id_hoc_sinh, id_lop, id_hoc_phi_thang, thang, so_tien, ngay_thanh_toan, phuong_thuc, created_at)
        VALUES (2, 1, 1, '2026-09', 100000, '2026-09-15', 'TIEN_MAT', '2026-09-15T10:00:00')
      ''');

        expect(
          () => paymentService.getPaymentSummary(1, 1, '2026-09'),
          throwsA(isA<Exception>()),
        );
      },
    );

    test('Fail Closed on Persisted Status Mismatch', () async {
      // Invoice claims DA_THANH_TOAN on DB, but payments total = 0!
      await db.execute('''
        UPDATE hoc_phi_thang SET trang_thai = 'DA_THANH_TOAN' WHERE id = 1
      ''');

      expect(
        () => paymentService.getPaymentSummary(1, 1, '2026-09'),
        throwsA(isA<Exception>()),
      );
    });

    test('Test F: Payment on NHAP draft invoice is REJECTED', () async {
      // Insert an actual NHAP invoice in DB
      await db.execute('''
        INSERT INTO hoc_phi_thang (id, id_hoc_sinh, id_lop, thang, id_chinh_sach_hoc_phi, so_buoi_eligible, so_buoi_tinh_phi, credit_opening, credit_earned, credit_used, credit_closing, tong_truoc_giam, so_tien_phai_thu, trang_thai, created_at, updated_at)
        VALUES (99, 1, 1, '2026-10', 1, 12, 12, 0, 0, 0, 0, 600000, 600000, 'NHAP', '2026-10-01', '2026-10-01')
      ''');

      expect(
        () => paymentService.recordPayment(
          studentId: 1,
          classId: 1,
          month: '2026-10',
          amount: 100000,
          paymentDate: '2026-10-01',
          method: PaymentMethod.TIEN_MAT,
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('Zero-Due Invoice Test: soTienPhaiThu = 0', () async {
      await db.execute('''
        INSERT INTO hoc_phi_thang (id, id_hoc_sinh, id_lop, thang, id_chinh_sach_hoc_phi, so_buoi_eligible, so_buoi_tinh_phi, credit_opening, credit_earned, credit_used, credit_closing, tong_truoc_giam, so_tien_phai_thu, trang_thai, created_at, updated_at)
        VALUES (88, 1, 1, '2026-11', 1, 0, 0, 0, 0, 0, 0, 0, 0, 'DA_CHOT', '2026-11-01', '2026-11-01')
      ''');

      final summary = await paymentService.getPaymentSummary(1, 1, '2026-11');
      expect(summary?.amountDue, 0);
      expect(summary?.totalPaid, 0);
      expect(summary?.remainingDebt, 0);

      expect(
        () => paymentService.recordPayment(
          studentId: 1,
          classId: 1,
          month: '2026-11',
          amount: 50000,
          paymentDate: '2026-11-01',
          method: PaymentMethod.TIEN_MAT,
        ),
        throwsA(isA<Exception>()),
      );
    });

    test(
      'Missing Validation Tests: Student, Class, Month, Date Mismatch',
      () async {
        // Wrong student ID
        expect(
          () => paymentService.recordPayment(
            studentId: 999,
            classId: 1,
            month: '2026-09',
            amount: 100000,
            paymentDate: '2026-09-15',
            method: PaymentMethod.TIEN_MAT,
          ),
          throwsA(isA<Exception>()),
        );

        // Wrong class ID
        expect(
          () => paymentService.recordPayment(
            studentId: 1,
            classId: 999,
            month: '2026-09',
            amount: 100000,
            paymentDate: '2026-09-15',
            method: PaymentMethod.TIEN_MAT,
          ),
          throwsA(isA<Exception>()),
        );

        // Invalid date format
        expect(
          () => paymentService.recordPayment(
            studentId: 1,
            classId: 1,
            month: '2026-09',
            amount: 100000,
            paymentDate: '15/09/2026',
            method: PaymentMethod.TIEN_MAT,
          ),
          throwsA(isA<Exception>()),
        );
      },
    );

    test('Blank Transaction ID and Note are normalized to NULL', () async {
      final payment = await paymentService.recordPayment(
        studentId: 1,
        classId: 1,
        month: '2026-09',
        amount: 100000,
        paymentDate: '2026-09-15',
        method: PaymentMethod.TIEN_MAT,
        transactionId: '   ',
        note: '   ',
      );

      expect(payment.transactionId, isNull);
      expect(payment.note, isNull);
    });

    test(
      'Deterministic Payment History Ordering Test: sorted by ngay_thanh_toan DESC, id DESC',
      () async {
        await paymentService.recordPayment(
          studentId: 1,
          classId: 1,
          month: '2026-09',
          amount: 100000,
          paymentDate: '2026-09-10',
          method: PaymentMethod.TIEN_MAT,
        );

        await paymentService.recordPayment(
          studentId: 1,
          classId: 1,
          month: '2026-09',
          amount: 100000,
          paymentDate: '2026-09-20',
          method: PaymentMethod.TIEN_MAT,
        );

        final payments = await paymentRepo.getPaymentsForInvoice(1);
        expect(payments.length, 2);
        expect(payments.first.paymentDate, '2026-09-20');
        expect(payments.last.paymentDate, '2026-09-10');
      },
    );
  });
}
