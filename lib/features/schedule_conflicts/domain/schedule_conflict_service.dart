import '../../classes/domain/class_service.dart';
import '../../schedule/data/assignment_repository.dart';
import '../../schedule/data/schedule_repository.dart';
import '../../session_adjustments/data/session_adjustment_repository.dart';
import '../../sessions/data/session_repository.dart';
import '../../sessions/domain/class_session.dart';
import '../data/schedule_constraint_repository.dart';
import 'schedule_conflict.dart';
import 'schedule_conflict_reason_code.dart';
import 'schedule_conflict_result.dart';
import 'schedule_constraint.dart';

class ScheduleConflictService {
  final ScheduleConstraintRepository _constraintRepo;
  final ScheduleRepository _scheduleRepo;
  final AssignmentRepository _assignmentRepo;
  final SessionRepository _sessionRepo;
  final SessionAdjustmentRepository _adjustmentRepo;
  final ClassService _classService;

  ScheduleConflictService(
    this._constraintRepo,
    this._scheduleRepo,
    this._assignmentRepo,
    this._sessionRepo,
    this._adjustmentRepo,
    this._classService,
  );

  /// Evaluates conflict when assigning a student to a recurring schedule
  Future<ScheduleConflictResult> evaluateCandidateAssignment({
    required int studentId,
    required int targetScheduleId,
    required String startDate,
    String? endDate,
    int? excludeAssignmentId,
  }) async {
    final targetSchedule = await _scheduleRepo.getById(targetScheduleId);
    if (targetSchedule == null) {
      throw Exception(
        'Không tìm thấy lịch học cần phân ca (id: $targetScheduleId)',
      );
    }

    final hardConflicts = <ScheduleConflict>[];
    final softWarnings = <ScheduleConflict>[];

    // 1. Check existing Tuition2027 center class assignments
    final existingAssignments = await _assignmentRepo.getByStudent(studentId);
    for (final assignment in existingAssignments) {
      if (assignment.id == excludeAssignmentId) continue;

      if (_isDateRangeOverlap(
        startDate,
        endDate,
        assignment.tuNgay,
        assignment.denNgay,
      )) {
        final existingSchedule = await _scheduleRepo.getById(
          assignment.idLichHoc,
        );
        if (existingSchedule == null) continue;

        if (existingSchedule.thuTrongTuan == targetSchedule.thuTrongTuan) {
          if (_isTimeOverlap(
            existingSchedule.gioBatDau,
            existingSchedule.gioKetThuc,
            targetSchedule.gioBatDau,
            targetSchedule.gioKetThuc,
          )) {
            final reason = _classifyTimeOverlap(
              existingSchedule.gioBatDau,
              existingSchedule.gioKetThuc,
              targetSchedule.gioBatDau,
              targetSchedule.gioKetThuc,
            );

            final targetClass = await _classService.getClassById(
              existingSchedule.idLop,
            );
            final className =
                targetClass?.tenLop ?? 'Lớp #${existingSchedule.idLop}';

            hardConflicts.add(
              ScheduleConflict(
                reasonCode: reason,
                isHard: true,
                message:
                    'Trùng lịch học tại $className (${existingSchedule.gioBatDau}-${existingSchedule.gioKetThuc}, Thứ ${existingSchedule.thuTrongTuan})',
                existingClassId: existingSchedule.idLop,
                existingScheduleId: existingSchedule.id,
                weekday: targetSchedule.thuTrongTuan,
                startTime: existingSchedule.gioBatDau,
                endTime: existingSchedule.gioKetThuc,
                sourceDescription: className,
              ),
            );
          }
        }
      }
    }

    // 2. Check student constraints (HARD_BLOCK, SOFT_PREFERENCE, OTHER_CENTER)
    final activeConstraints = await _constraintRepo.getActiveForStudent(
      studentId,
    );
    for (final constraint in activeConstraints) {
      if (constraint.occurrenceType == OccurrenceType.DINH_KY) {
        if (constraint.weekday == targetSchedule.thuTrongTuan) {
          if (_isDateRangeOverlap(
            startDate,
            endDate,
            constraint.effectiveFrom!,
            constraint.effectiveTo,
          )) {
            _evaluateConstraintAgainstTime(
              constraint: constraint,
              candStart: targetSchedule.gioBatDau,
              candEnd: targetSchedule.gioKetThuc,
              weekday: targetSchedule.thuTrongTuan,
              hardConflicts: hardConflicts,
              softWarnings: softWarnings,
            );
          }
        }
      } else if (constraint.occurrenceType == OccurrenceType.MOT_LAN) {
        final specDate = constraint.specificDate!;
        final specDt = DateTime.parse(specDate);
        if (specDt.weekday == targetSchedule.thuTrongTuan) {
          if (_isDateInInterval(specDate, startDate, endDate)) {
            _evaluateConstraintAgainstTime(
              constraint: constraint,
              candStart: targetSchedule.gioBatDau,
              candEnd: targetSchedule.gioKetThuc,
              weekday: targetSchedule.thuTrongTuan,
              date: specDate,
              hardConflicts: hardConflicts,
              softWarnings: softWarnings,
            );
          }
        }
      }
    }

    return ScheduleConflictResult(
      hardConflicts: hardConflicts,
      softWarnings: softWarnings,
    );
  }

