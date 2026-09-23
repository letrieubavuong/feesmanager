import 'schedule_conflict_reason_code.dart';

class ScheduleConflict {
  final ScheduleConflictReasonCode reasonCode;
  final bool isHard;
  final String message;
  final int? existingClassId;
  final int? existingScheduleId;
  final int? existingSessionId;
  final int? constraintId;
  final String? date;
  final int? weekday;
  final String? startTime;
  final String? endTime;
  final String? sourceDescription;

  const ScheduleConflict({
    required this.reasonCode,
    required this.isHard,
    required this.message,
    this.existingClassId,
    this.existingScheduleId,
    this.existingSessionId,
    this.constraintId,
    this.date,
    this.weekday,
    this.startTime,
    this.endTime,
    this.sourceDescription,
  });
}
