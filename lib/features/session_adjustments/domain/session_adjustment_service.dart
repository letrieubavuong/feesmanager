import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/database/database_provider.dart';
import '../../attendance/data/attendance_repository.dart';
import '../../attendance/domain/attendance_record.dart';
import '../../attendance/domain/attendance_service.dart';
import '../../classes/domain/class_service.dart';
import '../../memberships/domain/membership_service.dart';
import '../../roster/domain/roster_service.dart';
import '../../schedule_conflicts/domain/schedule_conflict_service.dart';
import '../../schedule_conflicts/presentation/schedule_conflict_providers.dart';
import '../../sessions/domain/class_session.dart';
import '../../sessions/domain/session_service.dart';
import '../../students/domain/student_service.dart';
import '../data/session_adjustment_repository.dart';
import 'session_adjustment.dart';

part 'session_adjustment_service.g.dart';

@Riverpod(keepAlive: true)
Future<SessionAdjustmentRepository> sessionAdjustmentRepository(
  SessionAdjustmentRepositoryRef ref,
) async {
  final db = await ref.watch(databaseProvider.future);
  return SessionAdjustmentRepository(db);
}

class SessionAdjustmentService {
  final SessionAdjustmentRepository _repo;
  final StudentService _studentService;
  final ClassService _classService;
  final SessionService _sessionService;
  final MembershipService _membershipService;
  final AttendanceRepository _attendanceRepo;
  final RosterService _rosterService;
  final ScheduleConflictService _conflictService;

  SessionAdjustmentService(
    this._repo,
    this._studentService,
    this._classService,
    this._sessionService,
    this._membershipService,
    this._attendanceRepo,
    this._rosterService,
    this._conflictService,
  );

  Future<int> createDoiCa({
    required int studentId,
    required int originalSessionId,
    required int targetSessionId,
    String? reason,
  }) async {
    final student = await _studentService.getStudentById(studentId);
    if (student == null) throw Exception('Không tìm thấy học sinh');

    final origSession = await _sessionService.getSessionById(originalSessionId);
    final targetSession = await _sessionService.getSessionById(targetSessionId);

    if (origSession == null || targetSession == null) {
      throw Exception('Không tìm thấy buổi học');
    }

    if (originalSessionId == targetSessionId) {
      throw Exception('Buổi học gốc và buổi học chuyển tới phải khác nhau');
    }

    if (origSession.loai != SessionType.CHINH ||
        targetSession.loai != SessionType.CHINH) {
      throw Exception('Đổi ca chỉ áp dụng cho buổi học chính thức (CHÍNH)');
    }

    if (origSession.trangThai != SessionStatus.DU_KIEN ||
        targetSession.trangThai != SessionStatus.DU_KIEN) {
      throw Exception('Chỉ được đổi ca giữa các buổi học dự kiến chưa diễn ra');
    }

    if (origSession.idLop != targetSession.idLop) {
      throw Exception('Buổi học chuyển tới phải thuộc cùng một lớp học');
    }

    if (origSession.ngay != targetSession.ngay) {
      throw Exception(
        'Đổi ca trong ngày chỉ áp dụng cho các ca trong cùng ngày',
      );
    }

    // Check base roster membership for student in original vs target
    final baseOrigRoster = await _rosterService.getBaseRosterForSession(
      originalSessionId,
    );
    final isBaseInOrig = baseOrigRoster.participants.any(
      (m) => m.student.id == studentId,
    );
    if (!isBaseInOrig) {
      throw Exception(
        'Học sinh không thuộc danh sách phân ca mặc định của buổi học gốc',
      );
    }

    final baseTargetRoster = await _rosterService.getBaseRosterForSession(
      targetSessionId,
    );
    final isBaseInTarget = baseTargetRoster.participants.any(
      (m) => m.student.id == studentId,
    );
    if (isBaseInTarget) {
      throw Exception(
        'Học sinh đã thuộc danh sách phân ca mặc định của buổi học chuyển tới',
      );
    }

    // Check attendance in original or target
    final origAtt = await _attendanceRepo.getBySessionAndStudent(
      originalSessionId,
      studentId,
    );
    if (origAtt != null) {
      throw Exception('Buổi học gốc đã có dữ liệu điểm danh cho học sinh này');
    }

    final targetAtt = await _attendanceRepo.getBySessionAndStudent(
      targetSessionId,
      studentId,
    );
    if (targetAtt != null) {
      throw Exception(
        'Buổi học chuyển tới đã có dữ liệu điểm danh cho học sinh này',
      );
    }

    // Recheck schedule conflicts before persistence
    final conflictResult = await _conflictService
        .evaluateOneOffSessionCandidate(
          studentId: studentId,
          targetSessionId: targetSessionId,
          replacingOriginalSessionId: originalSessionId,
        );
    if (!conflictResult.canAssign) {
      throw Exception(conflictResult.hardConflicts.first.message);
    }

    final adjustment = SessionAdjustment(
      idHocSinh: studentId,
      idLopGoc: origSession.idLop,
      idBuoiHocGoc: originalSessionId,
      idBuoiHocThamGia: targetSessionId,
      loai: SessionAdjustmentType.DOI_CA,
      lyDo: reason,
      createdAt: DateTime.now(),
    );

    return await _repo.create(adjustment);
  }

