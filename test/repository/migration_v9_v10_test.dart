import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:tuition2027/core/database/app_database.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('AppDatabase Migration v9 to v10', () {
    late String dbPath;

    setUp(() async {
      final tempDir = await Directory.systemTemp.createTemp(
        'migration_test_v9_v10',
      );
      dbPath = join(tempDir.path, 'test_migration_v9_v10.db');
    });

    test('Migration v9 to v10 preserves canonical Phase 0-8 data', () async {
      final dbV9 = await openDatabase(
        dbPath,
        version: 9,
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
              CHECK (gio_ket_thuc > gio_bat_dau),
              CHECK (loai IN ('CHINH', 'HOC_BU', 'PHAT_SINH')),
              CHECK (trang_thai IN ('DU_KIEN', 'DA_HOC', 'HUY', 'NGHI_LE')),
              UNIQUE(id_lop, ngay, gio_bat_dau)
            )
          ''');

          await db.execute('''
            CREATE TABLE buoi_du_ledger (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              id_hoc_sinh INTEGER NOT NULL,
              id_lop INTEGER NOT NULL,
              id_buoi_hoc INTEGER NULL,
              ngay_hieu_luc TEXT NOT NULL,
              delta INTEGER NOT NULL,
              ly_do TEXT NOT NULL,
              ghi_chu TEXT NULL,
              created_at TEXT NOT NULL,
              FOREIGN KEY (id_hoc_sinh) REFERENCES hoc_sinh (id),
              FOREIGN KEY (id_lop) REFERENCES lop (id),
              FOREIGN KEY (id_buoi_hoc) REFERENCES buoi_hoc (id),
              CHECK (delta != 0),
              CHECK (ly_do IN ('VUOT_SO_BUOI_CHUAN', 'BU_TRU_NGHI_CO_PHEP', 'DIEU_CHINH_THU_CONG', 'MIGRATION'))
            )
          ''');
        },
        onConfigure: (db) async => await db.execute('PRAGMA foreign_keys = ON'),
      );

      await dbV9.insert('hoc_sinh', {
        'id': 11,
        'ho_ten': 'S11',
        'created_at': '2026-01-01',
        'updated_at': '2026-01-01',
      });
      await dbV9.insert('lop', {
        'id': 21,
        'ten_lop': 'C21',
        'created_at': '2026-01-01',
        'updated_at': '2026-01-01',
      });
      await dbV9.insert('buoi_hoc', {
        'id': 61,
        'id_lop': 21,
        'ngay': '2026-09-21',
        'gio_bat_dau': '17:30',
        'gio_ket_thuc': '19:00',
        'loai': 'CHINH',
        'created_at': '2026-01-01',
        'updated_at': '2026-01-01',
      });

      // Populate v9 ledger rows
      await dbV9.insert('buoi_du_ledger', {
        'id': 100,
        'id_hoc_sinh': 11,
        'id_lop': 21,
        'id_buoi_hoc': 61,
        'ngay_hieu_luc': '2026-09-21',
        'delta': 1,
        'ly_do': 'VUOT_SO_BUOI_CHUAN',
        'ghi_chu': 'Auto earned',
        'created_at': '2026-09-21',
      });
      await dbV9.insert('buoi_du_ledger', {
        'id': 101,
        'id_hoc_sinh': 11,
        'id_lop': 21,
        'id_buoi_hoc': null,
        'ngay_hieu_luc': '2026-09-22',
        'delta': 2,
        'ly_do': 'DIEU_CHINH_THU_CONG',
        'ghi_chu': 'Manual add',
        'created_at': '2026-09-22',
      });
      await dbV9.insert('buoi_du_ledger', {
        'id': 102,
        'id_hoc_sinh': 11,
        'id_lop': 21,
        'id_buoi_hoc': null,
        'ngay_hieu_luc': '2026-09-23',
        'delta': -1,
        'ly_do': 'DIEU_CHINH_THU_CONG',
        'ghi_chu': 'Manual subtract',
        'created_at': '2026-09-23',
      });
      await dbV9.close();

      final appDb = AppDatabase(dbName: dbPath);
      final dbV10 = await appDb.database;

      expect(await dbV10.getVersion(), 10);

      // Verify all rows survive
      final rows = await dbV10.query('buoi_du_ledger', orderBy: 'id ASC');
      expect(rows.length, 3);

      expect(rows[0]['ly_do'], 'VUOT_SO_BUOI_CHUAN');
      expect(rows[0]['delta'], 1);
      expect(rows[0]['id_buoi_hoc'], 61);
      expect(rows[0]['ngay_hieu_luc'], '2026-09-21');
      expect(rows[0]['ghi_chu'], 'Auto earned');

      expect(rows[1]['ly_do'], 'DIEU_CHINH_THU_CONG');
      expect(rows[1]['delta'], 2);
      expect(rows[1]['id_buoi_hoc'], null);
      expect(rows[1]['ngay_hieu_luc'], '2026-09-22');
      expect(rows[1]['ghi_chu'], 'Manual add');

      expect(rows[2]['ly_do'], 'DIEU_CHINH_THU_CONG');
      expect(rows[2]['delta'], -1);
      expect(rows[2]['id_buoi_hoc'], null);
      expect(rows[2]['ngay_hieu_luc'], '2026-09-23');
      expect(rows[2]['ghi_chu'], 'Manual subtract');

      final violations = await dbV10.rawQuery('PRAGMA foreign_key_check');
      expect(violations, isEmpty);

      await dbV10.close();
    });

    test(
      'Fresh install DB version is 10 and foreign_key_check clean',
      () async {
        final freshDbPath = join(
          Directory.systemTemp.path,
          'test_fresh_v10.db',
        );
        await deleteDatabase(freshDbPath);

        final appDb = AppDatabase(dbName: freshDbPath);
        final db = await appDb.database;

        expect(await db.getVersion(), 10);

        final violations = await db.rawQuery('PRAGMA foreign_key_check');
        expect(violations, isEmpty);

        await db.close();
        await deleteDatabase(freshDbPath);
      },
    );

    test('Raw SQLite reason-specific CHECK constraints in v10', () async {
      final tempDbReg = join(
        Directory.systemTemp.path,
        'test_regression_v10.db',
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

      // 1. VUOT_SO_BUOI_CHUAN +1 with session -> ACCEPT
      await db.execute(
        "INSERT INTO buoi_du_ledger (id_hoc_sinh, id_lop, id_buoi_hoc, ngay_hieu_luc, delta, ly_do, created_at) VALUES (1, 1, 1, '2026-09-21', 1, 'VUOT_SO_BUOI_CHUAN', 'now')",
      );

      // 2. VUOT_SO_BUOI_CHUAN delta = -1 -> REJECT
      expect(
        () => db.execute(
          "INSERT INTO buoi_du_ledger (id_hoc_sinh, id_lop, id_buoi_hoc, ngay_hieu_luc, delta, ly_do, created_at) VALUES (1, 1, 1, '2026-09-21', -1, 'VUOT_SO_BUOI_CHUAN', 'now')",
        ),
        throwsA(isA<DatabaseException>()),
      );

      // 3. VUOT_SO_BUOI_CHUAN delta = +2 -> REJECT
      expect(
        () => db.execute(
          "INSERT INTO buoi_du_ledger (id_hoc_sinh, id_lop, id_buoi_hoc, ngay_hieu_luc, delta, ly_do, created_at) VALUES (1, 1, 1, '2026-09-21', 2, 'VUOT_SO_BUOI_CHUAN', 'now')",
        ),
        throwsA(isA<DatabaseException>()),
      );

      // 4. VUOT_SO_BUOI_CHUAN with NULL session -> REJECT
      expect(
        () => db.execute(
          "INSERT INTO buoi_du_ledger (id_hoc_sinh, id_lop, id_buoi_hoc, ngay_hieu_luc, delta, ly_do, created_at) VALUES (1, 1, NULL, '2026-09-21', 1, 'VUOT_SO_BUOI_CHUAN', 'now')",
        ),
        throwsA(isA<DatabaseException>()),
      );

      // 5. BU_TRU_NGHI_CO_PHEP -1 with session -> ACCEPT
      await db.execute(
        "INSERT INTO buoi_du_ledger (id_hoc_sinh, id_lop, id_buoi_hoc, ngay_hieu_luc, delta, ly_do, created_at) VALUES (1, 1, 1, '2026-09-21', -1, 'BU_TRU_NGHI_CO_PHEP', 'now')",
      );

      // 6. BU_TRU_NGHI_CO_PHEP +1 -> REJECT
      expect(
        () => db.execute(
          "INSERT INTO buoi_du_ledger (id_hoc_sinh, id_lop, id_buoi_hoc, ngay_hieu_luc, delta, ly_do, created_at) VALUES (1, 1, 1, '2026-09-21', 1, 'BU_TRU_NGHI_CO_PHEP', 'now')",
        ),
        throwsA(isA<DatabaseException>()),
      );

      // 7. BU_TRU_NGHI_CO_PHEP -2 -> REJECT
      expect(
        () => db.execute(
          "INSERT INTO buoi_du_ledger (id_hoc_sinh, id_lop, id_buoi_hoc, ngay_hieu_luc, delta, ly_do, created_at) VALUES (1, 1, 1, '2026-09-21', -2, 'BU_TRU_NGHI_CO_PHEP', 'now')",
        ),
        throwsA(isA<DatabaseException>()),
      );

      // 8. BU_TRU_NGHI_CO_PHEP with NULL session -> REJECT
      expect(
        () => db.execute(
          "INSERT INTO buoi_du_ledger (id_hoc_sinh, id_lop, id_buoi_hoc, ngay_hieu_luc, delta, ly_do, created_at) VALUES (1, 1, NULL, '2026-09-21', -1, 'BU_TRU_NGHI_CO_PHEP', 'now')",
        ),
        throwsA(isA<DatabaseException>()),
      );

      // 9. DIEU_CHINH_THU_CONG with any non-zero delta -> ACCEPT
      await db.execute(
        "INSERT INTO buoi_du_ledger (id_hoc_sinh, id_lop, ngay_hieu_luc, delta, ly_do, created_at) VALUES (1, 1, '2026-09-21', 5, 'DIEU_CHINH_THU_CONG', 'now')",
      );
      await db.execute(
        "INSERT INTO buoi_du_ledger (id_hoc_sinh, id_lop, ngay_hieu_luc, delta, ly_do, created_at) VALUES (1, 1, '2026-09-21', -3, 'DIEU_CHINH_THU_CONG', 'now')",
      );

      // 10. MIGRATION with non-zero delta -> ACCEPT
      await db.execute(
        "INSERT INTO buoi_du_ledger (id_hoc_sinh, id_lop, ngay_hieu_luc, delta, ly_do, created_at) VALUES (1, 1, '2026-09-21', -2, 'MIGRATION', 'now')",
      );

      await db.close();
      await deleteDatabase(tempDbReg);
    });

    test(
      'Migration v9 to v10 fails clearly if v9 database contains an invalid row',
      () async {
        final invalidDbPath = join(
          Directory.systemTemp.path,
          'test_invalid_v9.db',
        );
        await deleteDatabase(invalidDbPath);

        final dbV9 = await openDatabase(
          invalidDbPath,
          version: 9,
          onCreate: (db, version) async {
            await db.execute(
              "CREATE TABLE hoc_sinh (id INTEGER PRIMARY KEY, ho_ten TEXT, created_at TEXT, updated_at TEXT)",
            );
            await db.execute(
              "CREATE TABLE lop (id INTEGER PRIMARY KEY, ten_lop TEXT, created_at TEXT, updated_at TEXT)",
            );
            await db.execute(
              "CREATE TABLE buoi_hoc (id INTEGER PRIMARY KEY, id_lop INTEGER, ngay TEXT, gio_bat_dau TEXT, gio_ket_thuc TEXT, loai TEXT, created_at TEXT, updated_at TEXT)",
            );
            await db.execute(
              "CREATE TABLE buoi_du_ledger (id INTEGER PRIMARY KEY, id_hoc_sinh INTEGER, id_lop INTEGER, id_buoi_hoc INTEGER, ngay_hieu_luc TEXT, delta INTEGER, ly_do TEXT, ghi_chu TEXT, created_at TEXT)",
            );
          },
        );

        await dbV9.execute(
          "INSERT INTO hoc_sinh VALUES (1, 'H', 'now', 'now')",
        );
        await dbV9.execute("INSERT INTO lop VALUES (1, 'L', 'now', 'now')");
        await dbV9.execute(
          "INSERT INTO buoi_hoc VALUES (1, 1, '2026-09-21', '17:30', '19:00', 'CHINH', 'now', 'now')",
        );

        // Insert invalid v9 row: VUOT_SO_BUOI_CHUAN with delta = -1 (which v9 allowed but v10 CHECK rejects)
        await dbV9.execute(
          "INSERT INTO buoi_du_ledger VALUES (1, 1, 1, 1, '2026-09-21', -1, 'VUOT_SO_BUOI_CHUAN', 'Invalid', 'now')",
        );
        await dbV9.close();

        final appDb = AppDatabase(dbName: invalidDbPath);
        await expectLater(appDb.database, throwsA(isA<DatabaseException>()));

        await deleteDatabase(invalidDbPath);
      },
    );
  });
}
