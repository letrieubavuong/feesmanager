import '../../sessions/domain/class_session.dart';
import 'class.dart';
import 'class_filter.dart';

enum ClassOperationalStatus {
  needsAttendance,
  inProgress,
  upcomingToday,
  completedToday,
  missingTuitionPolicy,
  hasDebt,
  normal,
  archived,
}

enum ClassWarningType {
  missingTuitionPolicy,
  overdueAttendance,
  missingGeneratedSessions,
}

class ClassOperationalWarning {
  final ClassWarningType type;
  final String message;
  final int count;
  final List<int>? relatedIds;

  const ClassOperationalWarning({
    required this.type,
    required this.message,
    required this.count,
    this.relatedIds,
  });
}

class ClassOperationalRow {
  final ClassEntity classEntity;
  final int activeStudentCount;
  final String scheduleText;
  final ClassOperationalStatus status;
  final String secondaryStatusText;
  final int currentMonthDebt;
  final bool missingTuitionPolicy;
  final ClassSession? todaySession;

  const ClassOperationalRow({
    required this.classEntity,
    required this.activeStudentCount,
    required this.scheduleText,
    required this.status,
    required this.secondaryStatusText,
    required this.currentMonthDebt,
    required this.missingTuitionPolicy,
    this.todaySession,
  });
}

class ClassListOverview {
  final ClassFilter filter;
  final int activeClassCount;
  final int todaySessionCount;
  final int pendingAttendanceCount;
  final int missingTuitionPolicyCount;
  final List<ClassOperationalRow> rows;
  final List<ClassOperationalWarning> warnings;

  const ClassListOverview({
    required this.filter,
    required this.activeClassCount,
    required this.todaySessionCount,
    required this.pendingAttendanceCount,
    required this.missingTuitionPolicyCount,
    required this.rows,
    required this.warnings,
  });
}
