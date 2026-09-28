import 'package:flutter/foundation.dart';

enum TeachingReminderMinutes {
  off(0),
  fiveMinutes(5),
  tenMinutes(10);

  final int minutes;
  const TeachingReminderMinutes(this.minutes);

  static TeachingReminderMinutes fromMinutes(int value) {
    return TeachingReminderMinutes.values.firstWhere(
      (e) => e.minutes == value,
      orElse: () => TeachingReminderMinutes.off,
    );
  }
}

@immutable
class TeachingReminderInstance {
  final int id;
  final int classId;
  final String className;
  final DateTime sessionTime;
  final DateTime reminderTime;

  const TeachingReminderInstance({
    required this.id,
    required this.classId,
    required this.className,
    required this.sessionTime,
    required this.reminderTime,
  });

  String get title => 'Nhắc giờ dạy: $className';

  String get body {
    final hour = sessionTime.hour.toString().padLeft(2, '0');
    final minute = sessionTime.minute.toString().padLeft(2, '0');
    return 'Lớp $className bắt đầu lúc $hour:$minute';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TeachingReminderInstance &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          classId == other.classId &&
          className == other.className &&
          sessionTime == other.sessionTime &&
          reminderTime == other.reminderTime;

  @override
  int get hashCode =>
      id.hashCode ^
      classId.hashCode ^
      className.hashCode ^
      sessionTime.hashCode ^
      reminderTime.hashCode;
}
