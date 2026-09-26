import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/student.dart';
import '../domain/student_service.dart';

part 'student_controller.g.dart';

@riverpod
class StudentListController extends _$StudentListController {
  bool? _filterArchived =
      false; // false = Active only, true = Archived only, null = All
  String _currentQuery = '';

  @override
  FutureOr<List<Student>> build() async {
    final service = await ref.watch(studentServiceProvider.future);
    final allStudents = await service.searchStudents(
      _currentQuery,
      includeArchived: true,
    );

    if (_filterArchived == false) {
      return allStudents.where((s) => !s.daLuuTru).toList();
    } else if (_filterArchived == true) {
      return allStudents.where((s) => s.daLuuTru).toList();
    }
    return allStudents;
  }

  void setFilter(bool? showArchived) {
    _filterArchived = showArchived;
    ref.invalidateSelf();
  }

  Future<void> search(String query) async {
    _currentQuery = query;
    ref.invalidateSelf();
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

  Future<void> restore(int id) async {
    final service = await ref.read(studentServiceProvider.future);
    await service.restoreStudent(id);
    await refresh();
  }
}

@riverpod
class StudentFormController extends _$StudentFormController {
  @override
  void build() {}

  Future<void> save(Student student) async {
    final service = await ref.read(studentServiceProvider.future);
    await service.saveStudent(student);
  }
}
