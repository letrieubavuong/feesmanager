import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../app/common_widgets/app_feedback.dart';
import '../../../app/common_widgets/navy_components.dart';
import '../../../app/design_system/app_theme.dart';
import '../../settings/domain/vietqr_generator.dart';
import '../../settings/presentation/bank_account_settings_controller.dart';
import '../../settings/presentation/bank_account_settings_page.dart';
import 'widgets/payment_qr_share_card.dart';

class VietQrPaymentPage extends ConsumerStatefulWidget {
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
  ConsumerState<VietQrPaymentPage> createState() => _VietQrPaymentPageState();
}

class _VietQrPaymentPageState extends ConsumerState<VietQrPaymentPage> {
  final GlobalKey _cardKey = GlobalKey();
  bool _isSharing = false;

  Future<void> _shareCardImage(
    BuildContext context,
    String transferContent,
  ) async {
    if (_isSharing) return;

    setState(() {
      _isSharing = true;
    });

    try {
      final boundary =
          _cardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        throw Exception('Không thể chụp hình thẻ QR');
      }

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw Exception('Lỗi chuyển đổi hình ảnh QR');
      }

      final pngBytes = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final codeClean = widget.studentCode ?? 'hs';
      final fileMonth = widget.month.replaceAll('-', '');
      final fileName = 'hoc_phi_${codeClean}_$fileMonth.png';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(pngBytes);

      if (!context.mounted) return;

      // ignore: deprecated_member_use
      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'Học phí tháng ${widget.month} - ${widget.studentName}');
    } catch (e) {
      if (context.mounted) {
        AppFeedback.showErrorSnackBar(
          context,
          'Lỗi chia sẻ ảnh QR: ${e.toString().replaceAll('Exception: ', '')}',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSharing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
      studentCode: widget.studentCode,
      studentName: widget.studentName,
      className: widget.className,
      month: widget.month,
    );

    final qrPayload = VietQrGenerator.generateEmvCoPayload(
      settings: settings,
      amount: widget.remainingAmount,
      transferContent: transferContent,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Mã QR Thanh Toán'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // RepaintBoundary wrapping light PaymentQrShareCard
            Center(
              child: RepaintBoundary(
                key: _cardKey,
                child: PaymentQrShareCard(
                  studentName: widget.studentName,
                  className: widget.className,
                  month: widget.month,
                  remainingAmount: widget.remainingAmount,
                  bankName: settings.bankName,
                  accountNumber: settings.accountNumber,
                  accountHolder: settings.accountHolder,
                  transferContent: transferContent,
                  qrPayload: qrPayload,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Action Buttons
            SizedBox(
              width: 360,
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _isSharing
                          ? null
                          : () => _shareCardImage(context, transferContent),
                      icon: _isSharing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.share_outlined, size: 20),
                      label: Text(
                        _isSharing ? 'Đang tạo ảnh...' : 'Chia sẻ ảnh',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.cyanAccent,
                        side: const BorderSide(color: AppColors.cyanAccent),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: transferContent));
                        AppFeedback.showSuccessSnackBar(
                          context,
                          'Đã sao chép nội dung chuyển khoản',
                        );
                      },
                      icon: const Icon(Icons.copy_outlined, size: 18),
                      label: const Text(
                        'Sao chép nội dung CK',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
