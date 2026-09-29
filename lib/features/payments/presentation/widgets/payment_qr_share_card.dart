import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../tuition/domain/parent_tuition_slip.dart';
import 'vietqr_code_widget.dart';

/// The image shared with a parent: identity, balance and payment instructions.
class PaymentQrShareCard extends StatelessWidget {
  final ParentTuitionSlip slip;

  const PaymentQrShareCard({super.key, required this.slip});

  String get _month {
    try {
      return DateFormat('MM/yyyy').format(DateTime.parse('${slip.billingMonth}-01'));
    } catch (_) {
      return slip.billingMonth;
    }
  }

  String _money(int amount) => '${NumberFormat('#,###', 'vi_VN').format(amount)}đ';

  @override
  Widget build(BuildContext context) {
    if (!slip.isReady) {
      return _panel(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            slip.errorMessage ?? 'Chưa sẵn sàng tạo phiếu học phí',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF9F1239)),
          ),
        ),
      );
    }

    final fullyPaid = slip.remainingDebt <= 0;
    return _panel(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.school_outlined, color: Color(0xFF087B9A), size: 26),
            const SizedBox(height: 4),
            const Text('HỌC PHÍ', style: TextStyle(
              color: Color(0xFF12324B), fontSize: 17, fontWeight: FontWeight.w800)),
            Text('Tháng $_month', style: const TextStyle(
              color: Color(0xFF64748B), fontSize: 12)),
            const SizedBox(height: 14),
            _row('Học sinh', slip.studentName, bold: true),
            const SizedBox(height: 5),
            _row('Lớp', slip.className),
            const Divider(height: 22, color: Color(0xFFE2E8F0)),
            _row('Học phí phải thu', _money(slip.amountDue)),
            const SizedBox(height: 5),
            _row('Đã thanh toán', _money(slip.totalPaid)),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: fullyPaid ? const Color(0xFFF0FDF4) : const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: _row(
                fullyPaid ? 'Trạng thái' : 'Còn cần thanh toán',
                fullyPaid ? 'ĐÃ THANH TOÁN ĐỦ' : _money(slip.remainingDebt),
                bold: true,
                color: fullyPaid ? const Color(0xFF15803D) : const Color(0xFF1D4ED8),
              ),
            ),
            if (!fullyPaid) ...[
              const SizedBox(height: 14),
              if (slip.qrPayload.isNotEmpty) ...[
                VietQrCodeWidget(
                  payload: slip.qrPayload,
                  size: 190,
                  backgroundColor: Colors.white,
                  color: const Color(0xFF0F172A),
                ),
                const SizedBox(height: 8),
              ],
              _row('Ngân hàng', slip.bank.bankName),
              const SizedBox(height: 5),
              _row('Số tài khoản', slip.bank.accountNumber, bold: true),
              const SizedBox(height: 5),
              _row('Chủ tài khoản', slip.bank.accountHolder),
              const SizedBox(height: 5),
              _row('Nội dung CK', slip.transferContent, bold: true),
              const SizedBox(height: 10),
              const Text(
                'Vui lòng kiểm tra số tiền và nội dung chuyển khoản trước khi xác nhận.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF64748B), fontSize: 10),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _panel({required Widget child}) => Container(
    width: double.infinity,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE2E8F0)),
    ),
    child: child,
  );

  Widget _row(String label, String value, {bool bold = false, Color? color}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 112,
          child: Text(label, style: const TextStyle(
            color: Color(0xFF64748B), fontSize: 12)),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(value, textAlign: TextAlign.end,
            style: TextStyle(color: color ?? const Color(0xFF0F172A),
              fontSize: 12, fontWeight: bold ? FontWeight.bold : FontWeight.w500)),
        ),
      ],
    );
  }
}
