import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:tuition2027/core/database/app_database.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('Migration v11 to v12 Real DB Tests', () {
    late String dbPath;

    setUp(() async {
      final tempDir = await Directory.systemTemp.createTemp(
        'migration_v11_v12_real',
      );
      dbPath = join(tempDir.path, 'migration_v11_v12.db');
    });

    test(
      'Real v11 database upgrades to v12 preserving Phase 0-9 data and enforcing FK RESTRICT',
      () async {
        // 1. Create a real v11 database
        final dbV11 = await openDatabase(
          dbPath,
          version: 11,
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
              hoc_phi_thang_toi_da INTEGER NULL,
              ghi_chu TEXT NULL,
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
              giam_phan_tram INTEGER NOT NULL DEFAULT 0,
              giam_so_tien INTEGER NOT NULL DEFAULT 0,
              so_tien_phai_thu INTEGER NOT NULL,
              trang_thai TEXT NOT NULL,
              chot_luc TEXT NULL,
              ghi_chu TEXT NULL,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL,
              FOREIGN KEY (id_hoc_sinh) REFERENCES hoc_sinh (id),
              FOREIGN KEY (id_lop) REFERENCES lop (id),
              FOREIGN KEY (id_chinh_sach_hoc_phi) REFERENCES chinh_sach_hoc_phi (id)
            )
          ''');

            // Seed Phase 0-9 data in v11
            await db.execute(
              "INSERT INTO hoc_sinh (id, ho_ten, created_at, updated_at) VALUES (101, 'Student 101', '2026-01-01', '2026-01-01')",
            );
            await db.execute(
              "INSERT INTO lop (id, ten_lop, created_at, updated_at) VALUES (201, 'Class 201', '2026-01-01', '2026-01-01')",
            );
            await db.execute(
              "INSERT INTO chinh_sach_hoc_phi (id, id_lop, hieu_luc_tu, hoc_phi_moi_buoi, created_at, updated_at) VALUES (301, 201, '2026-01-01', 50000, '2026-01-01', '2026-01-01')",
            );
            await db.execute('''
            INSERT INTO hoc_phi_thang (id, id_hoc_sinh, id_lop, thang, id_chinh_sach_hoc_phi, so_buoi_eligible, so_buoi_tinh_phi, credit_opening, credit_earned, credit_used, credit_closing, tong_truoc_giam, so_tien_phai_thu, trang_thai, created_at, updated_at)
            VALUES (401, 101, 201, '2026-09', 301, 12, 12, 0, 0, 0, 0, 600000, 600000, 'DA_CHOT', '2026-09-01', '2026-09-01')
          ''');
          },
        );
        await dbV11.close();

        // 2. Open via AppDatabase (upgrades v11 -> v12)
        final appDb = AppDatabase(dbName: dbPath);
        final dbV12 = await appDb.database;

        // Assert version is 12
        expect(await dbV12.getVersion(), 13);

        // Assert Phase 0-9 data preserved (students, classes, policies, invoices)
        final hs = await dbV12.query('hoc_sinh', where: 'id = 101');
        expect(hs.first['ho_ten'], 'Student 101');

        final policy = await dbV12.query(
          'chinh_sach_hoc_phi',
          where: 'id = 301',
        );
        expect(policy.first['hoc_phi_moi_buoi'], 50000);

        final invoice = await dbV12.query('hoc_phi_thang', where: 'id = 401');
        expect(invoice.first['so_tien_phai_thu'], 600000);

        // Assert thanh_toan table created
        final tables = await dbV12.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='thanh_toan'",
        );
        expect(tables, isNotEmpty);

        // Assert indexes created
        final indexes = await dbV12.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='index' AND tbl_name='thanh_toan'",
        );
        final indexNames = indexes.map((i) => i['name'] as String).toSet();
        expect(indexNames.contains('idx_thanh_toan_ma_giao_dich'), isTrue);
        expect(indexNames.contains('idx_thanh_toan_invoice'), isTrue);
        expect(
          indexNames.contains('idx_thanh_toan_student_class_month'),
          isTrue,
        );
        expect(indexNames.contains('idx_thanh_toan_ngay'), isTrue);

        // Insert valid payment in v12
        await dbV12.execute('''
        INSERT INTO thanh_toan (id_hoc_sinh, id_lop, id_hoc_phi_thang, thang, so_tien, ngay_thanh_toan, phuong_thuc, ma_giao_dich, created_at)
        VALUES (101, 201, 401, '2026-09', 300000, '2026-09-15', 'CHUYEN_KHOAN', 'BANK_TX_001', '2026-09-15T10:00:00')
      ''');

        // Assert CHECK constraint: so_tien > 0
        expect(
          () => dbV12.execute('''
          INSERT INTO thanh_toan (id_hoc_sinh, id_lop, id_hoc_phi_thang, thang, so_tien, ngay_thanh_toan, phuong_thuc, created_at)
          VALUES (101, 201, 401, '2026-09', 0, '2026-09-15', 'TIEN_MAT', '2026-09-15T10:00:00')
        '''),
          throwsA(isA<DatabaseException>()),
        );

        // Assert CHECK constraint: phuong_thuc IN ('TIEN_MAT', 'CHUYEN_KHOAN', 'KHAC')
        expect(
          () => dbV12.execute('''
          INSERT INTO thanh_toan (id_hoc_sinh, id_lop, id_hoc_phi_thang, thang, so_tien, ngay_thanh_toan, phuong_thuc, created_at)
          VALUES (101, 201, 401, '2026-09', 100000, '2026-09-15', 'INVALID', '2026-09-15T10:00:00')
        '''),
          throwsA(isA<DatabaseException>()),
        );

        // Assert ON DELETE RESTRICT on student deletion
        expect(
          () => dbV12.execute("DELETE FROM hoc_sinh WHERE id = 101"),
          throwsA(isA<DatabaseException>()),
        );

        // Assert ON DELETE RESTRICT on class deletion
        expect(
          () => dbV12.execute("DELETE FROM lop WHERE id = 201"),
          throwsA(isA<DatabaseException>()),
        );

        // Assert ON DELETE RESTRICT on invoice deletion
        expect(
          () => dbV12.execute("DELETE FROM hoc_phi_thang WHERE id = 401"),
          throwsA(isA<DatabaseException>()),
        );

        // Assert partial UNIQUE index on ma_giao_dich
        expect(
          () => dbV12.execute('''
          INSERT INTO thanh_toan (id_hoc_sinh, id_lop, id_hoc_phi_thang, thang, so_tien, ngay_thanh_toan, phuong_thuc, ma_giao_dich, created_at)
          VALUES (101, 201, 401, '2026-09', 100000, '2026-09-16', 'CHUYEN_KHOAN', 'BANK_TX_001', '2026-09-16T10:00:00')
        '''),
          throwsA(isA<DatabaseException>()),
        );

        // Assert PRAGMA foreign_key_check is clean
        final violations = await dbV12.rawQuery('PRAGMA foreign_key_check');
        expect(violations, isEmpty);

        await dbV12.close();
      },
    );
  });
}
