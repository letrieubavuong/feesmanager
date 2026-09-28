import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../app/common_widgets/app_feedback.dart';
import '../../../app/common_widgets/app_loading_state.dart';
import '../../../app/common_widgets/navy_components.dart';
import '../../../app/design_system/app_theme.dart';
import '../../sessions/domain/session_generation_service.dart';
import '../../settings/presentation/bank_account_settings_page.dart';
import '../../tuition/domain/parent_tuition_slip.dart';
import '../../tuition/presentation/parent_tuition_slip_controller.dart';
import '../../tuition/presentation/tuition_controller.dart';
import 'widgets/payment_qr_share_card.dart';

class VietQrPaymentPage extends ConsumerStatefulWidget {
  final int studentId;
  final int classId;
  final String month;
  final String? studentName;
  final String? className;
  final int? remainingAmount;

  const VietQrPaymentPage({
    super.key,
    required this.studentId,
    required this.classId,
    required this.month,
    this.studentName,
    this.className,
    this.remainingAmount,
  });

  @override
  ConsumerState<VietQrPaymentPage> createState() => _VietQrPaymentPageState();
}

class _VietQrPaymentPageState extends ConsumerState<VietQrPaymentPage> {
  final GlobalKey _cardKey = GlobalKey();
  bool _isSharing = false;

  Future<void> _shareCardImage(
    BuildContext context,
    ParentTuitionSlip slip,
  ) async {
    if (_isSharing) return;

    setState(() {
      _isSharing = true;
    });

    try {
      final boundary =
          _cardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        throw Exception('Không thể chụp hình thẻ phiếu học phí');
      }

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw Exception('Lỗi chuyển đổi hình ảnh QR');
      }

      final pngBytes = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final fileMonth = widget.month.replaceAll('-', '');
      final fileName =
          'phieu_hoc_phi_${widget.studentId}_${widget.classId}_$fileMonth.png';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(pngBytes);

      if (!context.mounted) return;

      // ignore: deprecated_member_use
      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'Phiếu học phí tháng ${widget.month} - ${slip.studentName}');
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
    final slipAsync = ref.watch(
      parentTuitionSlipProvider((
        widget.studentId,
        widget.classId,
        widget.month,
      )),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Phiếu Học Phí & QR'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(
                parentTuitionSlipProvider((
                  widget.studentId,
                  widget.classId,
                  widget.month,
                )),
              );
            },
          ),
        ],
      ),
      body: slipAsync.when(
        loading: () => const Center(child: AppLoadingState()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: AppSectionCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Lỗi nạp dữ liệu phiếu học phí: $err',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.error),
                  ),
                ],
              ),
            ),
          ),
        ),
        data: (slip) => _buildBodyForSlip(context, slip),
      ),
    );
  }

  Widget _buildBodyForSlip(BuildContext context, ParentTuitionSlip slip) {
    if (slip.status == ParentTuitionSlipStatus.bankNotConfigured) {
      return Center(
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
      );
    }

    if (slip.status == ParentTuitionSlipStatus.projectedSessionsNotGenerated) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: AppSectionCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 56,
                  color: AppColors.warning,
                ),
                const SizedBox(height: 16),
                Text(
                  'Chưa sinh đủ buổi học tháng ${widget.month}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Vui lòng sinh buổi học tháng theo lịch định kỳ để tính chính xác số buổi dự kiến.',
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
                  onPressed: () async {
                    try {
                      final parts = widget.month.split('-');
                      final year = int.parse(parts[0]);
                      final month = int.parse(parts[1]);
                      final fromDate = DateTime(year, month, 1);
                      final toDate = DateTime(year, month + 1, 0);

                      final genService = await ref.read(
                        sessionGenerationServiceProvider.future,
                      );
                      final result = await genService.generateForClass(
                        classId: widget.classId,
                        fromDate: fromDate,
                        toDate: toDate,
                      );
                      if (context.mounted) {
                        AppFeedback.showSuccessSnackBar(
                          context,
                          'Đã sinh thành công ${result.createdCount} buổi học',
                        );
                        ref.invalidate(
                          parentTuitionSlipProvider((
                            widget.studentId,
                            widget.classId,
                            widget.month,
                          )),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        AppFeedback.showErrorSnackBar(
                          context,
                          'Lỗi sinh buổi học: ${e.toString().replaceAll('Exception: ', '')}',
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.auto_awesome, size: 18),
                  label: const Text('Sinh buổi học tháng'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (slip.status == ParentTuitionSlipStatus.noInvoiceFinalized) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: AppSectionCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.receipt_long_outlined,
                  size: 56,
                  color: AppColors.warning,
                ),
                const SizedBox(height: 16),
                Text(
                  'Chưa chốt học phí tháng ${widget.month}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Cần chốt học phí trước để đảm bảo tính chính xác số tiền cần chuyển.',
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
                  onPressed: () async {
                    try {
                      await ref
                          .read(invoiceControllerProvider.notifier)
                          .finalizeStudentInvoice(
                            studentId: widget.studentId,
                            classId: widget.classId,
                            month: widget.month,
                          );
                      if (context.mounted) {
                        AppFeedback.showSuccessSnackBar(
                          context,
                          'Đã chốt học phí thành công',
                        );
                        ref.invalidate(
                          parentTuitionSlipProvider((
                            widget.studentId,
                            widget.classId,
                            widget.month,
                          )),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        AppFeedback.showErrorSnackBar(
                          context,
                          'Lỗi chốt học phí: ${e.toString().replaceAll('Exception: ', '')}',
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text('Chốt học phí cho học sinh'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // RepaintBoundary wrapping light PaymentQrShareCard
          Center(
            child: RepaintBoundary(
              key: _cardKey,
              child: PaymentQrShareCard(slip: slip),
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
                        : () => _shareCardImage(context, slip),
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
                      _isSharing ? 'Đang tạo ảnh...' : 'Chia sẻ phiếu học phí',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                if (slip.remainingDebt > 0 &&
                    slip.transferContent.isNotEmpty) ...[
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
                        Clipboard.setData(
                          ClipboardData(text: slip.transferContent),
                        );
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
