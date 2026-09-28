import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;
import 'package:tuition2027/core/database/app_database.dart';
import 'package:tuition2027/features/attendance/data/attendance_repository.dart';
import 'package:tuition2027/features/classes/data/class_repository.dart';
import 'package:tuition2027/features/classes/domain/class_service.dart';
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
import 'package:tuition2027/features/session_credits/domain/credit_ledger_entry.dart';
import 'package:tuition2027/features/session_credits/domain/credit_ledger_reason.dart';
import 'package:tuition2027/features/session_credits/domain/session_credit_service.dart';
import 'package:tuition2027/features/sessions/data/session_repository.dart';
import 'package:tuition2027/features/sessions/domain/session_service.dart';
import 'package:tuition2027/features/settings/domain/bank_account_settings.dart';
import 'package:tuition2027/features/students/data/student_repository.dart';
import 'package:tuition2027/features/students/domain/student_service.dart';
import 'package:tuition2027/features/tuition/data/tuition_policy_repository.dart';
import 'package:tuition2027/features/tuition/data/tuition_repository.dart';
import 'package:tuition2027/features/tuition/domain/invoice_service.dart';
import 'package:tuition2027/features/tuition/domain/parent_tuition_slip.dart';
import 'package:tuition2027/features/tuition/domain/parent_tuition_slip_service.dart';
import 'package:tuition2027/features/tuition/domain/tuition_policy_service.dart';
import 'package:tuition2027/features/tuition/domain/tuition_service.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('ParentTuitionSlipService Domain Tests', () {
    late Database db;
    late StudentService studentService;
    late ClassService classService;
    late SessionService sessionService;
    late RosterService rosterService;
    late ScheduleDomainService scheduleService;
    late TuitionPolicyService policyService;
    late SessionCreditService creditService;
    late AttendanceRepository attendanceRepo;
    late InvoiceService invoiceService;
    late PaymentService paymentService;
    late MembershipService membershipService;
    late SessionCreditRepository creditRepo;
    late ParentTuitionSlipService slipService;

    const bankSettings = BankAccountSettings(
      bankName: 'MBBank',
      bankCode: 'MB',
      bankBin: '970422',
      accountNumber: '0123456789',
      accountHolder: 'TRAN VAN A',
      transferTemplate: 'HP {maHocSinh} {lop} {thang}',
    );

    // Tue, Thu, Sat dates in Sep 2026 (13 sessions total)
    final sep13Dates = [
      '2026-09-01', // Tue (2)
      '2026-09-03', // Thu (4)
      '2026-09-05', // Sat (6)
      '2026-09-08', // Tue (2)
      '2026-09-10', // Thu (4)
      '2026-09-12', // Sat (6)
      '2026-09-15', // Tue (2)
      '2026-09-17', // Thu (4)
      '2026-09-19', // Sat (6)
      '2026-09-22', // Tue (2)
      '2026-09-24', // Thu (4)
      '2026-09-26', // Sat (6)
      '2026-09-29', // Tue (2)
    ];

    setUp(() async {
      final tempDir = await Directory.systemTemp.createTemp('slip_service_test');
      final dbPath = p.join(tempDir.path, 'slip_service_test.db');
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
      creditRepo = SessionCreditRepository(db);
      final policyRepo = TuitionPolicyRepository(db);
      final tuitionRepo = TuitionRepository(db);
      final paymentRepo = PaymentRepository(db);
      final constraintRepo = ScheduleConstraintRepository(db);

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

      final conflictService = ScheduleConflictService(
        constraintRepo,
        scheduleRepo,
        assignRepo,
        sessionRepo,
        adjRepo,
        classService,
      );

      sessionService = SessionService(sessionRepo, classService);
      scheduleService = ScheduleDomainService(
        scheduleRepo,
        assignRepo,
        membershipService,
        classService,
        studentService,
        conflictService,
      );

      rosterService = RosterService(
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

      attendanceRepo = attRepo;

      final tuitionService = TuitionService(
        tuitionRepo,
        policyService,
        creditService,
        membershipService,
        attRepo,
        adjRepo,
        sessionRepo,
      );

      invoiceService = InvoiceService(
        tuitionRepo,
        tuitionService,
        creditService,
        creditRepo,
        membershipService,
        paymentRepo,
        db,
      );

      paymentService = PaymentService(
        paymentRepo,
        tuitionRepo,
        db,
      );

      slipService = ParentTuitionSlipService(
        studentService,
        classService,
        sessionService,
        rosterService,
        scheduleService,
        policyService,
        creditService,
        attendanceRepo,
        invoiceService,
        paymentService,
      );

      // Seed student 1 and class 1
      await db.execute('''
        INSERT INTO hoc_sinh (id, ho_ten, sdt_phu_huynh, created_at, updated_at)
        VALUES (1, 'Nguyễn Văn Ly', '0901234567', '2026-01-01T00:00:00.000', '2026-01-01T00:00:00.000')
      ''');

      await db.execute('''
        INSERT INTO lop (id, ten_lop, created_at, updated_at)
        VALUES (1, 'VẬT LÍ 10', '2026-01-01T00:00:00.000', '2026-01-01T00:00:00.000')
      ''');

      await membershipService.enrollStudent(
        studentId: 1,
        classId: 1,
        joinDate: DateTime.parse('2026-01-01'),
      );

      await policyService.createPolicy(
        classId: 1,
        effectiveFrom: '2026-01-01',
        feePerSession: 50000,
        standardSessionsPerMonth: 12,
      );

      // Schedules for Tue(2), Thu(4), Sat(6)
      for (final w in [2, 4, 6]) {
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
    });

    tearDown(() async {
      await db.close();
    });

    test('Test 1: Slip returns projectedSessionsNotGenerated when no month sessions generated', () async {
      final slip = await slipService.generateSlip(
        studentId: 1,
        classId: 1,
        month: '2026-09',
        bankSettings: bankSettings,
      );

      expect(slip.status, ParentTuitionSlipStatus.projectedSessionsNotGenerated);
      expect(slip.studentName, 'Nguyễn Văn Ly');
      expect(slip.className, 'VẬT LÍ 10');
    });

    test('Test 2: Projected session count & projected extra calculation when month sessions exist', () async {
      for (int i = 0; i < 13; i++) {
        final dateStr = sep13Dates[i];
        final weekday = DateTime.parse(dateStr).weekday;
        await db.insert('buoi_hoc', {
          'id': i + 1,
          'id_lop': 1,
          'id_lich_hoc': weekday,
          'ngay': dateStr,
          'gio_bat_dau': '17:30',
          'gio_ket_thuc': '19:00',
          'loai': 'CHINH',
          'trang_thai': 'DU_KIEN',
          'created_at': '2026-01-01T00:00:00.000',
          'updated_at': '2026-01-01T00:00:00.000',
        });
      }

      final slip = await slipService.generateSlip(
        studentId: 1,
        classId: 1,
        month: '2026-09',
        bankSettings: bankSettings,
      );

      expect(slip.status, ParentTuitionSlipStatus.noInvoiceFinalized);
      expect(slip.projectedSessionCount, 13);
      expect(slip.standardSessionLimit, 12);
      expect(slip.projectedExtraCount, 1);
    });

    test('Test 3: Multi-shift projection counts only student\'s shift', () async {
      // Add shift 100 on Tuesday 19:30 (student 1 is NOT assigned to shift 100)
      await db.insert('lich_hoc', {
        'id': 100,
        'id_lop': 1,
        'thu_trong_tuan': 2,
        'gio_bat_dau': '19:30',
        'gio_ket_thuc': '21:00',
        'hieu_luc_tu': '2026-01-01',
        'created_at': '2026-01-01T00:00:00.000',
        'updated_at': '2026-01-01T00:00:00.000',
      });

      // Assign student 1 to shift 2 (Tue 17:30)
      await db.insert('phan_ca_hoc_sinh', {
        'id': 1,
        'id_hoc_sinh': 1,
        'id_lop': 1,
        'id_lich_hoc': 2,
        'tu_ngay': '2026-01-01',
        'created_at': '2026-01-01T00:00:00.000',
        'updated_at': '2026-01-01T00:00:00.000',
      });

      // Tuesdays in Sep 2026: Sep 1, 8, 15, 22, 29 (5 Tuesdays)
      final tuesdays = ['2026-09-01', '2026-09-08', '2026-09-15', '2026-09-22', '2026-09-29'];

      // 5 sessions for shift 2 (Tue 17:30)
      for (int i = 0; i < 5; i++) {
        await db.insert('buoi_hoc', {
          'id': i + 1,
          'id_lop': 1,
          'id_lich_hoc': 2,
          'ngay': tuesdays[i],
          'gio_bat_dau': '17:30',
          'gio_ket_thuc': '19:00',
          'loai': 'CHINH',
          'trang_thai': 'DU_KIEN',
          'created_at': '2026-01-01T00:00:00.000',
          'updated_at': '2026-01-01T00:00:00.000',
        });
      }

      // 5 sessions for shift 100 (Tue 19:30 - not assigned to student 1)
      for (int i = 0; i < 5; i++) {
        await db.insert('buoi_hoc', {
          'id': i + 10,
          'id_lop': 1,
          'id_lich_hoc': 100,
          'ngay': tuesdays[i],
          'gio_bat_dau': '19:30',
          'gio_ket_thuc': '21:00',
          'loai': 'CHINH',
          'trang_thai': 'DU_KIEN',
          'created_at': '2026-01-01T00:00:00.000',
          'updated_at': '2026-01-01T00:00:00.000',
        });
      }

      final slip = await slipService.generateSlip(
        studentId: 1,
        classId: 1,
        month: '2026-09',
        bankSettings: bankSettings,
      );

      expect(slip.projectedSessionCount, 5);
    });

    test('Test 4: Canceled & Holiday sessions excluded from projected count', () async {
      for (int i = 0; i < 13; i++) {
        final dateStr = sep13Dates[i];
        final weekday = DateTime.parse(dateStr).weekday;
        final status = i == 0 ? 'HUY' : (i == 1 ? 'NGHI_LE' : 'DU_KIEN');
        await db.insert('buoi_hoc', {
          'id': i + 1,
          'id_lop': 1,
          'id_lich_hoc': weekday,
          'ngay': dateStr,
          'gio_bat_dau': '17:30',
          'gio_ket_thuc': '19:00',
          'loai': 'CHINH',
          'trang_thai': status,
          'created_at': '2026-01-01T00:00:00.000',
          'updated_at': '2026-01-01T00:00:00.000',
        });
      }

      final slip = await slipService.generateSlip(
        studentId: 1,
        classId: 1,
        month: '2026-09',
        bankSettings: bankSettings,
      );

      expect(slip.projectedSessionCount, 11);
    });

    test('Test 5: Opening credit balance as of day before month start', () async {
      // Insert a month session so slip generation advances past step 2
      await db.insert('buoi_hoc', {
        'id': 1,
        'id_lop': 1,
        'id_lich_hoc': 2,
        'ngay': '2026-09-01',
        'gio_bat_dau': '17:30',
        'gio_ket_thuc': '19:00',
        'loai': 'CHINH',
        'trang_thai': 'DU_KIEN',
        'created_at': '2026-01-01T00:00:00.000',
        'updated_at': '2026-01-01T00:00:00.000',
      });

      await creditRepo.addLedgerEntry(
        CreditLedgerEntry(
          idHocSinh: 1,
          idLop: 1,
          idBuoiHoc: null,
          ngayHieuLuc: '2026-08-15',
          delta: 3,
          lyDo: CreditLedgerReason.MIGRATION,
          ghiChu: 'Carried credit',
          createdAt: DateTime.now(),
        ),
      );
      await creditRepo.addLedgerEntry(
        CreditLedgerEntry(
          idHocSinh: 1,
          idLop: 1,
          idBuoiHoc: null,
          ngayHieuLuc: '2026-08-20',
          delta: -1,
          lyDo: CreditLedgerReason.DIEU_CHINH_THU_CONG,
          ghiChu: 'Used credit',
          createdAt: DateTime.now(),
        ),
      );

      final slip = await slipService.generateSlip(
        studentId: 1,
        classId: 1,
        month: '2026-09',
        bankSettings: bankSettings,
      );

      expect(slip.openingCreditBalance, 2);
    });
  });
}
