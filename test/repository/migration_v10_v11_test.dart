import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:tuition2027/core/database/app_database.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('AppDatabase Migration v10 to v11', () {
    late String dbPath;

    setUp(() async {
      final tempDir = await Directory.systemTemp.createTemp(
        'migration_test_v10_v11',
      );
      dbPath = join(tempDir.path, 'test_migration_v10_v11.db');
    });

    test('Migration v10 to v11 preserves canonical Phase 0-8 data', () async {
      final dbV10 = await openDatabase(
        dbPath,
        version: 10,
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
              FOREIGN KEY (id_lop) REFERENCES lop (id)
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
              FOREIGN KEY (id_buoi_hoc) REFERENCES buoi_hoc (id)
            )
          ''');
        },
        onConfigure: (db) async => await db.execute('PRAGMA foreign_keys = ON'),
      );

      await dbV10.insert('hoc_sinh', {
        'id': 101,
        'ho_ten': 'Student 101',
        'created_at': '2026-01-01',
        'updated_at': '2026-01-01',
      });
      await dbV10.insert('lop', {
        'id': 201,
        'ten_lop': 'Class 201',
        'created_at': '2026-01-01',
        'updated_at': '2026-01-01',
      });
      await dbV10.insert('buoi_hoc', {
        'id': 301,
        'id_lop': 201,
        'ngay': '2026-09-20',
        'gio_bat_dau': '17:30',
        'gio_ket_thuc': '19:00',
        'loai': 'CHINH',
        'created_at': '2026-01-01',
        'updated_at': '2026-01-01',
      });
      await dbV10.insert('buoi_du_ledger', {
        'id': 401,
        'id_hoc_sinh': 101,
        'id_lop': 201,
        'id_buoi_hoc': 301,
        'ngay_hieu_luc': '2026-09-20',
        'delta': 1,
        'ly_do': 'VUOT_SO_BUOI_CHUAN',
        'created_at': '2026-09-20',
      });
      await dbV10.close();

      // Upgrade via AppDatabase
      final appDb = AppDatabase(dbName: dbPath);
      final dbV11 = await appDb.database;

      expect(await dbV11.getVersion(), 13);

      // Assert all Phase 0-8 data survived
      final hs = await dbV11.query('hoc_sinh', where: 'id = 101');
      expect(hs.first['ho_ten'], 'Student 101');

      final cls = await dbV11.query('lop', where: 'id = 201');
      expect(cls.first['ten_lop'], 'Class 201');

      final ledger = await dbV11.query('buoi_du_ledger', where: 'id = 401');
      expect(ledger.first['delta'], 1);

      // Verify PRAGMA foreign_key_check is clean
      final violations = await dbV11.rawQuery('PRAGMA foreign_key_check');
      expect(violations, isEmpty);

      await dbV11.close();
    });

    test(
      'Fresh install DB version is 11 and foreign_key_check clean',
      () async {
        final freshDbPath = join(
          Directory.systemTemp.path,
          'test_fresh_v11.db',
        );
        await deleteDatabase(freshDbPath);

        final appDb = AppDatabase(dbName: freshDbPath);
        final db = await appDb.database;

        expect(await db.getVersion(), 13);

        final tables = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table'",
        );
        final tableNames = tables.map((t) => t['name'] as String).toSet();

        expect(tableNames.contains('chinh_sach_hoc_phi'), isTrue);
        expect(tableNames.contains('hoc_phi_thang'), isTrue);

        final violations = await db.rawQuery('PRAGMA foreign_key_check');
        expect(violations, isEmpty);

        await db.close();
        await deleteDatabase(freshDbPath);
      },
    );

    test('Raw SQLite constraints for Phase 9 tables', () async {
      final tempDb = join(Directory.systemTemp.path, 'test_v11_constraints.db');
      await deleteDatabase(tempDb);

      final appDb = AppDatabase(dbName: tempDb);
      final db = await appDb.database;

      await db.execute(
        "INSERT INTO hoc_sinh (id, ho_ten, created_at, updated_at) VALUES (1, 'H', 'now', 'now')",
      );
      await db.execute(
        "INSERT INTO lop (id, ten_lop, created_at, updated_at) VALUES (1, 'L', 'now', 'now')",
      );

      // 1. Valid policy
      await db.execute('''
        INSERT INTO chinh_sach_hoc_phi (id, id_lop, hieu_luc_tu, hieu_luc_den, so_buoi_chuan_thang, hoc_phi_moi_buoi, hoc_phi_thang_toi_da, created_at, updated_at)
        VALUES (10, 1, '2026-09-01', NULL, 12, 50000, 600000, 'now', 'now')
      ''');

      // 2. Reject duplicate open policy for same class
      expect(
        () => db.execute('''
          INSERT INTO chinh_sach_hoc_phi (id_lop, hieu_luc_tu, hieu_luc_den, so_buoi_chuan_thang, hoc_phi_moi_buoi, created_at, updated_at)
          VALUES (1, '2026-10-01', NULL, 12, 60000, 'now', 'now')
        '''),
        throwsA(isA<DatabaseException>()),
      );

      // 3. Reject negative fee
      expect(
        () => db.execute('''
          INSERT INTO chinh_sach_hoc_phi (id_lop, hieu_luc_tu, so_buoi_chuan_thang, hoc_phi_moi_buoi, created_at, updated_at)
          VALUES (1, '2026-11-01', 12, -1000, 'now', 'now')
        '''),
        throwsA(isA<DatabaseException>()),
      );

      // 4. Valid invoice
      await db.execute('''
        INSERT INTO hoc_phi_thang (id_hoc_sinh, id_lop, thang, id_chinh_sach_hoc_phi, so_buoi_eligible, so_buoi_tinh_phi, credit_opening, credit_earned, credit_used, credit_closing, tong_truoc_giam, giam_phan_tram, giam_so_tien, so_tien_phai_thu, trang_thai, created_at, updated_at)
        VALUES (1, 1, '2026-09', 10, 12, 12, 0, 0, 0, 0, 600000, 0, 0, 600000, 'DA_CHOT', 'now', 'now')
      ''');

      // 5. Reject duplicate invoice for same student + class + month
      expect(
        () => db.execute('''
          INSERT INTO hoc_phi_thang (id_hoc_sinh, id_lop, thang, id_chinh_sach_hoc_phi, so_buoi_eligible, so_buoi_tinh_phi, credit_opening, credit_earned, credit_used, credit_closing, tong_truoc_giam, giam_phan_tram, giam_so_tien, so_tien_phai_thu, trang_thai, created_at, updated_at)
          VALUES (1, 1, '2026-09', 10, 12, 12, 0, 0, 0, 0, 600000, 0, 0, 600000, 'DA_CHOT', 'now', 'now')
        '''),
        throwsA(isA<DatabaseException>()),
      );

      await db.close();
      await deleteDatabase(tempDb);
    });
  });
}
