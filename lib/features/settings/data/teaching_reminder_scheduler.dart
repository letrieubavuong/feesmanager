import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../domain/teaching_reminder.dart';

class TeachingReminderScheduler {
  final FlutterLocalNotificationsPlugin _notificationsPlugin;
  bool _isInitialized = false;

  TeachingReminderScheduler({
    FlutterLocalNotificationsPlugin? notificationsPlugin,
  }) : _notificationsPlugin =
           notificationsPlugin ?? FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    if (_isInitialized) return;

    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _notificationsPlugin.initialize(settings: initSettings);
    _isInitialized = true;
  }

  Future<bool> isPermissionGranted() async {
    await init();
    if (Platform.isAndroid) {
      final androidImpl = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (androidImpl != null) {
        final granted = await androidImpl.areNotificationsEnabled();
        return granted ?? false;
      }
    } else if (Platform.isIOS || Platform.isMacOS) {
      final darwinImpl = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      if (darwinImpl != null) {
        final granted = await darwinImpl.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }
    }
    return true;
  }

  Future<bool> requestPermission() async {
    await init();
    if (Platform.isAndroid) {
      final androidImpl = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (androidImpl != null) {
        final granted = await androidImpl.requestNotificationsPermission();
        return granted ?? false;
      }
    } else if (Platform.isIOS || Platform.isMacOS) {
      final darwinImpl = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      if (darwinImpl != null) {
        final granted = await darwinImpl.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }
    }
    return true;
  }

  Future<void> syncReminders(List<TeachingReminderInstance> reminders) async {
    await init();

    // Cancel all existing teaching reminders to ensure no duplicate or stale notifications
    await _notificationsPlugin.cancelAll();

    if (reminders.isEmpty) return;

    final permissionGranted = await isPermissionGranted();
    if (!permissionGranted) return;

    const androidDetails = AndroidNotificationDetails(
      'teaching_reminders_channel',
      'Nhắc giờ dạy',
      channelDescription: 'Thông báo nhắc nhở trước giờ học/giờ dạy',
      importance: Importance.high,
      priority: Priority.high,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
    );

    final localLocation = tz.local;

    for (final reminder in reminders) {
      try {
        final scheduledDate = tz.TZDateTime.from(
          reminder.reminderTime,
          localLocation,
        );

        await _notificationsPlugin.zonedSchedule(
          id: reminder.id,
          title: reminder.title,
          body: reminder.body,
          scheduledDate: scheduledDate,
          notificationDetails: notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
      } catch (_) {
        // Fallback for devices without exact alarm permission
        try {
          final scheduledDate = tz.TZDateTime.from(
            reminder.reminderTime,
            localLocation,
          );
          await _notificationsPlugin.zonedSchedule(
            id: reminder.id,
            title: reminder.title,
            body: reminder.body,
            scheduledDate: scheduledDate,
            notificationDetails: notificationDetails,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          );
        } catch (_) {}
      }
    }
  }
}
