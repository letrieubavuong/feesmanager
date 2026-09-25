import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../domain/report_scope.dart';
import '../domain/report_summary.dart';

class ReportPdfService {
  static final _currencyFormatter = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: 'đ',
    decimalDigits: 0,
  );

  static final _dateFormatter = DateFormat('dd/MM/yyyy HH:mm');

  /// Build PDF document bytes from a canonical [ReportSummary].
  ///
  /// Optionally accepts [regularFontData] and [boldFontData] for offline unit testing
  /// without requiring Flutter's [rootBundle].
  Future<Uint8List> buildPdf(
    ReportSummary summary, {
    Uint8List? regularFontData,
    Uint8List? boldFontData,
  }) async {
    final pdf = pw.Document();

    // Load offline Vietnamese TTF fonts
    late pw.Font ttfRegular;
    late pw.Font ttfBold;

    if (regularFontData != null && boldFontData != null) {
      ttfRegular = pw.Font.ttf(ByteData.sublistView(regularFontData));
      ttfBold = pw.Font.ttf(ByteData.sublistView(boldFontData));
    } else {
      final regData = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
      final boldData = await rootBundle.load('assets/fonts/Roboto-Bold.ttf');
      ttfRegular = pw.Font.ttf(regData);
      ttfBold = pw.Font.ttf(boldData);
    }

    final theme = pw.ThemeData.withFont(
      base: ttfRegular,
      bold: ttfBold,
    );

    final scope = summary.scope;
    final scopeStr = scope.mode == ReportMode.month
        ? 'Tháng ${scope.fromDate.substring(0, 7)}'
        : '${scope.fromDate} đến ${scope.toDate}';

    pdf.addPage(
      pw.MultiPage(
        maxPages: 100,
        pageFormat: PdfPageFormat.a4.landscape,
        theme: theme,
        margin: const pw.EdgeInsets.all(24),
        header: (context) => _buildHeader(summary, scopeStr),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          pw.SizedBox(height: 8),
          _buildSummaryCards(summary),
          pw.SizedBox(height: 14),
          if (summary.classSummaries.isNotEmpty) ...[
            pw.Text(
              'TỔNG QUAN THEO LỚP HỌC',
              style: const pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue900,
              ),
            ),
            pw.SizedBox(height: 4),
            _buildClassTableWidget(summary),
            pw.SizedBox(height: 14),
          ],
          if (summary.studentSummaries.isNotEmpty) ...[
            pw.Text(
              'CHI TIẾT THEO HỌC SINH',
              style: const pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue900,
              ),
            ),
            pw.SizedBox(height: 4),
            _buildStudentTableWidget(summary),
          ],
        ],
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildHeader(ReportSummary summary, String scopeStr) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'BÁO CÁO QUẢN LÝ HỌC TẬP & HỌC PHÍ',
              style: const pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue800,
              ),
            ),
            pw.Text(
              'Tuition2027',
              style: const pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey700,
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          'Phạm vi: $scopeStr | Ngày xuất: ${_dateFormatter.format(summary.generatedAt)}',
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
        ),
        pw.Divider(thickness: 1, color: PdfColors.grey400),
      ],
    );
  }

  pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 8),
      child: pw.Text(
        'Trang ${context.pageNumber} / ${context.pagesCount}',
        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
      ),
    );
  }

  pw.Widget _buildSummaryCards(ReportSummary summary) {
    final att = summary.attendance;
    final fin = summary.financial;

    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: const pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _buildKpiItem(
            'Tỷ lệ đi học',
            '${att.attendanceRatePercentage.toStringAsFixed(1)}%',
          ),
          _buildKpiItem('Số buổi', '${att.totalSessions}'),
          _buildKpiItem('Lượt tham gia', '${att.totalEligibleParticipations}'),
          _buildKpiItem(
            'Học phí chốt',
            _currencyFormatter.format(fin.totalInvoiced),
          ),
          _buildKpiItem(
            'Doanh thu thực nhận',
            _currencyFormatter.format(fin.totalPaid),
          ),
          _buildKpiItem(
            'Dư nợ hiện tại',
            _currencyFormatter.format(fin.totalOutstandingDebt),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildKpiItem(String title, String value) {
    return pw.Column(
      children: [
        pw.Text(
          title,
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          value,
          style: const pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
        ),
      ],
    );
  }

  pw.Widget _buildClassTableWidget(ReportSummary summary) {
    final headers = [
      'Tên Lớp',
      'Số HS',
      'Số Buổi',
      'Lượt',
      'Có Mặt',
      'Trễ',
      'Có Phép',
      'Không Phép',
      'Tỷ Lệ',
      'Học Phí Chốt',
      'Đã Thu',
      'Dư Nợ',
    ];

    final data = summary.classSummaries.map((c) {
      final att = c.attendance;
      final fin = c.financial;
      return [
        c.className,
        '${c.studentCountInScope}',
        '${att.totalSessions}',
        '${att.totalEligibleParticipations}',
        '${att.totalPresent}',
        '${att.totalLate}',
        '${att.totalExcusedAbsence}',
        '${att.totalUnexcusedAbsence}',
        '${att.attendanceRatePercentage.toStringAsFixed(1)}%',
        _currencyFormatter.format(fin.totalInvoiced),
        _currencyFormatter.format(fin.totalPaid),
        _currencyFormatter.format(fin.totalOutstandingDebt),
      ];
    }).toList();

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: data,
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      headerStyle: const pw.TextStyle(
        fontSize: 8,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
      ),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blue700),
      cellStyle: const pw.TextStyle(fontSize: 7),
      cellAlignment: pw.Alignment.centerLeft,
      headerAlignment: pw.Alignment.centerLeft,
    );
  }

  pw.Widget _buildStudentTableWidget(ReportSummary summary) {
    final headers = [
      'Tên Học Sinh',
      'Lớp Tham Gia',
      'Số Buổi',
      'Lượt',
      'Có Mặt',
      'Trễ',
      'Có Phép',
      'Không Phép',
      'Tỷ Lệ',
      'Học Phí Chốt',
      'Đã Thu',
      'Dư Nợ',
    ];

    final data = summary.studentSummaries.map((s) {
      final att = s.attendance;
      final fin = s.financial;
      return [
        s.studentName,
        s.enrolledClassNames.join(', '),
        '${att.totalSessions}',
        '${att.totalEligibleParticipations}',
        '${att.totalPresent}',
        '${att.totalLate}',
        '${att.totalExcusedAbsence}',
        '${att.totalUnexcusedAbsence}',
        '${att.attendanceRatePercentage.toStringAsFixed(1)}%',
        _currencyFormatter.format(fin.totalInvoiced),
        _currencyFormatter.format(fin.totalPaid),
        _currencyFormatter.format(fin.totalOutstandingDebt),
      ];
    }).toList();

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: data,
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      headerStyle: const pw.TextStyle(
        fontSize: 8,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
      ),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
      cellStyle: const pw.TextStyle(fontSize: 7),
      cellAlignment: pw.Alignment.centerLeft,
      headerAlignment: pw.Alignment.centerLeft,
    );
  }
}
