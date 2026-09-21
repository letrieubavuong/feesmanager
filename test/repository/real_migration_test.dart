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
    test('v3 -> latest (v5) verification', () async {
      final dbV3 = await openDatabase(
        dbPath,
        version: 3,
        onCreate: (db, version) async {
          await db.execute(
            'CREATE TABLE hoc_sinh (id INTEGER PRIMARY KEY, ho_ten TEXT, da_luu_tru INTEGER, created_at TEXT, updated_at TEXT)',
          );
          await db.execute(
            'CREATE TABLE lop (id INTEGER PRIMARY KEY, ten_lop TEXT, da_luu_tru INTEGER, created_at TEXT, updated_at TEXT)',
          );
          await db.execute('''
          CREATE TABLE tham_gia_lop (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            id_hoc_sinh INTEGER,
            id_lop INTEGER,
            tu_ngay TEXT,
            den_ngay TEXT,
            ly_do_ket_thuc TEXT,
            mien_giam_phan_tram INTEGER,
            ghi_chu TEXT,
            created_at TEXT,
            updated_at TEXT,
            FOREIGN KEY (id_hoc_sinh) REFERENCES hoc_sinh (id),
            FOREIGN KEY (id_lop) REFERENCES lop (id),
            UNIQUE(id_hoc_sinh, id_lop, tu_ngay)
          )
        ''');
        },
      );

      await dbV3.insert('hoc_sinh', {
        'id': 1,
        'ho_ten': 'S1',
        'da_luu_tru': 0,
        'created_at': '...',
        'updated_at': '...',
      });
      await dbV3.insert('lop', {
        'id': 1,
        'ten_lop': 'C1',
        'da_luu_tru': 0,
        'created_at': '...',
        'updated_at': '...',
      });
      await dbV3.insert('tham_gia_lop', {
        'id': 1,
        'id_hoc_sinh': 1,
        'id_lop': 1,
        'tu_ngay': '2026-09-01',
        'mien_giam_phan_tram': 0,
        'created_at': '...',
        'updated_at': '...',
      });
      await dbV3.close();

      final appDb = AppDatabase(dbName: dbPath);
      final dbV5 = await appDb.database;

      expect(await dbV5.getVersion(), 5);

      final tables = await dbV5.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name IN ('lich_hoc', 'phan_ca_hoc_sinh')",
      );
      expect(tables.length, 2);

      // Verify FKs
      final fkLich = await dbV5.rawQuery('PRAGMA foreign_key_list(lich_hoc)');
      expect(fkLich.any((f) => f['table'] == 'lop'), isTrue);

      final fkPhanCa = await dbV5.rawQuery(
        'PRAGMA foreign_key_list(phan_ca_hoc_sinh)',
      );
      expect(fkPhanCa.any((f) => f['table'] == 'hoc_sinh'), isTrue);
      expect(fkPhanCa.any((f) => f['table'] == 'lop'), isTrue);
      expect(fkPhanCa.any((f) => f['table'] == 'lich_hoc'), isTrue);

      await dbV5.close();
    });

    test('v4 -> v5 (added UNIQUE constraint on phan_ca_hoc_sinh)', () async {
      final dbV4 = await openDatabase(
        dbPath,
        version: 4,
        onCreate: (db, version) async {
          await db.execute(
            'CREATE TABLE hoc_sinh (id INTEGER PRIMARY KEY, ho_ten TEXT, created_at TEXT, updated_at TEXT)',
          );
          await db.execute(
            'CREATE TABLE lop (id INTEGER PRIMARY KEY, ten_lop TEXT, created_at TEXT, updated_at TEXT)',
          );
          await db.execute(
            'CREATE TABLE lich_hoc (id INTEGER PRIMARY KEY, id_lop INTEGER, thu_trong_tuan INTEGER, gio_bat_dau TEXT, gio_ket_thuc TEXT, hieu_luc_tu TEXT, created_at TEXT, updated_at TEXT)',
          );
          await db.execute('''
          CREATE TABLE phan_ca_hoc_sinh (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            id_hoc_sinh INTEGER,
            id_lop INTEGER,
            id_lich_hoc INTEGER,
            tu_ngay TEXT,
            den_ngay TEXT,
            nguon TEXT,
            ghi_chu TEXT,
            created_at TEXT,
            updated_at TEXT
          )
        ''');
        },
      );

      await dbV4.insert('hoc_sinh', {
        'id': 1,
        'ho_ten': 'S1',
        'created_at': '...',
        'updated_at': '...',
      });
      await dbV4.insert('lop', {
        'id': 1,
        'ten_lop': 'C1',
        'created_at': '...',
        'updated_at': '...',
      });
      await dbV4.insert('lich_hoc', {
        'id': 1,
        'id_lop': 1,
        'thu_trong_tuan': 1,
        'gio_bat_dau': '08:00',
        'gio_ket_thuc': '09:00',
        'hieu_luc_tu': '2026-09-01',
        'created_at': '...',
        'updated_at': '...',
      });

      // Valid v4 data
      await dbV4.insert('phan_ca_hoc_sinh', {
        'id_hoc_sinh': 1,
        'id_lop': 1,
        'id_lich_hoc': 1,
        'tu_ngay': '2026-09-01',
        'created_at': '...',
        'updated_at': '...',
      });
      await dbV4.close();

      final appDb = AppDatabase(dbName: dbPath);
      final dbV5 = await appDb.database;

      // Verify UNIQUE constraint works
      await dbV5.execute('PRAGMA foreign_keys = ON');
      expect(
        () => dbV5.insert('phan_ca_hoc_sinh', {
          'id_hoc_sinh': 1,
          'id_lop': 1,
          'id_lich_hoc': 1,
          'tu_ngay': '2026-09-01',
          'created_at': '...',
          'updated_at': '...',
        }),
        throwsA(isA<DatabaseException>()),
      );

      await dbV5.close();
    });

    test('Fresh Install v5 verification', () async {
      final appDb = AppDatabase(dbName: dbPath);
      final db = await appDb.database;

      expect(await db.getVersion(), 5);

      final violations = await db.rawQuery('PRAGMA foreign_key_check');
      expect(violations.isEmpty, isTrue);

      await db.close();
    });
  });
}
