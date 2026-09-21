import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:intl/intl.dart';
import '../../../core/database/database_provider.dart';
import '../data/membership_repository.dart';
import 'membership.dart';

part 'membership_service.g.dart';

@Riverpod(keepAlive: true)
Future<MembershipRepository> membershipRepository(MembershipRepositoryRef ref) async {
  final db = await ref.watch(databaseProvider.future);
  return MembershipRepository(db);
}

class MembershipService {
  final MembershipRepository _repository;

  MembershipService(this._repository);

  Future<void> enrollStudent({
    required int studentId,
    required int classId,
    required DateTime joinDate,
    int mienGiam = 0,
    String? ghiChu,
  }) async {
    final open = await _repository.getOpenMembership(studentId, classId);
    if (open != null) {
      throw Exception('Học sinh đã có membership đang hoạt động trong lớp này');
    }

    final dateFormat = DateFormat('yyyy-MM-dd');
    final membership = ClassMembership(
      idHocSinh: studentId,
      idLop: classId,
      tuNgay: dateFormat.format(joinDate),
      mienGiamPhanTram: mienGiam,
      ghiChu: ghiChu,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _repository.create(membership);
  }

  Future<void> leaveClass({
    required int studentId,
    required int classId,
    required DateTime endDate,
    String? reason,
  }) async {
    final open = await _repository.getOpenMembership(studentId, classId);
    if (open == null) {
      throw Exception('Không tìm thấy membership đang hoạt động');
    }

    final dateFormat = DateFormat('yyyy-MM-dd');
    final endDateStr = dateFormat.format(endDate);

    if (endDateStr.compareTo(open.tuNgay) < 0) {
      throw Exception('Ngày kết thúc không được trước ngày bắt đầu (${open.tuNgay})');
    }

    final updated = open.copyWith(
      denNgay: endDateStr,
      lyDoKetThuc: reason,
      updatedAt: DateTime.now(),
    );

    await _repository.update(updated);
  }

  Future<List<ClassMembership>> getMembershipHistory(int studentId, {int? classId}) async {
    if (classId != null) {
      final all = await _repository.getByStudent(studentId);
      return all.where((m) => m.idLop == classId).toList();
    }
    return _repository.getByStudent(studentId);
  }

  Future<List<ClassMembership>> getRoster(int classId, {DateTime? date}) async {
    final referenceDate = date ?? DateTime.now();
    final dateFormat = DateFormat('yyyy-MM-dd');
    return _repository.getActiveByClass(classId, dateFormat.format(referenceDate));
  }

  Future<int> getClassSize(int classId, {DateTime? date}) async {
    final referenceDate = date ?? DateTime.now();
    final dateFormat = DateFormat('yyyy-MM-dd');
    return _repository.getClassSize(classId, dateFormat.format(referenceDate));
  }

  Future<List<ClassMembership>> getActiveMembershipsForStudent(int studentId, {DateTime? date}) async {
    final referenceDate = date ?? DateTime.now();
    final dateFormat = DateFormat('yyyy-MM-dd');
    return _repository.getActiveByStudent(studentId, dateFormat.format(referenceDate));
  }

  Future<bool> hasActiveMemberships(int studentId) async {
    final now = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final active = await _repository.getActiveByStudent(studentId, now);
    return active.isNotEmpty;
  }
}

@Riverpod(keepAlive: true)
Future<MembershipService> membershipService(MembershipServiceRef ref) async {
  final repo = await ref.watch(membershipRepositoryProvider.future);
  return MembershipService(repo);
}
