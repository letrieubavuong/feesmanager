import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/database/database_provider.dart';
import '../../classes/domain/class_service.dart';
import '../../schedule/domain/schedule_service.dart';
import '../../session_adjustments/domain/session_adjustment_service.dart';
import '../../sessions/domain/session_service.dart';
import '../data/schedule_constraint_repository.dart';
import '../domain/schedule_conflict_result.dart';
import '../domain/schedule_conflict_service.dart';
import '../domain/schedule_constraint.dart';

part 'schedule_conflict_providers.g.dart';

@Riverpod(keepAlive: true)
Future<ScheduleConstraintRepository> scheduleConstraintRepository(
  ScheduleConstraintRepositoryRef ref,
) async {
  final db = await ref.watch(databaseProvider.future);
  return ScheduleConstraintRepository(db);
}

@Riverpod(keepAlive: true)
Future<ScheduleConflictService> scheduleConflictService(
  ScheduleConflictServiceRef ref,
) async {
  final constraintRepo = await ref.watch(
    scheduleConstraintRepositoryProvider.future,
  );
  final scheduleRepo = await ref.watch(scheduleRepositoryProvider.future);
  final assignmentRepo = await ref.watch(assignmentRepositoryProvider.future);
  final sessionRepo = await ref.watch(sessionRepositoryProvider.future);
  final adjustmentRepo = await ref.watch(
    sessionAdjustmentRepositoryProvider.future,
  );
  final classService = await ref.watch(classServiceProvider.future);

  return ScheduleConflictService(
    constraintRepo,
    scheduleRepo,
    assignmentRepo,
    sessionRepo,
    adjustmentRepo,
    classService,
  );
}

@riverpod
Future<List<ScheduleConstraint>> studentConstraints(
  StudentConstraintsRef ref,
  int studentId,
) async {
  final repo = await ref.watch(scheduleConstraintRepositoryProvider.future);
  return repo.getForStudent(studentId);
}

@Riverpod(keepAlive: true)
class ScheduleConstraintController extends _$ScheduleConstraintController {
  @override
  FutureOr<void> build() {}

  Future<int> createConstraint(ScheduleConstraint constraint) async {
    state = const AsyncLoading();
    late int resultId;
    state = await AsyncValue.guard(() async {
      final repo = await ref.read(scheduleConstraintRepositoryProvider.future);
      resultId = await repo.createConstraint(constraint);
      ref.invalidate(studentConstraintsProvider(constraint.studentId));
    });
    if (state.hasError) throw state.error!;
    return resultId;
  }

  Future<void> cancelConstraint(int id, int studentId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = await ref.read(scheduleConstraintRepositoryProvider.future);
      await repo.cancelConstraint(id);
      ref.invalidate(studentConstraintsProvider(studentId));
    });
    if (state.hasError) throw state.error!;
  }
}

@riverpod
Future<ScheduleConflictResult> assignmentConflictPreview(
  AssignmentConflictPreviewRef ref,
  (
    int studentId,
    int targetScheduleId,
    String startDate,
    String? endDate,
    int? excludeAssignmentId,
  )
  arg,
) async {
  final service = await ref.watch(scheduleConflictServiceProvider.future);
  return service.evaluateCandidateAssignment(
    studentId: arg.$1,
    targetScheduleId: arg.$2,
    startDate: arg.$3,
    endDate: arg.$4,
    excludeAssignmentId: arg.$5,
  );
}

@riverpod
Future<ScheduleConflictResult> oneOffConflictPreview(
  OneOffConflictPreviewRef ref,
  (
    int studentId,
    String targetDate,
    String startTime,
    String endTime,
    int? excludeSessionId,
  )
  arg,
) async {
  final service = await ref.watch(scheduleConflictServiceProvider.future);
  return service.evaluateOneOffCandidate(
    studentId: arg.$1,
    targetDate: arg.$2,
    startTime: arg.$3,
    endTime: arg.$4,
    excludeSessionId: arg.$5,
  );
}
