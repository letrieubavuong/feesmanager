import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../classes/presentation/class_controller.dart';
import '../../students/presentation/student_controller.dart';
import '../domain/report_scope.dart';
import '../domain/report_summary.dart';
import '../export/report_pdf_exporter.dart';
import 'report_controller.dart';

class ReportsPage extends ConsumerStatefulWidget {
  const ReportsPage({super.key});

  @override
  ConsumerState<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends ConsumerState<ReportsPage> {
  final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
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
    final classesAsync = ref.watch(classListControllerProvider);
    final studentsAsync = ref.watch(studentListControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Báo cáo & Thống kê'),
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
            // --- 1. FILTER CONTROLS BAR ---
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Phạm vi báo cáo',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 16,
                      runSpacing: 12,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        // Mode Segmented Button
                        SegmentedButton<ReportMode>(
                          segments: const [
                            ButtonSegment(
                              value: ReportMode.month,
                              label: Text('Theo tháng'),
                              icon: Icon(Icons.calendar_month),
                            ),
                            ButtonSegment(
                              value: ReportMode.customRange,
                              label: Text('Khoảng ngày'),
                              icon: Icon(Icons.date_range),
                            ),
                          ],
                          selected: {scope.mode},
                          onSelectionChanged: (selection) {
                            final newMode = selection.first;
                            if (newMode == ReportMode.month) {
                              final currentMonth = DateFormat(
                                'yyyy-MM',
                              ).format(DateTime.now());
                              ref
                                  .read(reportScopeNotifierProvider.notifier)
                                  .setMonth(currentMonth);
                            } else {
                              final now = DateTime.now();
                              final fromStr = DateFormat(
                                'yyyy-MM-01',
                              ).format(now);
                              final toStr = DateFormat(
                                'yyyy-MM-dd',
                              ).format(now);
                              ref
                                  .read(reportScopeNotifierProvider.notifier)
                                  .setCustomRange(fromStr, toStr);
                            }
                          },
                        ),

                        // Month Dropdown if ReportMode.month
                        if (scope.mode == ReportMode.month)
                          _buildMonthDropdown(context, scope),

                        // Custom Date Pickers if ReportMode.customRange
                        if (scope.mode == ReportMode.customRange) ...[
                          _buildDatePickerButton(
                            context: context,
                            label: 'Từ ngày',
                            dateStr: scope.fromDate,
                            oppositeDateStr: scope.toDate,
                            isFromDate: true,
                          ),
                          _buildDatePickerButton(
                            context: context,
                            label: 'Đến ngày',
                            dateStr: scope.toDate,
                            oppositeDateStr: scope.fromDate,
                            isFromDate: false,
                          ),
                        ],

                        // Class Filter
                        classesAsync.when(
                          data: (classes) => SizedBox(
                            width: 200,
                            child: DropdownButtonFormField<int?>(
                              initialValue: scope.classId,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Lớp học',
                                isDense: true,
                              ),
                              items: [
                                const DropdownMenuItem<int?>(
                                  value: null,
                                  child: Text(
                                    'Tất cả các lớp',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                ...classes.map(
                                  (c) => DropdownMenuItem<int?>(
                                    value: c.id,
                                    child: Text(
                                      c.tenLop,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ],
                              onChanged: (val) {
                                ref
                                    .read(reportScopeNotifierProvider.notifier)
                                    .setClassFilter(val);
                              },
                            ),
                          ),
                          loading: () => const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          error: (_, __) => const SizedBox(),
                        ),

                        // Student Filter
                        studentsAsync.when(
                          data: (students) => SizedBox(
                            width: 220,
                            child: DropdownButtonFormField<int?>(
                              initialValue: scope.studentId,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Học sinh',
                                isDense: true,
                              ),
                              items: [
                                const DropdownMenuItem<int?>(
                                  value: null,
                                  child: Text(
                                    'Tất cả học sinh',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                ...students.map(
                                  (s) => DropdownMenuItem<int?>(
                                    value: s.id,
                                    child: Text(
                                      s.hoTen,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ],
                              onChanged: (val) {
                                ref
                                    .read(reportScopeNotifierProvider.notifier)
                                    .setStudentFilter(val);
                              },
                            ),
                          ),
                          loading: () => const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          error: (_, __) => const SizedBox(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

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

  Widget _buildMonthDropdown(BuildContext context, ReportScope scope) {
    final now = DateTime.now();
    final months = List.generate(12, (i) {
      final date = DateTime(now.year, now.month - i, 1);
      return DateFormat('yyyy-MM').format(date);
    });

    final currentMonth = scope.fromDate.substring(0, 7);

    return SizedBox(
      width: 160,
      child: DropdownButtonFormField<String>(
        initialValue: months.contains(currentMonth)
            ? currentMonth
            : months.first,
        isExpanded: true,
        decoration: const InputDecoration(
          labelText: 'Chọn tháng',
          isDense: true,
        ),
        items: months
            .map(
              (m) => DropdownMenuItem<String>(
                value: m,
                child: Text('Tháng $m', overflow: TextOverflow.ellipsis),
              ),
            )
            .toList(),
        onChanged: (val) {
          if (val != null) {
            ref.read(reportScopeNotifierProvider.notifier).setMonth(val);
          }
        },
      ),
    );
  }

  Widget _buildDatePickerButton({
    required BuildContext context,
    required String label,
    required String dateStr,
    required String oppositeDateStr,
    required bool isFromDate,
  }) {
    return OutlinedButton.icon(
      icon: const Icon(Icons.event, size: 18),
      label: Text('$label: $dateStr'),
      onPressed: () async {
        final initialDate = DateTime.tryParse(dateStr) ?? DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: initialDate,
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (picked != null) {
          final selectedStr = DateFormat('yyyy-MM-dd').format(picked);
          if (isFromDate) {
            final toStr = selectedStr.compareTo(oppositeDateStr) > 0
                ? selectedStr
                : oppositeDateStr;
            ref
                .read(reportScopeNotifierProvider.notifier)
                .setCustomRange(selectedStr, toStr);
          } else {
            final fromStr = selectedStr.compareTo(oppositeDateStr) < 0
                ? selectedStr
                : oppositeDateStr;
            ref
                .read(reportScopeNotifierProvider.notifier)
                .setCustomRange(fromStr, selectedStr);
          }
        }
      },
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

    final width = MediaQuery.of(context).size.width;
    final kpiWidth = width >= 1000
        ? (width - 80) / 4
        : width >= 600
        ? (width - 64) / 2
        : width - 48;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- KPI CARDS RESPONSIVE WRAP ---
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: kpiWidth,
              child: _buildKpiCard(
                context,
                title: 'Tỷ lệ đi học',
                value:
                    '${summary.attendance.attendanceRatePercentage.toStringAsFixed(1)}%',
                subtitle:
                    'Có mặt: ${summary.attendance.totalPresent} / ${summary.attendance.totalEligibleParticipations} lượt (Trễ: ${summary.attendance.totalLate})',
                icon: Icons.check_circle_outline,
                color: Colors.green,
              ),
            ),
            SizedBox(
              width: kpiWidth,
              child: _buildKpiCard(
                context,
                title: 'Học phí chốt',
                value: currencyFormatter.format(
                  summary.financial.totalInvoiced,
                ),
                subtitle: 'Số hóa đơn đã chốt',
                icon: Icons.receipt_long,
                color: Colors.blue,
              ),
            ),
            SizedBox(
              width: kpiWidth,
              child: _buildKpiCard(
                context,
                title: 'Doanh thu thực nhận',
                value: currencyFormatter.format(summary.financial.totalPaid),
                subtitle: 'Tiền mặt đã thu',
                icon: Icons.paid,
                color: Colors.teal,
              ),
            ),
            SizedBox(
              width: kpiWidth,
              child: _buildKpiCard(
                context,
                title: 'Dư nợ hiện tại của hóa đơn trong kỳ',
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

        const SizedBox(height: 24),

        // --- CLASS BREAKDOWN TABLE ---
        if (summary.classSummaries.isNotEmpty) ...[
          Text(
            'Tổng quan theo Lớp học',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Card(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Lớp học')),
                  DataColumn(label: Text('Học sinh')),
                  DataColumn(label: Text('Tỷ lệ đi học')),
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
          const SizedBox(height: 24),
        ],

        // --- STUDENT BREAKDOWN TABLE ---
        if (summary.studentSummaries.isNotEmpty) ...[
          Text(
            'Chi tiết theo Học sinh',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Card(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Học sinh')),
                  DataColumn(label: Text('Lớp học')),
                  DataColumn(label: Text('Đi học / Tổng')),
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
                              '${s.attendance.totalPresent} / ${s.attendance.totalEligibleParticipations}',
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
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
