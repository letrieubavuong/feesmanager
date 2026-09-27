import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuition2027/features/classes/domain/class.dart';
import 'package:tuition2027/features/classes/presentation/class_controller.dart';
import 'package:tuition2027/features/reports/domain/report_scope.dart';
import 'package:tuition2027/features/reports/domain/report_summary.dart';
import 'package:tuition2027/features/reports/presentation/report_controller.dart';
import 'package:tuition2027/features/reports/presentation/reports_page.dart';
import 'package:tuition2027/features/students/domain/student.dart';
import 'package:tuition2027/features/students/presentation/student_controller.dart';

void main() {
  group('Reports Phone UI Redesign Tests', () {
    testWidgets(
      'ReportsPage displays compact top filter bar and 2-column KPI grid',
      (tester) async {
        // Create test summary data
        final mockSummary = ReportSummary(
          scope: ReportScope.forMonth(month: '2026-09'),
          generatedAt: DateTime(2026, 9, 20),
          attendance: const AttendanceReportSummary(
            totalSessions: 12,
            totalEligibleParticipations: 40,
            totalPresent: 36,
            totalLate: 2,
            totalExcusedAbsence: 2,
            totalUnexcusedAbsence: 0,
            attendanceRatePercentage: 90.0,
          ),
          financial: const FinancialReportSummary(
            totalInvoiced: 5000000,
            totalPaid: 4000000,
            totalOutstandingDebt: 1000000,
          ),
          classSummaries: const [
            ClassReportSummary(
              classId: 10,
              className: 'Toán 10A',
              studentCountInScope: 5,
              attendance: AttendanceReportSummary(
                totalSessions: 12,
                totalEligibleParticipations: 40,
                totalPresent: 36,
                totalLate: 2,
                totalExcusedAbsence: 2,
                totalUnexcusedAbsence: 0,
                attendanceRatePercentage: 90.0,
              ),
              financial: FinancialReportSummary(
                totalInvoiced: 5000000,
                totalPaid: 4000000,
                totalOutstandingDebt: 1000000,
              ),
            ),
          ],
          studentSummaries: [],
        );

        final mockClasses = [
          ClassEntity(
            id: 10,
            tenLop: 'Toán 10A',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];

        final mockStudents = [
          Student(
            id: 1,
            hoTen: 'Nguyễn Văn A',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];

        // Set phone screen dimensions (e.g. 390 x 844)
        tester.view.physicalSize = const Size(390 * 3, 844 * 3);
        tester.view.devicePixelRatio = 3.0;

        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              reportSummaryProvider.overrideWith((ref) async => mockSummary),
              classListControllerProvider.overrideWith(
                () => ClassListControllerMock(mockClasses),
              ),
              studentListControllerProvider.overrideWith(
                () => StudentListControllerMock(mockStudents),
              ),
            ],
            child: const MaterialApp(home: ReportsPage()),
          ),
        );

        await tester.pumpAndSettle();

        // Verify AppBar Title & Actions
        expect(find.text('Báo cáo'), findsOneWidget);
        expect(find.byIcon(Icons.picture_as_pdf), findsOneWidget);
        expect(find.byIcon(Icons.refresh), findsOneWidget);

        // Verify Compact Filter Bar
        expect(find.text('Tháng 09/2026'), findsOneWidget);
        expect(find.byKey(const Key('open_report_filter_btn')), findsOneWidget);

        // Verify KPI Summary Grid
        expect(find.text('Tỷ lệ đi học'), findsOneWidget);
        expect(find.text('90.0%'), findsAtLeast(1)); // 36/40 = 90%
        expect(find.text('Học phí đã chốt'), findsAtLeast(1));
        expect(find.text('Thực nhận'), findsAtLeast(1));
        expect(find.text('Còn nợ'), findsAtLeast(1));

        // Verify Structured Sections
        expect(find.text('A. ĐIỂM DANH'), findsOneWidget);
        expect(find.text('B. HỌC PHÍ'), findsOneWidget);
        expect(find.text('C. BUỔI HỌC'), findsOneWidget);
        expect(find.text('D. CHI TIẾT THEO LỚP HỌC'), findsOneWidget);

        // Tap Filter button to open ReportFilterBottomSheet
        await tester.tap(find.byKey(const Key('open_report_filter_btn')));
        await tester.pumpAndSettle();

        expect(find.text('BỘ LỌC BÁO CÁO'), findsOneWidget);
        expect(find.text('Theo tháng'), findsOneWidget);
        expect(find.text('Khoảng ngày'), findsOneWidget);
        expect(
          find.byKey(const Key('apply_report_filter_btn')),
          findsOneWidget,
        );
      },
    );
  });
}

class ClassListControllerMock extends ClassListController {
  final List<ClassEntity> _classes;
  ClassListControllerMock(this._classes);

  @override
  Future<List<ClassEntity>> build() async => _classes;
}

class StudentListControllerMock extends StudentListController {
  final List<Student> _students;
  StudentListControllerMock(this._students);

  @override
  Future<List<Student>> build() async => _students;
}
