import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tuition2027/core/database/app_database.dart';
import 'package:tuition2027/core/database/database_provider.dart';
import 'package:tuition2027/features/classes/presentation/class_detail_page.dart';
import 'package:tuition2027/l10n/app_localizations.dart';

Future<void> waitForAsyncProviders(
  WidgetTester tester, {
  int iterations = 10,
}) async {
  for (int i = 0; i < iterations; i++) {
    await tester.runAsync(() async {
      await Future.delayed(const Duration(milliseconds: 50));
    });
    await tester.pump();
  }
}

Future<Database> createTestDb() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  final tempDir = await Directory.systemTemp.createTemp('composite_test');
  final dbPath = join(
    tempDir.path,
    'test_${DateTime.now().microsecondsSinceEpoch}.db',
  );
  final appDb = AppDatabase(dbName: dbPath);
  return await appDb.database;
}

void main() {
  group('Real ClassDetailPage Composite UI Acceptance Tests', () {
    late Database db;

    setUp(() async {
      db = await createTestDb();
      final nowStr = DateTime.now().toIso8601String();

      // Create Active Class (id: 1)
      await db.insert('lop', {
        'id': 1,
        'ten_lop': 'Toán 12 Active',
        'mon_hoc': 'Toán',
        'si_so_toi_da': 30,
        'da_luu_tru': 0,
        'created_at': nowStr,
        'updated_at': nowStr,
      });

      // Create Archived Class (id: 2)
      await db.insert('lop', {
        'id': 2,
        'ten_lop': 'Vật lý 10 Archived',
        'mon_hoc': 'Vật lý',
        'si_so_toi_da': 20,
        'da_luu_tru': 1,
        'created_at': nowStr,
        'updated_at': nowStr,
      });
    });

    tearDown(() async {
      await db.close();
    });

    testWidgets(
      'ACTIVE CLASS: tab-specific actions, schedule creation, session generation, no overlapping FABs',
      (tester) async {
        tester.view.physicalSize = const Size(1200, 2800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [databaseProvider.overrideWith((ref) async => db)],
            child: const MaterialApp(
              locale: Locale('vi'),
              localizationsDelegates: [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: AppLocalizations.supportedLocales,
              home: ClassDetailPage(classId: 1),
            ),
          ),
        );

        await waitForAsyncProviders(tester);

        // 1. Sĩ số tab: "+ Thêm học sinh" button is visible
        expect(find.text('Thêm học sinh'), findsOneWidget);

        // 2. Switch to Lịch sử tab: "+ Thêm học sinh" action is absent from Lịch sử view
        await tester.tap(find.text('Lịch sử'));
        await tester.pump(const Duration(milliseconds: 300));
        await waitForAsyncProviders(tester);

        // Verify that Lịch sử list does not contain "Thêm học sinh" button
        expect(
          find.descendant(
            of: find.byType(ListView),
            matching: find.widgetWithText(ElevatedButton, 'Thêm học sinh'),
          ),
          findsNothing,
        );

        // 3. Switch to Lịch học tab: "+ Thêm lịch học" visible and usable
        await tester.tap(find.text('Lịch học'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 300));
        await waitForAsyncProviders(tester);

        expect(find.text('Thêm lịch học'), findsAtLeast(1));

        // Open Schedule Modal Bottom Sheet
        await tester.tap(find.widgetWithText(ElevatedButton, 'Thêm lịch học'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await waitForAsyncProviders(tester);

        // Save schedule
        await tester.tap(find.text('Lưu'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await waitForAsyncProviders(tester);

        // Schedule list updates immediately
        expect(find.textContaining('17:30 - 19:00'), findsAtLeast(1));

        // 4. Switch to Buổi học tab: "Sinh buổi học" action visible
        await tester.tap(find.text('Buổi học'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 300));
        await waitForAsyncProviders(tester);

        expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
        expect(find.byIcon(Icons.add), findsOneWidget);
      },
    );

    testWidgets(
      'ARCHIVED CLASS: banner visible, historical tabs readable, creation actions absent/disabled',
      (tester) async {
        tester.view.physicalSize = const Size(1200, 2800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [databaseProvider.overrideWith((ref) async => db)],
            child: const MaterialApp(
              locale: Locale('vi'),
              localizationsDelegates: [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: AppLocalizations.supportedLocales,
              home: ClassDetailPage(classId: 2),
            ),
          ),
        );

        await waitForAsyncProviders(tester);

        // Clear archived banner is visible
        expect(
          find.text(
            'Lớp đã lưu trữ. Dữ liệu lịch sử vẫn được giữ nguyên. Khôi phục lớp để tiếp tục hoạt động.',
          ),
          findsOneWidget,
        );

        // Sĩ số tab: "+ Thêm học sinh" ABSENT
        expect(find.text('Thêm học sinh'), findsNothing);

        // Switch to Lịch học tab: "+ Thêm lịch học" ABSENT
        await tester.tap(find.text('Lịch học'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 300));
        await waitForAsyncProviders(tester);

        expect(find.text('Thêm lịch học'), findsNothing);

        // Switch to Buổi học tab: creation FABs ABSENT
        await tester.tap(find.text('Buổi học'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 300));
        await waitForAsyncProviders(tester);

        expect(find.byIcon(Icons.auto_awesome), findsNothing);
      },
    );
  });
}
