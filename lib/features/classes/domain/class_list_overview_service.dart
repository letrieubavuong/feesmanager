import 'package:intl/intl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sqflite/sqflite.dart';
import '../../../core/database/database_provider.dart';
import '../../schedule/domain/class_schedule.dart';
import '../../sessions/domain/class_session.dart';
import 'class.dart';
import 'class_filter.dart';
import 'class_list_overview.dart';

part 'class_list_overview_service.g.dart';

class ClassListOverviewService {
  final Database _db;

  ClassListOverviewService(this._db);

  Future<ClassListOverview> getOverview(
    ClassFilter filter, {
    DateTime? targetDate,
  }) async {
    final now = targetDate ?? DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    final currentMonthStr = DateFormat('yyyy-MM').format(now);
    final currentTimeStr = DateFormat('HH:mm').format(now);

    // 1. Fetch Classes based on filter
    final List<Map<String, dynamic>> classMaps;
    if (filter == ClassFilter.archived) {
      classMaps = await _db.query(
        'lop',
        where: 'da_luu_tru = 1',
        orderBy: 'ten_lop ASC',
      );
    } else {
      // Active mode by default
      classMaps = await _db.query(
        'lop',
        where: 'da_luu_tru = 0',
        orderBy: 'ten_lop ASC',
      );
    }

    final classes = classMaps.map((m) => ClassEntity.fromMap(m)).toList();

    // Global active class count (always count da_luu_tru == 0)
    final activeCountResult = await _db.rawQuery(
      'SELECT COUNT(*) as count FROM lop WHERE da_luu_tru = 0',
    );
    final globalActiveClassCount =
        Sqflite.firstIntValue(activeCountResult) ?? 0;

    // 2. Batch Active Student Counts per Class
    final studentCountMaps = await _db.rawQuery(
      '''
      SELECT id_lop, COUNT(*) as active_count
      FROM tham_gia_lop
      WHERE tu_ngay <= ? AND (den_ngay IS NULL OR den_ngay >= ?)
      GROUP BY id_lop
      ''',
      [todayStr, todayStr],
    );

    final activeStudentCounts = <int, int>{};
    for (final row in studentCountMaps) {
      final idLop = row['id_lop'] as int;
      final count = row['active_count'] as int;
      activeStudentCounts[idLop] = count;
    }

    // 3. Batch Schedules per Class
    final scheduleMaps = await _db.query(
      'lich_hoc',
      orderBy: 'id_lop, thu_trong_tuan, gio_bat_dau',
    );

    final schedulesByClass = <int, List<ClassSchedule>>{};
    for (final map in scheduleMaps) {
      final s = ClassSchedule.fromMap(map);
      schedulesByClass.putIfAbsent(s.idLop, () => []).add(s);
    }

    // 4. Today Sessions
    final todaySessionMaps = await _db.rawQuery(
      '''
      SELECT * FROM buoi_hoc
      WHERE ngay = ? AND trang_thai NOT IN ('HUY', 'NGHI_LE')
      ORDER BY gio_bat_dau ASC
      ''',
      [todayStr],
    );

    final todaySessions =
        todaySessionMaps.map((m) => ClassSession.fromMap(m)).toList();

    final todaySessionsByClass = <int, List<ClassSession>>{};
    for (final s in todaySessions) {
      todaySessionsByClass.putIfAbsent(s.idLop, () => []).add(s);
    }

    // Today teaching session count (all non-cancelled sessions today across active classes)
    final todaySessionCount = todaySessions.length;

    // 5. Overdue / Pending Attendance Sessions
    final pendingSessionMaps = await _db.rawQuery(
      '''
      SELECT * FROM buoi_hoc
      WHERE (ngay = ? AND trang_thai = 'DU_KIEN') OR (ngay < ? AND trang_thai = 'DU_KIEN')
      ORDER BY ngay DESC, gio_bat_dau DESC
      ''',
      [todayStr, todayStr],
    );

    final pendingSessions =
        pendingSessionMaps.map((m) => ClassSession.fromMap(m)).toList();

    final overdueAttendanceSessions = <ClassSession>[];
    for (final s in pendingSessions) {
      if (s.ngay.compareTo(todayStr) < 0) {
        overdueAttendanceSessions.add(s);
      } else if (s.ngay == todayStr) {
        if (currentTimeStr.compareTo(s.gioKetThuc) >= 0) {
          overdueAttendanceSessions.add(s);
        }
      }
    }

    final pendingAttendanceCount = overdueAttendanceSessions.length;

    // 6. Effective Tuition Policy Check per Class
    final activePolicyClassMaps = await _db.rawQuery(
      '''
      SELECT DISTINCT id_lop FROM chinh_sach_hoc_phi
      WHERE thang_bat_dau <= ? AND (thang_ket_thuc IS NULL OR thang_ket_thuc >= ?)
      AND (da_luu_tru IS NULL OR da_luu_tru = 0)
      ''',
      [currentMonthStr, currentMonthStr],
    );

    final classesWithActivePolicy =
        activePolicyClassMaps.map((m) => m['id_lop'] as int).toSet();

    int missingTuitionPolicyCount = 0;
    final classesMissingPolicy = <int>[];

    for (final cls in classes) {
      if (!cls.daLuuTru) {
        final memberCount = activeStudentCounts[cls.id!] ?? 0;
        if (memberCount > 0 && !classesWithActivePolicy.contains(cls.id!)) {
          missingTuitionPolicyCount++;
          classesMissingPolicy.add(cls.id!);
        }
      }
    }

    // 7. Current Month Finalized Debt per Class
    final debtMaps = await _db.rawQuery(
      '''
      SELECT h.id_lop, (COALESCE(SUM(h.so_tien_phai_thu), 0) - COALESCE(SUM(p.so_tien), 0)) as debt
      FROM hoc_phi_thang h
      LEFT JOIN thanh_toan p ON h.id = p.id_hoa_don
      WHERE h.thang = ? AND h.trang_thai_chot = 1
      GROUP BY h.id_lop
      ''',
      [currentMonthStr],
    );

    final classDebtMap = <int, int>{};
    for (final row in debtMaps) {
      final idLop = row['id_lop'] as int;
      final debt = (row['debt'] as num).toInt();
      if (debt > 0) {
        classDebtMap[idLop] = debt;
      }
    }

    // 8. Build Rows
    final currencyFmt = NumberFormat('#,###', 'vi_VN');
    final rows = <ClassOperationalRow>[];

    for (final cls in classes) {
      final idLop = cls.id!;
      final activeStudentCount = activeStudentCounts[idLop] ?? 0;
      final classSchedules = schedulesByClass[idLop] ?? const [];
      final scheduleText = _formatScheduleSummary(classSchedules);
      final classTodaySessions = todaySessionsByClass[idLop] ?? const [];
      final debt = classDebtMap[idLop] ?? 0;
      final isMissingPolicy = classesMissingPolicy.contains(idLop);

      ClassOperationalStatus status;
      String secondaryText;
      ClassSession? relevantTodaySession;

      if (cls.daLuuTru) {
        status = ClassOperationalStatus.archived;
        secondaryText = 'Ngừng hoạt động';
      } else {
        // Evaluate today sessions
        final pendingToday = classTodaySessions.where(
          (s) => s.trangThai == SessionStatus.DU_KIEN,
        );
        final completedToday = classTodaySessions.where(
          (s) => s.trangThai == SessionStatus.DA_HOC,
        );

        if (pendingToday.isNotEmpty) {
          final nextSession = pendingToday.first;
          relevantTodaySession = nextSession;

          if (currentTimeStr.compareTo(nextSession.gioKetThuc) >= 0) {
            status = ClassOperationalStatus.needsAttendance;
            secondaryText = 'Hôm nay ${nextSession.gioBatDau} (Quá giờ)';
          } else if (currentTimeStr.compareTo(nextSession.gioBatDau) >= 0 &&
              currentTimeStr.compareTo(nextSession.gioKetThuc) < 0) {
            status = ClassOperationalStatus.inProgress;
            secondaryText = 'Đang diễn ra (${nextSession.gioBatDau}–${nextSession.gioKetThuc})';
          } else {
            status = ClassOperationalStatus.upcomingToday;
            secondaryText = 'Hôm nay ${nextSession.gioBatDau}';
          }
        } else if (completedToday.isNotEmpty) {
          relevantTodaySession = completedToday.last;
          status = ClassOperationalStatus.completedToday;
          secondaryText = 'Buổi gần nhất $todayStr';
        } else if (isMissingPolicy) {
          status = ClassOperationalStatus.missingTuitionPolicy;
          secondaryText = 'Thiếu chính sách tháng $currentMonthStr';
        } else if (debt > 0) {
          status = ClassOperationalStatus.hasDebt;
          secondaryText = 'Còn nợ ${currencyFmt.format(debt)}đ';
        } else {
          status = ClassOperationalStatus.normal;
          secondaryText = scheduleText.isNotEmpty ? scheduleText : 'Bình thường';
        }
      }

      rows.add(
        ClassOperationalRow(
          classEntity: cls,
          activeStudentCount: activeStudentCount,
          scheduleText: scheduleText,
          status: status,
          secondaryStatusText: secondaryText,
          currentMonthDebt: debt,
          missingTuitionPolicy: isMissingPolicy,
          todaySession: relevantTodaySession,
        ),
      );
    }

    // 9. Derive Warnings for Active Mode
    final warnings = <ClassOperationalWarning>[];
    if (filter != ClassFilter.archived) {
      if (pendingAttendanceCount > 0) {
        warnings.add(
          ClassOperationalWarning(
            type: ClassWarningType.overdueAttendance,
            message: '$pendingAttendanceCount buổi quá giờ cần điểm danh',
            count: pendingAttendanceCount,
            relatedIds: overdueAttendanceSessions.map((s) => s.id!).toList(),
          ),
        );
      }

      if (missingTuitionPolicyCount > 0) {
        warnings.add(
          ClassOperationalWarning(
            type: ClassWarningType.missingTuitionPolicy,
            message: '$missingTuitionPolicyCount lớp chưa thiết lập học phí',
            count: missingTuitionPolicyCount,
            relatedIds: classesMissingPolicy,
          ),
        );
      }

      // Check classes missing generated sessions in current week
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 6));
      final startOfWeekStr = DateFormat('yyyy-MM-dd').format(startOfWeek);
      final endOfWeekStr = DateFormat('yyyy-MM-dd').format(endOfWeek);

