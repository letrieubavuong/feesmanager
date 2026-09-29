import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../classes/domain/class_service.dart';
import '../../sessions/domain/class_session.dart';
import '../../sessions/domain/session_service.dart';

final classReminderServiceProvider = Provider<ClassReminderService>((ref) {
  return ClassReminderService(ref);
});

final reminderMinutesProvider = FutureProvider<int>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getInt(ClassReminderService.preferenceKey) ?? 0;
});

class ClassReminderService {
  static const preferenceKey = 'class_reminder_minutes';
  static const _scheduledIdsKey = 'class_reminder_scheduled_ids';
  final Ref _ref;
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  ClassReminderService(this._ref);

  Future<void> setMinutes(int minutes) async {
    if (minutes != 0 && minutes != 5 && minutes != 10) {
      throw ArgumentError.value(minutes);
    }
    final prefs = await SharedPreferences.getInstance();
    if (minutes != 0) {
      await _initialize();
      final allowed = await _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
      if (allowed == false) {
        throw Exception('Cần cấp quyền thông báo để nhắc trước giờ dạy.');
      }
    }
    await prefs.setInt(preferenceKey, minutes);
    await refresh();
    _ref.invalidate(reminderMinutesProvider);
  }

  Future<void> _initialize() async {
    tzdata.initializeTimeZones();
    await _notifications.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('teacher_notebook_foreground'),
        iOS: DarwinInitializationSettings(),
      ),
    );
  }

  Future<void> refresh() async {
    final prefs = await SharedPreferences.getInstance();
    final oldIds = prefs.getStringList(_scheduledIdsKey) ?? const <String>[];
    await _initialize();
    for (final oldId in oldIds) {
      final id = int.tryParse(oldId);
      if (id != null) await _notifications.cancel(id: id);
    }

    final minutes = prefs.getInt(preferenceKey) ?? 0;
    if (minutes == 0) {
      await prefs.setStringList(_scheduledIdsKey, []);
      return;
    }
    final now = DateTime.now();
    final sessionService = await _ref.read(sessionServiceProvider.future);
    final classService = await _ref.read(classServiceProvider.future);
    final sessions = await sessionService.getSessionsInDateRange(
      fromDate: now.toIso8601String().substring(0, 10),
      toDate: now
          .add(const Duration(days: 30))
          .toIso8601String()
          .substring(0, 10),
    );
    final classIds = sessions.map((s) => s.idLop).toSet().toList();
    final classes = await classService.getClassesByIds(classIds);
    final classNames = {for (final cls in classes) cls.id: cls.tenLop};
    final newIds = <String>[];
    for (final session in sessions) {
      if (session.trangThai != SessionStatus.DU_KIEN || session.id == null) {
        continue;
      }
      final start = DateTime.tryParse(
        '${session.ngay}T${session.gioBatDau}:00',
      );
      if (start == null) continue;
      final reminder = start.subtract(Duration(minutes: minutes));
      if (!reminder.isAfter(now)) continue;
      final id = session.id!;
      await _notifications.zonedSchedule(
        id: id,
        title: 'Sắp đến giờ dạy',
        body:
            '${classNames[session.idLop] ?? "Lớp học"} • ${session.gioBatDau}',
        scheduledDate: tz.TZDateTime.from(reminder, tz.getLocation('UTC')),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'teaching_reminders',
            'Nhắc giờ dạy',
            channelDescription: 'Thông báo trước buổi học',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
      newIds.add('$id');
    }
    await prefs.setStringList(_scheduledIdsKey, newIds);
  }
}
