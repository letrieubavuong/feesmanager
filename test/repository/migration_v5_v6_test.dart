import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tuition2027/core/database/app_database.dart';
import 'dart:io';
import 'package:path/path.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('Database Migration v5 -> v6', () {
    late String dbPath;

    setUp(() async {
      final tempDir = await Directory.systemTemp.createTemp('migration_test');
      dbPath = join(tempDir.path, 'test_migration.db');
    });

    test('v5 -> latest (v6) verification', () async {
      // 1. Create a v5 database manually
      final dbV5 = await openDatabase(
        dbPath,
        version: 5,
        onCreate: (db, version) async {
          await db.execute(
            'CREATE TABLE lop (id INTEGER PRIMARY KEY, ten_lop TEXT, da_luu_tru INTEGER, created_at TEXT, updated_at TEXT)',
          );
          await db.execute(
            'CREATE TABLE lich_hoc (id INTEGER PRIMARY KEY, id_lop INTEGER, thu_trong_tuan INTEGER, gio_bat_dau TEXT, gio_ket_thuc TEXT, hieu_luc_tu TEXT, hieu_luc_den TEXT, ghi_chu TEXT, created_at TEXT, updated_at TEXT, FOREIGN KEY (id_lop) REFERENCES lop (id))',
          );
          await db.insert('lop', {
            'id': 1,
            'ten_lop': 'Class V5',
            'da_luu_tru': 0,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          });
        },
      );
      await dbV5.close();

      // 2. Open with AppDatabase (should trigger migration to v6)
      final appDb = AppDatabase(dbName: dbPath);
      final db = await appDb.database;

      // 3. Verify version
      expect(await db.getVersion(), 6);

      // 4. Verify buoi_hoc table exists
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='buoi_hoc'",
      );
      expect(tables.length, 1);

      // 5. Verify FKs and Constraints on buoi_hoc
      await db.execute(
        "INSERT INTO buoi_hoc (id_lop, ngay, gio_bat_dau, gio_ket_thuc, loai, created_at, updated_at) VALUES (1, '2026-09-01', '17:30', '19:00', 'CHINH', 'now', 'now')",
      );

      // Test unique constraint (class, date, start_time)
      expect(
        () => db.execute(
          "INSERT INTO buoi_hoc (id_lop, ngay, gio_bat_dau, gio_ket_thuc, loai, created_at, updated_at) VALUES (1, '2026-09-01', '17:30', '19:00', 'CHINH', 'now', 'now')",
        ),
        throwsA(isA<DatabaseException>()),
      );

      // Test CHECK constraint (end > start)
      expect(
        () => db.execute(
          "INSERT INTO buoi_hoc (id_lop, ngay, gio_bat_dau, gio_ket_thuc, loai, created_at, updated_at) VALUES (1, '2026-09-02', '10:00', '09:00', 'CHINH', 'now', 'now')",
        ),
        throwsA(isA<DatabaseException>()),
      );

      // Verify old data preserved
      final classes = await db.query('lop');
      expect(classes.length, 1);
      expect(classes.first['ten_lop'], 'Class V5');

      await db.close();
    });

    test('Fresh Install v6 verification', () async {
      final appDb = AppDatabase(dbName: dbPath);
      final db = await appDb.database;

      expect(await db.getVersion(), 6);

      // buoi_hoc should exist
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='buoi_hoc'",
      );
      expect(tables.any((t) => t['name'] == 'buoi_hoc'), isTrue);

      // Verify PRAGMA foreign_key_check
      final fkCheck = await db.rawQuery('PRAGMA foreign_key_check');
      expect(fkCheck, isEmpty);

      await db.close();
    });
  });
}
