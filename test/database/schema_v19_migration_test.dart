import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tuition2027/core/database/app_database.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Database Schema V19 Migration Tests', () {
    test('upgrades from v18 to v19 cleanly and preserves existing data', () async {
      final dbFile = File(p.join(Directory.systemTemp.path, 'test_v19_migration.db'));
      if (dbFile.existsSync()) dbFile.deleteSync();
      final dbPath = dbFile.path;
      final db = await openDatabase(
        dbPath,
        version: 18,
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
            CREATE TABLE chinh_sach_hoc_phi (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              id_lop INTEGER NOT NULL,
              hieu_luc_tu TEXT NOT NULL,
              hieu_luc_den TEXT NULL,
              so_buoi_chuan_thang INTEGER NOT NULL DEFAULT 12,
              hoc_phi_moi_buoi INTEGER NOT NULL DEFAULT 0,
              hoc_phi_thang_toi_da INTEGER NULL,
              quy_tac_nghi_co_phep TEXT NOT NULL DEFAULT 'buTruBuoiDu',
              ghi_chu TEXT NULL,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE hoc_phi_thang (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              id_hoc_sinh INTEGER NOT NULL,
              id_lop INTEGER NOT NULL,
              thang TEXT NOT NULL,
              id_chinh_sach_hoc_phi INTEGER NOT NULL,
              so_buoi_eligible INTEGER NOT NULL,
              so_buoi_du_kien INTEGER NOT NULL DEFAULT 0,
              so_buoi_tinh_phi INTEGER NOT NULL,
              credit_opening INTEGER NOT NULL,
              credit_earned INTEGER NOT NULL,
              credit_used INTEGER NOT NULL,
              credit_closing INTEGER NOT NULL,
              tong_truoc_giam INTEGER NOT NULL,
              giam_phan_tram INTEGER NOT NULL DEFAULT 0,
              giam_so_tien INTEGER NOT NULL DEFAULT 0,
              so_tien_phai_thu INTEGER NOT NULL,
              trang_thai TEXT NOT NULL,
              chot_luc TEXT NULL,
              ghi_chu TEXT NULL,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL
            )
          ''');
        },
      );

      // Insert dummy v18 data
      await db.insert('hoc_sinh', {
        'ho_ten': 'Hoc Sinh Test',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      await db.insert('lop', {
        'ten_lop': 'Lop 9A',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      await db.insert('chinh_sach_hoc_phi', {
        'id_lop': 1,
        'hieu_luc_tu': '2026-01-01',
        'hoc_phi_moi_buoi': 50000,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      await db.insert('hoc_phi_thang', {
        'id_hoc_sinh': 1,
        'id_lop': 1,
        'thang': '2026-09',
        'id_chinh_sach_hoc_phi': 1,
        'so_buoi_eligible': 12,
        'so_buoi_du_kien': 12,
        'so_buoi_tinh_phi': 12,
        'credit_opening': 0,
        'credit_earned': 0,
        'credit_used': 0,
        'credit_closing': 0,
        'tong_truoc_giam': 600000,
        'so_tien_phai_thu': 600000,
        'trang_thai': 'DA_CHOT',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      await db.close();

      // Now upgrade using AppDatabase with v19 schema
      final appDb = AppDatabase(dbName: dbPath);
      final upgradedDb = await appDb.database;

      // Verify table center_tuition_policy exists
      final centerTable = await upgradedDb.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='center_tuition_policy'",
      );
      expect(centerTable.length, equals(1));

      // Verify existing invoice row survived and has id_chinh_sach_trung_tam == null
      final invoices = await upgradedDb.query('hoc_phi_thang');
      expect(invoices.length, equals(1));
      expect(invoices.first['id_chinh_sach_hoc_phi'], equals(1));
      expect(invoices.first['id_chinh_sach_trung_tam'], isNull);

      // Verify PRAGMA foreign_key_check is clean
      final fkCheck = await upgradedDb.rawQuery('PRAGMA foreign_key_check');
      expect(fkCheck, isEmpty);
    });
  });
}
