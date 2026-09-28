import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../tuition/domain/parent_tuition_slip.dart';
import 'vietqr_code_widget.dart';

/// Professional parent tuition slip export card.
/// Light background (responsive width up to 360 logical px).
class PaymentQrShareCard extends StatelessWidget {
  final ParentTuitionSlip slip;

  const PaymentQrShareCard({super.key, required this.slip});

  String get _formattedMonth {
    if (slip.billingMonth.contains('-')) {
      try {
        final parsed = DateTime.parse('${slip.billingMonth}-01');
        return DateFormat('MM/yyyy').format(parsed);
      } catch (_) {}
    }
    return slip.billingMonth;
  }

  String _formatCurrency(int amount) {
    return '${NumberFormat('#,###', 'vi_VN').format(amount)}đ';
  }

  @override
  Widget build(BuildContext context) {
    if (!slip.isReady) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFECDD3), width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Color(0xFFE11D48)),
            const SizedBox(height: 12),
            Text(
              slip.errorMessage ?? 'Chưa sẵn sàng tạo phiếu học phí',
              style: const TextStyle(
                color: Color(0xFF9F1239),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final isFullyPaid = slip.remainingDebt <= 0;

    return Container(
      width: double.infinity,
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
              'PHIẾU HỌC PHÍ',
              style: TextStyle(
                color: Color(0xFF1E40AF),
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'THÁNG $_formattedMonth',
            style: const TextStyle(
              color: Color(0xFF475569),
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),

          // Student & Class Information
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
                        slip.studentName.toUpperCase(),
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
                        slip.className,
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
          const SizedBox(height: 14),

          // SECTION 1: KẾ HOẠCH HỌC TRONG THÁNG
          _buildSectionHeader('KẾ HOẠCH HỌC TRONG THÁNG ${slip.billingMonth}'),
          const SizedBox(height: 8),
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
                _buildRowItemWithIcon(
                  icon: Icons.calendar_month,
                  label: 'Buổi dự kiến',
                  value: '${slip.projectedSessionCount} buổi',
                ),
                const SizedBox(height: 6),
                _buildRowItemWithIcon(
                  icon: Icons.task_alt,
                  label: 'Buổi chuẩn',
                  value: '${slip.standardSessionLimit} buổi',
                ),
                const SizedBox(height: 6),
                _buildRowItemWithIcon(
                  icon: Icons.add_circle_outline,
                  label: 'Dự kiến vượt chuẩn',
                  value: '${slip.projectedExtraCount} buổi',
                ),
                const SizedBox(height: 6),
                _buildRowItemWithIcon(
                  icon: Icons.sell_outlined,
                  label: 'Đơn giá',
                  value: '${_formatCurrency(slip.feePerSession)} / buổi',
                ),
                if (slip.monthlyMaxFee != null && slip.monthlyMaxFee! > 0) ...[
                  const SizedBox(height: 6),
                  _buildRowItemWithIcon(
                    icon: Icons.shield_outlined,
                    label: 'Học phí tối đa',
                    value: _formatCurrency(slip.monthlyMaxFee!),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),

          // SECTION 2: ĐỐI SOÁT HỌC SINH THÁNG TRƯỚC
          _buildSectionHeader(
            'ĐỐI SOÁT HỌC SINH THÁNG ${slip.reconciliationMonth}',
          ),
          const SizedBox(height: 8),
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
                _buildRowItemWithIcon(
                  icon: Icons.swap_horiz,
                  label: 'Buổi dư chuyển sang',
                  value: '${slip.openingCreditBalance} buổi',
                  isHighlight: slip.openingCreditBalance > 0,
                ),
                const SizedBox(height: 6),
                _buildRowItemWithIcon(
                  icon: Icons.cancel_outlined,
                  label: 'Vắng không phép',
                  value: '${slip.unexcusedAbsenceCount} buổi',
                ),
                const SizedBox(height: 6),
                _buildRowItemWithIcon(
                  icon: Icons.event_busy,
                  label: 'Vắng có phép',
                  value: '${slip.excusedAbsenceCount} buổi',
                ),
                const SizedBox(height: 6),
                _buildRowItemWithIcon(
                  icon: Icons.access_time,
                  label: 'Đi trễ',
                  value: '${slip.lateCount} buổi',
                ),
                const SizedBox(height: 6),
                _buildRowItemWithIcon(
                  icon: Icons.sync,
                  label: 'Học bù đã hoàn thành',
                  value: '${slip.makeupCompletedCount} buổi',
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 6),
                  child: Divider(color: Color(0xFFE2E8F0), height: 1),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Lưu ý:',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        slip.reconciliationAsOfDate != null
                            ? 'Điểm danh tính đến ${slip.reconciliationAsOfDate}'
                            : 'Chưa có dữ liệu điểm danh tháng ${slip.reconciliationMonth}',
                        style: const TextStyle(
                          color: Color(0xFF475569),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // SECTION 3: HỌC PHÍ & THANH TOÁN
          _buildSectionHeader('HỌC PHÍ & THANH TOÁN'),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFDCFCE7)),
            ),
            child: Column(
              children: [
                _buildRowItem('Phải thu', _formatCurrency(slip.amountDue)),
                const SizedBox(height: 6),
                _buildRowItem(
                  'Đã thu',
                  _formatCurrency(slip.totalPaid),
                  valueColor: const Color(0xFF16A34A),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 6),
                  child: Divider(color: Color(0xFFBBF7D0), height: 1),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        isFullyPaid ? 'TRẠNG THÁI' : 'CÒN PHẢI CHUYỂN',
                        style: const TextStyle(
                          color: Color(0xFF15803D),
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isFullyPaid
                          ? 'ĐÃ NỘP ĐỦ'
                          : _formatCurrency(slip.remainingDebt),
                      style: TextStyle(
                        color: isFullyPaid
                            ? const Color(0xFF16A34A)
                            : const Color(0xFFB91C1C),
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // SECTION 4: QR CODE OR FULLY PAID BADGE
          if (!isFullyPaid && slip.qrPayload.isNotEmpty) ...[
            VietQrCodeWidget(
              payload: slip.qrPayload,
              size: 220,
              backgroundColor: Colors.white,
              color: const Color(0xFF0F172A),
            ),
            const SizedBox(height: 14),

            // Bank details table
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
                  _buildBankInfoRow('Ngân hàng', slip.bank.bankName),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 6),
                    child: Divider(color: Color(0xFFE2E8F0), height: 1),
                  ),
                  _buildBankInfoRow(
                    'Số TK',
                    slip.bank.accountNumber,
                    isHighlight: true,
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 6),
                    child: Divider(color: Color(0xFFE2E8F0), height: 1),
                  ),
                  _buildBankInfoRow('Chủ TK', slip.bank.accountHolder),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 6),
                    child: Divider(color: Color(0xFFE2E8F0), height: 1),
                  ),
                  _buildBankInfoRow(
                    'Nội dung CK',
                    slip.transferContent,
                    isHighlight: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
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
          ] else if (isFullyPaid) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF86EFAC)),
              ),
              child: const Column(
                children: [
                  Icon(Icons.check_circle, size: 48, color: Color(0xFF16A34A)),
                  SizedBox(height: 8),
                  Text(
                    'ĐÃ THANH TOÁN ĐỦ HỌC PHÍ',
                    style: TextStyle(
                      color: Color(0xFF15803D),
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Cảm ơn phụ huynh đã hoàn tất học phí tháng!',
                    style: TextStyle(color: Color(0xFF166534), fontSize: 12),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 14),

          // Small Footer Disclaimer Note
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  '* Số buổi dự kiến dựa trên lịch học hiện hành. Điểm danh và buổi dư được đối soát theo dữ liệu thực tế tháng trước.',
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF334155),
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildRowItemWithIcon({
    required IconData icon,
    required String label,
    required String value,
    bool isHighlight = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: const Color(0xFF64748B)),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: TextStyle(
            color: isHighlight
                ? const Color(0xFF1E40AF)
                : const Color(0xFF0F172A),
            fontSize: 13,
            fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildRowItem(
    String label,
    String value, {
    bool isHighlight = false,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: TextStyle(
            color:
                valueColor ??
                (isHighlight
                    ? const Color(0xFF1E40AF)
                    : const Color(0xFF0F172A)),
            fontSize: 13,
            fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildBankInfoRow(
    String label,
    String value, {
    bool isHighlight = false,
  }) {
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
