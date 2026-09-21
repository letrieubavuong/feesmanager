import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tuition2027/core/database/app_database.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('AppDatabase Migration v6 to v7', () {
    test('Migration v6 to v7 preserves data and creates diem_danh table', () async {
      // Use in-memory DB but without the automatic AppDatabase logic initially
      final db = await openDatabase(
        inMemoryDatabasePath,
        version: 6,
        onCreate: (db, version) async {
          await db.execute('CREATE TABLE hoc_sinh (id INTEGER PRIMARY KEY, ho_ten TEXT, created_at TEXT, updated_at TEXT)');
          await db.execute('CREATE TABLE lop (id INTEGER PRIMARY KEY, ten_lop TEXT, created_at TEXT, updated_at TEXT)');
          await db.execute('CREATE TABLE buoi_hoc (id INTEGER PRIMARY KEY, id_lop INTEGER, ngay TEXT, gio_bat_dau TEXT, gio_ket_thuc TEXT, loai TEXT, created_at TEXT, updated_at TEXT)');
        },
      );

      await db.insert('hoc_sinh', {'id': 1, 'ho_ten': 'HS1', 'created_at': '2026-01-01', 'updated_at': '2026-01-01'});
      await db.insert('lop', {'id': 1, 'ten_lop': 'L1', 'created_at': '2026-01-01', 'updated_at': '2026-01-01'});
      await db.insert('buoi_hoc', {
        'id': 1, 
        'id_lop': 1, 
        'ngay': '2026-09-21', 
        'gio_bat_dau': '17:30', 
        'gio_ket_thuc': '19:00', 
        'loai': 'CHINH', 
        'created_at': '2026-01-01', 
        'updated_at': '2026-01-01'
      });

      // Now use AppDatabase on the SAME memory instance (requires caution with sqflite_ffi)
      // For FFI in-memory, each openDatabase(inMemoryDatabasePath) is a NEW database.
      // So we must trigger migration on the ALREADY open DB if possible, or use a file.
      
      // Let's use a temporary file for migration test to be safe.
      final tempDbPath = 'test_migration_v6_v7.db';
      await deleteDatabase(tempDbPath);
      
      final dbFileV6 = await openDatabase(
        tempDbPath,
        version: 6,
        onCreate: (db, version) async {
          await db.execute('CREATE TABLE hoc_sinh (id INTEGER PRIMARY KEY, ho_ten TEXT, created_at TEXT, updated_at TEXT)');
          await db.execute('CREATE TABLE lop (id INTEGER PRIMARY KEY, ten_lop TEXT, created_at TEXT, updated_at TEXT)');
          await db.execute('CREATE TABLE buoi_hoc (id INTEGER PRIMARY KEY, id_lop INTEGER, ngay TEXT, gio_bat_dau TEXT, gio_ket_thuc TEXT, loai TEXT, created_at TEXT, updated_at TEXT)');
        },
      );
      await dbFileV6.insert('hoc_sinh', {'id': 1, 'ho_ten': 'HS1', 'created_at': '2026-01-01', 'updated_at': '2026-01-01'});
      await dbFileV6.close();

      final appDb = AppDatabase(dbName: tempDbPath);
      final dbV7 = await appDb.database;

      expect(await dbV7.getVersion(), 7);
      final hs = await dbV7.query('hoc_sinh', where: 'id = 1');
      expect(hs.first['ho_ten'], 'HS1');

      final tableInfo = await dbV7.rawQuery("PRAGMA table_info(diem_danh)");
      expect(tableInfo.isNotEmpty, isTrue);

      await dbV7.close();
      await deleteDatabase(tempDbPath);
    });
  });
}
