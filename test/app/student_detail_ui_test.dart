import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuition2027/app/design_system/app_theme.dart';
import 'package:tuition2027/features/attendance/domain/attendance_record.dart';
import 'package:tuition2027/features/classes/domain/class.dart';
import 'package:tuition2027/features/memberships/domain/membership.dart';
import 'package:tuition2027/features/sessions/domain/class_session.dart';
import 'package:tuition2027/features/students/domain/student.dart';
import 'package:tuition2027/features/students/domain/student_detail_overview.dart';
import 'package:tuition2027/features/students/domain/student_detail_overview_service.dart';
import 'package:tuition2027/features/students/presentation/student_detail_page.dart';
import 'package:tuition2027/l10n/app_localizations.dart';

void main() {
  final now = DateTime.now();

  final student = Student(
    id: 1,
    hoTen: 'Bùi Gia An',
    sdtPhuHuynh: '0962345678',
    gioiTinh: 'NAM',
    createdAt: now,
    updatedAt: now,
  );

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

  final overview = StudentDetailOverview(
    student: student,
    activeClasses: [
      StudentActiveClassSummary(
        classEntity: classEntity1,
        membership: ClassMembership(
          id: 100,
          idHocSinh: 1,
          idLop: 10,
          tuNgay: '2026-09-08',
          createdAt: now,
          updatedAt: now,
        ),
        shiftText: '17:30–19:00 • Thứ 3,5',
      ),
      StudentActiveClassSummary(
        classEntity: classEntity2,
        membership: ClassMembership(
          id: 101,
          idHocSinh: 1,
          idLop: 20,
          tuNgay: '2026-09-08',
          createdAt: now,
          updatedAt: now,
        ),
        shiftText: '19:30–21:00 • Thứ 2,6',
      ),
    ],
    firstActiveMembershipDate: DateTime(2026, 9, 8),
    financial: const StudentMonthFinancialSummary(
      month: '2026-09',
      finalizedDue: 2350000,
      totalPaid: 1900000,
      remainingDebt: 450000,
      finalizedInvoiceCount: 2,
      unfinalizedClassCount: 0,
      previewUnfinalizedAmount: 0,
      state: StudentFinancialDisplayState.partiallyPaid,
    ),
    recentAttendance: [
      StudentRecentAttendanceItem(
        attendance: AttendanceRecord(
          id: 1,
          idBuoiHoc: 1,
          idHocSinh: 1,
          idLopGoc: 10,
          trangThai: AttendanceStatus.CO_MAT,
          createdAt: now,
          updatedAt: now,
        ),
        session: ClassSession(
          id: 1,
          idLop: 10,
          ngay: '2026-09-28',
          gioBatDau: '17:30',
          gioKetThuc: '19:00',
          loai: SessionType.CHINH,
          trangThai: SessionStatus.DA_HOC,
          createdAt: now,
          updatedAt: now,
        ),
        classEntity: classEntity1,
      ),
    ],
    activeBusyTimes: [],
  );

  Widget createWidgetUnderTest() {
    return ProviderScope(
      overrides: [
        studentDetailOverviewProvider(1).overrideWith((ref) async => overview),
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
        home: const StudentDetailPage(studentId: 1),
      ),
    );
  }

  group('Phase 14B.4 Student Detail Business Dashboard UI Tests', () {
    testWidgets('Renders header, KPIs, business actions & financial summary', (
      tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Header
      expect(find.text('Bùi Gia An'), findsOneWidget);
      expect(find.text('0962345678 (PH)'), findsOneWidget);
      expect(find.textContaining('Tham gia từ: 08/09/2026'), findsOneWidget);

      // KPIs
      expect(find.text('2 lớp đang tham gia'), findsOneWidget);
      expect(find.textContaining('450.000'), findsAtLeast(1));

      // 4 Business Actions
      expect(find.text('Sửa hồ sơ'), findsOneWidget);
      expect(find.text('Thêm vào lớp'), findsOneWidget);
      expect(find.text('Giờ bận'), findsWidgets);
      expect(find.text('Ghi nhận thu'), findsOneWidget);

      // Active Classes Section
      expect(find.text('Lớp 11A1'), findsAtLeast(1));
      expect(find.text('Lớp 12A2'), findsOneWidget);

      // Current Month Tuition
      expect(find.textContaining('2.350.000'), findsOneWidget);
      expect(find.textContaining('1.900.000'), findsOneWidget);
      expect(find.textContaining('450.000'), findsAtLeast(1));

      // Attendance status - ICON ONLY (no visible text "Có mặt" in compact row)
      // Check Tooltip message exists for accessibility
      expect(find.byTooltip('Có mặt'), findsOneWidget);
    });
  });
}
