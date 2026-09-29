import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
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
import 'package:tuition2027/features/session_credits/domain/session_credit_service.dart';
import 'package:tuition2027/features/sessions/data/session_repository.dart';
import 'package:tuition2027/features/sessions/domain/session_service.dart';
import 'package:tuition2027/features/students/data/student_repository.dart';
import 'package:tuition2027/features/students/domain/student_service.dart';
import 'package:tuition2027/features/tuition/data/tuition_policy_repository.dart';
import 'package:tuition2027/features/tuition/data/tuition_repository.dart';
import 'package:tuition2027/features/tuition/domain/class_month_tuition_overview_service.dart';
import 'package:tuition2027/features/tuition/domain/tuition_policy_service.dart';
import 'package:tuition2027/features/tuition/domain/tuition_service.dart';
import 'package:tuition2027/features/tuition/presentation/class_tuition_tab.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('Tuition Performance & Filter Tests', () {
    late Database db;
    late Directory tempDir;
    late MembershipRepository membershipRepo;
    late MembershipService membershipService;
    late StudentRepository studentRepo;
    late StudentService studentService;
    late ClassRepository classRepo;
    late ClassService classService;
    late ScheduleRepository scheduleRepo;
    late ScheduleDomainService scheduleService;
    late SessionRepository sessionRepo;
    late SessionService sessionService;
    late RosterService rosterService;
    late AttendanceRepository attendanceRepo;
    late SessionAdjustmentRepository adjustmentRepo;
    late SessionCreditRepository creditRepo;
    late SessionCreditService creditService;
    late TuitionPolicyRepository policyRepo;
    late TuitionPolicyService policyService;
    late TuitionRepository tuitionRepo;
    late PaymentRepository paymentRepo;
    late PaymentService paymentService;
    late TuitionService tuitionService;
    late ClassMonthTuitionOverviewService overviewService;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('tuition_perf_test');
      final dbPath = join(tempDir.path, 'tuition_perf.db');
      final appDb = AppDatabase(dbName: dbPath);
      db = await appDb.database;

      membershipRepo = MembershipRepository(db);
      membershipService = MembershipService(membershipRepo);
      studentRepo = StudentRepository(db);
      studentService = StudentService(studentRepo, membershipService);
      classRepo = ClassRepository(db);
      classService = ClassService(classRepo, membershipService);
      scheduleRepo = ScheduleRepository(db);
      sessionRepo = SessionRepository(db);
      sessionService = SessionService(sessionRepo, classService);
      adjustmentRepo = SessionAdjustmentRepository(db);
      final assignRepo = AssignmentRepository(db);
      final constraintRepo = ScheduleConstraintRepository(db);
      final conflictService = ScheduleConflictService(
        constraintRepo,
        scheduleRepo,
        assignRepo,
        sessionRepo,
        adjustmentRepo,
        classService,
      );
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
        adjustmentRepo,
      );
      attendanceRepo = AttendanceRepository(db);
      creditRepo = SessionCreditRepository(db);
      policyRepo = TuitionPolicyRepository(db);
      tuitionRepo = TuitionRepository(db);
      policyService = TuitionPolicyService(
        policyRepo,
        classService,
        tuitionRepo,
        creditRepo,
        db,
      );
      creditService = SessionCreditService(
        creditRepo,
        sessionService,
        rosterService,
        attendanceRepo,
        studentService,
        classService,
        policyService,
      );
      paymentRepo = PaymentRepository(db);
      paymentService = PaymentService(paymentRepo, tuitionRepo, db);
      tuitionService = TuitionService(
        tuitionRepo,
        policyService,
        creditService,
        membershipService,
        attendanceRepo,
        adjustmentRepo,
        sessionRepo,
      );
      overviewService = ClassMonthTuitionOverviewService(
        membershipService,
        studentRepo,
        policyService,
        sessionService,
        creditService,
        creditRepo,
        attendanceRepo,
        adjustmentRepo,
        sessionRepo,
        tuitionRepo,
        paymentService,
        tuitionService,
      );
    });

    tearDown(() async {
      await db.close();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test(
      'calculatePreviewFromResolvedData matches previewTuition calculation result',
      () async {
        final nowStr = DateTime.now().toIso8601String();
        final studentId = await db.insert('hoc_sinh', {
          'ho_ten': 'Test Student',
          'sdt_phu_huynh': '0901234567',
          'zalo_link_status': 'CHUA_LIEN_KET',
          'da_luu_tru': 0,
          'created_at': nowStr,
          'updated_at': nowStr,
        });

        final classId = await db.insert('lop', {
          'ten_lop': 'Math 10',
          'da_luu_tru': 0,
          'created_at': nowStr,
          'updated_at': nowStr,
        });

        for (int w = 1; w <= 7; w++) {
          await db.insert('lich_hoc', {
            'id_lop': classId,
            'thu_trong_tuan': w,
            'gio_bat_dau': '08:00',
            'gio_ket_thuc': '09:30',
            'hieu_luc_tu': '2026-01-01',
            'created_at': nowStr,
            'updated_at': nowStr,
          });
        }

        await membershipService.enrollStudent(
          studentId: studentId,
          classId: classId,
          joinDate: DateTime.parse('2026-09-01'),
          mienGiam: 10,
        );

        await policyService.createPolicy(
          classId: classId,
          effectiveFrom: '2026-09-01',
          feePerSession: 100000,
          standardSessionsPerMonth: 4,
        );

        for (int i = 1; i <= 4; i++) {
          final dt = DateTime.parse('2026-09-0$i');
          final sId = await db.insert('buoi_hoc', {
            'id_lop': classId,
            'id_lich_hoc': dt.weekday,
            'ngay': '2026-09-0$i',
            'gio_bat_dau': '08:00',
            'gio_ket_thuc': '09:30',
            'loai': 'CHINH',
            'trang_thai': 'DA_HOC',
            'created_at': nowStr,
            'updated_at': nowStr,
          });

          await db.insert('diem_danh', {
            'id_buoi_hoc': sId,
            'id_hoc_sinh': studentId,
            'id_lop_goc': classId,
            'trang_thai': i == 1
                ? 'CO_MAT'
                : (i == 2 ? 'TRE' : 'NGHI_KHONG_PHEP'),
            'created_at': nowStr,
            'updated_at': nowStr,
          });
        }

        final preview1 = await tuitionService.previewTuition(
          studentId,
          classId,
          '2026-09',
        );

        expect(preview1.soBuoiEligible, 4);
        expect(preview1.soBuoiTinhPhi, 4);
        expect(preview1.giamPhanTram, 10);
        expect(preview1.soTienPhaiThu, 360000);
      },
    );

    test(
      'Class overview calculates overview with single roster call per candidate session',
      () async {
        final nowStr = DateTime.now().toIso8601String();
        final classId = await db.insert('lop', {
          'ten_lop': 'Physics 12',
          'da_luu_tru': 0,
          'created_at': nowStr,
          'updated_at': nowStr,
        });

        for (int w = 1; w <= 7; w++) {
          await db.insert('lich_hoc', {
            'id_lop': classId,
            'thu_trong_tuan': w,
            'gio_bat_dau': '08:00',
            'gio_ket_thuc': '09:30',
            'hieu_luc_tu': '2026-01-01',
            'created_at': nowStr,
            'updated_at': nowStr,
          });
        }

        await policyService.createPolicy(
          classId: classId,
          effectiveFrom: '2026-09-01',
          feePerSession: 150000,
          standardSessionsPerMonth: 4,
        );

        final s1 = await db.insert('hoc_sinh', {
          'ho_ten': 'S1',
          'sdt_phu_huynh': '0123456789',
          'zalo_link_status': 'CHUA_LIEN_KET',
          'da_luu_tru': 0,
          'created_at': nowStr,
          'updated_at': nowStr,
        });
        final s2 = await db.insert('hoc_sinh', {
          'ho_ten': 'S2',
          'sdt_phu_huynh': '0987654321',
          'zalo_link_status': 'CHUA_LIEN_KET',
          'da_luu_tru': 0,
          'created_at': nowStr,
          'updated_at': nowStr,
        });

        await membershipService.enrollStudent(
          studentId: s1,
          classId: classId,
          joinDate: DateTime.parse('2026-09-01'),
        );
        await membershipService.enrollStudent(
          studentId: s2,
          classId: classId,
          joinDate: DateTime.parse('2026-09-01'),
        );

        final sessId = await db.insert('buoi_hoc', {
          'id_lop': classId,
          'id_lich_hoc': 6,
          'ngay': '2026-09-05',
          'gio_bat_dau': '08:00',
          'gio_ket_thuc': '09:30',
          'loai': 'CHINH',
          'trang_thai': 'DA_HOC',
          'created_at': nowStr,
          'updated_at': nowStr,
        });

        await db.insert('diem_danh', {
          'id_buoi_hoc': sessId,
          'id_hoc_sinh': s1,
          'id_lop_goc': classId,
          'trang_thai': 'CO_MAT',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
        await db.insert('diem_danh', {
          'id_buoi_hoc': sessId,
          'id_hoc_sinh': s2,
          'id_lop_goc': classId,
          'trang_thai': 'CO_MAT',
          'created_at': nowStr,
          'updated_at': nowStr,
        });

        final overview = await overviewService.getOverview(classId, '2026-09');
        expect(overview.studentRows.length, 2);
      },
    );

    testWidgets(
      'ClassTuitionTab renders 3 filter segments (Tạm tính, Còn nợ, Đã nộp)',
      (tester) async {
        final nowStr = DateTime.now().toIso8601String();
        final classId = await db.insert('lop', {
          'ten_lop': 'Chemistry 11',
          'da_luu_tru': 0,
          'created_at': nowStr,
          'updated_at': nowStr,
        });

        for (int w = 1; w <= 7; w++) {
          await db.insert('lich_hoc', {
            'id_lop': classId,
            'thu_trong_tuan': w,
            'gio_bat_dau': '08:00',
            'gio_ket_thuc': '09:30',
            'hieu_luc_tu': '2026-01-01',
            'created_at': nowStr,
            'updated_at': nowStr,
          });
        }

        final studentId = await db.insert('hoc_sinh', {
          'ho_ten': 'Phạm Hoàng Ân',
          'sdt_phu_huynh': '0912345678',
          'zalo_link_status': 'CHUA_LIEN_KET',
          'da_luu_tru': 0,
          'created_at': nowStr,
          'updated_at': nowStr,
        });

        await membershipService.enrollStudent(
          studentId: studentId,
          classId: classId,
          joinDate: DateTime.parse('2026-09-01'),
        );

        await policyService.createPolicy(
          classId: classId,
          effectiveFrom: '2026-09-01',
          feePerSession: 100000,
          standardSessionsPerMonth: 4,
        );

        final sessId = await db.insert('buoi_hoc', {
          'id_lop': classId,
          'id_lich_hoc': 6,
          'ngay': '2026-09-05',
          'gio_bat_dau': '08:00',
          'gio_ket_thuc': '09:30',
          'loai': 'CHINH',
          'trang_thai': 'DA_HOC',
          'created_at': nowStr,
          'updated_at': nowStr,
        });

        await db.insert('diem_danh', {
          'id_buoi_hoc': sessId,
          'id_hoc_sinh': studentId,
          'id_lop_goc': classId,
          'trang_thai': 'CO_MAT',
          'created_at': nowStr,
          'updated_at': nowStr,
        });

        final container = ProviderContainer(
          overrides: [
            classMonthTuitionOverviewServiceProvider.overrideWith(
              (ref) async => overviewService,
            ),
          ],
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: Scaffold(body: ClassTuitionTab(classId: classId)),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.textContaining('Tạm tính'), findsOneWidget);
        expect(find.textContaining('Còn nợ'), findsOneWidget);
        expect(find.textContaining('Đã nộp'), findsOneWidget);
        expect(find.text('Phạm Hoàng Ân'), findsOneWidget);
      },
    );
  });
}
