import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/student_shift_assignment.dart';
import '../domain/schedule_service.dart';

part 'assignment_controller.g.dart';

@riverpod
class ClassAssignmentController extends _$ClassAssignmentController {
  @override
  FutureOr<List<StudentShiftAssignment>> build(int classId) async {
    final service = await ref.watch(scheduleServiceProvider.future);
    return service.getAssignmentsForClass(classId);
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  Future<AssignmentConflictResult> assign({
    required int studentId,
    required int classId,
    required int scheduleId,
    required DateTime startDate,
  }) async {
    state = const AsyncValue.loading();
    final service = await ref.read(scheduleServiceProvider.future);
    final result = await service.assignStudent(
      studentId: studentId,
      classId: classId,
      scheduleId: scheduleId,
      startDate: startDate,
    );
    if (result.canAssign) {
      ref.invalidateSelf();
      await future;
    } else {
      state = AsyncValue.error(result.conflictReason ?? 'Unknown conflict', StackTrace.current);
    }
    return result;
  }
}
