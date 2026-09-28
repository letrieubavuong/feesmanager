import 'package:intl/intl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sqflite/sqflite.dart';
import '../../../core/database/database_provider.dart';
import '../../classes/domain/class_filter.dart';
import '../../classes/domain/class_service.dart';
import '../../memberships/domain/membership_service.dart';
import '../../payments/domain/payment_service.dart';
import '../../sessions/domain/class_session.dart';
import '../../sessions/domain/session_service.dart';
import '../../students/domain/student_service.dart';
import '../../tuition/data/tuition_policy_repository.dart';
import '../../tuition/data/tuition_repository.dart';
import '../../tuition/domain/tuition_policy_service.dart';
import '../../tuition/domain/tuition_service.dart';

import 'dashboard_overview.dart';

part 'dashboard_service.g.dart';

class DashboardService {
  final SessionService _sessionService;
  final ClassService _classService;
  final StudentService _studentService;
  final MembershipService _membershipService;
  final TuitionRepository _tuitionRepo;
  final TuitionPolicyRepository _tuitionPolicyRepo;
  final PaymentService _paymentService;
  final Database _db;

  DashboardService(
    this._sessionService,
    this._classService,
    this._studentService,
    this._membershipService,
    this._tuitionRepo,
    this._tuitionPolicyRepo,
    this._paymentService,
    this._db,
  );

