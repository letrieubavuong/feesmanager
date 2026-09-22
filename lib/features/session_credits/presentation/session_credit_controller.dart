import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/monthly_credit_summary.dart';
import '../domain/session_credit_service.dart';

part 'session_credit_controller.g.dart';

@riverpod
class SessionCreditController extends _$SessionCreditController {
  @override
  FutureOr<MonthlyCreditSummary> build(
    int studentId,
    int classId,
    String month,
  ) async {
    final service = await ref.watch(sessionCreditServiceProvider.future);
    return service.previewMonth(studentId, classId, month);
  }

  Future<void> reconcile() async {
    final service = await ref.read(sessionCreditServiceProvider.future);
    try {
      await service.reconcileEarnedCreditsForStudentClassMonth(
        studentId,
        classId,
        month,
      );
      state = AsyncData(await service.previewMonth(studentId, classId, month));
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> addManualAdjustment({
    required int delta,
    required String effectiveDate,
    required String note,
  }) async {
    final service = await ref.read(sessionCreditServiceProvider.future);
    try {
      await service.addManualAdjustment(
        studentId: studentId,
        classId: classId,
        delta: delta,
        effectiveDate: effectiveDate,
        note: note,
      );
      state = AsyncData(await service.previewMonth(studentId, classId, month));
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}
