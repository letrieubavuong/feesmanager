import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:tuition2027/features/attendance/data/attendance_repository.dart';
import 'package:tuition2027/core/database/app_database.dart';
import 'package:tuition2027/features/classes/data/class_repository.dart';
import 'package:tuition2027/features/classes/domain/class.dart';
import 'package:tuition2027/features/classes/domain/class_filter.dart';
import 'package:tuition2027/features/classes/domain/class_list_overview_service.dart';
import 'package:tuition2027/features/classes/domain/class_service.dart';
import 'package:tuition2027/features/dashboard/domain/dashboard_overview.dart';
import 'package:tuition2027/features/dashboard/domain/dashboard_service.dart';
import 'package:tuition2027/features/memberships/data/membership_repository.dart';
import 'package:tuition2027/features/memberships/domain/membership_service.dart';
import 'package:tuition2027/features/payments/data/payment_repository.dart';
import 'package:tuition2027/features/payments/domain/payment_method.dart';
import 'package:tuition2027/features/payments/domain/payment_service.dart';
import 'package:tuition2027/features/sessions/data/session_repository.dart';
import 'package:tuition2027/features/sessions/domain/class_session.dart';
import 'package:tuition2027/features/sessions/domain/session_service.dart';
import 'package:tuition2027/features/students/data/student_repository.dart';
import 'package:tuition2027/features/students/domain/student.dart';
import 'package:tuition2027/features/students/domain/student_detail_overview.dart';
import 'package:tuition2027/features/students/domain/student_detail_overview_service.dart';
import 'package:tuition2027/features/students/domain/student_service.dart';
import 'package:tuition2027/features/tuition/data/tuition_policy_repository.dart';
import 'package:tuition2027/features/tuition/data/tuition_repository.dart';
import 'package:tuition2027/features/tuition/domain/tuition_invoice.dart';
import 'package:tuition2027/features/tuition/domain/tuition_policy.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database db;
  late String dbPath;
  late StudentRepository studentRepo;
  late MembershipRepository membershipRepo;
  late MembershipService membershipService;
  late StudentService studentService;
  late ClassRepository classRepo;
  late ClassService classService;
  late TuitionPolicyRepository tuitionPolicyRepo;
  late TuitionRepository tuitionRepo;
  late PaymentRepository paymentRepo;
  late PaymentService paymentService;
  late SessionRepository sessionRepo;
  late SessionService sessionService;

  late ClassListOverviewService classOverviewService;
  late StudentDetailOverviewService studentOverviewService;
  late DashboardService dashboardService;

  setUp(() async {
    final tempDir = Directory.systemTemp.createTempSync('hotfix_test_');
    dbPath = p.join(tempDir.path, 'tuition_test.db');
    final appDb = AppDatabase(dbName: dbPath);
    db = await appDb.database;

    studentRepo = StudentRepository(db);
    membershipRepo = MembershipRepository(db);
    membershipService = MembershipService(membershipRepo);
    studentService = StudentService(studentRepo, membershipService);

    classRepo = ClassRepository(db);
    classService = ClassService(classRepo, membershipService);

    tuitionPolicyRepo = TuitionPolicyRepository(db);
    tuitionRepo = TuitionRepository(db);
    paymentRepo = PaymentRepository(db);
    paymentService = PaymentService(paymentRepo, tuitionRepo, db);

    sessionRepo = SessionRepository(db);
    sessionService = SessionService(sessionRepo, classService);

    classOverviewService = ClassListOverviewService(
      db,
      tuitionPolicyRepo,
      tuitionRepo,
      paymentService,
    );

    final attendanceRepo = AttendanceRepository(db);

    studentOverviewService = StudentDetailOverviewService(
      db,
      studentService,
      classService,
      tuitionRepo,
      paymentService,
      attendanceRepo,
      sessionRepo,
    );

    dashboardService = DashboardService(
      sessionService,
      classService,
      studentService,
      membershipService,
      tuitionRepo,
      tuitionPolicyRepo,
      paymentService,
      db,
    );
  });

  tearDown(() async {
    await db.close();
    final file = File(dbPath);
    if (await file.exists()) {
      await file.delete();
      await file.parent.delete();
    }
  });

  group('HOTFIX 14B.DATA-01 Data Correctness Tests', () {
    test('SECTION 24: Class debt multi-payment calculation', () async {
      final now = DateTime.parse('2026-09-15T10:00:00');
      final sId = await studentRepo.create(
        Student(hoTen: 'Học sinh A', createdAt: now, updatedAt: now),
      );
      final cId = await classRepo.create(
        ClassEntity(tenLop: 'Lớp 11A1', createdAt: now, updatedAt: now),
      );

      final pId = await tuitionPolicyRepo.insert(
        TuitionPolicy(
          idLop: cId,
          hieuLucTu: '2026-09-01',
          soBuoiChuanThang: 12,
          hocPhiMoiBuoi: 25000,
          createdAt: now,
          updatedAt: now,
        ),
      );
      await membershipService.enrollStudent(
        studentId: sId,
        classId: cId,
        joinDate: DateTime(2026, 9, 1),
      );

      await tuitionRepo.insertInvoice(
        TuitionInvoice(
          idHocSinh: sId,
          idLop: cId,
          thang: '2026-09',
          idChinhSachHocPhi: pId,
          soBuoiEligible: 12,
          soBuoiTinhPhi: 12,
          creditOpening: 0,
          creditEarned: 0,
          creditUsed: 0,
          creditClosing: 0,
          tongTruocGiam: 300000,
          giamPhanTram: 0,
          giamSoTien: 0,
          soTienPhaiThu: 300000,
          trangThai: TuitionInvoiceStatus.DA_CHOT,
          chotLuc: now,
          createdAt: now,
          updatedAt: now,
        ),
      );

      await paymentService.recordPayment(
        studentId: sId,
        classId: cId,
        month: '2026-09',
        amount: 100000,
        paymentDate: '2026-09-10',
        method: PaymentMethod.TIEN_MAT,
      );
      await paymentService.recordPayment(
        studentId: sId,
        classId: cId,
        month: '2026-09',
        amount: 100000,
        paymentDate: '2026-09-15',
        method: PaymentMethod.CHUYEN_KHOAN,
      );

      final overview = await classOverviewService.getOverview(
        ClassFilter.active,
        targetDate: DateTime(2026, 9, 28),
      );

      expect(overview.rows.length, 1);
      expect(overview.rows.first.currentMonthDebt, 100000);
      expect(overview.rows.first.currentMonthDebt, isNot(400000));
    });

    test('SECTION 25: Student late payment made in following month', () async {
      final now = DateTime.parse('2026-09-15T10:00:00');
      final sId = await studentRepo.create(
        Student(hoTen: 'Học sinh B', createdAt: now, updatedAt: now),
      );
      final cId = await classRepo.create(
        ClassEntity(tenLop: 'Lớp 12A1', createdAt: now, updatedAt: now),
      );

      final pId = await tuitionPolicyRepo.insert(
        TuitionPolicy(
          idLop: cId,
          hieuLucTu: '2026-09-01',
          soBuoiChuanThang: 10,
          hocPhiMoiBuoi: 50000,
          createdAt: now,
          updatedAt: now,
        ),
      );

      await membershipService.enrollStudent(
        studentId: sId,
        classId: cId,
        joinDate: DateTime(2026, 9, 1),
      );

      await tuitionRepo.insertInvoice(
        TuitionInvoice(
          idHocSinh: sId,
          idLop: cId,
          thang: '2026-09',
          idChinhSachHocPhi: pId,
          soBuoiEligible: 10,
          soBuoiTinhPhi: 10,
          creditOpening: 0,
          creditEarned: 0,
          creditUsed: 0,
          creditClosing: 0,
          tongTruocGiam: 500000,
          giamPhanTram: 0,
          giamSoTien: 0,
          soTienPhaiThu: 500000,
          trangThai: TuitionInvoiceStatus.DA_CHOT,
          chotLuc: now,
          createdAt: now,
          updatedAt: now,
        ),
      );

      await paymentService.recordPayment(
        studentId: sId,
        classId: cId,
        month: '2026-09',
        amount: 500000,
        paymentDate: '2026-10-02',
        method: PaymentMethod.CHUYEN_KHOAN,
      );

      final studentOverview = await studentOverviewService.getOverview(
        sId,
        targetDate: DateTime(2026, 9, 28),
      );

      expect(studentOverview.financial.finalizedDue, 500000);
      expect(studentOverview.financial.totalPaid, 500000);
      expect(studentOverview.financial.remainingDebt, 0);
      expect(
        studentOverview.financial.state,
        StudentFinancialDisplayState.fullyPaid,
      );
    });

    test(
      'SECTION 26: Class Entity ID mapping does not read membership ID',
      () async {
        final now = DateTime.parse('2026-09-15T10:00:00');
        final sId = await studentRepo.create(
          Student(hoTen: 'Học sinh C', createdAt: now, updatedAt: now),
        );
        final cId = await classRepo.create(
          ClassEntity(id: 12, tenLop: 'Lớp 12', createdAt: now, updatedAt: now),
        );

        await db.insert('tham_gia_lop', {
          'id': 900,
          'id_hoc_sinh': sId,
          'id_lop': cId,
          'tu_ngay': '2026-09-01',
          'den_ngay': null,
          'mien_giam_phan_tram': 0,
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        });

        final studentOverview = await studentOverviewService.getOverview(
          sId,
          targetDate: DateTime(2026, 9, 28),
        );

        expect(studentOverview.activeClasses.length, 1);
        final activeClassItem = studentOverview.activeClasses.first;
        expect(activeClassItem.membership.id, 900);
        expect(activeClassItem.classEntity.id, 12);
        expect(activeClassItem.classEntity.id, isNot(900));
      },
    );

    test(
      'SECTION 27 & 28: Tuition Policy query and AppDatabase V15 schema',
      () async {
        final now = DateTime.parse('2026-09-01T00:00:00');
        final sId = await studentRepo.create(
          Student(hoTen: 'Học sinh D', createdAt: now, updatedAt: now),
        );
        final cId = await classRepo.create(
          ClassEntity(id: 12, tenLop: 'Lớp 12', createdAt: now, updatedAt: now),
        );

        await membershipService.enrollStudent(
          studentId: sId,
          classId: cId,
          joinDate: DateTime(2026, 9, 1),
        );

        await tuitionPolicyRepo.insert(
          TuitionPolicy(
            idLop: cId,
            hieuLucTu: '2026-09-01',
            hieuLucDen: null,
            soBuoiChuanThang: 12,
            hocPhiMoiBuoi: 20000,
            createdAt: now,
            updatedAt: now,
          ),
        );

        final classOverview = await classOverviewService.getOverview(
          ClassFilter.active,
          targetDate: DateTime(2026, 9, 28),
        );

        expect(classOverview.rows.length, 1);
        expect(classOverview.rows.first.missingTuitionPolicy, isFalse);
      },
    );

    test(
      'SECTION 29: Dashboard attendance correction reads ly_do column',
      () async {
        final now = DateTime.parse('2026-09-28T10:00:00');
        final sId = await studentRepo.create(
          Student(hoTen: 'Học sinh E', createdAt: now, updatedAt: now),
        );
        final cId = await classRepo.create(
          ClassEntity(tenLop: 'Lớp 10B', createdAt: now, updatedAt: now),
        );
        final sessId = await sessionRepo.create(
          ClassSession(
            idLop: cId,
            ngay: '2026-09-28',
            gioBatDau: '17:30',
            gioKetThuc: '19:00',
            loai: SessionType.CHINH,
            trangThai: SessionStatus.DA_HOC,
            createdAt: now,
            updatedAt: now,
          ),
        );

        await db.insert('diem_danh_chinh_sua', {
          'id_buoi_hoc': sessId,
          'id_hoc_sinh': sId,
          'trang_thai_cu': 'CHUA_DIEM_DANH',
          'trang_thai_moi': 'CO_MAT',
          'ly_do': 'Sửa nhầm trạng thái',
          'changed_at': now.toIso8601String(),
        });

        final dashOverview = await dashboardService.getOverview(
          targetDate: now,
        );

        final corrActivities = dashOverview.recentActivities.where(
          (a) => a.type == DashboardActivityType.attendanceCorrection,
        );

        expect(corrActivities.length, 1);
        expect(corrActivities.first.subtitle, 'Sửa nhầm trạng thái');
      },
    );

    test(
      'SECTION 30: Finalized invoice activity survives status payment change',
      () async {
        final now = DateTime.parse('2026-09-28T10:00:00');
        final sId = await studentRepo.create(
          Student(hoTen: 'Học sinh F', createdAt: now, updatedAt: now),
        );
        final cId = await classRepo.create(
          ClassEntity(tenLop: 'Lớp 10A1', createdAt: now, updatedAt: now),
        );

        final pId = await tuitionPolicyRepo.insert(
          TuitionPolicy(
            idLop: cId,
            hieuLucTu: '2026-09-01',
            soBuoiChuanThang: 10,
            hocPhiMoiBuoi: 50000,
            createdAt: now,
            updatedAt: now,
          ),
        );

        await tuitionRepo.insertInvoice(
          TuitionInvoice(
            idHocSinh: sId,
            idLop: cId,
            thang: '2026-09',
            idChinhSachHocPhi: pId,
            soBuoiEligible: 10,
            soBuoiTinhPhi: 10,
            creditOpening: 0,
            creditEarned: 0,
            creditUsed: 0,
            creditClosing: 0,
            tongTruocGiam: 500000,
            giamPhanTram: 0,
            giamSoTien: 0,
            soTienPhaiThu: 500000,
            trangThai: TuitionInvoiceStatus.DA_CHOT,
            chotLuc: now,
            createdAt: now,
            updatedAt: now,
          ),
        );

        // Record full payment to change status to DA_THANH_TOAN
        await paymentService.recordPayment(
          studentId: sId,
          classId: cId,
          month: '2026-09',
          amount: 500000,
          paymentDate: '2026-09-28',
          method: PaymentMethod.TIEN_MAT,
        );

        final dashOverview = await dashboardService.getOverview(
          targetDate: now,
        );

        final finalizedActivities = dashOverview.recentActivities.where(
          (a) => a.type == DashboardActivityType.tuitionFinalized,
        );

        expect(finalizedActivities.length, 1);
        expect(finalizedActivities.first.subtitle, contains('Lớp 10A1'));
      },
    );
  });
}
