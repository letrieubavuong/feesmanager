import '../../sessions/domain/class_session.dart';

class ClassAttendanceTimelineItem {
  final ClassSession session;
  final int presentCount;
  final int lateCount;
  final int excusedCount;
  final int unexcusedCount;
  final int recordedCount;
  final bool hasCorrectionHistory;

  const ClassAttendanceTimelineItem({
    required this.session,
    required this.presentCount,
    required this.lateCount,
    required this.excusedCount,
    required this.unexcusedCount,
    required this.recordedCount,
    required this.hasCorrectionHistory,
  });
}
