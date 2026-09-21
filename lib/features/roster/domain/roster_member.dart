// ignore_for_file: constant_identifier_names

import '../../students/domain/student.dart';
import '../../memberships/domain/membership.dart';
import '../../schedule/domain/student_shift_assignment.dart';

enum RosterInclusionSource { SINGLE_SHIFT_MEMBERSHIP, EXPLICIT_ASSIGNMENT }

class RosterMember {
  final Student student;
  final ClassMembership membership;
  final StudentShiftAssignment? assignment;
  final RosterInclusionSource source;

  const RosterMember({
    required this.student,
    required this.membership,
    this.assignment,
    required this.source,
  });
}
