import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:tuition2027/core/database/app_database.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late String dbPath;

  setUp(() async {
    final tempDir = await Directory.systemTemp.createTemp('migration_test');
    dbPath = join(tempDir.path, 'test_migration.db');
  });

  group('AppDatabase Migration', () {
    test('v1 -> v3 (fresh install simulator)', () async {
      // Create v1 db
      final dbV1 = await openDatabase(dbPath, version: 1, onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE hoc_sinh (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            ho_ten TEXT NOT NULL,
            ngay_sinh TEXT NULL,
            gioi_tinh TEXT NULL,
            ten_phu_huynh TEXT NULL,
            sdt_phu_huynh TEXT NULL,
            sdt_hoc_sinh TEXT NULL,
            email TEXT NULL,
            truong_dang_hoc TEXT NULL,
            khoi INTEGER NULL,
            dia_chi TEXT NULL,
            facebook TEXT NULL,
            ghi_chu TEXT NULL,
            zalo_user_id TEXT NULL,
            zalo_display_name TEXT NULL,
            zalo_link_status TEXT NOT NULL DEFAULT 'CHUA_LIEN_KET',
            da_luu_tru INTEGER NOT NULL DEFAULT 0,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');
      });

      await dbV1.insert('hoc_sinh', {
        'id': 100,
        'ho_ten': 'Legacy Student',
        'zalo_link_status': 'CHUA_LIEN_KET',
        'da_luu_tru': 0,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      await dbV1.close();

      // Upgrade to latest using AppDatabase
      final appDb = AppDatabase(dbName: dbPath);
      // Overriding directory for test
      // AppDatabase currently uses getDatabasesPath(). 
      // For ffi on windows it usually points to a local folder.
      // Let's just use the absolute path in AppDatabase constructor by refactoring it to accept full path or just name.
      // Actually we refactored it to accept dbName. Let's make sure it works.
      
      final dbV3 = await appDb.database;
      
      final student = await dbV3.query('hoc_sinh', where: 'id = 100');
      expect(student.length, 1);
      expect(student.first['ho_ten'], 'Legacy Student');

      // Check if new tables exist
      final tables = await dbV3.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name IN ('lop', 'tham_gia_lop')");
      expect(tables.length, 2);

      expect(await dbV3.getVersion(), 3);
      await dbV3.close();
    });

    test('v2 -> v3 (added constraints)', () async {
       final dbV2 = await openDatabase(dbPath, version: 2, onCreate: (db, version) async {
        // Mock v2 creation (tables from v1 + v2 migration)
        await db.execute('CREATE TABLE hoc_sinh (id INTEGER PRIMARY KEY, ho_ten TEXT NOT NULL, created_at TEXT NOT NULL, updated_at TEXT NOT NULL)');
        await db.execute('CREATE TABLE lop (id INTEGER PRIMARY KEY, ten_lop TEXT NOT NULL, created_at TEXT NOT NULL, updated_at TEXT NOT NULL)');
        await db.execute('''
          CREATE TABLE tham_gia_lop (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            id_hoc_sinh INTEGER NOT NULL,
            id_lop INTEGER NOT NULL,
            tu_ngay TEXT NOT NULL,
            den_ngay TEXT NULL,
            ly_do_ket_thuc TEXT NULL,
            mien_giam_phan_tram INTEGER NOT NULL DEFAULT 0,
            ghi_chu TEXT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');
      });

      await dbV2.insert('tham_gia_lop', {
        'id_hoc_sinh': 1,
        'id_lop': 1,
        'tu_ngay': '2026-09-01',
        'den_ngay': '2026-10-01', // Valid in v3
        'mien_giam_phan_tram': 50, // Valid in v3
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      await dbV2.close();

      // Upgrade to v3
      final appDb = AppDatabase(dbName: dbPath);
      
      // We need to disable foreign keys during migration in AppDatabase if we want to copy data 
      // where children were inserted before parents (though usually it's fine if they already exist).
      // In this test, parents DO exist but FK check might be sensitive during table swap.
      final dbV3 = await appDb.database;

      final row = await dbV3.query('tham_gia_lop');
      expect(row.length, 1);
      expect(row.first['mien_giam_phan_tram'], 50);

      // Verify constraints now work
      expect(
        () => dbV3.insert('tham_gia_lop', {
          'id_hoc_sinh': 1,
          'id_lop': 1,
          'tu_ngay': '2026-10-01',
          'den_ngay': '2026-09-01', // CHECK(den_ngay >= tu_ngay)
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        }),
        throwsA(isA<DatabaseException>()),
      );

      expect(
        () => dbV3.insert('tham_gia_lop', {
          'id_hoc_sinh': 1,
          'id_lop': 1,
          'tu_ngay': '2026-10-01',
          'mien_giam_phan_tram': -1, // CHECK(between 0 and 100)
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        }),
        throwsA(isA<DatabaseException>()),
      );

      await dbV3.close();
    });
  });
}
