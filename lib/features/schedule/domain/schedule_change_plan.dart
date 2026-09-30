class ScheduleChangePlan {
  final int scheduleId;
  final int newWeekday;
  final String newStart;
  final String newEnd;
  final String effectiveFrom;
  final String? effectiveTo;
  final String applyFrom;
  final bool isDirectEdit;
  final List<String> protectedSessions;
  final List<String> conflicts;
  final bool hasHardConflict;
  final int affectedAssignmentsCount;
  final List<String> affectedMonths;
  final String revisionToken;

  const ScheduleChangePlan({
    required this.scheduleId,
    required this.newWeekday,
    required this.newStart,
    required this.newEnd,
    required this.effectiveFrom,
    this.effectiveTo,
    required this.applyFrom,
    required this.isDirectEdit,
    required this.protectedSessions,
    required this.conflicts,
    required this.hasHardConflict,
    required this.affectedAssignmentsCount,
    required this.affectedMonths,
    required this.revisionToken,
  });
}
