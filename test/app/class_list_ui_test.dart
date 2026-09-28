import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuition2027/app/design_system/app_theme.dart';
import 'package:tuition2027/features/classes/domain/class.dart';
import 'package:tuition2027/features/classes/domain/class_filter.dart';
import 'package:tuition2027/features/classes/domain/class_list_overview.dart';
import 'package:tuition2027/features/classes/presentation/class_list_overview_controller.dart';
import 'package:tuition2027/features/classes/presentation/class_list_page.dart';
import 'package:tuition2027/features/sessions/domain/class_session.dart';
import 'package:tuition2027/l10n/app_localizations.dart';

void main() {
  final now = DateTime.now();

  final classEntity1 = ClassEntity(
    id: 10,
    tenLop: 'Lớp 11A1',
    daLuuTru: false,
    createdAt: now,
    updatedAt: now,
  );

  final classEntity2 = ClassEntity(
    id: 20,
    tenLop: 'Lớp 12A2',
    daLuuTru: false,
    createdAt: now,
    updatedAt: now,
  );

  final overview = ClassListOverview(
    filter: ClassFilter.active,
    activeClassCount: 12,
    todaySessionCount: 5,
    pendingAttendanceCount: 3,
    missingTuitionPolicyCount: 2,
    rows: [
      ClassOperationalRow(
        classEntity: classEntity1,
        activeStudentCount: 28,
        scheduleText: 'Thứ 3,5 • 17:30–19:00',
        status: ClassOperationalStatus.needsAttendance,
        secondaryStatusText: 'Hôm nay 17:30',
        currentMonthDebt: 0,
        missingTuitionPolicy: false,
        todaySession: ClassSession(
          id: 1,
          idLop: 10,
          ngay: '2026-09-28',
          gioBatDau: '17:30',
          gioKetThuc: '19:00',
          loai: SessionType.CHINH,
          trangThai: SessionStatus.DU_KIEN,
          createdAt: now,
          updatedAt: now,
        ),
      ),
      ClassOperationalRow(
        classEntity: classEntity2,
        activeStudentCount: 30,
        scheduleText: 'Thứ 2,6 • 19:30–21:00',
        status: ClassOperationalStatus.completedToday,
        secondaryStatusText: 'Buổi gần nhất 28/09',
        currentMonthDebt: 0,
        missingTuitionPolicy: false,
      ),
    ],
    warnings: const [
      ClassOperationalWarning(
        type: ClassWarningType.overdueAttendance,
        message: '3 buổi quá giờ cần điểm danh',
        count: 3,
      ),
      ClassOperationalWarning(
        type: ClassWarningType.missingTuitionPolicy,
        message: '2 lớp chưa thiết lập học phí',
        count: 2,
      ),
    ],
  );

  Widget createWidgetUnderTest() {
    return ProviderScope(
      overrides: [
        classListOverviewControllerProvider.overrideWith(
          () => _FakeOverviewController(overview),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('vi')],
        home: const ClassListPage(),
      ),
    );
  }

  group('Phase 14B.5 Class Dashboard UI Tests', () {
    testWidgets('Renders AppBar, 2-state toggle, 4 KPIs, cards & warnings without search bar', (
      tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Search bar must be COMPLETELY REMOVED
      expect(find.byType(TextField), findsNothing);

      // AppBar
      expect(find.text('Lớp học'), findsOneWidget);
      expect(find.byIcon(Icons.add_rounded), findsOneWidget);

      // 2-State Filter Toggle (No "Tất cả")
      expect(find.text('Đang hoạt động'), findsWidgets);
      expect(find.text('Ngừng hoạt động'), findsWidgets);
      expect(find.text('Tất cả'), findsNothing);

      // 4 KPIs
      expect(find.text('12'), findsOneWidget); // Active classes
      expect(find.text('5'), findsOneWidget); // Today sessions
      expect(find.text('3'), findsAtLeast(1)); // Needs attendance
      expect(find.text('2'), findsAtLeast(1)); // Missing tuition

      // Class cards
      expect(find.text('Lớp 11A1'), findsOneWidget);
      expect(find.text('Thứ 3,5 • 17:30–19:00'), findsOneWidget);
      expect(find.text('28 học sinh'), findsOneWidget);

      expect(find.text('Lớp 12A2'), findsOneWidget);
      expect(find.text('Thứ 2,6 • 19:30–21:00'), findsOneWidget);
      expect(find.text('30 học sinh'), findsOneWidget);

      // Warnings section
      expect(find.text('Cần xử lý'), findsOneWidget);
      expect(find.text('3 buổi quá giờ cần điểm danh'), findsOneWidget);
      expect(find.text('2 lớp chưa thiết lập học phí'), findsOneWidget);
    });
  });
}

class _FakeOverviewController extends ClassListOverviewController {
  final ClassListOverview _initialOverview;
  _FakeOverviewController(this._initialOverview);

  @override
  FutureOr<ClassListOverview> build() async {
    return _initialOverview;
  }
}
