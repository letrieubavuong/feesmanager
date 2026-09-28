import 'package:intl/intl.dart';
import '../../schedule/domain/class_schedule.dart';
import '../../sessions/domain/class_session.dart';
import 'teaching_reminder.dart';

class TeachingReminderPlanner {
  const TeachingReminderPlanner();

  static List<TeachingReminderInstance> buildUpcoming({
    required DateTime now,
    required List<ClassSchedule> schedules,
    required List<ClassSession> actualSessions,
    required Map<int, String> classNames,
    required TeachingReminderMinutes reminderMinutes,
    int horizonDays = 30,
  }) {
    if (reminderMinutes == TeachingReminderMinutes.off) {
      return const [];
    }

    final dateFormat = DateFormat('yyyy-MM-dd');
    final reminders = <TeachingReminderInstance>[];
    final processedClassDates = <String>{}; // Key: "$idLop-$dateStr"

    for (int i = 0; i <= horizonDays; i++) {
      final date = DateTime(
        now.year,
        now.month,
        now.day,
      ).add(Duration(days: i));
      final dateStr = dateFormat.format(date);
      final weekday = date.weekday;

      // 1. Process actual sessions for this date first (overrides schedules)
      final sessionsOnDate = actualSessions.where((s) => s.ngay == dateStr);
      for (final session in sessionsOnDate) {
        processedClassDates.add('${session.idLop}-$dateStr');

        // Skip canceled or holiday sessions
        if (session.trangThai == SessionStatus.HUY ||
            session.trangThai == SessionStatus.NGHI_LE) {
          continue;
        }

        final timeParts = _parseTime(session.gioBatDau);
        if (timeParts == null) continue;

        final sessionTime = DateTime(
          date.year,
          date.month,
          date.day,
          timeParts.hour,
          timeParts.minute,
        );

        final reminderTime = sessionTime.subtract(
          Duration(minutes: reminderMinutes.minutes),
        );

        if (reminderTime.isAfter(now)) {
          final className =
              classNames[session.idLop] ?? 'Lớp #${session.idLop}';
          final idKey = 'actual-${session.idLop}-$dateStr-${session.id ?? 0}';
          reminders.add(
            TeachingReminderInstance(
              id: idKey.hashCode & 0x7FFFFFFF,
              classId: session.idLop,
              className: className,
              sessionTime: sessionTime,
              reminderTime: reminderTime,
            ),
          );
        }
      }

      // 2. Process recurring schedules for classes without actual sessions on this date
      final activeSchedulesOnDate = schedules.where((s) {
        return s.thuTrongTuan == weekday && s.isEffectiveOn(date);
      });

      for (final schedule in activeSchedulesOnDate) {
        final key = '${schedule.idLop}-$dateStr';
        if (processedClassDates.contains(key)) continue;

        final timeParts = _parseTime(schedule.gioBatDau);
        if (timeParts == null) continue;

        final sessionTime = DateTime(
          date.year,
          date.month,
          date.day,
          timeParts.hour,
          timeParts.minute,
        );

        final reminderTime = sessionTime.subtract(
          Duration(minutes: reminderMinutes.minutes),
        );

        if (reminderTime.isAfter(now)) {
          final className =
              classNames[schedule.idLop] ?? 'Lớp #${schedule.idLop}';
          final idKey =
              'schedule-${schedule.idLop}-$dateStr-${schedule.id ?? 0}';
          reminders.add(
            TeachingReminderInstance(
              id: idKey.hashCode & 0x7FFFFFFF,
              classId: schedule.idLop,
              className: className,
              sessionTime: sessionTime,
              reminderTime: reminderTime,
            ),
          );
        }
      }
    }

    reminders.sort((a, b) => a.reminderTime.compareTo(b.reminderTime));
    return reminders;
  }

  static TimeOfDayParts? _parseTime(String timeStr) {
    try {
      final parts = timeStr.trim().split(':');
      if (parts.length >= 2) {
        return TimeOfDayParts(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }
    } catch (_) {}
    return null;
  }
}

class TimeOfDayParts {
  final int hour;
  final int minute;
  const TimeOfDayParts({required this.hour, required this.minute});
}