  /// Evaluates conflict for a one-off session candidate (Đổi ca, Học bù, Phát sinh)
  Future<ScheduleConflictResult> evaluateOneOffCandidate({
    required int studentId,
    required String targetDate,
    required String startTime,
    required String endTime,
    int? excludeSessionId,
    int? excludeClassId,
  }) async {
    final hardConflicts = <ScheduleConflict>[];
    final softWarnings = <ScheduleConflict>[];

    final targetDt = DateTime.parse(targetDate);
    final weekday = targetDt.weekday;

    // 1. Check recurring center class assignments active on targetDate
    final existingAssignments = await _assignmentRepo.getByStudent(studentId);
    for (final assignment in existingAssignments) {
      if (_isDateInInterval(
        targetDate,
        assignment.tuNgay,
        assignment.denNgay,
      )) {
        final existingSchedule = await _scheduleRepo.getById(
          assignment.idLichHoc,
        );
        if (existingSchedule == null) continue;
        if (excludeClassId != null &&
            existingSchedule.idLop == excludeClassId) {
          continue;
        }

        if (existingSchedule.thuTrongTuan == weekday) {
          if (_isTimeOverlap(
            existingSchedule.gioBatDau,
            existingSchedule.gioKetThuc,
            startTime,
            endTime,
          )) {
            final reason = _classifyTimeOverlap(
              existingSchedule.gioBatDau,
              existingSchedule.gioKetThuc,
              startTime,
              endTime,
            );

            final targetClass = await _classService.getClassById(
              existingSchedule.idLop,
            );
            final className =
                targetClass?.tenLop ?? 'Lớp #${existingSchedule.idLop}';

            hardConflicts.add(
              ScheduleConflict(
                reasonCode: reason,
                isHard: true,
                message:
                    'Trùng lịch học định kỳ tại $className (${existingSchedule.gioBatDau}-${existingSchedule.gioKetThuc}, ngày $targetDate)',
                existingClassId: existingSchedule.idLop,
                existingScheduleId: existingSchedule.id,
                date: targetDate,
                weekday: weekday,
                startTime: existingSchedule.gioBatDau,
                endTime: existingSchedule.gioKetThuc,
                sourceDescription: className,
              ),
            );
          }
        }
      }
    }

    // 2. Check student constraints active on targetDate
    final activeConstraints = await _constraintRepo.getActiveForStudent(
      studentId,
    );
    for (final constraint in activeConstraints) {
      bool applies = false;
      if (constraint.occurrenceType == OccurrenceType.DINH_KY) {
        if (constraint.weekday == weekday &&
            _isDateInInterval(
              targetDate,
              constraint.effectiveFrom!,
              constraint.effectiveTo,
            )) {
          applies = true;
        }
      } else if (constraint.occurrenceType == OccurrenceType.MOT_LAN) {
        if (constraint.specificDate == targetDate) {
          applies = true;
        }
      }

      if (applies) {
        _evaluateConstraintAgainstTime(
          constraint: constraint,
          candStart: startTime,
          candEnd: endTime,
          weekday: weekday,
          date: targetDate,
          hardConflicts: hardConflicts,
          softWarnings: softWarnings,
        );
      }
    }

    // 3. Check existing actual sessions and adjustments on targetDate
    final allSessionsOnDate = await _sessionRepo.getByDate(targetDate);
    for (final session in allSessionsOnDate) {
      if (session.id == excludeSessionId) continue;
      if (session.trangThai == SessionStatus.HUY ||
          session.trangThai == SessionStatus.NGHI_LE) {
        continue;
      }

      // Check if student is in roster/adjustments of this session
      final adjustments = await _adjustmentRepo.getByTargetSession(session.id!);
      final isAdjustmentParticipant = adjustments.any(
        (a) => a.idHocSinh == studentId,
      );

      bool isRostered = isAdjustmentParticipant;
      if (!isRostered) {
        // Check if student has base assignment for this class/session
        final classAssignments = await _assignmentRepo.getByStudent(studentId);
        isRostered = classAssignments.any(
          (a) =>
              a.idLop == session.idLop &&
              _isDateInInterval(targetDate, a.tuNgay, a.denNgay),
        );
      }

      if (isRostered) {
        if (_isTimeOverlap(
          session.gioBatDau,
          session.gioKetThuc,
          startTime,
          endTime,
        )) {
          final targetClass = await _classService.getClassById(session.idLop);
          final className = targetClass?.tenLop ?? 'Lớp #${session.idLop}';

          hardConflicts.add(
            ScheduleConflict(
              reasonCode: ScheduleConflictReasonCode.ONE_OFF_SESSION_CONFLICT,
              isHard: true,
              message:
                  'Trùng lịch với buổi học khác ngày $targetDate tại $className (${session.gioBatDau}-${session.gioKetThuc})',
              existingClassId: session.idLop,
              existingSessionId: session.id,
              date: targetDate,
              weekday: weekday,
              startTime: session.gioBatDau,
              endTime: session.gioKetThuc,
              sourceDescription: className,
            ),
          );
        }
      }
    }

    return ScheduleConflictResult(
      hardConflicts: hardConflicts,
      softWarnings: softWarnings,
    );
  }

