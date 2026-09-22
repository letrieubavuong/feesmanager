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
  });
}
