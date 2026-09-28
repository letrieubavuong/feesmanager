import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:tuition2027/core/database/app_database.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('Migration v13 to v14 Real DB Tests', () {
    late String dbPath;

    setUp(() async {
      final tempDir = await Directory.systemTemp.createTemp(
        'migration_v13_v14_real',
      );
      dbPath = join(tempDir.path, 'migration_v13_v14.db');
    });

    test(
      'Real v13 database upgrades to v14 creating audit tables thanh_toan_chinh_sua and hoc_phi_chinh_sua',
      () async {
        // 1. Create a real v13 database
        final dbV13 = await openDatabase(
          dbPath,
          version: 13,
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
            CREATE TABLE chinh_sach_hoc_phi (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              id_lop INTEGER NOT NULL,
              hieu_luc_tu TEXT NOT NULL,
              hieu_luc_den TEXT NULL,
              so_buoi_chuan_thang INTEGER NOT NULL DEFAULT 12,
              hoc_phi_moi_buoi INTEGER NOT NULL DEFAULT 0,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL,
              FOREIGN KEY (id_lop) REFERENCES lop (id)
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
              so_buoi_tinh_phi INTEGER NOT NULL,
              credit_opening INTEGER NOT NULL,
              credit_earned INTEGER NOT NULL,
              credit_used INTEGER NOT NULL,
              credit_closing INTEGER NOT NULL,
              tong_truoc_giam INTEGER NOT NULL,
              so_tien_phai_thu INTEGER NOT NULL,
              trang_thai TEXT NOT NULL,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL,
              FOREIGN KEY (id_hoc_sinh) REFERENCES hoc_sinh (id),
              FOREIGN KEY (id_lop) REFERENCES lop (id),
              FOREIGN KEY (id_chinh_sach_hoc_phi) REFERENCES chinh_sach_hoc_phi (id)
            )
          ''');
            await db.execute('''
            CREATE TABLE thanh_toan (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              id_hoc_sinh INTEGER NOT NULL,
              id_lop INTEGER NOT NULL,
              id_hoc_phi_thang INTEGER NULL,
              thang TEXT NOT NULL,
              so_tien INTEGER NOT NULL,
              ngay_thanh_toan TEXT NOT NULL,
              phuong_thuc TEXT NOT NULL,
              ma_giao_dich TEXT NULL,
              created_at TEXT NOT NULL,
              FOREIGN KEY (id_hoc_sinh) REFERENCES hoc_sinh (id) ON DELETE RESTRICT,
              FOREIGN KEY (id_lop) REFERENCES lop (id) ON DELETE RESTRICT,
              FOREIGN KEY (id_hoc_phi_thang) REFERENCES hoc_phi_thang (id) ON DELETE RESTRICT
            )
          ''');

            // Seed Phase 0-13 data in v13
            await db.execute(
              "INSERT INTO hoc_sinh (id, ho_ten, created_at, updated_at) VALUES (101, 'Student 101', '2026-01-01', '2026-01-01')",
            );
            await db.execute(
              "INSERT INTO lop (id, ten_lop, created_at, updated_at) VALUES (201, 'Class 201', '2026-01-01', '2026-01-01')",
            );
            await db.execute(
              "INSERT INTO chinh_sach_hoc_phi (id, id_lop, hieu_luc_tu, hoc_phi_moi_buoi, created_at, updated_at) VALUES (501, 201, '2026-01-01', 50000, '2026-01-01', '2026-01-01')",
            );
            await db.execute('''
            INSERT INTO hoc_phi_thang (id, id_hoc_sinh, id_lop, thang, id_chinh_sach_hoc_phi, so_buoi_eligible, so_buoi_tinh_phi, credit_opening, credit_earned, credit_used, credit_closing, tong_truoc_giam, so_tien_phai_thu, trang_thai, created_at, updated_at)
            VALUES (601, 101, 201, '2026-09', 501, 12, 12, 0, 0, 0, 0, 600000, 600000, 'CON_NO', '2026-09-01', '2026-09-01')
          ''');
            await db.execute('''
            INSERT INTO thanh_toan (id, id_hoc_sinh, id_lop, id_hoc_phi_thang, thang, so_tien, ngay_thanh_toan, phuong_thuc, ma_giao_dich, created_at)
            VALUES (701, 101, 201, 601, '2026-09', 300000, '2026-09-15', 'CHUYEN_KHOAN', 'BANK_001', '2026-09-15')
          ''');
          },
        );
        await dbV13.close();

        // 2. Open via AppDatabase (upgrades v13 -> v14)
        final appDb = AppDatabase(dbName: dbPath);
        final dbV14 = await appDb.database;

        expect(await dbV14.getVersion(), 14);

        // Assert tables created
        final paymentAuditTable = await dbV14.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='thanh_toan_chinh_sua'",
        );
        expect(paymentAuditTable, isNotEmpty);

        final invoiceAuditTable = await dbV14.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='hoc_phi_chinh_sua'",
        );
        expect(invoiceAuditTable, isNotEmpty);

        // Assert indexes created
        final paymentIndexes = await dbV14.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='index' AND tbl_name='thanh_toan_chinh_sua'",
        );
        expect(
          paymentIndexes
              .map((i) => i['name'])
              .contains('idx_thanh_toan_chinh_sua_payment'),
          isTrue,
        );

        final invoiceIndexes = await dbV14.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='index' AND tbl_name='hoc_phi_chinh_sua'",
        );
        expect(
          invoiceIndexes
              .map((i) => i['name'])
              .contains('idx_hoc_phi_chinh_sua_invoice'),
          isTrue,
        );

        // Insert valid payment audit
        await dbV14.execute('''
          INSERT INTO thanh_toan_chinh_sua (id_thanh_toan, so_tien_cu, so_tien_moi, ngay_thanh_toan_cu, ngay_thanh_toan_moi, phuong_thuc_cu, phuong_thuc_moi, ly_do_chinh_sua, changed_at)
          VALUES (701, 300000, 250000, '2026-09-15', '2026-09-15', 'CHUYEN_KHOAN', 'CHUYEN_KHOAN', 'Sửa nhầm số tiền', '2026-09-16T10:00:00')
        ''');

        // Assert FK RESTRICT on payment deletion with audit
        expect(
          () => dbV14.execute("DELETE FROM thanh_toan WHERE id = 701"),
          throwsA(isA<DatabaseException>()),
        );

        final PRAGMA = await dbV14.rawQuery('PRAGMA foreign_key_check');
        expect(PRAGMA, isEmpty);

        await dbV14.close();
      },
    );
  });
}