  Future<DashboardOverview> getOverview({DateTime? targetDate}) async {
    final now = targetDate ?? DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    final monthStr = DateFormat('yyyy-MM').format(now);
    final currentTimeStr = DateFormat('HH:mm').format(now);

    // 1. Fetch Today Sessions
    final rawTodaySessions = await _sessionService.getSessionsInDateRange(
      fromDate: todayStr,
      toDate: todayStr,
    );

    // Filter teaching sessions for KPI (CHINH, HOC_BU, PHAT_SINH, excluding HUY & NGHI_LE)
    final teachingSessionsToday = rawTodaySessions.where((s) {
      return s.trangThai != SessionStatus.HUY &&
          s.trangThai != SessionStatus.NGHI_LE;
    }).toList();

    final todaySessionCount = teachingSessionsToday.length;

    final pendingAttendanceSessions = teachingSessionsToday.where((s) {
      return s.trangThai == SessionStatus.DU_KIEN;
    }).toList();
    final pendingAttendanceCount = pendingAttendanceSessions.length;

    // Sort all today's sessions by start time ASC then id ASC for schedule list
    final sortedTodaySessions = List<ClassSession>.from(rawTodaySessions)
      ..sort((a, b) {
        final cmp = a.gioBatDau.compareTo(b.gioBatDau);
        if (cmp != 0) return cmp;
        return (a.id ?? 0).compareTo(b.id ?? 0);
      });

    // Batch resolve class names for today's sessions (NO N+1)
    final classIdsToday = sortedTodaySessions
        .map((s) => s.idLop)
        .toSet()
        .toList();
    final classEntitiesToday = await _classService.getClassesByIds(
      classIdsToday,
    );
    final classMap = {for (var c in classEntitiesToday) c.id!: c};

    final todayScheduleItems = sortedTodaySessions.map((s) {
      final cls = classMap[s.idLop];
      return DashboardTodaySession(
        session: s,
        className: cls?.tenLop ?? 'Lớp #${s.idLop}',
      );
    }).toList();

    // 2. Unfinalized Tuition Student-Class Count for Current Month
    final activeClasses = await _classService.getClasses(
      filter: ClassFilter.active,
    );
    final activeClassIds = activeClasses.map((c) => c.id!).toSet();
    final finalizedInvoices = await _tuitionRepo.getInvoicesInMonthRange(
      fromMonth: monthStr,
      toMonth: monthStr,
    );
    final finalizedSet = {
      for (final inv in finalizedInvoices) '${inv.idHocSinh}_${inv.idLop}',
    };

    final monthStart = '$monthStr-01';
    final parsedStart = DateTime.parse(monthStart);
    final monthEndDt = DateTime(parsedStart.year, parsedStart.month + 1, 0);
    final monthEnd = DateFormat('yyyy-MM-dd').format(monthEndDt);

    final monthMemberships = await _membershipService
        .getMembershipsOverlappingDateRange(
          fromDate: monthStart,
          toDate: monthEnd,
        );

    int unfinalizedCount = 0;
    for (final m in monthMemberships) {
      if (activeClassIds.contains(m.idLop)) {
        final key = '${m.idHocSinh}_${m.idLop}';
        if (!finalizedSet.contains(key)) {
          unfinalizedCount++;
        }
      }
    }

    // 3. Outstanding Debt for Current Month
    int totalOutstandingDebt = 0;
    if (finalizedInvoices.isNotEmpty) {
      final summaries = await _paymentService.getPaymentSummariesForInvoices(
        finalizedInvoices,
      );
      for (final s in summaries) {
        if (s.remainingDebt > 0) {
          totalOutstandingDebt += s.remainingDebt;
        }
      }
    }

    // 4. Tasks (Việc cần làm)
    final firstPendingClass = pendingAttendanceSessions.isNotEmpty
        ? classMap[pendingAttendanceSessions.first.idLop]?.tenLop
        : null;

    final tasks = <DashboardTask>[
      DashboardTask(
        type: DashboardTaskType.attendanceNow,
        title: 'Điểm danh ngay',
        subtitle: pendingAttendanceCount == 0
            ? 'Không có buổi cần điểm danh'
            : pendingAttendanceCount == 1
            ? '${firstPendingClass != null ? "Lớp $firstPendingClass • " : ""}${pendingAttendanceSessions.first.gioBatDau}–${pendingAttendanceSessions.first.gioKetThuc}'
            : '$pendingAttendanceCount buổi cần điểm danh',
        isEnabled: pendingAttendanceCount > 0,
      ),
      DashboardTask(
        type: DashboardTaskType.generateSessions,
        title: 'Sinh buổi học',
        subtitle: 'Tạo buổi từ lịch học định kỳ',
      ),
      DashboardTask(
        type: DashboardTaskType.finalizeTuition,
        title: 'Chốt học phí tháng',
        subtitle: 'Tháng $monthStr • $unfinalizedCount lượt chưa chốt',
      ),
      DashboardTask(
        type: DashboardTaskType.exportReportPdf,
        title: 'Xuất báo cáo PDF',
        subtitle: 'Báo cáo học phí & điểm danh',
      ),
    ];

    // 5. Warnings (Cảnh báo nghiệp vụ)
    final warnings = <DashboardWarning>[];

    // A. Unassigned Students in Scheduled Active Classes
    final unassignedCount = await _queryUnassignedActiveStudentsCount(todayStr);
    if (unassignedCount > 0) {
      warnings.add(
        DashboardWarning(
          type: DashboardWarningType.unassignedStudents,
          title: 'Học sinh chưa phân ca',
          description: '$unassignedCount học sinh chưa phân ca',
          count: unassignedCount,
        ),
      );
    }

    // B. Overdue Attendance Sessions
    final overdueCount = await _queryOverdueSessionsCount(
      todayStr,
      currentTimeStr,
    );
    if (overdueCount > 0) {
      warnings.add(
        DashboardWarning(
          type: DashboardWarningType.overdueAttendance,
          title: 'Buổi học chưa điểm danh',
          description: '$overdueCount buổi đã qua giờ nhưng chưa hoàn tất',
          count: overdueCount,
        ),
      );
    }

    // C. Missing Tuition Policy for Active Classes in Current Month
    final missingPolicyCount = await _queryMissingTuitionPolicyCount(
      activeClasses,
      todayStr,
    );
    if (missingPolicyCount > 0) {
      warnings.add(
        DashboardWarning(
          type: DashboardWarningType.missingTuitionPolicy,
          title: 'Thiếu chính sách học phí',
          description:
              '$missingPolicyCount lớp chưa thiết lập học phí tháng này',
          count: missingPolicyCount,
        ),
      );
    }

    // 6. Recent Activity
    final recentActivities = await _fetchRecentActivities(limit: 5);

    return DashboardOverview(
      generatedAt: now,
      todaySessionCount: todaySessionCount,
      pendingAttendanceCount: pendingAttendanceCount,
      unfinalizedTuitionStudentCount: unfinalizedCount,
      outstandingDebt: totalOutstandingDebt,
      todaySessions: todayScheduleItems,
      tasks: tasks,
      warnings: warnings,
      recentActivities: recentActivities,
    );
  }

