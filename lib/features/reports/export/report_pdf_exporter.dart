import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import '../domain/report_scope.dart';
import '../domain/report_summary.dart';
import 'report_pdf_service.dart';

abstract class ReportPdfExporter {
  Future<void> export(ReportSummary summary);
}

class DefaultReportPdfExporter implements ReportPdfExporter {
  final ReportPdfService _pdfService;

  DefaultReportPdfExporter([ReportPdfService? pdfService])
    : _pdfService = pdfService ?? ReportPdfService();

  @override
  Future<void> export(ReportSummary summary) async {
    final pdfBytes = await _pdfService.buildPdf(summary);
    final fileName = summary.scope.mode == ReportMode.month
        ? 'BaoCao_${summary.scope.fromDate.substring(0, 7)}.pdf'
        : 'BaoCao_${summary.scope.fromDate}_${summary.scope.toDate}.pdf';

    await Printing.layoutPdf(
      onLayout: (format) async => pdfBytes,
      name: fileName,
    );
  }
}

final reportPdfExporterProvider = Provider<ReportPdfExporter>((ref) {
  return DefaultReportPdfExporter();
});
