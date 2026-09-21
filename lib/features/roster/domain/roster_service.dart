import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../sessions/domain/session_service.dart';
import '../../memberships/domain/membership_service.dart';
import '../../schedule/domain/schedule_service.dart';
import '../../students/domain/student_service.dart';
import '../../students/domain/student.dart';
import '../../sessions/domain/class_session.dart';
import '../../session_adjustments/data/session_adjustment_repository.dart';
import '../../session_adjustments/domain/session_adjustment.dart';
import '../../session_adjustments/domain/session_adjustment_service.dart';
import 'roster_member.dart';
import 'roster_result.dart';

part 'roster_service.g.dart';

class RosterService {
  final SessionService _sessionService;
  final MembershipService _membershipService;
  final ScheduleDomainService _scheduleService;
  final StudentService _studentService;
  final SessionAdjustmentRepository _adjustmentRepo;

  RosterService(
    this._sessionService,
    this._membershipService,
    this._scheduleService,
    this._studentService,
    this._adjustmentRepo,
  );

  Future<RosterResult> getBaseRosterForSession(int sessionId) async {
    final session = await _sessionService.getSessionById(sessionId);
    if (session == null) {
      throw Exception('Không tìm thấy buổi học (ID: $sessionId)');
    }

    if (session.loai == SessionType.HOC_BU ||
        session.loai == SessionType.PHAT_SINH) {
      return RosterResult(
        session: session,
        participants: [],
        unassignedMembers: [],
        issues: [],
        requiresOneOffAdjustments: true,
      );
    }

    return await _computeBaseChinhRoster(session);
  }

  Future<RosterResult> getRosterForSession(int sessionId) async {
    final session = await _sessionService.getSessionById(sessionId);
    if (session == null) {
      throw Exception('Không tìm thấy buổi học (ID: $sessionId)');
    }

    List<RosterMember> participants = [];
    List<Student> unassignedMembers = [];
    List<RosterIssue> issues = [];

    // 1. Compute Base Roster
    if (session.loai == SessionType.CHINH) {
      final baseResult = await _computeBaseChinhRoster(session);
      participants = List.from(baseResult.participants);
      unassignedMembers = List.from(baseResult.unassignedMembers);
      issues = List.from(baseResult.issues);

      // Fail closed on blocking base schedule issues
      if (issues.any(
        (i) => i.code != RosterIssueCode.UNASSIGNED_IN_MULTI_SHIFT,
      )) {
        return RosterResult(
          session: session,
          participants: [],
          unassignedMembers: [],
          issues: issues,
        );
      }
    }

    // 2. Process One-Off Adjustments
    final outgoingAdjs = await _adjustmentRepo.getByOriginalSession(sessionId);
    final incomingAdjs = await _adjustmentRepo.getByTargetSession(sessionId);

    // Remove outgoing DOI_CA
    for (final outAdj in outgoingAdjs) {
      if (outAdj.loai == SessionAdjustmentType.DOI_CA) {
        participants.removeWhere((m) => m.student.id == outAdj.idHocSinh);
      }
    }

    // Add incoming adjustments
    final students = await _studentService.getStudents(includeArchived: true);
    final studentMap = {for (var s in students) s.id: s};

    for (final incAdj in incomingAdjs) {
      final student = studentMap[incAdj.idHocSinh];
      if (student == null) {
        issues.add(
          RosterIssue(
            code: RosterIssueCode.ADJUSTMENT_STUDENT_MISSING,
            message:
                'Không tìm thấy hồ sơ học sinh điều chỉnh (ID: ${incAdj.idHocSinh})',
            context: incAdj,
          ),
        );
        continue;
      }

      // Membership validation in orig class
      final origMemberships = await _membershipService
          .getMembershipsForStudentAndClass(incAdj.idHocSinh, incAdj.idLopGoc);

      final validM = origMemberships.cast<dynamic>().firstWhere((m) {
        final den = m.denNgay ?? '9999-12-31';
        return m.tuNgay.compareTo(session.ngay) <= 0 &&
            den.compareTo(session.ngay) >= 0;
      }, orElse: () => null);

      if (validM == null) {
        issues.add(
          RosterIssue(
            code: RosterIssueCode.ADJUSTMENT_MEMBERSHIP_INVALID,
            message:
                'Học sinh ${student.hoTen} không có quá trình học hợp lệ tại lớp gốc.',
            context: incAdj,
          ),
        );
        continue;
      }

      // Check duplicates
      if (participants.any((p) => p.student.id == student.id)) {
        issues.add(
          RosterIssue(
            code: RosterIssueCode.DUPLICATE_ONE_OFF_PARTICIPATION,
            message:
                'Học sinh ${student.hoTen} bị trùng lặp trong danh sách tham gia.',
            context: incAdj,
          ),
        );
        continue;
      }

      RosterInclusionSource source;
      switch (incAdj.loai) {
        case SessionAdjustmentType.DOI_CA:
          if (session.loai != SessionType.CHINH) {
            issues.add(
              RosterIssue(
                code: RosterIssueCode.ADJUSTMENT_TYPE_INVALID_FOR_SESSION,
                message: 'Chỉ buổi học chính thức mới nhận điều chỉnh Đổi ca.',
                context: incAdj,
              ),
            );
            continue;
          }
          source = RosterInclusionSource.DOI_CA;
          break;
        case SessionAdjustmentType.HOC_BU:
          if (session.loai != SessionType.HOC_BU) {
            issues.add(
              RosterIssue(
                code: RosterIssueCode.ADJUSTMENT_TYPE_INVALID_FOR_SESSION,
                message: 'Chỉ buổi Học bù mới nhận điều chỉnh Học bù.',
                context: incAdj,
              ),
            );
            continue;
          }
          source = RosterInclusionSource.HOC_BU;
          break;
        case SessionAdjustmentType.PHAT_SINH:
          if (session.loai != SessionType.PHAT_SINH) {
            issues.add(
              RosterIssue(
                code: RosterIssueCode.ADJUSTMENT_TYPE_INVALID_FOR_SESSION,
                message: 'Chỉ buổi Phát sinh mới nhận điều chỉnh Phát sinh.',
                context: incAdj,
              ),
            );
            continue;
          }
          source = RosterInclusionSource.PHAT_SINH;
          break;
      }

      participants.add(
        RosterMember(
          student: student,
          membership: validM,
          adjustment: incAdj,
          source: source,
        ),
      );
    }

    final requiresOneOff =
        (session.loai == SessionType.HOC_BU ||
            session.loai == SessionType.PHAT_SINH) &&
        incomingAdjs.isEmpty;

    _sortRosterMembers(participants);
    _sortStudents(unassignedMembers);

    return RosterResult(
      session: session,
      participants: participants,
      unassignedMembers: unassignedMembers,
      issues: issues,
      requiresOneOffAdjustments: requiresOneOff,
    );
  }

