import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tuition2027/app/design_system/app_theme.dart';
import 'package:tuition2027/features/attendance/data/attendance_repository.dart';
import 'package:tuition2027/features/classes/data/class_repository.dart';
import 'package:tuition2027/features/classes/domain/class_filter.dart';
import 'package:tuition2027/features/classes/domain/class_list_overview_service.dart';
import 'package:tuition2027/features/classes/domain/class_service.dart';
import 'package:tuition2027/features/dashboard/domain/dashboard_overview.dart';
import 'package:tuition2027/features/dashboard/presentation/dashboard_page.dart';
import 'package:tuition2027/features/memberships/data/membership_repository.dart';
import 'package:tuition2027/features/memberships/domain/membership_service.dart';
import 'package:tuition2027/features/payments/domain/invoice_payment_summary.dart';
import 'package:tuition2027/features/payments/domain/payment_service.dart';
import 'package:tuition2027/features/sessions/data/session_repository.dart';
import 'package:tuition2027/features/sessions/domain/class_session.dart';
import 'package:tuition2027/features/students/data/student_repository.dart';
import 'package:tuition2027/features/students/domain/student_detail_overview_service.dart';
import 'package:tuition2027/features/students/domain/student_service.dart';
import 'package:tuition2027/features/tuition/data/tuition_policy_repository.dart';
import 'package:tuition2027/features/tuition/data/tuition_repository.dart';
import 'package:tuition2027/features/tuition/domain/tuition_invoice.dart';

