import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/student.dart';
import '../domain/student_service.dart';

part 'student_controller.g.dart';

@riverpod
class StudentListController extends _$StudentListController {
  @override
  FutureOr<List<Student>> build() async {
    final service = await ref.watch(studentServiceProvider.future);
    return service.getStudents();
  }

  Future<void> search(String query) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final service = await ref.read(studentServiceProvider.future);
      return service.searchStudents(query);
    });
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  Future<void> archive(int id) async {
    final service = await ref.read(studentServiceProvider.future);
    await service.archiveStudent(id);
    await refresh();
  }
}

@riverpod
class StudentFormController extends _$StudentFormController {
  @override
  FutureOr<void> build() {}

  Future<bool> save(Student student) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final service = await ref.read(studentServiceProvider.future);
      await service.saveStudent(student);
    });
    return !state.hasError;
  }
}
