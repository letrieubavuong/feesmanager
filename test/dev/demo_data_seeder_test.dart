// test/dev/demo_data_seeder_test.dart

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tuition2027/core/database/app_database.dart';
import 'package:tuition2027/dev/demo_data_seeder.dart';
import 'package:tuition2027/features/attendance/data/attendance_repository.dart';
import 'package:tuition2027/features/attendance/domain/attendance_service.dart';
import 'package:tuition2027/features/classes/data/class_repository.dart';
import 'package:tuition2027/features/classes/domain/class_service.dart';
import 'package:tuition2027/features/leave/data/leave_request_repository.dart';
import 'package:tuition2027/features/leave/domain/leave_request_service.dart';
import 'package:tuition2027/features/memberships/data/membership_repository.dart';
import 'package:tuition2027/features/memberships/domain/membership_service.dart';
import 'package:tuition2027/features/payments/data/payment_repository.dart';
import 'package:tuition2027/features/payments/domain/payment_service.dart';
import 'package:tuition2027/features/roster/domain/roster_service.dart';
import 'package:tuition2027/features/schedule/data/assignment_repository.dart';
import 'package:tuition2027/features/schedule/data/schedule_repository.dart';
import 'package:tuition2027/features/schedule/domain/schedule_service.dart';
import 'package:tuition2027/features/schedule_conflicts/data/schedule_constraint_repository.dart';
import 'package:tuition2027/features/schedule_conflicts/domain/schedule_conflict_service.dart';
import 'package:tuition2027/features/session_adjustments/data/session_adjustment_repository.dart';
import 'package:tuition2027/features/session_credits/data/session_credit_repository.dart';
import 'package:tuition2027/features/session_credits/domain/session_credit_service.dart';
import 'package:tuition2027/features/sessions/data/session_repository.dart';
import 'package:tuition2027/features/sessions/domain/session_generation_service.dart';
import 'package:tuition2027/features/sessions/domain/session_service.dart';
import 'package:tuition2027/features/students/data/student_repository.dart';
import 'package:tuition2027/features/students/domain/student_service.dart';
import 'package:tuition2027/features/tuition/data/tuition_policy_repository.dart';
import 'package:tuition2027/features/tuition/data/tuition_repository.dart';
import 'package:tuition2027/features/tuition/domain/invoice_service.dart';
import 'package:tuition2027/features/tuition/domain/tuition_policy_service.dart';
import 'package:tuition2027/features/tuition/domain/tuition_service.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late String dbPath;
  late AppDatabase appDb;
  late Database db;
  late DemoDataSeeder seeder;

  setUp(() async {
    final tempDir = await Directory.systemTemp.createTemp('demo_seeder_test');
    dbPath = join(tempDir.path, 'demo_seeder.db');
    appDb = AppDatabase(dbName: dbPath);
    db = await appDb.database;

    final classRepo = ClassRepository(db);
    final membershipRepo = MembershipRepository(db);
    final studentRepo = StudentRepository(db);
    final scheduleRepo = ScheduleRepository(db);
    final assignmentRepo = AssignmentRepository(db);
    final sessionRepo = SessionRepository(db);
    final attendanceRepo = AttendanceRepository(db);
    final leaveRepo = LeaveRequestRepository(db);
    final tuitionPolicyRepo = TuitionPolicyRepository(db);
    final tuitionRepo = TuitionRepository(db);
    final creditRepo = SessionCreditRepository(db);
    final paymentRepo = PaymentRepository(db);
    final adjRepo = SessionAdjustmentRepository(db);
    final constraintRepo = ScheduleConstraintRepository(db);

    final membershipService = MembershipService(membershipRepo);
    final classService = ClassService(classRepo, membershipService);
    final studentService = StudentService(studentRepo, membershipService);
    final tuitionPolicyService = TuitionPolicyService(
      tuitionPolicyRepo,
      classService,
      tuitionRepo,
      creditRepo,
      db,
    );

    final conflictService = ScheduleConflictService(
      constraintRepo,
      scheduleRepo,
      assignmentRepo,
      sessionRepo,
      adjRepo,
      classService,
    );
    final scheduleService = ScheduleDomainService(
      scheduleRepo,
      assignmentRepo,
      membershipService,
      classService,
      studentService,
      conflictService,
    );
    final sessionService = SessionService(sessionRepo, classService);
    final sessionGenService = SessionGenerationService(
      sessionRepo,
      scheduleService,
      classService,
    );
    final rosterService = RosterService(
      sessionService,
      membershipService,
      scheduleService,
      studentService,
      adjRepo,
    );
    final leaveService = LeaveRequestService(
      leaveRepo,
      studentService,
      classService,
      membershipService,
    );
    final attendanceService = AttendanceService(
      attendanceRepo,
      rosterService,
      sessionService,
      leaveService,
    );
    final creditService = SessionCreditService(
      creditRepo,
      sessionService,
      rosterService,
      attendanceRepo,
      studentService,
      classService,
      tuitionPolicyService,
    );
    final tuitionService = TuitionService(
      tuitionRepo,
      tuitionPolicyService,
      creditService,
      membershipService,
      attendanceRepo,
      adjRepo,
      sessionRepo,
    );
    final paymentService = PaymentService(paymentRepo, tuitionRepo, db);
    final invoiceService = InvoiceService(
      tuitionRepo,
      tuitionService,
      creditService,
      creditRepo,
      membershipService,
      paymentRepo,
      sessionService,
      db,
    );

    seeder = DemoDataSeeder(
      classService: classService,
      studentService: studentService,
      membershipService: membershipService,
      scheduleService: scheduleService,
      sessionGenService: sessionGenService,
      sessionService: sessionService,
      attendanceService: attendanceService,
      tuitionPolicyService: tuitionPolicyService,
      invoiceService: invoiceService,
      paymentService: paymentService,
      db: db,
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('DemoDataSeeder Verification Tests', () {
    test(
      'First seed creates expected dataset & second seed is idempotent',
      () async {
        // 1. Run First Seed
        final res1 = await seeder.seed();

        expect(res1.classesCreated, 5);
        expect(res1.studentsCreated, 80);
        expect(res1.membershipsCreated, 100);
        expect(res1.schedulesCreated, 11);
        expect(res1.stoppedStudents, 4);

        // Verify DB counts directly
        final classCount = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM lop'),
        );
        expect(classCount, 5);

        final studentCount = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM hoc_sinh'),
        );
        expect(studentCount, 80);

        final activeStudentCount = Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM hoc_sinh WHERE da_luu_tru = 0',
          ),
        );
        expect(activeStudentCount, 76);

        final archivedStudentCount = Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM hoc_sinh WHERE da_luu_tru = 1',
          ),
        );
        expect(archivedStudentCount, 4);

        final membershipCount = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM tham_gia_lop'),
        );
        expect(membershipCount, 100);

        final scheduleCount = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM lich_hoc'),
        );
        expect(scheduleCount, 11);

        final policyCount = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM chinh_sach_hoc_phi'),
        );
        expect(policyCount, 5);

        // 2. Verify 80 unique Vietnamese names and gender balance
        final studentRows = await db.query('hoc_sinh');
        final names = studentRows.map((r) => r['ho_ten'] as String).toSet();
        expect(names.length, 80);

        final maleCount = studentRows
            .where((r) => r['gioi_tinh'] == 'NAM')
            .length;
        final femaleCount = studentRows
            .where((r) => r['gioi_tinh'] == 'NU')
            .length;
        expect(maleCount, 40);
        expect(femaleCount, 40);

        // 3. Verify all initial membership start dates are 2026-07-02
        final membershipRows = await db.query('tham_gia_lop');
        for (final m in membershipRows) {
          expect(m['tu_ngay'], '2026-07-02');
        }

        // 4. Verify 4 stopped students have end date 2026-08-31
        final endedMemberships = membershipRows
            .where((m) => m['den_ngay'] != null)
            .toList();
        expect(endedMemberships.isNotEmpty, isTrue);
        for (final m in endedMemberships) {
          expect(m['den_ngay'], '2026-08-31');
        }

        // 5. Verify historical attendance populated and future sessions remain DU_KIEN
        final pastSessions = await db.rawQuery(
          "SELECT * FROM buoi_hoc WHERE ngay < '2026-09-28' AND trang_thai != 'HUY' AND trang_thai != 'NGHI_LE'",
        );
        expect(pastSessions.isNotEmpty, isTrue);
        for (final s in pastSessions) {
          expect(s['trang_thai'], 'DA_HOC');
        }

        final futureSessions = await db.rawQuery(
          "SELECT * FROM buoi_hoc WHERE ngay > '2026-09-28'",
        );
        expect(futureSessions.isNotEmpty, isTrue);
        for (final s in futureSessions) {
          expect(s['trang_thai'], 'DU_KIEN');
        }

        // 6. Verify NGHI_LE sessions have no attendance records
        final holidaySessions = await db.rawQuery(
          "SELECT * FROM buoi_hoc WHERE trang_thai = 'NGHI_LE'",
        );
        for (final h in holidaySessions) {
          final att = await db.rawQuery(
            "SELECT * FROM diem_danh WHERE id_buoi_hoc = ?",
            [h['id']],
          );
          expect(att.isEmpty, isTrue);
        }

        // 7. PRAGMA foreign_key_check passes
        final fkCheck = await db.rawQuery('PRAGMA foreign_key_check');
        expect(fkCheck, isEmpty);

        // 8. Run Second Seed for Idempotency
        final res2 = await seeder.seed();

        expect(res2.classesCreated, 0);
        expect(res2.studentsCreated, 0);
        expect(res2.classesReused, 5);
        expect(res2.studentsReused, 80);
        expect(res2.membershipsCreated, 0);
        expect(res2.schedulesCreated, 0);

        final finalClassCount = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM lop'),
        );
        expect(finalClassCount, 5);

        final finalStudentCount = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM hoc_sinh'),
        );
        expect(finalStudentCount, 80);

        final finalMembershipCount = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM tham_gia_lop'),
        );
        expect(finalMembershipCount, 100);
      },
    );
  });
}