  void _evaluateConstraintAgainstTime({
    required ScheduleConstraint constraint,
    required String candStart,
    required String candEnd,
    int? weekday,
    String? date,
    required List<ScheduleConflict> hardConflicts,
    required List<ScheduleConflict> softWarnings,
  }) {
    final overlap = _isTimeOverlap(
      constraint.startTime,
      constraint.endTime,
      candStart,
      candEnd,
    );

    final sourceDesc =
        constraint.sourceName != null && constraint.sourceName!.isNotEmpty
        ? constraint.sourceName!
        : constraint.type.displayName;

    if (overlap) {
      if (constraint.type == ConstraintType.HARD_BLOCK) {
        hardConflicts.add(
          ScheduleConflict(
            reasonCode: ScheduleConflictReasonCode.HARD_BLOCK,
            isHard: true,
            message:
                'Trùng lịch bận cố định: $sourceDesc (${constraint.startTime}-${constraint.endTime})',
            constraintId: constraint.id,
            date: date,
            weekday: weekday,
            startTime: constraint.startTime,
            endTime: constraint.endTime,
            sourceDescription: sourceDesc,
          ),
        );
      } else if (constraint.type == ConstraintType.OTHER_CENTER) {
        hardConflicts.add(
          ScheduleConflict(
            reasonCode: ScheduleConflictReasonCode.OTHER_CENTER_CLASS,
            isHard: true,
            message:
                'Trùng lịch học tại trung tâm khác: $sourceDesc (${constraint.startTime}-${constraint.endTime})',
            constraintId: constraint.id,
            date: date,
            weekday: weekday,
            startTime: constraint.startTime,
            endTime: constraint.endTime,
            sourceDescription: sourceDesc,
          ),
        );
      } else if (constraint.type == ConstraintType.SOFT_PREFERENCE) {
        softWarnings.add(
          ScheduleConflict(
            reasonCode: ScheduleConflictReasonCode.SOFT_PREFERENCE,
            isHard: false,
            message:
                'Vào khung giờ không ưu tiên: $sourceDesc (${constraint.startTime}-${constraint.endTime})',
            constraintId: constraint.id,
            date: date,
            weekday: weekday,
            startTime: constraint.startTime,
            endTime: constraint.endTime,
            sourceDescription: sourceDesc,
          ),
        );
      }
    } else {
      // Check travel buffer for OTHER_CENTER
      if (constraint.type == ConstraintType.OTHER_CENTER &&
          constraint.travelBufferMinutes > 0) {
        final gapMinutes = _calculateGapMinutes(
          candStart,
          candEnd,
          constraint.startTime,
          constraint.endTime,
        );

        if (gapMinutes < constraint.travelBufferMinutes) {
          softWarnings.add(
            ScheduleConflict(
              reasonCode: ScheduleConflictReasonCode.TRAVEL_BUFFER,
              isHard: false,
              message:
                  'Khoảng cách giữa 2 ca ($gapMinutes phút) ít hơn thời gian di chuyển (${constraint.travelBufferMinutes} phút) với $sourceDesc',
              constraintId: constraint.id,
              date: date,
              weekday: weekday,
              startTime: constraint.startTime,
              endTime: constraint.endTime,
              sourceDescription: sourceDesc,
            ),
          );
        }
      }
    }
  }

