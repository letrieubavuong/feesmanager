import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tuition2027/features/memberships/data/membership_repository.dart';
import 'package:tuition2027/features/memberships/domain/membership_service.dart';
import 'package:tuition2027/features/students/data/student_repository.dart';
import 'package:tuition2027/features/students/domain/student.dart';
import 'package:tuition2027/features/classes/data/class_repository.dart';
import 'package:tuition2027/features/classes/domain/class.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database db;
  late MembershipService service;
  late StudentRepository studentRepo;
  late ClassRepository classRepo;

  setUp(() async {
    db = await openDatabase(
      inMemoryDatabasePath,
      version: 2,
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
          UNIQUE(id_hoc_sinh, id_lop, tu_ngay)
        )
      ''');
        await db.execute('''
        CREATE UNIQUE INDEX idx_tham_gia_lop_open_interval 
        ON tham_gia_lop(id_hoc_sinh, id_lop) 
        WHERE den_ngay IS NULL
      ''');
      },
    );

    studentRepo = StudentRepository(db);
    classRepo = ClassRepository(db);
    final membershipRepo = MembershipRepository(db);
    service = MembershipService(membershipRepo);
  });

  tearDown(() async {
    await db.close();
  });

  group('Membership Logic', () {
    test('enroll and class size', () async {
      final sId = await studentRepo.create(
        Student(
          hoTen: 'An',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      final cId = await classRepo.create(
        ClassEntity(
          tenLop: 'Class A',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      await service.enrollStudent(
        studentId: sId,
        classId: cId,
        joinDate: DateTime(2026, 9, 1),
      );

      expect(await service.getClassSize(cId, date: DateTime(2026, 8, 31)), 0);
      expect(await service.getClassSize(cId, date: DateTime(2026, 9, 1)), 1);
      expect(await service.getClassSize(cId, date: DateTime(2026, 9, 20)), 1);
    });

    test('pause and resume', () async {
      final sId = await studentRepo.create(
        Student(
          hoTen: 'An',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      final cId = await classRepo.create(
        ClassEntity(
          tenLop: 'Class A',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      // Enroll
      await service.enrollStudent(
        studentId: sId,
        classId: cId,
        joinDate: DateTime(2026, 9, 1),
      );

      // Pause from 16/10 (last day active is 15/10)
      await service.leaveClass(
        studentId: sId,
        classId: cId,
        endDate: DateTime(2026, 10, 15),
      );

      expect(await service.getClassSize(cId, date: DateTime(2026, 10, 15)), 1);
      expect(await service.getClassSize(cId, date: DateTime(2026, 10, 16)), 0);

      // Resume from 20/10
      await service.enrollStudent(
        studentId: sId,
        classId: cId,
        joinDate: DateTime(2026, 10, 20),
      );

      expect(await service.getClassSize(cId, date: DateTime(2026, 10, 19)), 0);
      expect(await service.getClassSize(cId, date: DateTime(2026, 10, 20)), 1);

      final history = await service.getMembershipHistory(sId);
      expect(history.length, 2);
    });

    test('prevent duplicate open membership', () async {
      final sId = await studentRepo.create(
        Student(
          hoTen: 'An',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      final cId = await classRepo.create(
        ClassEntity(
          tenLop: 'Class A',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      await service.enrollStudent(
        studentId: sId,
        classId: cId,
        joinDate: DateTime(2026, 9, 1),
      );

      expect(
        () => service.enrollStudent(
          studentId: sId,
          classId: cId,
          joinDate: DateTime(2026, 10, 1),
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('rejoin after leaving', () async {
      final sId = await studentRepo.create(
        Student(
          hoTen: 'An',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      final cId = await classRepo.create(
        ClassEntity(
          tenLop: 'Class A',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      await service.enrollStudent(
        studentId: sId,
        classId: cId,
        joinDate: DateTime(2026, 1, 1),
      );
      await service.leaveClass(
        studentId: sId,
        classId: cId,
        endDate: DateTime(2026, 3, 31),
      );

      await service.enrollStudent(
        studentId: sId,
        classId: cId,
        joinDate: DateTime(2026, 6, 1),
      );

      final history = await service.getMembershipHistory(sId);
      expect(history.length, 2);
    });
  });
}
