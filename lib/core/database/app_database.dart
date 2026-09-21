import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class AppDatabase {
  static const String _defaultDbName = 'tuition_next.db';
  static const int _dbVersion = 5;

  final String dbName;
  Database? _database;

  AppDatabase({this.dbName = _defaultDbName});

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = isAbsolute(dbName)
        ? dbName
        : join(await getDatabasesPath(), dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: _onConfigure,
      onOpen: (db) async {
        // Essential for complex migrations that swap tables
        await db.execute('PRAGMA foreign_keys = ON');
      },
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
    if (version >= 3) {
      await _migrateV2ToV3(db);
    }
    if (version >= 4) {
      await _migrateV3ToV4(db);
    }
    if (version >= 5) {
      await _migrateV4ToV5(db);
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _migrateV1ToV2(db);
    }
    if (oldVersion < 3) {
      await _migrateV2ToV3(db);
    }
    if (oldVersion < 4) {
      await _migrateV3ToV4(db);
    }
    if (oldVersion < 5) {
      await _migrateV4ToV5(db);
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
    await db.execute(
      'CREATE INDEX idx_hoc_sinh_sdt_phu_huynh ON hoc_sinh(sdt_phu_huynh)',
    );
    await db.execute(
      'CREATE INDEX idx_hoc_sinh_da_luu_tru ON hoc_sinh(da_luu_tru)',
    );
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
    await db.execute(
      'CREATE INDEX idx_tham_gia_lop_hoc_sinh ON tham_gia_lop(id_hoc_sinh)',
    );
    await db.execute(
      'CREATE INDEX idx_tham_gia_lop_lop ON tham_gia_lop(id_lop)',
    );
  }

  Future<void> _migrateV2ToV3(Database db) async {
    // PRAGMA foreign_keys = OFF must be outside transaction to work in some SQLite versions/drivers
    await db.execute('PRAGMA foreign_keys = OFF');
    try {
      await db.transaction((txn) async {
        // 1. Create new table with constraints
        await txn.execute('''
        CREATE TABLE tham_gia_lop_new (
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
          UNIQUE(id_hoc_sinh, id_lop, tu_ngay),
          CHECK (den_ngay IS NULL OR den_ngay >= tu_ngay),
          CHECK (mien_giam_phan_tram BETWEEN 0 AND 100)
        )
      ''');

        // 2. Copy data
        await txn.execute('''
        INSERT INTO tham_gia_lop_new (
          id, id_hoc_sinh, id_lop, tu_ngay, den_ngay, 
          ly_do_ket_thuc, mien_giam_phan_tram, ghi_chu, 
          created_at, updated_at
        )
        SELECT 
          id, id_hoc_sinh, id_lop, tu_ngay, den_ngay, 
          ly_do_ket_thuc, mien_giam_phan_tram, ghi_chu, 
          created_at, updated_at
        FROM tham_gia_lop
      ''');

        // 3. Drop old table and rename
        await txn.execute('DROP TABLE tham_gia_lop');
        await txn.execute(
          'ALTER TABLE tham_gia_lop_new RENAME TO tham_gia_lop',
        );

        // 4. Recreate indexes
        await txn.execute('''
        CREATE UNIQUE INDEX idx_tham_gia_lop_open_interval 
        ON tham_gia_lop(id_hoc_sinh, id_lop) 
        WHERE den_ngay IS NULL
      ''');
        await txn.execute(
          'CREATE INDEX idx_tham_gia_lop_hoc_sinh ON tham_gia_lop(id_hoc_sinh)',
        );
        await txn.execute(
          'CREATE INDEX idx_tham_gia_lop_lop ON tham_gia_lop(id_lop)',
        );
      });
    } finally {
      await db.execute('PRAGMA foreign_keys = ON');
    }
  }

  Future<void> _migrateV3ToV4(Database db) async {
    await db.execute('''
      CREATE TABLE lich_hoc (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        id_lop INTEGER NOT NULL,
        thu_trong_tuan INTEGER NOT NULL,
        gio_bat_dau TEXT NOT NULL,
        gio_ket_thuc TEXT NOT NULL,
        hieu_luc_tu TEXT NOT NULL,
        hieu_luc_den TEXT NULL,
        ghi_chu TEXT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (id_lop) REFERENCES lop (id),
        CHECK (thu_trong_tuan BETWEEN 1 AND 7),
        CHECK (gio_ket_thuc > gio_bat_dau),
        CHECK (hieu_luc_den IS NULL OR hieu_luc_den >= hieu_luc_tu)
      )
    ''');

    await db.execute('''
      CREATE UNIQUE INDEX idx_lich_hoc_unique 
      ON lich_hoc(id_lop, thu_trong_tuan, gio_bat_dau, hieu_luc_tu)
    ''');

    await db.execute('''
      CREATE TABLE phan_ca_hoc_sinh (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        id_hoc_sinh INTEGER NOT NULL,
        id_lop INTEGER NOT NULL,
        id_lich_hoc INTEGER NOT NULL,
        tu_ngay TEXT NOT NULL,
        den_ngay TEXT NULL,
        nguon TEXT NULL,
        ghi_chu TEXT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (id_hoc_sinh) REFERENCES hoc_sinh (id),
        FOREIGN KEY (id_lop) REFERENCES lop (id),
        FOREIGN KEY (id_lich_hoc) REFERENCES lich_hoc (id),
        CHECK (den_ngay IS NULL OR den_ngay >= tu_ngay)
      )
    ''');

    await db.execute('CREATE INDEX idx_lich_hoc_lop ON lich_hoc(id_lop)');
    await db.execute('CREATE INDEX idx_phan_ca_hoc_sinh_hs ON phan_ca_hoc_sinh(id_hoc_sinh)');
    await db.execute('CREATE INDEX idx_phan_ca_hoc_sinh_lop ON phan_ca_hoc_sinh(id_lop)');
    await db.execute('CREATE INDEX idx_phan_ca_hoc_sinh_lich ON phan_ca_hoc_sinh(id_lich_hoc)');
  }

  Future<void> _migrateV4ToV5(Database db) async {
    await db.execute('PRAGMA foreign_keys = OFF');
    try {
      await db.transaction((txn) async {
        // 1. Create new table with UNIQUE constraint
        await txn.execute('''
          CREATE TABLE phan_ca_hoc_sinh_new (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            id_hoc_sinh INTEGER NOT NULL,
            id_lop INTEGER NOT NULL,
            id_lich_hoc INTEGER NOT NULL,
            tu_ngay TEXT NOT NULL,
            den_ngay TEXT NULL,
            nguon TEXT NULL,
            ghi_chu TEXT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            FOREIGN KEY (id_hoc_sinh) REFERENCES hoc_sinh (id),
            FOREIGN KEY (id_lop) REFERENCES lop (id),
            FOREIGN KEY (id_lich_hoc) REFERENCES lich_hoc (id),
            UNIQUE(id_hoc_sinh, id_lich_hoc, tu_ngay),
            CHECK (den_ngay IS NULL OR den_ngay >= tu_ngay)
          )
        ''');

        // 2. Copy data
        await txn.execute('''
          INSERT INTO phan_ca_hoc_sinh_new (
            id, id_hoc_sinh, id_lop, id_lich_hoc, tu_ngay, den_ngay,
            nguon, ghi_chu, created_at, updated_at
          )
          SELECT 
            id, id_hoc_sinh, id_lop, id_lich_hoc, tu_ngay, den_ngay,
            nguon, ghi_chu, created_at, updated_at
          FROM phan_ca_hoc_sinh
        ''');

        // 3. Drop old and rename
        await txn.execute('DROP TABLE phan_ca_hoc_sinh');
        await txn.execute('ALTER TABLE phan_ca_hoc_sinh_new RENAME TO phan_ca_hoc_sinh');

        // 4. Recreate indexes
        await txn.execute('CREATE INDEX idx_phan_ca_hoc_sinh_hs ON phan_ca_hoc_sinh(id_hoc_sinh)');
        await txn.execute('CREATE INDEX idx_phan_ca_hoc_sinh_lop ON phan_ca_hoc_sinh(id_lop)');
        await txn.execute('CREATE INDEX idx_phan_ca_hoc_sinh_lich ON phan_ca_hoc_sinh(id_lich_hoc)');
      });
    } finally {
      await db.execute('PRAGMA foreign_keys = ON');
    }
  }
}
