import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tuition2027/core/database/app_database.dart';
import 'package:tuition2027/features/settings/data/school_repository.dart';
import 'package:tuition2027/features/settings/domain/school_catalog_service.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  test(
    'v15 upgrade preserves student school and catalog prevents duplicates',
    () async {
      final directory = await Directory.systemTemp.createTemp('school_catalog');
      final path = join(directory.path, 'tuition.db');
      final old = await openDatabase(
        path,
        version: 15,
        onCreate: (db, _) async {
          await db.execute(
            'CREATE TABLE hoc_sinh(id INTEGER PRIMARY KEY, truong_dang_hoc TEXT)',
          );
          await db.insert('hoc_sinh', {
            'id': 1,
            'truong_dang_hoc': 'THCS Nguyễn Du',
          });
        },
      );
      await old.close();
      final database = await AppDatabase(dbName: path).database;
      final catalog = SchoolCatalogService(SchoolRepository(database));
      expect(await database.getVersion(), AppDatabase.schemaVersion);
      expect(await catalog.list(), ['THCS Nguyễn Du']);
      await catalog.add(' THPT Lê Quý Đôn ');
      expect(await catalog.list(), contains('THPT Lê Quý Đôn'));
      await expectLater(
        catalog.add('thpt lê quý đôn'),
        throwsA(isA<DatabaseException>()),
      );
      expect(
        (await database.query('hoc_sinh')).single['truong_dang_hoc'],
        'THCS Nguyễn Du',
      );
      await database.close();
      await directory.delete(recursive: true);
    },
  );
}
