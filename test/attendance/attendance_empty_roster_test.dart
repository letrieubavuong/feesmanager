import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' hide equals;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tuition2027/core/database/app_database.dart';
import 'package:tuition2027/core/database/database_provider.dart';
import 'package:tuition2027/features/attendance/presentation/attendance_page.dart';
import 'package:tuition2027/l10n/app_localizations.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late String nowStr;

  setUp(() {
    nowStr = DateTime.now().toIso8601String();
  });

  Future<Database> createTestDb() async {
    final tempDir = await Directory.systemTemp.createTemp('att_ui_test');
    final dbPath = join(
      tempDir.path,
      'test_${DateTime.now().microsecondsSinceEpoch}.db',
    );
    final appDb = AppDatabase(dbName: dbPath);
    return await appDb.database;
  }

  testWidgets(
    'Phase 14B.1 Attendance UI: Empty PHAT_SINH roster shows Add Student button',
    (tester) async {
      final db = await createTestDb();

      await db.insert('lop', {
        'id': 1,
        'ten_lop': 'Lớp Vật Lý 10',
        'da_luu_tru': 0,
        'created_at': nowStr,
        'updated_at': nowStr,
      });

      // Session 1: PHAT_SINH with zero students
      await db.insert('buoi_hoc', {
        'id': 1,
        'id_lop': 1,
        'id_lich_hoc': null,
        'ngay': '2026-09-28',
        'gio_bat_dau': '18:00',
        'gio_ket_thuc': '19:30',
        'loai': 'PHAT_SINH',
        'trang_thai': 'DU_KIEN',
        'created_at': nowStr,
        'updated_at': nowStr,
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [databaseProvider.overrideWith((ref) async => db)],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: AttendancePage(sessionId: 1)),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Buổi học phát sinh'), findsOneWidget);
      expect(find.text('Thêm học sinh'), findsOneWidget);

      await db.close();
    },
  );

  testWidgets(
    'Phase 14B.1 Attendance UI: Empty HOC_BU roster shows guidance banner',
    (tester) async {
      final db = await createTestDb();

      await db.insert('lop', {
        'id': 1,
        'ten_lop': 'Lớp Vật Lý 10',
        'da_luu_tru': 0,
        'created_at': nowStr,
        'updated_at': nowStr,
      });

      // Session 2: HOC_BU with zero students
      await db.insert('buoi_hoc', {
        'id': 2,
        'id_lop': 1,
        'id_lich_hoc': null,
        'ngay': '2026-09-28',
        'gio_bat_dau': '18:00',
        'gio_ket_thuc': '19:30',
        'loai': 'HOC_BU',
        'trang_thai': 'DU_KIEN',
        'created_at': nowStr,
        'updated_at': nowStr,
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [databaseProvider.overrideWith((ref) async => db)],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: AttendancePage(sessionId: 2)),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Buổi học bù theo ca riêng'), findsOneWidget);

      await db.close();
    },
  );
}
