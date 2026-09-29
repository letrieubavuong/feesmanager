import 'package:flutter_test/flutter_test.dart';
import 'package:tuition2027/features/schedule/domain/class_schedule.dart';
import 'package:tuition2027/features/sessions/domain/class_session.dart';
import 'package:tuition2027/features/settings/domain/teaching_reminder.dart';
import 'package:tuition2027/features/settings/domain/teaching_reminder_planner.dart';

void main() {
  group('TeachingReminderPlanner Tests', () {
    final now = DateTime(2026, 9, 29, 8, 0); // Tuesday 08:00 AM

    final schedules = [
      ClassSchedule(
        id: 1,
        idLop: 10,
        thuTrongTuan: 2, // Tuesday
        gioBatDau: '14:00',
        gioKetThuc: '16:00',
        hieuLucTu: '2026-09-01',
        createdAt: now,
        updatedAt: now,
      ),
      ClassSchedule(
        id: 2,
        idLop: 20,
        thuTrongTuan: 3, // Wednesday
        gioBatDau: '18:00',
        gioKetThuc: '20:00',
        hieuLucTu: '2026-09-01',
        createdAt: now,
        updatedAt: now,
      ),
    ];

    final classNames = {10: 'Toán 9A', 20: 'Lý 10B'};

    test('buildUpcoming returns empty list when reminder is off', () {
      final result = TeachingReminderPlanner.buildUpcoming(
        now: now,
        schedules: schedules,
        actualSessions: const [],
        classNames: classNames,
        reminderMinutes: TeachingReminderMinutes.off,
      );

      expect(result, isEmpty);
    });

    test(
      'buildUpcoming calculates correct 5m reminder times for recurring schedule',
      () {
        final result = TeachingReminderPlanner.buildUpcoming(
          now: now,
          schedules: schedules,
          actualSessions: const [],
          classNames: classNames,
          reminderMinutes: TeachingReminderMinutes.fiveMinutes,
          horizonDays: 7,
        );

        expect(result.isNotEmpty, isTrue);

        // Tuesday Sep 29 14:00 session -> reminder at 13:55
        final firstReminder = result.first;
        expect(firstReminder.classId, equals(10));
        expect(firstReminder.className, equals('Toán 9A'));
        expect(firstReminder.sessionTime, equals(DateTime(2026, 9, 29, 14, 0)));
        expect(
          firstReminder.reminderTime,
          equals(DateTime(2026, 9, 29, 13, 55)),
        );
        expect(firstReminder.title, contains('Toán 9A'));
        expect(firstReminder.body, contains('14:00'));
      },
    );

    test(
      'buildUpcoming overrides recurring schedule when actual session exists',
      () {
        final actualSessions = [
          // Actual session on Tuesday Sep 29 moved from 14:00 to 15:30
          ClassSession(
            id: 101,
            idLop: 10,
            ngay: '2026-09-29',
            gioBatDau: '15:30',
            gioKetThuc: '17:30',
            loai: SessionType.CHINH,
            trangThai: SessionStatus.DU_KIEN,
            createdAt: now,
            updatedAt: now,
          ),
        ];

        final result = TeachingReminderPlanner.buildUpcoming(
          now: now,
          schedules: schedules,
          actualSessions: actualSessions,
          classNames: classNames,
          reminderMinutes: TeachingReminderMinutes.tenMinutes,
          horizonDays: 0,
        );

        expect(result.length, equals(1));
        expect(result.first.sessionTime, equals(DateTime(2026, 9, 29, 15, 30)));
        expect(
          result.first.reminderTime,
          equals(DateTime(2026, 9, 29, 15, 20)),
        );
      },
    );

    test('buildUpcoming skips canceled or holiday actual sessions', () {
      final actualSessions = [
        ClassSession(
          id: 101,
          idLop: 10,
          ngay: '2026-09-29',
          gioBatDau: '14:00',
          gioKetThuc: '16:00',
          loai: SessionType.CHINH,
          trangThai: SessionStatus.HUY, // Canceled!
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final result = TeachingReminderPlanner.buildUpcoming(
        now: now,
        schedules: schedules,
        actualSessions: actualSessions,
        classNames: classNames,
        reminderMinutes: TeachingReminderMinutes.fiveMinutes,
        horizonDays: 1,
      );

      // Class 10 is canceled for Sep 29, so no reminder for Sep 29!
      expect(
        result.where((r) => r.classId == 10 && r.sessionTime.day == 29),
        isEmpty,
      );
    });
  });
}
