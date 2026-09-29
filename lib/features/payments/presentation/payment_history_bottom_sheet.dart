import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/common_widgets/app_loading_state.dart';
import '../../../app/design_system/app_theme.dart';
import '../../../app/localization/app_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../tuition/presentation/tuition_controller.dart';
import '../domain/payment_method.dart';
import 'payment_controller.dart';
import 'record_payment_bottom_sheet.dart';

class PaymentHistoryBottomSheet extends ConsumerWidget {
  final int studentId;
  final int classId;
  final String month;
  final String studentName;

  const PaymentHistoryBottomSheet({
    super.key,
    required this.studentId,
    required this.classId,
    required this.month,
    required this.studentName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(
      invoicePaymentsProvider((studentId, classId, month)),
    );

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Phiếu thu đã ghi nhận',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$studentName • Tháng $month',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Chọn ⋮ trên từng phiếu để sửa ngày thu hoặc số tiền.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 10),
            paymentsAsync.when(
              loading: () => const AppLoadingState(),
              error: (err, stack) => Center(
                child: Text(
                  'Lỗi tải lịch sử: $err',
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
              data: (payments) {
                if (payments.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Text(
                        'Chưa có khoản thu nào trong tháng này',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: payments.length,
                  separatorBuilder: (_, __) =>
                      const Divider(color: AppColors.surfaceHigh, height: 16),
                  itemBuilder: (context, index) {
                    final p = payments[index];
                    final dateText = DateFormatter.formatDisplayDate(
                      p.paymentDate,
                    );

                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceHigh,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.payments_outlined,
                              color: AppColors.success,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppFormatter.formatCurrency(
                                    p.amount,
                                    context: context,
                                  ),
                                  style: const TextStyle(
                                    color: AppColors.success,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${p.method.displayName} • $dateText',
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                                if (p.transactionId != null &&
                                    p.transactionId!.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    'Mã GD: ${p.transactionId}',
                                    style: const TextStyle(
                                      color: AppColors.cyanAccent,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                                if (p.note != null && p.note!.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    'Ghi chú: ${p.note}',
                                    style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 11,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          PopupMenuButton<String>(
                            icon: const Icon(
                              Icons.more_vert,
                              color: AppColors.textSecondary,
                            ),
                            color: AppColors.surfaceHigh,
                            onSelected: (value) async {
                              if (value == 'edit') {
                                final updated =
                                    await showEditPaymentBottomSheet(
                                      context,
                                      studentId: studentId,
                                      classId: classId,
                                      month: month,
                                      existingPayment: p,
                                    );
                                if (updated == true && context.mounted) {
                                  ref.invalidate(
                                    invoicePaymentsProvider((
                                      studentId,
                                      classId,
                                      month,
                                    )),
                                  );
                                  ref.invalidate(
                                    classMonthTuitionOverviewProvider((
                                      classId,
                                      month,
                                    )),
                                  );
                                }
                              }
                            },
                            itemBuilder: (_) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.edit,
                                      color: AppColors.cyanAccent,
                                      size: 18,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Sửa phiếu thu',
                                      style: TextStyle(
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> showPaymentHistoryBottomSheet(
  BuildContext context, {
  required int studentId,
  required int classId,
  required String month,
  required String studentName,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    enableDrag: true,
    useSafeArea: true,
    builder: (_) => PaymentHistoryBottomSheet(
      studentId: studentId,
      classId: classId,
      month: month,
      studentName: studentName,
    ),
  );
}
