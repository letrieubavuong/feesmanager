import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/class.dart';
import '../domain/class_service.dart';

part 'class_controller.g.dart';

@riverpod
class ClassListController extends _$ClassListController {
  @override
  FutureOr<List<ClassEntity>> build() async {
    final service = await ref.watch(classServiceProvider.future);
    return service.getClasses();
  }

  Future<void> search(String query) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final service = await ref.read(classServiceProvider.future);
      return service.searchClasses(query);
    });
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}

@riverpod
class ClassFormController extends _$ClassFormController {
  @override
  FutureOr<void> build() {}

  Future<bool> save(ClassEntity classEntity) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final service = await ref.read(classServiceProvider.future);
      await service.saveClass(classEntity);
    });
    return !state.hasError;
  }
}

@riverpod
Future<ClassEntity?> classDetail(ClassDetailRef ref, int id) async {
  final service = await ref.watch(classServiceProvider.future);
  return service.getClassById(id);
}
