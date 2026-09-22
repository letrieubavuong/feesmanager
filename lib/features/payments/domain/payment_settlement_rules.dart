import '../../tuition/domain/tuition_invoice.dart';
import 'invoice_payment_summary.dart';
import 'payment.dart';

class PaymentSettlementRules {
  static InvoicePaymentSummary evaluate({
    required TuitionInvoice invoice,
    required List<Payment> payments,
  }) {
    // 1. Validate payment-invoice relationship
    for (final p in payments) {
      if (p.invoiceId != null && p.invoiceId != invoice.id) {
        throw Exception(
          'Lỗi bất biến dữ liệu thanh toán: Payment #${p.id} có invoiceId (${p.invoiceId}) không khớp với invoice #${invoice.id}',
        );
      }
      if (p.studentId != invoice.idHocSinh ||
          p.classId != invoice.idLop ||
          p.month != invoice.thang) {
        throw Exception(
          'Lỗi bất biến dữ liệu thanh toán: Payment #${p.id} không khớp thông tin học sinh, lớp hoặc tháng với hóa đơn #${invoice.id}',
        );
      }
    }

    final amountDue = invoice.soTienPhaiThu;
    final totalPaid = payments.fold<int>(0, (sum, p) => sum + p.amount);

    // Fail closed on overpayment corruption
    if (totalPaid > amountDue) {
      throw Exception(
        'Lỗi bất biến dữ liệu thanh toán: Tổng số tiền đã trả ($totalPaidđ) vượt quá tiền phải thu ($amountDueđ) cho hóa đơn #${invoice.id}',
      );
    }

    final remainingDebt = amountDue - totalPaid;

    final TuitionInvoiceStatus expectedStatus;
    if (invoice.trangThai == TuitionInvoiceStatus.NHAP) {
      if (payments.isNotEmpty) {
        throw Exception(
          'Lỗi bất biến dữ liệu: Hóa đơn nháp không được phép chứa giao dịch thanh toán.',
        );
      }
      expectedStatus = TuitionInvoiceStatus.NHAP;
    } else if (totalPaid == 0) {
      expectedStatus = TuitionInvoiceStatus.DA_CHOT;
    } else if (totalPaid == amountDue) {
      expectedStatus = TuitionInvoiceStatus.DA_THANH_TOAN;
    } else {
      expectedStatus = TuitionInvoiceStatus.CON_NO;
    }

    // Fail closed if persisted invoice status conflicts with canonical payment truth
    if (invoice.trangThai.isFinalizedSnapshot &&
        invoice.trangThai != expectedStatus) {
      throw Exception(
        'Lỗi bất biến trạng thái hóa đơn: Trạng thái chốt trên DB (${invoice.trangThai.name}) mâu thuẫn với tổng số tiền đã thanh toán ($totalPaidđ / $amountDueđ, kỳ vọng: ${expectedStatus.name})',
      );
    }

    return InvoicePaymentSummary(
      invoice: invoice,
      payments: payments,
      amountDue: amountDue,
      totalPaid: totalPaid,
      remainingDebt: remainingDebt,
      paymentCount: payments.length,
      settlementStatus: expectedStatus,
    );
  }

  static TuitionInvoiceStatus deriveStatus({
    required bool isFinalized,
    required int amountDue,
    required int totalPaid,
  }) {
    if (!isFinalized) return TuitionInvoiceStatus.NHAP;
    if (totalPaid > amountDue) {
      throw Exception(
        'Lỗi bất biến dữ liệu: Tổng thanh toán ($totalPaidđ) vượt quá tiền phải thu ($amountDueđ).',
      );
    }
    if (totalPaid == 0) return TuitionInvoiceStatus.DA_CHOT;
    if (totalPaid == amountDue) return TuitionInvoiceStatus.DA_THANH_TOAN;
    return TuitionInvoiceStatus.CON_NO;
  }
}
