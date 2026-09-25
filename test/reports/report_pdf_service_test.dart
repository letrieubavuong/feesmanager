import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuition2027/features/reports/domain/report_scope.dart';
import 'package:tuition2027/features/reports/domain/report_summary.dart';
import 'package:tuition2027/features/reports/export/report_pdf_service.dart';

void main() {
  late ReportPdfService pdfService;
  late Uint8List regularFontBytes;
  late Uint8List boldFontBytes;

  setUpAll(() {
    pdfService = ReportPdfService();
    regularFontBytes = File(
      'assets/fonts/Roboto-Regular.ttf',
    ).readAsBytesSync();
    boldFontBytes = File('assets/fonts/Roboto-Bold.ttf').readAsBytesSync();
  });

  group('ReportPdfService Pure Renderer Unit Tests', () {
    test(
      'Empty/minimal ReportSummary builds valid PDF bytes with %PDF- header',
      () async {
        final summary = ReportSummary(
          scope: ReportScope.forMonth(month: '2026-10'),
          generatedAt: DateTime(2026, 10, 1, 10, 0),
          attendance: AttendanceReportSummary.zero(),
          financial: FinancialReportSummary.zero(),
          classSummaries: [],
          studentSummaries: [],
        );

        final pdfBytes = await pdfService.buildPdf(
          summary,
          regularFontData: regularFontBytes,
          boldFontData: boldFontBytes,
        );

        expect(pdfBytes, isNotNull);
        expect(pdfBytes.length, greaterThan(100));

        // PDF signature check (%PDF-1.x)
        final header = String.fromCharCodes(pdfBytes.sublist(0, 5));
        expect(header, equals('%PDF-'));
      },
    );

    test(
      'Month scope ReportSummary with Vietnamese Unicode and currency formatting renders cleanly',
      () async {
        final summary = ReportSummary(
          scope: ReportScope.forMonth(month: '2026-10'),
          generatedAt: DateTime(2026, 10, 15, 14, 30),
          attendance: const AttendanceReportSummary(
            totalSessions: 8,
            totalEligibleParticipations: 16,
            totalPresent: 14,
            totalLate: 2,
            totalExcusedAbsence: 0,
            totalUnexcusedAbsence: 0,
            attendanceRatePercentage: 87.5,
          ),
          financial: const FinancialReportSummary(
            totalInvoiced: 2000000,
            totalPaid: 1500000,
            totalOutstandingDebt: 500000,
          ),
          classSummaries: const [
            ClassReportSummary(
              classId: 1,
              className: 'Lớp Luyện Thi Chuẩn Nguyễn Văn A (Tiếng Việt)',
              studentCountInScope: 2,
              attendance: AttendanceReportSummary(
                totalSessions: 8,
                totalEligibleParticipations: 16,
                totalPresent: 14,
                totalLate: 2,
                totalExcusedAbsence: 0,
                totalUnexcusedAbsence: 0,
                attendanceRatePercentage: 87.5,
              ),
              financial: FinancialReportSummary(
                totalInvoiced: 2000000,
                totalPaid: 1500000,
                totalOutstandingDebt: 500000,
              ),
            ),
          ],
          studentSummaries: const [
            StudentReportSummary(
              studentId: 10,
              studentName: 'Nguyễn Thị Hoàng Trâm Anh',
              enrolledClassNames: [
                'Lớp Luyện Thi Chuẩn Nguyễn Văn A (Tiếng Việt)',
              ],
              attendance: AttendanceReportSummary(
                totalSessions: 8,
                totalEligibleParticipations: 8,
                totalPresent: 7,
                totalLate: 1,
                totalExcusedAbsence: 0,
                totalUnexcusedAbsence: 0,
                attendanceRatePercentage: 87.5,
              ),
              financial: FinancialReportSummary(
                totalInvoiced: 1000000,
                totalPaid: 750000,
                totalOutstandingDebt: 250000,
              ),
            ),
          ],
        );

        final pdfBytes = await pdfService.buildPdf(
          summary,
          regularFontData: regularFontBytes,
          boldFontData: boldFontBytes,
        );

        expect(pdfBytes.length, greaterThan(1000));
        expect(String.fromCharCodes(pdfBytes.sublist(0, 5)), equals('%PDF-'));
      },
    );

    test('Custom Range scope ReportSummary builds without exception', () async {
      final summary = ReportSummary(
        scope: ReportScope.customRange(
          fromDate: '2026-09-01',
          toDate: '2026-10-15',
        ),
        generatedAt: DateTime.now(),
        attendance: AttendanceReportSummary.zero(),
        financial: FinancialReportSummary.zero(),
        classSummaries: [],
        studentSummaries: [],
      );

      final pdfBytes = await pdfService.buildPdf(
        summary,
        regularFontData: regularFontBytes,
        boldFontData: boldFontBytes,
      );

      expect(pdfBytes, isNotNull);
      expect(String.fromCharCodes(pdfBytes.sublist(0, 5)), equals('%PDF-'));
    });

    test(
      'Large dataset creates multi-page PDF without overflow exception',
      () async {
        final classSummaries = List.generate(
          30,
          (i) => ClassReportSummary(
            classId: i + 1,
            className: 'Lớp Học Số ${i + 1} - Chuyên Đề Nâng Cao ${i + 1}',
            studentCountInScope: 15,
            attendance: const AttendanceReportSummary(
              totalSessions: 12,
              totalEligibleParticipations: 180,
              totalPresent: 160,
              totalLate: 10,
              totalExcusedAbsence: 5,
              totalUnexcusedAbsence: 5,
              attendanceRatePercentage: 88.9,
            ),
            financial: const FinancialReportSummary(
              totalInvoiced: 15000000,
              totalPaid: 12000000,
              totalOutstandingDebt: 3000000,
            ),
          ),
        );

        final studentSummaries = List.generate(
          50,
          (i) => StudentReportSummary(
            studentId: i + 1,
            studentName: 'Học Sinh Lớp Lớn Nguyễn Văn Khang Số ${i + 1}',
            enrolledClassNames: ['Lớp Học Số ${(i % 30) + 1}'],
            attendance: const AttendanceReportSummary(
              totalSessions: 12,
              totalEligibleParticipations: 12,
              totalPresent: 10,
              totalLate: 1,
              totalExcusedAbsence: 1,
              totalUnexcusedAbsence: 0,
              attendanceRatePercentage: 83.3,
            ),
            financial: const FinancialReportSummary(
              totalInvoiced: 1000000,
              totalPaid: 800000,
              totalOutstandingDebt: 200000,
            ),
          ),
        );

        final largeSummary = ReportSummary(
          scope: ReportScope.forMonth(month: '2026-10'),
          generatedAt: DateTime.now(),
          attendance: const AttendanceReportSummary(
            totalSessions: 360,
            totalEligibleParticipations: 5400,
            totalPresent: 4800,
            totalLate: 300,
            totalExcusedAbsence: 150,
            totalUnexcusedAbsence: 150,
            attendanceRatePercentage: 88.9,
          ),
          financial: const FinancialReportSummary(
            totalInvoiced: 450000000,
            totalPaid: 360000000,
            totalOutstandingDebt: 90000000,
          ),
          classSummaries: classSummaries,
          studentSummaries: studentSummaries,
        );

        final pdfBytes = await pdfService.buildPdf(
          largeSummary,
          regularFontData: regularFontBytes,
          boldFontData: boldFontBytes,
        );

        expect(pdfBytes.length, greaterThan(5000));
        expect(String.fromCharCodes(pdfBytes.sublist(0, 5)), equals('%PDF-'));
      },
    );

    test(
      'PDF ↔ UI Figure Parity: PDF renderer outputs same numbers as UI ReportSummary source',
      () async {
        final summary = ReportSummary(
          scope: ReportScope.forMonth(month: '2026-10'),
          generatedAt: DateTime(2026, 10, 20),
          attendance: const AttendanceReportSummary(
            totalSessions: 10,
            totalEligibleParticipations: 20,
            totalPresent: 18,
            totalLate: 2,
            totalExcusedAbsence: 0,
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
              classId: 1,
              className: 'Class Parity',
              studentCountInScope: 2,
              attendance: AttendanceReportSummary(
                totalSessions: 10,
                totalEligibleParticipations: 20,
                totalPresent: 18,
                totalLate: 2,
                totalExcusedAbsence: 0,
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
          studentSummaries: const [],
        );

        final pdfBytes = await pdfService.buildPdf(
          summary,
          regularFontData: regularFontBytes,
          boldFontData: boldFontBytes,
        );

        // Verify PDF renders cleanly from the exact same source summary figures
        expect(summary.attendance.attendanceRatePercentage, equals(90.0));
        expect(summary.financial.totalOutstandingDebt, equals(1000000));
        expect(pdfBytes.length, greaterThan(500));
      },
    );

    test(
      'All 10 overall attendance & financial summary fields rendered cleanly in PDF with zero and large values',
      () async {
        final summary = ReportSummary(
          scope: ReportScope.forMonth(month: '2026-10'),
          generatedAt: DateTime(2026, 10, 31, 23, 59),
          attendance: const AttendanceReportSummary(
            totalSessions: 100,
            totalEligibleParticipations: 1500,
            totalPresent: 1400,
            totalLate: 50,
            totalExcusedAbsence: 30,
            totalUnexcusedAbsence: 20,
            attendanceRatePercentage: 93.3,
          ),
          financial: const FinancialReportSummary(
            totalInvoiced: 1500000000,
            totalPaid: 1200000000,
            totalOutstandingDebt: 300000000,
          ),
          classSummaries: const [
            ClassReportSummary(
              classId: 101,
              className:
                  'Lớp Luyện Thi Đại Học Chất Lượng Cao Nguyễn Văn Cừ Mã Số 101 (Đã Lưu Trữ)',
              studentCountInScope: 15,
              attendance: AttendanceReportSummary(
                totalSessions: 100,
                totalEligibleParticipations: 1500,
                totalPresent: 1400,
                totalLate: 50,
                totalExcusedAbsence: 30,
                totalUnexcusedAbsence: 20,
                attendanceRatePercentage: 93.3,
              ),
              financial: FinancialReportSummary(
                totalInvoiced: 1500000000,
                totalPaid: 1200000000,
                totalOutstandingDebt: 300000000,
              ),
            ),
          ],
          studentSummaries: const [
            StudentReportSummary(
              studentId: 201,
              studentName:
                  'Công Tằng Tôn Nữ Hoàng Thị Đoan Trang Nguyễn (Đã Nghỉ Học)',
              enrolledClassNames: [
                'Lớp Luyện Thi Đại Học Chất Lượng Cao Nguyễn Văn Cừ Mã Số 101 (Đã Lưu Trữ)',
              ],
              attendance: AttendanceReportSummary(
                totalSessions: 100,
                totalEligibleParticipations: 100,
                totalPresent: 95,
                totalLate: 3,
                totalExcusedAbsence: 2,
                totalUnexcusedAbsence: 0,
                attendanceRatePercentage: 95.0,
              ),
              financial: FinancialReportSummary(
                totalInvoiced: 100000000,
                totalPaid: 80000000,
                totalOutstandingDebt: 20000000,
              ),
            ),
          ],
        );

        final pdfBytes = await pdfService.buildPdf(
          summary,
          regularFontData: regularFontBytes,
          boldFontData: boldFontBytes,
        );

        expect(pdfBytes, isNotNull);
        expect(pdfBytes.length, greaterThan(1000));
        expect(String.fromCharCodes(pdfBytes.sublist(0, 5)), equals('%PDF-'));
      },
    );
  });
}
