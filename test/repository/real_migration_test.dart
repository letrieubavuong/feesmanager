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

  group('AppDatabase Migration Hardening', () {
    test('v1 -> latest (v3) verification', () async {
      // Create v1 db
      final dbV1 = await openDatabase(
        dbPath,
        version: 1,
        onCreate: (db, version) async {
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
        },
      );

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
      final dbV3 = await appDb.database;

      final student = await dbV3.query('hoc_sinh', where: 'id = 100');
      expect(student.length, 1);

      // Verify tables exist
      final tables = await dbV3.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name IN ('lop', 'tham_gia_lop')",
      );
      expect(tables.length, 2);

      // Verify Foreign Keys in v3
      final fkList = await dbV3.rawQuery(
        'PRAGMA foreign_key_list(tham_gia_lop)',
      );
      final hasStudentFk = fkList.any(
        (fk) => fk['table'] == 'hoc_sinh' && fk['from'] == 'id_hoc_sinh',
      );
      final hasClassFk = fkList.any(
        (fk) => fk['table'] == 'lop' && fk['from'] == 'id_lop',
      );

      expect(
        hasStudentFk,
        isTrue,
        reason: 'Missing id_hoc_sinh -> hoc_sinh(id) FK',
      );
      expect(hasClassFk, isTrue, reason: 'Missing id_lop -> lop(id) FK');

      await dbV3.close();
    });

    test('v2 -> v3 (added constraints and preserved FKs)', () async {
      final dbV2 = await openDatabase(
        dbPath,
        version: 2,
        onCreate: (db, version) async {
          await db.execute(
            'CREATE TABLE hoc_sinh (id INTEGER PRIMARY KEY, ho_ten TEXT NOT NULL, created_at TEXT NOT NULL, updated_at TEXT NOT NULL)',
          );
          await db.execute(
            'CREATE TABLE lop (id INTEGER PRIMARY KEY, ten_lop TEXT NOT NULL, created_at TEXT NOT NULL, updated_at TEXT NOT NULL)',
          );
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
            updated_at TEXT NOT NULL,
            FOREIGN KEY (id_hoc_sinh) REFERENCES hoc_sinh (id),
            FOREIGN KEY (id_lop) REFERENCES lop (id)
          )
        ''');
        },
      );

      // Insert valid data in v2
      await dbV2.insert('hoc_sinh', {
        'id': 1,
        'ho_ten': 'Student 1',
        'created_at': '...',
        'updated_at': '...',
      });
      await dbV2.insert('lop', {
        'id': 1,
        'ten_lop': 'Class 1',
        'created_at': '...',
        'updated_at': '...',
      });
      await dbV2.insert('tham_gia_lop', {
        'id': 300,
        'id_hoc_sinh': 1,
        'id_lop': 1,
        'tu_ngay': '2026-09-01',
        'den_ngay': '2026-10-01',
        'mien_giam_phan_tram': 50,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      await dbV2.close();

      // Upgrade to v3
      final appDb = AppDatabase(dbName: dbPath);
      final dbV3 = await appDb.database;

      // Verify preservation
      final row = await dbV3.query('tham_gia_lop', where: 'id = 300');
      expect(row.length, 1);
      expect(row.first['id_hoc_sinh'], 1);

      // Verify FKs preserved
      final fkList = await dbV3.rawQuery(
        'PRAGMA foreign_key_list(tham_gia_lop)',
      );
      expect(fkList.any((fk) => fk['table'] == 'hoc_sinh'), isTrue);
      expect(fkList.any((fk) => fk['table'] == 'lop'), isTrue);

      // Verify constraints enforced in v3
      await dbV3.execute('PRAGMA foreign_keys = ON');

      // Invalid student FK
      expect(
        () => dbV3.insert('tham_gia_lop', {
          'id_hoc_sinh': 999,
          'id_lop': 1,
          'tu_ngay': '2026-11-01',
          'created_at': '...',
          'updated_at': '...',
        }),
        throwsA(isA<DatabaseException>()),
      );

      // Invalid mien_giam range
      expect(
        () => dbV3.insert('tham_gia_lop', {
          'id_hoc_sinh': 1,
          'id_lop': 1,
          'tu_ngay': '2026-11-01',
          'mien_giam_phan_tram': 101,
          'created_at': '...',
          'updated_at': '...',
        }),
        throwsA(isA<DatabaseException>()),
      );

      await dbV3.close();
    });
  });
}
