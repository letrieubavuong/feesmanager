import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../memberships/domain/membership_service.dart';
import '../../memberships/presentation/membership_providers.dart';
import '../../payments/domain/payment_service.dart';
import '../../payments/presentation/payment_controller.dart';
import '../../students/domain/student_service.dart';
import '../domain/class_month_tuition_overview.dart';
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
Future<TuitionPolicy?> effectiveTuitionPolicy(
  EffectiveTuitionPolicyRef ref,
  (int classId, String month) arg,
) async {
  final service = await ref.watch(tuitionPolicyServiceProvider.future);
  final dateStr = '${arg.$2}-01';
  return service.getEffectivePolicyForDateStr(arg.$1, dateStr);
}

@riverpod
Future<List<TuitionInvoice>> classMonthInvoices(
  ClassMonthInvoicesRef ref,
  (int classId, String month) arg,
) async {
  final service = await ref.watch(invoiceServiceProvider.future);
  return service.getInvoicesForClassMonth(arg.$1, arg.$2);
}

@riverpod
class TuitionPolicyController extends _$TuitionPolicyController {
  @override
  FutureOr<void> build() {}

  Future<TuitionPolicy> createPolicy({
    required int classId,
    required String effectiveFrom,
    String? effectiveTo,
    int standardSessionsPerMonth =
        TuitionPolicyDefaults.standardSessionsPerMonth,
    required int feePerSession,
    int? monthlyMaxFee,
    String? note,
  }) async {
    state = const AsyncLoading();
    late TuitionPolicy result;
    state = await AsyncValue.guard(() async {
      final service = await ref.read(tuitionPolicyServiceProvider.future);
      result = await service.createPolicy(
        classId: classId,
        effectiveFrom: effectiveFrom,
        effectiveTo: effectiveTo,
        standardSessionsPerMonth: standardSessionsPerMonth,
        feePerSession: feePerSession,
        monthlyMaxFee: monthlyMaxFee,
        note: note,
      );

      ref.invalidate(classTuitionPoliciesProvider(classId));
      ref.invalidate(effectiveTuitionPolicyProvider);
      ref.invalidate(tuitionPreviewControllerProvider);
    });
    if (state.hasError) {
      throw state.error!;
    }
    return result;
  }
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
      ref.invalidate(classMonthInvoicesProvider((classId, month)));
      ref.invalidate(classMonthPaymentSummariesProvider((classId, month)));
      ref.invalidate(
        invoicePaymentSummaryProvider((studentId, classId, month)),
      );
      ref.invalidate(classTuitionPoliciesProvider(classId));
      ref.invalidate(effectiveTuitionPolicyProvider((classId, month)));
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

      for (final invoice in result) {
        ref.invalidate(
          studentInvoiceProvider(
            invoice.idHocSinh,
            invoice.idLop,
            invoice.thang,
          ),
        );
        ref.invalidate(
          tuitionPreviewControllerProvider(
            invoice.idHocSinh,
            invoice.idLop,
            invoice.thang,
          ),
        );
        ref.invalidate(
          invoicePaymentSummaryProvider((
            invoice.idHocSinh,
            invoice.idLop,
            invoice.thang,
          )),
        );
      }

      ref.invalidate(classMonthInvoicesProvider((classId, month)));
      ref.invalidate(classMonthPaymentSummariesProvider((classId, month)));
      ref.invalidate(classMonthTuitionOverviewProvider((classId, month)));
      ref.invalidate(classTuitionPoliciesProvider(classId));
      ref.invalidate(effectiveTuitionPolicyProvider((classId, month)));
      ref.invalidate(classMonthMembershipsProvider((classId, month)));
      ref.invalidate(classMonthStudentsProvider((classId, month)));
      ref.invalidate(classRosterProvider);
    });
    if (state.hasError) {
      throw state.error!;
    }
    return result;
  }

  Future<TuitionInvoice> recalculateInvoice({
    required int studentId,
    required int classId,
    required String month,
    required String reason,
  }) async {
    state = const AsyncLoading();
    late TuitionInvoice result;
    state = await AsyncValue.guard(() async {
      final service = await ref.read(invoiceServiceProvider.future);
      result = await service.recalculateFinalizedInvoiceWithoutPayments(
        studentId: studentId,
        classId: classId,
        month: month,
        reason: reason,
      );
      ref.invalidate(studentInvoiceProvider(studentId, classId, month));
      ref.invalidate(
        tuitionPreviewControllerProvider(studentId, classId, month),
      );
      ref.invalidate(classMonthInvoicesProvider((classId, month)));
      ref.invalidate(classMonthPaymentSummariesProvider((classId, month)));
      ref.invalidate(classMonthTuitionOverviewProvider((classId, month)));
    });
    if (state.hasError) {
      throw state.error!;
    }
    return result;
  }
}

