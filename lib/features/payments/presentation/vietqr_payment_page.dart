import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/common_widgets/app_feedback.dart';
import '../../../app/common_widgets/navy_components.dart';
import '../../../app/design_system/app_theme.dart';
import '../../settings/domain/vietqr_generator.dart';
import '../../settings/presentation/bank_account_settings_controller.dart';
import '../../settings/presentation/bank_account_settings_page.dart';

class VietQrPaymentPage extends ConsumerWidget {
  final String studentName;
  final String? studentCode;
  final String className;
  final String month;
  final int remainingAmount;

  const VietQrPaymentPage({
    super.key,
    required this.studentName,
    this.studentCode,
    required this.className,
    required this.month,
    required this.remainingAmount,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(bankAccountSettingsProvider);

    if (!settings.isConfigured) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Thanh toán QR')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: AppSectionCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.account_balance_outlined,
                    size: 56,
                    color: AppColors.warning,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Chưa thiết lập tài khoản nhận học phí',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Vui lòng cấu hình Ngân hàng và Số tài khoản để tự động tạo mã QR chuyển khoản.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const BankAccountSettingsPage(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.settings_outlined, size: 18),
                    label: const Text('Thiết lập tài khoản nhận học phí'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final transferContent = VietQrGenerator.formatTransferContent(
      template: settings.transferTemplate,
      studentCode: studentCode ?? studentName,
      month: month,
    );

    final qrImageUrl =
        'https://api.vietqr.io/image/${settings.bankBin}-${settings.accountNumber}-compact.png?amount=$remainingAmount&addInfo=${Uri.encodeComponent(transferContent)}&accountName=${Uri.encodeComponent(settings.accountHolder)}';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Mã QR Thanh Toán')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            AppSectionCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    'QUÉT MÃ QR ĐỂ THANH TOÁN',
                    style: TextStyle(
                      color: AppColors.cyanAccent,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(12),
                      child: Image.network(
                        qrImageUrl,
                        width: 240,
                        height: 240,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 240,
                            height: 240,
                            color: Colors.grey.shade200,
                            child: const Center(
                              child: Text(
                                'Không thể tải mã QR.\nVui lòng kiểm tra kết nối mạng.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${remainingAmount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} đ',
                    style: const TextStyle(
                      color: AppColors.success,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Học sinh: $studentName • Lớp: $className',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AppSectionCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildCopyRow(
                    context,
                    label: 'Ngân hàng',
                    value: settings.bankName,
                  ),
                  const Divider(color: AppColors.border, height: 16),
                  _buildCopyRow(
                    context,
                    label: 'Số tài khoản',
                    value: settings.accountNumber,
                    canCopy: true,
                  ),
                  const Divider(color: AppColors.border, height: 16),
                  _buildCopyRow(
                    context,
                    label: 'Chủ tài khoản',
                    value: settings.accountHolder,
                  ),
                  const Divider(color: AppColors.border, height: 16),
                  _buildCopyRow(
                    context,
                    label: 'Nội dung chuyển khoản',
                    value: transferContent,
                    canCopy: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCopyRow(
    BuildContext context, {
    required String label,
    required String value,
    bool canCopy = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        if (canCopy)
          IconButton(
            icon: const Icon(
              Icons.copy_outlined,
              color: AppColors.cyanAccent,
              size: 18,
            ),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: value));
              AppFeedback.showSuccessSnackBar(context, 'Đã sao chép $label');
            },
          ),
      ],
    );
  }
}