  Future<int> _queryUnassignedActiveStudentsCount(String todayStr) async {
    const sql = '''
      SELECT COUNT(DISTINCT t.id_hoc_sinh) as cnt
      FROM tham_gia_lop t
      JOIN lop l ON t.id_lop = l.id
      JOIN lich_hoc lh ON lh.id_lop = l.id
      LEFT JOIN phan_ca_hoc_sinh pc ON pc.id_hoc_sinh = t.id_hoc_sinh 
        AND pc.id_lop = t.id_lop 
        AND pc.tu_ngay <= ? 
        AND (pc.den_ngay IS NULL OR pc.den_ngay >= ?)
      WHERE l.da_luu_tru = 0
        AND t.tu_ngay <= ?
        AND (t.den_ngay IS NULL OR t.den_ngay >= ?)
        AND lh.hieu_luc_tu <= ?
        AND (lh.hieu_luc_den IS NULL OR lh.hieu_luc_den >= ?)
        AND pc.id IS NULL
    ''';
    final res = await _db.rawQuery(sql, [
      todayStr,
      todayStr,
      todayStr,
      todayStr,
      todayStr,
      todayStr,
    ]);
    return Sqflite.firstIntValue(res) ?? 0;
  }

  Future<int> _queryOverdueSessionsCount(
    String todayStr,
    String currentTimeStr,
  ) async {
    const sql = '''
      SELECT COUNT(*)
      FROM buoi_hoc
      WHERE trang_thai = 'DU_KIEN'
        AND (
          ngay < ? OR (ngay = ? AND gio_ket_thuc < ?)
        )
    ''';
    final res = await _db.rawQuery(sql, [todayStr, todayStr, currentTimeStr]);
    return Sqflite.firstIntValue(res) ?? 0;
  }

  Future<int> _queryMissingTuitionPolicyCount(
    List<dynamic> activeClasses,
    String todayStr,
  ) async {
    final activeIds = activeClasses
        .map((c) => c.id as int?)
        .whereType<int>()
        .toList();
    if (activeIds.isEmpty) return 0;
    final monthStartStr = '${todayStr.substring(0, 7)}-01';
    final setWithPolicy = await _tuitionPolicyRepo
        .getClassIdsWithEffectivePolicyOnDate(activeIds, monthStartStr);
    return activeIds.where((id) => !setWithPolicy.contains(id)).length;
  }

