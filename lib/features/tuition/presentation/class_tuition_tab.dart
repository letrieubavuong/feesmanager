import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../app/common_widgets/app_feedback.dart';
import '../../../app/common_widgets/app_loading_state.dart';
import '../../../app/common_widgets/navy_components.dart';
import '../../../app/common_widgets/student_avatar.dart';
import '../../../app/design_system/app_theme.dart';
import '../../../app/localization/app_formatter.dart';
import '../../classes/presentation/class_controller.dart';
import '../../payments/presentation/payment_history_bottom_sheet.dart';
import '../../payments/presentation/record_payment_bottom_sheet.dart';
import '../../payments/presentation/vietqr_payment_page.dart';
import '../domain/class_month_tuition_overview.dart';
import 'tuition_controller.dart';

class ClassTuitionTab extends ConsumerStatefulWidget {
  final int classId;

  const ClassTuitionTab({super.key, required this.classId});

  @override
  ConsumerState<ClassTuitionTab> createState() => _ClassTuitionTabState();
}

class _ClassTuitionTabState extends ConsumerState<ClassTuitionTab> {
  late String _selectedMonth;

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
    });
  }

  @override
  Widget build(BuildContext context) {
    final overviewAsync = ref.watch(
      classMonthTuitionOverviewProvider((widget.classId, _selectedMonth)),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMonthSelector(context),
          const SizedBox(height: 12),
          _buildKpiSummary(context, overviewAsync),
          const SizedBox(height: 16),
          _buildActionHeader(context, overviewAsync),
          const SizedBox(height: 12),
          _buildStudentTuitionList(context, overviewAsync),
        ],
      ),
    );
  }

  Widget _buildMonthSelector(BuildContext context) {
    final formattedMonth = DateFormat(
      'MM/yyyy',
    ).format(DateTime.parse('$_selectedMonth-01'));

    return AppSectionCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: AppColors.cyanAccent),
            onPressed: () => _changeMonth(-1),
          ),
          Row(
            children: [
              const Icon(
                Icons.calendar_month_outlined,
                color: AppColors.cyanAccent,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Tháng $formattedMonth',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: AppColors.cyanAccent),
            onPressed: () => _changeMonth(1),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiSummary(
    BuildContext context,
    AsyncValue<ClassMonthTuitionOverview> overviewAsync,
  ) {
    return overviewAsync.when(
      loading: () => const AppSectionCard(
        child: Padding(padding: EdgeInsets.all(16), child: AppLoadingState()),
      ),
      error: (err, _) => AppSectionCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Lỗi nạp dữ liệu tài chính: $err',
                style: const TextStyle(color: AppColors.error, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
      data: (overview) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = (constraints.maxWidth - 12) / 2;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: cardWidth,
                  child: AppMetricCard(
                    title: 'Tạm tính',
                    value: AppFormatter.formatCurrency(
                      overview.previewTotalDue,
                      context: context,
                    ),
                    subtitle: '${overview.previewStudentCount} học sinh',
                    valueColor: AppColors.cyanAccent,
                    icon: Icons.calculate_outlined,
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: AppMetricCard(
                    title: 'Đã chốt',
                    value: AppFormatter.formatCurrency(
                      overview.finalizedTotalDue,
                      context: context,
                    ),
                    subtitle: '${overview.finalizedStudentCount} học sinh',
                    valueColor: AppColors.textPrimary,
                    icon: Icons.receipt_long_outlined,
                  ),
                ),
                SizedBox(
                  width: cardWidth,
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
                SizedBox(
                  width: cardWidth,
                  child: AppMetricCard(
                    title: 'Còn nợ',
                    value: AppFormatter.formatCurrency(
                      overview.remainingDebt,
                      context: context,
                    ),
                    valueColor: AppColors.error,
                    icon: Icons.account_balance_wallet_outlined,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildActionHeader(
    BuildContext context,
    AsyncValue<ClassMonthTuitionOverview> overviewAsync,
  ) {
    final canFinalize =
        overviewAsync.hasValue && overviewAsync.value!.previewStudentCount > 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Danh sách học phí',
          style: TextStyle(
            color: AppColors.cyanAccent,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          ),
          onPressed: canFinalize
              ? () => _handlePreflightAndFinalize(context, overviewAsync.value!)
              : null,
          icon: const Icon(Icons.check_circle_outline, size: 16),
          label: const Text('Chốt học phí tháng'),
        ),
      ],
    );
  }

  Widget _buildStudentTuitionList(
    BuildContext context,
    AsyncValue<ClassMonthTuitionOverview> overviewAsync,
  ) {
    return overviewAsync.when(
      data: (overview) {
        if (overview.studentRows.isEmpty) {
          return const AppSectionCard(
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'Không có học sinh nào tham gia lớp trong tháng này.',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
          );
        }

        return Column(
          children: overview.studentRows.map((row) {
            return _StudentTuitionCard(
              row: row,
              classId: widget.classId,
              month: _selectedMonth,
            );
          }).toList(),
        );
      },
      loading: () => const Center(
        child: Padding(padding: EdgeInsets.all(24), child: AppLoadingState()),
      ),
      error: (e, _) => Text(
        'Lỗi danh sách học sinh: $e',
        style: const TextStyle(color: AppColors.error),
      ),
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final student = row.student;

    return AppSectionCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StudentAvatar(
                gioiTinh: student.gioiTinh,
                studentName: student.hoTen,
                radius: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.hoTen,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'SĐT: ${student.sdtPhuHuynh ?? "Chưa có"}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
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
          const SizedBox(height: 10),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 10),
          if (row.isBlocked) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: AppColors.warning,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      row.pendingReason ?? 'Chưa đủ dữ liệu tính học phí',
                      style: const TextStyle(
                        color: AppColors.warning,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            _buildTuitionBreakdown(context),
          ],
          const SizedBox(height: 10),
          _buildActionRow(context, ref),
        ],
      ),
    );
  }

  Widget _buildTuitionBreakdown(BuildContext context) {
    int eligible = 0;
    int charged = 0;
    int feePerSession = 0;
    int totalFee = 0;
    int totalPaid = row.amountPaid;
    int remainingDebt = row.remainingDebt;

    if (row.isFinalized && row.invoice != null) {
      final inv = row.invoice!;
      eligible = inv.soBuoiEligible;
      charged = inv.soBuoiTinhPhi;
      feePerSession = inv.soBuoiTinhPhi > 0
          ? inv.tongTruocGiam ~/ inv.soBuoiTinhPhi
          : 0;
      totalFee = inv.soTienPhaiThu;
    } else if (row.preview != null) {
      final p = row.preview!;
      eligible = p.soBuoiEligible;
      charged = p.soBuoiTinhPhi;
      feePerSession = p.policy.hocPhiMoiBuoi;
      totalFee = p.soTienPhaiThu;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '• $eligible buổi đủ điều kiện ($charged buổi tính phí × ${AppFormatter.formatCurrency(feePerSession, context: context)}/buổi)',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                row.isFinalized ? 'Đã chốt:' : 'Tạm tính:',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                AppFormatter.formatCurrency(totalFee, context: context),
                style: const TextStyle(
                  color: AppColors.cyanAccent,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (row.isFinalized) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Đã thu:',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                Text(
                  AppFormatter.formatCurrency(totalPaid, context: context),
                  style: const TextStyle(
                    color: AppColors.success,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Còn nợ:',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                Text(
                  AppFormatter.formatCurrency(remainingDebt, context: context),
                  style: TextStyle(
                    color: remainingDebt > 0
                        ? AppColors.error
                        : AppColors.success,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionRow(BuildContext context, WidgetRef ref) {
    final isFinalized = row.isFinalized;
    final remainingDebt = row.remainingDebt;
    final totalPaid = row.amountPaid;
    final studentId = row.student.id!;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (isFinalized || totalPaid > 0)
          TextButton.icon(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
            onPressed: () => showPaymentHistoryBottomSheet(
              context,
              studentId: studentId,
              classId: classId,
              month: month,
              studentName: row.student.hoTen,
            ),
            icon: const Icon(
              Icons.history,
              size: 16,
              color: AppColors.cyanAccent,
            ),
            label: const Text(
              'Lịch sử thu',
              style: TextStyle(color: AppColors.cyanAccent, fontSize: 12),
            ),
          )
        else
          const SizedBox.shrink(),

        Row(
          children: [
            if (isFinalized) ...[
              if (totalPaid == 0) ...[
                TextButton.icon(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                  ),
                  onPressed: () => _handleRecalculateInvoice(context, ref),
                  icon: const Icon(
                    Icons.refresh,
                    size: 16,
                    color: AppColors.warning,
                  ),
                  label: const Text(
                    'Tính lại học phí',
                    style: TextStyle(color: AppColors.warning, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              if (remainingDebt > 0) ...[
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  onPressed: () {
                    final clsAsync = ref
                        .read(classDetailProvider(classId))
                        .value;
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => VietQrPaymentPage(
                          studentName: row.student.hoTen,
                          className: clsAsync?.tenLop ?? '',
                          month: month,
                          remainingAmount: remainingDebt,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.qr_code_2,
                    size: 16,
                    color: AppColors.cyanAccent,
                  ),
                  label: const Text(
                    'QR',
                    style: TextStyle(color: AppColors.cyanAccent, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 6),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                  ),
                  onPressed: () => showRecordPaymentBottomSheet(
                    context,
                    studentId: studentId,
                    classId: classId,
                    month: month,
                    suggestedAmount: remainingDebt,
                  ),
                  icon: const Icon(Icons.payments_outlined, size: 16),
                  label: const Text(
                    'Thanh toán',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ] else
                const Text(
                  'Đã hoàn tất thanh toán',
                  style: TextStyle(
                    color: AppColors.success,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ] else ...[
              const Text(
                'Chốt học phí trước khi thu tiền.',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  void _handleRecalculateInvoice(BuildContext context, WidgetRef ref) async {
    final reasonController = TextEditingController(
      text: 'Cập nhật điểm danh sau khi chốt',
    );

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Tính lại học phí đã chốt',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tính lại hóa đơn tháng $month của học sinh ${row.student.hoTen} dựa trên dữ liệu điểm danh mới nhất.',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Lý do tính lại *',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              foregroundColor: Colors.black,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Tính lại'),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    try {
      await ref
          .read(invoiceControllerProvider.notifier)
          .recalculateInvoice(
            studentId: row.student.id!,
            classId: classId,
            month: month,
            reason: reasonController.text.trim(),
          );

      if (context.mounted) {
        AppFeedback.showSuccessSnackBar(
          context,
          'Đã tính lại học phí thành công cho ${row.student.hoTen}',
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
