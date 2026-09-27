import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../app/common_widgets/navy_components.dart';
import '../../../app/design_system/app_theme.dart';
import '../../../app/navigation/app_global_drawer.dart';
import '../../../core/utils/date_formatter.dart';
import '../domain/report_scope.dart';
import '../domain/report_summary.dart';
import '../export/report_pdf_exporter.dart';
import 'report_controller.dart';
import 'report_filter_bottom_sheet.dart';

class ReportsPage extends ConsumerStatefulWidget {
  const ReportsPage({super.key});

  @override
  ConsumerState<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends ConsumerState<ReportsPage> {
  final currencyFormatter = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: 'đ',
    decimalDigits: 0,
  );
  bool _isExporting = false;

  Future<void> _exportPdf(BuildContext context, ReportSummary summary) async {
    if (_isExporting) return;

    setState(() {
      _isExporting = true;
    });

    try {
      final exporter = ref.read(reportPdfExporterProvider);
      await exporter.export(summary);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi xuất PDF: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scope = ref.watch(reportScopeNotifierProvider);
    final summaryAsync = ref.watch(reportSummaryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const AppGlobalDrawer(),
      appBar: AppBar(
        leading: const GlobalMenuButton(),
        title: const Text('Báo cáo thống kê'),
        actions: [
          summaryAsync.when(
            data: (summary) => IconButton(
              icon: _isExporting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(
                      Icons.picture_as_pdf_outlined,
                      color: AppColors.cyanAccent,
                    ),
              onPressed: _isExporting
                  ? null
                  : () => _exportPdf(context, summary),
              tooltip: _isExporting ? 'Đang xuất PDF...' : 'Xuất báo cáo PDF',
            ),
            loading: () => const IconButton(
              icon: Icon(
                Icons.picture_as_pdf_outlined,
                color: AppColors.textMuted,
              ),
              onPressed: null,
            ),
            error: (_, __) => const IconButton(
              icon: Icon(
                Icons.picture_as_pdf_outlined,
                color: AppColors.textMuted,
              ),
              onPressed: null,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
            onPressed: () => ref.invalidate(reportSummaryProvider),
            tooltip: 'Làm mới báo cáo',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCompactFilterBar(context, scope),
            const SizedBox(height: 16),
            summaryAsync.when(
              data: (summary) => _buildReportContent(context, summary),
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(40.0),
                  child: Column(
                    children: [
                      CircularProgressIndicator(color: AppColors.primary),
                      SizedBox(height: 12),
                      Text(
                        'Đang tổng hợp báo cáo...',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
              error: (err, stack) => AppSectionCard(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.error),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Lỗi tải báo cáo: $err',
                          style: const TextStyle(color: AppColors.error),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => ref.invalidate(reportSummaryProvider),
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactFilterBar(BuildContext context, ReportScope scope) {
    String scopeText;
    if (scope.mode == ReportMode.month) {
      final parts = scope.fromDate.split('-');
      scopeText =
          'Tháng ${parts.length >= 2 ? "${parts[1]}/${parts[0]}" : scope.fromDate}';
    } else {
      final fromDisplay = DateFormatter.formatDisplayDate(scope.fromDate);
      final toDisplay = DateFormatter.formatDisplayDate(scope.toDate);
      scopeText = '$fromDisplay - $toDisplay';
    }

    return AppSectionCard(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
      child: Row(
        children: [
          const Icon(
            Icons.calendar_month_outlined,
            size: 20,
            color: AppColors.cyanAccent,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  scopeText,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (scope.classId != null || scope.studentId != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2.0),
                    child: Text(
                      [
                        if (scope.classId != null) 'Đã lọc lớp',
                        if (scope.studentId != null) 'Đã lọc học sinh',
                      ].join(' • '),
                      style: const TextStyle(
                        color: AppColors.cyanAccent,
                        fontSize: 11,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          ElevatedButton.icon(
            key: const Key('open_report_filter_btn'),
            icon: const Icon(Icons.tune, size: 16),
            label: const Text('Bộ lọc'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.surfaceHigh,
              foregroundColor: AppColors.textPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
            onPressed: () => ReportFilterBottomSheet.show(context),
          ),
        ],
      ),
    );
  }

  Widget _buildReportContent(BuildContext context, ReportSummary summary) {
    if (summary.isEmpty) {
      return const AppSectionCard(
        padding: EdgeInsets.all(32.0),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.bar_chart_outlined,
                size: 48,
                color: AppColors.textMuted,
              ),
              SizedBox(height: 12),
              Text(
                'Chưa có dữ liệu báo cáo trong khoảng thời gian đã chọn.',
                style: TextStyle(fontSize: 14, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Phone 2x2 KPI Grid
        Row(
          children: [
            Expanded(
              child: AppMetricCard(
                title: 'Tỷ lệ đi học',
                value:
                    '${summary.attendance.attendanceRatePercentage.toStringAsFixed(1)}%',
                subtitle:
                    '${summary.attendance.totalPresent}/${summary.attendance.totalEligibleParticipations} lượt',
                valueColor: AppColors.success,
                icon: Icons.check_circle_outline,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: AppMetricCard(
                title: 'Học phí đã chốt',
                value: currencyFormatter.format(
                  summary.financial.totalInvoiced,
                ),
                subtitle: 'Hóa đơn trong kỳ',
                valueColor: AppColors.cyanAccent,
                icon: Icons.receipt_long_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: AppMetricCard(
                title: 'Thực nhận',
                value: currencyFormatter.format(summary.financial.totalPaid),
                subtitle: 'Đã thu tiền',
                valueColor: AppColors.success,
                icon: Icons.payments_outlined,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: AppMetricCard(
                title: 'Còn nợ',
                value: currencyFormatter.format(
                  summary.financial.totalOutstandingDebt,
                ),
                subtitle: 'Cần thu thêm',
                valueColor: summary.financial.totalOutstandingDebt > 0
                    ? AppColors.error
                    : AppColors.textMuted,
                icon: Icons.account_balance_wallet_outlined,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // SECTION A: ĐIỂM DANH
        const AppSectionHeader(title: 'A. ĐIỂM DANH THỐNG KÊ'),
        AppSectionCard(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Tỷ lệ đi học tổng thể',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    '${summary.attendance.attendanceRatePercentage.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: summary.attendance.attendanceRatePercentage / 100,
                  minHeight: 8,
                  backgroundColor: AppColors.surfaceHigh,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.success,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _buildSubMetric(
                      'Có mặt',
                      '${summary.attendance.totalPresent}',
                      AppColors.success,
                    ),
                  ),
                  Expanded(
                    child: _buildSubMetric(
                      'Đi trễ',
                      '${summary.attendance.totalLate}',
                      AppColors.warning,
                    ),
                  ),
                  Expanded(
                    child: _buildSubMetric(
                      'Có phép',
                      '${summary.attendance.totalExcusedAbsence}',
                      AppColors.cyanAccent,
                    ),
                  ),
                  Expanded(
                    child: _buildSubMetric(
                      'Không phép',
                      '${summary.attendance.totalUnexcusedAbsence}',
                      AppColors.error,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // SECTION B: HỌC PHÍ
        const AppSectionHeader(title: 'B. TỔNG HỢP HỌC PHÍ'),
        AppSectionCard(
          child: Row(
            children: [
              Expanded(
                child: _buildSubMetric(
                  'Hóa đơn chốt',
                  currencyFormatter.format(summary.financial.totalInvoiced),
                  AppColors.cyanAccent,
                ),
              ),
              Expanded(
                child: _buildSubMetric(
                  'Thực nhận',
                  currencyFormatter.format(summary.financial.totalPaid),
                  AppColors.success,
                ),
              ),
              Expanded(
                child: _buildSubMetric(
                  'Dư nợ',
                  currencyFormatter.format(
                    summary.financial.totalOutstandingDebt,
                  ),
                  summary.financial.totalOutstandingDebt > 0
                      ? AppColors.error
                      : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // SECTION C: BUỔI HỌC
        const AppSectionHeader(title: 'C. TỔNG HỢP BUỔI HỌC'),
        AppSectionCard(
          child: Row(
            children: [
              Expanded(
                child: _buildSubMetric(
                  'Tổng số buổi',
                  '${summary.attendance.totalSessions}',
                  AppColors.primary,
                ),
              ),
              Expanded(
                child: _buildSubMetric(
                  'Tổng lượt học',
                  '${summary.attendance.totalEligibleParticipations}',
                  AppColors.cyanAccent,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubMetric(String label, String value, Color color) {
    return Column(
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
