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
import 'package:tuition2027/features/tuition/domain/invoice_service.dart';
import 'package:tuition2027/features/tuition/domain/tuition_invoice.dart';
import 'package:tuition2027/features/tuition/domain/tuition_policy_service.dart';
import 'package:tuition2027/features/tuition/domain/tuition_service.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('InvoiceService Finalization Tests', () {
    late Database db;
    late InvoiceService invoiceService;
    late TuitionPolicyService policyService;
    late SessionCreditService creditService;
    late MembershipService membershipService;
    late StudentService studentService;
    late ClassService classService;
    late SessionCreditRepository creditRepo;

    setUp(() async {
      final tempDir = await Directory.systemTemp.createTemp('invoice_test');
      final dbPath = join(tempDir.path, 'invoice_test.db');
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

      membershipService = MembershipService(memberRepo);
      studentService = StudentService(studentRepo, membershipService);
      classService = ClassService(classRepo, membershipService);
      policyService = TuitionPolicyService(
        policyRepo,
        classService,
        tuitionRepo,
      );

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
        db,
      );

      // Seed Student & Class
      await db.execute('''
        INSERT INTO hoc_sinh (id, ho_ten, sdt_phu_huynh, created_at, updated_at)
        VALUES (1, 'Student 1', '0901234567', '2026-01-01T00:00:00.000', '2026-01-01T00:00:00.000')
      ''');

      await db.execute('''
        INSERT INTO lop (id, ten_lop, created_at, updated_at)
        VALUES (1, 'Class 1', '2026-01-01T00:00:00.000', '2026-01-01T00:00:00.000')
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
      );

      await policyService.createPolicy(
        classId: 1,
        effectiveFrom: '2026-01-01',
        feePerSession: 50000,
        standardSessionsPerMonth: 12,
      );
    });

    tearDown(() async {
      await db.close();
    });

    test(
      'Finalize student invoice creates snapshot and consumes credit atomically',
      () async {
        // Add +1 opening credit
        await creditRepo.addLedgerEntry(
          CreditLedgerEntry(
            idHocSinh: 1,
            idLop: 1,
            idBuoiHoc: null,
            ngayHieuLuc: '2026-08-15',
            delta: 1,
            lyDo: CreditLedgerReason.MIGRATION,
            ghiChu: 'Opening',
            createdAt: DateTime.now(),
          ),
        );

        // 1 CO_MAT, 1 NGHI_CO_PHEP
        await db.execute('''
        INSERT INTO buoi_hoc (id, id_lop, id_lich_hoc, ngay, gio_bat_dau, gio_ket_thuc, loai, trang_thai, created_at, updated_at)
        VALUES (10, 1, 2, '2026-09-01', '17:30', '19:00', 'CHINH', 'DA_HOC', '2026-01-01T00:00:00.000', '2026-01-01T00:00:00.000')
      ''');
        await db.execute('''
        INSERT INTO diem_danh (id_buoi_hoc, id_hoc_sinh, id_lop_goc, trang_thai, created_at, updated_at)
        VALUES (10, 1, 1, 'CO_MAT', '2026-01-01T00:00:00.000', '2026-01-01T00:00:00.000')
      ''');

        await db.execute('''
        INSERT INTO buoi_hoc (id, id_lop, id_lich_hoc, ngay, gio_bat_dau, gio_ket_thuc, loai, trang_thai, created_at, updated_at)
        VALUES (11, 1, 3, '2026-09-02', '17:30', '19:00', 'CHINH', 'DA_HOC', '2026-01-01T00:00:00.000', '2026-01-01T00:00:00.000')
      ''');
        await db.execute('''
        INSERT INTO diem_danh (id_buoi_hoc, id_hoc_sinh, id_lop_goc, trang_thai, created_at, updated_at)
        VALUES (11, 1, 1, 'NGHI_CO_PHEP', '2026-01-01T00:00:00.000', '2026-01-01T00:00:00.000')
      ''');

        final invoice = await invoiceService.finalizeStudentInvoice(
          1,
          1,
          '2026-09',
        );

        expect(invoice.trangThai, TuitionInvoiceStatus.DA_CHOT);
        expect(invoice.soBuoiEligible, 2);
        expect(invoice.soBuoiTinhPhi, 2);
        expect(invoice.creditOpening, 1);
        expect(invoice.creditUsed, 1);
        expect(invoice.creditClosing, 0);
        expect(invoice.soTienPhaiThu, 100000);

        // Check credit ledger row created for BU_TRU_NGHI_CO_PHEP
        final ledger = await creditRepo.getLedgerForStudentAndClass(1, 1);
        expect(ledger.length, 2);
        expect(ledger.last.delta, -1);
        expect(ledger.last.lyDo, CreditLedgerReason.BU_TRU_NGHI_CO_PHEP);
        expect(ledger.last.idBuoiHoc, 11);

        // Re-finalizing throws exception
        expect(
          () => invoiceService.finalizeStudentInvoice(1, 1, '2026-09'),
          throwsA(isA<Exception>()),
        );
      },
    );

    test(
      'Creating retroactive policy is blocked when a finalized invoice exists',
      () async {
        await db.execute('''
        INSERT INTO buoi_hoc (id, id_lop, id_lich_hoc, ngay, gio_bat_dau, gio_ket_thuc, loai, trang_thai, created_at, updated_at)
        VALUES (20, 1, 2, '2026-09-01', '17:30', '19:00', 'CHINH', 'DA_HOC', '2026-01-01T00:00:00.000', '2026-01-01T00:00:00.000')
      ''');
        await db.execute('''
        INSERT INTO diem_danh (id_buoi_hoc, id_hoc_sinh, id_lop_goc, trang_thai, created_at, updated_at)
        VALUES (20, 1, 1, 'CO_MAT', '2026-01-01T00:00:00.000', '2026-01-01T00:00:00.000')
      ''');

        final invoiceSep = await invoiceService.finalizeStudentInvoice(
          1,
          1,
          '2026-09',
        );
        expect(invoiceSep.soTienPhaiThu, 50000);

        // Attempting to backdate a policy for September 2026 is BLOCKED!
        expect(
          () => policyService.createPolicy(
            classId: 1,
            effectiveFrom: '2026-09-01',
            feePerSession: 80000,
          ),
          throwsA(isA<Exception>()),
        );

        final fetchedSep = await invoiceService.getInvoice(1, 1, '2026-09');
        expect(
          fetchedSep?.soTienPhaiThu,
          50000,
        ); // Historical September invoice UNCHANGED!
      },
    );
  });
}
