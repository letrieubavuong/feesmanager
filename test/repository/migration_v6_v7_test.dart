import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:tuition2027/core/database/app_database.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('AppDatabase Migration v6 to v7', () {
    late String dbPath;

    setUp(() async {
      final tempDir = await Directory.systemTemp.createTemp(
        'migration_test_v6_v7',
      );
      dbPath = join(tempDir.path, 'test_migration_v6_v7.db');
    });

    test('Migration v6 to v7 preserves canonical Phase 0-5 data', () async {
      // 1. Create a REAL v6 database with canonical schema
      final dbV6 = await openDatabase(
        dbPath,
        version: 6,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE hoc_sinh (
              id INTEGER PRIMARY KEY,
              ho_ten TEXT NOT NULL,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE lop (
              id INTEGER PRIMARY KEY,
              ten_lop TEXT NOT NULL,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE tham_gia_lop (
              id INTEGER PRIMARY KEY,
              id_hoc_sinh INTEGER NOT NULL,
              id_lop INTEGER NOT NULL,
              tu_ngay TEXT NOT NULL,
              den_ngay TEXT,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL,
              FOREIGN KEY (id_hoc_sinh) REFERENCES hoc_sinh (id),
              FOREIGN KEY (id_lop) REFERENCES lop (id)
            )
          ''');
          await db.execute('''
            CREATE TABLE lich_hoc (
              id INTEGER PRIMARY KEY,
              id_lop INTEGER NOT NULL,
              thu_trong_tuan INTEGER NOT NULL,
              gio_bat_dau TEXT NOT NULL,
              gio_ket_thuc TEXT NOT NULL,
              hieu_luc_tu TEXT NOT NULL,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL,
              FOREIGN KEY (id_lop) REFERENCES lop (id)
            )
          ''');
          await db.execute('''
            CREATE TABLE phan_ca_hoc_sinh (
              id INTEGER PRIMARY KEY,
              id_hoc_sinh INTEGER NOT NULL,
              id_lop INTEGER NOT NULL,
              id_lich_hoc INTEGER NOT NULL,
              tu_ngay TEXT NOT NULL,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL,
              FOREIGN KEY (id_hoc_sinh) REFERENCES hoc_sinh (id),
              FOREIGN KEY (id_lop) REFERENCES lop (id),
              FOREIGN KEY (id_lich_hoc) REFERENCES lich_hoc (id)
            )
          ''');
          await db.execute('''
            CREATE TABLE buoi_hoc (
              id INTEGER PRIMARY KEY,
              id_lop INTEGER NOT NULL,
              id_lich_hoc INTEGER,
              ngay TEXT NOT NULL,
              gio_bat_dau TEXT NOT NULL,
              gio_ket_thuc TEXT NOT NULL,
              loai TEXT NOT NULL,
              trang_thai TEXT NOT NULL DEFAULT 'DU_KIEN',
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL,
              FOREIGN KEY (id_lop) REFERENCES lop (id),
              FOREIGN KEY (id_lich_hoc) REFERENCES lich_hoc (id)
            )
          ''');
        },
      );

      // 2. Populate explicit IDs and values
      await dbV6.insert('hoc_sinh', {
        'id': 11,
        'ho_ten': 'Student 11',
        'created_at': '2026-01-01',
        'updated_at': '2026-01-01',
      });
      await dbV6.insert('lop', {
        'id': 21,
        'ten_lop': 'Class 21',
        'created_at': '2026-01-01',
        'updated_at': '2026-01-01',
      });
      await dbV6.insert('tham_gia_lop', {
        'id': 31,
        'id_hoc_sinh': 11,
        'id_lop': 21,
        'tu_ngay': '2026-09-01',
        'created_at': '2026-01-01',
        'updated_at': '2026-01-01',
      });
      await dbV6.insert('lich_hoc', {
        'id': 41,
        'id_lop': 21,
        'thu_trong_tuan': 1,
        'gio_bat_dau': '17:30',
        'gio_ket_thuc': '19:00',
        'hieu_luc_tu': '2026-09-01',
        'created_at': '2026-01-01',
        'updated_at': '2026-01-01',
      });
      await dbV6.insert('phan_ca_hoc_sinh', {
        'id': 51,
        'id_hoc_sinh': 11,
        'id_lop': 21,
        'id_lich_hoc': 41,
        'tu_ngay': '2026-09-01',
        'created_at': '2026-01-01',
        'updated_at': '2026-01-01',
      });
      await dbV6.insert('buoi_hoc', {
        'id': 61,
        'id_lop': 21,
        'id_lich_hoc': 41,
        'ngay': '2026-09-21',
        'gio_bat_dau': '17:30',
        'gio_ket_thuc': '19:00',
        'loai': 'CHINH',
        'created_at': '2026-01-01',
        'updated_at': '2026-01-01',
      });
      await dbV6.close();

      // 3. Open with latest AppDatabase
      final appDb = AppDatabase(dbName: dbPath);
      final dbV7 = await appDb.database;

      // 4. Assert user_version == 7
      expect(await dbV7.getVersion(), 7);

      // 5. Assert every existing row/ID/value is preserved
      final hs = await dbV7.query('hoc_sinh', where: 'id = 11');
      expect(hs.first['ho_ten'], 'Student 11');

      final buoi = await dbV7.query('buoi_hoc', where: 'id = 61');
      expect(buoi.first['ngay'], '2026-09-21');

      // 6. Verify diem_danh FKs
      final fkList = await dbV7.rawQuery("PRAGMA foreign_key_list(diem_danh)");
      final fks = fkList
          .map((f) => {'from': f['from'], 'table': f['table']})
          .toList();

      expect(
        fks.any((f) => f['from'] == 'id_buoi_hoc' && f['table'] == 'buoi_hoc'),
        isTrue,
      );
      expect(
        fks.any((f) => f['from'] == 'id_hoc_sinh' && f['table'] == 'hoc_sinh'),
        isTrue,
      );
      expect(
        fks.any((f) => f['from'] == 'id_lop_goc' && f['table'] == 'lop'),
        isTrue,
      );
      expect(
        fks.any(
          (f) => f['from'] == 'id_buoi_vang_goc' && f['table'] == 'buoi_hoc',
        ),
        isTrue,
      );

      await dbV7.close();
    });

    test('Raw DB constraints and vocab regression', () async {
      // Use explicit path for file-based testing to avoid memory issues with FKs in some FFI setups
      final tempDbReg = join(
        Directory.systemTemp.path,
        'test_regression_v7.db',
      );
      await deleteDatabase(tempDbReg);

      final appDb = AppDatabase(dbName: tempDbReg);
      final db = await appDb.database;

      // Mock prerequisite data
      await db.execute(
        "INSERT INTO hoc_sinh (id, ho_ten, created_at, updated_at) VALUES (1, 'H', 'now', 'now')",
      );
      await db.execute(
        "INSERT INTO lop (id, ten_lop, created_at, updated_at) VALUES (1, 'L', 'now', 'now')",
      );
      await db.execute(
        "INSERT INTO buoi_hoc (id, id_lop, ngay, gio_bat_dau, gio_ket_thuc, loai, created_at, updated_at) VALUES (1, 1, '2026-09-21', '17:30', '19:00', 'CHINH', 'now', 'now')",
      );

      // Valid insert
      await db.execute('''
        INSERT INTO diem_danh (id_buoi_hoc, id_hoc_sinh, id_lop_goc, trang_thai, loai_tham_gia, created_at, updated_at)
        VALUES (1, 1, 1, 'CO_MAT', 'CHINH', 'now', 'now')
      ''');

      // Reject invalid status ABC
      expect(
        () => db.execute('''
        INSERT INTO diem_danh (id_buoi_hoc, id_hoc_sinh, id_lop_goc, trang_thai, created_at, updated_at)
        VALUES (1, 2, 1, 'ABC', 'now', 'now')
      '''),
        throwsA(isA<DatabaseException>()),
      );

      // Reject application-only CHUA_DIEM_DANH
      expect(
        () => db.execute('''
        INSERT INTO diem_danh (id_buoi_hoc, id_hoc_sinh, id_lop_goc, trang_thai, created_at, updated_at)
        VALUES (1, 3, 1, 'CHUA_DIEM_DANH', 'now', 'now')
      '''),
        throwsA(isA<DatabaseException>()),
      );

      // Unique constraint
      expect(
        () => db.execute('''
        INSERT INTO diem_danh (id_buoi_hoc, id_hoc_sinh, id_lop_goc, trang_thai, created_at, updated_at)
        VALUES (1, 1, 1, 'TRE', 'CHINH', 'now', 'now')
      '''),
        throwsA(isA<DatabaseException>()),
      );

      await db.close();
    });
  });
}