@riverpod
Future<ClassMonthTuitionOverview> classMonthTuitionOverview(
  ClassMonthTuitionOverviewRef ref,
  (int classId, String month) arg,
) async {
  final classId = arg.$1;
  final month = arg.$2;

  final membershipService = await ref.watch(membershipServiceProvider.future);
  final invoiceService = await ref.watch(invoiceServiceProvider.future);
  final paymentService = await ref.watch(paymentServiceProvider.future);
  final tuitionService = await ref.watch(tuitionServiceProvider.future);
  final studentRepo = await ref.watch(studentRepositoryProvider.future);

  final classMonthMemberships = await membershipService
      .getMembershipsForClassMonth(classId, month);
  final studentIds = classMonthMemberships.map((m) => m.idHocSinh).toSet();

  final invoices = await invoiceService.getInvoicesForClassMonth(
    classId,
    month,
  );
  final invoiceMap = {for (final inv in invoices) inv.idHocSinh: inv};

  final paymentSummaries = await paymentService
      .getPaymentSummariesForClassMonth(classId, month);

  final students = await studentRepo.getByIds(studentIds.toList());
  final studentMap = {for (final s in students) s.id!: s};

  int previewTotalDue = 0;
  int finalizedTotalDue = 0;
  int totalPaid = 0;
  int remainingDebt = 0;

  int previewStudentCount = 0;
  int finalizedStudentCount = 0;
  int pendingStudentCount = 0;

  final studentRows = <ClassMonthTuitionStudentRow>[];

  for (final sid in studentIds) {
    final student = studentMap[sid];
    if (student == null) continue;

    final invoice = invoiceMap[sid];
    final summary = paymentSummaries[sid];

    if (invoice != null && invoice.trangThai.isFinalizedSnapshot) {
      finalizedStudentCount++;
      finalizedTotalDue += invoice.soTienPhaiThu;
      final pPaid = summary?.totalPaid ?? 0;
      final rDebt = summary?.remainingDebt ?? (invoice.soTienPhaiThu - pPaid);
      totalPaid += pPaid;
      remainingDebt += rDebt;

      ClassStudentTuitionState st;
      if (rDebt <= 0) {
        st = ClassStudentTuitionState.PAID;
      } else if (pPaid > 0) {
        st = ClassStudentTuitionState.PARTIALLY_PAID;
      } else {
        st = ClassStudentTuitionState.FINALIZED_UNPAID;
      }

      studentRows.add(
        ClassMonthTuitionStudentRow(
          student: student,
          invoice: invoice,
          paymentSummary: summary,
          state: st,
        ),
      );
    } else {
      try {
        final preview = await tuitionService.previewTuition(
          sid,
          classId,
          month,
        );
        previewStudentCount++;
        previewTotalDue += preview.soTienPhaiThu;

        studentRows.add(
          ClassMonthTuitionStudentRow(
            student: student,
            preview: preview,
            state: ClassStudentTuitionState.PREVIEW_READY,
          ),
        );
      } catch (e) {
        pendingStudentCount++;
        final errMessage = e.toString().replaceAll('Exception: ', '');
        studentRows.add(
          ClassMonthTuitionStudentRow(
            student: student,
            state: errMessage.contains('chính sách')
                ? ClassStudentTuitionState.ERROR
                : ClassStudentTuitionState.PENDING_ATTENDANCE,
            pendingReason: errMessage,
          ),
        );
      }
    }
  }

  return ClassMonthTuitionOverview(
    classId: classId,
    month: month,
    previewTotalDue: previewTotalDue,
    finalizedTotalDue: finalizedTotalDue,
    totalPaid: totalPaid,
    remainingDebt: remainingDebt,
    previewStudentCount: previewStudentCount,
    finalizedStudentCount: finalizedStudentCount,
    pendingStudentCount: pendingStudentCount,
    studentRows: studentRows,
  );
}
