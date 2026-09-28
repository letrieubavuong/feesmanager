import 'package:intl/intl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sqflite/sqflite.dart';
import '../../../core/database/database_provider.dart';
import '../../attendance/domain/attendance_record.dart';
import '../../classes/domain/class.dart';
import '../../memberships/domain/membership.dart';
import '../../payments/domain/payment.dart';
import '../../schedule_conflicts/data/schedule_constraint_repository.dart';
import '../../sessions/domain/class_session.dart';
import '../../students/domain/student_service.dart';
import 'student_detail_overview.dart';

part 'student_detail_overview_service.g.dart';

class StudentDetailOverviewService {
  final Database _db;
  final StudentService _studentService;

  StudentDetailOverviewService(
    this._db,
    this._studentService,
  );

  Future<StudentDetailOverview> getOverview(
    int studentId, {
    DateTime? targetDate,
  }) async {
    final now = targetDate ?? DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    final monthStr = DateFormat('yyyy-MM').format(now);

    // 1. Fetch Student
    final student = await _studentService.getStudentById(studentId);
    if (student == null) {
      throw Exception('Không tìm thấy học sinh ID $studentId');
    }

    // 2. Earliest membership date ("Tham gia từ")
    final firstDateRes = await _db.rawQuery(
      'SELECT MIN(tu_ngay) as min_date FROM tham_gia_lop WHERE id_hoc_sinh = ?',
      [studentId],
    );
    DateTime? firstActiveMembershipDate;
    if (firstDateRes.isNotEmpty && firstDateRes.first['min_date'] != null) {
      final minStr = firstDateRes.first['min_date'] as String;
      firstActiveMembershipDate = DateTime.tryParse(minStr);
    }

    // 3. Active Classes TODAY & Shifts
    final activeMemRows = await _db.rawQuery(
      '''
      SELECT t.*, l.id as lop_id, l.ten_lop, l.da_luu_tru 
      FROM tham_gia_lop t 
      JOIN lop l ON t.id_lop = l.id 
      WHERE t.id_hoc_sinh = ? 
        AND l.da_luu_tru = 0 
        AND t.tu_ngay <= ? 
        AND (t.den_ngay IS NULL OR t.den_ngay >= ?)
      ORDER BY l.ten_lop ASC
      ''',
      [studentId, todayStr, todayStr],
    );

    final List<StudentActiveClassSummary> activeClasses = [];

    for (final row in activeMemRows) {
      final classId = row['id_lop'] as int;
      final classEntity = ClassEntity.fromMap(row);
      final membership = ClassMembership.fromMap(row);

      // Query active shift assignments for this student & class today
      final shiftRows = await _db.rawQuery(
        '''
        SELECT pc.*, lh.thu_trong_tuan, lh.gio_bat_dau, lh.gio_ket_thuc 
        FROM phan_ca_hoc_sinh pc 
        JOIN lich_hoc lh ON pc.id_lich_hoc = lh.id 
        WHERE pc.id_hoc_sinh = ? 
          AND pc.id_lop = ? 
          AND pc.tu_ngay <= ? 
          AND (pc.den_ngay IS NULL OR pc.den_ngay >= ?)
        ''',
        [studentId, classId, todayStr, todayStr],
      );

      String shiftText = '';
      if (shiftRows.length > 1) {
        shiftText = '${shiftRows.length} ca đang áp dụng';
      } else if (shiftRows.length == 1) {
        final r = shiftRows.first;
        final thu = r['thu_trong_tuan'] as int?;
        final gbd = r['gio_bat_dau'] as String?;
        final gkt = r['gio_ket_thuc'] as String?;
        final thuStr = _formatWeekday(thu);
        if (gbd != null && gkt != null) {
          shiftText = '$gbd–$gkt${thuStr.isNotEmpty ? ' • $thuStr' : ''}';
        }
      } else {
        // Check effective schedules for class
        final scheduleRows = await _db.rawQuery(
          '''
          SELECT * FROM lich_hoc 
          WHERE id_lop = ? 
            AND hieu_luc_tu <= ? 
            AND (hieu_luc_den IS NULL OR hieu_luc_den >= ?)
          ORDER BY thu_trong_tuan ASC
          ''',
          [classId, todayStr, todayStr],
        );

        if (scheduleRows.isNotEmpty) {
          final weekdays = scheduleRows
              .map((s) => _formatWeekday(s['thu_trong_tuan'] as int?))
              .where((w) => w.isNotEmpty)
              .toSet()
              .join(',');
          final firstSched = scheduleRows.first;
          final gbd = firstSched['gio_bat_dau'] as String?;
          final gkt = firstSched['gio_ket_thuc'] as String?;
          if (gbd != null && gkt != null) {
            shiftText = '$gbd–$gkt${weekdays.isNotEmpty ? ' • $weekdays' : ''}';
          }
        }
      }

      activeClasses.add(
        StudentActiveClassSummary(
          classEntity: classEntity,
          membership: membership,
          shiftText: shiftText,
        ),
      );
    }

    // 4. Current-Month Financial Summary
    final invoiceRows = await _db.rawQuery(
      '''
      SELECT * FROM hoc_phi_thang 
      WHERE id_hoc_sinh = ? AND thang = ? AND chot_luc IS NOT NULL
      ''',
      [studentId, monthStr],
    );

    int finalizedDue = 0;
    for (final invRow in invoiceRows) {
      final val = invRow['so_tien_phai_thu'];
      if (val is num) {
        finalizedDue += val.toInt();
      }
    }

    final paymentRows = await _db.rawQuery(
      '''
      SELECT * FROM thanh_toan 
      WHERE id_hoc_sinh = ? AND strftime('%Y-%m', ngay_thu) = ?
      ''',
      [studentId, monthStr],
    );

    int totalPaid = 0;
    for (final pRow in paymentRows) {
      final val = pRow['so_tien'];
      if (val is num) {
        totalPaid += val.toInt();
      }
    }

    final remainingDebt = (finalizedDue - totalPaid) > 0
        ? (finalizedDue - totalPaid)
        : 0;

    // Check unfinalized classes for current month
    final unfinalizedRows = await _db.rawQuery(
      '''
      SELECT COUNT(DISTINCT t.id_lop) as cnt
      FROM tham_gia_lop t
      JOIN lop l ON t.id_lop = l.id
      LEFT JOIN hoc_phi_thang h ON h.id_hoc_sinh = t.id_hoc_sinh AND h.id_lop = t.id_lop AND h.thang = ? AND h.chot_luc IS NOT NULL
      WHERE t.id_hoc_sinh = ?
        AND l.da_luu_tru = 0
        AND strftime('%Y-%m', t.tu_ngay) <= ?
        AND (t.den_ngay IS NULL OR strftime('%Y-%m', t.den_ngay) >= ?)
        AND h.id IS NULL
      ''',
      [monthStr, studentId, monthStr, monthStr],
    );

    final unfinalizedCount = Sqflite.firstIntValue(unfinalizedRows) ?? 0;

    StudentFinancialDisplayState finState;
    if (invoiceRows.isEmpty) {
      finState = StudentFinancialDisplayState.noFinalizedInvoices;
    } else if (totalPaid == 0 && remainingDebt > 0) {
      finState = StudentFinancialDisplayState.unpaid;
    } else if (totalPaid > 0 && remainingDebt > 0) {
      finState = StudentFinancialDisplayState.partiallyPaid;
    } else if (remainingDebt == 0 && finalizedDue > 0) {
      finState = StudentFinancialDisplayState.fullyPaid;
    } else {
      finState = StudentFinancialDisplayState.hasUnfinalizedClasses;
    }

    // Latest Payment (ever)
    final latestPaymentRows = await _db.rawQuery(
      '''
      SELECT * FROM thanh_toan 
      WHERE id_hoc_sinh = ? 
      ORDER BY ngay_thu DESC, created_at DESC 
      LIMIT 1
      ''',
      [studentId],
    );

    Payment? latestPayment;
    if (latestPaymentRows.isNotEmpty) {
      latestPayment = Payment.fromMap(latestPaymentRows.first);
    }

    final financial = StudentMonthFinancialSummary(
      month: monthStr,
      finalizedDue: finalizedDue,
      totalPaid: totalPaid,
      remainingDebt: remainingDebt,
      finalizedInvoiceCount: invoiceRows.length,
      unfinalizedClassCount: unfinalizedCount,
      previewUnfinalizedAmount: 0,
      state: finState,
      latestPayment: latestPayment,
    );

    // 5. Recent Attendance (Latest 3)
    final attRows = await _db.rawQuery(
      '''
      SELECT d.*, b.id as buoi_id, b.id_lop, b.ngay, b.gio_bat_dau, b.gio_ket_thuc, b.trang_thai as buoi_trang_thai, l.ten_lop, l.da_luu_tru
      FROM diem_danh d 
      JOIN buoi_hoc b ON d.id_buoi_hoc = b.id 
      JOIN lop l ON b.id_lop = l.id 
      WHERE d.id_hoc_sinh = ? 
      ORDER BY b.ngay DESC, b.gio_bat_dau DESC 
      LIMIT 3
      ''',
      [studentId],
    );

    final List<StudentRecentAttendanceItem> recentAttendance = [];
    for (final row in attRows) {
      final attMap = {
        'id': row['id'],
        'id_buoi_hoc': row['id_buoi_hoc'],
        'id_hoc_sinh': row['id_hoc_sinh'],
        'id_lop_goc': row['id_lop_goc'] ?? row['id_lop'],
        'trang_thai': row['trang_thai'],
        'loai_tham_gia': row['loai_tham_gia'] ?? 'CHINH',
        'id_buoi_vang_goc': row['id_buoi_vang_goc'],
        'ghi_chu': row['ghi_chu'],
        'created_at': row['created_at'] ?? DateTime.now().toIso8601String(),
        'updated_at': row['updated_at'] ?? DateTime.now().toIso8601String(),
      };
      final attendance = AttendanceRecord.fromMap(attMap);
      final sessionMap = {
        'id': row['buoi_id'],
        'id_lop': row['id_lop'],
        'ngay': row['ngay'],
        'gio_bat_dau': row['gio_bat_dau'],
        'gio_ket_thuc': row['gio_ket_thuc'],
        'trang_thai': row['buoi_trang_thai'],
      };
      final session = ClassSession.fromMap(sessionMap);
      final classEntity = ClassEntity.fromMap({
        'id': row['id_lop'],
        'ten_lop': row['ten_lop'],
        'da_luu_tru': row['da_luu_tru'] ?? 0,
      });

      recentAttendance.add(
        StudentRecentAttendanceItem(
          attendance: attendance,
          session: session,
          classEntity: classEntity,
        ),
      );
    }

    // 6. Active Busy Times (ScheduleConstraints)
    final constraintRepo = ScheduleConstraintRepository(_db);
    final activeBusyTimes = await constraintRepo.getActiveForStudent(studentId);

    return StudentDetailOverview(
      student: student,
      activeClasses: activeClasses,
      firstActiveMembershipDate: firstActiveMembershipDate,
      financial: financial,
      recentAttendance: recentAttendance,
      activeBusyTimes: activeBusyTimes,
    );
  }

  String _formatWeekday(int? thu) {
    switch (thu) {
      case 1:
        return 'Thứ 2';
      case 2:
        return 'Thứ 3';
      case 3:
        return 'Thứ 4';
      case 4:
        return 'Thứ 5';
      case 5:
        return 'Thứ 6';
      case 6:
        return 'Thứ 7';
      case 7:
        return 'Chủ Nhật';
      default:
        return '';
    }
  }
}

@riverpod
Future<StudentDetailOverviewService> studentDetailOverviewService(
  StudentDetailOverviewServiceRef ref,
) async {
  final db = await ref.watch(databaseProvider.future);
  final studentService = await ref.watch(studentServiceProvider.future);
  return StudentDetailOverviewService(db, studentService);
}

@riverpod
Future<StudentDetailOverview> studentDetailOverview(
  StudentDetailOverviewRef ref,
  int studentId,
) async {
  final service = await ref.watch(studentDetailOverviewServiceProvider.future);
  return service.getOverview(studentId);
}
