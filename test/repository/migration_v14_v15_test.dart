// ignore_for_file: non_constant_identifier_names

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:tuition2027/core/database/app_database.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('Migration v14 to v15 Idempotency Tests', () {
    late String dbPath;

    setUp(() async {
      final tempDir = await Directory.systemTemp.createTemp(
        'migration_v14_v15_test',
      );
      dbPath = join(tempDir.path, 'migration_v14_v15.db');
    });

    test(
      'TEST A: Normal v14 database upgrades to v15 creating diem_danh_chinh_sua audit table',
      () async {
        final dbV14 = await openDatabase(
          dbPath,
          version: 14,
          onConfigure: (db) async =>
              await db.execute('PRAGMA foreign_keys = ON'),
          onCreate: (db, version) async {
            await db.execute('''
              CREATE TABLE hoc_sinh (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                ho_ten TEXT NOT NULL,
                da_luu_tru INTEGER NOT NULL DEFAULT 0,
                created_at TEXT NOT NULL,
                updated_at TEXT NOT NULL
              )
            ''');
            await db.execute('''
              CREATE TABLE lop (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                ten_lop TEXT NOT NULL,
                da_luu_tru INTEGER NOT NULL DEFAULT 0,
                created_at TEXT NOT NULL,
                updated_at TEXT NOT NULL
              )
            ''');
            await db.execute('''
              CREATE TABLE buoi_hoc (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                id_lop INTEGER NOT NULL,
                ngay TEXT NOT NULL,
                gio_bat_dau TEXT NOT NULL,
                gio_ket_thuc TEXT NOT NULL,
                loai TEXT NOT NULL,
                trang_thai TEXT NOT NULL DEFAULT 'DA_HOC',
                created_at TEXT NOT NULL,
                updated_at TEXT NOT NULL,
                FOREIGN KEY (id_lop) REFERENCES lop (id)
              )
            ''');
            await db.execute('''
              CREATE TABLE diem_danh (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                id_buoi_hoc INTEGER NOT NULL,
                id_hoc_sinh INTEGER NOT NULL,
                id_lop_goc INTEGER NOT NULL,
                loai_tham_gia TEXT NOT NULL DEFAULT 'CHINH_THUC',
                trang_thai TEXT NOT NULL,
                ghi_chu TEXT NULL,
                created_at TEXT NOT NULL,
                updated_at TEXT NOT NULL,
                FOREIGN KEY (id_buoi_hoc) REFERENCES buoi_hoc (id) ON DELETE RESTRICT,
                FOREIGN KEY (id_hoc_sinh) REFERENCES hoc_sinh (id) ON DELETE RESTRICT,
                FOREIGN KEY (id_lop_goc) REFERENCES lop (id) ON DELETE RESTRICT
              )
            ''');

            await db.execute(
              "INSERT INTO hoc_sinh (id, ho_ten, created_at, updated_at) VALUES (1, 'Student 1', '2026-01-01', '2026-01-01')",
            );
            await db.execute(
              "INSERT INTO lop (id, ten_lop, created_at, updated_at) VALUES (1, 'Class 1', '2026-01-01', '2026-01-01')",
            );
            await db.execute(
              "INSERT INTO buoi_hoc (id, id_lop, ngay, gio_bat_dau, gio_ket_thuc, loai, created_at, updated_at) VALUES (1, 1, '2026-09-01', '17:30', '19:00', 'CHINH', '2026-01-01', '2026-01-01')",
            );
          },
        );
        await dbV14.close();

        final appDb = AppDatabase(dbName: dbPath);
        final dbV15 = await appDb.database;

        expect(await dbV15.getVersion(), AppDatabase.schemaVersion);

        final auditTable = await dbV15.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='diem_danh_chinh_sua'",
        );
        expect(auditTable, isNotEmpty);

        final indexes = await dbV15.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='index' AND tbl_name='diem_danh_chinh_sua'",
        );
        final indexNames = indexes.map((i) => i['name']).toSet();
        expect(indexNames.contains('idx_diem_danh_chinh_sua_buoi_hoc'), isTrue);
        expect(indexNames.contains('idx_diem_danh_chinh_sua_hoc_sinh'), isTrue);

        final fkCheck = await dbV15.rawQuery('PRAGMA foreign_key_check');
        expect(fkCheck, isEmpty);

        await dbV15.close();
      },
    );

    test(
      'TEST B: Precreated diem_danh_chinh_sua table in v14 database upgrades safely without error and preserves existing audit rows',
      () async {
        final dbV14 = await openDatabase(
          dbPath,
          version: 14,
          onConfigure: (db) async =>
              await db.execute('PRAGMA foreign_keys = ON'),
          onCreate: (db, version) async {
            await db.execute('''
              CREATE TABLE hoc_sinh (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                ho_ten TEXT NOT NULL,
                da_luu_tru INTEGER NOT NULL DEFAULT 0,
                created_at TEXT NOT NULL,
                updated_at TEXT NOT NULL
              )
            ''');
            await db.execute('''
              CREATE TABLE lop (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                ten_lop TEXT NOT NULL,
                da_luu_tru INTEGER NOT NULL DEFAULT 0,
                created_at TEXT NOT NULL,
                updated_at TEXT NOT NULL
              )
            ''');
            await db.execute('''
              CREATE TABLE buoi_hoc (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                id_lop INTEGER NOT NULL,
                ngay TEXT NOT NULL,
                gio_bat_dau TEXT NOT NULL,
                gio_ket_thuc TEXT NOT NULL,
                loai TEXT NOT NULL,
                trang_thai TEXT NOT NULL DEFAULT 'DA_HOC',
                created_at TEXT NOT NULL,
                updated_at TEXT NOT NULL
              )
            ''');
            await db.execute('''
              CREATE TABLE diem_danh_chinh_sua (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                id_diem_danh INTEGER NULL,
                id_buoi_hoc INTEGER NOT NULL,
                id_hoc_sinh INTEGER NOT NULL,
                trang_thai_cu TEXT NULL,
                trang_thai_moi TEXT NOT NULL,
                ly_do TEXT NOT NULL,
                changed_at TEXT NOT NULL
              )
            ''');

            await db.execute(
              "INSERT INTO hoc_sinh (id, ho_ten, created_at, updated_at) VALUES (1, 'Student 1', '2026-01-01', '2026-01-01')",
            );
            await db.execute(
              "INSERT INTO lop (id, ten_lop, created_at, updated_at) VALUES (1, 'Class 1', '2026-01-01', '2026-01-01')",
            );
            await db.execute(
              "INSERT INTO buoi_hoc (id, id_lop, ngay, gio_bat_dau, gio_ket_thuc, loai, created_at, updated_at) VALUES (1, 1, '2026-09-01', '17:30', '19:00', 'CHINH', '2026-01-01', '2026-01-01')",
            );
            await db.execute('''
              INSERT INTO diem_danh_chinh_sua (id, id_diem_danh, id_buoi_hoc, id_hoc_sinh, trang_thai_cu, trang_thai_moi, ly_do, changed_at)
              VALUES (99, NULL, 1, 1, 'CO_MAT', 'TRE', 'Nhập nhầm', '2026-09-28T10:00:00')
            ''');
          },
        );
        await dbV14.close();

        final appDb = AppDatabase(dbName: dbPath);
        final dbV15 = await appDb.database;

        expect(await dbV15.getVersion(), AppDatabase.schemaVersion);

        final auditRows = await dbV15.rawQuery(
          'SELECT * FROM diem_danh_chinh_sua WHERE id = 99',
        );
        expect(auditRows.length, 1);
        expect(auditRows.first['ly_do'], 'Nhập nhầm');

        final countResult = Sqflite.firstIntValue(
          await dbV15.rawQuery('SELECT COUNT(*) FROM diem_danh_chinh_sua'),
        );
        expect(countResult, 1);

        final indexes = await dbV15.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='index' AND tbl_name='diem_danh_chinh_sua'",
        );
        final indexNames = indexes.map((i) => i['name']).toSet();
        expect(indexNames.contains('idx_diem_danh_chinh_sua_buoi_hoc'), isTrue);
        expect(indexNames.contains('idx_diem_danh_chinh_sua_hoc_sinh'), isTrue);

        await dbV15.close();
      },
    );

    test(
      'TEST C: Partial index state recovers indexes cleanly when table exists without indexes',
      () async {
        final dbV14 = await openDatabase(
          dbPath,
          version: 14,
          onConfigure: (db) async =>
              await db.execute('PRAGMA foreign_keys = ON'),
          onCreate: (db, version) async {
            await db.execute('''
              CREATE TABLE hoc_sinh (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                ho_ten TEXT NOT NULL,
                da_luu_tru INTEGER NOT NULL DEFAULT 0,
                created_at TEXT NOT NULL,
                updated_at TEXT NOT NULL
              )
            ''');
            await db.execute('''
              CREATE TABLE lop (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                ten_lop TEXT NOT NULL,
                da_luu_tru INTEGER NOT NULL DEFAULT 0,
                created_at TEXT NOT NULL,
                updated_at TEXT NOT NULL
              )
            ''');
            await db.execute('''
              CREATE TABLE buoi_hoc (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                id_lop INTEGER NOT NULL,
                ngay TEXT NOT NULL,
                gio_bat_dau TEXT NOT NULL,
                gio_ket_thuc TEXT NOT NULL,
                loai TEXT NOT NULL,
                trang_thai TEXT NOT NULL DEFAULT 'DA_HOC',
                created_at TEXT NOT NULL,
                updated_at TEXT NOT NULL
              )
            ''');
            await db.execute('''
              CREATE TABLE diem_danh_chinh_sua (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                id_diem_danh INTEGER NULL,
                id_buoi_hoc INTEGER NOT NULL,
                id_hoc_sinh INTEGER NOT NULL,
                trang_thai_cu TEXT NULL,
                trang_thai_moi TEXT NOT NULL,
                ly_do TEXT NOT NULL,
                changed_at TEXT NOT NULL
              )
            ''');
          },
        );
        await dbV14.close();

        final appDb = AppDatabase(dbName: dbPath);
        final dbV15 = await appDb.database;

        expect(await dbV15.getVersion(), AppDatabase.schemaVersion);

        final indexes = await dbV15.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='index' AND tbl_name='diem_danh_chinh_sua'",
        );
        final indexNames = indexes.map((i) => i['name']).toSet();
        expect(indexNames.contains('idx_diem_danh_chinh_sua_buoi_hoc'), isTrue);
        expect(indexNames.contains('idx_diem_danh_chinh_sua_hoc_sinh'), isTrue);

        await dbV15.close();
      },
    );

    test(
      'TEST D: Reopening upgraded v15 database completes without errors',
      () async {
        final appDb1 = AppDatabase(dbName: dbPath);
        final db1 = await appDb1.database;
        expect(await db1.getVersion(), AppDatabase.schemaVersion);
        await db1.execute('''
        INSERT INTO hoc_sinh (id, ho_ten, created_at, updated_at)
        VALUES (10, 'Student 10', '2026-01-01', '2026-01-01')
      ''');
        await db1.execute('''
        INSERT INTO lop (id, ten_lop, created_at, updated_at)
        VALUES (10, 'Class 10', '2026-01-01', '2026-01-01')
      ''');
        await db1.execute('''
        INSERT INTO buoi_hoc (id, id_lop, ngay, gio_bat_dau, gio_ket_thuc, loai, created_at, updated_at)
        VALUES (10, 10, '2026-09-01', '17:30', '19:00', 'CHINH', '2026-01-01', '2026-01-01')
      ''');
        await db1.execute('''
        INSERT INTO diem_danh_chinh_sua (id, id_diem_danh, id_buoi_hoc, id_hoc_sinh, trang_thai_cu, trang_thai_moi, ly_do, changed_at)
        VALUES (100, NULL, 10, 10, 'CO_MAT', 'VANG', 'Sửa lại điểm danh', '2026-09-28T11:00:00')
      ''');
        await db1.close();

        final appDb2 = AppDatabase(dbName: dbPath);
        final db2 = await appDb2.database;
        expect(await db2.getVersion(), AppDatabase.schemaVersion);

        final row = await db2.rawQuery(
          'SELECT * FROM diem_danh_chinh_sua WHERE id = 100',
        );
        expect(row.length, 1);
        expect(row.first['ly_do'], 'Sửa lại điểm danh');

        await db2.close();
      },
    );

    test(
      'TEST E: Fresh installation on empty database creates all audit tables and indexes at version 15',
      () async {
        final appDb = AppDatabase(dbName: dbPath);
        final db = await appDb.database;

        expect(await db.getVersion(), AppDatabase.schemaVersion);

        final tables = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name IN ('diem_danh_chinh_sua', 'thanh_toan_chinh_sua', 'hoc_phi_chinh_sua')",
        );
        expect(tables.length, 3);

        final fkCheck = await db.rawQuery('PRAGMA foreign_key_check');
        expect(fkCheck, isEmpty);

        await db.close();
      },
    );
  });
}
