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
import 'package:tuition2027/features/session_credits/domain/credit_ledger_entry.dart';
import 'package:tuition2027/features/session_credits/domain/credit_ledger_reason.dart';
import 'package:tuition2027/features/session_credits/domain/session_credit_service.dart';
import 'package:tuition2027/features/sessions/data/session_repository.dart';
import 'package:tuition2027/features/sessions/domain/session_service.dart';
import 'package:tuition2027/features/students/data/student_repository.dart';
import 'package:tuition2027/features/students/domain/student_service.dart';
import 'package:tuition2027/features/tuition/data/tuition_policy_repository.dart';
import 'package:tuition2027/features/tuition/data/tuition_repository.dart';
import 'package:tuition2027/features/tuition/domain/tuition_policy_service.dart';
import 'package:tuition2027/features/tuition/domain/tuition_preview.dart';
import 'package:tuition2027/features/tuition/domain/tuition_service.dart';

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
      policyService = TuitionPolicyService(policyRepo, classService);

      final sessionService = SessionService(sessionRepo, classService);
      final scheduleService = ScheduleDomainService(
        scheduleRepo,
        assignRepo,
        membershipService,
        classService,
        studentService,
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

      // Add Membership from 2026-01-01 with 10% discount
      await membershipService.enrollStudent(
        studentId: 1,
        classId: 1,
        joinDate: DateTime.parse('2026-01-01'),
        mienGiam: 10,
      );

      // Policy: fee 50,000, standard 12, max cap 500,000
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
      // Create 12 CHINH DA_HOC sessions in Sep 2026
      for (int i = 1; i <= 12; i++) {
        final dayStr = i < 10 ? '0$i' : '$i';
        final dateStr = '2026-09-$dayStr';
        final dt = DateTime.parse(dateStr);
        await db.execute('''
          INSERT INTO buoi_hoc (id, id_lop, id_lich_hoc, ngay, gio_bat_dau, gio_ket_thuc, loai, trang_thai, created_at, updated_at)
          VALUES ($i, 1, ${dt.weekday}, '$dateStr', '17:30', '19:00', 'CHINH', 'DA_HOC', '2026-01-01T00:00:00.000', '2026-01-01T00:00:00.000')
        ''');

        // Attendance: CO_MAT
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
      // Amount after discount = 540,000 > cap 500,000 -> final due = 500,000
      expect(preview.soTienPhaiThu, 500000);

      // Pure read check: hoc_phi_thang is empty!
      final invoices = await db.query('hoc_phi_thang');
      expect(invoices, isEmpty);
    });

    test(
      'NGHI_CO_PHEP consumes credit if available, non-chargeable if no credit',
      () async {
        // Add +1 opening credit
        final creditRepo = SessionCreditRepository(db);
        await creditRepo.addLedgerEntry(
          CreditLedgerEntry(
            idHocSinh: 1,
            idLop: 1,
            idBuoiHoc: null,
            ngayHieuLuc: '2026-08-15',
            delta: 1,
            lyDo: CreditLedgerReason.MIGRATION,
            ghiChu: 'Opening credit',
            createdAt: DateTime.now(),
          ),
        );

        // Create 2 sessions: 1 CO_MAT, 1 NGHI_CO_PHEP
        await db.execute('''
        INSERT INTO buoi_hoc (id, id_lop, id_lich_hoc, ngay, gio_bat_dau, gio_ket_thuc, loai, trang_thai, created_at, updated_at)
        VALUES (101, 1, 2, '2026-09-01', '17:30', '19:00', 'CHINH', 'DA_HOC', '2026-01-01T00:00:00.000', '2026-01-01T00:00:00.000')
      ''');
        await db.execute('''
        INSERT INTO diem_danh (id_buoi_hoc, id_hoc_sinh, id_lop_goc, trang_thai, created_at, updated_at)
        VALUES (101, 1, 1, 'CO_MAT', '2026-01-01T00:00:00.000', '2026-01-01T00:00:00.000')
      ''');

        await db.execute('''
        INSERT INTO buoi_hoc (id, id_lop, id_lich_hoc, ngay, gio_bat_dau, gio_ket_thuc, loai, trang_thai, created_at, updated_at)
        VALUES (102, 1, 3, '2026-09-02', '17:30', '19:00', 'CHINH', 'DA_HOC', '2026-01-01T00:00:00.000', '2026-01-01T00:00:00.000')
      ''');
        await db.execute('''
        INSERT INTO diem_danh (id_buoi_hoc, id_hoc_sinh, id_lop_goc, trang_thai, created_at, updated_at)
        VALUES (102, 1, 1, 'NGHI_CO_PHEP', '2026-01-01T00:00:00.000', '2026-01-01T00:00:00.000')
      ''');

        final preview = await service.previewTuition(1, 1, '2026-09');

        expect(preview.soBuoiEligible, 2);
        expect(preview.creditOpening, 1);
        expect(preview.creditUsed, 1); // Spent 1 credit for NGHI_CO_PHEP
        expect(preview.creditClosing, 0);
        expect(preview.soBuoiTinhPhi, 2); // Both chargeable
        expect(preview.tongTruocGiam, 100000);
        expect(preview.giamPhanTram, 10);
        expect(preview.giamSoTien, 10000);
        expect(preview.soTienPhaiThu, 90000);

        // Verify candidates
        final c102 = preview.candidates.firstWhere((c) => c.session.id == 102);
        expect(c102.usesCredit, isTrue);
        expect(
          c102.chargeType,
          TuitionCandidateChargeType.CHARGEABLE_EXCUSED_WITH_CREDIT,
        );
      },
    );
  });
}
