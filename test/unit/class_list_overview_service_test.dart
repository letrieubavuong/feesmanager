import 'package:flutter_test/flutter_test.dart';
import 'package:tuition2027/features/classes/domain/class.dart';
import 'package:tuition2027/features/classes/domain/class_filter.dart';
import 'package:tuition2027/features/classes/domain/class_list_overview.dart';
import 'package:tuition2027/features/sessions/domain/class_session.dart';

void main() {
  final now = DateTime.now();

  group('ClassListOverview Read Model Unit Tests', () {
    test('ClassListOverview holds active class count, KPIs & rows', () {
      final classEntity1 = ClassEntity(
        id: 10,
        tenLop: 'Lớp 11A1',
        daLuuTru: false,
        createdAt: now,
        updatedAt: now,
      );

      final classEntity2 = ClassEntity(
        id: 20,
        tenLop: 'Lớp 12A2',
        daLuuTru: false,
        createdAt: now,
        updatedAt: now,
      );

      final row1 = ClassOperationalRow(
        classEntity: classEntity1,
        activeStudentCount: 28,
        scheduleText: 'Thứ 3,5 • 17:30–19:00',
        status: ClassOperationalStatus.needsAttendance,
        secondaryStatusText: 'Hôm nay 17:30',
        currentMonthDebt: 0,
        missingTuitionPolicy: false,
        todaySession: ClassSession(
          id: 1,
          idLop: 10,
          ngay: '2026-09-28',
          gioBatDau: '17:30',
          gioKetThuc: '19:00',
          loai: SessionType.CHINH,
          trangThai: SessionStatus.DU_KIEN,
          createdAt: now,
          updatedAt: now,
        ),
      );

      final row2 = ClassOperationalRow(
        classEntity: classEntity2,
        activeStudentCount: 30,
        scheduleText: 'Thứ 2,6 • 19:30–21:00',
        status: ClassOperationalStatus.completedToday,
        secondaryStatusText: 'Buổi gần nhất 28/09',
        currentMonthDebt: 0,
        missingTuitionPolicy: false,
      );

      final overview = ClassListOverview(
        filter: ClassFilter.active,
        activeClassCount: 12,
        todaySessionCount: 5,
        pendingAttendanceCount: 3,
        missingTuitionPolicyCount: 2,
        rows: [row1, row2],
        warnings: const [
          ClassOperationalWarning(
            type: ClassWarningType.overdueAttendance,
            message: '3 buổi quá giờ cần điểm danh',
            count: 3,
          ),
          ClassOperationalWarning(
            type: ClassWarningType.missingTuitionPolicy,
            message: '2 lớp chưa thiết lập học phí',
            count: 2,
          ),
        ],
      );

      expect(overview.activeClassCount, equals(12));
      expect(overview.todaySessionCount, equals(5));
      expect(overview.pendingAttendanceCount, equals(3));
      expect(overview.missingTuitionPolicyCount, equals(2));
      expect(overview.rows.length, equals(2));
      expect(overview.rows[0].classEntity.tenLop, equals('Lớp 11A1'));
      expect(overview.rows[0].activeStudentCount, equals(28));
      expect(
        overview.rows[0].status,
        equals(ClassOperationalStatus.needsAttendance),
      );
      expect(overview.warnings.length, equals(2));
    });
  });
}
