import 'package:intl/intl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/database/database_provider.dart';
import '../../classes/domain/class_service.dart';
import '../../memberships/domain/membership_service.dart';
import '../../students/domain/student_service.dart';
import '../data/leave_request_repository.dart';
import 'leave_request.dart';

part 'leave_request_service.g.dart';

@Riverpod(keepAlive: true)
Future<LeaveRequestRepository> leaveRequestRepository(
  LeaveRequestRepositoryRef ref,
) async {
  final db = await ref.watch(databaseProvider.future);
  return LeaveRequestRepository(db);
}

class LeaveRequestService {
  final LeaveRequestRepository _repo;
  final StudentService _studentService;
  final ClassService _classService;
  final MembershipService _membershipService;

  LeaveRequestService(
    this._repo,
    this._studentService,
    this._classService,
    this._membershipService,
  );

  Future<int> createLeaveRequest(LeaveRequest request) async {
    final student = await _studentService.getStudentById(request.idHocSinh);
    if (student == null) throw Exception('Không tìm thấy học sinh');

    final cls = await _classService.getClassById(request.idLop);
    if (cls == null) throw Exception('Không tìm thấy lớp học');

    _validateDates(request.tuNgay, request.denNgay);

    // Validate membership intersection
    final memberships = await _membershipService
        .getMembershipsForStudentAndClass(request.idHocSinh, request.idLop);

    final intersectsMembership = memberships.any((m) {
      final mDen = m.denNgay ?? '9999-12-31';
      return m.tuNgay.compareTo(request.denNgay) <= 0 &&
          mDen.compareTo(request.tuNgay) >= 0;
    });

    if (!intersectsMembership) {
      throw Exception(
        'Học sinh không có thời gian tham gia lớp học trùng với thời gian xin nghỉ.',
      );
    }

    // Check overlapping active requests
    final overlapping = await _repo.findOverlappingActiveRequests(
      request.idHocSinh,
      request.idLop,
      request.tuNgay,
      request.denNgay,
    );

    if (overlapping.isNotEmpty) {
      throw Exception(
        'Đã có đơn nghỉ học đang chờ duyệt hoặc đã duyệt trong khoảng thời gian này.',
      );
    }

    final newRequest = request.copyWith(
      trangThai: LeaveRequestStatus.CHO_DUYET,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    return await _repo.create(newRequest);
  }

  Future<void> updateStatus(int requestId, LeaveRequestStatus newStatus) async {
    final existing = await _repo.getById(requestId);
    if (existing == null) throw Exception('Không tìm thấy đơn nghỉ học');

    if (existing.trangThai != LeaveRequestStatus.CHO_DUYET) {
      throw Exception(
        'Đơn nghỉ học đã ở trạng thái ${existing.trangThai.name}, không thể chuyển trạng thái.',
      );
    }

    if (newStatus == LeaveRequestStatus.CHO_DUYET) {
      throw Exception('Trạng thái không hợp lệ.');
    }

    await _repo.update(
      existing.copyWith(trangThai: newStatus, updatedAt: DateTime.now()),
    );
  }

  Future<LeaveRequest?> getById(int id) => _repo.getById(id);

  Future<List<LeaveRequest>> getByClass(int classId) =>
      _repo.getByClass(classId);

  Future<List<LeaveRequest>> getByStudentAndClass(int studentId, int classId) =>
      _repo.getByStudentAndClass(studentId, classId);

  Future<LeaveRequest?> findApprovedLeave(
    int studentId,
    int classId,
    String date,
  ) => _repo.findApprovedLeave(studentId, classId, date);

  void _validateDates(String tuNgay, String denNgay) {
    try {
      final pTu = DateFormat('yyyy-MM-dd').parseStrict(tuNgay);
      final pDen = DateFormat('yyyy-MM-dd').parseStrict(denNgay);

      if (DateFormat('yyyy-MM-dd').format(pTu) != tuNgay ||
          DateFormat('yyyy-MM-dd').format(pDen) != denNgay) {
        throw Exception('Ngày không đúng định dạng YYYY-MM-DD');
      }

      if (denNgay.compareTo(tuNgay) < 0) {
        throw Exception('Từ ngày phải nhỏ hơn hoặc bằng đến ngày');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Định dạng ngày không hợp lệ');
    }
  }
}

@Riverpod(keepAlive: true)
Future<LeaveRequestService> leaveRequestService(
  LeaveRequestServiceRef ref,
) async {
  final repo = await ref.watch(leaveRequestRepositoryProvider.future);
  final studentService = await ref.watch(studentServiceProvider.future);
  final classService = await ref.watch(classServiceProvider.future);
  final membershipService = await ref.watch(membershipServiceProvider.future);
  return LeaveRequestService(
    repo,
    studentService,
    classService,
    membershipService,
  );
}
