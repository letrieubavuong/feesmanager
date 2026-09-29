import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/common_widgets/app_feedback.dart';
import '../../../app/common_widgets/app_loading_state.dart';
import '../../../app/common_widgets/navy_components.dart';
import '../../../app/common_widgets/parent_contact_actions.dart';
import '../../../app/common_widgets/student_avatar.dart';
import '../../../app/design_system/app_theme.dart';
import '../../../app/localization/app_formatter.dart';
import '../../classes/presentation/class_controller.dart';
import '../../payments/presentation/payment_history_bottom_sheet.dart';
import '../../payments/presentation/record_payment_bottom_sheet.dart';
import '../../payments/presentation/vietqr_payment_page.dart';
import '../../students/presentation/student_detail_page.dart';
import '../domain/class_month_tuition_overview.dart';
import 'tuition_controller.dart';

enum TuitionPaymentFilter { outstanding, paid }

class ClassTuitionTab extends ConsumerStatefulWidget {
  final int classId;
  final Widget? classSelector;

  const ClassTuitionTab({super.key, required this.classId, this.classSelector});

  @override
  ConsumerState<ClassTuitionTab> createState() => _ClassTuitionTabState();
}

class _ClassTuitionTabState extends ConsumerState<ClassTuitionTab> {
  late String _selectedMonth;
  TuitionPaymentFilter? _userFilter;
  String? _lastMonth;

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateFormat('yyyy-MM').format(DateTime.now());
  }

  void _changeMonth(int deltaMonths) {
    final parsed = DateTime.parse('$_selectedMonth-01');
    final newDate = DateTime(parsed.year, parsed.month + deltaMonths, 1);
    setState(() {
      _selectedMonth = DateFormat('yyyy-MM').format(newDate);
      _userFilter = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final overviewAsync = ref.watch(
      classMonthTuitionOverviewProvider((widget.classId, _selectedMonth)),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(6, 12, 6, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.account_balance_wallet_outlined,
                color: AppColors.cyanAccent,
                size: 17,
              ),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'Tổng quan học phí',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              _buildMonthSelector(context),
            ],
          ),
          const SizedBox(height: 12),
          overviewAsync.when(
            data: (overview) {
              final outstandingCount = overview.studentRows
                  .where((r) => !r.isFinalized || r.remainingDebt > 0)
                  .length;
              final paidCount = overview.studentRows
                  .where((r) => r.isFinalized && r.remainingDebt <= 0)
                  .length;

              if (_lastMonth != _selectedMonth) {
                _lastMonth = _selectedMonth;
                _userFilter = null;
              }

              final effectiveFilter =
                  _userFilter ??
                  (outstandingCount > 0
                      ? TuitionPaymentFilter.outstanding
                      : TuitionPaymentFilter.paid);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildKpiSummary(context, overview),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (widget.classSelector != null) ...[
                        Expanded(child: widget.classSelector!),
                        const SizedBox(width: 6),
                      ],
                      _buildFilterToggle(
                        context,
                        effectiveFilter,
                        outstandingCount,
                        paidCount,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildUnfinalizedBanner(context, overview),
                  const SizedBox(height: 12),
                  const Row(
                    children: [
                      Icon(
                        Icons.people_outline,
                        color: AppColors.cyanAccent,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Danh sách học sinh',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildStudentTuitionList(context, overview, effectiveFilter),
                ],
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: AppLoadingState(),
            ),
            error: (err, _) => AppSectionCard(
              padding: const EdgeInsets.all(12),
              child: Text(
                'Lỗi nạp dữ liệu tài chính: ${err.toString().replaceAll("Exception: ", "")}',
                style: const TextStyle(color: AppColors.error, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSelector(BuildContext context) {
    final formattedMonth = DateFormat(
      'MM/yyyy',
    ).format(DateTime.parse('$_selectedMonth-01'));

    return SizedBox(
      width: 128,
      child: AppSectionCard(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(
                Icons.chevron_left,
                color: AppColors.cyanAccent,
                size: 20,
              ),
              onPressed: () => _changeMonth(-1),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 24, height: 28),
            ),
            Expanded(
              child: Text(
                formattedMonth,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.chevron_right,
                color: AppColors.cyanAccent,
                size: 20,
              ),
              onPressed: () => _changeMonth(1),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 24, height: 28),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiSummary(
    BuildContext context,
    ClassMonthTuitionOverview overview,
  ) {
    return Row(
      children: [
        Expanded(
          child: AppMetricCard(
            title: 'Đã thu',
            value: AppFormatter.formatCurrency(
              overview.totalPaid,
              context: context,
            ),
            valueColor: AppColors.success,
            icon: Icons.payments_outlined,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: AppMetricCard(
            title: 'Dự kiến còn thu',
            value: AppFormatter.formatCurrency(
              overview.previewTotalDue + overview.remainingDebt,
              context: context,
            ),
            valueColor: AppColors.error,
            icon: Icons.account_balance_wallet_outlined,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterToggle(
    BuildContext context,
    TuitionPaymentFilter activeFilter,
    int outstandingCount,
    int paidCount,
  ) {
    return Row(
      children: [
        const Text(
          'Còn thu',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
        ),
        Switch.adaptive(
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          value: activeFilter == TuitionPaymentFilter.paid,
          onChanged: (paid) => setState(
            () => _userFilter = paid
                ? TuitionPaymentFilter.paid
                : TuitionPaymentFilter.outstanding,
          ),
        ),
        const Text(
          'Đã thu',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildUnfinalizedBanner(
    BuildContext context,
    ClassMonthTuitionOverview overview,
  ) {
    final unfinalizedRows = overview.studentRows
        .where((r) => !r.isFinalized)
        .toList();
    if (unfinalizedRows.isEmpty) return const SizedBox.shrink();

    final blockedCount = overview.pendingStudentCount;
    final unfinalizedCount = unfinalizedRows.length;

    final String label = blockedCount > 0
        ? '$unfinalizedCount chưa chốt • $blockedCount chưa đủ dữ liệu'
        : '$unfinalizedCount học sinh chưa chốt học phí';

    return AppSectionCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.warning,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.warning,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: const Size(0, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () => _handlePreflightAndFinalize(context, overview),
            child: const Text(
              'Chốt học phí',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentTuitionList(
    BuildContext context,
    ClassMonthTuitionOverview overview,
    TuitionPaymentFilter activeFilter,
  ) {
    List<ClassMonthTuitionStudentRow> targetRows;
    if (activeFilter == TuitionPaymentFilter.outstanding) {
      targetRows = overview.studentRows
          .where((r) => !r.isFinalized || r.remainingDebt > 0)
          .toList();
    } else {
      targetRows = overview.studentRows
          .where((r) => r.isFinalized && r.remainingDebt <= 0)
          .toList();
    }

    targetRows.sort(
      (a, b) => a.student.hoTen.toLowerCase().compareTo(
        b.student.hoTen.toLowerCase(),
      ),
    );

    if (targetRows.isEmpty) {
      String emptyText;
      if (activeFilter == TuitionPaymentFilter.outstanding) {
        emptyText = 'Không có khoản tạm tính hoặc chưa thanh toán.';
      } else {
        emptyText = 'Chưa có học sinh đã nộp đủ.';
      }
      return AppSectionCard(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              emptyText,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      children: targetRows.map((row) {
        return _StudentTuitionCard(
          row: row,
          classId: widget.classId,
          month: _selectedMonth,
        );
      }).toList(),
    );
  }

  void _handlePreflightAndFinalize(
    BuildContext context,
    ClassMonthTuitionOverview overview,
  ) async {
    final readyCount = overview.previewStudentCount;
    final finalizedCount = overview.finalizedStudentCount;
    final blockedCount = overview.pendingStudentCount;

    final blockedRows = overview.studentRows.where((r) => r.isBlocked).toList();

    final confirm = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Chốt học phí tháng $_selectedMonth',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () => Navigator.pop(context, false),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceHigh,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Sẵn sàng chốt:',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                        Text(
                          '$readyCount học sinh',
                          style: const TextStyle(
                            color: AppColors.success,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Đã chốt trước đó:',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                        Text(
                          '$finalizedCount học sinh',
                          style: const TextStyle(
                            color: AppColors.cyanAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Bị chặn (chưa đủ dữ liệu):',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                        Text(
                          '$blockedCount học sinh',
                          style: TextStyle(
                            color: blockedCount > 0
                                ? AppColors.warning
                                : AppColors.textMuted,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (blockedRows.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'Danh sách học sinh bị chặn:',
                  style: TextStyle(
                    color: AppColors.warning,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  constraints: const BoxConstraints(maxHeight: 120),
                  child: SingleChildScrollView(
                    child: Column(
                      children: blockedRows.map((r) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.warning_amber_rounded,
                                color: AppColors.warning,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '${r.student.hoTen}: ${r.pendingReason ?? "Thiếu dữ liệu điểm danh"}',
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              const Text(
                'Lưu ý: Chốt học phí sẽ tạo snapshot cố định cho các học sinh sẵn sàng.',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Hủy'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: readyCount > 0
                        ? () => Navigator.pop(context, true)
                        : null,
                    icon: const Icon(Icons.check),
                    label: Text('Xác nhận chốt ($readyCount HS)'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm != true || !context.mounted) return;

    try {
      final invoices = await ref
          .read(invoiceControllerProvider.notifier)
          .finalizeClassInvoices(
            classId: widget.classId,
            month: _selectedMonth,
          );

      if (context.mounted) {
        AppFeedback.showSuccessSnackBar(
          context,
          'Đã chốt học phí thành công cho ${invoices.length} học sinh',
        );
      }
    } catch (e) {
      if (context.mounted) {
        AppFeedback.showErrorSnackBar(
          context,
          e.toString().replaceAll('Exception: ', ''),
        );
      }
    }
  }
}

class _StudentTuitionCard extends ConsumerWidget {
  final ClassMonthTuitionStudentRow row;
  final int classId;
  final String month;

  const _StudentTuitionCard({
    required this.row,
    required this.classId,
    required this.month,
  });

  Future<void> _finalizeStudent(BuildContext context, WidgetRef ref) async {
    final confirm = await showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Chốt học phí học sinh',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${row.student.hoTen} • Tháng $month',
                style: const TextStyle(color: AppColors.textPrimary),
              ),
              const SizedBox(height: 6),
              Text(
                'Tạm tính: ${AppFormatter.formatCurrency(row.amountDue, context: context)}',
                style: const TextStyle(
                  color: AppColors.cyanAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Chốt sẽ lưu cố định số buổi và học phí của học sinh này.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(sheetContext, false),
                    child: const Text('Hủy'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(sheetContext, true),
                    child: const Text('Xác nhận chốt'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (confirm != true || !context.mounted) return;
    try {
      await ref
          .read(invoiceControllerProvider.notifier)
          .finalizeStudentInvoice(
            studentId: row.student.id!,
            classId: classId,
            month: month,
          );
      if (context.mounted) {
        AppFeedback.showSuccessSnackBar(
          context,
          'Đã chốt học phí cho ${row.student.hoTen}',
        );
      }
    } catch (error) {
      if (context.mounted) {
        AppFeedback.showErrorSnackBar(
          context,
          error.toString().replaceAll('Exception: ', ''),
        );
      }
    }
  }

  void _showStudentTuitionDetailBottomSheet(
    BuildContext context,
    ClassMonthTuitionStudentRow row,
  ) {
    int eligible = 0;
    int charged = 0;
    int feePerSession = 0;
    int totalFee = row.amountDue;
    int totalPaid = row.amountPaid;
    int remainingDebt = row.remainingDebt;

    if (row.isFinalized && row.invoice != null) {
      final inv = row.invoice!;
      eligible = inv.soBuoiEligible;
      charged = inv.soBuoiTinhPhi;
      feePerSession = inv.soBuoiTinhPhi > 0
          ? inv.tongTruocGiam ~/ inv.soBuoiTinhPhi
          : 0;
    } else if (row.preview != null) {
      final p = row.preview!;
      eligible = p.soBuoiEligible;
      charged = p.soBuoiTinhPhi;
      feePerSession = p.policy.hocPhiMoiBuoi;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.surface,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  StudentAvatar(
                    gioiTinh: row.student.gioiTinh,
                    studentName: row.student.hoTen,
                    radius: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          row.student.hoTen,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Chi tiết học phí tháng $month',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AppStatusChip(
                    label: row.stateLabel,
                    color: row.stateColor,
                    compact: true,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceHigh,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    _buildDetailRow(
                      context,
                      'Buổi đủ điều kiện:',
                      '$eligible buổi',
                    ),
                    const SizedBox(height: 8),
                    _buildDetailRow(context, 'Buổi tính phí:', '$charged buổi'),
                    const SizedBox(height: 8),
                    _buildDetailRow(
                      context,
                      'Đơn giá / buổi:',
                      AppFormatter.formatCurrency(
                        feePerSession,
                        context: context,
                      ),
                    ),
                    const Divider(color: AppColors.border, height: 16),
                    _buildDetailRow(
                      context,
                      row.isFinalized ? 'Đã chốt học phí:' : 'Tạm tính:',
                      AppFormatter.formatCurrency(totalFee, context: context),
                      isBold: true,
                      valueColor: AppColors.cyanAccent,
                    ),
                    const SizedBox(height: 8),
                    _buildDetailRow(
                      context,
                      'Đã thu:',
                      AppFormatter.formatCurrency(totalPaid, context: context),
                      valueColor: AppColors.success,
                    ),
                    const SizedBox(height: 8),
                    _buildDetailRow(
                      context,
                      'Chưa thanh toán:',
                      AppFormatter.formatCurrency(
                        remainingDebt,
                        context: context,
                      ),
                      isBold: true,
                      valueColor: remainingDebt > 0
                          ? AppColors.error
                          : AppColors.success,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Đóng'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value, {
    bool isBold = false,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? AppColors.textPrimary,
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final student = row.student;
    final remainingDebt = row.remainingDebt;
    final amountPaid = row.amountPaid;
    final isUnpaid = remainingDebt > 0;

    return AppSectionCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => StudentDetailPage(studentId: student.id!),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StudentAvatar(
            gioiTinh: student.gioiTinh,
            studentName: student.hoTen,
            radius: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        student.hoTen,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      AppFormatter.formatCurrency(
                        isUnpaid ? remainingDebt : amountPaid,
                        context: context,
                      ),
                      maxLines: 1,
                      style: TextStyle(
                        color: isUnpaid ? AppColors.error : AppColors.success,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        isUnpaid
                            ? row.isFinalized
                                  ? 'Chưa thanh toán'
                                  : 'Tạm tính'
                            : 'Đã thu',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    ParentContactActions(phone: student.sdtPhuHuynh),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            key: Key('tuition_student_menu_${student.id}'),
            tooltip: 'Tùy chọn học phí',
            child: const SizedBox(
              width: 48,
              height: 48,
              child: Center(
                child: Icon(Icons.more_vert, color: AppColors.textSecondary),
              ),
            ),
            color: AppColors.surfaceHigh,
            onSelected: (value) async {
              if (value == 'finalize') {
                await _finalizeStudent(context, ref);
              } else if (value == 'payment') {
                await showRecordPaymentBottomSheet(
                  context,
                  studentId: student.id!,
                  classId: classId,
                  month: month,
                  suggestedAmount: remainingDebt,
                );
                if (context.mounted) {
                  ref.invalidate(
                    classMonthTuitionOverviewProvider((classId, month)),
                  );
                }
              } else if (value == 'qr') {
                final cls = ref.read(classDetailProvider(classId)).value;
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => VietQrPaymentPage(
                      studentId: student.id!,
                      classId: classId,
                      month: month,
                      studentName: student.hoTen,
                      className: cls?.tenLop ?? '',
                      remainingAmount: remainingDebt,
                    ),
                  ),
                );
              } else if (value == 'history') {
                await showPaymentHistoryBottomSheet(
                  context,
                  studentId: student.id!,
                  classId: classId,
                  month: month,
                  studentName: student.hoTen,
                );
                ref.invalidate(
                  classMonthTuitionOverviewProvider((classId, month)),
                );
              } else if (value == 'detail') {
                _showStudentTuitionDetailBottomSheet(context, row);
              } else if (value == 'recalc') {
                _handleRecalculateInvoice(context, ref);
              }
            },
            itemBuilder: (context) => [
              if (row.state == ClassStudentTuitionState.PREVIEW_READY)
                const PopupMenuItem(
                  value: 'finalize',
                  child: ListTile(
                    dense: true,
                    leading: Icon(Icons.verified_outlined),
                    title: Text('Chốt học phí em này'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              if (isUnpaid) ...[
                const PopupMenuItem(
                  value: 'payment',
                  child: ListTile(
                    dense: true,
                    leading: Icon(Icons.payments_outlined),
                    title: Text('Thu tiền'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'qr',
                  child: ListTile(
                    dense: true,
                    leading: Icon(Icons.qr_code_2),
                    title: Text('Tạo mã QR'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
              if (row.isFinalized || amountPaid > 0)
                const PopupMenuItem(
                  value: 'history',
                  child: ListTile(
                    dense: true,
                    leading: Icon(Icons.history),
                    title: Text('Xem / sửa phiếu thu'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              const PopupMenuItem(
                value: 'detail',
                child: ListTile(
                  dense: true,
                  leading: Icon(Icons.receipt_long_outlined),
                  title: Text('Chi tiết học phí'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              if (row.isFinalized && amountPaid == 0 && isUnpaid)
                const PopupMenuItem(
                  value: 'recalc',
                  child: ListTile(
                    dense: true,
                    leading: Icon(Icons.calculate_outlined),
                    title: Text('Tính lại học phí'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleRecalculateInvoice(BuildContext context, WidgetRef ref) async {
    final reasonController = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surfaceHigh,
        title: const Text(
          'Tính lại học phí',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tính lại cho học sinh ${row.student.hoTen}. Thao tác này sẽ cập nhật invoice theo dữ liệu điểm danh mới nhất.',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Lý do tính lại *',
                hintText: 'VD: Cập nhật điểm danh bù',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              foregroundColor: Colors.black,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xác nhận tính lại'),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    final reason = reasonController.text.trim();
    if (reason.isEmpty) {
      AppFeedback.showErrorSnackBar(
        context,
        'Vui lòng nhập lý do tính lại học phí',
      );
      return;
    }

    try {
      await ref
          .read(invoiceControllerProvider.notifier)
          .recalculateInvoice(
            studentId: row.student.id!,
            classId: classId,
            month: month,
            reason: reason,
          );
      if (context.mounted) {
        AppFeedback.showSuccessSnackBar(
          context,
          'Đã tính lại học phí thành công',
        );
      }
    } catch (e) {
      if (context.mounted) {
        AppFeedback.showErrorSnackBar(
          context,
          e.toString().replaceAll('Exception: ', ''),
        );
      }
    }
  }
}
