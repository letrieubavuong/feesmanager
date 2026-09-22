import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:tuition2027/core/database/app_database.dart';
import 'package:tuition2027/features/classes/data/class_repository.dart';
import 'package:tuition2027/features/classes/domain/class_service.dart';
import 'package:tuition2027/features/memberships/data/membership_repository.dart';
import 'package:tuition2027/features/memberships/domain/membership_service.dart';
import 'package:tuition2027/features/session_credits/data/session_credit_repository.dart';
import 'package:tuition2027/features/tuition/data/tuition_policy_repository.dart';
import 'package:tuition2027/features/tuition/data/tuition_repository.dart';
import 'package:tuition2027/features/tuition/domain/tuition_invoice.dart';
import 'package:tuition2027/features/tuition/domain/tuition_policy_service.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('TuitionPolicyService Hardening Tests', () {
    late Database db;
    late TuitionPolicyRepository repo;
    late ClassService classService;
    late TuitionPolicyService service;
    late TuitionRepository tuitionRepo;

    setUp(() async {
      final tempDir = await Directory.systemTemp.createTemp('policy_test');
      final dbPath = join(tempDir.path, 'policy_test.db');
      final appDb = AppDatabase(dbName: dbPath);
      db = await appDb.database;

      final classRepo = ClassRepository(db);
      final memberRepo = MembershipRepository(db);
      tuitionRepo = TuitionRepository(db);
      final creditRepo = SessionCreditRepository(db);
      final membershipService = MembershipService(memberRepo);
      classService = ClassService(classRepo, membershipService);
      repo = TuitionPolicyRepository(db);
      service = TuitionPolicyService(
        repo,
        classService,
        tuitionRepo,
        creditRepo,
        db,
      );

      await db.execute('''
        INSERT INTO hoc_sinh (id, ho_ten, sdt_phu_huynh, created_at, updated_at)
        VALUES (1, 'Student 1', '0901234567', '2026-01-01T00:00:00.000', '2026-01-01T00:00:00.000')
      ''');

      await db.execute('''
        INSERT INTO lop (id, ten_lop, mon_hoc, created_at, updated_at)
        VALUES (1, 'Math 10A', 'Math', '2026-01-01T00:00:00.000', '2026-01-01T00:00:00.000')
      ''');
    });

    tearDown(() async {
      await db.close();
    });

    test('Create effective policy and query by date', () async {
      final policy = await service.createPolicy(
        classId: 1,
        effectiveFrom: '2026-09-01',
        feePerSession: 50000,
        standardSessionsPerMonth: 12,
        monthlyMaxFee: 600000,
      );

      expect(policy.id, isNotNull);
      expect(policy.soBuoiChuanThang, 12);
      expect(policy.hocPhiMoiBuoi, 50000);

      final effective = await service.getEffectivePolicyForDateStr(
        1,
        '2026-09-15',
      );
      expect(effective?.id, policy.id);
    });

    test(
      'Creating a new open policy automatically closes previous open policy',
      () async {
        final p1 = await service.createPolicy(
          classId: 1,
          effectiveFrom: '2026-01-01',
          feePerSession: 40000,
        );

        await service.createPolicy(
          classId: 1,
          effectiveFrom: '2026-09-01',
          feePerSession: 50000,
        );

        final oldPolicyUpdated = await repo.getById(p1.id!);
        expect(oldPolicyUpdated?.hieuLucDen, '2026-08-31');

        final effectiveAug = await service.getEffectivePolicyForDateStr(
          1,
          '2026-08-15',
        );
        expect(effectiveAug?.hocPhiMoiBuoi, 40000);

        final effectiveSep = await service.getEffectivePolicyForDateStr(
          1,
          '2026-09-15',
        );
        expect(effectiveSep?.hocPhiMoiBuoi, 50000);
      },
    );

    test(
      'Reject non-month-boundary effectiveFrom or effectiveTo date',
      () async {
        expect(
          () => service.createPolicy(
            classId: 1,
            effectiveFrom: '2026-09-15',
            feePerSession: 50000,
          ),
          throwsA(isA<Exception>()),
        );

        expect(
          () => service.createPolicy(
            classId: 1,
            effectiveFrom: '2026-09-01',
            effectiveTo: '2026-09-15',
            feePerSession: 50000,
          ),
          throwsA(isA<Exception>()),
        );
      },
    );

    test(
      'Reject policy creation if a future finalized invoice exists in affected range',
      () async {
        await service.createPolicy(
          classId: 1,
          effectiveFrom: '2026-01-01',
          feePerSession: 50000,
        );

        // Insert DA_CHOT invoice in Oct 2026
        await tuitionRepo.insertInvoice(
          TuitionInvoice(
            idHocSinh: 1,
            idLop: 1,
            thang: '2026-10',
            idChinhSachHocPhi: 1,
            soBuoiEligible: 12,
            soBuoiTinhPhi: 12,
            creditOpening: 0,
            creditEarned: 0,
            creditUsed: 0,
            creditClosing: 0,
            tongTruocGiam: 600000,
            giamPhanTram: 0,
            giamSoTien: 0,
            soTienPhaiThu: 600000,
            trangThai: TuitionInvoiceStatus.DA_CHOT,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        // Attempting to backdate or insert policy starting Sep 2026 is REJECTED!
        expect(
          () => service.createPolicy(
            classId: 1,
            effectiveFrom: '2026-09-01',
            feePerSession: 60000,
          ),
          throwsA(isA<Exception>()),
        );
      },
    );

    test(
      'Reject retroactive N change when automated credit ledger entries exist',
      () async {
        await service.createPolicy(
          classId: 1,
          effectiveFrom: '2026-01-01',
          standardSessionsPerMonth: 12,
          feePerSession: 50000,
        );

        // Insert session 100 in buoi_hoc first to satisfy foreign key
        await db.execute('''
        INSERT INTO buoi_hoc (id, id_lop, id_lich_hoc, ngay, gio_bat_dau, gio_ket_thuc, loai, trang_thai, created_at, updated_at)
        VALUES (100, 1, NULL, '2026-09-20', '17:30', '19:00', 'CHINH', 'DA_HOC', '2026-01-01T00:00:00.000', '2026-01-01T00:00:00.000')
      ''');

        // Insert automated VUOT_SO_BUOI_CHUAN credit entry generated under N=12 in Sep 2026
        await db.execute('''
        INSERT INTO buoi_du_ledger (id_hoc_sinh, id_lop, id_buoi_hoc, ngay_hieu_luc, delta, ly_do, ghi_chu, created_at)
        VALUES (1, 1, 100, '2026-09-20', 1, 'VUOT_SO_BUOI_CHUAN', 'Extra credit', '2026-01-01T00:00:00.000')
      ''');

        // Attempting to create retroactive policy with N=15 for Sep 2026 is REJECTED!
        expect(
          () => service.createPolicy(
            classId: 1,
            effectiveFrom: '2026-09-01',
            standardSessionsPerMonth: 15,
            feePerSession: 50000,
          ),
          throwsA(isA<Exception>()),
        );
      },
    );
  });
}
