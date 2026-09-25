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
import 'package:tuition2027/features/reports/export/report_pdf_exporter.dart';
import 'package:tuition2027/features/reports/presentation/report_controller.dart';
import 'package:tuition2027/features/reports/presentation/reports_page.dart';

class MockReportPdfExporter implements ReportPdfExporter {
  int invocationCount = 0;
  ReportSummary? lastSummary;
  Completer<void>? pendingCompleter;
  bool shouldThrow = false;

  @override
  Future<void> export(ReportSummary summary) async {
    invocationCount++;
    lastSummary = summary;
    if (shouldThrow) {
      throw Exception('Simulated Export Failure');
    }
    if (pendingCompleter != null) {
      await pendingCompleter!.future;
    }
  }
}

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  Future<Database> createTestDb() async {
    final tempDir = await Directory.systemTemp.createTemp('p12b_ui_test');
    final dbPath = join(
      tempDir.path,
      'test_${DateTime.now().microsecondsSinceEpoch}.db',
    );
    final appDb = AppDatabase(dbName: dbPath);
    return await appDb.database;
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

  group('Phase 12B PDF Export UI Widget Tests', () {
    testWidgets(
      'Export PDF button is disabled/unavailable when summary is loading',
      (tester) async {
        late Database db;
        await tester.runAsync(() async {
          db = await createTestDb();
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

        final pdfIconButtonFinder = find.widgetWithIcon(
          IconButton,
          Icons.picture_as_pdf,
        );
        expect(pdfIconButtonFinder, findsOneWidget);

        final pdfIconButton = tester.widget<IconButton>(pdfIconButtonFinder);
        expect(pdfIconButton.onPressed, isNull); // Disabled while loading!

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
      },
    );

    testWidgets(
      'Export PDF button is disabled when summary is in AsyncError state',
      (tester) async {
        late Database db;
        await tester.runAsync(() async {
          db = await createTestDb();
        });

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              databaseProvider.overrideWith((ref) async => db),
              reportSummaryProvider.overrideWith(
                (ref) => Future.error(Exception('Simulated Report Error')),
              ),
            ],
            child: const MaterialApp(home: ReportsPage()),
          ),
        );

        await waitForAsyncProviders(tester);

        final pdfIconButtonFinder = find.widgetWithIcon(
          IconButton,
          Icons.picture_as_pdf,
        );
        expect(pdfIconButtonFinder, findsOneWidget);

        final pdfIconButton = tester.widget<IconButton>(pdfIconButtonFinder);
        expect(pdfIconButton.onPressed, isNull); // Disabled on error!

        await tester.runAsync(() async => db.close());
      },
    );

    testWidgets(
      'Double tap during pending export invokes exporter exactly ONCE',
      (tester) async {
        late Database db;
        await tester.runAsync(() async {
          db = await createTestDb();
        });

        final mockExporter = MockReportPdfExporter();
        final pendingCompleter = Completer<void>();
        mockExporter.pendingCompleter = pendingCompleter;

        final dummySummary = ReportSummary(
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
              reportSummaryProvider.overrideWith((ref) async => dummySummary),
              reportPdfExporterProvider.overrideWithValue(mockExporter),
            ],
            child: const MaterialApp(home: ReportsPage()),
          ),
        );

        await waitForAsyncProviders(tester);

        final pdfIconButtonFinder = find.widgetWithIcon(
          IconButton,
          Icons.picture_as_pdf,
        );
        expect(pdfIconButtonFinder, findsOneWidget);

        // Tap 1 -> starts export
        await tester.tap(pdfIconButtonFinder);
        await tester.pump();

        expect(mockExporter.invocationCount, equals(1));

        // Tap 2 while export is pending (button now displays progress indicator) -> double tap prevented!
        final exportingButtonFinder = find.byType(IconButton).first;
        await tester.tap(exportingButtonFinder);
        await tester.pump();

        expect(mockExporter.invocationCount, equals(1));

        // Resolve export pending completer
        pendingCompleter.complete();
        await tester.pumpAndSettle();

        await tester.runAsync(() async => db.close());
      },
    );

    testWidgets(
      'Export failure shows SnackBar error message and re-enables button',
      (tester) async {
        late Database db;
        await tester.runAsync(() async {
          db = await createTestDb();
        });

        final mockExporter = MockReportPdfExporter();
        mockExporter.shouldThrow = true;

        final dummySummary = ReportSummary(
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
              reportSummaryProvider.overrideWith((ref) async => dummySummary),
              reportPdfExporterProvider.overrideWithValue(mockExporter),
            ],
            child: const MaterialApp(home: ReportsPage()),
          ),
        );

        await waitForAsyncProviders(tester);

        final pdfIconButtonFinder = find.widgetWithIcon(
          IconButton,
          Icons.picture_as_pdf,
        );
        await tester.tap(pdfIconButtonFinder);
        await tester.pumpAndSettle();

        expect(find.textContaining('Lỗi xuất PDF'), findsOneWidget);

        final btnAfterError = tester.widget<IconButton>(pdfIconButtonFinder);
        expect(btnAfterError.onPressed, isNotNull); // Re-enabled after failure!

        await tester.runAsync(() async => db.close());
      },
    );

    testWidgets(
      'Scope parity: Exporter receives exact ReportSummary for current scope',
      (tester) async {
        late Database db;
        await tester.runAsync(() async {
          db = await createTestDb();
        });

        final mockExporter = MockReportPdfExporter();

        final scopeCustom = ReportScope.customRange(
          fromDate: '2026-09-01',
          toDate: '2026-09-30',
          classId: 10,
          studentId: 5,
        );
        final dummySummary = ReportSummary(
          scope: scopeCustom,
          generatedAt: DateTime.now(),
          attendance: const AttendanceReportSummary(
            totalSessions: 12,
            totalEligibleParticipations: 12,
            totalPresent: 11,
            totalLate: 1,
            totalExcusedAbsence: 0,
            totalUnexcusedAbsence: 0,
            attendanceRatePercentage: 91.7,
          ),
          financial: const FinancialReportSummary(
            totalInvoiced: 1200000,
            totalPaid: 1200000,
            totalOutstandingDebt: 0,
          ),
          classSummaries: [],
          studentSummaries: [],
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              databaseProvider.overrideWith((ref) async => db),
              reportSummaryProvider.overrideWith((ref) async => dummySummary),
              reportPdfExporterProvider.overrideWithValue(mockExporter),
            ],
            child: const MaterialApp(home: ReportsPage()),
          ),
        );

        await waitForAsyncProviders(tester);

        final pdfIconButtonFinder = find.widgetWithIcon(
          IconButton,
          Icons.picture_as_pdf,
        );
        await tester.tap(pdfIconButtonFinder);
        await tester.pumpAndSettle();

        expect(mockExporter.invocationCount, equals(1));
        expect(mockExporter.lastSummary, equals(dummySummary));
        expect(mockExporter.lastSummary!.scope.classId, equals(10));
        expect(mockExporter.lastSummary!.scope.studentId, equals(5));

        await tester.runAsync(() async => db.close());
      },
    );
  });
}
