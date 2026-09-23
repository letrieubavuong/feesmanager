import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class TestDbHelper {
  static Future<Database> createLatest() async {
    final db = await openDatabase(
      inMemoryDatabasePath,
      version: 5,
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
          UNIQUE(id_hoc_sinh, id_lop, tu_ngay),
          CHECK (den_ngay IS NULL OR den_ngay >= tu_ngay),
          CHECK (mien_giam_phan_tram BETWEEN 0 AND 100)
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
          UNIQUE(id_hoc_sinh, id_lich_hoc, tu_ngay),
          CHECK (den_ngay IS NULL OR den_ngay >= tu_ngay)
        )
      ''');

        await db.execute('''
        CREATE TABLE buoi_hoc (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          id_lop INTEGER NOT NULL,
          ngay TEXT NOT NULL,
          thu_trong_tuan INTEGER NOT NULL,
          gio_bat_dau TEXT NOT NULL,
          gio_ket_thuc TEXT NOT NULL,
          loai TEXT NOT NULL DEFAULT 'CHINH',
          trang_thai TEXT NOT NULL DEFAULT 'DU_KIEN',
          ghi_chu TEXT NULL,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          FOREIGN KEY (id_lop) REFERENCES lop (id)
        )
      ''');

        await db.execute('''
        CREATE TABLE dieu_chinh_buoi_hoc (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          id_hoc_sinh INTEGER NOT NULL,
          id_buoi_hoc_goc INTEGER NULL,
          id_buoi_hoc_dich INTEGER NOT NULL,
          loai TEXT NOT NULL,
          ly_do TEXT NULL,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          FOREIGN KEY (id_hoc_sinh) REFERENCES hoc_sinh (id),
          FOREIGN KEY (id_buoi_hoc_goc) REFERENCES buoi_hoc (id),
          FOREIGN KEY (id_buoi_hoc_dich) REFERENCES buoi_hoc (id)
        )
      ''');

        await db.execute('''
        CREATE TABLE rang_buoc_lich_hoc_sinh (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          id_hoc_sinh INTEGER NOT NULL,
          loai TEXT NOT NULL,
          kieu TEXT NOT NULL,
          thu_trong_tuan INTEGER NULL,
          ngay_cu_the TEXT NULL,
          gio_bat_dau TEXT NOT NULL,
          gio_ket_thuc TEXT NOT NULL,
          hieu_luc_tu TEXT NULL,
          hieu_luc_den TEXT NULL,
          travel_buffer_phut INTEGER NOT NULL DEFAULT 0,
          ten_nguon TEXT NULL,
          ghi_chu TEXT NULL,
          trang_thai TEXT NOT NULL DEFAULT 'HOAT_DONG',
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          FOREIGN KEY (id_hoc_sinh) REFERENCES hoc_sinh (id) ON DELETE RESTRICT
        )
      ''');
      },
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
    return db;
  }
}
