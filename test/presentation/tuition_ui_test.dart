import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:tuition2027/core/database/app_database.dart';
import 'package:tuition2027/core/database/database_provider.dart';
import 'package:tuition2027/features/payments/domain/invoice_payment_summary.dart';
import 'package:tuition2027/features/payments/domain/payment.dart';
import 'package:tuition2027/features/payments/domain/payment_method.dart';
import 'package:tuition2027/features/payments/presentation/widgets/payment_qr_share_card.dart';
import 'package:tuition2027/features/payments/presentation/widgets/vietqr_code_widget.dart';
import 'package:tuition2027/features/settings/domain/bank_account_settings.dart';
import 'package:tuition2027/features/settings/domain/vietqr_generator.dart';
import 'package:tuition2027/features/students/domain/student.dart';
import 'package:tuition2027/features/tuition/domain/class_month_tuition_overview.dart';
import 'package:tuition2027/features/tuition/domain/parent_tuition_slip.dart';
import 'package:tuition2027/features/tuition/domain/tuition_invoice.dart';
import 'package:tuition2027/features/tuition/presentation/class_tuition_tab.dart';
import 'package:tuition2027/features/tuition/presentation/tuition_controller.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('Phase 14B.6 Tuition Rebuild & QR Share Tests', () {
    late Database db;
    const nowMonth = '2026-09';

    setUp(() async {
      final tempDir = await Directory.systemTemp.createTemp('tuition_ui_test');
      final dbPath = join(tempDir.path, 'tuition_ui_test.db');
      final appDb = AppDatabase(dbName: dbPath);
      db = await appDb.database;
    });

    tearDown(() async {
      await db.close();
    });

    // TEST 44: Filter Test (Unpaid vs Paid vs Unfinalized)
    testWidgets(
      'Test 44 - Tuition filter separates Unpaid, Paid, and Unfinalized',
      (tester) async {
        final studentA = Student(
          id: 1,
          hoTen: 'Student A',
          sdtPhuHuynh: '0901111111',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final studentB = Student(
          id: 2,
          hoTen: 'Student B',
          sdtPhuHuynh: '0902222222',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final studentC = Student(
          id: 3,
          hoTen: 'Student C',
          sdtPhuHuynh: '0903333333',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final studentD = Student(
          id: 4,
          hoTen: 'Student D',
          sdtPhuHuynh: '0904444444',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Student A: Finalized, due 500k, paid 0 -> remaining 500k (UNPAID)
        final invA = TuitionInvoice(
          id: 1,
          idHocSinh: 1,
          idLop: 1,
          thang: nowMonth,
          idChinhSachHocPhi: 1,
          soBuoiEligible: 10,
          soBuoiTinhPhi: 10,
          creditOpening: 0,
          creditEarned: 0,
          creditUsed: 0,
          creditClosing: 0,
          tongTruocGiam: 500000,
          giamPhanTram: 0,
          giamSoTien: 0,
          soTienPhaiThu: 500000,
          trangThai: TuitionInvoiceStatus.DA_CHOT,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        final sumA = InvoicePaymentSummary.calculate(
          invoice: invA,
          payments: [],
        );

        // Student B: Finalized, due 500k, paid 200k -> remaining 300k (UNPAID)
        final invB = TuitionInvoice(
          id: 2,
          idHocSinh: 2,
          idLop: 1,
          thang: nowMonth,
          idChinhSachHocPhi: 1,
          soBuoiEligible: 10,
          soBuoiTinhPhi: 10,
          creditOpening: 0,
          creditEarned: 0,
          creditUsed: 0,
          creditClosing: 0,
          tongTruocGiam: 500000,
          giamPhanTram: 0,
          giamSoTien: 0,
          soTienPhaiThu: 500000,
          trangThai: TuitionInvoiceStatus.CON_NO,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        final payB = Payment(
          id: 1,
          studentId: 2,
          classId: 1,
          invoiceId: 2,
          month: nowMonth,
          amount: 200000,
          paymentDate: '$nowMonth-10',
          method: PaymentMethod.CHUYEN_KHOAN,
          createdAt: DateTime.now(),
        );
        final sumB = InvoicePaymentSummary.calculate(
          invoice: invB,
          payments: [payB],
        );

        // Student C: Finalized, due 500k, paid 500k -> remaining 0 (PAID)
        final invC = TuitionInvoice(
          id: 3,
          idHocSinh: 3,
          idLop: 1,
          thang: nowMonth,
          idChinhSachHocPhi: 1,
          soBuoiEligible: 10,
          soBuoiTinhPhi: 10,
          creditOpening: 0,
          creditEarned: 0,
          creditUsed: 0,
          creditClosing: 0,
          tongTruocGiam: 500000,
          giamPhanTram: 0,
          giamSoTien: 0,
          soTienPhaiThu: 500000,
          trangThai: TuitionInvoiceStatus.DA_THANH_TOAN,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        final payC = Payment(
          id: 2,
          studentId: 3,
          classId: 1,
          invoiceId: 3,
          month: nowMonth,
          amount: 500000,
          paymentDate: '$nowMonth-10',
          method: PaymentMethod.CHUYEN_KHOAN,
          createdAt: DateTime.now(),
        );
        final sumC = InvoicePaymentSummary.calculate(
          invoice: invC,
          payments: [payC],
        );

        final rowA = ClassMonthTuitionStudentRow(
          student: studentA,
          invoice: invA,
          paymentSummary: sumA,
          state: ClassStudentTuitionState.FINALIZED_UNPAID,
        );
        final rowB = ClassMonthTuitionStudentRow(
          student: studentB,
          invoice: invB,
          paymentSummary: sumB,
          state: ClassStudentTuitionState.PARTIALLY_PAID,
        );
        final rowC = ClassMonthTuitionStudentRow(
          student: studentC,
          invoice: invC,
          paymentSummary: sumC,
          state: ClassStudentTuitionState.PAID,
        );
        final rowD = ClassMonthTuitionStudentRow(
          student: studentD,
          state: ClassStudentTuitionState.PREVIEW_READY,
        );

        final testOverview = ClassMonthTuitionOverview(
          classId: 1,
          month: nowMonth,
          previewTotalDue: 500000,
          finalizedTotalDue: 1500000,
          totalPaid: 700000,
          remainingDebt: 800000,
          previewStudentCount: 1,
          finalizedStudentCount: 3,
          pendingStudentCount: 0,
          studentRows: [rowA, rowB, rowC, rowD],
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              databaseProvider.overrideWith((ref) async => db),
              classMonthTuitionOverviewProvider((
                1,
                nowMonth,
              )).overrideWith((ref) async => testOverview),
            ],
            child: const MaterialApp(
              home: Scaffold(body: ClassTuitionTab(classId: 1)),
            ),
          ),
        );

        for (int i = 0; i < 5; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }

        // No "Tất cả" filter
        expect(find.text('Tất cả'), findsNothing);

        // Default: "Chưa nộp" segment selected
        expect(find.text('Student A'), findsOneWidget);
        expect(find.text('Student B'), findsOneWidget);
        expect(find.text('Student C'), findsNothing);

        await tester.tap(find.byKey(const Key('tuition_student_menu_1')));
        await tester.pumpAndSettle();
        expect(find.text('Thu tiền'), findsOneWidget);
        expect(find.text('Tạo mã QR'), findsOneWidget);
        await tester.tapAt(const Offset(2, 2));
        await tester.pumpAndSettle();

        // Unfinalized banner present
        expect(
          find.textContaining('1 học sinh chưa chốt học phí'),
          findsOneWidget,
        );
        expect(find.text('Chốt học phí'), findsOneWidget);

        // No phone numbers exposed on student list
        expect(find.textContaining('0901111111'), findsNothing);

        // Switch to "Đã nộp" segment
        await tester.tap(find.textContaining('Đã nộp'));
        await tester.pumpAndSettle();

        expect(find.text('Student C'), findsOneWidget);
        expect(find.text('Student A'), findsNothing);
        expect(find.text('Student B'), findsNothing);
      },
    );

    // TEST 46: QR Amount = remaining debt (NOT original invoice amount)
    test('Test 46 - QR code amount uses remaining debt', () {
      const settings = BankAccountSettings(
        bankName: 'MBBank',
        bankCode: 'MB',
        bankBin: '970422',
        accountNumber: '0123456789',
        accountHolder: 'TRAN VAN A',
        transferTemplate: 'HP {maHocSinh} {thang}',
      );

      final qrPayload = VietQrGenerator.generateEmvCoPayload(
        settings: settings,
        amount: 300000, // remaining debt when invoice is 500k and 200k paid
        transferContent: VietQrGenerator.formatTransferContent(
          template: settings.transferTemplate,
          studentCode: '125',
          month: '09/2026',
        ),
      );

      expect(qrPayload, contains('5406300000')); // Tag 54 amount = 300000
    });

    // TEST 47: Transfer content formatting
    test(
      'Test 47 - Transfer content template replaces student code, name, class, and month',
      () {
        const template = 'HP {maHocSinh} {tenHocSinh} {lop} {thang}';

        final content = VietQrGenerator.formatTransferContent(
          template: template,
          studentCode: '125',
          studentName: 'Nguyễn Văn Ly',
          className: 'VẬT LÍ 10',
          month: '2026-09',
        );

        expect(content, contains('125'));
        expect(content, contains('NGUYEN VAN LY'));
        expect(content, contains('VAT LI 10'));
        expect(content, contains('202609'));
      },
    );

    // TEST 48: QR Share Card widget contains required payment details
    testWidgets(
      'Test 48 - PaymentQrShareCard shows parent payment essentials',
      (tester) async {
        const slip = ParentTuitionSlip(
          studentId: 125,
          classId: 1,
          month: '2026-09',
          studentName: 'Nguyễn Văn Ly',
          className: 'VẬT LÍ 10',
          status: ParentTuitionSlipStatus.ready,
          projectedSessionCount: 13,
          standardSessionLimit: 12,
          projectedExtraCount: 1,
          openingCreditBalance: 2,
          presentCount: 10,
          lateCount: 0,
          excusedAbsenceCount: 1,
          unexcusedAbsenceCount: 0,
          makeupCompletedCount: 1,
          reconciliationAsOfDate: '28/09/2026',
          amountDue: 600000,
          totalPaid: 150000,
          remainingDebt: 450000,
          bank: BankAccountSettings(
            bankName: 'MBBank',
            bankCode: 'MB',
            bankBin: '970422',
            accountNumber: '0123456789',
            accountHolder: 'TRAN VAN A',
            transferTemplate: 'HP {maHocSinh} {lop} {thang}',
          ),
          transferContent: 'HP 125 VATLI10 092026',
          qrPayload: '000201010212...',
        );

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: PaymentQrShareCard(slip: slip),
              ),
            ),
          ),
        );

        expect(find.text('HỌC PHÍ'), findsOneWidget);
        expect(find.text('Nguyễn Văn Ly'), findsOneWidget);
        expect(find.text('VẬT LÍ 10'), findsOneWidget);
        expect(find.text('450.000đ'), findsOneWidget);
        expect(find.text('MBBank'), findsOneWidget);
        expect(find.text('0123456789'), findsOneWidget);
        expect(find.text('TRAN VAN A'), findsOneWidget);
        expect(find.text('HP 125 VATLI10 092026'), findsOneWidget);
        expect(find.byType(VietQrCodeWidget), findsOneWidget);
        expect(find.text('Buổi dự kiến'), findsNothing);
        expect(find.text('Buổi dư chuyển sang'), findsNothing);
      },
    );
  });
}
