import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/session_adjustment.dart';
import '../domain/session_adjustment_service.dart';

part 'session_adjustment_controller.g.dart';

@riverpod
class SessionAdjustmentController extends _$SessionAdjustmentController {
  @override
  FutureOr<List<SessionAdjustment>> build(int sessionId) async {
    final service = await ref.watch(sessionAdjustmentServiceProvider.future);
    return service.getByTargetSession(sessionId);
  }

  Future<void> createDoiCa({
    required int studentId,
    required int originalSessionId,
    required int targetSessionId,
    String? reason,
  }) async {
    final service = await ref.read(sessionAdjustmentServiceProvider.future);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await service.createDoiCa(
        studentId: studentId,
        originalSessionId: originalSessionId,
        targetSessionId: targetSessionId,
        reason: reason,
      );
      return service.getByTargetSession(targetSessionId);
    });
  }

  Future<void> createHocBu({
    required int studentId,
    required int originalSessionId,
    required int targetSessionId,
    String? reason,
  }) async {
    final service = await ref.read(sessionAdjustmentServiceProvider.future);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await service.createHocBu(
        studentId: studentId,
        originalSessionId: originalSessionId,
        targetSessionId: targetSessionId,
        reason: reason,
      );
      return service.getByTargetSession(targetSessionId);
    });
  }

  Future<void> createPhatSinh({
    required int studentId,
    required int originalClassId,
    required int targetSessionId,
    String? reason,
  }) async {
    final service = await ref.read(sessionAdjustmentServiceProvider.future);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await service.createPhatSinh(
        studentId: studentId,
        originalClassId: originalClassId,
        targetSessionId: targetSessionId,
        reason: reason,
      );
      return service.getByTargetSession(targetSessionId);
    });
  }

  Future<void> removeAdjustment(int adjustmentId, int sessionId) async {
    final service = await ref.read(sessionAdjustmentServiceProvider.future);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await service.removeAdjustment(adjustmentId);
      return service.getByTargetSession(sessionId);
    });
  }
}
