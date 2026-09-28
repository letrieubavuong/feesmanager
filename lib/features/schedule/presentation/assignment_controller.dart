import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../students/domain/student.dart';
import '../domain/bulk_assignment_result.dart';
import '../domain/student_shift_assignment.dart';
import '../domain/schedule_service.dart';

part 'assignment_controller.g.dart';

@riverpod
class ClassAssignmentController extends _$ClassAssignmentController {
  @override
  FutureOr<List<StudentShiftAssignment>> build(int classId) async {
    final service = await ref.watch(classScheduleServiceProvider.future);
    return service.getAssignmentsForClass(classId);
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  Future<List<Student>> loadBulkCandidates({
    required int scheduleId,
    required DateTime startDate,
  }) async {
    final service = await ref.read(classScheduleServiceProvider.future);
    return service.getBulkAssignmentCandidates(
      classId: classId,
      scheduleId: scheduleId,
      startDate: startDate,
    );
  }

  Future<BulkAssignmentPreview> previewBulk({
    required List<int> studentIds,
    required int scheduleId,
    required DateTime startDate,
  }) async {
    final service = await ref.read(classScheduleServiceProvider.future);
    return service.previewBulkAssignment(
      studentIds: studentIds,
      classId: classId,
      scheduleId: scheduleId,
      startDate: startDate,
    );
  }

  Future<BulkAssignmentResult> assignBulk({
    required List<int> studentIds,
    required int scheduleId,
    required DateTime startDate,
    String? note,
  }) async {
    state = const AsyncValue.loading();
    final service = await ref.read(classScheduleServiceProvider.future);
    final result = await service.assignStudentsBulk(
      studentIds: studentIds,
      classId: classId,
      scheduleId: scheduleId,
      startDate: startDate,
      note: note,
    );
    ref.invalidateSelf();
    await future;
    return result;
  }

  Future<AssignmentConflictResult> assign({
    required int studentId,
    required int classId,
    required int scheduleId,
    required DateTime startDate,
  }) async {
    state = const AsyncValue.loading();
    final service = await ref.read(classScheduleServiceProvider.future);
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
      state = AsyncValue.error(
        result.conflictReason ?? 'Unknown conflict',
        StackTrace.current,
      );
    }
    return result;
  }

  Future<void> close({
    required int assignmentId,
    required DateTime endDate,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final service = await ref.read(classScheduleServiceProvider.future);
      await service.closeAssignment(assignmentId, endDate);
      return service.getAssignmentsForClass(classId);
    });
  }

  Future<void> changeShift({
    required int studentId,
    required int oldAssignmentId,
    required int newScheduleId,
    required DateTime effectiveDate,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final service = await ref.read(classScheduleServiceProvider.future);
      await service.changeRecurringShift(
        studentId: studentId,
        classId: classId,
        oldAssignmentId: oldAssignmentId,
        newScheduleId: newScheduleId,
        effectiveDate: effectiveDate,
      );
      return service.getAssignmentsForClass(classId);
    });
  }

  Future<void> updateStartDate({
    required int assignmentId,
    required DateTime newStartDate,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final service = await ref.read(classScheduleServiceProvider.future);
      await service.updateAssignmentStartDate(
        assignmentId: assignmentId,
        newStartDate: newStartDate,
      );
      return service.getAssignmentsForClass(classId);
    });
  }
}
