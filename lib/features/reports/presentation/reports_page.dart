import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../app/common_widgets/navy_components.dart';
import '../../../app/design_system/app_theme.dart';
import '../../../app/navigation/app_global_drawer.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context)!;
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
            content: Text(l10n.reportsExportPdfError(e.toString())),
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
    final l10n = AppLocalizations.of(context)!;
    final scope = ref.watch(reportScopeNotifierProvider);
    final summaryAsync = ref.watch(reportSummaryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const AppGlobalDrawer(),
      appBar: AppBar(
        leading: const GlobalMenuButton(),
        title: Text(l10n.reportsTitle),
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
              tooltip: l10n.reportsExportPdf,
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
            tooltip: l10n.commonRetry,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCompactFilterBar(context, scope, l10n),
            const SizedBox(height: 16),
            summaryAsync.when(
              data: (summary) => _buildReportContent(context, summary, l10n),
              loading: () => Center(
                child: Padding(
                  padding: const EdgeInsets.all(40.0),
                  child: Column(
                    children: [
                      const CircularProgressIndicator(color: AppColors.primary),
                      const SizedBox(height: 12),
                      Text(
                        l10n.commonLoading,
                        style: const TextStyle(color: AppColors.textSecondary),
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
                          '${l10n.commonError}: $err',
                          style: const TextStyle(color: AppColors.error),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => ref.invalidate(reportSummaryProvider),
                        child: Text(l10n.commonRetry),
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

  Widget _buildCompactFilterBar(
    BuildContext context,
    ReportScope scope,
    AppLocalizations l10n,
  ) {
    String scopeText;
    if (scope.mode == ReportMode.month) {
      final parts = scope.fromDate.split('-');
      scopeText =
          '${l10n.reportsModeMonth} ${parts.length >= 2 ? "${parts[1]}/${parts[0]}" : scope.fromDate}';
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
                        if (scope.classId != null) l10n.reportsFilteredClass,
                        if (scope.studentId != null)
                          l10n.reportsFilteredStudent,
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
            label: Text(l10n.reportsFilterTitle),
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

  Widget _buildReportContent(
    BuildContext context,
    ReportSummary summary,
    AppLocalizations l10n,
  ) {
    if (summary.isEmpty) {
      return AppSectionCard(
        padding: const EdgeInsets.all(32.0),
        child: Center(
          child: Column(
            children: [
              const Icon(
                Icons.bar_chart_outlined,
                size: 48,
                color: AppColors.textMuted,
              ),
              const SizedBox(height: 12),
              Text(
                l10n.reportsNoData,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textMuted,
                ),
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
                title: l10n.reportsKpiAttendanceRate,
                value:
                    '${summary.attendance.attendanceRatePercentage.toStringAsFixed(1)}%',
                subtitle:
                    '${summary.attendance.totalPresent}/${summary.attendance.totalEligibleParticipations}',
                valueColor: AppColors.success,
                icon: Icons.check_circle_outline,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: AppMetricCard(
                title: l10n.reportsKpiInvoiced,
                value: currencyFormatter.format(
                  summary.financial.totalInvoiced,
                ),
                subtitle: '',
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
                title: l10n.reportsKpiPaid,
                value: currencyFormatter.format(summary.financial.totalPaid),
                subtitle: '',
                valueColor: AppColors.success,
                icon: Icons.payments_outlined,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: AppMetricCard(
                title: l10n.reportsKpiOutstanding,
                value: currencyFormatter.format(
                  summary.financial.totalOutstandingDebt,
                ),
                subtitle: '',
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
        AppSectionHeader(title: l10n.reportsSectionAttendance),
        AppSectionCard(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      l10n.reportsAttendanceOverallRate,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
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
                      l10n.reportsAttendancePresent,
                      '${summary.attendance.totalPresent}',
                      AppColors.success,
                    ),
                  ),
                  Expanded(
                    child: _buildSubMetric(
                      l10n.reportsAttendanceLate,
                      '${summary.attendance.totalLate}',
                      AppColors.warning,
                    ),
                  ),
                  Expanded(
                    child: _buildSubMetric(
                      l10n.reportsAttendanceExcused,
                      '${summary.attendance.totalExcusedAbsence}',
                      AppColors.cyanAccent,
                    ),
                  ),
                  Expanded(
                    child: _buildSubMetric(
                      l10n.reportsAttendanceUnexcused,
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
        AppSectionHeader(title: l10n.reportsSectionFinancial),
        AppSectionCard(
          child: Row(
            children: [
              Expanded(
                child: _buildSubMetric(
                  l10n.reportsFinancialInvoiced,
                  currencyFormatter.format(summary.financial.totalInvoiced),
                  AppColors.cyanAccent,
                ),
              ),
              Expanded(
                child: _buildSubMetric(
                  l10n.reportsFinancialPaid,
                  currencyFormatter.format(summary.financial.totalPaid),
                  AppColors.success,
                ),
              ),
              Expanded(
                child: _buildSubMetric(
                  l10n.reportsFinancialDebt,
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
        AppSectionHeader(title: l10n.reportsSectionSessions),
        AppSectionCard(
          child: Row(
            children: [
              Expanded(
                child: _buildSubMetric(
                  l10n.reportsTotalSessions,
                  '${summary.attendance.totalSessions}',
                  AppColors.primary,
                ),
              ),
              Expanded(
                child: _buildSubMetric(
                  l10n.reportsTotalParticipations,
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
