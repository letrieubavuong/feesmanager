// ignore_for_file: constant_identifier_names

import '../../students/domain/student.dart';
import '../../memberships/domain/membership.dart';
import '../../schedule/domain/student_shift_assignment.dart';
import '../../session_adjustments/domain/session_adjustment.dart';

enum RosterInclusionSource {
  SINGLE_SHIFT_MEMBERSHIP,
  EXPLICIT_ASSIGNMENT,
  DOI_CA,
  HOC_BU,
  PHAT_SINH,
}

class RosterMember {
  final Student student;
  final ClassMembership membership;
  final StudentShiftAssignment? assignment;
  final SessionAdjustment? adjustment;
  final RosterInclusionSource source;

  const RosterMember({
    required this.student,
    required this.membership,
    this.assignment,
    this.adjustment,
    required this.source,
  });
}