      final weekSessionClassMaps = await _db.rawQuery(
        '''
        SELECT DISTINCT id_lop FROM buoi_hoc
        WHERE ngay >= ? AND ngay <= ? AND trang_thai NOT IN ('HUY')
        ''',
        [startOfWeekStr, endOfWeekStr],
      );
      final classesWithWeekSessions =
          weekSessionClassMaps.map((m) => m['id_lop'] as int).toSet();

      final classesMissingWeekSessions = <int>[];
      for (final cls in classes) {
        if (!cls.daLuuTru) {
          final hasSchedules = (schedulesByClass[cls.id!] ?? const []).isNotEmpty;
          if (hasSchedules && !classesWithWeekSessions.contains(cls.id!)) {
            classesMissingWeekSessions.add(cls.id!);
          }
        }
      }

      if (classesMissingWeekSessions.isNotEmpty) {
        warnings.add(
          ClassOperationalWarning(
            type: ClassWarningType.missingGeneratedSessions,
            message:
                '${classesMissingWeekSessions.length} lớp chưa sinh buổi tuần này',
            count: classesMissingWeekSessions.length,
            relatedIds: classesMissingWeekSessions,
          ),
        );
      }
    }

    return ClassListOverview(
      filter: filter,
      activeClassCount: globalActiveClassCount,
      todaySessionCount: todaySessionCount,
      pendingAttendanceCount: pendingAttendanceCount,
      missingTuitionPolicyCount: missingTuitionPolicyCount,
      rows: rows,
      warnings: warnings,
    );
  }

  static String _formatScheduleSummary(List<ClassSchedule> schedules) {
    if (schedules.isEmpty) return '';

    // Group by start & end time
    final byTime = <String, List<int>>{};
    for (final s in schedules) {
      final key = '${s.gioBatDau}–${s.gioKetThuc}';
      byTime.putIfAbsent(key, () => []).add(s.thuTrongTuan);
    }

    if (byTime.length == 1) {
      final entry = byTime.entries.first;
      final timeRange = entry.key;
      final weekdays = entry.value..sort();
      final weekdayParts = weekdays.map((w) {
        if (w == 7) return 'CN';
        return (w + 1).toString(); // 1->2 (Thứ 2), 2->3 (Thứ 3), etc.
      }).join(',');
      return 'Thứ $weekdayParts • $timeRange';
    }

    if (byTime.length > 1) {
      return '${schedules.length} ca đang áp dụng';
    }

    return '';
  }
}

@riverpod
Future<ClassListOverviewService> classListOverviewService(
  ClassListOverviewServiceRef ref,
) async {
  final db = await ref.watch(databaseProvider.future);
  return ClassListOverviewService(db);
}

@riverpod
Future<ClassListOverview> classListOverview(
  ClassListOverviewRef ref,
  ClassFilter filter,
) async {
  final service = await ref.watch(classListOverviewServiceProvider.future);
  return service.getOverview(filter);
}
