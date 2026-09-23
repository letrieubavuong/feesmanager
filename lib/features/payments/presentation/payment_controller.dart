import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../memberships/presentation/membership_providers.dart';
import '../../tuition/presentation/tuition_controller.dart';
import '../domain/invoice_payment_summary.dart';
import '../domain/payment.dart';
import '../domain/payment_method.dart';
import '../domain/payment_service.dart';

part 'payment_controller.g.dart';

@riverpod
Future<InvoicePaymentSummary?> invoicePaymentSummary(
  InvoicePaymentSummaryRef ref,
  (int studentId, int classId, String month) arg,
) async {
  final service = await ref.watch(paymentServiceProvider.future);
  return service.getPaymentSummary(arg.$1, arg.$2, arg.$3);
}

@riverpod
Future<Map<int, InvoicePaymentSummary>> classMonthPaymentSummaries(
  ClassMonthPaymentSummariesRef ref,
  (int classId, String month) arg,
) async {
  final service = await ref.watch(paymentServiceProvider.future);
  return service.getPaymentSummariesForClassMonth(arg.$1, arg.$2);
}

@riverpod
Future<List<Payment>> invoicePayments(
  InvoicePaymentsRef ref,
  (int studentId, int classId, String month) arg,
) async {
  final service = await ref.watch(paymentServiceProvider.future);
  return service.getPaymentsForStudentClassMonth(arg.$1, arg.$2, arg.$3);
}

@Riverpod(keepAlive: true)
class PaymentController extends _$PaymentController {
  @override
  FutureOr<void> build() {}

  Future<Payment> recordPayment({
    required int studentId,
    required int classId,
    required String month,
    required int amount,
    required String paymentDate,
    required PaymentMethod method,
    String? transactionId,
    String? note,
  }) async {
    state = const AsyncLoading();
    late Payment result;
    state = await AsyncValue.guard(() async {
      final service = await ref.read(paymentServiceProvider.future);
      result = await service.recordPayment(
        studentId: studentId,
        classId: classId,
        month: month,
        amount: amount,
        paymentDate: paymentDate,
        method: method,
        transactionId: transactionId,
        note: note,
      );

      // Invalidate dependent providers to trigger instant live refresh
      ref.invalidate(classMonthInvoicesProvider((classId, month)));
      ref.invalidate(studentInvoiceProvider(studentId, classId, month));
      ref.invalidate(
        tuitionPreviewControllerProvider(studentId, classId, month),
      );
      ref.invalidate(
        invoicePaymentSummaryProvider((studentId, classId, month)),
      );
      ref.invalidate(classMonthPaymentSummariesProvider((classId, month)));
      ref.invalidate(invoicePaymentsProvider((studentId, classId, month)));
      ref.invalidate(classMonthStudentsProvider((classId, month)));
      ref.invalidate(classTuitionPoliciesProvider(classId));
      ref.invalidate(effectiveTuitionPolicyProvider((classId, month)));
    });
    if (state.hasError) {
      throw state.error!;
    }
    return result;
  }
}
