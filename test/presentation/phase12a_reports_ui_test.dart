import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' hide equals;
import 'package:tuition2027/core/database/app_database.dart';
import 'package:tuition2027/core/database/database_provider.dart';
import 'package:tuition2027/features/reports/domain/report_scope.dart';
import 'package:tuition2027/features/reports/domain/report_summary.dart';
import 'package:tuition2027/features/reports/presentation/report_controller.dart';
import 'package:tuition2027/features/reports/presentation/reports_page.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late String nowStr;

  setUp(() {
    nowStr = DateTime.now().toIso8601String();
  });

  Future<Database> createTestDb() async {
    final tempDir = await Directory.systemTemp.createTemp('p12a_ui_test');
    final dbPath = join(
      tempDir.path,
      'test_${DateTime.now().microsecondsSinceEpoch}.db',
    );
    final appDb = AppDatabase(dbName: dbPath);
    return await appDb.database;
  }

  Future<void> setupBaseData(Database db) async {
    await db.insert('hoc_sinh', {
      'id': 1,
      'ho_ten': 'Student A',
      'da_luu_tru': 0,
      'created_at': nowStr,
      'updated_at': nowStr,
    });
    await db.insert('lop', {
      'id': 10,
      'ten_lop': 'Class 10A',
      'da_luu_tru': 0,
      'created_at': nowStr,
      'updated_at': nowStr,
    });
  }

  Future<void> waitForAsyncProviders(
    WidgetTester tester, {
    int iterations = 15,
  }) async {
    for (int i = 0; i < iterations; i++) {
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 50));
      });
      await tester.pump();
    }
  }

  group('Phase 12A Reports Page UI Tests', () {
    testWidgets('ReportsPage displays loading state indicator', (tester) async {
      late Database db;
      await tester.runAsync(() async {
        db = await createTestDb();
        await setupBaseData(db);
      });

      final pendingCompleter = Completer<ReportSummary>();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWith((ref) async => db),
            reportSummaryProvider.overrideWith(
              (ref) => pendingCompleter.future,
            ),
          ],
          child: const MaterialApp(home: ReportsPage()),
        ),
      );

      await tester.pump();

      expect(find.text('Báo cáo & Thống kê'), findsOneWidget);
      expect(find.text('Đang tổng hợp báo cáo...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsAtLeast(1));

      pendingCompleter.complete(
        ReportSummary(
          scope: ReportScope.forMonth(month: '2026-10'),
          generatedAt: DateTime.now(),
          attendance: AttendanceReportSummary.zero(),
          financial: FinancialReportSummary.zero(),
          classSummaries: [],
          studentSummaries: [],
        ),
      );
      await tester.runAsync(() async => db.close());
    });

    testWidgets('ReportsPage displays error state with retry button', (
      tester,
    ) async {
      late Database db;
      await tester.runAsync(() async {
        db = await createTestDb();
        await setupBaseData(db);
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWith((ref) async => db),
            reportSummaryProvider.overrideWith(
              (ref) => Future.error(Exception('Simulated Error')),
            ),
          ],
          child: const MaterialApp(home: ReportsPage()),
        ),
      );

      await waitForAsyncProviders(tester);

      expect(find.textContaining('Lỗi tải báo cáo'), findsOneWidget);
      expect(find.text('Thử lại'), findsOneWidget);

      await tester.runAsync(() async => db.close());
    });

    testWidgets('ReportsPage displays empty state card when summary is empty', (
      tester,
    ) async {
      late Database db;
      await tester.runAsync(() async {
        db = await createTestDb();
        await setupBaseData(db);
      });

      final emptySummary = ReportSummary(
        scope: ReportScope.forMonth(month: '2026-10'),
        generatedAt: DateTime.now(),
        attendance: AttendanceReportSummary.zero(),
        financial: FinancialReportSummary.zero(),
        classSummaries: [],
        studentSummaries: [],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWith((ref) async => db),
            reportSummaryProvider.overrideWith((ref) async => emptySummary),
          ],
          child: const MaterialApp(home: ReportsPage()),
        ),
      );

      await waitForAsyncProviders(tester);

      expect(
        find.text('Chưa có dữ liệu báo cáo trong khoảng thời gian đã chọn.'),
        findsOneWidget,
      );

      await tester.runAsync(() async => db.close());
    });

    testWidgets(
      'ReportsPage renders KPI cards and breakdown tables with summary data',
      (tester) async {
        late Database db;
        await tester.runAsync(() async {
          db = await createTestDb();
          await setupBaseData(db);
        });

        tester.view.physicalSize = const Size(1200, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final dummySummary = ReportSummary(
          scope: ReportScope.forMonth(month: '2026-10'),
          generatedAt: DateTime.now(),
          attendance: const AttendanceReportSummary(
            totalSessions: 5,
            totalEligibleParticipations: 10,
            totalPresent: 8,
            totalLate: 1,
            totalExcusedAbsence: 1,
            totalUnexcusedAbsence: 1,
            attendanceRatePercentage: 80.0,
          ),
          financial: const FinancialReportSummary(
            totalInvoiced: 1000000,
            totalPaid: 700000,
            totalOutstandingDebt: 300000,
          ),
          classSummaries: const [
            ClassReportSummary(
              classId: 10,
              className: 'Class 10A',
              studentCountInScope: 5,
              attendance: AttendanceReportSummary(
                totalSessions: 5,
                totalEligibleParticipations: 10,
                totalPresent: 8,
                totalLate: 1,
                totalExcusedAbsence: 1,
                totalUnexcusedAbsence: 1,
                attendanceRatePercentage: 80.0,
              ),
              financial: FinancialReportSummary(
                totalInvoiced: 1000000,
                totalPaid: 700000,
                totalOutstandingDebt: 300000,
              ),
            ),
          ],
          studentSummaries: const [
            StudentReportSummary(
              studentId: 1,
              studentName: 'Student A',
              enrolledClassNames: ['Class 10A'],
              attendance: AttendanceReportSummary(
                totalSessions: 5,
                totalEligibleParticipations: 10,
                totalPresent: 8,
                totalLate: 1,
                totalExcusedAbsence: 1,
                totalUnexcusedAbsence: 1,
                attendanceRatePercentage: 80.0,
              ),
              financial: FinancialReportSummary(
                totalInvoiced: 1000000,
                totalPaid: 700000,
                totalOutstandingDebt: 300000,
              ),
            ),
          ],
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              databaseProvider.overrideWith((ref) async => db),
              reportSummaryProvider.overrideWith((ref) async => dummySummary),
            ],
            child: const MaterialApp(home: ReportsPage()),
          ),
        );

        await waitForAsyncProviders(tester);

        expect(find.text('80.0%'), findsAtLeast(1));
        expect(find.text('Tỷ lệ đi học'), findsAtLeast(1));
        expect(find.text('Học phí chốt'), findsAtLeast(1));
        expect(find.text('Doanh thu thực nhận'), findsAtLeast(1));
        expect(
          find.text('Dư nợ hiện tại của hóa đơn trong kỳ'),
          findsAtLeast(1),
        );

        expect(find.text('Tổng quan theo Lớp học'), findsOneWidget);
        expect(find.text('Class 10A'), findsAtLeast(1));

        expect(find.text('Chi tiết theo Học sinh'), findsOneWidget);
        expect(find.text('Student A'), findsOneWidget);

        await tester.runAsync(() async => db.close());
      },
    );

    testWidgets(
      'ReportsPage does not display stale KPI numbers while new scope is loading',
      (tester) async {
        late Database db;
        await tester.runAsync(() async {
          db = await createTestDb();
          await setupBaseData(db);
        });

        final initialSummary = ReportSummary(
          scope: ReportScope.forMonth(month: '2026-10'),
          generatedAt: DateTime.now(),
          attendance: const AttendanceReportSummary(
            totalSessions: 5,
            totalEligibleParticipations: 10,
            totalPresent: 10,
            totalLate: 0,
            totalExcusedAbsence: 0,
            totalUnexcusedAbsence: 0,
            attendanceRatePercentage: 100.0,
          ),
          financial: const FinancialReportSummary(
            totalInvoiced: 999999,
            totalPaid: 999999,
            totalOutstandingDebt: 0,
          ),
          classSummaries: [],
          studentSummaries: [],
        );

        final nextCompleter = Completer<ReportSummary>();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              databaseProvider.overrideWith((ref) async => db),
              reportSummaryProvider.overrideWith((ref) {
                final scope = ref.watch(reportScopeNotifierProvider);
                if (scope.mode == ReportMode.month) {
                  return Future.value(initialSummary);
                }
                return nextCompleter.future;
              }),
            ],
            child: const MaterialApp(home: ReportsPage()),
          ),
        );

        await waitForAsyncProviders(tester);

        expect(find.text('100.0%'), findsOneWidget);

        // Switch mode to Custom Range -> triggers new scope load
        await tester.tap(find.text('Khoảng ngày'));
        await tester.pump();

        // Verify loading indicator is displayed and old stale numbers (100.0%) ARE NOT SHOWN AS NEW DATA
        expect(find.text('Đang tổng hợp báo cáo...'), findsOneWidget);
        expect(find.text('100.0%'), findsNothing);

        nextCompleter.complete(initialSummary);
        await tester.runAsync(() async => db.close());
      },
    );

    testWidgets(
      'ReportsPage renders historical archived class and student from ReportSummary',
      (tester) async {
        late Database db;
        await tester.runAsync(() async {
          db = await createTestDb();
          await setupBaseData(db);
        });

        tester.view.physicalSize = const Size(1200, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final archivedSummary = ReportSummary(
          scope: ReportScope.forMonth(month: '2026-10'),
          generatedAt: DateTime.now(),
          attendance: const AttendanceReportSummary(
            totalSessions: 2,
            totalEligibleParticipations: 4,
            totalPresent: 4,
            totalLate: 0,
            totalExcusedAbsence: 0,
            totalUnexcusedAbsence: 0,
            attendanceRatePercentage: 100.0,
          ),
          financial: const FinancialReportSummary(
            totalInvoiced: 500000,
            totalPaid: 500000,
            totalOutstandingDebt: 0,
          ),
          classSummaries: const [
            ClassReportSummary(
              classId: 99,
              className: 'Archived Class 99',
              studentCountInScope: 1,
              attendance: AttendanceReportSummary(
                totalSessions: 2,
                totalEligibleParticipations: 4,
                totalPresent: 4,
                totalLate: 0,
                totalExcusedAbsence: 0,
                totalUnexcusedAbsence: 0,
                attendanceRatePercentage: 100.0,
              ),
              financial: FinancialReportSummary(
                totalInvoiced: 500000,
                totalPaid: 500000,
                totalOutstandingDebt: 0,
              ),
            ),
          ],
          studentSummaries: const [
            StudentReportSummary(
              studentId: 88,
              studentName: 'Archived Student 88',
              enrolledClassNames: ['Archived Class 99'],
              attendance: AttendanceReportSummary(
                totalSessions: 2,
                totalEligibleParticipations: 4,
                totalPresent: 4,
                totalLate: 0,
                totalExcusedAbsence: 0,
                totalUnexcusedAbsence: 0,
                attendanceRatePercentage: 100.0,
              ),
              financial: FinancialReportSummary(
                totalInvoiced: 500000,
                totalPaid: 500000,
                totalOutstandingDebt: 0,
              ),
            ),
          ],
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              databaseProvider.overrideWith((ref) async => db),
              reportSummaryProvider.overrideWith(
                (ref) async => archivedSummary,
              ),
            ],
            child: const MaterialApp(home: ReportsPage()),
          ),
        );

        await waitForAsyncProviders(tester);

        expect(find.text('Archived Class 99'), findsAtLeast(1));
        expect(find.text('Archived Student 88'), findsOneWidget);

        await tester.runAsync(() async => db.close());
      },
    );
  });
}