  Future<List<DashboardActivity>> _fetchRecentActivities({
    int limit = 5,
  }) async {
    final activities = <DashboardActivity>[];

    final paymentRows = await _db.query(
      'thanh_toan',
      orderBy: 'created_at DESC',
      limit: limit,
    );
    final completedSessionRows = await _db.query(
      'buoi_hoc',
      where: "trang_thai = 'DA_HOC'",
      orderBy: 'updated_at DESC',
      limit: limit,
    );
    final finalizedInvoiceRows = await _db.query(
      'hoc_phi_thang',
      where: 'chot_luc IS NOT NULL',
      orderBy: 'chot_luc DESC',
      limit: limit,
    );
    final attendanceCorrRows = await _db.query(
      'diem_danh_chinh_sua',
      orderBy: 'changed_at DESC',
      limit: limit,
    );

    final studentIds = <int>{};
    final classIds = <int>{};

    for (final r in paymentRows) {
      studentIds.add(r['id_hoc_sinh'] as int);
    }
    for (final r in completedSessionRows) {
      classIds.add(r['id_lop'] as int);
    }
    for (final r in finalizedInvoiceRows) {
      classIds.add(r['id_lop'] as int);
    }
    for (final r in attendanceCorrRows) {
      final sId = r['id_hoc_sinh'] as int?;
      if (sId != null) studentIds.add(sId);
    }

    final students = await _studentService.getStudentsByIds(
      studentIds.toList(),
    );
    final classes = await _classService.getClassesByIds(classIds.toList());

    final studentMap = {for (var s in students) s.id!: s.hoTen};
    final classMap = {for (var c in classes) c.id!: c.tenLop};

    final fmt = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    for (final r in paymentRows) {
      final sId = r['id_hoc_sinh'] as int;
      final amount = r['so_tien'] as int;
      final dateStr = r['created_at'] as String?;
      if (dateStr == null) continue;
      final dt = DateTime.tryParse(dateStr);
      if (dt == null) continue;
      final sName = studentMap[sId] ?? 'Học sinh #$sId';

      activities.add(
        DashboardActivity(
          type: DashboardActivityType.paymentRecorded,
          title: 'Đã thu ${fmt.format(amount)}',
          subtitle: 'Phụ huynh/Học sinh: $sName',
          timestamp: dt,
        ),
      );
    }

    for (final r in completedSessionRows) {
      final cId = r['id_lop'] as int;
      final dateStr = r['updated_at'] as String?;
      final sessionDate = r['ngay'] as String? ?? '';
      if (dateStr == null) continue;
      final dt = DateTime.tryParse(dateStr);
      if (dt == null) continue;
      final cName = classMap[cId] ?? 'Lớp #$cId';

      activities.add(
        DashboardActivity(
          type: DashboardActivityType.sessionCompleted,
          title: 'Điểm danh hoàn tất',
          subtitle: '$cName ($sessionDate)',
          timestamp: dt,
        ),
      );
    }

    for (final r in finalizedInvoiceRows) {
      final cId = r['id_lop'] as int;
      final month = r['thang'] as String;
      final dateStr = r['chot_luc'] as String?;
      if (dateStr == null) continue;
      final dt = DateTime.tryParse(dateStr);
      if (dt == null) continue;
      final cName = classMap[cId] ?? 'Lớp #$cId';

      activities.add(
        DashboardActivity(
          type: DashboardActivityType.tuitionFinalized,
          title: 'Đã chốt học phí',
          subtitle: '$cName (Tháng $month)',
          timestamp: dt,
        ),
      );
    }

    for (final r in attendanceCorrRows) {
      final dateStr = r['changed_at'] as String?;
      if (dateStr == null) continue;
      final dt = DateTime.tryParse(dateStr);
      if (dt == null) continue;

      activities.add(
        DashboardActivity(
          type: DashboardActivityType.attendanceCorrection,
          title: 'Chỉnh sửa điểm danh',
          subtitle: r['ly_do'] as String? ?? 'Ghi nhận điều chỉnh',
          timestamp: dt,
        ),
      );
    }

    activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return activities.take(limit).toList();
  }
}

@Riverpod(keepAlive: true)
Future<DashboardService> dashboardService(DashboardServiceRef ref) async {
  final sessionService = await ref.watch(sessionServiceProvider.future);
  final classService = await ref.watch(classServiceProvider.future);
  final studentService = await ref.watch(studentServiceProvider.future);
  final membershipService = await ref.watch(membershipServiceProvider.future);
  final tuitionRepo = await ref.watch(tuitionRepositoryProvider.future);
  final tuitionPolicyRepo = await ref.watch(
    tuitionPolicyRepositoryProvider.future,
  );
  final paymentService = await ref.watch(paymentServiceProvider.future);
  final db = await ref.watch(databaseProvider.future);

  return DashboardService(
    sessionService,
    classService,
    studentService,
    membershipService,
    tuitionRepo,
    tuitionPolicyRepo,
    paymentService,
    db,
  );
}
