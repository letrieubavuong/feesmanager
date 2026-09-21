import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/database/database_provider.dart';
import '../../roster/domain/roster_service.dart';
import '../../sessions/domain/session_service.dart';
import '../../sessions/domain/class_session.dart';
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

  AttendanceService(this._repo, this._rosterService, this._sessionService);

  Future<AttendanceSheet> getAttendanceForSession(int sessionId) async {
    final session = await _sessionService.getSessionById(sessionId);
    if (session == null) throw Exception('Không tìm thấy buổi học');

    final roster = await _rosterService.getRosterForSession(sessionId);
    final persistedRecords = await _repo.getBySession(sessionId);
    final recordMap = {for (var r in persistedRecords) r.idHocSinh: r};

    final members = roster.participants.map((rm) {
      final record = recordMap[rm.student.id];
      return AttendanceSheetMember(
        rosterMember: rm,
        persistedRecord: record,
        state: AttendanceState.fromStatus(record?.trangThai),
      );
    }).toList();

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
    );
  }

  Future<void> saveDraft(
    int sessionId,
    Map<int, AttendanceState> states,
  ) async {
    final sheet = await getAttendanceForSession(sessionId);

    if (!sheet.isRosterValid) {
      throw Exception(
        'Không thể lưu điểm danh cho danh sách lớp không hợp lệ.',
      );
    }

    if (sheet.session.trangThai == SessionStatus.HUY ||
        sheet.session.trangThai == SessionStatus.NGHI_LE) {
      throw Exception('Không thể điểm danh cho buổi học đã Hủy hoặc Nghỉ lễ.');
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
        if (newState == AttendanceState.HOC_BU) {
          throw Exception(
            'Chức năng đánh dấu HỌC BÙ sẽ được triển khai ở Phase 7.',
          );
        }

        toUpsert.add(
          AttendanceRecord(
            idBuoiHoc: sessionId,
            idHocSinh: studentId,
            idLopGoc: sheet.session.idLop,
            trangThai: newState.toStatus()!,
            loaiThamGia: AttendanceParticipationType.CHINH,
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

    if (!sheet.isOperationallyValid) {
      throw Exception('Không thể hoàn tất: Dữ liệu điểm danh không hợp lệ.');
    }

    if (sheet.session.trangThai == SessionStatus.HUY ||
        sheet.session.trangThai == SessionStatus.NGHI_LE) {
      throw Exception(
        'Không thể hoàn tất điểm danh cho buổi học đã Hủy hoặc Nghỉ lễ.',
      );
    }

    if (sheet.session.loai == SessionType.HOC_BU ||
        sheet.session.loai == SessionType.PHAT_SINH) {
      throw Exception(
        'Buổi học bù/phát sinh cần được điều chỉnh danh sách ở Phase 7 trước khi hoàn tất.',
      );
    }

    if (!allowIncomplete && !sheet.isComplete) {
      throw Exception(
        'Vẫn còn ${sheet.unresolvedCount} học sinh chưa điểm danh.',
      );
    }

    await _sessionService.markTaughtFromAttendance(sessionId);
  }
}

@Riverpod(keepAlive: true)
Future<AttendanceService> attendanceService(AttendanceServiceRef ref) async {
  final repo = await ref.watch(attendanceRepositoryProvider.future);
  final rosterService = await ref.watch(rosterServiceProvider.future);
  final sessionService = await ref.watch(sessionServiceProvider.future);
  return AttendanceService(repo, rosterService, sessionService);
}
