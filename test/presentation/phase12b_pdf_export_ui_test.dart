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
      'Export PDF button is enabled when summary resolves AsyncData',
      (tester) async {
        late Database db;
        await tester.runAsync(() async {
          db = await createTestDb();
        });

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
        expect(pdfIconButton.onPressed, isNotNull); // Enabled on AsyncData!

        await tester.runAsync(() async => db.close());
      },
    );
  });
}
