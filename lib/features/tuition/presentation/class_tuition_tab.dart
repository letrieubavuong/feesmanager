import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../app/common_widgets/app_feedback.dart';
import '../../../app/common_widgets/navy_components.dart';
import '../../../app/common_widgets/student_avatar.dart';
import '../../../app/design_system/app_theme.dart';
import '../../classes/presentation/class_controller.dart';
import '../../memberships/presentation/membership_providers.dart';
import '../../payments/domain/invoice_payment_summary.dart';
import '../../payments/presentation/payment_controller.dart';
import '../../payments/presentation/record_payment_bottom_sheet.dart';
import '../../payments/presentation/vietqr_payment_page.dart';
import '../../students/domain/student.dart';
import '../domain/tuition_invoice.dart';
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
    final rosterAsync = ref.watch(
      classMonthStudentsProvider((widget.classId, _selectedMonth)),
    );
    final invoicesAsync = ref.watch(
      classMonthInvoicesProvider((widget.classId, _selectedMonth)),
    );
    final paymentSummariesAsync = ref.watch(
      classMonthPaymentSummariesProvider((widget.classId, _selectedMonth)),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMonthSelector(context),
          const SizedBox(height: 12),
          _buildKpiSummary(
            context,
            rosterAsync,
            invoicesAsync,
            paymentSummariesAsync,
          ),
          const SizedBox(height: 12),
          _buildActionHeader(context),
          const SizedBox(height: 12),
          _buildStudentTuitionList(
            context,
            rosterAsync,
            invoicesAsync,
            paymentSummariesAsync,
          ),
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
    AsyncValue<List<Student>> rosterAsync,
    AsyncValue<List<TuitionInvoice>> invoicesAsync,
    AsyncValue<Map<int, InvoicePaymentSummary>> summariesAsync,
  ) {
    if (invoicesAsync.isLoading || summariesAsync.isLoading) {
      return const Row(
        children: [
          Expanded(
            child: AppMetricCard(
              title: 'Phải thu',
              value: '...',
              valueColor: AppColors.textPrimary,
              icon: Icons.receipt_long_outlined,
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: AppMetricCard(
              title: 'Đã thu',
              value: '...',
              valueColor: AppColors.success,
              icon: Icons.payments_outlined,
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: AppMetricCard(
              title: 'Còn nợ',
              value: '...',
              valueColor: AppColors.error,
              icon: Icons.account_balance_wallet_outlined,
            ),
          ),
        ],
      );
    }

    if (invoicesAsync.hasError || summariesAsync.hasError) {
      final err = invoicesAsync.error ?? summariesAsync.error;
      return AppSectionCard(
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
      );
    }

    final invoices = invoicesAsync.value ?? [];
    final summaries = summariesAsync.value ?? {};

    int totalDue = 0;
    int totalPaid = 0;
    int totalDebt = 0;
    int finalizedCount = 0;

    for (final inv in invoices) {
      if (inv.trangThai.isFinalizedSnapshot) {
        finalizedCount++;
        totalDue += inv.soTienPhaiThu;
        final summary = summaries[inv.idHocSinh];
        if (summary != null) {
          totalPaid += summary.totalPaid;
          totalDebt += summary.remainingDebt;
        } else {
          totalDebt += inv.soTienPhaiThu;
        }
      }
    }

    final currencyFormat = NumberFormat('#,###');

    return Row(
      children: [
        Expanded(
          child: AppMetricCard(
            title: 'Phải thu',
            value: '${currencyFormat.format(totalDue)}đ',
            valueColor: AppColors.textPrimary,
            icon: Icons.receipt_long_outlined,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: AppMetricCard(
            title: 'Đã thu',
            value: '${currencyFormat.format(totalPaid)}đ',
            valueColor: AppColors.success,
            icon: Icons.payments_outlined,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: AppMetricCard(
            title: 'Còn nợ',
            value: '${currencyFormat.format(totalDebt)}đ',
            valueColor: AppColors.error,
            subtitle: 'Chốt: $finalizedCount hóa đơn',
            icon: Icons.account_balance_wallet_outlined,
          ),
        ),
      ],
    );
  }

  Widget _buildActionHeader(BuildContext context) {
    final invoicesAsync = ref.watch(
      classMonthInvoicesProvider((widget.classId, _selectedMonth)),
    );
    final canFinalize = !invoicesAsync.isLoading && !invoicesAsync.hasError;

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
              ? () => _handleFinalizeAllInvoices(context)
              : null,
          icon: const Icon(Icons.check_circle_outline, size: 16),
          label: const Text('Chốt học phí tháng'),
        ),
      ],
    );
  }

  Widget _buildStudentTuitionList(
    BuildContext context,
    AsyncValue<List<Student>> rosterAsync,
    AsyncValue<List<TuitionInvoice>> invoicesAsync,
    AsyncValue<Map<int, InvoicePaymentSummary>> summariesAsync,
  ) {
    return rosterAsync.when(
      data: (students) {
        if (students.isEmpty) {
          return const AppSectionCard(
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Không có học sinh nào trong tháng này.',
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
          children: students.map((s) {
            return _StudentTuitionCard(
              student: s,
              classId: widget.classId,
              month: _selectedMonth,
              invoicesAsync: invoicesAsync,
              summariesAsync: summariesAsync,
            );
          }).toList(),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (e, _) => Text(
        'Lỗi danh sách học sinh: $e',
        style: const TextStyle(color: AppColors.error),
      ),
    );
  }

  void _handleFinalizeAllInvoices(BuildContext context) async {
    final confirm = await AppFeedback.showConfirmBottomSheet(
      context,
      title: 'Chốt học phí tháng $_selectedMonth',
      message:
          'Chốt học phí sẽ tạo snapshot hóa đơn chính thức cho tất cả học sinh trong tháng.\n\n'
          '• Giá trị học phí đã chốt sẽ KHÔNG bị thay đổi kể cả khi sửa chính sách sau này.\n'
          '• Bạn vẫn có thể ghi nhận thanh toán sau khi chốt.',
      confirmLabel: 'Xác nhận chốt',
      isDestructive: false,
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
  final Student student;
  final int classId;
  final String month;
  final AsyncValue<List<TuitionInvoice>> invoicesAsync;
  final AsyncValue<Map<int, InvoicePaymentSummary>> summariesAsync;

  const _StudentTuitionCard({
    required this.student,
    required this.classId,
    required this.month,
    required this.invoicesAsync,
    required this.summariesAsync,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final previewAsync = ref.watch(
      tuitionPreviewControllerProvider(student.id!, classId, month),
    );
    final currencyFormat = NumberFormat('#,###');

    if (invoicesAsync.isLoading ||
        summariesAsync.isLoading ||
        previewAsync.isLoading) {
      return AppSectionCard(
        margin: const EdgeInsets.only(bottom: 8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              StudentAvatar(
                gioiTinh: student.gioiTinh,
                studentName: student.hoTen,
                radius: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  student.hoTen,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (invoicesAsync.hasError ||
        summariesAsync.hasError ||
        previewAsync.hasError) {
      final err =
          invoicesAsync.error ?? summariesAsync.error ?? previewAsync.error;
      return AppSectionCard(
        margin: const EdgeInsets.only(bottom: 8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
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
                    Text(
                      'Lỗi: $err',
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const AppStatusChip(
                label: 'Lỗi dữ liệu',
                color: AppColors.error,
                compact: true,
              ),
            ],
          ),
        ),
      );
    }

    final invoices = invoicesAsync.value ?? [];
    final invoice = invoices.cast<TuitionInvoice?>().firstWhere(
      (i) => i != null && i.idHocSinh == student.id,
      orElse: () => null,
    );

    final isFinalized = invoice?.trangThai.isFinalizedSnapshot == true;
    final summaries = summariesAsync.value ?? {};
    final summary = summaries[student.id];

    final int amountDue = isFinalized
        ? (invoice?.soTienPhaiThu ?? 0)
        : (previewAsync.value?.soTienPhaiThu ?? 0);
    final int amountPaid = summary?.totalPaid ?? 0;
    final int remainingDebt = isFinalized
        ? (summary?.remainingDebt ?? amountDue)
        : amountDue;

    Color statusColor = AppColors.warning;
    String statusLabel = 'Chưa chốt';

    if (isFinalized) {
      if (remainingDebt <= 0) {
        statusColor = AppColors.success;
        statusLabel = 'Đã thanh toán';
      } else if (amountPaid > 0) {
        statusColor = AppColors.warning;
        statusLabel = 'Còn nợ (${currencyFormat.format(remainingDebt)}đ)';
      } else {
        statusColor = AppColors.error;
        statusLabel = 'Đã chốt (${currencyFormat.format(amountDue)}đ)';
      }
    }

    return AppSectionCard(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
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
                      'Phải thu: ${currencyFormat.format(amountDue)}đ | Đã trả: ${currencyFormat.format(amountPaid)}đ',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              AppStatusChip(
                label: statusLabel,
                color: statusColor,
                compact: true,
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (remainingDebt > 0) ...[
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
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
                          studentName: student.hoTen,
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
                const SizedBox(width: 8),
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
                    studentId: student.id!,
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
            ],
          ),
        ],
      ),
    );
  }
}
