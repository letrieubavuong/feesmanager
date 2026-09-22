import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class AppDatabase {
  static const String _defaultDbName = 'tuition_next.db';
  static const int _dbVersion = 11;

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
    if (version >= 6) {
      await _migrateV5ToV6(db);
    }
    if (version >= 7) {
      await _migrateV6ToV7(db);
    }
    if (version >= 8) {
      await _migrateV7ToV8(db);
    }
    if (version >= 9) {
      await _migrateV8ToV9(db);
    }
    if (version >= 10) {
      await _migrateV9ToV10(db);
    }
    if (version >= 11) {
      await _migrateV10ToV11(db);
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
    if (oldVersion < 6) {
      await _migrateV5ToV6(db);
    }
    if (oldVersion < 7) {
      await _migrateV6ToV7(db);
    }
    if (oldVersion < 8) {
      await _migrateV7ToV8(db);
    }
    if (oldVersion < 9) {
      await _migrateV8ToV9(db);
    }
    if (oldVersion < 10) {
      await _migrateV9ToV10(db);
    }
    if (oldVersion < 11) {
      await _migrateV10ToV11(db);
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
    await db.execute(
      'CREATE INDEX idx_phan_ca_hoc_sinh_hs ON phan_ca_hoc_sinh(id_hoc_sinh)',
    );
    await db.execute(
      'CREATE INDEX idx_phan_ca_hoc_sinh_lop ON phan_ca_hoc_sinh(id_lop)',
    );
    await db.execute(
      'CREATE INDEX idx_phan_ca_hoc_sinh_lich ON phan_ca_hoc_sinh(id_lich_hoc)',
    );
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
        await txn.execute(
          'ALTER TABLE phan_ca_hoc_sinh_new RENAME TO phan_ca_hoc_sinh',
        );

        // 4. Recreate indexes
        await txn.execute(
          'CREATE INDEX idx_phan_ca_hoc_sinh_hs ON phan_ca_hoc_sinh(id_hoc_sinh)',
        );
        await txn.execute(
          'CREATE INDEX idx_phan_ca_hoc_sinh_lop ON phan_ca_hoc_sinh(id_lop)',
        );
        await txn.execute(
          'CREATE INDEX idx_phan_ca_hoc_sinh_lich ON phan_ca_hoc_sinh(id_lich_hoc)',
        );
      });
    } finally {
      await db.execute('PRAGMA foreign_keys = ON');
    }
  }

  Future<void> _migrateV5ToV6(Database db) async {
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
        FOREIGN KEY (id_lop) REFERENCES lop (id),
        FOREIGN KEY (id_lich_hoc) REFERENCES lich_hoc (id),
        CHECK (gio_ket_thuc > gio_bat_dau),
        CHECK (loai IN ('CHINH', 'HOC_BU', 'PHAT_SINH')),
        CHECK (trang_thai IN ('DU_KIEN', 'DA_HOC', 'HUY', 'NGHI_LE')),
        UNIQUE(id_lop, ngay, gio_bat_dau)
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_buoi_hoc_lop_ngay ON buoi_hoc(id_lop, ngay)',
    );
    await db.execute(
      'CREATE INDEX idx_buoi_hoc_lich_ngay ON buoi_hoc(id_lich_hoc, ngay)',
    );
  }

  Future<void> _migrateV6ToV7(Database db) async {
    await db.execute('''
      CREATE TABLE diem_danh (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        id_buoi_hoc INTEGER NOT NULL,
        id_hoc_sinh INTEGER NOT NULL,
        id_lop_goc INTEGER NOT NULL,
        trang_thai TEXT NOT NULL,
        loai_tham_gia TEXT NOT NULL DEFAULT 'CHINH',
        id_buoi_vang_goc INTEGER NULL,
        ghi_chu TEXT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (id_buoi_hoc) REFERENCES buoi_hoc (id),
        FOREIGN KEY (id_hoc_sinh) REFERENCES hoc_sinh (id),
        FOREIGN KEY (id_lop_goc) REFERENCES lop (id),
        FOREIGN KEY (id_buoi_vang_goc) REFERENCES buoi_hoc (id),
        UNIQUE(id_buoi_hoc, id_hoc_sinh),
        CHECK (trang_thai IN ('CO_MAT', 'TRE', 'NGHI_CO_PHEP', 'NGHI_KHONG_PHEP', 'HOC_BU')),
        CHECK (loai_tham_gia IN ('CHINH', 'DOI_CA', 'HOC_BU'))
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_diem_danh_buoi_hoc ON diem_danh(id_buoi_hoc)',
    );
    await db.execute(
      'CREATE INDEX idx_diem_danh_hoc_sinh ON diem_danh(id_hoc_sinh)',
    );
    await db.execute(
      'CREATE INDEX idx_diem_danh_hs_buoi ON diem_danh(id_hoc_sinh, id_buoi_hoc)',
    );
  }

  Future<void> _migrateV7ToV8(Database db) async {
    await db.execute('''
      CREATE TABLE don_nghi_hoc (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        id_hoc_sinh INTEGER NOT NULL,
        id_lop INTEGER NOT NULL,
        tu_ngay TEXT NOT NULL,
        den_ngay TEXT NOT NULL,
        ly_do TEXT NULL,
        trang_thai TEXT NOT NULL DEFAULT 'CHO_DUYET',
        ghi_chu TEXT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (id_hoc_sinh) REFERENCES hoc_sinh (id),
        FOREIGN KEY (id_lop) REFERENCES lop (id),
        CHECK (den_ngay >= tu_ngay),
        CHECK (trang_thai IN ('CHO_DUYET', 'DA_DUYET', 'TU_CHOI'))
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_don_nghi_hoc_hs_dates ON don_nghi_hoc(id_hoc_sinh, tu_ngay, den_ngay)',
    );
    await db.execute(
      'CREATE INDEX idx_don_nghi_hoc_lop_dates ON don_nghi_hoc(id_lop, tu_ngay, den_ngay)',
    );
    await db.execute(
      'CREATE INDEX idx_don_nghi_hoc_trang_thai ON don_nghi_hoc(trang_thai)',
    );

    await db.execute('''
      CREATE TABLE dieu_chinh_buoi_hoc (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        id_hoc_sinh INTEGER NOT NULL,
        id_lop_goc INTEGER NOT NULL,
        id_buoi_hoc_goc INTEGER NULL,
        id_buoi_hoc_tham_gia INTEGER NOT NULL,
        loai TEXT NOT NULL,
        ly_do TEXT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (id_hoc_sinh) REFERENCES hoc_sinh (id),
        FOREIGN KEY (id_lop_goc) REFERENCES lop (id),
        FOREIGN KEY (id_buoi_hoc_goc) REFERENCES buoi_hoc (id),
        FOREIGN KEY (id_buoi_hoc_tham_gia) REFERENCES buoi_hoc (id),
        CHECK (loai IN ('DOI_CA', 'HOC_BU', 'PHAT_SINH')),
        CHECK (id_buoi_hoc_goc IS NULL OR id_buoi_hoc_goc != id_buoi_hoc_tham_gia),
        CHECK (loai = 'PHAT_SINH' OR id_buoi_hoc_goc IS NOT NULL),
        UNIQUE (id_hoc_sinh, id_buoi_hoc_tham_gia)
      )
    ''');

    await db.execute('''
      CREATE UNIQUE INDEX idx_dieu_chinh_doi_ca_unique 
      ON dieu_chinh_buoi_hoc(id_hoc_sinh, id_buoi_hoc_goc) 
      WHERE loai = 'DOI_CA' AND id_buoi_hoc_goc IS NOT NULL
    ''');

    await db.execute(
      'CREATE INDEX idx_dieu_chinh_tham_gia ON dieu_chinh_buoi_hoc(id_buoi_hoc_tham_gia)',
    );
    await db.execute(
      'CREATE INDEX idx_dieu_chinh_goc ON dieu_chinh_buoi_hoc(id_buoi_hoc_goc)',
    );
    await db.execute(
      'CREATE INDEX idx_dieu_chinh_hs ON dieu_chinh_buoi_hoc(id_hoc_sinh)',
    );
    await db.execute(
      'CREATE INDEX idx_dieu_chinh_lop_goc ON dieu_chinh_buoi_hoc(id_lop_goc)',
    );
  }

  Future<void> _migrateV8ToV9(Database db) async {
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
        FOREIGN KEY (id_buoi_hoc) REFERENCES buoi_hoc (id),
        CHECK (delta != 0),
        CHECK (ly_do IN ('VUOT_SO_BUOI_CHUAN', 'BU_TRU_NGHI_CO_PHEP', 'DIEU_CHINH_THU_CONG', 'MIGRATION'))
      )
    ''');

    await db.execute('''
      CREATE UNIQUE INDEX idx_buoi_du_auto_event_unique
      ON buoi_du_ledger(id_hoc_sinh, id_lop, id_buoi_hoc, ly_do)
      WHERE id_buoi_hoc IS NOT NULL AND ly_do IN ('VUOT_SO_BUOI_CHUAN', 'BU_TRU_NGHI_CO_PHEP')
    ''');

    await db.execute(
      'CREATE INDEX idx_buoi_du_student_class_date ON buoi_du_ledger(id_hoc_sinh, id_lop, ngay_hieu_luc)',
    );
    await db.execute(
      'CREATE INDEX idx_buoi_du_class_date ON buoi_du_ledger(id_lop, ngay_hieu_luc)',
    );
    await db.execute(
      'CREATE INDEX idx_buoi_du_session ON buoi_du_ledger(id_buoi_hoc)',
    );
  }

  Future<void> _migrateV9ToV10(Database db) async {
    await db.execute('PRAGMA foreign_keys = OFF');
    try {
      await db.transaction((txn) async {
        // 1. Create new table with hardened reason-specific CHECK constraints
        await txn.execute('''
          CREATE TABLE buoi_du_ledger_new (
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
            FOREIGN KEY (id_buoi_hoc) REFERENCES buoi_hoc (id),
            CHECK (delta != 0),
            CHECK (
              ly_do IN (
                'VUOT_SO_BUOI_CHUAN',
                'BU_TRU_NGHI_CO_PHEP',
                'DIEU_CHINH_THU_CONG',
                'MIGRATION'
              )
            ),
            CHECK (
                 (
                   ly_do = 'VUOT_SO_BUOI_CHUAN'
                   AND id_buoi_hoc IS NOT NULL
                   AND delta = 1
                 )
              OR (
                   ly_do = 'BU_TRU_NGHI_CO_PHEP'
                   AND id_buoi_hoc IS NOT NULL
                   AND delta = -1
                 )
              OR (
                   ly_do = 'DIEU_CHINH_THU_CONG'
                   AND delta != 0
                 )
              OR (
                   ly_do = 'MIGRATION'
                   AND delta != 0
                 )
            )
          )
        ''');

        // 2. Copy existing valid data
        await txn.execute('''
          INSERT INTO buoi_du_ledger_new (
            id, id_hoc_sinh, id_lop, id_buoi_hoc, ngay_hieu_luc,
            delta, ly_do, ghi_chu, created_at
          )
          SELECT 
            id, id_hoc_sinh, id_lop, id_buoi_hoc, ngay_hieu_luc,
            delta, ly_do, ghi_chu, created_at
          FROM buoi_du_ledger
        ''');

        // 3. Drop old table and rename new
        await txn.execute('DROP TABLE buoi_du_ledger');
        await txn.execute(
          'ALTER TABLE buoi_du_ledger_new RENAME TO buoi_du_ledger',
        );

        // 4. Recreate indexes
        await txn.execute('''
          CREATE UNIQUE INDEX idx_buoi_du_auto_event_unique
          ON buoi_du_ledger(id_hoc_sinh, id_lop, id_buoi_hoc, ly_do)
          WHERE id_buoi_hoc IS NOT NULL AND ly_do IN ('VUOT_SO_BUOI_CHUAN', 'BU_TRU_NGHI_CO_PHEP')
        ''');
        await txn.execute(
          'CREATE INDEX idx_buoi_du_student_class_date ON buoi_du_ledger(id_hoc_sinh, id_lop, ngay_hieu_luc)',
        );
        await txn.execute(
          'CREATE INDEX idx_buoi_du_class_date ON buoi_du_ledger(id_lop, ngay_hieu_luc)',
        );
        await txn.execute(
          'CREATE INDEX idx_buoi_du_session ON buoi_du_ledger(id_buoi_hoc)',
        );
      });
    } finally {
      await db.execute('PRAGMA foreign_keys = ON');
    }
  }

  Future<void> _migrateV10ToV11(Database db) async {
    // 1. Create table chinh_sach_hoc_phi
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
        FOREIGN KEY (id_lop) REFERENCES lop (id),
        UNIQUE (id_lop, hieu_luc_tu),
        CHECK (so_buoi_chuan_thang > 0),
        CHECK (hoc_phi_moi_buoi >= 0),
        CHECK (hoc_phi_thang_toi_da IS NULL OR hoc_phi_thang_toi_da >= 0),
        CHECK (hieu_luc_den IS NULL OR hieu_luc_den >= hieu_luc_tu)
      )
    ''');

    await db.execute('''
      CREATE UNIQUE INDEX idx_chinh_sach_open_interval 
      ON chinh_sach_hoc_phi(id_lop) 
      WHERE hieu_luc_den IS NULL
    ''');

    await db.execute(
      'CREATE INDEX idx_chinh_sach_lop_dates ON chinh_sach_hoc_phi(id_lop, hieu_luc_tu, hieu_luc_den)',
    );

    // 2. Create table hoc_phi_thang
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
        FOREIGN KEY (id_chinh_sach_hoc_phi) REFERENCES chinh_sach_hoc_phi (id),
        UNIQUE (id_hoc_sinh, id_lop, thang),
        CHECK (so_buoi_eligible >= 0),
        CHECK (so_buoi_tinh_phi >= 0),
        CHECK (giam_phan_tram BETWEEN 0 AND 100),
        CHECK (giam_so_tien >= 0),
        CHECK (so_tien_phai_thu >= 0),
        CHECK (trang_thai IN ('NHAP', 'DA_CHOT', 'DA_THANH_TOAN', 'CON_NO'))
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_hoc_phi_thang_student_class ON hoc_phi_thang(id_hoc_sinh, id_lop, thang)',
    );
    await db.execute(
      'CREATE INDEX idx_hoc_phi_thang_class_month ON hoc_phi_thang(id_lop, thang)',
    );
    await db.execute(
      'CREATE INDEX idx_hoc_phi_thang_status ON hoc_phi_thang(trang_thai)',
    );
  }
}
