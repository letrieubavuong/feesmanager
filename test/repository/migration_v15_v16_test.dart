import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tuition2027/core/database/app_database.dart';
import 'package:tuition2027/features/settings/data/school_repository.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  test(
    'v15 to v16 preserves student schools and supports archived catalog entries',
    () async {
      final temp = await Directory.systemTemp.createTemp('schools_v16');
      final path = join(temp.path, 'test.db');
      try {
        final old = await openDatabase(
          path,
          version: 15,
          onCreate: (db, _) async {
            await db.execute('''
            CREATE TABLE hoc_sinh (
              id INTEGER PRIMARY KEY,
              truong_dang_hoc TEXT NULL
            )
          ''');
            await db.insert('hoc_sinh', {
              'id': 1,
              'truong_dang_hoc': 'THCS Nguyễn Du',
            });
            await db.insert('hoc_sinh', {
              'id': 2,
              'truong_dang_hoc': ' THCS Nguyễn Du ',
            });
          },
        );
        await old.close();

        final db = await AppDatabase(dbName: path).database;
        expect(await db.getVersion(), 16);
        final repository = SchoolRepository(db);
        expect((await repository.listActive()).map((s) => s.name).toList(), [
          'THCS Nguyễn Du',
        ]);
        await repository.archive((await repository.listActive()).single.id);
        expect(await repository.listActive(), isEmpty);
        await repository.add('thcs nguyễn du');
        expect((await repository.listActive()).single.name, 'THCS Nguyễn Du');
        final students = await db.query('hoc_sinh', orderBy: 'id');
        expect(students[0]['truong_dang_hoc'], 'THCS Nguyễn Du');
        expect(students[1]['truong_dang_hoc'], ' THCS Nguyễn Du ');
        await db.close();
      } finally {
        await temp.delete(recursive: true);
      }
    },
  );
}
