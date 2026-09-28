import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/attendance_service.dart';
import '../domain/class_attendance_timeline_item.dart';

part 'class_attendance_timeline_controller.g.dart';

@riverpod
Future<List<ClassAttendanceTimelineItem>> classAttendanceTimeline(
  ClassAttendanceTimelineRef ref, {
  required int classId,
  required String yearMonth,
}) async {
  final service = await ref.watch(attendanceServiceProvider.future);
  return service.getClassAttendanceTimeline(classId, yearMonth);
}
