// ignore_for_file: constant_identifier_names

import '../../sessions/domain/class_session.dart';
import '../../students/domain/student.dart';
import 'roster_member.dart';

enum RosterIssueCode {
  SESSION_SCHEDULE_MISSING,
  SESSION_SCHEDULE_CLASS_MISMATCH,
  SESSION_SCHEDULE_NOT_EFFECTIVE,
  STUDENT_PROFILE_MISSING,
  UNASSIGNED_IN_MULTI_SHIFT,
  MULTIPLE_ACTIVE_ASSIGNMENTS,
  INVALID_ASSIGNMENT,
  ADJUSTMENT_STUDENT_MISSING,
  ADJUSTMENT_SOURCE_CLASS_MISSING,
  ADJUSTMENT_ORIGINAL_SESSION_MISSING,
  ADJUSTMENT_TARGET_SESSION_MISMATCH,
  ADJUSTMENT_MEMBERSHIP_INVALID,
  ADJUSTMENT_TYPE_INVALID_FOR_SESSION,
  DUPLICATE_ONE_OFF_PARTICIPATION,
}

class RosterIssue {
  final RosterIssueCode code;
  final String message;
  final dynamic context;

  const RosterIssue({required this.code, required this.message, this.context});
}

class RosterResult {
  final ClassSession session;
  final List<RosterMember> participants;
  final List<Student> unassignedMembers;
  final List<RosterIssue> issues;
  final bool requiresOneOffAdjustments;

  const RosterResult({
    required this.session,
    required this.participants,
    required this.unassignedMembers,
    required this.issues,
    this.requiresOneOffAdjustments = false,
  });

  bool get isOperationallyValid => issues.every((i) => _isNonBlocking(i.code));

  bool _isNonBlocking(RosterIssueCode code) {
    // Some issues might just be warnings
    return code == RosterIssueCode.UNASSIGNED_IN_MULTI_SHIFT;
  }
}
