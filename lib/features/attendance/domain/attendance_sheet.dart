import '../../roster/domain/roster_member.dart';
import '../../roster/domain/roster_result.dart';
import 'attendance_record.dart';
import 'attendance_state.dart';
import '../../sessions/domain/class_session.dart';

class AttendanceSheetMember {
  final RosterMember rosterMember;
  final AttendanceRecord? persistedRecord;
  final AttendanceState state;

  AttendanceSheetMember({
    required this.rosterMember,
    this.persistedRecord,
    required this.state,
  });

  AttendanceSheetMember copyWith({AttendanceState? state}) {
    return AttendanceSheetMember(
      rosterMember: rosterMember,
      persistedRecord: persistedRecord,
      state: state ?? this.state,
    );
  }
}

enum AttendanceSheetIssueCode { ATTENDANCE_OUTSIDE_ROSTER }

class AttendanceSheetIssue {
  final AttendanceSheetIssueCode code;
  final String message;
  final dynamic context;

  const AttendanceSheetIssue({
    required this.code,
    required this.message,
    this.context,
  });
}

class AttendanceSheet {
  final ClassSession session;
  final List<AttendanceSheetMember> members;
  final List<AttendanceSheetIssue> issues;
  final bool isRosterValid;
  final List<RosterIssue> rosterIssues;

  AttendanceSheet({
    required this.session,
    required this.members,
    required this.issues,
    required this.isRosterValid,
    this.rosterIssues = const [],
  });

  bool get isOperationallyValid => isRosterValid && issues.isEmpty;

  int get unresolvedCount =>
      members.where((m) => m.state == AttendanceState.CHUA_DIEM_DANH).length;

  bool get isComplete => unresolvedCount == 0;
}
