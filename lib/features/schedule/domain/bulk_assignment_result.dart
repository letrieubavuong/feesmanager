import '../../schedule_conflicts/domain/schedule_conflict_result.dart';
import '../../students/domain/student.dart';

enum BulkAssignmentStatus {
  ready,
  alreadyAssigned,
  hardConflict,
  invalidBoundary,
  failed,
}

class BulkAssignmentItemResult {
  final int studentId;
  final String studentName;
  final BulkAssignmentStatus status;
  final ScheduleConflictResult? conflictResult;
  final String? message;

  const BulkAssignmentItemResult({
    required this.studentId,
    required this.studentName,
    required this.status,
    this.conflictResult,
    this.message,
  });

  bool get isReady => status == BulkAssignmentStatus.ready;
  bool get isBlocked =>
      status == BulkAssignmentStatus.hardConflict ||
      status == BulkAssignmentStatus.invalidBoundary ||
      status == BulkAssignmentStatus.failed;
  bool get hasWarnings =>
      conflictResult != null && conflictResult!.hasWarnings;
}

class BulkAssignmentPreview {
  final List<Student> readyStudents;
  final List<BulkAssignmentItemResult> blocked;
  final List<BulkAssignmentItemResult> warnings;

  const BulkAssignmentPreview({
    required this.readyStudents,
    required this.blocked,
    required this.warnings,
  });
}

class BulkAssignmentResult {
  final int totalAttempted;
  final int successCount;
  final List<BulkAssignmentItemResult> items;

  const BulkAssignmentResult({
    required this.totalAttempted,
    required this.successCount,
    required this.items,
  });
}
