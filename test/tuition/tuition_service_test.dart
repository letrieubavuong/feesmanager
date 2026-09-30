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
        rosterService,
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

    test(
      'Excused absence fee follows effective policy and does not use credit',
      () async {
        await db.insert('buoi_hoc', {
          'id': 1,
          'id_lop': 1,
          'id_lich_hoc': DateTime(2026, 9, 1).weekday,
          'ngay': '2026-09-01',
          'gio_bat_dau': '17:30',
          'gio_ket_thuc': '19:00',
          'loai': 'CHINH',
          'trang_thai': 'DA_HOC',
          'created_at': '2026-01-01T00:00:00.000',
          'updated_at': '2026-01-01T00:00:00.000',
        });
        await db.insert('diem_danh', {
          'id_buoi_hoc': 1,
          'id_hoc_sinh': 1,
          'id_lop_goc': 1,
          'trang_thai': 'NGHI_CO_PHEP',
          'created_at': '2026-01-01T00:00:00.000',
          'updated_at': '2026-01-01T00:00:00.000',
        });

        await db.update('chinh_sach_hoc_phi', {
          'quy_tac_nghi_co_phep': 'tinhPhi',
        });
        final charged = await service.previewTuition(1, 1, '2026-09');
        expect(charged.soBuoiTinhPhi, 1);
        expect(charged.soTienPhaiThu, 45000); // 50,000 less 10% class discount
        expect(charged.creditUsed, 0);

        await db.update('chinh_sach_hoc_phi', {
          'quy_tac_nghi_co_phep': 'khongTinhPhi',
        });
        final waived = await service.previewTuition(1, 1, '2026-09');
        expect(waived.soBuoiTinhPhi, 0);
        expect(waived.soTienPhaiThu, 0);
        expect(waived.creditUsed, 0);
      },
    );

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
      expect(preview.giamSoTien, 50000); // 10% of capped base (500,000)
      expect(preview.soTienPhaiThu, 450000);
    });

    test('Holiday sessions consume accumulated credit and remain chargeable', () async {
      await db.insert('buoi_du_ledger', {
        'id_hoc_sinh': 1,
        'id_lop': 1,
        'ngay_hieu_luc': '2026-08-31',
        'delta': 2,
        'ly_do': 'DIEU_CHINH_THU_CONG',
        'ghi_chu': 'Hai buổi dư tích lũy tháng 7 và 8',
        'created_at': '2026-08-31T00:00:00.000',
      });
      for (final entry in [(1, '2026-09-02'), (2, '2026-09-03')]) {
        final date = DateTime.parse(entry.$2);
        await db.insert('buoi_hoc', {
          'id': entry.$1,
          'id_lop': 1,
          'id_lich_hoc': date.weekday,
          'ngay': entry.$2,
          'gio_bat_dau': '17:30',
          'gio_ket_thuc': '19:00',
          'loai': 'CHINH',
          'trang_thai': 'NGHI_LE',
          'created_at': '2026-01-01T00:00:00.000',
          'updated_at': '2026-01-01T00:00:00.000',
        });
      }

      final preview = await service.previewTuition(1, 1, '2026-09');

      expect(preview.soBuoiDuKien, 2);
      expect(preview.soBuoiTinhPhi, 2);
      expect(preview.creditOpening, 2);
      expect(preview.creditUsed, 2);
      expect(preview.creditClosing, 0);
      expect(preview.tongTruocGiam, 100000);
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

      // 2. Above cap: 12 sessions * 50,000 = 600,000 => capped base = 500,000. Discount 10% on 500,000 = 50,000 => Net = 450,000.
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
      expect(previewAbove.soTienPhaiThu, 450000);
    });
  });
}
