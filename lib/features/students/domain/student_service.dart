import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/utils/phone_normalizer.dart';
import '../../memberships/domain/membership_service.dart';
import '../data/student_repository.dart';
import 'student.dart';

part 'student_service.g.dart';

@Riverpod(keepAlive: true)
Future<StudentRepository> studentRepository(StudentRepositoryRef ref) async {
  final db = await ref.watch(databaseProvider.future);
  return StudentRepository(db);
}

class StudentService {
  final StudentRepository _repository;
  final MembershipService _membershipService;

  StudentService(this._repository, this._membershipService);

  Future<List<Student>> getStudents({bool includeArchived = false}) {
    return _repository.getAll(includeArchived: includeArchived);
  }

  Future<List<Student>> searchStudents(
    String query, {
    bool includeArchived = false,
  }) {
    if (query.trim().isEmpty) {
      return getStudents(includeArchived: includeArchived);
    }
    return _repository.search(query.trim(), includeArchived: includeArchived);
  }

  Future<void> saveStudent(Student student) async {
    if (student.hoTen.trim().isEmpty) {
      throw Exception('Họ tên không được để trống');
    }

    final normalizedStudent = student.copyWith(
      hoTen: student.hoTen.trim(),
      sdtPhuHuynh: PhoneNormalizer.normalize(student.sdtPhuHuynh),
      sdtHocSinh: PhoneNormalizer.normalize(student.sdtHocSinh),
      updatedAt: DateTime.now(),
    );

    if (normalizedStudent.id == null) {
      await _repository.create(normalizedStudent);
    } else {
      await _repository.update(normalizedStudent);
    }
  }

  Future<void> archiveStudent(int id) async {
    final hasActive = await _membershipService.hasActiveMemberships(id);
    if (hasActive) {
      throw Exception(
        'Học sinh vẫn đang thuộc các lớp. Hãy kết thúc các membership trước.',
      );
    }
    await _repository.setArchiveStatus(id, true);
  }

  Future<void> restoreStudent(int id) async {
    await _repository.setArchiveStatus(id, false);
  }

  Future<Student?> getStudentById(int id) {
    return _repository.getById(id);
  }

  Future<List<Student>> getStudentsByIds(List<int> ids) {
    return _repository.getByIds(ids);
  }
}

@Riverpod(keepAlive: true)
Future<StudentService> studentService(StudentServiceRef ref) async {
  final repo = await ref.watch(studentRepositoryProvider.future);
  final membershipService = await ref.watch(membershipServiceProvider.future);
  return StudentService(repo, membershipService);
}
