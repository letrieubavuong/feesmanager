import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:tuition2027/core/database/app_database.dart';
import 'package:tuition2027/features/classes/data/class_repository.dart';
import 'package:tuition2027/features/classes/domain/class_service.dart';
import 'package:tuition2027/features/memberships/data/membership_repository.dart';
import 'package:tuition2027/features/memberships/domain/membership_service.dart';
import 'package:tuition2027/features/tuition/data/tuition_policy_repository.dart';
import 'package:tuition2027/features/tuition/data/tuition_repository.dart';
import 'package:tuition2027/features/tuition/domain/tuition_policy_service.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('TuitionPolicyService Tests', () {
    late Database db;
    late TuitionPolicyRepository repo;
    late ClassService classService;
    late TuitionPolicyService service;

    setUp(() async {
      final tempDir = await Directory.systemTemp.createTemp('policy_test');
      final dbPath = join(tempDir.path, 'policy_test.db');
      final appDb = AppDatabase(dbName: dbPath);
      db = await appDb.database;

      final classRepo = ClassRepository(db);
      final memberRepo = MembershipRepository(db);
      final tuitionRepo = TuitionRepository(db);
      final membershipService = MembershipService(memberRepo);
      classService = ClassService(classRepo, membershipService);
      repo = TuitionPolicyRepository(db);
      service = TuitionPolicyService(repo, classService, tuitionRepo);

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

    test('Reject invalid fee, standard session count or interval', () async {
      expect(
        () => service.createPolicy(
          classId: 1,
          effectiveFrom: '2026-09-01',
          feePerSession: -5000,
        ),
        throwsA(isA<Exception>()),
      );

      expect(
        () => service.createPolicy(
          classId: 1,
          effectiveFrom: '2026-09-01',
          feePerSession: 50000,
          standardSessionsPerMonth: 0,
        ),
        throwsA(isA<Exception>()),
      );

      expect(
        () => service.createPolicy(
          classId: 1,
          effectiveFrom: '2026-09-30',
          effectiveTo: '2026-09-01',
          feePerSession: 50000,
        ),
        throwsA(isA<Exception>()),
      );
    });
  });
}
