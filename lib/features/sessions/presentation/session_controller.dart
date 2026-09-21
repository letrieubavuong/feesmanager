import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/class_session.dart';
import '../domain/session_service.dart';
import '../domain/session_generation_service.dart';

part 'session_controller.g.dart';

@riverpod
class ClassSessionController extends _$ClassSessionController {
  @override
  FutureOr<List<ClassSession>> build(int classId) async {
    final service = await ref.watch(sessionServiceProvider.future);
    return service.getSessionsForClass(classId);
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  Future<SessionGenerationResult> generate({
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    state = const AsyncValue.loading();
    final genService = await ref.read(sessionGenerationServiceProvider.future);
    final result = await genService.generateForClass(
      classId: classId,
      fromDate: fromDate,
      toDate: toDate,
    );
    ref.invalidateSelf();
    await future;
    return result;
  }

  Future<void> createManual(ClassSession session) async {
    state = const AsyncValue.loading();
    final service = await ref.read(sessionServiceProvider.future);
    await service.createManualSession(session);
    ref.invalidateSelf();
    await future;
  }

  Future<void> updateStatus(int sessionId, SessionStatus status) async {
    state = const AsyncValue.loading();
    final service = await ref.read(sessionServiceProvider.future);
    await service.updateStatus(sessionId, status);
    ref.invalidateSelf();
    await future;
  }
}
