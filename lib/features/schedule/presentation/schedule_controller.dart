import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/class_schedule.dart';
import '../domain/schedule_service.dart';

part 'schedule_controller.g.dart';

@riverpod
class ClassScheduleController extends _$ClassScheduleController {
  @override
  FutureOr<List<ClassSchedule>> build(int classId) async {
    final service = await ref.watch(classScheduleServiceProvider.future);
    return service.getSchedulesForClass(classId);
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  Future<bool> create(ClassSchedule schedule) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final service = await ref.read(classScheduleServiceProvider.future);
      await service.createSchedule(schedule);
      return ref
          .read(classScheduleServiceProvider.future)
          .then((s) => s.getSchedulesForClass(schedule.idLop));
    });
    return !state.hasError;
  }

  Future<bool> close(int scheduleId, DateTime endDate) async {
    final schedule = (await future).firstWhere((s) => s.id == scheduleId);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final service = await ref.read(classScheduleServiceProvider.future);
      await service.closeSchedule(scheduleId, endDate);
      return ref
          .read(classScheduleServiceProvider.future)
          .then((s) => s.getSchedulesForClass(schedule.idLop));
    });
    return !state.hasError;
  }
}
