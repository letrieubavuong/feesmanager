import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
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
            backgroundColor: Colors.red,
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
      drawer: const AppGlobalDrawer(),
      appBar: AppBar(
        leading: const GlobalMenuButton(),
        title: const Text('Báo cáo'),
        actions: [
          summaryAsync.when(
            data: (summary) => IconButton(
              icon: _isExporting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.picture_as_pdf),
              onPressed: _isExporting
                  ? null
                  : () => _exportPdf(context, summary),
              tooltip: _isExporting ? 'Đang xuất PDF...' : 'Xuất báo cáo PDF',
            ),
            loading: () => const IconButton(
              icon: Icon(Icons.picture_as_pdf),
              onPressed: null,
              tooltip: 'Đang tổng hợp báo cáo...',
            ),
            error: (_, __) => const IconButton(
              icon: Icon(Icons.picture_as_pdf),
              onPressed: null,
              tooltip: 'Không thể xuất PDF',
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
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
            // --- 1. COMPACT FILTER BAR ---
            _buildCompactFilterBar(context, scope),

            const SizedBox(height: 16),

            // --- 2. REPORT CONTENT ASYNC STATE ---
            summaryAsync.when(
              data: (summary) => _buildReportContent(context, summary),
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(40.0),
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 12),
                      Text('Đang tổng hợp báo cáo...'),
                    ],
                  ),
                ),
              ),
              error: (err, stack) => Card(
                color: Theme.of(context).colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Lỗi tải báo cáo: $err',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onErrorContainer,
                          ),
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
    final theme = Theme.of(context);

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

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            Icon(
              Icons.calendar_month,
              size: 20,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    scopeText,
                    style: theme.textTheme.titleMedium?.copyWith(
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
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            ElevatedButton.icon(
              key: const Key('open_report_filter_btn'),
              icon: const Icon(Icons.tune, size: 18),
              label: const Text('Bộ lọc'),
              style: ElevatedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              onPressed: () => ReportFilterBottomSheet.show(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportContent(BuildContext context, ReportSummary summary) {
    if (summary.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.bar_chart_outlined, size: 48, color: Colors.grey),
                SizedBox(height: 12),
                Text(
                  'Chưa có dữ liệu báo cáo trong khoảng thời gian đã chọn.',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    // On phone screen sizes, build 2-column grid. On larger screens, build 4-column.
    final cardWidth = screenWidth >= 900
        ? (screenWidth - 80) / 4
        : (screenWidth - 44) / 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- KPI CARDS 2-COLUMN GRID ON PHONE ---
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: cardWidth,
              child: _buildKpiCard(
                context,
                title: 'Tỷ lệ đi học',
                value:
                    '${summary.attendance.attendanceRatePercentage.toStringAsFixed(1)}%',
                subtitle:
                    '${summary.attendance.totalPresent}/${summary.attendance.totalEligibleParticipations} lượt',
                icon: Icons.check_circle_outline,
                color: Colors.green,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _buildKpiCard(
                context,
                title: 'Học phí đã chốt',
                value: currencyFormatter.format(
                  summary.financial.totalInvoiced,
                ),
                subtitle: 'Hóa đơn trong kỳ',
                icon: Icons.receipt_long,
                color: Colors.blue,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _buildKpiCard(
                context,
                title: 'Thực nhận',
                value: currencyFormatter.format(summary.financial.totalPaid),
                subtitle: 'Đã thu tiền',
                icon: Icons.paid,
                color: Colors.teal,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _buildKpiCard(
                context,
                title: 'Còn nợ',
                value: currencyFormatter.format(
                  summary.financial.totalOutstandingDebt,
                ),
                subtitle: 'Cần thu thêm',
                icon: Icons.account_balance_wallet,
                color: summary.financial.totalOutstandingDebt > 0
                    ? Colors.orange.shade800
                    : Colors.grey,
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // --- SECTION A: ĐIỂM DANH ---
        _buildSectionTitle(context, 'A. ĐIỂM DANH', Icons.how_to_reg_outlined),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Tỷ lệ đi học tổng thể',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    Text(
                      '${summary.attendance.attendanceRatePercentage.toStringAsFixed(1)}%',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
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
                    backgroundColor: Colors.grey.shade300,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.green,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildSubMetric(
                        'Có mặt',
                        '${summary.attendance.totalPresent}',
                        Colors.green,
                      ),
                    ),
                    Expanded(
                      child: _buildSubMetric(
                        'Đi trễ',
                        '${summary.attendance.totalLate}',
                        Colors.orange,
                      ),
                    ),
                    Expanded(
                      child: _buildSubMetric(
                        'Có phép',
                        '${summary.attendance.totalExcusedAbsence}',
                        Colors.blue,
                      ),
                    ),
                    Expanded(
                      child: _buildSubMetric(
                        'Vắng x.phép',
                        '${summary.attendance.totalUnexcusedAbsence}',
                        Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),

        // --- SECTION B: HỌC PHÍ ---
        _buildSectionTitle(context, 'B. HỌC PHÍ', Icons.payments_outlined),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildSubMetric(
                        'Chốt hóa đơn',
                        currencyFormatter.format(
                          summary.financial.totalInvoiced,
                        ),
                        Colors.blue,
                      ),
                    ),
                    Expanded(
                      child: _buildSubMetric(
                        'Đã thu',
                        currencyFormatter.format(summary.financial.totalPaid),
                        Colors.teal,
                      ),
                    ),
                    Expanded(
                      child: _buildSubMetric(
                        'Dư nợ',
                        currencyFormatter.format(
                          summary.financial.totalOutstandingDebt,
                        ),
                        summary.financial.totalOutstandingDebt > 0
                            ? Colors.orange.shade800
                            : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),

        // --- SECTION C: BUỔI HỌC ---
        _buildSectionTitle(context, 'C. BUỔI HỌC', Icons.event_note_outlined),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: _buildSubMetric(
                    'Tổng số buổi',
                    '${summary.attendance.totalSessions}',
                    Colors.indigo,
                  ),
                ),
                Expanded(
                  child: _buildSubMetric(
                    'Tổng lượt học',
                    '${summary.attendance.totalEligibleParticipations}',
                    Colors.deepPurple,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),

        // --- SECTION D: CLASS BREAKDOWN TABLE ---
        if (summary.classSummaries.isNotEmpty) ...[
          _buildSectionTitle(
            context,
            'D. CHI TIẾT THEO LỚP HỌC',
            Icons.class_outlined,
          ),
          const SizedBox(height: 8),
          Card(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Lớp học')),
                  DataColumn(label: Text('Sĩ số')),
                  DataColumn(label: Text('Đi học')),
                  DataColumn(label: Text('Học phí chốt')),
                  DataColumn(label: Text('Thực nhận')),
                  DataColumn(label: Text('Còn nợ')),
                ],
                rows: summary.classSummaries
                    .map(
                      (c) => DataRow(
                        cells: [
                          DataCell(
                            Text(
                              c.className,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          DataCell(Text('${c.studentCountInScope}')),
                          DataCell(
                            Text(
                              '${c.attendance.attendanceRatePercentage.toStringAsFixed(1)}%',
                            ),
                          ),
                          DataCell(
                            Text(
                              currencyFormatter.format(
                                c.financial.totalInvoiced,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              currencyFormatter.format(c.financial.totalPaid),
                            ),
                          ),
                          DataCell(
                            Text(
                              currencyFormatter.format(
                                c.financial.totalOutstandingDebt,
                              ),
                              style: TextStyle(
                                color: c.financial.totalOutstandingDebt > 0
                                    ? Colors.orange.shade800
                                    : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],

        // --- STUDENT BREAKDOWN TABLE ---
        if (summary.studentSummaries.isNotEmpty) ...[
          _buildSectionTitle(
            context,
            'CHI TIẾT THEO HỌC SINH',
            Icons.person_outline,
          ),
          const SizedBox(height: 8),
          Card(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Học sinh')),
                  DataColumn(label: Text('Lớp học')),
                  DataColumn(label: Text('Đi học')),
                  DataColumn(label: Text('Học phí chốt')),
                  DataColumn(label: Text('Thực nhận')),
                  DataColumn(label: Text('Còn nợ')),
                ],
                rows: summary.studentSummaries
                    .map(
                      (s) => DataRow(
                        cells: [
                          DataCell(
                            Text(
                              s.studentName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          DataCell(Text(s.enrolledClassNames.join(', '))),
                          DataCell(
                            Text(
                              '${s.attendance.totalPresent}/${s.attendance.totalEligibleParticipations}',
                            ),
                          ),
                          DataCell(
                            Text(
                              currencyFormatter.format(
                                s.financial.totalInvoiced,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              currencyFormatter.format(s.financial.totalPaid),
                            ),
                          ),
                          DataCell(
                            Text(
                              currencyFormatter.format(
                                s.financial.totalOutstandingDebt,
                              ),
                              style: TextStyle(
                                color: s.financial.totalOutstandingDebt > 0
                                    ? Colors.orange.shade800
                                    : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, IconData icon) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }

  Widget _buildKpiCard(
    BuildContext context, {
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: Colors.grey.shade600),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
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
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
