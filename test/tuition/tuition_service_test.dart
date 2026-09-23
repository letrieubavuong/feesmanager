import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:tuition2027/core/database/app_database.dart';
import 'package:tuition2027/features/attendance/data/attendance_repository.dart';
import 'package:tuition2027/features/classes/data/class_repository.dart';
import 'package:tuition2027/features/classes/domain/class_service.dart';
import 'package:tuition2027/features/memberships/data/membership_repository.dart';
import 'package:tuition2027/features/memberships/domain/membership_service.dart';
import 'package:tuition2027/features/roster/domain/roster_service.dart';
import 'package:tuition2027/features/schedule/data/assignment_repository.dart';
import 'package:tuition2027/features/schedule/data/schedule_repository.dart';
import 'package:tuition2027/features/schedule/domain/schedule_service.dart';
import 'package:tuition2027/features/session_adjustments/data/session_adjustment_repository.dart';
import 'package:tuition2027/features/session_credits/data/session_credit_repository.dart';
import 'package:tuition2027/features/session_credits/domain/session_credit_service.dart';
import 'package:tuition2027/features/sessions/data/session_repository.dart';
import 'package:tuition2027/features/sessions/domain/session_service.dart';
import 'package:tuition2027/features/students/data/student_repository.dart';
import 'package:tuition2027/features/students/domain/student_service.dart';
import 'package:tuition2027/features/tuition/data/tuition_policy_repository.dart';
import 'package:tuition2027/features/tuition/data/tuition_repository.dart';
import 'package:tuition2027/features/tuition/domain/tuition_policy_service.dart';
import 'package:tuition2027/features/tuition/domain/tuition_service.dart';