  Future<RosterResult> _computeBaseChinhRoster(ClassSession session) async {
    final issues = <RosterIssue>[];

    if (session.idLichHoc == null) {
      issues.add(
        const RosterIssue(
          code: RosterIssueCode.SESSION_SCHEDULE_MISSING,
          message: 'Buổi học chính thức thiếu liên kết lịch học gốc.',
        ),
      );
    } else {
      final schedule = await _scheduleService.getScheduleById(
        session.idLichHoc!,
      );
      final sessionDate = DateTime.parse(session.ngay);

      if (schedule == null) {
        issues.add(
          const RosterIssue(
            code: RosterIssueCode.SESSION_SCHEDULE_MISSING,
            message: 'Không tìm thấy lịch học gốc của buổi học này.',
          ),
        );
      } else if (schedule.idLop != session.idLop) {
        issues.add(
          const RosterIssue(
            code: RosterIssueCode.SESSION_SCHEDULE_CLASS_MISMATCH,
            message: 'Lịch học gốc không thuộc về lớp của buổi học này.',
          ),
        );
      } else if (schedule.thuTrongTuan != sessionDate.weekday) {
        issues.add(
          const RosterIssue(
            code: RosterIssueCode.SESSION_SCHEDULE_NOT_EFFECTIVE,
            message:
                'Thứ trong tuần của lịch gốc không khớp với ngày buổi học.',
          ),
        );
      } else if (session.ngay.compareTo(schedule.hieuLucTu) < 0 ||
          (schedule.hieuLucDen != null &&
              session.ngay.compareTo(schedule.hieuLucDen!) > 0)) {
        issues.add(
          const RosterIssue(
            code: RosterIssueCode.SESSION_SCHEDULE_NOT_EFFECTIVE,
            message: 'Lịch học gốc không còn hiệu lực tại ngày của buổi học.',
          ),
        );
      }
    }

    if (issues.any(
      (i) => i.code != RosterIssueCode.UNASSIGNED_IN_MULTI_SHIFT,
    )) {
      return RosterResult(
        session: session,
        participants: [],
        unassignedMembers: [],
        issues: issues,
      );
    }

    final participants = <RosterMember>[];
    final unassignedMembers = <Student>[];
    final referenceDate = DateTime.parse(session.ngay);

    final effectiveSchedules = await _scheduleService.getSchedulesForClass(
      session.idLop,
      date: referenceDate,
    );
    final schedulesForSessionDay = effectiveSchedules
        .where((s) => s.thuTrongTuan == referenceDate.weekday)
        .toList();
    final isMultiShift = schedulesForSessionDay.length >= 2;

    final activeMemberships = await _membershipService.getRoster(
      session.idLop,
      date: referenceDate,
    );
    final students = await _studentService.getStudents(includeArchived: true);
    final studentMap = {for (var s in students) s.id: s};

    final assignments = isMultiShift
        ? await _scheduleService.getAssignmentsForClass(session.idLop)
        : null;

    for (final m in activeMemberships) {
      final student = studentMap[m.idHocSinh];
      if (student == null) {
        issues.add(
          RosterIssue(
            code: RosterIssueCode.STUDENT_PROFILE_MISSING,
            message: 'Không tìm thấy hồ sơ học sinh (ID: ${m.idHocSinh})',
            context: m.idHocSinh,
          ),
        );
        continue;
      }

      if (!isMultiShift) {
        participants.add(
          RosterMember(
            student: student,
            membership: m,
            source: RosterInclusionSource.SINGLE_SHIFT_MEMBERSHIP,
          ),
        );
      } else {
        final activeAssignments = assignments!.where((a) {
          if (a.idHocSinh != m.idHocSinh) return false;
          if (session.ngay.compareTo(a.tuNgay) < 0) return false;
          if (a.denNgay != null && session.ngay.compareTo(a.denNgay!) > 0) {
            return false;
          }
          return true;
        }).toList();

        if (activeAssignments.isEmpty) {
          unassignedMembers.add(student);
          issues.add(
            RosterIssue(
              code: RosterIssueCode.UNASSIGNED_IN_MULTI_SHIFT,
              message: 'Học sinh ${student.hoTen} chưa được phân ca.',
              context: student,
            ),
          );
        } else if (activeAssignments.length > 1) {
          issues.add(
            RosterIssue(
              code: RosterIssueCode.MULTIPLE_ACTIVE_ASSIGNMENTS,
              message: 'Học sinh ${student.hoTen} có nhiều phân ca trùng lặp.',
              context: student,
            ),
          );
        } else {
          final a = activeAssignments.first;
          final aSchedule = await _scheduleService.getScheduleById(a.idLichHoc);
          bool isAssignmentValid = true;

          if (aSchedule == null ||
              aSchedule.idLop != session.idLop ||
              aSchedule.thuTrongTuan != referenceDate.weekday ||
              session.ngay.compareTo(aSchedule.hieuLucTu) < 0 ||
              (aSchedule.hieuLucDen != null &&
                  session.ngay.compareTo(aSchedule.hieuLucDen!) > 0)) {
            isAssignmentValid = false;
          }

          if (isAssignmentValid && a.tuNgay.compareTo(m.tuNgay) < 0) {
            isAssignmentValid = false;
          }
          if (isAssignmentValid && m.denNgay != null) {
            if (a.denNgay == null || a.denNgay!.compareTo(m.denNgay!) > 0) {
              isAssignmentValid = false;
            }
          }

          if (!isAssignmentValid) {
            issues.add(
              RosterIssue(
                code: RosterIssueCode.INVALID_ASSIGNMENT,
                message: 'Phân ca của học sinh ${student.hoTen} không hợp lệ.',
                context: a,
              ),
            );
          } else if (a.idLichHoc == session.idLichHoc) {
            participants.add(
              RosterMember(
                student: student,
                membership: m,
                assignment: a,
                source: RosterInclusionSource.EXPLICIT_ASSIGNMENT,
              ),
            );
          }
        }
      }
    }

    _sortRosterMembers(participants);
    _sortStudents(unassignedMembers);

    return RosterResult(
      session: session,
      participants: participants,
      unassignedMembers: unassignedMembers,
      issues: issues,
    );
  }

  void _sortRosterMembers(List<RosterMember> list) {
    list.sort((a, b) {
      final nameCompare = a.student.hoTen.compareTo(b.student.hoTen);
      if (nameCompare != 0) return nameCompare;
      return (a.student.id ?? 0).compareTo(b.student.id ?? 0);
    });
  }

  void _sortStudents(List<Student> list) {
    list.sort((a, b) {
      final nameCompare = a.hoTen.compareTo(b.hoTen);
      if (nameCompare != 0) return nameCompare;
      return (a.id ?? 0).compareTo(b.id ?? 0);
    });
  }
}

@Riverpod(keepAlive: true)
Future<RosterService> rosterService(RosterServiceRef ref) async {
  final sessionService = await ref.watch(sessionServiceProvider.future);
  final membershipService = await ref.watch(membershipServiceProvider.future);
  final scheduleService = await ref.watch(classScheduleServiceProvider.future);
  final studentService = await ref.watch(studentServiceProvider.future);
  final adjustmentRepo = await ref.watch(
    sessionAdjustmentRepositoryProvider.future,
  );

  return RosterService(
    sessionService,
    membershipService,
    scheduleService,
    studentService,
    adjustmentRepo,
  );
}
