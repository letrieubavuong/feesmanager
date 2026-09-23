import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:tuition2027/core/database/app_database.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('AppDatabase Migration v7 to v8', () {
    late String dbPath;

    setUp(() async {
      final tempDir = await Directory.systemTemp.createTemp(
        'migration_test_v7_v8',
      );
      dbPath = join(tempDir.path, 'test_migration_v7_v8.db');
    });

    test('Migration v7 to v8 preserves canonical Phase 0-6 data', () async {
      final dbV7 = await openDatabase(
        dbPath,
        version: 7,
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
        },
        onConfigure: (db) async => await db.execute('PRAGMA foreign_keys = ON'),
      );

      await dbV7.insert('hoc_sinh', {
        'id': 11,
        'ho_ten': 'Student 11',
        'created_at': '2026-01-01',
        'updated_at': '2026-01-01',
      });
      await dbV7.insert('lop', {
        'id': 21,
        'ten_lop': 'Class 21',
        'created_at': '2026-01-01',
        'updated_at': '2026-01-01',
      });
      await dbV7.insert('tham_gia_lop', {
        'id': 31,
        'id_hoc_sinh': 11,
        'id_lop': 21,
        'tu_ngay': '2026-09-01',
        'created_at': '2026-01-01',
        'updated_at': '2026-01-01',
      });
      await dbV7.insert('lich_hoc', {
        'id': 41,
        'id_lop': 21,
        'thu_trong_tuan': 1,
        'gio_bat_dau': '17:30',
        'gio_ket_thuc': '19:00',
        'hieu_luc_tu': '2026-09-01',
        'created_at': '2026-01-01',
        'updated_at': '2026-01-01',
      });
      await dbV7.insert('phan_ca_hoc_sinh', {
        'id': 51,
        'id_hoc_sinh': 11,
        'id_lop': 21,
        'id_lich_hoc': 41,
        'tu_ngay': '2026-09-01',
        'created_at': '2026-01-01',
        'updated_at': '2026-01-01',
      });
      await dbV7.insert('buoi_hoc', {
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
      await dbV7.insert('diem_danh', {
        'id': 71,
        'id_buoi_hoc': 61,
        'id_hoc_sinh': 11,
        'id_lop_goc': 21,
        'trang_thai': 'CO_MAT',
        'loai_tham_gia': 'CHINH',
        'created_at': '2026-01-01',
        'updated_at': '2026-01-01',
      });
      await dbV7.close();

      final appDb = AppDatabase(dbName: dbPath);
      final dbV8 = await appDb.database;

      expect(await dbV8.getVersion(), 13);

      // Assert all rows survive
      final hs = await dbV8.query('hoc_sinh', where: 'id = 11');
      expect(hs.first['ho_ten'], 'Student 11');

      final cls = await dbV8.query('lop', where: 'id = 21');
      expect(cls.first['ten_lop'], 'Class 21');

      final tgl = await dbV8.query('tham_gia_lop', where: 'id = 31');
      expect(tgl.first['id_hoc_sinh'], 11);
      expect(tgl.first['id_lop'], 21);

      final lh = await dbV8.query('lich_hoc', where: 'id = 41');
      expect(lh.first['id_lop'], 21);

      final pc = await dbV8.query('phan_ca_hoc_sinh', where: 'id = 51');
      expect(pc.first['id_hoc_sinh'], 11);

      final bh = await dbV8.query('buoi_hoc', where: 'id = 61');
      expect(bh.first['id_lop'], 21);

      final dd = await dbV8.query('diem_danh', where: 'id = 71');
      expect(dd.first['trang_thai'], 'CO_MAT');
      expect(dd.first['id_hoc_sinh'], 11);

      // Verify FKs for don_nghi_hoc
      final leaveFkList = await dbV8.rawQuery(
        "PRAGMA foreign_key_list(don_nghi_hoc)",
      );
      final leaveFks = leaveFkList
          .map((f) => {'from': f['from'], 'table': f['table']})
          .toList();
      expect(
        leaveFks.any(
          (f) => f['from'] == 'id_hoc_sinh' && f['table'] == 'hoc_sinh',
        ),
        isTrue,
      );
      expect(
        leaveFks.any((f) => f['from'] == 'id_lop' && f['table'] == 'lop'),
        isTrue,
      );

      // Verify FKs for dieu_chinh_buoi_hoc
      final adjFkList = await dbV8.rawQuery(
        "PRAGMA foreign_key_list(dieu_chinh_buoi_hoc)",
      );
      final adjFks = adjFkList
          .map((f) => {'from': f['from'], 'table': f['table']})
          .toList();
      expect(
        adjFks.any(
          (f) => f['from'] == 'id_hoc_sinh' && f['table'] == 'hoc_sinh',
        ),
        isTrue,
      );
      expect(
        adjFks.any((f) => f['from'] == 'id_lop_goc' && f['table'] == 'lop'),
        isTrue,
      );
      expect(
        adjFks.any(
          (f) => f['from'] == 'id_buoi_hoc_goc' && f['table'] == 'buoi_hoc',
        ),
        isTrue,
      );
      expect(
        adjFks.any(
          (f) =>
              f['from'] == 'id_buoi_hoc_tham_gia' && f['table'] == 'buoi_hoc',
        ),
        isTrue,
      );

      final violations = await dbV8.rawQuery('PRAGMA foreign_key_check');
      expect(violations, isEmpty);

      await dbV8.close();
    });

    test('Raw DB constraints for Phase 7 tables', () async {
      final tempDbReg = join(
        Directory.systemTemp.path,
        'test_regression_v8.db',
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
      await db.execute(
        "INSERT INTO buoi_hoc (id, id_lop, ngay, gio_bat_dau, gio_ket_thuc, loai, created_at, updated_at) VALUES (2, 1, '2026-09-21', '19:30', '21:00', 'CHINH', 'now', 'now')",
      );

      // Leave statuses
      final validLeaveStatuses = ['CHO_DUYET', 'DA_DUYET', 'TU_CHOI'];
      for (final s in validLeaveStatuses) {
        await db.execute(
          "INSERT INTO don_nghi_hoc (id_hoc_sinh, id_lop, tu_ngay, den_ngay, trang_thai, created_at, updated_at) VALUES (1, 1, '2026-09-21', '2026-09-21', ?, 'now', 'now')",
          [s],
        );
      }

      // Reject invalid leave status
      expect(
        () => db.execute(
          "INSERT INTO don_nghi_hoc (id_hoc_sinh, id_lop, tu_ngay, den_ngay, trang_thai, created_at, updated_at) VALUES (1, 1, '2026-09-21', '2026-09-21', 'APPROVED', 'now', 'now')",
        ),
        throwsA(isA<DatabaseException>()),
      );

      // Reject den_ngay < tu_ngay
      expect(
        () => db.execute(
          "INSERT INTO don_nghi_hoc (id_hoc_sinh, id_lop, tu_ngay, den_ngay, created_at, updated_at) VALUES (1, 1, '2026-09-21', '2026-09-20', 'now', 'now')",
        ),
        throwsA(isA<DatabaseException>()),
      );

      // Adjustments
      final validAdjTypes = ['DOI_CA', 'HOC_BU', 'PHAT_SINH'];
      for (int i = 0; i < validAdjTypes.length; i++) {
        final sId = i + 10;
        await db.execute(
          "INSERT INTO hoc_sinh (id, ho_ten, created_at, updated_at) VALUES (?, 'S', 'now', 'now')",
          [sId],
        );
        final origB = validAdjTypes[i] == 'PHAT_SINH' ? null : 1;
        await db.execute(
          "INSERT INTO dieu_chinh_buoi_hoc (id_hoc_sinh, id_lop_goc, id_buoi_hoc_goc, id_buoi_hoc_tham_gia, loai, created_at) VALUES (?, 1, ?, 2, ?, 'now')",
          [sId, origB, validAdjTypes[i]],
        );
      }

      // Reject invalid type
      expect(
        () => db.execute(
          "INSERT INTO dieu_chinh_buoi_hoc (id_hoc_sinh, id_lop_goc, id_buoi_hoc_goc, id_buoi_hoc_tham_gia, loai, created_at) VALUES (1, 1, 1, 2, 'INVALID', 'now')",
        ),
        throwsA(isA<DatabaseException>()),
      );

      // Reject id_buoi_hoc_goc == id_buoi_hoc_tham_gia
      expect(
        () => db.execute(
          "INSERT INTO dieu_chinh_buoi_hoc (id_hoc_sinh, id_lop_goc, id_buoi_hoc_goc, id_buoi_hoc_tham_gia, loai, created_at) VALUES (1, 1, 1, 1, 'DOI_CA', 'now')",
        ),
        throwsA(isA<DatabaseException>()),
      );

      // Reject DOI_CA with null id_buoi_hoc_goc
      expect(
        () => db.execute(
          "INSERT INTO dieu_chinh_buoi_hoc (id_hoc_sinh, id_lop_goc, id_buoi_hoc_goc, id_buoi_hoc_tham_gia, loai, created_at) VALUES (1, 1, NULL, 2, 'DOI_CA', 'now')",
        ),
        throwsA(isA<DatabaseException>()),
      );

      // Reject HOC_BU with null id_buoi_hoc_goc
      expect(
        () => db.execute(
          "INSERT INTO dieu_chinh_buoi_hoc (id_hoc_sinh, id_lop_goc, id_buoi_hoc_goc, id_buoi_hoc_tham_gia, loai, created_at) VALUES (1, 1, NULL, 2, 'HOC_BU', 'now')",
        ),
        throwsA(isA<DatabaseException>()),
      );

      // Accept PHAT_SINH with null id_buoi_hoc_goc
      await db.execute(
        "INSERT INTO dieu_chinh_buoi_hoc (id, id_hoc_sinh, id_lop_goc, id_buoi_hoc_goc, id_buoi_hoc_tham_gia, loai, created_at) VALUES (999, 1, 1, NULL, 2, 'PHAT_SINH', 'now')",
      );
      final psCheck = await db.query('dieu_chinh_buoi_hoc', where: 'id = 999');
      expect(psCheck, isNotEmpty);
      await db.delete('dieu_chinh_buoi_hoc', where: 'id = 999');

      // Isolated FK failures
      // Leave invalid student
      expect(
        () => db.execute(
          "INSERT INTO don_nghi_hoc (id_hoc_sinh, id_lop, tu_ngay, den_ngay, trang_thai, created_at, updated_at) VALUES (99999, 1, '2026-09-21', '2026-09-21', 'CHO_DUYET', 'now', 'now')",
        ),
        throwsA(isA<DatabaseException>()),
      );
      // Leave invalid class
      expect(
        () => db.execute(
          "INSERT INTO don_nghi_hoc (id_hoc_sinh, id_lop, tu_ngay, den_ngay, trang_thai, created_at, updated_at) VALUES (1, 99999, '2026-09-21', '2026-09-21', 'CHO_DUYET', 'now', 'now')",
        ),
        throwsA(isA<DatabaseException>()),
      );
      // Adj invalid student
      expect(
        () => db.execute(
          "INSERT INTO dieu_chinh_buoi_hoc (id_hoc_sinh, id_lop_goc, id_buoi_hoc_goc, id_buoi_hoc_tham_gia, loai, created_at) VALUES (99999, 1, 1, 2, 'DOI_CA', 'now')",
        ),
        throwsA(isA<DatabaseException>()),
      );
      // Adj invalid orig class
      expect(
        () => db.execute(
          "INSERT INTO dieu_chinh_buoi_hoc (id_hoc_sinh, id_lop_goc, id_buoi_hoc_goc, id_buoi_hoc_tham_gia, loai, created_at) VALUES (1, 99999, 1, 2, 'DOI_CA', 'now')",
        ),
        throwsA(isA<DatabaseException>()),
      );
      // Adj invalid orig session
      expect(
        () => db.execute(
          "INSERT INTO dieu_chinh_buoi_hoc (id_hoc_sinh, id_lop_goc, id_buoi_hoc_goc, id_buoi_hoc_tham_gia, loai, created_at) VALUES (1, 1, 99999, 2, 'DOI_CA', 'now')",
        ),
        throwsA(isA<DatabaseException>()),
      );
      // Adj invalid target session
      expect(
        () => db.execute(
          "INSERT INTO dieu_chinh_buoi_hoc (id_hoc_sinh, id_lop_goc, id_buoi_hoc_goc, id_buoi_hoc_tham_gia, loai, created_at) VALUES (1, 1, 1, 99999, 'DOI_CA', 'now')",
        ),
        throwsA(isA<DatabaseException>()),
      );

      // Duplicate DOI_CA for same student & orig session rejected by partial unique index
      await db.execute(
        "INSERT INTO hoc_sinh (id, ho_ten, created_at, updated_at) VALUES (99, 'Dup', 'now', 'now')",
      );
      await db.execute(
        "INSERT INTO buoi_hoc (id, id_lop, ngay, gio_bat_dau, gio_ket_thuc, loai, created_at, updated_at) VALUES (3, 1, '2026-09-21', '10:00', '11:00', 'CHINH', 'now', 'now')",
      );
      await db.execute(
        "INSERT INTO dieu_chinh_buoi_hoc (id_hoc_sinh, id_lop_goc, id_buoi_hoc_goc, id_buoi_hoc_tham_gia, loai, created_at) VALUES (99, 1, 1, 2, 'DOI_CA', 'now')",
      );
      expect(
        () => db.execute(
          "INSERT INTO dieu_chinh_buoi_hoc (id_hoc_sinh, id_lop_goc, id_buoi_hoc_goc, id_buoi_hoc_tham_gia, loai, created_at) VALUES (99, 1, 1, 3, 'DOI_CA', 'now')",
        ),
        throwsA(isA<DatabaseException>()),
      );

      await db.close();
      await deleteDatabase(tempDbReg);
    });

    test(
      'Fresh install DB version is 8 and PRAGMA foreign_key_check is clean',
      () async {
        final freshDbPath = join(
          Directory.systemTemp.path,
          'test_fresh_v8_install.db',
        );
        await deleteDatabase(freshDbPath);

        final appDb = AppDatabase(dbName: freshDbPath);
        final db = await appDb.database;

        expect(await db.getVersion(), 13);

        final tables = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table'",
        );
        final tableNames = tables.map((t) => t['name'] as String).toSet();

        expect(tableNames.contains('don_nghi_hoc'), isTrue);
        expect(tableNames.contains('dieu_chinh_buoi_hoc'), isTrue);

        final fkViolations = await db.rawQuery('PRAGMA foreign_key_check');
        expect(fkViolations, isEmpty);

        await db.close();
        await deleteDatabase(freshDbPath);
      },
    );
  });
}
