import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class AppDatabase {
  static const String _dbName = 'tuition_next.db';
  static const int _dbVersion = 1;

  Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onConfigure: _onConfigure,
    );
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreate(Database db, int version) async {
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

    await db.execute('CREATE INDEX idx_hoc_sinh_ho_ten ON hoc_sinh(ho_ten)');
    await db.execute('CREATE INDEX idx_hoc_sinh_sdt_phu_huynh ON hoc_sinh(sdt_phu_huynh)');
    await db.execute('CREATE INDEX idx_hoc_sinh_da_luu_tru ON hoc_sinh(da_luu_tru)');
  }
}
