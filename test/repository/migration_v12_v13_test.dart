import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:tuition2027/core/database/app_database.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('Migration v12 to v13 Real DB Tests', () {
    late String dbPath;

    setUp(() async {
      final tempDir = await Directory.systemTemp.createTemp(
        'migration_v12_v13_real',
      );
      dbPath = join(tempDir.path, 'migration_v12_v13.db');
    });

    test(
      'Real v12 database upgrades to v13 preserving Phase 0-10 data and enforcing FK RESTRICT & CHECK constraints',
      () async {
        // 1. Create a real v12 database
        final dbV12 = await openDatabase(
          dbPath,
          version: 12,
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
            CREATE TABLE lich_hoc (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              id_lop INTEGER NOT NULL,
              thu_trong_tuan INTEGER NOT NULL,
              gio_bat_dau TEXT NOT NULL,
              gio_ket_thuc TEXT NOT NULL,
              hieu_luc_tu TEXT NOT NULL,
              hieu_luc_den TEXT NULL,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL,
              FOREIGN KEY (id_lop) REFERENCES lop (id)
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
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL,
              FOREIGN KEY (id_hoc_sinh) REFERENCES hoc_sinh (id),
              FOREIGN KEY (id_lop) REFERENCES lop (id),
              FOREIGN KEY (id_lich_hoc) REFERENCES lich_hoc (id)
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

            // Seed Phase 0-10 data in v12
            await db.execute(
              "INSERT INTO hoc_sinh (id, ho_ten, created_at, updated_at) VALUES (101, 'Student 101', '2026-01-01', '2026-01-01')",
            );
            await db.execute(
              "INSERT INTO lop (id, ten_lop, created_at, updated_at) VALUES (201, 'Class 201', '2026-01-01', '2026-01-01')",
            );
            await db.execute(
              "INSERT INTO lich_hoc (id, id_lop, thu_trong_tuan, gio_bat_dau, gio_ket_thuc, hieu_luc_tu, created_at, updated_at) VALUES (301, 201, 1, '17:30', '19:00', '2026-01-01', '2026-01-01', '2026-01-01')",
            );
            await db.execute(
              "INSERT INTO phan_ca_hoc_sinh (id, id_hoc_sinh, id_lop, id_lich_hoc, tu_ngay, created_at, updated_at) VALUES (401, 101, 201, 301, '2026-01-01', '2026-01-01', '2026-01-01')",
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
        await dbV12.close();

        // 2. Open via AppDatabase (upgrades v12 -> v13)
        final appDb = AppDatabase(dbName: dbPath);
        final dbV13 = await appDb.database;

        // Assert version is 13
        expect(await dbV13.getVersion(), 13);

        // Assert Phase 0-10 data preserved
        final hs = await dbV13.query('hoc_sinh', where: 'id = 101');
        expect(hs.first['ho_ten'], 'Student 101');

        final payment = await dbV13.query('thanh_toan', where: 'id = 701');
        expect(payment.first['so_tien'], 300000);

        // Assert rang_buoc_lich_hoc_sinh table created
        final tables = await dbV13.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='rang_buoc_lich_hoc_sinh'",
        );
        expect(tables, isNotEmpty);

        // Assert indexes created
        final indexes = await dbV13.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='index' AND tbl_name='rang_buoc_lich_hoc_sinh'",
        );
        final indexNames = indexes.map((i) => i['name'] as String).toSet();
        expect(indexNames.contains('idx_rang_buoc_student_status'), isTrue);
        expect(indexNames.contains('idx_rang_buoc_student_weekday'), isTrue);
        expect(indexNames.contains('idx_rang_buoc_student_date'), isTrue);

        // Insert valid DINH_KY constraint
        await dbV13.execute('''
        INSERT INTO rang_buoc_lich_hoc_sinh (id_hoc_sinh, loai, kieu, thu_trong_tuan, gio_bat_dau, gio_ket_thuc, hieu_luc_tu, created_at, updated_at)
        VALUES (101, 'HARD_BLOCK', 'DINH_KY', 1, '18:00', '20:00', '2026-01-01', '2026-01-01', '2026-01-01')
      ''');

        // Insert valid MOT_LAN constraint
        await dbV13.execute('''
        INSERT INTO rang_buoc_lich_hoc_sinh (id_hoc_sinh, loai, kieu, ngay_cu_the, gio_bat_dau, gio_ket_thuc, created_at, updated_at)
        VALUES (101, 'OTHER_CENTER', 'MOT_LAN', '2026-10-15', '08:00', '10:00', '2026-01-01', '2026-01-01')
      ''');

        // Assert CHECK constraint: invalid loai rejected
        expect(
          () => dbV13.execute('''
          INSERT INTO rang_buoc_lich_hoc_sinh (id_hoc_sinh, loai, kieu, thu_trong_tuan, gio_bat_dau, gio_ket_thuc, hieu_luc_tu, created_at, updated_at)
          VALUES (101, 'INVALID_LOAI', 'DINH_KY', 1, '18:00', '20:00', '2026-01-01', '2026-01-01', '2026-01-01')
        '''),
          throwsA(isA<DatabaseException>()),
        );

        // Assert CHECK constraint: invalid kieu rejected
        expect(
          () => dbV13.execute('''
          INSERT INTO rang_buoc_lich_hoc_sinh (id_hoc_sinh, loai, kieu, thu_trong_tuan, gio_bat_dau, gio_ket_thuc, hieu_luc_tu, created_at, updated_at)
          VALUES (101, 'HARD_BLOCK', 'INVALID_KIEU', 1, '18:00', '20:00', '2026-01-01', '2026-01-01', '2026-01-01')
        '''),
          throwsA(isA<DatabaseException>()),
        );

        // Assert CHECK constraint: invalid weekday (not 1..7) rejected
        expect(
          () => dbV13.execute('''
          INSERT INTO rang_buoc_lich_hoc_sinh (id_hoc_sinh, loai, kieu, thu_trong_tuan, gio_bat_dau, gio_ket_thuc, hieu_luc_tu, created_at, updated_at)
          VALUES (101, 'HARD_BLOCK', 'DINH_KY', 9, '18:00', '20:00', '2026-01-01', '2026-01-01', '2026-01-01')
        '''),
          throwsA(isA<DatabaseException>()),
        );

        // Assert CHECK constraint: invalid time format (gio_bat_dau) rejected
        expect(
          () => dbV13.execute('''
          INSERT INTO rang_buoc_lich_hoc_sinh (id_hoc_sinh, loai, kieu, thu_trong_tuan, gio_bat_dau, gio_ket_thuc, hieu_luc_tu, created_at, updated_at)
          VALUES (101, 'HARD_BLOCK', 'DINH_KY', 1, 'INVALID', '20:00', '2026-01-01', '2026-01-01', '2026-01-01')
        '''),
          throwsA(isA<DatabaseException>()),
        );

        // Assert CHECK constraint: gio_ket_thuc <= gio_bat_dau rejected
        expect(
          () => dbV13.execute('''
          INSERT INTO rang_buoc_lich_hoc_sinh (id_hoc_sinh, loai, kieu, thu_trong_tuan, gio_bat_dau, gio_ket_thuc, hieu_luc_tu, created_at, updated_at)
          VALUES (101, 'HARD_BLOCK', 'DINH_KY', 1, '20:00', '18:00', '2026-01-01', '2026-01-01', '2026-01-01')
        '''),
          throwsA(isA<DatabaseException>()),
        );

        // Assert CHECK constraint: negative travel buffer rejected
        expect(
          () => dbV13.execute('''
          INSERT INTO rang_buoc_lich_hoc_sinh (id_hoc_sinh, loai, kieu, thu_trong_tuan, gio_bat_dau, gio_ket_thuc, hieu_luc_tu, travel_buffer_phut, created_at, updated_at)
          VALUES (101, 'OTHER_CENTER', 'DINH_KY', 1, '18:00', '20:00', '2026-01-01', -15, '2026-01-01', '2026-01-01')
        '''),
          throwsA(isA<DatabaseException>()),
        );

        // Assert CHECK constraint: DINH_KY with ngay_cu_the rejected
        expect(
          () => dbV13.execute('''
          INSERT INTO rang_buoc_lich_hoc_sinh (id_hoc_sinh, loai, kieu, thu_trong_tuan, ngay_cu_the, gio_bat_dau, gio_ket_thuc, hieu_luc_tu, created_at, updated_at)
          VALUES (101, 'HARD_BLOCK', 'DINH_KY', 1, '2026-10-15', '18:00', '20:00', '2026-01-01', '2026-01-01', '2026-01-01')
        '''),
          throwsA(isA<DatabaseException>()),
        );

        // Assert CHECK constraint: MOT_LAN with thu_trong_tuan rejected
        expect(
          () => dbV13.execute('''
          INSERT INTO rang_buoc_lich_hoc_sinh (id_hoc_sinh, loai, kieu, thu_trong_tuan, ngay_cu_the, gio_bat_dau, gio_ket_thuc, created_at, updated_at)
          VALUES (101, 'HARD_BLOCK', 'MOT_LAN', 1, '2026-10-15', '18:00', '20:00', '2026-01-01', '2026-01-01')
        '''),
          throwsA(isA<DatabaseException>()),
        );

        // Assert CHECK constraint: DINH_KY with hieu_luc_den < hieu_luc_tu rejected
        expect(
          () => dbV13.execute('''
          INSERT INTO rang_buoc_lich_hoc_sinh (id_hoc_sinh, loai, kieu, thu_trong_tuan, gio_bat_dau, gio_ket_thuc, hieu_luc_tu, hieu_luc_den, created_at, updated_at)
          VALUES (101, 'HARD_BLOCK', 'DINH_KY', 1, '18:00', '20:00', '2026-06-01', '2026-01-01', '2026-01-01', '2026-01-01')
        '''),
          throwsA(isA<DatabaseException>()),
        );

        // Assert CHECK constraint: 24:00 and 25:00 time rejected
        expect(
          () => dbV13.execute('''
          INSERT INTO rang_buoc_lich_hoc_sinh (id_hoc_sinh, loai, kieu, thu_trong_tuan, gio_bat_dau, gio_ket_thuc, hieu_luc_tu, created_at, updated_at)
          VALUES (101, 'HARD_BLOCK', 'DINH_KY', 1, '24:00', '25:00', '2026-01-01', '2026-01-01', '2026-01-01')
        '''),
          throwsA(isA<DatabaseException>()),
        );

        // Assert CHECK constraint: invalid status rejected
        expect(
          () => dbV13.execute('''
          INSERT INTO rang_buoc_lich_hoc_sinh (id_hoc_sinh, loai, kieu, thu_trong_tuan, gio_bat_dau, gio_ket_thuc, hieu_luc_tu, trang_thai, created_at, updated_at)
          VALUES (101, 'HARD_BLOCK', 'DINH_KY', 1, '18:00', '20:00', '2026-01-01', 'INVALID_STATUS', '2026-01-01', '2026-01-01')
        '''),
          throwsA(isA<DatabaseException>()),
        );

        // Assert CHECK constraint: MOT_LAN with effectiveFrom/effectiveTo rejected
        expect(
          () => dbV13.execute('''
          INSERT INTO rang_buoc_lich_hoc_sinh (id_hoc_sinh, loai, kieu, ngay_cu_the, gio_bat_dau, gio_ket_thuc, hieu_luc_tu, created_at, updated_at)
          VALUES (101, 'HARD_BLOCK', 'MOT_LAN', '2026-10-15', '18:00', '20:00', '2026-01-01', '2026-01-01', '2026-01-01')
        '''),
          throwsA(isA<DatabaseException>()),
        );

        // Assert CHECK constraint: malformed date slash 2026/10/15 rejected
        expect(
          () => dbV13.execute('''
          INSERT INTO rang_buoc_lich_hoc_sinh (id_hoc_sinh, loai, kieu, ngay_cu_the, gio_bat_dau, gio_ket_thuc, created_at, updated_at)
          VALUES (101, 'HARD_BLOCK', 'MOT_LAN', '2026/10/15', '18:00', '20:00', '2026-01-01', '2026-01-01')
        '''),
          throwsA(isA<DatabaseException>()),
        );

        // Assert CHECK constraint: invalid month 13 in date 2026-13-01 rejected
        expect(
          () => dbV13.execute('''
          INSERT INTO rang_buoc_lich_hoc_sinh (id_hoc_sinh, loai, kieu, ngay_cu_the, gio_bat_dau, gio_ket_thuc, created_at, updated_at)
          VALUES (101, 'HARD_BLOCK', 'MOT_LAN', '2026-13-01', '18:00', '20:00', '2026-01-01', '2026-01-01')
        '''),
          throwsA(isA<DatabaseException>()),
        );

        // Assert ON DELETE RESTRICT on student deletion with active constraint
        expect(
          () => dbV13.execute("DELETE FROM hoc_sinh WHERE id = 101"),
          throwsA(isA<DatabaseException>()),
        );

        // Assert PRAGMA foreign_key_check is clean
        final violations = await dbV13.rawQuery('PRAGMA foreign_key_check');
        expect(violations, isEmpty);

        await dbV13.close();
      },
    );
  });
}
