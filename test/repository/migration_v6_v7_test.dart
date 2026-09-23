import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:tuition2027/core/database/app_database.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('AppDatabase Migration v6 to v7', () {
    late String dbPath;

    setUp(() async {
      final tempDir = await Directory.systemTemp.createTemp(
        'migration_test_v6_v7',
      );
      dbPath = join(tempDir.path, 'test_migration_v6_v7.db');
    });

    test('Migration v6 to v7 preserves canonical Phase 0-5 data', () async {
      final dbV6 = await openDatabase(
        dbPath,
        version: 6,
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
        },
        onConfigure: (db) async => await db.execute('PRAGMA foreign_keys = ON'),
      );

      await dbV6.insert('hoc_sinh', {
        'id': 11,
        'ho_ten': 'Student 11',
        'created_at': '2026-01-01',
        'updated_at': '2026-01-01',
      });
      await dbV6.insert('lop', {
        'id': 21,
        'ten_lop': 'Class 21',
        'created_at': '2026-01-01',
        'updated_at': '2026-01-01',
      });
      await dbV6.insert('tham_gia_lop', {
        'id': 31,
        'id_hoc_sinh': 11,
        'id_lop': 21,
        'tu_ngay': '2026-09-01',
        'created_at': '2026-01-01',
        'updated_at': '2026-01-01',
      });
      await dbV6.insert('lich_hoc', {
        'id': 41,
        'id_lop': 21,
        'thu_trong_tuan': 1,
        'gio_bat_dau': '17:30',
        'gio_ket_thuc': '19:00',
        'hieu_luc_tu': '2026-09-01',
        'created_at': '2026-01-01',
        'updated_at': '2026-01-01',
      });
      await dbV6.insert('phan_ca_hoc_sinh', {
        'id': 51,
        'id_hoc_sinh': 11,
        'id_lop': 21,
        'id_lich_hoc': 41,
        'tu_ngay': '2026-09-01',
        'created_at': '2026-01-01',
        'updated_at': '2026-01-01',
      });
      await dbV6.insert('buoi_hoc', {
        'id': 61,
        'id_lop': 21,
        'id_lich_hoc': 41,
        'ngay': '2026-09-21',
        'gio_bat_dau': '17:30',
        'gio_ket_thuc': '19:00',
        'loai': 'CHINH',
        'created_at': '2026-01-01',
        'updated_at': '2026-01-01',
      });
      await dbV6.close();

      final appDb = AppDatabase(dbName: dbPath);
      final dbV7 = await appDb.database;

      expect(await dbV7.getVersion(), 13);

      // Assert ALL rows survive
      final hs = await dbV7.query('hoc_sinh', where: 'id = 11');
      expect(hs.first['ho_ten'], 'Student 11');

      final cls = await dbV7.query('lop', where: 'id = 21');
      expect(cls.first['ten_lop'], 'Class 21');

      final tgl = await dbV7.query('tham_gia_lop', where: 'id = 31');
      expect(tgl.first['id_hoc_sinh'], 11);
      expect(tgl.first['id_lop'], 21);
      expect(tgl.first['tu_ngay'], '2026-09-01');

      final lh = await dbV7.query('lich_hoc', where: 'id = 41');
      expect(lh.first['id_lop'], 21);
      expect(lh.first['thu_trong_tuan'], 1);
      expect(lh.first['gio_bat_dau'], '17:30');
      expect(lh.first['gio_ket_thuc'], '19:00');
      expect(lh.first['hieu_luc_tu'], '2026-09-01');

      final pc = await dbV7.query('phan_ca_hoc_sinh', where: 'id = 51');
      expect(pc.first['id_hoc_sinh'], 11);
      expect(pc.first['id_lop'], 21);
      expect(pc.first['id_lich_hoc'], 41);
      expect(pc.first['tu_ngay'], '2026-09-01');

      final buoi = await dbV7.query('buoi_hoc', where: 'id = 61');
      expect(buoi.first['id_lop'], 21);
      expect(buoi.first['id_lich_hoc'], 41);
      expect(buoi.first['ngay'], '2026-09-21');
      expect(buoi.first['gio_bat_dau'], '17:30');
      expect(buoi.first['gio_ket_thuc'], '19:00');
      expect(buoi.first['loai'], 'CHINH');

      final fkList = await dbV7.rawQuery("PRAGMA foreign_key_list(diem_danh)");
      final fks = fkList
          .map((f) => {'from': f['from'], 'table': f['table']})
          .toList();

      expect(
        fks.any((f) => f['from'] == 'id_buoi_hoc' && f['table'] == 'buoi_hoc'),
        isTrue,
      );
      expect(
        fks.any((f) => f['from'] == 'id_hoc_sinh' && f['table'] == 'hoc_sinh'),
        isTrue,
      );
      expect(
        fks.any((f) => f['from'] == 'id_lop_goc' && f['table'] == 'lop'),
        isTrue,
      );
      expect(
        fks.any(
          (f) => f['from'] == 'id_buoi_vang_goc' && f['table'] == 'buoi_hoc',
        ),
        isTrue,
      );

      final violations = await dbV7.rawQuery('PRAGMA foreign_key_check');
      expect(violations, isEmpty);

      await dbV7.close();
    });

    test('Raw DB constraints and vocab regression', () async {
      final tempDbReg = join(
        Directory.systemTemp.path,
        'test_regression_v7.db',
      );
      await deleteDatabase(tempDbReg);

      final appDb = AppDatabase(dbName: tempDbReg);
      final db = await appDb.database;

      await db.execute(
        "INSERT INTO hoc_sinh (id, ho_ten, created_at, updated_at) VALUES (1, 'H', 'now', 'now')",
      );
      await db.execute(
        "INSERT INTO lop (id, ten_lop, created_at, updated_at) VALUES (1, 'L', 'now', 'now')",
      );
      await db.execute(
        "INSERT INTO buoi_hoc (id, id_lop, ngay, gio_bat_dau, gio_ket_thuc, loai, created_at, updated_at) VALUES (1, 1, '2026-09-21', '17:30', '19:00', 'CHINH', 'now', 'now')",
      );

      final validStatuses = [
        'CO_MAT',
        'TRE',
        'NGHI_CO_PHEP',
        'NGHI_KHONG_PHEP',
        'HOC_BU',
      ];
      for (int i = 0; i < validStatuses.length; i++) {
        final sId = i + 10;
        await db.execute(
          "INSERT INTO hoc_sinh (id, ho_ten, created_at, updated_at) VALUES (?, 'S', 'now', 'now')",
          [sId],
        );
        await db.execute(
          '''
          INSERT INTO diem_danh (id_buoi_hoc, id_hoc_sinh, id_lop_goc, trang_thai, loai_tham_gia, created_at, updated_at)
          VALUES (1, ?, 1, ?, 'CHINH', 'now', 'now')
        ''',
          [sId, validStatuses[i]],
        );

        final row = await db.query(
          'diem_danh',
          where: 'id_hoc_sinh = ?',
          whereArgs: [sId],
        );
        expect(row.first['trang_thai'], validStatuses[i]);
      }

      // Explicitly reject invalid statuses
      final invalidStatuses = ['ABC', 'PRESENT', 'CHUA_DIEM_DANH'];
      for (int i = 0; i < invalidStatuses.length; i++) {
        final sId = i + 50;
        await db.execute(
          "INSERT INTO hoc_sinh (id, ho_ten, created_at, updated_at) VALUES (?, 'Inv', 'now', 'now')",
          [sId],
        );
        expect(
          () => db.execute(
            '''
            INSERT INTO diem_danh (id_buoi_hoc, id_hoc_sinh, id_lop_goc, trang_thai, created_at, updated_at)
            VALUES (1, ?, 1, ?, 'now', 'now')
          ''',
            [sId, invalidStatuses[i]],
          ),
          throwsA(isA<DatabaseException>()),
        );
      }

      // Unique constraint
      expect(
        () => db.execute('''
        INSERT INTO diem_danh (id_buoi_hoc, id_hoc_sinh, id_lop_goc, trang_thai, loai_tham_gia, created_at, updated_at)
        VALUES (1, 10, 1, 'TRE', 'CHINH', 'now', 'now')
      '''),
        throwsA(isA<DatabaseException>()),
      );

      // Foreign Keys
      expect(
        () => db.execute('''
        INSERT INTO diem_danh (id_buoi_hoc, id_hoc_sinh, id_lop_goc, trang_thai, loai_tham_gia, created_at, updated_at)
        VALUES (999, 1, 1, 'CO_MAT', 'CHINH', 'now', 'now')
      '''),
        throwsA(isA<DatabaseException>()),
      );

      expect(
        () => db.execute('''
        INSERT INTO diem_danh (id_buoi_hoc, id_hoc_sinh, id_lop_goc, trang_thai, loai_tham_gia, created_at, updated_at)
        VALUES (1, 999, 1, 'CO_MAT', 'CHINH', 'now', 'now')
      '''),
        throwsA(isA<DatabaseException>()),
      );

      expect(
        () => db.execute('''
        INSERT INTO diem_danh (id_buoi_hoc, id_hoc_sinh, id_lop_goc, trang_thai, loai_tham_gia, created_at, updated_at)
        VALUES (1, 1, 999, 'CO_MAT', 'CHINH', 'now', 'now')
      '''),
        throwsA(isA<DatabaseException>()),
      );

      expect(
        () => db.execute('''
        INSERT INTO diem_danh (id_buoi_hoc, id_hoc_sinh, id_lop_goc, id_buoi_vang_goc, trang_thai, loai_tham_gia, created_at, updated_at)
        VALUES (1, 1, 1, 999, 'CO_MAT', 'CHINH', 'now', 'now')
      '''),
        throwsA(isA<DatabaseException>()),
      );

      await db.execute(
        "INSERT INTO hoc_sinh (id, ho_ten, created_at, updated_at) VALUES (4, 'H4', 'now', 'now')",
      );
      await db.execute('''
        INSERT INTO diem_danh (id_buoi_hoc, id_hoc_sinh, id_lop_goc, id_buoi_vang_goc, trang_thai, loai_tham_gia, created_at, updated_at)
        VALUES (1, 4, 1, NULL, 'CO_MAT', 'CHINH', 'now', 'now')
      ''');

      // Participation types
      final validTypes = ['CHINH', 'DOI_CA', 'HOC_BU'];
      for (int i = 0; i < validTypes.length; i++) {
        final sId = i + 100;
        await db.execute(
          "INSERT INTO hoc_sinh (id, ho_ten, created_at, updated_at) VALUES (?, 'ST', 'now', 'now')",
          [sId],
        );
        await db.execute(
          '''
          INSERT INTO diem_danh (id_buoi_hoc, id_hoc_sinh, id_lop_goc, trang_thai, loai_tham_gia, created_at, updated_at)
          VALUES (1, ?, 1, 'CO_MAT', ?, 'now', 'now')
        ''',
          [sId, validTypes[i]],
        );
      }

      final invalidTypes = ['ABC', 'PHAT_SINH'];
      for (int i = 0; i < invalidTypes.length; i++) {
        final sId = i + 200;
        await db.execute(
          "INSERT INTO hoc_sinh (id, ho_ten, created_at, updated_at) VALUES (?, 'H', 'now', 'now')",
          [sId],
        );
        expect(
          () => db.execute(
            '''
            INSERT INTO diem_danh (id_buoi_hoc, id_hoc_sinh, id_lop_goc, trang_thai, loai_tham_gia, created_at, updated_at)
            VALUES (1, ?, 1, 'CO_MAT', ?, 'now', 'now')
          ''',
            [sId, invalidTypes[i]],
          ),
          throwsA(isA<DatabaseException>()),
        );
      }

      await db.close();
      await deleteDatabase(tempDbReg);
    });
  });
}
