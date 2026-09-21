import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/database/database_provider.dart';
import '../../leave/domain/leave_request_service.dart';
import '../../roster/domain/roster_member.dart';
import '../../roster/domain/roster_service.dart';
import '../../sessions/domain/class_session.dart';
import '../../sessions/domain/session_service.dart';
import '../data/attendance_repository.dart';
import 'attendance_record.dart';
import 'attendance_sheet.dart';
import 'attendance_state.dart';

part 'attendance_service.g.dart';

@Riverpod(keepAlive: true)
Future<AttendanceRepository> attendanceRepository(
  AttendanceRepositoryRef ref,
) async {
  final db = await ref.watch(databaseProvider.future);
  return AttendanceRepository(db);
}

class AttendanceService {
  final AttendanceRepository _repo;
  final RosterService _rosterService;
  final SessionService _sessionService;
  final LeaveRequestService _leaveRequestService;

  AttendanceService(
    this._repo,
    this._rosterService,
    this._sessionService,
    this._leaveRequestService,
  );

  Future<AttendanceSheet> getAttendanceForSession(int sessionId) async {
    final session = await _sessionService.getSessionById(sessionId);
    if (session == null) throw Exception('Không tìm thấy buổi học');

    final roster = await _rosterService.getRosterForSession(sessionId);
    final persistedRecords = await _repo.getBySession(sessionId);
    final recordMap = {for (var r in persistedRecords) r.idHocSinh: r};

    final members = <AttendanceSheetMember>[];

    for (final rm in roster.participants) {
      final record = recordMap[rm.student.id];
      AttendanceState? suggestedState;
      String? suggestionReason;

      if (record == null) {
        if (rm.source == RosterInclusionSource.SINGLE_SHIFT_MEMBERSHIP ||
            rm.source == RosterInclusionSource.EXPLICIT_ASSIGNMENT) {
          final approvedLeave = await _leaveRequestService.findApprovedLeave(
            rm.student.id!,
            session.idLop,
            session.ngay,
          );
          if (approvedLeave != null) {
            suggestedState = AttendanceState.NGHI_CO_PHEP;
            suggestionReason = 'Đơn nghỉ đã duyệt';
          }
        }
      }

      members.add(
        AttendanceSheetMember(
          rosterMember: rm,
          persistedRecord: record,
          state: AttendanceState.fromStatus(record?.trangThai),
          suggestedState: suggestedState,
          suggestionReason: suggestionReason,
        ),
      );
    }

    final issues = <AttendanceSheetIssue>[];
    final participantIds = roster.participants.map((p) => p.student.id).toSet();
    for (final record in persistedRecords) {
      if (!participantIds.contains(record.idHocSinh)) {
        issues.add(
          AttendanceSheetIssue(
            code: AttendanceSheetIssueCode.ATTENDANCE_OUTSIDE_ROSTER,
            message:
                'Học sinh (ID: ${record.idHocSinh}) có dữ liệu điểm danh nhưng không thuộc danh sách lớp buổi này.',
            context: record,
          ),
        );
      }
    }

    return AttendanceSheet(
      session: session,
      members: members,
      issues: issues,
      isRosterValid: roster.isOperationallyValid,
      rosterIssues: roster.issues,
      requiresOneOffAdjustments: roster.requiresOneOffAdjustments,
    );
  }

