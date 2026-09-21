import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tuition2027/features/students/domain/student_service.dart';
import 'package:tuition2027/features/students/data/student_repository.dart';
import 'package:tuition2027/features/students/domain/student.dart';
import 'package:tuition2027/features/memberships/domain/membership_service.dart';
import 'package:tuition2027/features/memberships/data/membership_repository.dart';
import 'package:tuition2027/features/classes/data/class_repository.dart';
import 'package:tuition2027/features/classes/domain/class.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database db;
  late StudentService studentService;
  late MembershipService membershipService;
  late ClassRepository classRepo;

  setUp(() async {
    db = await openDatabase(inMemoryDatabasePath, version: 2,
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
          FOREIGN KEY (id_lop) REFERENCES lop (id)
        )
      ''');
    });
    
    classRepo = ClassRepository(db);
    final studentRepo = StudentRepository(db);
    final membershipRepo = MembershipRepository(db);
    membershipService = MembershipService(membershipRepo);
    studentService = StudentService(studentRepo, membershipService);
  });

  tearDown(() async {
    await db.close();
  });

  group('Student Archive Blocking', () {
    test('should block archive if student has active membership', () async {
      await studentService.saveStudent(Student(hoTen: 'An', createdAt: DateTime.now(), updatedAt: DateTime.now()));
      final students = await studentService.getStudents();
      final id = students.first.id!;

      final cId = await classRepo.create(ClassEntity(tenLop: 'Class A', createdAt: DateTime.now(), updatedAt: DateTime.now()));

      await membershipService.enrollStudent(
        studentId: id, 
        classId: cId, 
        joinDate: DateTime.now().subtract(const Duration(days: 10)),
      );
      
      expect(
        studentService.archiveStudent(id),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('Học sinh vẫn đang thuộc các lớp'))),
      );

      // End membership (yesterday)
      await membershipService.leaveClass(
        studentId: id, 
        classId: cId, 
        endDate: DateTime.now().subtract(const Duration(days: 1)),
      );
      
      // Should now be allowed to archive
      await studentService.archiveStudent(id);
      final archived = await studentService.getStudents(includeArchived: true);
      expect(archived.first.daLuuTru, isTrue);
    });
  });
}
