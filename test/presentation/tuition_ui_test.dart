import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:tuition2027/core/database/app_database.dart';
import 'package:tuition2027/core/database/database_provider.dart';
import 'package:tuition2027/features/memberships/presentation/membership_providers.dart';
import 'package:tuition2027/features/students/domain/student.dart';
import 'package:tuition2027/features/students/presentation/student_detail_page.dart';
import 'package:tuition2027/features/tuition/domain/tuition_invoice.dart';
import 'package:tuition2027/features/tuition/domain/tuition_policy.dart';
import 'package:tuition2027/features/tuition/domain/tuition_preview.dart';
import 'package:tuition2027/features/tuition/presentation/class_tuition_tab.dart';
import 'package:tuition2027/features/tuition/presentation/tuition_controller.dart';

class _FakeTuitionPreviewController extends TuitionPreviewController {
  @override
  Future<TuitionPreview> build(int studentId, int classId, String month) async {
    final policy = TuitionPolicy(
      id: 1,
      idLop: classId,
      hieuLucTu: '2026-01-01',
      hocPhiMoiBuoi: 50000,
      soBuoiChuanThang: 12,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    return TuitionPreview(
      studentId: studentId,
      classId: classId,
      month: month,
      policy: policy,
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
      candidates: [],
    );
  }
}

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('Tuition UI Tests', () {
    late Database db;

    setUp(() async {
      final tempDir = await Directory.systemTemp.createTemp('tuition_ui_test');
      final dbPath = join(tempDir.path, 'tuition_ui_test.db');
      final appDb = AppDatabase(dbName: dbPath);
      db = await appDb.database;
    });

    tearDown(() async {
      await db.close();
    });

    testWidgets(
      'ClassTuitionTab renders policy card, student card, and draft chip',
      (tester) async {
        final testPolicy = TuitionPolicy(
          id: 1,
          idLop: 1,
          hieuLucTu: '2026-01-01',
          hocPhiMoiBuoi: 50000,
          soBuoiChuanThang: 12,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final testStudent = Student(
          id: 1,
          hoTen: 'Student UI Test',
          sdtPhuHuynh: '0901234567',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final nowMonth = DateTime.now().toString().substring(0, 7);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              databaseProvider.overrideWith((ref) async => db),
              classTuitionPoliciesProvider(
                1,
              ).overrideWith((ref) async => [testPolicy]),
              effectiveTuitionPolicyProvider((
                1,
                nowMonth,
              )).overrideWith((ref) async => testPolicy),
              classMonthStudentsProvider((
                1,
                nowMonth,
              )).overrideWith((ref) async => [testStudent]),
              studentDetailProvider(1).overrideWith((ref) async => testStudent),
              tuitionPreviewControllerProvider(
                1,
                1,
                nowMonth,
              ).overrideWith(() => _FakeTuitionPreviewController()),
            ],
            child: const MaterialApp(
              home: Scaffold(body: ClassTuitionTab(classId: 1)),
            ),
          ),
        );

        for (int i = 0; i < 5; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }

        expect(find.text('Chính sách học phí'), findsOneWidget);
        expect(find.textContaining('Học phí: 50,000đ / buổi'), findsOneWidget);
        expect(find.text('Danh sách học phí học sinh'), findsOneWidget);
        expect(find.text('Student UI Test'), findsOneWidget);
        expect(find.text('NHÁP'), findsOneWidget);
      },
    );

    testWidgets(
      'ClassTuitionTab renders DA_CHOT snapshot chip without finalize button',
      (tester) async {
        final testStudent = Student(
          id: 1,
          hoTen: 'Finalized Student',
          sdtPhuHuynh: '0901234567',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final testInvoice = TuitionInvoice(
          id: 1,
          idHocSinh: 1,
          idLop: 1,
          thang: DateTime.now().toString().substring(0, 7),
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
              studentInvoiceProvider(
                1,
                1,
                nowMonth,
              ).overrideWith((ref) async => testInvoice),
            ],
            child: const MaterialApp(
              home: Scaffold(body: ClassTuitionTab(classId: 1)),
            ),
          ),
        );

        for (int i = 0; i < 5; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }

        expect(find.text('ĐÃ CHỐT'), findsOneWidget);
        expect(find.text('Chốt học phí'), findsNothing);
      },
    );

    testWidgets(
      'ClassTuitionTab renders DA_THANH_TOAN snapshot chip without finalize button',
      (tester) async {
        final testStudent = Student(
          id: 1,
          hoTen: 'Paid Student',
          sdtPhuHuynh: '0901234567',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final testInvoice = TuitionInvoice(
          id: 1,
          idHocSinh: 1,
          idLop: 1,
          thang: DateTime.now().toString().substring(0, 7),
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
              studentInvoiceProvider(
                1,
                1,
                nowMonth,
              ).overrideWith((ref) async => testInvoice),
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
        expect(find.text('Chốt học phí'), findsNothing);
      },
    );

    testWidgets(
      'ClassTuitionTab renders CON_NO snapshot chip without finalize button',
      (tester) async {
        final testStudent = Student(
          id: 1,
          hoTen: 'In Debt Student',
          sdtPhuHuynh: '0901234567',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final testInvoice = TuitionInvoice(
          id: 1,
          idHocSinh: 1,
          idLop: 1,
          thang: DateTime.now().toString().substring(0, 7),
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
              studentInvoiceProvider(
                1,
                1,
                nowMonth,
              ).overrideWith((ref) async => testInvoice),
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
        expect(find.text('Chốt học phí'), findsNothing);
      },
    );
  });
}
