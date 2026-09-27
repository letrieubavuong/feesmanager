import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tuition2027/core/database/app_database.dart';
import 'package:tuition2027/core/database/database_provider.dart';
import 'package:tuition2027/features/memberships/presentation/enroll_student_bottom_sheet.dart';
import 'package:tuition2027/l10n/app_localizations.dart';

Future<void> waitForAsyncProviders(
  WidgetTester tester, {
  int iterations = 10,
}) async {
  for (int i = 0; i < iterations; i++) {
    await tester.runAsync(() async {
      await Future.delayed(const Duration(milliseconds: 50));
    });
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<Database> createTestDb() async {
  final tempDir = await Directory.systemTemp.createTemp('enrollment_two_flows');
  final dbPath = p.join(
    tempDir.path,
    'test_${DateTime.now().microsecondsSinceEpoch}.db',
  );
  final appDb = AppDatabase(dbName: dbPath);
  return await appDb.database;
}

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  group('Add Student Two Flows Tests', () {
    late Database db;

    setUp(() async {
      db = await createTestDb();
      final nowStr = DateTime.now().toIso8601String();

      // Create class 1
      await db.insert('lop', {
        'id': 1,
        'ten_lop': 'Lớp Anh Văn 12',
        'mon_hoc': 'Anh',
        'si_so_toi_da': 30,
        'da_luu_tru': 0,
        'created_at': nowStr,
        'updated_at': nowStr,
      });
    });

    tearDown(() async {
      await db.close();
    });

    testWidgets(
      'Option B: Thêm học sinh mới creates student profile and enrolls into class in one flow',
      (tester) async {
        tester.view.physicalSize = const Size(1200, 2800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [databaseProvider.overrideWith((ref) async => db)],
            child: MaterialApp(
              locale: const Locale('vi'),
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: Builder(
                  builder: (context) => ElevatedButton(
                    onPressed: () =>
                        showEnrollStudentBottomSheet(context, classId: 1),
                    child: const Text('Open Sheet'),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open Sheet'));
        await tester.pump(const Duration(milliseconds: 300));
        await waitForAsyncProviders(tester);

        // Switch to Option B: Thêm HS mới
        await tester.tap(find.text('Thêm HS mới'));
        await tester.pump(const Duration(milliseconds: 300));
        await waitForAsyncProviders(tester);

        // Enter new student name
        final nameField = find.byType(TextFormField).first;
        await tester.enterText(nameField, 'Nguyễn Văn Mới');
        await tester.pump(const Duration(milliseconds: 300));

        // Save
        await tester.tap(find.text('Lưu'));
        await waitForAsyncProviders(tester);
        await tester.pump(const Duration(milliseconds: 300));

        // Verify student is created in DB
        final studentsInDb = await db.query(
          'hoc_sinh',
          where: 'ho_ten = ?',
          whereArgs: ['Nguyễn Văn Mới'],
        );
        expect(studentsInDb.length, equals(1));

        // Verify membership row created in DB
        final membershipsInDb = await db.query(
          'tham_gia_lop',
          where: 'id_lop = ?',
          whereArgs: [1],
        );
        expect(membershipsInDb.length, equals(1));
      },
    );
  });
}
