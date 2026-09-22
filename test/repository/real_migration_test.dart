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
    test('v3 -> latest (v7) verification', () async {
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
      final dbLatest = await appDb.database;

      expect(await dbLatest.getVersion(), 12);

      final tables = await dbLatest.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name IN ('lich_hoc', 'phan_ca_hoc_sinh', 'buoi_hoc', 'diem_danh')",
      );
      expect(tables.length, 4);

      // Verify FKs
      final fkLich = await dbLatest.rawQuery(
        'PRAGMA foreign_key_list(lich_hoc)',
      );
      expect(fkLich.any((f) => f['table'] == 'lop'), isTrue);

      final fkPhanCa = await dbLatest.rawQuery(
        'PRAGMA foreign_key_list(phan_ca_hoc_sinh)',
      );
      expect(fkPhanCa.any((f) => f['table'] == 'hoc_sinh'), isTrue);
      expect(fkPhanCa.any((f) => f['table'] == 'lop'), isTrue);
      expect(fkPhanCa.any((f) => f['table'] == 'lich_hoc'), isTrue);

      final fkBuoiHoc = await dbLatest.rawQuery(
        'PRAGMA foreign_key_list(buoi_hoc)',
      );
      expect(fkBuoiHoc.any((f) => f['table'] == 'lop'), isTrue);
      expect(fkBuoiHoc.any((f) => f['table'] == 'lich_hoc'), isTrue);

      final fkDiemDanh = await dbLatest.rawQuery(
        'PRAGMA foreign_key_list(diem_danh)',
      );
      expect(fkDiemDanh.any((f) => f['table'] == 'buoi_hoc'), isTrue);
      expect(fkDiemDanh.any((f) => f['table'] == 'hoc_sinh'), isTrue);
      expect(fkDiemDanh.any((f) => f['table'] == 'lop'), isTrue);

      await dbLatest.close();
    });

    test('Fresh Install latest verification', () async {
      final appDb = AppDatabase(dbName: dbPath);
      final db = await appDb.database;

      expect(await db.getVersion(), 12);

      final violations = await db.rawQuery('PRAGMA foreign_key_check');
      expect(violations.isEmpty, isTrue);

      await db.close();
    });
  });
}
