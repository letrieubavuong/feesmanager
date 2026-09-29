import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:intl/intl.dart';
import '../../../core/database/database_provider.dart';
import '../data/membership_repository.dart';
import 'membership.dart';

part 'membership_service.g.dart';

@Riverpod(keepAlive: true)
Future<MembershipRepository> membershipRepository(
  MembershipRepositoryRef ref,
) async {
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
    if (mienGiam < 0 || mienGiam > 100) {
      throw Exception('Miễn giảm phải từ 0 đến 100%');
    }

    final dateFormat = DateFormat('yyyy-MM-dd');
    final joinDateStr = dateFormat.format(joinDate);

    final isOverlap = await _repository.hasOverlappingMembership(
      studentId,
      classId,
      joinDateStr,
      null,
    );
    if (isOverlap) {
      throw Exception(
        'Khoảng thời gian này đã có membership khác của học sinh trong lớp',
      );
    }

    final membership = ClassMembership(
      idHocSinh: studentId,
      idLop: classId,
      tuNgay: joinDateStr,
      mienGiamPhanTram: mienGiam,
      ghiChu: ghiChu,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _repository.create(membership);
  }

  Future<void> enrollStudents({
    required List<int> studentIds,
    required int classId,
    required DateTime joinDate,
    int mienGiam = 0,
    String? ghiChu,
  }) async {
    if (studentIds.isEmpty || studentIds.toSet().length != studentIds.length) {
      throw Exception('Vui lòng chọn học sinh không trùng lặp');
    }
    if (mienGiam < 0 || mienGiam > 100) {
      throw Exception('Miễn giảm phải từ 0 đến 100%');
    }
    final date = DateFormat('yyyy-MM-dd').format(joinDate);
    final now = DateTime.now();
    await _repository.createBatch([
      for (final id in studentIds)
        ClassMembership(
          idHocSinh: id,
          idLop: classId,
          tuNgay: date,
          mienGiamPhanTram: mienGiam,
          ghiChu: ghiChu,
          createdAt: now,
          updatedAt: now,
        ),
    ]);
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
      throw Exception(
        'Ngày kết thúc không được trước ngày bắt đầu (${open.tuNgay})',
      );
    }

    // Since we are closing an open interval, we don't need to check overlap for the rest of history
    // because it was already checked when the interval was opened.

    final updated = open.copyWith(
      denNgay: endDateStr,
      lyDoKetThuc: reason,
      updatedAt: DateTime.now(),
    );

    await _repository.update(updated);
  }

  Future<void> changeJoinDate({
    required ClassMembership membership,
    required DateTime joinDate,
  }) async {
    if (membership.id == null) {
      throw Exception('Không tìm thấy lần tham gia lớp');
    }
    final newDate = DateFormat('yyyy-MM-dd').format(joinDate);
    if (newDate == membership.tuNgay) return;
    if (membership.denNgay != null &&
        newDate.compareTo(membership.denNgay!) > 0) {
      throw Exception(
        'Ngày tham gia phải trước hoặc bằng ngày nghỉ lớp (${membership.denNgay})',
      );
    }
    if (await _repository.hasOverlappingMembership(
      membership.idHocSinh,
      membership.idLop,
      newDate,
      membership.denNgay,
      excludeId: membership.id,
    )) {
      throw Exception('Ngày tham gia trùng khoảng thời gian học sinh đã ở lớp');
    }
    await _repository.changeJoinDate(membership, newDate);
  }

  Future<ClassMembership?> getActiveMembership(
    int studentId,
    int classId,
    DateTime date,
  ) {
    final dateFormat = DateFormat('yyyy-MM-dd');
    return _repository.getActiveMembership(
      studentId,
      classId,
      dateFormat.format(date),
    );
  }

  Future<List<ClassMembership>> getMembershipHistory(
    int studentId, {
    int? classId,
  }) async {
    if (classId != null) {
      final all = await _repository.getByStudent(studentId);
      return all.where((m) => m.idLop == classId).toList();
    }
    return _repository.getByStudent(studentId);
  }

  Future<List<ClassMembership>> getMembershipsForStudentAndClass(
    int studentId,
    int classId,
  ) async {
    final all = await _repository.getByStudent(studentId);
    return all.where((m) => m.idLop == classId).toList();
  }

  Future<List<ClassMembership>> getMembershipsForClassMonth(
    int classId,
    String month, // YYYY-MM
  ) async {
    final monthStart = '$month-01';
    final parsedStart = DateTime.parse(monthStart);
    final monthEndDt = DateTime(parsedStart.year, parsedStart.month + 1, 0);
    final monthEnd = DateFormat('yyyy-MM-dd').format(monthEndDt);

    return _repository.getOverlappingDateRange(
      fromDate: monthStart,
      toDate: monthEnd,
      classId: classId,
    );
  }

  Future<List<int>> getUniqueStudentIdsForClassMonth(
    int classId,
    String month, // YYYY-MM
  ) async {
    final memberships = await getMembershipsForClassMonth(classId, month);
    return memberships.map((m) => m.idHocSinh).toSet().toList();
  }

  Future<List<ClassMembership>> getRoster(int classId, {DateTime? date}) async {
    final referenceDate = date ?? DateTime.now();
    final dateFormat = DateFormat('yyyy-MM-dd');
    return _repository.getActiveByClass(
      classId,
      dateFormat.format(referenceDate),
    );
  }

  Future<int> getClassSize(int classId, {DateTime? date}) async {
    final referenceDate = date ?? DateTime.now();
    final dateFormat = DateFormat('yyyy-MM-dd');
    return _repository.getClassSize(classId, dateFormat.format(referenceDate));
  }

  Future<List<ClassMembership>> getActiveMembershipsForStudent(
    int studentId, {
    DateTime? date,
  }) async {
    final referenceDate = date ?? DateTime.now();
    final dateFormat = DateFormat('yyyy-MM-dd');
    return _repository.getActiveByStudent(
      studentId,
      dateFormat.format(referenceDate),
    );
  }

  Future<List<ClassMembership>> getActiveMembershipsOnDate(
    DateTime date,
  ) async {
    final dateFormat = DateFormat('yyyy-MM-dd');
    return _repository.getActiveOnDate(dateFormat.format(date));
  }

  Future<List<ClassMembership>> getMembershipsOverlappingDateRange({
    required String fromDate,
    required String toDate,
    int? classId,
    int? studentId,
  }) => _repository.getOverlappingDateRange(
    fromDate: fromDate,
    toDate: toDate,
    classId: classId,
    studentId: studentId,
  );

  Future<bool> hasActiveMemberships(int studentId) async {
    final now = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final active = await _repository.getActiveByStudent(studentId, now);
    return active.isNotEmpty;
  }

  Future<bool> hasOverlappingMembership({
    required int studentId,
    required int classId,
    required DateTime joinDate,
    DateTime? endDate,
  }) async {
    final dateFormat = DateFormat('yyyy-MM-dd');
    final startStr = dateFormat.format(joinDate);
    final endStr = endDate != null ? dateFormat.format(endDate) : null;
    return _repository.hasOverlappingMembership(
      studentId,
      classId,
      startStr,
      endStr,
    );
  }

  Future<List<int>> getActiveStudentIdsInClass(
    int classId,
    DateTime date,
  ) async {
    final dateFormat = DateFormat('yyyy-MM-dd');
    final active = await _repository.getActiveByClass(
      classId,
      dateFormat.format(date),
    );
    return active.map((m) => m.idHocSinh).toList();
  }
}

@Riverpod(keepAlive: true)
Future<MembershipService> membershipService(MembershipServiceRef ref) async {
  final repo = await ref.watch(membershipRepositoryProvider.future);
  return MembershipService(repo);
}