  Future<int> createHocBu({
    required int studentId,
    required int originalSessionId,
    required int targetSessionId,
    String? reason,
  }) async {
    final student = await _studentService.getStudentById(studentId);
    if (student == null) throw Exception('Không tìm thấy học sinh');

    final origSession = await _sessionService.getSessionById(originalSessionId);
    final targetSession = await _sessionService.getSessionById(targetSessionId);

    if (origSession == null || targetSession == null) {
      throw Exception('Không tìm thấy buổi học');
    }

    if (origSession.loai != SessionType.CHINH) {
      throw Exception('Buổi học vắng gốc phải là buổi học chính thức (CHÍNH)');
    }

    if (origSession.trangThai != SessionStatus.DA_HOC) {
      throw Exception('Buổi học vắng gốc phải ở trạng thái ĐÃ HỌC');
    }

    // Original membership on original session date
    final origMemberships = await _membershipService
        .getMembershipsForStudentAndClass(studentId, origSession.idLop);
    final validOrigMembership = origMemberships.any((m) {
      final den = m.denNgay ?? '9999-12-31';
      return m.tuNgay.compareTo(origSession.ngay) <= 0 &&
          den.compareTo(origSession.ngay) >= 0;
    });
    if (!validOrigMembership) {
      throw Exception(
        'Học sinh không có quá trình học hợp lệ tại lớp gốc vào ngày buổi học vắng',
      );
    }

    // Original attendance MUST exist and be NGHI_CO_PHEP or NGHI_KHONG_PHEP
    final origAtt = await _attendanceRepo.getBySessionAndStudent(
      originalSessionId,
      studentId,
    );
    if (origAtt == null) {
      throw Exception(
        'Không tìm thấy dữ liệu điểm danh vắng của học sinh ở buổi học gốc',
      );
    }

    if (origAtt.trangThai != AttendanceStatus.NGHI_CO_PHEP &&
        origAtt.trangThai != AttendanceStatus.NGHI_KHONG_PHEP) {
      throw Exception(
        'Chỉ học sinh vắng (Nghỉ có phép / Nghỉ không phép) mới được xếp học bù',
      );
    }

    if (targetSession.loai != SessionType.HOC_BU) {
      throw Exception('Buổi học đích phải là buổi HỌC BÙ');
    }

    if (targetSession.trangThai != SessionStatus.DU_KIEN) {
      throw Exception('Buổi học bù đích phải ở trạng thái DỰ KIẾN');
    }

    if (targetSession.ngay.compareTo(origSession.ngay) < 0) {
      throw Exception(
        'Ngày học bù phải lớn hơn hoặc bằng ngày của buổi học vắng',
      );
    }

    final existingTarget = await _repo.getByStudentAndTargetSession(
      studentId,
      targetSessionId,
    );
    if (existingTarget != null) {
      throw Exception('Học sinh đã được xếp vào buổi học bù này');
    }

    // Recheck schedule conflicts before persistence
    final conflictResult = await _conflictService
        .evaluateOneOffSessionCandidate(
          studentId: studentId,
          targetSessionId: targetSessionId,
        );
    if (!conflictResult.canAssign) {
      throw Exception(conflictResult.hardConflicts.first.message);
    }

    final adjustment = SessionAdjustment(
      idHocSinh: studentId,
      idLopGoc: origSession.idLop,
      idBuoiHocGoc: originalSessionId,
      idBuoiHocThamGia: targetSessionId,
      loai: SessionAdjustmentType.HOC_BU,
      lyDo: reason,
      createdAt: DateTime.now(),
    );

    return await _repo.create(adjustment);
  }

