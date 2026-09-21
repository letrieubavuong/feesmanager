import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tuition2027/features/students/data/student_repository.dart';
import 'package:tuition2027/features/students/domain/student.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database db;
  late StudentRepository repository;

  setUp(() async {
    db = await openDatabase(inMemoryDatabasePath, version: 1,
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
    });
    repository = StudentRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('StudentRepository', () {
    final testStudent = Student(
      hoTen: 'Nguyen Van A',
      tenPhuHuynh: 'Nguyen Van B',
      sdtPhuHuynh: '0905123456',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    test('create and getById', () async {
      final id = await repository.create(testStudent);
      final student = await repository.getById(id);

      expect(student, isNotNull);
      expect(student!.hoTen, 'Nguyen Van A');
      expect(student.id, id);
    });

    test('update student', () async {
      final id = await repository.create(testStudent);
      final student = (await repository.getById(id))!;
      
      final updatedStudent = student.copyWith(hoTen: 'Nguyen Van C');
      await repository.update(updatedStudent);

      final result = await repository.getById(id);
      expect(result!.hoTen, 'Nguyen Van C');
    });

    test('archive and restore', () async {
      final id = await repository.create(testStudent);
      
      await repository.setArchiveStatus(id, true);
      var activeStudents = await repository.getAll();
      expect(activeStudents.length, 0);

      var allStudents = await repository.getAll(includeArchived: true);
      expect(allStudents.length, 1);
      expect(allStudents.first.daLuuTru, true);

      await repository.setArchiveStatus(id, false);
      activeStudents = await repository.getAll();
      expect(activeStudents.length, 1);
    });

    test('search students', () async {
      await repository.create(testStudent);
      await repository.create(testStudent.copyWith(hoTen: 'Tran Van B', sdtPhuHuynh: '0905999999'));

      final searchByName = await repository.search('Nguyen');
      expect(searchByName.length, 1);
      expect(searchByName.first.hoTen, 'Nguyen Van A');

      final searchByPhone = await repository.search('0905999');
      expect(searchByPhone.length, 1);
      expect(searchByPhone.first.hoTen, 'Tran Van B');
    });

    test('sibling same phone should work', () async {
      await repository.create(testStudent.copyWith(hoTen: 'An'));
      await repository.create(testStudent.copyWith(hoTen: 'Binh'));

      final students = await repository.getAll();
      expect(students.length, 2);
    });
  });
}
