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

    test('v5 -> latest (v6) verification with full data chain', () async {
      // 1. Create a v5 database with full chain of Phase 1-3 data
      final dbV5 = await openDatabase(
        dbPath,
        version: 5,
        onCreate: (db, version) async {
          await db.execute('''
          CREATE TABLE hoc_sinh (
            id INTEGER PRIMARY KEY,
            ho_ten TEXT,
            da_luu_tru INTEGER,
            created_at TEXT,
            updated_at TEXT
          )
        ''');
          await db.execute('''
          CREATE TABLE lop (
            id INTEGER PRIMARY KEY,
            ten_lop TEXT,
            da_luu_tru INTEGER,
            created_at TEXT,
            updated_at TEXT
          )
        ''');
          await db.execute('''
          CREATE TABLE tham_gia_lop (
            id INTEGER PRIMARY KEY,
            id_hoc_sinh INTEGER,
            id_lop INTEGER,
            tu_ngay TEXT,
            den_ngay TEXT,
            mien_giam_phan_tram INTEGER,
            created_at TEXT,
            updated_at TEXT,
            FOREIGN KEY (id_hoc_sinh) REFERENCES hoc_sinh (id),
            FOREIGN KEY (id_lop) REFERENCES lop (id)
          )
        ''');
          await db.execute('''
          CREATE TABLE lich_hoc (
            id INTEGER PRIMARY KEY,
            id_lop INTEGER,
            thu_trong_tuan INTEGER,
            gio_bat_dau TEXT,
            gio_ket_thuc TEXT,
            hieu_luc_tu TEXT,
            hieu_luc_den TEXT,
            created_at TEXT,
            updated_at TEXT,
            FOREIGN KEY (id_lop) REFERENCES lop (id)
          )
        ''');
          await db.execute('''
          CREATE TABLE phan_ca_hoc_sinh (
            id INTEGER PRIMARY KEY,
            id_hoc_sinh INTEGER,
            id_lop INTEGER,
            id_lich_hoc INTEGER,
            tu_ngay TEXT,
            den_ngay TEXT,
            created_at TEXT,
            updated_at TEXT,
            FOREIGN KEY (id_hoc_sinh) REFERENCES hoc_sinh (id),
            FOREIGN KEY (id_lop) REFERENCES lop (id),
            FOREIGN KEY (id_lich_hoc) REFERENCES lich_hoc (id)
          )
        ''');

          // Insert data with specific IDs
          await db.insert('hoc_sinh', {
            'id': 11,
            'ho_ten': 'S11',
            'da_luu_tru': 0,
            'created_at': '2026-01-01',
            'updated_at': '2026-01-01',
          });
          await db.insert('lop', {
            'id': 21,
            'ten_lop': 'C21',
            'da_luu_tru': 0,
            'created_at': '2026-01-01',
            'updated_at': '2026-01-01',
          });
          await db.insert('tham_gia_lop', {
            'id': 31,
            'id_hoc_sinh': 11,
            'id_lop': 21,
            'tu_ngay': '2026-09-01',
            'mien_giam_phan_tram': 0,
            'created_at': '2026-01-01',
            'updated_at': '2026-01-01',
          });
          await db.insert('lich_hoc', {
            'id': 41,
            'id_lop': 21,
            'thu_trong_tuan': 1,
            'gio_bat_dau': '17:30',
            'gio_ket_thuc': '19:00',
            'hieu_luc_tu': '2026-09-01',
            'created_at': '2026-01-01',
            'updated_at': '2026-01-01',
          });
          await db.insert('phan_ca_hoc_sinh', {
            'id': 51,
            'id_hoc_sinh': 11,
            'id_lop': 21,
            'id_lich_hoc': 41,
            'tu_ngay': '2026-09-01',
            'created_at': '2026-01-01',
            'updated_at': '2026-01-01',
          });
        },
      );
      await dbV5.close();

      // 2. Open with AppDatabase (migration to v7)
      final appDb = AppDatabase(dbName: dbPath);
      final db = await appDb.database;

      // 3. Verify version
      expect(await db.getVersion(), 8);

      // 4. Verify Phase 1-3 data preservation
      final student = (await db.query('hoc_sinh', where: 'id = 11')).first;
      expect(student['ho_ten'], 'S11');

      final cls = (await db.query('lop', where: 'id = 21')).first;
      expect(cls['ten_lop'], 'C21');

      final membership = (await db.query(
        'tham_gia_lop',
        where: 'id = 31',
      )).first;
      expect(membership['id_hoc_sinh'], 11);
      expect(membership['id_lop'], 21);
      expect(membership['tu_ngay'], '2026-09-01');

      final schedule = (await db.query('lich_hoc', where: 'id = 41')).first;
      expect(schedule['id_lop'], 21);
      expect(schedule['gio_bat_dau'], '17:30');

      final assignment = (await db.query(
        'phan_ca_hoc_sinh',
        where: 'id = 51',
      )).first;
      expect(assignment['id_lich_hoc'], 41);
      expect(assignment['tu_ngay'], '2026-09-01');

      // 5. Verify buoi_hoc FKs and constraints
      final fks = await db.rawQuery("PRAGMA foreign_key_list(buoi_hoc)");
      expect(fks.any((f) => f['table'] == 'lop'), isTrue);
      expect(fks.any((f) => f['table'] == 'lich_hoc'), isTrue);

      // 6. DB Constraint Tests
      // Invalid class FK
      expect(
        () => db.execute(
          "INSERT INTO buoi_hoc (id_lop, ngay, gio_bat_dau, gio_ket_thuc, loai, created_at, updated_at) VALUES (999, '2026-09-01', '17:30', '19:00', 'CHINH', 'now', 'now')",
        ),
        throwsA(isA<DatabaseException>()),
      );

      // Invalid non-null schedule FK
      expect(
        () => db.execute(
          "INSERT INTO buoi_hoc (id_lop, id_lich_hoc, ngay, gio_bat_dau, gio_ket_thuc, loai, created_at, updated_at) VALUES (21, 999, '2026-09-01', '17:30', '19:00', 'CHINH', 'now', 'now')",
        ),
        throwsA(isA<DatabaseException>()),
      );

      // Valid null schedule FK
      await db.execute(
        "INSERT INTO buoi_hoc (id_lop, id_lich_hoc, ngay, gio_bat_dau, gio_ket_thuc, loai, created_at, updated_at) VALUES (21, NULL, '2026-09-10', '10:00', '11:00', 'HOC_BU', 'now', 'now')",
      );

      // Invalid loai
      expect(
        () => db.execute(
          "INSERT INTO buoi_hoc (id_lop, ngay, gio_bat_dau, gio_ket_thuc, loai, created_at, updated_at) VALUES (21, '2026-09-11', '17:30', '19:00', 'INVALID', 'now', 'now')",
        ),
        throwsA(isA<DatabaseException>()),
      );

      // Invalid status
      expect(
        () => db.execute(
          "INSERT INTO buoi_hoc (id_lop, ngay, gio_bat_dau, gio_ket_thuc, loai, trang_thai, created_at, updated_at) VALUES (21, '2026-09-11', '17:30', '19:00', 'CHINH', 'INVALID', 'now', 'now')",
        ),
        throwsA(isA<DatabaseException>()),
      );

      // end == start
      expect(
        () => db.execute(
          "INSERT INTO buoi_hoc (id_lop, ngay, gio_bat_dau, gio_ket_thuc, loai, created_at, updated_at) VALUES (21, '2026-09-12', '10:00', '10:00', 'CHINH', 'now', 'now')",
        ),
        throwsA(isA<DatabaseException>()),
      );

      // end < start
      expect(
        () => db.execute(
          "INSERT INTO buoi_hoc (id_lop, ngay, gio_bat_dau, gio_ket_thuc, loai, created_at, updated_at) VALUES (21, '2026-09-12', '10:00', '09:00', 'CHINH', 'now', 'now')",
        ),
        throwsA(isA<DatabaseException>()),
      );

      // duplicate identity
      await db.execute(
        "INSERT INTO buoi_hoc (id_lop, ngay, gio_bat_dau, gio_ket_thuc, loai, created_at, updated_at) VALUES (21, '2026-09-20', '08:00', '09:00', 'CHINH', 'now', 'now')",
      );
      expect(
        () => db.execute(
          "INSERT INTO buoi_hoc (id_lop, ngay, gio_bat_dau, gio_ket_thuc, loai, created_at, updated_at) VALUES (21, '2026-09-20', '08:00', '10:00', 'HOC_BU', 'now', 'now')",
        ),
        throwsA(isA<DatabaseException>()),
      );

      await db.close();
    });

    test('Fresh Install latest verification', () async {
      final appDb = AppDatabase(dbName: dbPath);
      final db = await appDb.database;

      expect(await db.getVersion(), 8);

      // All Phase 0-4 tables exist
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table'",
      );
      final tableNames = tables.map((t) => t['name'] as String).toList();
      expect(
        tableNames,
        containsAll([
          'hoc_sinh',
          'lop',
          'tham_gia_lop',
          'lich_hoc',
          'phan_ca_hoc_sinh',
          'buoi_hoc',
        ]),
      );

      final fkCheck = await db.rawQuery('PRAGMA foreign_key_check');
      expect(fkCheck, isEmpty);

      await db.close();
    });
  });
}
