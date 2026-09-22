import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('Migration v11 to v12 Tests', () {
    late String dbPath;

    setUp(() async {
      final tempDir = await Directory.systemTemp.createTemp(
        'migration_v11_v12',
      );
      dbPath = join(tempDir.path, 'migration_v11_v12.db');
    });

    test('Fresh v12 database creates thanh_toan table with constraints', () async {
      final db = await openDatabase(
        dbPath,
        version: 12,
        onConfigure: (db) async => await db.execute('PRAGMA foreign_keys = ON'),
        onCreate: (db, version) async {
          // Execute minimal table creations for v12
          await db.execute('''
            CREATE TABLE hoc_sinh (id INTEGER PRIMARY KEY, ho_ten TEXT NOT NULL)
          ''');
          await db.execute('''
            CREATE TABLE lop (id INTEGER PRIMARY KEY, ten_lop TEXT NOT NULL)
          ''');
          await db.execute('''
            CREATE TABLE hoc_phi_thang (id INTEGER PRIMARY KEY, id_hoc_sinh INTEGER, id_lop INTEGER, thang TEXT, so_tien_phai_thu INTEGER, trang_thai TEXT)
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
              ghi_chu TEXT NULL,
              created_at TEXT NOT NULL,
              FOREIGN KEY (id_hoc_sinh) REFERENCES hoc_sinh (id) ON DELETE RESTRICT,
              FOREIGN KEY (id_lop) REFERENCES lop (id) ON DELETE RESTRICT,
              FOREIGN KEY (id_hoc_phi_thang) REFERENCES hoc_phi_thang (id) ON DELETE RESTRICT,
              CHECK (so_tien > 0),
              CHECK (phuong_thuc IN ('TIEN_MAT', 'CHUYEN_KHOAN', 'KHAC'))
            )
          ''');
          await db.execute('''
            CREATE UNIQUE INDEX idx_thanh_toan_ma_giao_dich 
            ON thanh_toan (ma_giao_dich) 
            WHERE ma_giao_dich IS NOT NULL AND ma_giao_dich <> ''
          ''');
        },
      );

      // Verify table exists
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='thanh_toan'",
      );
      expect(tables, isNotEmpty);

      // Seed foreign keys
      await db.execute(
        "INSERT INTO hoc_sinh (id, ho_ten) VALUES (1, 'Student 1')",
      );
      await db.execute("INSERT INTO lop (id, ten_lop) VALUES (1, 'Class 1')");
      await db.execute(
        "INSERT INTO hoc_phi_thang (id, id_hoc_sinh, id_lop, thang, so_tien_phai_thu, trang_thai) VALUES (1, 1, 1, '2026-09', 600000, 'DA_CHOT')",
      );

      // Insert valid payment
      await db.execute('''
        INSERT INTO thanh_toan (id_hoc_sinh, id_lop, id_hoc_phi_thang, thang, so_tien, ngay_thanh_toan, phuong_thuc, ma_giao_dich, created_at)
        VALUES (1, 1, 1, '2026-09', 300000, '2026-09-15', 'CHUYEN_KHOAN', 'TX123', '2026-09-15T10:00:00')
      ''');

      final payments = await db.query('thanh_toan');
      expect(payments.length, 1);
      expect(payments.first['so_tien'], 300000);

      // Verify duplicate transaction ID fails
      expect(
        () => db.execute('''
          INSERT INTO thanh_toan (id_hoc_sinh, id_lop, id_hoc_phi_thang, thang, so_tien, ngay_thanh_toan, phuong_thuc, ma_giao_dich, created_at)
          VALUES (1, 1, 1, '2026-09', 100000, '2026-09-16', 'CHUYEN_KHOAN', 'TX123', '2026-09-16T10:00:00')
        '''),
        throwsA(isA<DatabaseException>()),
      );

      // Verify invalid amount <= 0 fails
      expect(
        () => db.execute('''
          INSERT INTO thanh_toan (id_hoc_sinh, id_lop, id_hoc_phi_thang, thang, so_tien, ngay_thanh_toan, phuong_thuc, created_at)
          VALUES (1, 1, 1, '2026-09', 0, '2026-09-16', 'TIEN_MAT', '2026-09-16T10:00:00')
        '''),
        throwsA(isA<DatabaseException>()),
      );

      // Verify invalid payment method fails
      expect(
        () => db.execute('''
          INSERT INTO thanh_toan (id_hoc_sinh, id_lop, id_hoc_phi_thang, thang, so_tien, ngay_thanh_toan, phuong_thuc, created_at)
          VALUES (1, 1, 1, '2026-09', 100000, '2026-09-16', 'INVALID_METHOD', '2026-09-16T10:00:00')
        '''),
        throwsA(isA<DatabaseException>()),
      );

      await db.close();
    });
  });
}
