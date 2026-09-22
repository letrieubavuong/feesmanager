import '../../tuition/domain/tuition_invoice.dart';
import 'payment.dart';
import 'payment_settlement_rules.dart';

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
    return PaymentSettlementRules.evaluate(
      invoice: invoice,
      payments: payments,
    );
  }
}
