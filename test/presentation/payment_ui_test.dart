import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:tuition2027/core/database/app_database.dart';
import 'package:tuition2027/core/database/database_provider.dart';
import 'package:tuition2027/features/memberships/presentation/membership_providers.dart';
import 'package:tuition2027/features/payments/domain/invoice_payment_summary.dart';
import 'package:tuition2027/features/payments/domain/payment.dart';
import 'package:tuition2027/features/payments/domain/payment_method.dart';
import 'package:tuition2027/features/payments/presentation/payment_controller.dart';
import 'package:tuition2027/features/students/domain/student.dart';
import 'package:tuition2027/features/students/presentation/student_detail_page.dart';
import 'package:tuition2027/features/tuition/domain/tuition_invoice.dart';
import 'package:tuition2027/features/tuition/presentation/class_tuition_tab.dart';
import 'package:tuition2027/features/tuition/presentation/tuition_controller.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('Payment UI Tests', () {
    late Database db;

    setUp(() async {
      final tempDir = await Directory.systemTemp.createTemp('payment_ui_test');
      final dbPath = join(tempDir.path, 'payment_ui_test.db');
      final appDb = AppDatabase(dbName: dbPath);
      db = await appDb.database;
    });

    tearDown(() async {
      await db.close();
    });

    testWidgets(
      'ClassTuitionTab renders payment summary and action buttons for CON_NO invoice',
      (tester) async {
        final testStudent = Student(
          id: 1,
          hoTen: 'Debt Student',
          sdtPhuHuynh: '0901234567',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final nowMonth = DateTime.now().toString().substring(0, 7);

        final testInvoice = TuitionInvoice(
          id: 1,
          idHocSinh: 1,
          idLop: 1,
          thang: nowMonth,
          idChinhSachHocPhi: 1,
          soBuoiEligible: 12,
          soBuoiTinhPhi: 12,
          creditOpening: 0,
          creditEarned: 0,
          creditUsed: 0,
          creditClosing: 0,
          tongTruocGiam: 600000,
          giamPhanTram: 0,
          giamSoTien: 0,
          soTienPhaiThu: 600000,
          trangThai: TuitionInvoiceStatus.CON_NO,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final testPayment = Payment(
          id: 1,
          studentId: 1,
          classId: 1,
          invoiceId: 1,
          month: nowMonth,
          amount: 300000,
          paymentDate: '$nowMonth-10',
          method: PaymentMethod.CHUYEN_KHOAN,
          transactionId: 'TX001',
          createdAt: DateTime.now(),
        );

        final testSummary = InvoicePaymentSummary.calculate(
          invoice: testInvoice,
          payments: [testPayment],
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              databaseProvider.overrideWith((ref) async => db),
              classTuitionPoliciesProvider(1).overrideWith((ref) async => []),
              effectiveTuitionPolicyProvider((
                1,
                nowMonth,
              )).overrideWith((ref) async => null),
              classMonthStudentsProvider((
                1,
                nowMonth,
              )).overrideWith((ref) async => [testStudent]),
              studentDetailProvider(1).overrideWith((ref) async => testStudent),
              classMonthInvoicesProvider((
                1,
                nowMonth,
              )).overrideWith((ref) async => [testInvoice]),
              studentInvoiceProvider(
                1,
                1,
                nowMonth,
              ).overrideWith((ref) async => testInvoice),
              invoicePaymentSummaryProvider((
                1,
                1,
                nowMonth,
              )).overrideWith((ref) async => testSummary),
              classMonthPaymentSummariesProvider((
                1,
                nowMonth,
              )).overrideWith((ref) async => {1: testSummary}),
            ],
            child: const MaterialApp(
              home: Scaffold(body: ClassTuitionTab(classId: 1)),
            ),
          ),
        );

        for (int i = 0; i < 5; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }

        expect(find.text('CÒN NỢ'), findsOneWidget);
        expect(find.textContaining('Phải thu: 600,000đ'), findsOneWidget);
        expect(find.textContaining('Đã trả: 300,000đ'), findsOneWidget);
        expect(find.textContaining('Còn lại: 300,000đ'), findsOneWidget);
        expect(find.text('Thanh toán'), findsOneWidget);
        expect(find.text('Lịch sử TT'), findsOneWidget);
      },
    );

    testWidgets(
      'Fully paid DA_THANH_TOAN invoice does NOT render Thanh toán button',
      (tester) async {
        final testStudent = Student(
          id: 1,
          hoTen: 'Paid Student',
          sdtPhuHuynh: '0901234567',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final nowMonth = DateTime.now().toString().substring(0, 7);

        final testInvoice = TuitionInvoice(
          id: 1,
          idHocSinh: 1,
          idLop: 1,
          thang: nowMonth,
          idChinhSachHocPhi: 1,
          soBuoiEligible: 12,
          soBuoiTinhPhi: 12,
          creditOpening: 0,
          creditEarned: 0,
          creditUsed: 0,
          creditClosing: 0,
          tongTruocGiam: 600000,
          giamPhanTram: 0,
          giamSoTien: 0,
          soTienPhaiThu: 600000,
          trangThai: TuitionInvoiceStatus.DA_THANH_TOAN,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final testPayment = Payment(
          id: 1,
          studentId: 1,
          classId: 1,
          invoiceId: 1,
          month: nowMonth,
          amount: 600000,
          paymentDate: '$nowMonth-10',
          method: PaymentMethod.CHUYEN_KHOAN,
          createdAt: DateTime.now(),
        );

        final testSummary = InvoicePaymentSummary.calculate(
          invoice: testInvoice,
          payments: [testPayment],
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              databaseProvider.overrideWith((ref) async => db),
              classTuitionPoliciesProvider(1).overrideWith((ref) async => []),
              effectiveTuitionPolicyProvider((
                1,
                nowMonth,
              )).overrideWith((ref) async => null),
              classMonthStudentsProvider((
                1,
                nowMonth,
              )).overrideWith((ref) async => [testStudent]),
              studentDetailProvider(1).overrideWith((ref) async => testStudent),
              classMonthInvoicesProvider((
                1,
                nowMonth,
              )).overrideWith((ref) async => [testInvoice]),
              studentInvoiceProvider(
                1,
                1,
                nowMonth,
              ).overrideWith((ref) async => testInvoice),
              invoicePaymentSummaryProvider((
                1,
                1,
                nowMonth,
              )).overrideWith((ref) async => testSummary),
              classMonthPaymentSummariesProvider((
                1,
                nowMonth,
              )).overrideWith((ref) async => {1: testSummary}),
            ],
            child: const MaterialApp(
              home: Scaffold(body: ClassTuitionTab(classId: 1)),
            ),
          ),
        );

        for (int i = 0; i < 5; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }

        expect(find.text('ĐÃ THANH TOÁN'), findsOneWidget);
        expect(find.text('Thanh toán'), findsNothing);
        expect(find.text('Lịch sử TT'), findsOneWidget);
      },
    );

    testWidgets(
      'Invoice provider LOADING state fails closed without draft preview or action buttons',
      (tester) async {
        final testStudent = Student(
          id: 1,
          hoTen: 'Invoice Loading Student',
          sdtPhuHuynh: '0901234567',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final nowMonth = DateTime.now().toString().substring(0, 7);
        final completer = Completer<List<TuitionInvoice>>();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              databaseProvider.overrideWith((ref) async => db),
              classTuitionPoliciesProvider(1).overrideWith((ref) async => []),
              effectiveTuitionPolicyProvider((
                1,
                nowMonth,
              )).overrideWith((ref) async => null),
              classMonthStudentsProvider((
                1,
                nowMonth,
              )).overrideWith((ref) async => [testStudent]),
              studentDetailProvider(1).overrideWith((ref) async => testStudent),
              classMonthInvoicesProvider((
                1,
                nowMonth,
              )).overrideWith((ref) => completer.future),
              classMonthPaymentSummariesProvider((
                1,
                nowMonth,
              )).overrideWith((ref) async => {}),
            ],
            child: const MaterialApp(
              home: Scaffold(body: ClassTuitionTab(classId: 1)),
            ),
          ),
        );

        for (int i = 0; i < 5; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }

        expect(find.text('Đang tải dữ liệu hóa đơn...'), findsOneWidget);
        expect(find.text('NHÁP'), findsNothing);
        expect(find.text('Chốt học phí'), findsNothing);
        expect(find.text('Thanh toán'), findsNothing);
      },
    );

    testWidgets(
      'Invoice provider ERROR state fails closed without draft preview or action buttons',
      (tester) async {
        final testStudent = Student(
          id: 1,
          hoTen: 'Invoice Error Student',
          sdtPhuHuynh: '0901234567',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final nowMonth = DateTime.now().toString().substring(0, 7);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              databaseProvider.overrideWith((ref) async => db),
              classTuitionPoliciesProvider(1).overrideWith((ref) async => []),
              effectiveTuitionPolicyProvider((
                1,
                nowMonth,
              )).overrideWith((ref) async => null),
              classMonthStudentsProvider((
                1,
                nowMonth,
              )).overrideWith((ref) async => [testStudent]),
              studentDetailProvider(1).overrideWith((ref) async => testStudent),
              classMonthInvoicesProvider((
                1,
                nowMonth,
              )).overrideWith((ref) => Future.error('Invoice DB Error')),
              classMonthPaymentSummariesProvider((
                1,
                nowMonth,
              )).overrideWith((ref) async => {}),
            ],
            child: const MaterialApp(
              home: Scaffold(body: ClassTuitionTab(classId: 1)),
            ),
          ),
        );

        for (int i = 0; i < 5; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }

        expect(
          find.textContaining('Lỗi dữ liệu hóa đơn: Invoice DB Error'),
          findsOneWidget,
        );
        expect(find.text('NHÁP'), findsNothing);
        expect(find.text('Chốt học phí'), findsNothing);
        expect(find.text('Thanh toán'), findsNothing);
      },
    );

    testWidgets(
      'Finalized invoice + payment summary provider LOADING state hides Thanh toán button',
      (tester) async {
        final testStudent = Student(
          id: 1,
          hoTen: 'Loading Student',
          sdtPhuHuynh: '0901234567',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final nowMonth = DateTime.now().toString().substring(0, 7);

        final testInvoice = TuitionInvoice(
          id: 1,
          idHocSinh: 1,
          idLop: 1,
          thang: nowMonth,
          idChinhSachHocPhi: 1,
          soBuoiEligible: 12,
          soBuoiTinhPhi: 12,
          creditOpening: 0,
          creditEarned: 0,
          creditUsed: 0,
          creditClosing: 0,
          tongTruocGiam: 600000,
          giamPhanTram: 0,
          giamSoTien: 0,
          soTienPhaiThu: 600000,
          trangThai: TuitionInvoiceStatus.DA_CHOT,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final completer = Completer<Map<int, InvoicePaymentSummary>>();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              databaseProvider.overrideWith((ref) async => db),
              classTuitionPoliciesProvider(1).overrideWith((ref) async => []),
              effectiveTuitionPolicyProvider((
                1,
                nowMonth,
              )).overrideWith((ref) async => null),
              classMonthStudentsProvider((
                1,
                nowMonth,
              )).overrideWith((ref) async => [testStudent]),
              studentDetailProvider(1).overrideWith((ref) async => testStudent),
              classMonthInvoicesProvider((
                1,
                nowMonth,
              )).overrideWith((ref) async => [testInvoice]),
              classMonthPaymentSummariesProvider((
                1,
                nowMonth,
              )).overrideWith((ref) => completer.future),
            ],
            child: const MaterialApp(
              home: Scaffold(body: ClassTuitionTab(classId: 1)),
            ),
          ),
        );

        for (int i = 0; i < 5; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }

        expect(find.text('Đang tải dữ liệu thanh toán...'), findsOneWidget);
        expect(find.text('Thanh toán'), findsNothing);
      },
    );

    testWidgets(
      'Finalized invoice + payment summary provider ERROR state fails closed without Thanh toán button',
      (tester) async {
        final testStudent = Student(
          id: 1,
          hoTen: 'Error Student',
          sdtPhuHuynh: '0901234567',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final nowMonth = DateTime.now().toString().substring(0, 7);

        final testInvoice = TuitionInvoice(
          id: 1,
          idHocSinh: 1,
          idLop: 1,
          thang: nowMonth,
          idChinhSachHocPhi: 1,
          soBuoiEligible: 12,
          soBuoiTinhPhi: 12,
          creditOpening: 0,
          creditEarned: 0,
          creditUsed: 0,
          creditClosing: 0,
          tongTruocGiam: 600000,
          giamPhanTram: 0,
          giamSoTien: 0,
          soTienPhaiThu: 600000,
          trangThai: TuitionInvoiceStatus.DA_CHOT,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              databaseProvider.overrideWith((ref) async => db),
              classTuitionPoliciesProvider(1).overrideWith((ref) async => []),
              effectiveTuitionPolicyProvider((
                1,
                nowMonth,
              )).overrideWith((ref) async => null),
              classMonthStudentsProvider((
                1,
                nowMonth,
              )).overrideWith((ref) async => [testStudent]),
              studentDetailProvider(1).overrideWith((ref) async => testStudent),
              classMonthInvoicesProvider((
                1,
                nowMonth,
              )).overrideWith((ref) async => [testInvoice]),
              classMonthPaymentSummariesProvider((
                1,
                nowMonth,
              )).overrideWith((ref) => Future.error('DB Error')),
            ],
            child: const MaterialApp(
              home: Scaffold(body: ClassTuitionTab(classId: 1)),
            ),
          ),
        );

        for (int i = 0; i < 5; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }

        expect(
          find.textContaining('Lỗi dữ liệu thanh toán: DB Error'),
          findsOneWidget,
        );
        expect(find.text('Thanh toán'), findsNothing);
      },
    );

    test(
      'PaymentController recordPayment live invalidates classMonthInvoicesProvider and classMonthPaymentSummariesProvider',
      () async {
        // Seed DB
        await db.execute('''
        INSERT INTO hoc_sinh (id, ho_ten, sdt_phu_huynh, created_at, updated_at)
        VALUES (1, 'Student 1', '0901234567', '2026-01-01T00:00:00.000', '2026-01-01T00:00:00.000')
      ''');

        await db.execute('''
        INSERT INTO lop (id, ten_lop, created_at, updated_at)
        VALUES (1, 'Class 1', '2026-01-01T00:00:00.000', '2026-01-01T00:00:00.000')
      ''');

        await db.execute('''
        INSERT INTO chinh_sach_hoc_phi (id, id_lop, hieu_luc_tu, hoc_phi_moi_buoi, created_at, updated_at)
        VALUES (1, 1, '2026-01-01', 50000, '2026-01-01T00:00:00.000', '2026-01-01T00:00:00.000')
      ''');

        await db.execute('''
        INSERT INTO hoc_phi_thang (id, id_hoc_sinh, id_lop, thang, id_chinh_sach_hoc_phi, so_buoi_eligible, so_buoi_tinh_phi, credit_opening, credit_earned, credit_used, credit_closing, tong_truoc_giam, so_tien_phai_thu, trang_thai, created_at, updated_at)
        VALUES (1, 1, 1, '2026-09', 1, 12, 12, 0, 0, 0, 0, 600000, 600000, 'DA_CHOT', '2026-09-01T00:00:00.000', '2026-09-01T00:00:00.000')
      ''');

        final container = ProviderContainer(
          overrides: [databaseProvider.overrideWith((ref) async => db)],
        );
        addTearDown(container.dispose);

        // Read initial invoices & summaries
        var invoices = await container.read(
          classMonthInvoicesProvider((1, '2026-09')).future,
        );
        expect(invoices.first.trangThai, TuitionInvoiceStatus.DA_CHOT);

        var summaries = await container.read(
          classMonthPaymentSummariesProvider((1, '2026-09')).future,
        );
        expect(summaries[1]?.remainingDebt, 600000);

        // Record partial payment 300,000
        await container
            .read(paymentControllerProvider.notifier)
            .recordPayment(
              studentId: 1,
              classId: 1,
              month: '2026-09',
              amount: 300000,
              paymentDate: '2026-09-15',
              method: PaymentMethod.CHUYEN_KHOAN,
            );

        // Re-read batch providers - must reload live with new state CON_NO
        invoices = await container.read(
          classMonthInvoicesProvider((1, '2026-09')).future,
        );
        expect(invoices.first.trangThai, TuitionInvoiceStatus.CON_NO);

        summaries = await container.read(
          classMonthPaymentSummariesProvider((1, '2026-09')).future,
        );
        expect(summaries[1]?.totalPaid, 300000);
        expect(summaries[1]?.remainingDebt, 300000);
        expect(summaries[1]?.settlementStatus, TuitionInvoiceStatus.CON_NO);

        // Record remaining payment 300,000
        await container
            .read(paymentControllerProvider.notifier)
            .recordPayment(
              studentId: 1,
              classId: 1,
              month: '2026-09',
              amount: 300000,
              paymentDate: '2026-09-20',
              method: PaymentMethod.TIEN_MAT,
            );

        // Re-read batch providers - must reload live with new state DA_THANH_TOAN
        invoices = await container.read(
          classMonthInvoicesProvider((1, '2026-09')).future,
        );
        expect(invoices.first.trangThai, TuitionInvoiceStatus.DA_THANH_TOAN);

        summaries = await container.read(
          classMonthPaymentSummariesProvider((1, '2026-09')).future,
        );
        expect(summaries[1]?.totalPaid, 600000);
        expect(summaries[1]?.remainingDebt, 0);
        expect(
          summaries[1]?.settlementStatus,
          TuitionInvoiceStatus.DA_THANH_TOAN,
        );
      },
    );
  });
}