  Future<void> saveDraft(
    int sessionId,
    Map<int, AttendanceState> states,
  ) async {
    final sheet = await getAttendanceForSession(sessionId);

    if (!sheet.isOperationallyValid) {
      throw Exception(
        'Không thể lưu điểm danh: Dữ liệu hiện tại không hợp lệ hoặc danh sách lớp có lỗi.',
      );
    }

    if (sheet.session.trangThai == SessionStatus.HUY ||
        sheet.session.trangThai == SessionStatus.NGHI_LE) {
      throw Exception('Không thể điểm danh cho buổi học đã Hủy hoặc Nghỉ lễ.');
    }

    if (sheet.requiresOneOffAdjustments) {
      throw Exception(
        'Buổi học bù/phát sinh chưa có danh sách học sinh tham gia.',
      );
    }

    final toUpsert = <AttendanceRecord>[];
    final toDeleteIds = <int>[];
    final now = DateTime.now();

    for (final entry in states.entries) {
      final studentId = entry.key;
      final newState = entry.value;

      final member = sheet.members
          .where((m) => m.rosterMember.student.id == studentId)
          .firstOrNull;
      if (member == null) {
        throw Exception(
          'Học sinh (ID: $studentId) không thuộc danh sách lớp buổi này.',
        );
      }

      if (newState == AttendanceState.CHUA_DIEM_DANH) {
        if (member.persistedRecord != null) {
          toDeleteIds.add(studentId);
        }
      } else {
        AttendanceParticipationType loaiThamGia;
        int idLopGoc;
        int? idBuoiVangGoc;

        final source = member.rosterMember.source;
        final adj = member.rosterMember.adjustment;

        if (source == RosterInclusionSource.DOI_CA) {
          loaiThamGia = AttendanceParticipationType.DOI_CA;
          idLopGoc = adj!.idLopGoc;
          idBuoiVangGoc = null;
        } else if (source == RosterInclusionSource.HOC_BU) {
          loaiThamGia = AttendanceParticipationType.HOC_BU;
          idLopGoc = adj!.idLopGoc;
          idBuoiVangGoc = adj.idBuoiHocGoc;
        } else if (source == RosterInclusionSource.PHAT_SINH) {
          loaiThamGia = AttendanceParticipationType.CHINH;
          idLopGoc = adj!.idLopGoc;
          idBuoiVangGoc = null;
        } else {
          loaiThamGia = AttendanceParticipationType.CHINH;
          idLopGoc = member.rosterMember.membership.idLop;
          idBuoiVangGoc = null;
        }

        if (newState == AttendanceState.HOC_BU &&
            source != RosterInclusionSource.HOC_BU) {
          throw Exception(
            'Trạng thái HỌC BÙ chỉ áp dụng cho học sinh được xếp học bù.',
          );
        }

        toUpsert.add(
          AttendanceRecord(
            idBuoiHoc: sessionId,
            idHocSinh: studentId,
            idLopGoc: idLopGoc,
            trangThai: newState.toStatus()!,
            loaiThamGia: loaiThamGia,
            idBuoiVangGoc: idBuoiVangGoc,
            createdAt: member.persistedRecord?.createdAt ?? now,
            updatedAt: now,
          ),
        );
      }
    }

    await _repo.batchSave(sessionId, toUpsert, toDeleteIds);
  }

  Future<void> finalizeSessionAttendance(
    int sessionId, {
    bool allowIncomplete = false,
  }) async {
    final sheet = await getAttendanceForSession(sessionId);

    if (sheet.session.trangThai == SessionStatus.DA_HOC) {
      return; // Idempotent
    }

    if (!sheet.isOperationallyValid) {
      throw Exception('Không thể hoàn tất: Dữ liệu điểm danh không hợp lệ.');
    }

    if (sheet.session.trangThai == SessionStatus.HUY ||
        sheet.session.trangThai == SessionStatus.NGHI_LE) {
      throw Exception(
        'Không thể hoàn tất điểm danh cho buổi học đã Hủy hoặc Nghỉ lễ.',
      );
    }

    if (sheet.requiresOneOffAdjustments) {
      throw Exception(
        'Buổi học bù/phát sinh chưa có danh sách học sinh tham gia.',
      );
    }

    if (!allowIncomplete && !sheet.isComplete) {
      throw Exception(
        'Vẫn còn ${sheet.unresolvedCount} học sinh chưa điểm danh.',
      );
    }

    await _sessionService.markTaughtFromAttendance(
      sessionId,
      oneOffRosterResolved: !sheet.requiresOneOffAdjustments,
    );
  }
}

@Riverpod(keepAlive: true)
Future<AttendanceService> attendanceService(AttendanceServiceRef ref) async {
  final repo = await ref.watch(attendanceRepositoryProvider.future);
  final rosterService = await ref.watch(rosterServiceProvider.future);
  final sessionService = await ref.watch(sessionServiceProvider.future);
  final leaveRequestService = await ref.watch(
    leaveRequestServiceProvider.future,
  );
  return AttendanceService(
    repo,
    rosterService,
    sessionService,
    leaveRequestService,
  );
}
