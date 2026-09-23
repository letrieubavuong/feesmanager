import 'schedule_conflict.dart';
import 'schedule_conflict_reason_code.dart';

class ScheduleConflictResult {
  final bool canAssign;
  final List<ScheduleConflict> hardConflicts;
  final List<ScheduleConflict> softWarnings;
  final Set<ScheduleConflictReasonCode> reasonCodes;

  ScheduleConflictResult({
    required this.hardConflicts,
    required this.softWarnings,
  }) : canAssign = hardConflicts.isEmpty,
       reasonCodes = {
         ...hardConflicts.map((c) => c.reasonCode),
         ...softWarnings.map((c) => c.reasonCode),
       };

  factory ScheduleConflictResult.clear() {
    return ScheduleConflictResult(
      hardConflicts: const [],
      softWarnings: const [],
    );
  }

  bool get hasWarnings => softWarnings.isNotEmpty;
  bool get hasConflicts => hardConflicts.isNotEmpty;
}