  bool _isTimeOverlap(String s1, String e1, String s2, String e2) {
    return s1.compareTo(e2) < 0 && s2.compareTo(e1) < 0;
  }

  ScheduleConflictReasonCode _classifyTimeOverlap(
    String s1,
    String e1,
    String s2,
    String e2,
  ) {
    if (s1 == s2 && e1 == e2) {
      return ScheduleConflictReasonCode.EXACT_OVERLAP;
    }
    final start1 = _timeToMinutes(s1);
    final end1 = _timeToMinutes(e1);
    final start2 = _timeToMinutes(s2);
    final end2 = _timeToMinutes(e2);

    if ((start1 <= start2 && end1 >= end2) ||
        (start2 <= start1 && end2 >= end1)) {
      return ScheduleConflictReasonCode.CONTAINED_OVERLAP;
    }

    return ScheduleConflictReasonCode.PARTIAL_OVERLAP;
  }

  bool _isDateRangeOverlap(
    String start1,
    String? end1,
    String start2,
    String? end2,
  ) {
    if (end1 != null && end1.compareTo(start2) < 0) return false;
    if (end2 != null && start1.compareTo(end2) > 0) return false;
    return true;
  }

  bool _isDateInInterval(String dateStr, String startStr, String? endStr) {
    if (dateStr.compareTo(startStr) < 0) return false;
    if (endStr != null && dateStr.compareTo(endStr) > 0) return false;
    return true;
  }

  int _timeToMinutes(String timeStr) {
    final parts = timeStr.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  int _calculateGapMinutes(String s1, String e1, String s2, String e2) {
    final start1 = _timeToMinutes(s1);
    final end1 = _timeToMinutes(e1);
    final start2 = _timeToMinutes(s2);
    final end2 = _timeToMinutes(e2);

    if (start1 >= end2) {
      return start1 - end2;
    } else if (start2 >= end1) {
      return start2 - end1;
    } else {
      return 0; // Overlapping
    }
  }
}