  Future<int> createPhatSinh({
    required int studentId,
    required int originalClassId,
    required int targetSessionId,
    String? reason,
  }) async {
    final student = await _studentService.getStudentById(studentId);
    if (student == null) throw Exception('Không tìm thấy học sinh');

    final origClass = await _classService.getClassById(originalClassId);
    if (origClass == null) throw Exception('Không tìm thấy lớp học gốc');

    final targetSession = await _sessionService.getSessionById(targetSessionId);
    if (targetSession == null) throw Exception('Không tìm thấy buổi học đích');

    if (targetSession.loai != SessionType.PHAT_SINH) {
      throw Exception('Buổi học đích phải là buổi PHÁT SINH');
    }

    if (targetSession.trangThai != SessionStatus.DU_KIEN) {
      throw Exception('Buổi học phát sinh đích phải ở trạng thái DỰ KIẾN');
    }

    // Verify student has active membership in originalClassId on target date
    final memberships = await _membershipService
        .getMembershipsForStudentAndClass(studentId, originalClassId);

    final validMembership = memberships.any((m) {
      final den = m.denNgay ?? '9999-12-31';
      return m.tuNgay.compareTo(targetSession.ngay) <= 0 &&
          den.compareTo(targetSession.ngay) >= 0;
    });

    if (!validMembership) {
      throw Exception(
        'Học sinh không có quá trình học hợp lệ tại lớp gốc vào ngày học phát sinh',
      );
    }

    final existingTarget = await _repo.getByStudentAndTargetSession(
      studentId,
      targetSessionId,
    );
    if (existingTarget != null) {
      throw Exception('Học sinh đã được xếp vào buổi học phát sinh này');
    }

    // Recheck schedule conflicts before persistence
    final conflictResult = await _conflictService
        .evaluateOneOffSessionCandidate(
          studentId: studentId,
          targetSessionId: targetSessionId,
        );
    if (!conflictResult.canAssign) {
      throw Exception(conflictResult.hardConflicts.first.message);
    }

    final adjustment = SessionAdjustment(
      idHocSinh: studentId,
      idLopGoc: originalClassId,
      idBuoiHocGoc: null,
      idBuoiHocThamGia: targetSessionId,
      loai: SessionAdjustmentType.PHAT_SINH,
      lyDo: reason,
      createdAt: DateTime.now(),
    );

    return await _repo.create(adjustment);
  }

  Future<void> removeAdjustment(int adjustmentId) async {
    final adj = await _repo.getById(adjustmentId);
    if (adj == null) throw Exception('Không tìm thấy điều chỉnh buổi học');

    final targetSession = await _sessionService.getSessionById(
      adj.idBuoiHocThamGia,
    );
    if (targetSession != null &&
        targetSession.trangThai == SessionStatus.DA_HOC) {
      throw Exception(
        'Buổi học đã hoàn tất, không thể hủy bỏ điều chỉnh tham gia',
      );
    }

    // Attendance check in target
    final targetAtt = await _attendanceRepo.getBySessionAndStudent(
      adj.idBuoiHocThamGia,
      adj.idHocSinh,
    );
    if (targetAtt != null) {
      throw Exception(
        'Đã có dữ liệu điểm danh ở buổi học đích, không thể hủy bỏ điều chỉnh',
      );
    }

    // For DOI_CA check original attendance
    if (adj.loai == SessionAdjustmentType.DOI_CA && adj.idBuoiHocGoc != null) {
      final origAtt = await _attendanceRepo.getBySessionAndStudent(
        adj.idBuoiHocGoc!,
        adj.idHocSinh,
      );
      if (origAtt != null) {
        throw Exception(
          'Đã có dữ liệu điểm danh ở buổi học gốc, không thể hủy bỏ điều chỉnh',
        );
      }
    }

    await _repo.delete(adjustmentId);
  }

  Future<SessionAdjustment?> getById(int id) => _repo.getById(id);

  Future<List<SessionAdjustment>> getByTargetSession(int sessionId) =>
      _repo.getByTargetSession(sessionId);

  Future<List<SessionAdjustment>> getByOriginalSession(int sessionId) =>
      _repo.getByOriginalSession(sessionId);
}

@Riverpod(keepAlive: true)
Future<SessionAdjustmentService> sessionAdjustmentService(
  SessionAdjustmentServiceRef ref,
) async {
  final repo = await ref.watch(sessionAdjustmentRepositoryProvider.future);
  final studentService = await ref.watch(studentServiceProvider.future);
  final classService = await ref.watch(classServiceProvider.future);
  final sessionService = await ref.watch(sessionServiceProvider.future);
  final membershipService = await ref.watch(membershipServiceProvider.future);
  final attendanceRepo = await ref.watch(attendanceRepositoryProvider.future);
  final rosterService = await ref.watch(rosterServiceProvider.future);
  final conflictService = await ref.watch(
    scheduleConflictServiceProvider.future,
  );

  return SessionAdjustmentService(
    repo,
    studentService,
    classService,
    sessionService,
    membershipService,
    attendanceRepo,
    rosterService,
    conflictService,
  );
}
