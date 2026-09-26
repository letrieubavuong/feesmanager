import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tuition2027/app/navigation/ui_keys.dart';
import 'package:tuition2027/core/database/app_database.dart';
import 'package:tuition2027/core/database/database_provider.dart';
import 'package:tuition2027/features/memberships/presentation/enroll_student_bottom_sheet.dart';
import 'package:tuition2027/l10n/app_localizations.dart';

Future<void> waitForAsyncProviders(
  WidgetTester tester, {
  int iterations = 20,
}) async {
  for (int i = 0; i < iterations; i++) {
    await tester.runAsync(() async {
      await Future.delayed(const Duration(milliseconds: 50));
    });
    await tester.pump();
  }
}

Future<void> dismissSnackBar(WidgetTester tester) async {
  final scaffolds = find.byType(Scaffold).evaluate();
  if (scaffolds.isNotEmpty) {
    try {
      ScaffoldMessenger.of(scaffolds.first).clearSnackBars();
      await tester.pump();
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
    } catch (_) {}
  }
}

Future<Database> createTestDb() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  final tempDir = await Directory.systemTemp.createTemp('enrollment_test');
  final dbPath = join(
    tempDir.path,
    'test_${DateTime.now().microsecondsSinceEpoch}.db',
  );
  final appDb = AppDatabase(dbName: dbPath);
  return await appDb.database;
}

void main() {
  group('Enrollment Candidate Filtering Tests', () {
    late Database db;

    setUp(() async {
      db = await createTestDb();
      final nowStr = DateTime.now().toIso8601String();

      // Create class 1
      await db.insert('lop', {
        'id': 1,
        'ten_lop': 'Lớp Lập Trình 10',
        'mon_hoc': 'Toán',
        'si_so_toi_da': 30,
        'da_luu_tru': 0,
        'created_at': nowStr,
        'updated_at': nowStr,
      });

      // Create student A (id: 1)
      await db.insert('hoc_sinh', {
        'id': 1,
        'ho_ten': 'Nguyễn Văn A',
        'sdt_phu_huynh': '0901234567',
        'da_luu_tru': 0,
        'created_at': nowStr,
        'updated_at': nowStr,
      });

      // Create student B (id: 2)
      await db.insert('hoc_sinh', {
        'id': 2,
        'ho_ten': 'Trần Thị B',
        'sdt_phu_huynh': '0907654321',
        'da_luu_tru': 0,
        'created_at': nowStr,
        'updated_at': nowStr,
      });
    });

    tearDown(() async {
      await db.close();
    });

    testWidgets(
      'A and B active students -> enroll A into class -> reopen selector -> A absent, B present',
      (tester) async {
        int sheetKey = 1;
        Widget buildApp() {
          return ProviderScope(
            overrides: [databaseProvider.overrideWith((ref) async => db)],
            child: MaterialApp(
              key: ValueKey(sheetKey),
              locale: const Locale('vi'),
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: EnrollStudentBottomSheet(
                  key: ValueKey(sheetKey),
                  classId: 1,
                ),
              ),
            ),
          );
        }

        await tester.pumpWidget(buildApp());
        await waitForAsyncProviders(tester);

        final selectorKey = find.byKey(UiKeys.enrollStudentSelector);
        expect(selectorKey, findsOneWidget);

        // Open candidate selector
        await tester.tap(selectorKey);
        await waitForAsyncProviders(tester);

        final itemA = find.widgetWithText(ListTile, 'Nguyễn Văn A');
        final itemB = find.widgetWithText(ListTile, 'Trần Thị B');

        // Both A and B must be present in candidate selector dialog
        expect(itemA, findsOneWidget);
        expect(itemB, findsOneWidget);

        // Select A
        await tester.tap(itemA);
        await waitForAsyncProviders(tester);

        // Submit enrollment for A
        await tester.tap(find.text('Lưu'));
        await waitForAsyncProviders(tester);
        await dismissSnackBar(tester);

        // Re-pump widget with new key to reopen fresh sheet
        sheetKey++;
        await tester.pumpWidget(buildApp());
        await waitForAsyncProviders(tester);

        // Open candidate selector
        await tester.tap(selectorKey);
        await waitForAsyncProviders(tester);

        // A must be ABSENT, B must be PRESENT in candidate selector dialog
        expect(itemA, findsNothing);
        expect(itemB, findsOneWidget);
      },
    );
  });
}
