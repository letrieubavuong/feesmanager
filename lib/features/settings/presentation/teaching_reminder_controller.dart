import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../classes/domain/class_filter.dart';
import '../../classes/domain/class_service.dart';
import '../../schedule/domain/class_schedule.dart';
import '../../schedule/domain/schedule_service.dart';
import '../../sessions/domain/session_service.dart';
import '../data/teaching_reminder_scheduler.dart';
import '../domain/teaching_reminder.dart';
import '../domain/teaching_reminder_planner.dart';

const _prefKey = 'teaching_reminder_minutes';

final teachingReminderSchedulerProvider = Provider<TeachingReminderScheduler>((
  ref,
) {
  return TeachingReminderScheduler();
});

class TeachingReminderState {
  final TeachingReminderMinutes minutes;
  final bool isPermissionGranted;

  const TeachingReminderState({
    required this.minutes,
    required this.isPermissionGranted,
  });

  TeachingReminderState copyWith({
    TeachingReminderMinutes? minutes,
    bool? isPermissionGranted,
  }) {
    return TeachingReminderState(
      minutes: minutes ?? this.minutes,
      isPermissionGranted: isPermissionGranted ?? this.isPermissionGranted,
    );
  }
}

class TeachingReminderController extends StateNotifier<TeachingReminderState> {
  final TeachingReminderScheduler _scheduler;
  final Ref _ref;

  TeachingReminderController(this._scheduler, this._ref)
    : super(
        const TeachingReminderState(
          minutes: TeachingReminderMinutes.off,
          isPermissionGranted: true,
        ),
      ) {
    _loadState();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMinutes = prefs.getInt(_prefKey) ?? 0;
    final minutes = TeachingReminderMinutes.fromMinutes(savedMinutes);
    final isGranted = await _scheduler.isPermissionGranted();

    state = TeachingReminderState(
      minutes: minutes,
      isPermissionGranted: isGranted,
    );

    if (minutes != TeachingReminderMinutes.off) {
      await syncNow();
    }
  }

  Future<void> setReminderMinutes(TeachingReminderMinutes value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefKey, value.minutes);

    bool isGranted = state.isPermissionGranted;
    if (value != TeachingReminderMinutes.off) {
      isGranted = await _scheduler.requestPermission();
    }

    state = TeachingReminderState(
      minutes: value,
      isPermissionGranted: isGranted,
    );

    await syncNow();
  }

  Future<void> syncNow() async {
    if (state.minutes == TeachingReminderMinutes.off) {
      await _scheduler.syncReminders(const []);
      return;
    }

    try {
      final now = DateTime.now();
      final classRepo = await _ref.read(classRepositoryProvider.future);
      final classes = await classRepo.getAll(filter: ClassFilter.all);
      final classNames = {for (final c in classes) c.id!: c.tenLop};

      final scheduleRepo = await _ref.read(scheduleRepositoryProvider.future);
      final maps = await scheduleRepo.db.query('lich_hoc');
      final schedules = maps.map((m) => ClassSchedule.fromMap(m)).toList();

      final sessionRepo = await _ref.read(sessionRepositoryProvider.future);
      final startDate = DateFormat('yyyy-MM-dd').format(now);
      final endDate = DateFormat(
        'yyyy-MM-dd',
      ).format(now.add(const Duration(days: 30)));
      final sessions = await sessionRepo.getByDateRange(
        fromDate: startDate,
        toDate: endDate,
      );

      final reminders = TeachingReminderPlanner.buildUpcoming(
        now: now,
        schedules: schedules,
        actualSessions: sessions,
        classNames: classNames,
        reminderMinutes: state.minutes,
        horizonDays: 30,
      );

      await _scheduler.syncReminders(reminders);
    } catch (_) {
      // Fail closed gracefully
    }
  }
}

final teachingReminderControllerProvider =
    StateNotifierProvider<TeachingReminderController, TeachingReminderState>((
      ref,
    ) {
      final scheduler = ref.watch(teachingReminderSchedulerProvider);
      return TeachingReminderController(scheduler, ref);
    });
