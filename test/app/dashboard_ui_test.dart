import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tuition2027/app/navigation/ui_keys.dart';
import 'package:tuition2027/features/dashboard/domain/dashboard_overview.dart';
import 'package:tuition2027/features/dashboard/presentation/dashboard_controller.dart';
import 'package:tuition2027/features/dashboard/presentation/dashboard_page.dart';
import 'package:tuition2027/features/sessions/domain/class_session.dart';
import '../test_helper.dart';

class MockDashboardController extends DashboardController {
  final DashboardOverview mockOverview;
  MockDashboardController(this.mockOverview);

  @override
  FutureOr<DashboardOverview> build() => mockOverview;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  final now = DateTime.now();

  final sampleOverview = DashboardOverview(
    generatedAt: now,
    todaySessionCount: 4,
    pendingAttendanceCount: 2,
    unfinalizedTuitionStudentCount: 8,
    outstandingDebt: 2350000,
    todaySessions: [
      DashboardTodaySession(
        session: ClassSession(
          id: 101,
          idLop: 1,
          ngay: '2026-09-28',
          gioBatDau: '14:00',
          gioKetThuc: '15:30',
          loai: SessionType.CHINH,
          trangThai: SessionStatus.DA_HOC,
          createdAt: now,
          updatedAt: now,
        ),
        className: 'Lớp 10A3',
      ),
      DashboardTodaySession(
        session: ClassSession(
          id: 102,
          idLop: 2,
          ngay: '2026-09-28',
          gioBatDau: '17:30',
          gioKetThuc: '19:00',
          loai: SessionType.CHINH,
          trangThai: SessionStatus.DU_KIEN,
          createdAt: now,
          updatedAt: now,
        ),
        className: 'Lớp 11A1',
      ),
    ],
    tasks: [
      DashboardTask(
        type: DashboardTaskType.attendanceNow,
        title: 'Điểm danh ngay',
        subtitle: '2 buổi cần điểm danh',
      ),
      DashboardTask(
        type: DashboardTaskType.generateSessions,
        title: 'Sinh buổi học',
        subtitle: 'Tạo buổi từ lịch học định kỳ',
      ),
      DashboardTask(
        type: DashboardTaskType.finalizeTuition,
        title: 'Chốt học phí tháng',
        subtitle: 'Tháng 09/2026 • 8 lượt chưa chốt',
      ),
      DashboardTask(
        type: DashboardTaskType.exportReportPdf,
        title: 'Xuất báo cáo PDF',
        subtitle: 'Báo cáo học phí & điểm danh',
      ),
    ],
    warnings: [
      DashboardWarning(
        type: DashboardWarningType.unassignedStudents,
        title: 'Học sinh chưa phân ca',
        description: '5 học sinh chưa phân ca',
        count: 5,
      ),
    ],
    recentActivities: [
      DashboardActivity(
        type: DashboardActivityType.paymentRecorded,
        title: 'Đã thu 500.000đ',
        subtitle: 'Phụ huynh/Học sinh: Nguyễn Minh Anh',
        timestamp: now,
      ),
    ],
  );

  group('Phase 14B.3 Business-First Dashboard UI Tests', () {
    testWidgets(
      'DashboardPage renders greeting, 4 KPIs, business tasks, schedule & warnings',
      (tester) async {
        await tester.pumpWidget(
          createTestApp(
            home: const DashboardPage(),
            overrides: [
              dashboardControllerProvider.overrideWith(
                () => MockDashboardController(sampleOverview),
              ),
            ],
          ),
        );

        await tester.pumpAndSettle();

        // Greeting & Header
        expect(find.text('Chào thầy cô!'), findsOneWidget);
        expect(find.text('Trang chủ'), findsOneWidget);

        // 4 KPIs
        expect(find.text('Buổi hôm nay'), findsOneWidget);
        expect(find.text('4'), findsOneWidget);

        expect(find.text('Cần điểm danh'), findsAtLeast(1));
        expect(find.text('2'), findsOneWidget);

        expect(find.text('Chưa chốt học phí'), findsOneWidget);
        expect(find.text('8'), findsOneWidget);

        expect(find.text('Nợ cần xử lý'), findsOneWidget);
        expect(find.textContaining('2.350.000'), findsOneWidget);

        // Business Quick Actions (Tasks) - NO duplicate navigation shortcuts for Student/Class/Tuition
        expect(find.text('Việc cần làm hôm nay'), findsOneWidget);
        expect(find.byKey(UiKeys.dashboardQuickAddStudent), findsOneWidget);
        expect(find.byKey(UiKeys.dashboardQuickManageClasses), findsOneWidget);
        expect(find.byKey(UiKeys.dashboardQuickViewTuition), findsOneWidget);
        expect(find.byKey(UiKeys.dashboardQuickViewReports), findsOneWidget);

        expect(find.text('Điểm danh ngay'), findsOneWidget);
        expect(find.text('Sinh buổi học'), findsOneWidget);
        expect(find.text('Chốt học phí tháng'), findsOneWidget);
        expect(find.text('Xuất báo cáo PDF'), findsOneWidget);

        // Schedule timeline
        expect(find.text('Lớp 10A3'), findsOneWidget);
        expect(find.text('Lớp 11A1'), findsOneWidget);

        // Warnings
        expect(find.text('5 học sinh chưa phân ca'), findsOneWidget);
      },
    );

    testWidgets(
      'DashboardPage does NOT render global search input or duplicate navigation quick actions',
      (tester) async {
        await tester.pumpWidget(
          createTestApp(
            home: const DashboardPage(),
            overrides: [
              dashboardControllerProvider.overrideWith(
                () => MockDashboardController(sampleOverview),
              ),
            ],
          ),
        );

        await tester.pumpAndSettle();

        // Search bar removed from Homepage
        expect(find.byKey(UiKeys.dashboardSearchInput), findsNothing);

        // Verify quick action tiles represent Business Tasks, not navigation menu entries
        expect(find.text('Điểm danh ngay'), findsOneWidget);
        expect(find.text('Sinh buổi học'), findsOneWidget);
      },
    );
  });
}
