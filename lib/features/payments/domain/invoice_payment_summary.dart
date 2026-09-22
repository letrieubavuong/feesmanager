import '../../tuition/domain/tuition_invoice.dart';
import 'payment.dart';

class InvoicePaymentSummary {
  final TuitionInvoice invoice;
  final List<Payment> payments;
  final int amountDue;
  final int totalPaid;
  final int remainingDebt;
  final int paymentCount;
  final TuitionInvoiceStatus settlementStatus;

  InvoicePaymentSummary({
    required this.invoice,
    required this.payments,
    required this.amountDue,
    required this.totalPaid,
    required this.remainingDebt,
    required this.paymentCount,
    required this.settlementStatus,
  });

  factory InvoicePaymentSummary.calculate({
    required TuitionInvoice invoice,
    required List<Payment> payments,
  }) {
    final amountDue = invoice.soTienPhaiThu;
    final totalPaid = payments.fold<int>(0, (sum, p) => sum + p.amount);
    final remainingDebt = amountDue > totalPaid ? amountDue - totalPaid : 0;

    final TuitionInvoiceStatus derivedStatus;
    if (invoice.trangThai == TuitionInvoiceStatus.NHAP) {
      derivedStatus = TuitionInvoiceStatus.NHAP;
    } else if (totalPaid == 0) {
      derivedStatus = TuitionInvoiceStatus.DA_CHOT;
    } else if (totalPaid >= amountDue) {
      derivedStatus = TuitionInvoiceStatus.DA_THANH_TOAN;
    } else {
      derivedStatus = TuitionInvoiceStatus.CON_NO;
    }

    return InvoicePaymentSummary(
      invoice: invoice,
      payments: payments,
      amountDue: amountDue,
      totalPaid: totalPaid,
      remainingDebt: remainingDebt,
      paymentCount: payments.length,
      settlementStatus: derivedStatus,
    );
  }
}
