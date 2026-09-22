import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../memberships/presentation/membership_providers.dart';
import '../domain/invoice_service.dart';
import '../domain/tuition_invoice.dart';
import '../domain/tuition_policy.dart';
import '../domain/tuition_policy_service.dart';
import '../domain/tuition_preview.dart';
import '../domain/tuition_service.dart';

part 'tuition_controller.g.dart';

@riverpod
Future<List<TuitionPolicy>> classTuitionPolicies(
  ClassTuitionPoliciesRef ref,
  int classId,
) async {
  final service = await ref.watch(tuitionPolicyServiceProvider.future);
  return service.getPoliciesForClass(classId);
}

@riverpod
class TuitionPreviewController extends _$TuitionPreviewController {
  @override
  FutureOr<TuitionPreview> build(
    int studentId,
    int classId,
    String month,
  ) async {
    final service = await ref.watch(tuitionServiceProvider.future);
    return service.previewTuition(studentId, classId, month);
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final service = await ref.read(tuitionServiceProvider.future);
      return service.previewTuition(studentId, classId, month);
    });
  }
}

@riverpod
Future<TuitionInvoice?> studentInvoice(
  StudentInvoiceRef ref,
  int studentId,
  int classId,
  String month,
) async {
  final service = await ref.watch(invoiceServiceProvider.future);
  return service.getInvoice(studentId, classId, month);
}

@riverpod
class InvoiceController extends _$InvoiceController {
  @override
  FutureOr<void> build() {}

  Future<TuitionInvoice> finalizeStudentInvoice({
    required int studentId,
    required int classId,
    required String month,
  }) async {
    state = const AsyncLoading();
    late TuitionInvoice result;
    state = await AsyncValue.guard(() async {
      final service = await ref.read(invoiceServiceProvider.future);
      result = await service.finalizeStudentInvoice(studentId, classId, month);
      ref.invalidate(studentInvoiceProvider(studentId, classId, month));
      ref.invalidate(
        tuitionPreviewControllerProvider(studentId, classId, month),
      );
      ref.invalidate(classTuitionPoliciesProvider(classId));
      ref.invalidate(classMonthMembershipsProvider((classId, month)));
      ref.invalidate(classMonthStudentsProvider((classId, month)));
      ref.invalidate(classRosterProvider);
    });
    if (state.hasError) {
      throw state.error!;
    }
    return result;
  }

  Future<List<TuitionInvoice>> finalizeClassInvoices({
    required int classId,
    required String month,
  }) async {
    state = const AsyncLoading();
    late List<TuitionInvoice> result;
    state = await AsyncValue.guard(() async {
      final service = await ref.read(invoiceServiceProvider.future);
      result = await service.finalizeClassInvoices(classId, month);
      ref.invalidate(classTuitionPoliciesProvider(classId));
      ref.invalidate(classMonthMembershipsProvider((classId, month)));
      ref.invalidate(classMonthStudentsProvider((classId, month)));
      ref.invalidate(classRosterProvider);
    });
    if (state.hasError) {
      throw state.error!;
    }
    return result;
  }
}
