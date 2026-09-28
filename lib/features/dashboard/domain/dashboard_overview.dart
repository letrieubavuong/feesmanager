import '../../sessions/domain/class_session.dart';

class DashboardTodaySession {
  final ClassSession session;
  final String className;
  final int? canonicalRosterCount;

  DashboardTodaySession({
    required this.session,
    required this.className,
    this.canonicalRosterCount,
  });
}

enum DashboardTaskType {
  attendanceNow,
  generateSessions,
  finalizeTuition,
  exportReportPdf,
}

class DashboardTask {
  final DashboardTaskType type;
  final String title;
  final String subtitle;
  final bool isEnabled;

  DashboardTask({
    required this.type,
    required this.title,
    required this.subtitle,
    this.isEnabled = true,
  });
}

enum DashboardWarningType {
  unassignedStudents,
  overdueAttendance,
  missingTuitionPolicy,
}

class DashboardWarning {
  final DashboardWarningType type;
  final String title;
  final String description;
  final int count;

  DashboardWarning({
    required this.type,
    required this.title,
    required this.description,
    required this.count,
  });
}

enum DashboardActivityType {
  paymentRecorded,
  paymentCorrection,
  sessionCompleted,
  tuitionFinalized,
  attendanceCorrection,
}

class DashboardActivity {
  final DashboardActivityType type;
  final String title;
  final String subtitle;
  final DateTime timestamp;

  DashboardActivity({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.timestamp,
  });
}

class DashboardOverview {
  final DateTime generatedAt;

  final int todaySessionCount;
  final int pendingAttendanceCount;
  final int unfinalizedTuitionStudentCount;
  final int outstandingDebt;

  final List<DashboardTodaySession> todaySessions;
  final List<DashboardTask> tasks;
  final List<DashboardWarning> warnings;
  final List<DashboardActivity> recentActivities;

  DashboardOverview({
    required this.generatedAt,
    required this.todaySessionCount,
    required this.pendingAttendanceCount,
    required this.unfinalizedTuitionStudentCount,
    required this.outstandingDebt,
    required this.todaySessions,
    required this.tasks,
    required this.warnings,
    required this.recentActivities,
  });
}