import 'package:tuition2027/l10n/app_localizations.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database db;

  setUp(() async {
    db = await openDatabase(
      inMemoryDatabasePath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE hoc_sinh (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            ho_ten TEXT NOT NULL,
            ngay_sinh TEXT,
            gioi_ten TEXT,
            gioi_tinh TEXT,
            truong_dang_hoc TEXT,
            khoi INTEGER,
            ten_phu_huynh TEXT,
            sdt_phu_huynh TEXT,
            sdt_hoc_sinh TEXT,
            email TEXT,
            dia_chi TEXT,
            facebook TEXT,
            ghi_chu TEXT,
            zalo_user_id TEXT,
            zalo_display_name TEXT,
            zalo_link_status TEXT NOT NULL DEFAULT 'NONE',
            da_luu_tru INTEGER NOT NULL DEFAULT 0,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE lop (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            ten_lop TEXT NOT NULL,
            mon_hoc TEXT,
            khoi INTEGER,
            si_so_toi_da INTEGER,
            ghi_chu TEXT,
            da_luu_tru INTEGER NOT NULL DEFAULT 0,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE buoi_hoc (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            id_lop INTEGER NOT NULL,
            id_lich_hoc INTEGER,
            ngay TEXT NOT NULL,
            gio_bat_dau TEXT NOT NULL,
            gio_ket_thuc TEXT NOT NULL,
            loai TEXT NOT NULL DEFAULT 'CHINH',
            trang_thai TEXT NOT NULL DEFAULT 'DU_KIEN',
            ghi_chu TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE diem_danh (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            id_buoi_hoc INTEGER NOT NULL,
            id_hoc_sinh INTEGER NOT NULL,
            id_lop_goc INTEGER,
            trang_thai TEXT NOT NULL,
            loai_tham_gia TEXT NOT NULL DEFAULT 'CHINH',
            id_buoi_vang_goc INTEGER,
            ghi_chu TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE tham_gia_lop (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            id_hoc_sinh INTEGER NOT NULL,
            id_lop INTEGER NOT NULL,
            tu_ngay TEXT NOT NULL,
            den_ngay TEXT,
            muc_giam_gia INTEGER DEFAULT 0,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE phan_ca_hoc_sinh (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            id_hoc_sinh INTEGER NOT NULL,
            id_lop INTEGER NOT NULL,
            id_lich_hoc INTEGER NOT NULL,
            tu_ngay TEXT NOT NULL,
            den_ngay TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE rang_buoc_lich_hoc_sinh (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            id_hoc_sinh INTEGER NOT NULL,
            loai TEXT NOT NULL,
            kieu TEXT NOT NULL,
            thu_trong_tuan INTEGER,
            ngay_cu_the TEXT,
            gio_bat_dau TEXT NOT NULL,
            gio_ket_thuc TEXT NOT NULL,
            hieu_luc_tu TEXT,
            hieu_luc_den TEXT,
            travel_buffer_phut INTEGER NOT NULL DEFAULT 0,
            ten_nguon TEXT,
            ghi_chu TEXT,
            trang_thai TEXT NOT NULL DEFAULT 'HOAT_DONG',
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE lich_hoc (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            id_lop INTEGER NOT NULL,
            thu_trong_tuan INTEGER NOT NULL,
            gio_bat_dau TEXT NOT NULL,
            gio_ket_thuc TEXT NOT NULL,
            hieu_luc_tu TEXT NOT NULL,
            hieu_luc_den TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE hoc_phi_thang (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            id_hoc_sinh INTEGER NOT NULL,
            id_lop INTEGER NOT NULL,
            thang TEXT NOT NULL,
            so_buoi_chuan INTEGER NOT NULL,
            don_gia_buoi INTEGER NOT NULL,
            so_buoi_du_kien INTEGER NOT NULL,
            so_buoi_co_mat INTEGER NOT NULL,
            so_buoi_vang_phep INTEGER NOT NULL,
            so_buoi_vang_khong_phep INTEGER NOT NULL,
            so_buoi_du INTEGER NOT NULL,
            so_tien_giam_gia INTEGER NOT NULL DEFAULT 0,
            so_tien_phai_thu INTEGER NOT NULL,
            chot_luc TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE thanh_toan (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            id_hoc_sinh INTEGER NOT NULL,
            id_lop INTEGER NOT NULL,
            so_tien INTEGER NOT NULL,
            ngay_thanh_toan TEXT NOT NULL,
            phuong_thuc TEXT NOT NULL,
            ghi_chu TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE gio_ban_hoc_sinh (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            id_hoc_sinh INTEGER NOT NULL,
            loai_tan_suat TEXT NOT NULL,
            thu_trong_tuan INTEGER,
            ngay_cu_the TEXT,
            gio_bat_dau TEXT NOT NULL,
            gio_ket_thuc TEXT NOT NULL,
            hieu_luc_tu TEXT NOT NULL,
            hieu_luc_den TEXT,
            ghi_chu TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');
      },
    );
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets(
    'Today Schedule timeline items render with ascending time order',
    (tester) async {
      final now = DateTime.now();
      final todayStr = DateFormat('yyyy-MM-dd').format(now);

      final s1 = ClassSession(
        id: 1,
        idLop: 10,
        ngay: todayStr,
        gioBatDau: '08:00',
        gioKetThuc: '09:30',
        loai: SessionType.CHINH,
        trangThai: SessionStatus.DA_HOC,
        createdAt: now,
        updatedAt: now,
      );

      final s2 = ClassSession(
        id: 2,
        idLop: 11,
        ngay: todayStr,
        gioBatDau: '10:00',
        gioKetThuc: '11:30',
        loai: SessionType.CHINH,
        trangThai: SessionStatus.DA_HOC,
        createdAt: now,
        updatedAt: now,
      );

      final sessions = [
        DashboardTodaySession(session: s1, className: 'Toán 6'),
        DashboardTodaySession(session: s2, className: 'KHTN 8'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('vi'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final l10n = AppLocalizations.of(context)!;
                return DashboardTodayTimelineItem(
                  item: sessions[0],
                  isFirst: true,
                  isLast: false,
                  statusText: l10n.dashboardDone,
                  statusColor: AppColors.success,
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('08:00–09:30'), findsOneWidget);
      expect(find.text('Toán 6'), findsOneWidget);
      expect(find.text('Đã xong'), findsOneWidget);
    },
  );

  testWidgets('Recent Activity expander starts collapsed and toggles on tap', (
    tester,
  ) async {
    final now = DateTime.now();
    final activities = [
      DashboardActivity(
        title: 'Điểm danh hoàn tất',
        subtitle: 'Toán 6',
        timestamp: now,
        type: DashboardActivityType.sessionCompleted,
      ),
      DashboardActivity(
        title: 'Đã thu 350.000đ',
        subtitle: 'Bùi Đức Quang',
        timestamp: now.subtract(const Duration(minutes: 10)),
        type: DashboardActivityType.paymentRecorded,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('vi'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: DashboardRecentActivitiesExpander(activities: activities),
        ),
      ),
    );

    // Initial state: collapsed
    expect(find.text('Cập nhật gần đây'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('Điểm danh hoàn tất'), findsNothing);

    // Tap header to expand
    await tester.tap(find.byType(InkWell));
    await tester.pumpAndSettle();

    expect(find.text('Điểm danh hoàn tất'), findsOneWidget);
    expect(find.text('Đã thu 350.000đ'), findsOneWidget);
  });

  test('Class list is sorted by grade ASC with null grade last', () async {
    final now = DateTime.now().toIso8601String();

    await db.insert('lop', {
      'ten_lop': 'Vật lí 12',
      'khoi': 12,
      'mon_hoc': 'Vật lí',
      'created_at': now,
      'updated_at': now,
    });
    await db.insert('lop', {
      'ten_lop': 'Toán 6',
      'khoi': 6,
      'mon_hoc': 'Toán',
      'created_at': now,
      'updated_at': now,
    });
    await db.insert('lop', {
      'ten_lop': 'KHTN 8',
      'khoi': 8,
      'mon_hoc': 'KHTN',
      'created_at': now,
      'updated_at': now,
    });
    await db.insert('lop', {
      'ten_lop': 'Năng khiếu',
      'khoi': null,
      'mon_hoc': 'Khác',
      'created_at': now,
      'updated_at': now,
    });

    final dummyTuitionPolicyRepo = DummyTuitionPolicyRepository(db);
    final dummyTuitionRepo = DummyTuitionRepository(db);
    final dummyPaymentService = DummyPaymentService(db);

    final service = ClassListOverviewService(
      db,
      dummyTuitionPolicyRepo,
      dummyTuitionRepo,
      dummyPaymentService,
    );

    final overview = await service.getOverview(ClassFilter.active);
    final sortedNames = overview.rows.map((r) => r.classEntity.tenLop).toList();

    expect(sortedNames, ['Toán 6', 'KHTN 8', 'Vật lí 12', 'Năng khiếu']);
  });

  test(
    'StudentDetailOverviewService loads recent attendance without type cast exception',
    () async {
      final nowStr = DateTime.now().toIso8601String();

      // Insert student
      final studentId = await db.insert('hoc_sinh', {
        'ho_ten': 'Bùi Đức Quang',
        'khoi': 10,
        'truong_dang_hoc': 'THPT Gia Định',
        'sdt_phu_huynh': '0907000045',
        'zalo_link_status': 'NONE',
        'da_luu_tru': 0,
        'created_at': nowStr,
        'updated_at': nowStr,
      });

      // Insert class
      final classId = await db.insert('lop', {
        'ten_lop': 'Vật lí 10',
        'khoi': 10,
        'created_at': nowStr,
        'updated_at': nowStr,
      });

      // Insert session
      final sessionId = await db.insert('buoi_hoc', {
        'id_lop': classId,
        'ngay': '2026-09-28',
        'gio_bat_dau': '19:30',
        'gio_ket_thuc': '21:00',
        'loai': 'CHINH',
        'trang_thai': 'DA_HOC',
        'created_at': nowStr,
        'updated_at': nowStr,
      });

      // Insert attendance
      await db.insert('diem_danh', {
        'id_buoi_hoc': sessionId,
        'id_hoc_sinh': studentId,
        'id_lop_goc': classId,
        'trang_thai': 'CO_MAT',
        'loai_tham_gia': 'CHINH',
        'created_at': nowStr,
        'updated_at': nowStr,
      });

      final studentRepo = StudentRepository(db);
      final classRepo = ClassRepository(db);
      final membershipRepo = MembershipRepository(db);
      final membershipService = MembershipService(membershipRepo);

      final studentService = StudentService(studentRepo, membershipService);
      final classService = ClassService(classRepo, membershipService);
      final attendanceRepo = AttendanceRepository(db);
      final sessionRepo = SessionRepository(db);

      final dummyTuitionRepo = DummyTuitionRepository(db);
      final dummyPaymentService = DummyPaymentService(db);

      final overviewService = StudentDetailOverviewService(
        db,
        studentService,
        classService,
        dummyTuitionRepo,
        dummyPaymentService,
        attendanceRepo,
        sessionRepo,
      );

      // THIS MUST NOT THROW type 'Null' is not a subtype of type 'String'
      final overview = await overviewService.getOverview(studentId);

      expect(overview.student.hoTen, 'Bùi Đức Quang');
      expect(overview.recentAttendance.length, 1);
      expect(overview.recentAttendance.first.session.loai, SessionType.CHINH);
      expect(overview.recentAttendance.first.classEntity.tenLop, 'Vật lí 10');
    },
  );
}

class DummyTuitionPolicyRepository implements TuitionPolicyRepository {
  final Database db;
  DummyTuitionPolicyRepository(this.db);
  Database get dbInstance => db;
  @override
  Future<Set<int>> getClassIdsWithEffectivePolicyOnDate(
    List<int> ids,
    String date,
  ) async => {};
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class DummyTuitionRepository implements TuitionRepository {
  final Database db;
  DummyTuitionRepository(this.db);
  Database get dbInstance => db;
  @override
  Future<List<TuitionInvoice>> getInvoicesInMonthRange({
    required String fromMonth,
    required String toMonth,
    int? studentId,
    int? classId,
  }) async => [];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class DummyPaymentService implements PaymentService {
  final Database db;
  DummyPaymentService(this.db);
  @override
  Future<List<InvoicePaymentSummary>> getPaymentSummariesForInvoices(
    List<TuitionInvoice> invoices,
  ) async => [];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