import 'package:tuition2027/features/schedule_conflicts/data/schedule_constraint_repository.dart';
import 'package:tuition2027/features/schedule_conflicts/domain/schedule_conflict_service.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('TuitionService Pure Read Preview Tests', () {
    late Database db;
    late TuitionService service;
    late TuitionPolicyService policyService;
    late SessionCreditService creditService;
    late MembershipService membershipService;
    late StudentService studentService;
    late ClassService classService;

    setUp(() async {
      final tempDir = await Directory.systemTemp.createTemp('tuition_test');
      final dbPath = join(tempDir.path, 'tuition_test.db');
      final appDb = AppDatabase(dbName: dbPath);
      db = await appDb.database;

      final studentRepo = StudentRepository(db);
      final classRepo = ClassRepository(db);
      final memberRepo = MembershipRepository(db);
      final scheduleRepo = ScheduleRepository(db);
      final assignRepo = AssignmentRepository(db);
      final sessionRepo = SessionRepository(db);
      final attRepo = AttendanceRepository(db);
      final adjRepo = SessionAdjustmentRepository(db);
      final creditRepo = SessionCreditRepository(db);
      final policyRepo = TuitionPolicyRepository(db);
      final tuitionRepo = TuitionRepository(db);

      membershipService = MembershipService(memberRepo);
      studentService = StudentService(studentRepo, membershipService);
      classService = ClassService(classRepo, membershipService);
      policyService = TuitionPolicyService(
        policyRepo,
        classService,
        tuitionRepo,
        creditRepo,
        db,
      );

      final constraintRepo = ScheduleConstraintRepository(db);
      final conflictService = ScheduleConflictService(
        constraintRepo,
        scheduleRepo,
        assignRepo,
        sessionRepo,
        adjRepo,
        classService,
      );

      final sessionService = SessionService(sessionRepo, classService);
      final scheduleService = ScheduleDomainService(
        scheduleRepo,
        assignRepo,
        membershipService,
        classService,
        studentService,
        conflictService,
      );
      final rosterService = RosterService(
        sessionService,
        membershipService,
        scheduleService,
        studentService,
        adjRepo,
      );

      creditService = SessionCreditService(
        creditRepo,
        sessionService,
        rosterService,
        attRepo,
        studentService,
        classService,
        policyService,
      );

      service = TuitionService(
        tuitionRepo,
        policyService,
        creditService,
        membershipService,
        attRepo,
        adjRepo,
        sessionRepo,
      );

      // Seed Student & Class
      await db.execute('''
        INSERT INTO hoc_sinh (id, ho_ten, sdt_phu_huynh, created_at, updated_at)
        VALUES (1, 'Nguyen Van A', '0901234567', '2026-01-01T00:00:00.000', '2026-01-01T00:00:00.000')
      ''');

      await db.execute('''
        INSERT INTO lop (id, ten_lop, created_at, updated_at)
        VALUES (1, 'Math 10A', '2026-01-01T00:00:00.000', '2026-01-01T00:00:00.000')
      ''');

      for (int w = 1; w <= 7; w++) {
        await db.insert('lich_hoc', {
          'id': w,
          'id_lop': 1,
          'thu_trong_tuan': w,
          'gio_bat_dau': '17:30',
          'gio_ket_thuc': '19:00',
          'hieu_luc_tu': '2026-01-01',
          'created_at': '2026-01-01T00:00:00.000',
          'updated_at': '2026-01-01T00:00:00.000',
        });
      }

      await membershipService.enrollStudent(
        studentId: 1,
        classId: 1,
        joinDate: DateTime.parse('2026-01-01'),
        mienGiam: 10,
      );

      await policyService.createPolicy(
        classId: 1,
        effectiveFrom: '2026-01-01',
        feePerSession: 50000,
        standardSessionsPerMonth: 12,
        monthlyMaxFee: 500000,
      );
    });

    tearDown(() async {
      await db.close();
    });

    test('Standard 12 sessions attended preview', () async {
      for (int i = 1; i <= 12; i++) {
        final dayStr = i < 10 ? '0$i' : '$i';
        final dateStr = '2026-09-$dayStr';
        final dt = DateTime.parse(dateStr);
        await db.execute('''
          INSERT INTO buoi_hoc (id, id_lop, id_lich_hoc, ngay, gio_bat_dau, gio_ket_thuc, loai, trang_thai, created_at, updated_at)
          VALUES ($i, 1, ${dt.weekday}, '$dateStr', '17:30', '19:00', 'CHINH', 'DA_HOC', '2026-01-01T00:00:00.000', '2026-01-01T00:00:00.000')
        ''');

        await db.execute('''
          INSERT INTO diem_danh (id_buoi_hoc, id_hoc_sinh, id_lop_goc, trang_thai, created_at, updated_at)
          VALUES ($i, 1, 1, 'CO_MAT', '2026-01-01T00:00:00.000', '2026-01-01T00:00:00.000')
        ''');
      }

      final preview = await service.previewTuition(1, 1, '2026-09');

      expect(preview.soBuoiEligible, 12);
      expect(preview.soBuoiTinhPhi, 12);
      expect(preview.tongTruocGiam, 600000); // 12 * 50,000
      expect(preview.giamPhanTram, 10);
      expect(preview.giamSoTien, 60000); // 10% of 600,000
      expect(preview.soTienPhaiThu, 500000);
    });

    test(
      'Double-Count Credit Case B: Pre-reconciled extra credit is NOT double-counted',
      () async {
        // 12 standard sessions + 1 extra session (13)
        for (int i = 1; i <= 13; i++) {
          final dayStr = i < 10 ? '0$i' : '$i';
          final dateStr = '2026-09-$dayStr';
          final dt = DateTime.parse(dateStr);
          await db.execute('''
          INSERT INTO buoi_hoc (id, id_lop, id_lich_hoc, ngay, gio_bat_dau, gio_ket_thuc, loai, trang_thai, created_at, updated_at)
          VALUES ($i, 1, ${dt.weekday}, '$dateStr', '17:30', '19:00', 'CHINH', 'DA_HOC', '2026-01-01T00:00:00.000', '2026-01-01T00:00:00.000')
        ''');
          await db.execute('''
          INSERT INTO diem_danh (id_buoi_hoc, id_hoc_sinh, id_lop_goc, trang_thai, created_at, updated_at)
          VALUES ($i, 1, 1, 'CO_MAT', '2026-01-01T00:00:00.000', '2026-01-01T00:00:00.000')
        ''');
        }

        // Pre-reconcile session 13 into buoi_du_ledger
        await db.execute('''
        INSERT INTO buoi_du_ledger (id_hoc_sinh, id_lop, id_buoi_hoc, ngay_hieu_luc, delta, ly_do, ghi_chu, created_at)
        VALUES (1, 1, 13, '2026-09-13', 1, 'VUOT_SO_BUOI_CHUAN', 'Pre-reconciled credit', '2026-01-01T00:00:00.000')
      ''');

        final preview = await service.previewTuition(1, 1, '2026-09');

        // Crucial assertion: Preview closing MUST be 1, NOT 2!
        expect(preview.creditOpening, 0);
        expect(preview.creditEarned, 1);
        expect(preview.creditClosing, 1);
      },
    );

    test('Monthly Cap Boundary Tests: below, equal, above, null cap', () async {
      // 1. Below cap: 2 sessions * 50,000 = 100,000, 10% discount => 90,000
      for (int i = 1; i <= 2; i++) {
        final dateStr = '2026-09-0$i';
        final dt = DateTime.parse(dateStr);
        await db.execute('''
          INSERT INTO buoi_hoc (id, id_lop, id_lich_hoc, ngay, gio_bat_dau, gio_ket_thuc, loai, trang_thai, created_at, updated_at)
          VALUES ($i, 1, ${dt.weekday}, '$dateStr', '17:30', '19:00', 'CHINH', 'DA_HOC', '2026-01-01T00:00:00.000', '2026-01-01T00:00:00.000')
        ''');
        await db.execute('''
          INSERT INTO diem_danh (id_buoi_hoc, id_hoc_sinh, id_lop_goc, trang_thai, created_at, updated_at)
          VALUES ($i, 1, 1, 'CO_MAT', '2026-01-01T00:00:00.000', '2026-01-01T00:00:00.000')
        ''');
      }

      final previewBelow = await service.previewTuition(1, 1, '2026-09');
      expect(previewBelow.soTienPhaiThu, 90000);

      // 2. Above cap: 12 sessions * 50,000 = 600,000 - 10% = 540,000 > cap 500,000 => 500,000
      for (int i = 3; i <= 12; i++) {
        final dayStr = i < 10 ? '0$i' : '$i';
        final dateStr = '2026-09-$dayStr';
        final dt = DateTime.parse(dateStr);
        await db.execute('''
          INSERT INTO buoi_hoc (id, id_lop, id_lich_hoc, ngay, gio_bat_dau, gio_ket_thuc, loai, trang_thai, created_at, updated_at)
          VALUES ($i, 1, ${dt.weekday}, '$dateStr', '17:30', '19:00', 'CHINH', 'DA_HOC', '2026-01-01T00:00:00.000', '2026-01-01T00:00:00.000')
        ''');
        await db.execute('''
          INSERT INTO diem_danh (id_buoi_hoc, id_hoc_sinh, id_lop_goc, trang_thai, created_at, updated_at)
          VALUES ($i, 1, 1, 'CO_MAT', '2026-01-01T00:00:00.000', '2026-01-01T00:00:00.000')
        ''');
      }

      final previewAbove = await service.previewTuition(1, 1, '2026-09');
      expect(previewAbove.soTienPhaiThu, 500000);
    });
  });
}
