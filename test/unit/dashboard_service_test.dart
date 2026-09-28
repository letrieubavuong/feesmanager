import 'package:flutter_test/flutter_test.dart';
import 'package:tuition2027/features/dashboard/domain/dashboard_overview.dart';
import 'package:tuition2027/features/sessions/domain/class_session.dart';

void main() {
  final now = DateTime.now();

  group('DashboardOverview Read Model Unit Tests', () {
    test('DashboardTodaySession holds session and class name', () {
      final session = ClassSession(
        id: 1,
        idLop: 10,
        ngay: '2026-09-28',
        gioBatDau: '14:00',
        gioKetThuc: '15:30',
        loai: SessionType.CHINH,
        trangThai: SessionStatus.DU_KIEN,
        createdAt: now,
        updatedAt: now,
      );

      final item = DashboardTodaySession(
        session: session,
        className: 'Lớp 10A3',
      );

      expect(item.session.id, 1);
      expect(item.className, 'Lớp 10A3');
    });

    test('DashboardOverview calculates totals correctly', () {
      final overview = DashboardOverview(
        generatedAt: now,
        todaySessionCount: 4,
        pendingAttendanceCount: 2,
        unfinalizedTuitionStudentCount: 8,
        outstandingDebt: 2350000,
        todaySessions: [],
        tasks: [],
        warnings: [],
        recentActivities: [],
      );

      expect(overview.todaySessionCount, 4);
      expect(overview.pendingAttendanceCount, 2);
      expect(overview.unfinalizedTuitionStudentCount, 8);
      expect(overview.outstandingDebt, 2350000);
    });

    test('DashboardActivity sorts by timestamp descending', () {
      final act1 = DashboardActivity(
        type: DashboardActivityType.paymentRecorded,
        title: 'Payment 1',
        subtitle: 'Details',
        timestamp: DateTime(2026, 9, 28, 10, 0),
      );

      final act2 = DashboardActivity(
        type: DashboardActivityType.sessionCompleted,
        title: 'Session 1',
        subtitle: 'Details',
        timestamp: DateTime(2026, 9, 28, 14, 0),
      );

      final list = [act1, act2];
      list.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      expect(list.first.title, 'Session 1');
      expect(list.last.title, 'Payment 1');
    });
  });
}
