import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/class.dart';
import '../domain/class_service.dart';

import '../domain/class_filter.dart';

part 'class_controller.g.dart';

@riverpod
class ClassListController extends _$ClassListController {
  ClassFilter _filter = ClassFilter.active;
  String _query = '';

  @override
  FutureOr<List<ClassEntity>> build() async {
    final service = await ref.watch(classServiceProvider.future);
    if (_query.isNotEmpty) {
      return service.searchClasses(_query, filter: _filter);
    }
    return service.getClasses(filter: _filter);
  }

  Future<void> search(String query) async {
    _query = query;
    ref.invalidateSelf();
  }

  void setFilter(ClassFilter filter) {
    _filter = filter;
    ref.invalidateSelf();
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  Future<void> restore(int id) async {
    final service = await ref.read(classServiceProvider.future);
    await service.restoreClass(id);
    await refresh();
  }

  Future<void> archive(int id) async {
    final service = await ref.read(classServiceProvider.future);
    await service.archiveClass(id);
    await refresh();
  }
}

@riverpod
class ClassFormController extends _$ClassFormController {
  @override
  void build() {}

  Future<void> save(ClassEntity classEntity) async {
    final service = await ref.read(classServiceProvider.future);
    await service.saveClass(classEntity);
  }
}

@riverpod
Future<ClassEntity?> classDetail(ClassDetailRef ref, int id) async {
  final service = await ref.watch(classServiceProvider.future);
  return service.getClassById(id);
}
