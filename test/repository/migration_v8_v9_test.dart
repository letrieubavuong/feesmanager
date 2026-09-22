import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:tuition2027/core/database/app_database.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('AppDatabase Migration v8 to v9', () {
    late String dbPath;

    setUp(() async {
      final tempDir = await Directory.systemTemp.createTemp(
        'migration_test_v8_v9',
      );
      dbPath = join(tempDir.path, 'test_migration_v8_v9.db');
    });

    test('Migration v8 to v9 preserves canonical Phase 0-7 data', () async {
      final dbV8 = await openDatabase(
        dbPath,
        version: 8,
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

          await db.execute('''
            CREATE TABLE lop (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              ten_lop TEXT NOT NULL,
              khoi INTEGER NULL,
              mon_hoc TEXT NULL,
              si_so_toi_da INTEGER NULL,
              ghi_chu TEXT NULL,
              da_luu_tru INTEGER NOT NULL DEFAULT 0,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL
            )
          ''');

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
              FOREIGN KEY (id_lop) REFERENCES lop (id),
              UNIQUE(id_hoc_sinh, id_lop, tu_ngay),
              CHECK (den_ngay IS NULL OR den_ngay >= tu_ngay),
              CHECK (mien_giam_phan_tram BETWEEN 0 AND 100)
            )
          ''');

          await db.execute('''
            CREATE TABLE lich_hoc (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              id_lop INTEGER NOT NULL,
              thu_trong_tuan INTEGER NOT NULL,
              gio_bat_dau TEXT NOT NULL,
              gio_ket_thuc TEXT NOT NULL,
              hieu_luc_tu TEXT NOT NULL,
              hieu_luc_den TEXT NULL,
              ghi_chu TEXT NULL,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL,
              FOREIGN KEY (id_lop) REFERENCES lop (id),
              CHECK (thu_trong_tuan BETWEEN 1 AND 7),
              CHECK (gio_ket_thuc > gio_bat_dau),
              CHECK (hieu_luc_den IS NULL OR hieu_luc_den >= hieu_luc_tu)
            )
          ''');

          await db.execute('''
            CREATE TABLE phan_ca_hoc_sinh (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              id_hoc_sinh INTEGER NOT NULL,
              id_lop INTEGER NOT NULL,
              id_lich_hoc INTEGER NOT NULL,
              tu_ngay TEXT NOT NULL,
              den_ngay TEXT NULL,
              nguon TEXT NULL,
              ghi_chu TEXT NULL,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL,
              FOREIGN KEY (id_hoc_sinh) REFERENCES hoc_sinh (id),
              FOREIGN KEY (id_lop) REFERENCES lop (id),
              FOREIGN KEY (id_lich_hoc) REFERENCES lich_hoc (id),
              UNIQUE(id_hoc_sinh, id_lich_hoc, tu_ngay),
              CHECK (den_ngay IS NULL OR den_ngay >= tu_ngay)
            )
          ''');

          await db.execute('''
            CREATE TABLE buoi_hoc (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              id_lop INTEGER NOT NULL,
              id_lich_hoc INTEGER NULL,
              ngay TEXT NOT NULL,
              gio_bat_dau TEXT NOT NULL,
              gio_ket_thuc TEXT NOT NULL,
              loai TEXT NOT NULL,
              trang_thai TEXT NOT NULL DEFAULT 'DU_KIEN',
              ghi_chu TEXT NULL,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL,
              FOREIGN KEY (id_lop) REFERENCES lop (id),
              FOREIGN KEY (id_lich_hoc) REFERENCES lich_hoc (id),
              CHECK (gio_ket_thuc > gio_bat_dau),
              CHECK (loai IN ('CHINH', 'HOC_BU', 'PHAT_SINH')),
              CHECK (trang_thai IN ('DU_KIEN', 'DA_HOC', 'HUY', 'NGHI_LE')),
              UNIQUE(id_lop, ngay, gio_bat_dau)
            )
          ''');

          await db.execute('''
            CREATE TABLE diem_danh (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              id_buoi_hoc INTEGER NOT NULL,
              id_hoc_sinh INTEGER NOT NULL,
              id_lop_goc INTEGER NOT NULL,
              trang_thai TEXT NOT NULL,
              loai_tham_gia TEXT NOT NULL DEFAULT 'CHINH',
              id_buoi_vang_goc INTEGER NULL,
              ghi_chu TEXT NULL,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL,
              FOREIGN KEY (id_buoi_hoc) REFERENCES buoi_hoc (id),
              FOREIGN KEY (id_hoc_sinh) REFERENCES hoc_sinh (id),
              FOREIGN KEY (id_lop_goc) REFERENCES lop (id),
              FOREIGN KEY (id_buoi_vang_goc) REFERENCES buoi_hoc (id),
              UNIQUE(id_buoi_hoc, id_hoc_sinh),
              CHECK (trang_thai IN ('CO_MAT', 'TRE', 'NGHI_CO_PHEP', 'NGHI_KHONG_PHEP', 'HOC_BU')),
              CHECK (loai_tham_gia IN ('CHINH', 'DOI_CA', 'HOC_BU'))
            )
          ''');

          await db.execute('''
            CREATE TABLE don_nghi_hoc (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              id_hoc_sinh INTEGER NOT NULL,
              id_lop INTEGER NOT NULL,
              tu_ngay TEXT NOT NULL,
              den_ngay TEXT NOT NULL,
              ly_do TEXT NULL,
              trang_thai TEXT NOT NULL DEFAULT 'CHO_DUYET',
              ghi_chu TEXT NULL,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL,
              FOREIGN KEY (id_hoc_sinh) REFERENCES hoc_sinh (id),
              FOREIGN KEY (id_lop) REFERENCES lop (id),
              CHECK (den_ngay >= tu_ngay),
              CHECK (trang_thai IN ('CHO_DUYET', 'DA_DUYET', 'TU_CHOI'))
            )
          ''');

          await db.execute('''
            CREATE TABLE dieu_chinh_buoi_hoc (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              id_hoc_sinh INTEGER NOT NULL,
              id_lop_goc INTEGER NOT NULL,
              id_buoi_hoc_goc INTEGER NULL,
              id_buoi_hoc_tham_gia INTEGER NOT NULL,
              loai TEXT NOT NULL,
              ly_do TEXT NULL,
              created_at TEXT NOT NULL,
              FOREIGN KEY (id_hoc_sinh) REFERENCES hoc_sinh (id),
              FOREIGN KEY (id_lop_goc) REFERENCES lop (id),
              FOREIGN KEY (id_buoi_hoc_goc) REFERENCES buoi_hoc (id),
              FOREIGN KEY (id_buoi_hoc_tham_gia) REFERENCES buoi_hoc (id),
              CHECK (loai IN ('DOI_CA', 'HOC_BU', 'PHAT_SINH')),
              CHECK (id_buoi_hoc_goc IS NULL OR id_buoi_hoc_goc != id_buoi_hoc_tham_gia),
              CHECK (loai = 'PHAT_SINH' OR id_buoi_hoc_goc IS NOT NULL),
              UNIQUE (id_hoc_sinh, id_buoi_hoc_tham_gia)
            )
          ''');
        },
        onConfigure: (db) async => await db.execute('PRAGMA foreign_keys = ON'),
      );

      await dbV8.insert('hoc_sinh', {
        'id': 11,
        'ho_ten': 'Student 11',
        'created_at': '2026-01-01',
        'updated_at': '2026-01-01',
      });
      await dbV8.insert('lop', {
        'id': 21,
        'ten_lop': 'Class 21',
        'created_at': '2026-01-01',
        'updated_at': '2026-01-01',
      });
      await dbV8.insert('tham_gia_lop', {
        'id': 31,
        'id_hoc_sinh': 11,
        'id_lop': 21,
        'tu_ngay': '2026-09-01',
        'created_at': '2026-01-01',
        'updated_at': '2026-01-01',
      });
      await dbV8.insert('lich_hoc', {
        'id': 41,
        'id_lop': 21,
        'thu_trong_tuan': 1,
        'gio_bat_dau': '17:30',
        'gio_ket_thuc': '19:00',
        'hieu_luc_tu': '2026-09-01',
        'created_at': '2026-01-01',
        'updated_at': '2026-01-01',
      });
      await dbV8.insert('phan_ca_hoc_sinh', {
        'id': 51,
        'id_hoc_sinh': 11,
        'id_lop': 21,
        'id_lich_hoc': 41,
        'tu_ngay': '2026-09-01',
        'created_at': '2026-01-01',
        'updated_at': '2026-01-01',
      });
      await dbV8.insert('buoi_hoc', {
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
      await dbV8.insert('diem_danh', {
        'id': 71,
        'id_buoi_hoc': 61,
        'id_hoc_sinh': 11,
        'id_lop_goc': 21,
        'trang_thai': 'CO_MAT',
        'loai_tham_gia': 'CHINH',
        'created_at': '2026-01-01',
        'updated_at': '2026-01-01',
      });
      await dbV8.insert('don_nghi_hoc', {
        'id': 81,
        'id_hoc_sinh': 11,
        'id_lop': 21,
        'tu_ngay': '2026-09-20',
        'den_ngay': '2026-09-22',
        'trang_thai': 'DA_DUYET',
        'created_at': '2026-01-01',
        'updated_at': '2026-01-01',
      });
      await dbV8.insert('dieu_chinh_buoi_hoc', {
        'id': 91,
        'id_hoc_sinh': 11,
        'id_lop_goc': 21,
        'id_buoi_hoc_goc': null,
        'id_buoi_hoc_tham_gia': 61,
        'loai': 'PHAT_SINH',
        'created_at': '2026-01-01',
      });
      await dbV8.close();

      final appDb = AppDatabase(dbName: dbPath);
      final dbV10 = await appDb.database;

      expect(await dbV10.getVersion(), 11);

      // Assert all Phase 0-7 rows survive
      final hs = await dbV10.query('hoc_sinh', where: 'id = 11');
      expect(hs.first['ho_ten'], 'Student 11');

      final cls = await dbV10.query('lop', where: 'id = 21');
      expect(cls.first['ten_lop'], 'Class 21');

      final tgl = await dbV10.query('tham_gia_lop', where: 'id = 31');
      expect(tgl.first['id_hoc_sinh'], 11);

      final lh = await dbV10.query('lich_hoc', where: 'id = 41');
      expect(lh.first['id_lop'], 21);

      final pc = await dbV10.query('phan_ca_hoc_sinh', where: 'id = 51');
      expect(pc.first['id_hoc_sinh'], 11);

      final bh = await dbV10.query('buoi_hoc', where: 'id = 61');
      expect(bh.first['id_lop'], 21);

      final dd = await dbV10.query('diem_danh', where: 'id = 71');
      expect(dd.first['trang_thai'], 'CO_MAT');

      final dnh = await dbV10.query('don_nghi_hoc', where: 'id = 81');
      expect(dnh.first['trang_thai'], 'DA_DUYET');

      final dch = await dbV10.query('dieu_chinh_buoi_hoc', where: 'id = 91');
      expect(dch.first['loai'], 'PHAT_SINH');

      // Verify buoi_du_ledger table exists and has correct FKs
      final fkList = await dbV10.rawQuery(
        'PRAGMA foreign_key_list(buoi_du_ledger)',
      );
      final fks = fkList
          .map((f) => {'from': f['from'], 'table': f['table']})
          .toList();

      expect(
        fks.any((f) => f['from'] == 'id_hoc_sinh' && f['table'] == 'hoc_sinh'),
        isTrue,
      );
      expect(
        fks.any((f) => f['from'] == 'id_lop' && f['table'] == 'lop'),
        isTrue,
      );
      expect(
        fks.any((f) => f['from'] == 'id_buoi_hoc' && f['table'] == 'buoi_hoc'),
        isTrue,
      );

      final violations = await dbV10.rawQuery('PRAGMA foreign_key_check');
      expect(violations, isEmpty);

      await dbV10.close();
    });

    test(
      'Fresh install DB version is 10 and foreign_key_check is clean',
      () async {
        final freshDbPath = join(
          Directory.systemTemp.path,
          'test_fresh_v10_install.db',
        );
        await deleteDatabase(freshDbPath);

        final appDb = AppDatabase(dbName: freshDbPath);
        final db = await appDb.database;

        expect(await db.getVersion(), 11);

        final tables = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table'",
        );
        final tableNames = tables.map((t) => t['name'] as String).toSet();

        expect(tableNames.contains('buoi_du_ledger'), isTrue);

        final fkViolations = await db.rawQuery('PRAGMA foreign_key_check');
        expect(fkViolations, isEmpty);

        await db.close();
        await deleteDatabase(freshDbPath);
      },
    );

    test('Raw SQLite constraints for buoi_du_ledger table', () async {
      final tempDbReg = join(
        Directory.systemTemp.path,
        'test_regression_v9.db',
      );
      await deleteDatabase(tempDbReg);

      final appDb = AppDatabase(dbName: tempDbReg);
      final db = await appDb.database;

      await db.execute(
        "INSERT INTO hoc_sinh (id, ho_ten, created_at, updated_at) VALUES (1, 'H', 'now', 'now')",
      );
      await db.execute(
        "INSERT INTO lop (id, ten_lop, created_at, updated_at) VALUES (1, 'L', 'now', 'now')",
      );
      await db.execute(
        "INSERT INTO buoi_hoc (id, id_lop, ngay, gio_bat_dau, gio_ket_thuc, loai, created_at, updated_at) VALUES (1, 1, '2026-09-21', '17:30', '19:00', 'CHINH', 'now', 'now')",
      );

      // Valid entries according to hardened constraints:
      // VUOT_SO_BUOI_CHUAN: delta = 1, id_buoi_hoc = 1
      await db.execute(
        "INSERT INTO buoi_du_ledger (id, id_hoc_sinh, id_lop, id_buoi_hoc, ngay_hieu_luc, delta, ly_do, created_at) VALUES (10, 1, 1, 1, '2026-09-21', 1, 'VUOT_SO_BUOI_CHUAN', 'now')",
      );
      // BU_TRU_NGHI_CO_PHEP: delta = -1, id_buoi_hoc = 1
      await db.execute(
        "INSERT INTO buoi_du_ledger (id, id_hoc_sinh, id_lop, id_buoi_hoc, ngay_hieu_luc, delta, ly_do, created_at) VALUES (11, 1, 1, 1, '2026-09-21', -1, 'BU_TRU_NGHI_CO_PHEP', 'now')",
      );
      // DIEU_CHINH_THU_CONG: delta != 0, id_buoi_hoc = null
      await db.execute(
        "INSERT INTO buoi_du_ledger (id, id_hoc_sinh, id_lop, id_buoi_hoc, ngay_hieu_luc, delta, ly_do, created_at) VALUES (12, 1, 1, NULL, '2026-09-21', 2, 'DIEU_CHINH_THU_CONG', 'now')",
      );
      // MIGRATION: delta != 0, id_buoi_hoc = null
      await db.execute(
        "INSERT INTO buoi_du_ledger (id, id_hoc_sinh, id_lop, id_buoi_hoc, ngay_hieu_luc, delta, ly_do, created_at) VALUES (13, 1, 1, NULL, '2026-09-21', -1, 'MIGRATION', 'now')",
      );

      // Reject invalid reason
      expect(
        () => db.execute(
          "INSERT INTO buoi_du_ledger (id_hoc_sinh, id_lop, ngay_hieu_luc, delta, ly_do, created_at) VALUES (1, 1, '2026-09-21', 1, 'INVALID_REASON', 'now')",
        ),
        throwsA(isA<DatabaseException>()),
      );

      // Reject delta = 0
      expect(
        () => db.execute(
          "INSERT INTO buoi_du_ledger (id_hoc_sinh, id_lop, ngay_hieu_luc, delta, ly_do, created_at) VALUES (1, 1, '2026-09-21', 0, 'DIEU_CHINH_THU_CONG', 'now')",
        ),
        throwsA(isA<DatabaseException>()),
      );

      // Partial unique index idx_buoi_du_auto_event_unique duplicate prevention
      expect(
        () => db.execute(
          "INSERT INTO buoi_du_ledger (id_hoc_sinh, id_lop, id_buoi_hoc, ngay_hieu_luc, delta, ly_do, created_at) VALUES (1, 1, 1, '2026-09-21', 1, 'VUOT_SO_BUOI_CHUAN', 'now')",
        ),
        throwsA(isA<DatabaseException>()),
      );

      // Isolated FK failures
      expect(
        () => db.execute(
          "INSERT INTO buoi_du_ledger (id_hoc_sinh, id_lop, ngay_hieu_luc, delta, ly_do, created_at) VALUES (99999, 1, '2026-09-21', 1, 'DIEU_CHINH_THU_CONG', 'now')",
        ),
        throwsA(isA<DatabaseException>()),
      );
      expect(
        () => db.execute(
          "INSERT INTO buoi_du_ledger (id_hoc_sinh, id_lop, ngay_hieu_luc, delta, ly_do, created_at) VALUES (1, 99999, '2026-09-21', 1, 'DIEU_CHINH_THU_CONG', 'now')",
        ),
        throwsA(isA<DatabaseException>()),
      );
      expect(
        () => db.execute(
          "INSERT INTO buoi_du_ledger (id_hoc_sinh, id_lop, id_buoi_hoc, ngay_hieu_luc, delta, ly_do, created_at) VALUES (1, 1, 99999, '2026-09-21', 1, 'VUOT_SO_BUOI_CHUAN', 'now')",
        ),
        throwsA(isA<DatabaseException>()),
      );

      await db.close();
      await deleteDatabase(tempDbReg);
    });
  });
}
