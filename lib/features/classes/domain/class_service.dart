import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/database/database_provider.dart';
import '../../memberships/domain/membership_service.dart';
import '../data/class_repository.dart';
import 'class.dart';

part 'class_service.g.dart';

@Riverpod(keepAlive: true)
Future<ClassRepository> classRepository(ClassRepositoryRef ref) async {
  final db = await ref.watch(databaseProvider.future);
  return ClassRepository(db);
}

class ClassService {
  final ClassRepository _repository;
  final MembershipService _membershipService;

  ClassService(this._repository, this._membershipService);

  Future<List<ClassEntity>> getClasses({bool includeArchived = false}) {
    return _repository.getAll(includeArchived: includeArchived);
  }

  Future<List<ClassEntity>> searchClasses(String query, {bool includeArchived = false}) {
    if (query.trim().isEmpty) {
      return getClasses(includeArchived: includeArchived);
    }
    return _repository.search(query.trim(), includeArchived: includeArchived);
  }

  Future<void> saveClass(ClassEntity classEntity) async {
    if (classEntity.tenLop.trim().isEmpty) {
      throw Exception('Tên lớp không được để trống');
    }

    final normalizedClass = classEntity.copyWith(
      tenLop: classEntity.tenLop.trim(),
      updatedAt: DateTime.now(),
    );

    if (normalizedClass.id == null) {
      await _repository.create(normalizedClass);
    } else {
      await _repository.update(normalizedClass);
    }
  }

  Future<int> getActiveMemberCount(int id) {
    return _membershipService.getClassSize(id);
  }

  Future<void> archiveClass(int id) async {
    await _repository.setArchiveStatus(id, true);
  }

  Future<void> restoreClass(int id) async {
    await _repository.setArchiveStatus(id, false);
  }

  Future<ClassEntity?> getClassById(int id) {
    return _repository.getById(id);
  }
}

@Riverpod(keepAlive: true)
Future<ClassService> classService(ClassServiceRef ref) async {
  final repo = await ref.watch(classRepositoryProvider.future);
  final membershipService = await ref.watch(membershipServiceProvider.future);
  return ClassService(repo, membershipService);
}
