import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'vietqr_code_widget.dart';

/// Clean light-background payment card designed for export/share to parents.
class PaymentQrShareCard extends StatelessWidget {
  final String studentName;
  final String className;
  final String month;
  final int remainingAmount;
  final String bankName;
  final String accountNumber;
  final String accountHolder;
  final String transferContent;
  final String qrPayload;

  const PaymentQrShareCard({
    super.key,
    required this.studentName,
    required this.className,
    required this.month,
    required this.remainingAmount,
    required this.bankName,
    required this.accountNumber,
    required this.accountHolder,
    required this.transferContent,
    required this.qrPayload,
  });

  String get _formattedMonth {
    if (month.contains('-')) {
      try {
        final parsed = DateTime.parse('$month-01');
        return DateFormat('MM/yyyy').format(parsed);
      } catch (_) {}
    }
    return month;
  }

  String get _formattedAmount {
    return '${NumberFormat('#,###', 'vi_VN').format(remainingAmount)}đ';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 360,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'THÔNG TIN HỌC PHÍ',
              style: TextStyle(
                color: Color(0xFF1E40AF),
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tháng $_formattedMonth',
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),

          // Student & Class Info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Học sinh:',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        studentName,
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.end,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Lớp học:',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        className,
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.end,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Amount Section
          const Text(
            'SỐ TIỀN CẦN CHUYỂN',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _formattedAmount,
            style: const TextStyle(
              color: Color(0xFF15803D),
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),

          // QR Code Display (Local EMVCo QR, Size 220)
          VietQrCodeWidget(
            payload: qrPayload,
            size: 220,
            backgroundColor: Colors.white,
            color: const Color(0xFF0F172A),
          ),
          const SizedBox(height: 16),

          // Bank Details Table
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Column(
              children: [
                _buildInfoRow('Ngân hàng', bankName),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 6),
                  child: Divider(color: Color(0xFFE2E8F0), height: 1),
                ),
                _buildInfoRow('Số TK', accountNumber, isHighlight: true),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 6),
                  child: Divider(color: Color(0xFFE2E8F0), height: 1),
                ),
                _buildInfoRow('Chủ TK', accountHolder),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 6),
                  child: Divider(color: Color(0xFFE2E8F0), height: 1),
                ),
                _buildInfoRow(
                  'Nội dung CK',
                  transferContent,
                  isHighlight: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Footer Instruction
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline, size: 14, color: Color(0xFF94A3B8)),
              SizedBox(width: 4),
              Flexible(
                child: Text(
                  'Vui lòng chuyển đúng số tiền và nội dung trên.',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: isHighlight
                  ? const Color(0xFF1E40AF)
                  : const Color(0xFF0F172A),
              fontSize: 13,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
