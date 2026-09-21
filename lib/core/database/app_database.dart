import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class AppDatabase {
  static const String _dbName = 'tuition_next.db';
  static const int _dbVersion = 2;

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
      onUpgrade: _onUpgrade,
      onConfigure: _onConfigure,
    );
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createTablesV1(db);
    if (version >= 2) {
      await _migrateV1ToV2(db);
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _migrateV1ToV2(db);
    }
  }

  Future<void> _createTablesV1(Database db) async {
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

  Future<void> _migrateV1ToV2(Database db) async {
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
        UNIQUE(id_hoc_sinh, id_lop, tu_ngay)
      )
    ''');

    await db.execute('''
      CREATE UNIQUE INDEX idx_tham_gia_lop_open_interval 
      ON tham_gia_lop(id_hoc_sinh, id_lop) 
      WHERE den_ngay IS NULL
    ''');

    await db.execute('CREATE INDEX idx_lop_da_luu_tru ON lop(da_luu_tru)');
    await db.execute('CREATE INDEX idx_tham_gia_lop_hoc_sinh ON tham_gia_lop(id_hoc_sinh)');
    await db.execute('CREATE INDEX idx_tham_gia_lop_lop ON tham_gia_lop(id_lop)');
  }
}
