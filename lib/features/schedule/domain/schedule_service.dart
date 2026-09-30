import 'package:sqflite/sqflite.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:intl/intl.dart';

import '../../../core/database/database_provider.dart';
import '../../../core/utils/date_and_time_validators.dart';
import '../data/schedule_repository.dart';
import '../data/assignment_repository.dart';
import 'bulk_assignment_result.dart';
import 'class_schedule.dart';
import 'schedule_change_plan.dart';
import 'student_shift_assignment.dart';
import '../../memberships/domain/membership_service.dart';
import '../../students/domain/student_service.dart';
import '../../students/domain/student.dart';
import '../../classes/domain/class_service.dart';
import '../../schedule_conflicts/domain/schedule_conflict_result.dart';
import '../../schedule_conflicts/domain/schedule_conflict_service.dart';
import '../../schedule_conflicts/presentation/schedule_conflict_providers.dart';

part 'schedule_service.g.dart';

@Riverpod(keepAlive: true)
Future<ScheduleRepository> scheduleRepository(ScheduleRepositoryRef ref) async {
  final db = await ref.watch(databaseProvider.future);
  return ScheduleRepository(db);
}

@Riverpod(keepAlive: true)
Future<AssignmentRepository> assignmentRepository(
  AssignmentRepositoryRef ref,
) async {
  final db = await ref.watch(databaseProvider.future);
  return AssignmentRepository(db);
}

class ScheduleDomainService {
  final ScheduleRepository _scheduleRepo;
  final AssignmentRepository _assignmentRepo;
  final MembershipService _membershipService;
  final ClassService _classService;
  final StudentService _studentService;
  final ScheduleConflictService _conflictService;

  ScheduleDomainService(
    this._scheduleRepo,
    this._assignmentRepo,
    this._membershipService,
    this._classService,
    this._studentService,
    this._conflictService,
  );

  // --- Schedule Management ---

  Future<ClassSchedule> createSchedule(ClassSchedule schedule) async {
    final cls = await _classService.getClassById(schedule.idLop);
    if (cls == null) throw Exception('Không tìm thấy lớp học');
    if (cls.daLuuTru) {
      throw Exception('Không thể tạo lịch học cho lớp đã lưu trữ');
    }

    _validateSchedule(schedule);

    final id = await _scheduleRepo.create(schedule);
    final created = schedule.copyWith(id: id);

    final db = _scheduleRepo.db;
    final fromDt = DateTime.parse(schedule.hieuLucTu);
    final toDt = schedule.hieuLucDen != null
        ? DateTime.parse(schedule.hieuLucDen!)
        : DateTime(fromDt.year, fromDt.month + 3, 1);

    await db.transaction((txn) async {
      await _generateSessionsInTxn(
        txn,
        classId: schedule.idLop,
        fromDate: fromDt,
        toDate: toDt,
      );
    });

    return created;
  }

  Future<void> closeSchedule(int scheduleId, DateTime endDate) async {
    final existing = await _scheduleRepo.getById(scheduleId);
    if (existing == null) throw Exception('Không tìm thấy lịch học');

    final dateFormat = DateFormat('yyyy-MM-dd');
    final endStr = dateFormat.format(endDate);

    if (endStr.compareTo(existing.hieuLucTu) < 0) {
      throw Exception(
        'Ngày kết thúc hiệu lực không được trước ngày bắt đầu (${existing.hieuLucTu})',
      );
    }

    if (existing.hieuLucDen != null) {
      if (endStr == existing.hieuLucDen) return; // Idempotent
      throw Exception(
        'Không thể đóng lịch học đã kết thúc (${existing.hieuLucDen})',
      );
    }

    final assignments = await _assignmentRepo.getBySchedule(scheduleId);
    for (final a in assignments) {
      if (a.denNgay == null || a.denNgay!.compareTo(endStr) > 0) {
        throw Exception(
          'Phân ca học sinh vượt quá ngày kết thúc hiệu lực của lịch học ($endStr)',
        );
      }
    }

    final db = _scheduleRepo.db;
    await db.transaction((txn) async {
      await _scheduleRepo.updateInTxn(
        txn,
        existing.copyWith(hieuLucDen: endStr, updatedAt: DateTime.now()),
      );

      // Clean up future un-attended DU_KIEN sessions past endStr
      await txn.delete(
        'buoi_hoc',
        where: 'id_lich_hoc = ? AND ngay > ? AND trang_thai = ?',
        whereArgs: [scheduleId, endStr, 'DU_KIEN'],
      );
    });
  }

  Future<ScheduleChangePlan> previewScheduleChange({
    required int scheduleId,
    required int newWeekday,
    required String newStart,
    required String newEnd,
    required String newEffectiveFrom,
    String? newEffectiveTo,
  }) async {
    final existing = await _scheduleRepo.getById(scheduleId);
    if (existing == null) throw Exception('Không tìm thấy lịch học');

    DateAndTimeValidators.validateTimeOrder(
      newStart,
      newEnd,
      'newStart',
      'newEnd',
    );
    DateAndTimeValidators.validateDateRange(
      newEffectiveFrom,
      newEffectiveTo,
      'newEffectiveFrom',
      'newEffectiveTo',
    );
    if (newWeekday < 1 || newWeekday > 7) {
      throw Exception('Thứ trong tuần không hợp lệ (1-7)');
    }

    final db = _scheduleRepo.db;

    final sessions = await db.query(
      'buoi_hoc',
      where: 'id_lich_hoc = ?',
      whereArgs: [scheduleId],
    );

    final protectedSessions = <String>[];
    final conflicts = <String>[];
    bool hasHistory = false;
    bool hasHardConflict = false;

    for (final sMap in sessions) {
      final sessionId = sMap['id'] as int;
      final sessionDate = sMap['ngay'] as String;
      final sessionStatus = sMap['trang_thai'] as String;

      final attendanceCount = Sqflite.firstIntValue(
        await db.rawQuery(
          'SELECT COUNT(*) FROM diem_danh WHERE id_buoi_hoc = ?',
          [sessionId],
        ),
      ) ?? 0;

      final adjustmentCount = Sqflite.firstIntValue(
        await db.rawQuery(
          'SELECT COUNT(*) FROM dieu_chinh_buoi_hoc WHERE id_buoi_hoc_goc = ? OR id_buoi_hoc_tham_gia = ?',
          [sessionId, sessionId],
        ),
      ) ?? 0;

      if (sessionStatus != 'DU_KIEN' || attendanceCount > 0 || adjustmentCount > 0) {
        hasHistory = true;
        protectedSessions.add(
          'Buổi $sessionDate (${sessionStatus == 'DU_KIEN' ? 'Đã ghi nhận dữ liệu điểm danh/đổi ca' : sessionStatus})',
        );
        if (sessionDate.compareTo(newEffectiveFrom) >= 0) {
          hasHardConflict = true;
          conflicts.add(
            'Không thể thay đổi lịch học vì có buổi học ngày $sessionDate đã ghi nhận dữ liệu (điểm danh/điều chỉnh).',
          );
        }
      }
    }

    final isDirectEdit = !hasHistory;

    final assignments = await _assignmentRepo.getBySchedule(scheduleId);
    if (!hasHardConflict) {
      for (final a in assignments) {
        final student = await _studentService.getStudentById(a.idHocSinh);
        final studentName = student?.hoTen ?? 'Học sinh #${a.idHocSinh}';

        final effectiveAssignStart =
            newEffectiveFrom.compareTo(a.tuNgay) > 0 ? newEffectiveFrom : a.tuNgay;
        String? effectiveAssignEnd = a.denNgay;
        if (newEffectiveTo != null) {
          if (effectiveAssignEnd == null || effectiveAssignEnd.compareTo(newEffectiveTo) > 0) {
            effectiveAssignEnd = newEffectiveTo;
          }
        }

        if (effectiveAssignEnd != null && effectiveAssignStart.compareTo(effectiveAssignEnd) > 0) {
          conflicts.add(
            '$studentName: Phân ca bị mất hiệu lực do khoảng lịch học mới ($newEffectiveFrom - ${newEffectiveTo ?? "không xác định"}) không giao với phân ca cũ (${a.tuNgay} - ${a.denNgay ?? "không xác định"}).',
          );
          hasHardConflict = true;
          continue;
        }

        final conflictResult = await _conflictService.evaluateCandidateAssignment(
          studentId: a.idHocSinh,
          targetScheduleId: scheduleId,
          startDate: effectiveAssignStart,
          endDate: effectiveAssignEnd,
          excludeAssignmentId: a.id,
          excludeScheduleId: scheduleId,
          studentName: studentName,
        );

        if (conflictResult.hardConflicts.isNotEmpty) {
          hasHardConflict = true;
          for (final hc in conflictResult.hardConflicts) {
            conflicts.add(hc.message);
          }
        }
      }
    }

    final affectedMonths = <String>{};
    final fromDt = DateTime.parse(newEffectiveFrom);
    final toDt = newEffectiveTo != null
        ? DateTime.parse(newEffectiveTo)
        : DateTime(fromDt.year, fromDt.month + 3, 1);
    for (
      var d = fromDt;
      d.isBefore(toDt.add(const Duration(days: 1)));
      d = DateTime(d.year, d.month + 1, 1)
    ) {
      affectedMonths.add(DateFormat('yyyy-MM').format(d));
    }

    final revisionToken = DateTime.now().millisecondsSinceEpoch.toString();

    return ScheduleChangePlan(
      scheduleId: scheduleId,
      newWeekday: newWeekday,
      newStart: newStart,
      newEnd: newEnd,
      effectiveFrom: newEffectiveFrom,
      effectiveTo: newEffectiveTo,
      applyFrom: newEffectiveFrom,
      isDirectEdit: isDirectEdit,
      protectedSessions: protectedSessions,
      conflicts: conflicts,
      hasHardConflict: hasHardConflict,
      affectedAssignmentsCount: assignments.length,
      affectedMonths: affectedMonths.toList(),
      revisionToken: revisionToken,
    );
  }

  Future<void> applyScheduleChange({
    required ScheduleChangePlan plan,
    String? ghiChu,
  }) async {
    if (plan.hasHardConflict) {
      throw Exception(
        'Không thể lưu lịch học do có xung đột cứng:\n${plan.conflicts.join('\n')}',
      );
    }

    final existing = await _scheduleRepo.getById(plan.scheduleId);
    if (existing == null) throw Exception('Không tìm thấy lịch học');

    final assignments = await _assignmentRepo.getBySchedule(plan.scheduleId);
    final db = _scheduleRepo.db;

    await db.transaction((txn) async {
      if (plan.isDirectEdit) {
        final updated = existing.copyWith(
          thuTrongTuan: plan.newWeekday,
          gioBatDau: plan.newStart,
          gioKetThuc: plan.newEnd,
          hieuLucTu: plan.effectiveFrom,
          hieuLucDen: plan.effectiveTo,
          ghiChu: ghiChu ?? existing.ghiChu,
          updatedAt: DateTime.now(),
        );
        _validateSchedule(updated);
        await _scheduleRepo.updateInTxn(txn, updated);

        await txn.rawDelete('''
          DELETE FROM buoi_hoc 
          WHERE id_lich_hoc = ? AND trang_thai = 'DU_KIEN'
            AND id NOT IN (SELECT id_buoi_hoc FROM diem_danh)
            AND id NOT IN (SELECT id_buoi_hoc_goc FROM dieu_chinh_buoi_hoc WHERE id_buoi_hoc_goc IS NOT NULL)
            AND id NOT IN (SELECT id_buoi_hoc_tham_gia FROM dieu_chinh_buoi_hoc)
        ''', [plan.scheduleId]);

        for (final a in assignments) {
          String newAssignStart = a.tuNgay;
          if (newAssignStart.compareTo(plan.effectiveFrom) < 0) {
            newAssignStart = plan.effectiveFrom;
          }
          String? newAssignEnd = a.denNgay;
          if (plan.effectiveTo != null) {
            if (newAssignEnd == null || newAssignEnd.compareTo(plan.effectiveTo!) > 0) {
              newAssignEnd = plan.effectiveTo;
            }
          }
          if (newAssignStart != a.tuNgay || newAssignEnd != a.denNgay) {
            await _assignmentRepo.updateInTxn(
              txn,
              a.copyWith(
                tuNgay: newAssignStart,
                denNgay: newAssignEnd,
                updatedAt: DateTime.now(),
              ),
            );
          }
        }
      } else {
        final dateFormat = DateFormat('yyyy-MM-dd');
        final dayBeforeStr = dateFormat.format(
          DateTime.parse(plan.effectiveFrom).subtract(const Duration(days: 1)),
        );

        if (dayBeforeStr.compareTo(existing.hieuLucTu) < 0) {
          throw Exception(
            'Ngày áp dụng lịch mới (${plan.effectiveFrom}) phải sau ngày bắt đầu lịch cũ (${existing.hieuLucTu}).',
          );
        }

        final closedOld = existing.copyWith(
          hieuLucDen: dayBeforeStr,
          updatedAt: DateTime.now(),
        );
        await _scheduleRepo.updateInTxn(txn, closedOld);

        final newSchedule = ClassSchedule(
          idLop: existing.idLop,
          thuTrongTuan: plan.newWeekday,
          gioBatDau: plan.newStart,
          gioKetThuc: plan.newEnd,
          hieuLucTu: plan.effectiveFrom,
          hieuLucDen: plan.effectiveTo,
          ghiChu: ghiChu ?? existing.ghiChu,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        _validateSchedule(newSchedule);
        final newScheduleId = await _scheduleRepo.createInTxn(txn, newSchedule);

        for (final a in assignments) {
          if (a.denNgay == null || a.denNgay!.compareTo(plan.effectiveFrom) >= 0) {
            if (a.tuNgay.compareTo(dayBeforeStr) <= 0) {
              await _assignmentRepo.updateInTxn(
                txn,
                a.copyWith(denNgay: dayBeforeStr, updatedAt: DateTime.now()),
              );
              await _assignmentRepo.createInTxn(
                txn,
                StudentShiftAssignment(
                  idHocSinh: a.idHocSinh,
                  idLop: a.idLop,
                  idLichHoc: newScheduleId,
                  tuNgay: plan.effectiveFrom,
                  denNgay: a.denNgay,
                  ghiChu: a.ghiChu,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                ),
              );
            } else {
              await _assignmentRepo.updateInTxn(
                txn,
                a.copyWith(idLichHoc: newScheduleId, updatedAt: DateTime.now()),
              );
            }
          }
        }

        await txn.rawDelete('''
          DELETE FROM buoi_hoc 
          WHERE id_lich_hoc = ? AND ngay >= ? AND trang_thai = 'DU_KIEN'
            AND id NOT IN (SELECT id_buoi_hoc FROM diem_danh)
            AND id NOT IN (SELECT id_buoi_hoc_goc FROM dieu_chinh_buoi_hoc WHERE id_buoi_hoc_goc IS NOT NULL)
            AND id NOT IN (SELECT id_buoi_hoc_tham_gia FROM dieu_chinh_buoi_hoc)
        ''', [plan.scheduleId, plan.effectiveFrom]);
      }

      final fromDt = DateTime.parse(plan.effectiveFrom);
      final toDt = plan.effectiveTo != null
          ? DateTime.parse(plan.effectiveTo!)
          : DateTime(fromDt.year, fromDt.month + 3, 1);
      await _generateSessionsInTxn(
        txn,
        classId: existing.idLop,
        fromDate: fromDt,
        toDate: toDt,
      );
    });
  }

  Future<void> reviseSchedule({
    required int scheduleId,
    required int thuTrongTuan,
    required String gioBatDau,
    required String gioKetThuc,
    required DateTime effectiveDate,
    DateTime? effectiveTo,
    String? ghiChu,
  }) async {
    final dateFormat = DateFormat('yyyy-MM-dd');
    final effectiveFromStr = dateFormat.format(effectiveDate);
    final effectiveToStr =
        effectiveTo != null ? dateFormat.format(effectiveTo) : null;

    final plan = await previewScheduleChange(
      scheduleId: scheduleId,
      newWeekday: thuTrongTuan,
      newStart: gioBatDau,
      newEnd: gioKetThuc,
      newEffectiveFrom: effectiveFromStr,
      newEffectiveTo: effectiveToStr,
    );

    await applyScheduleChange(plan: plan, ghiChu: ghiChu);
  }

  Future<void> _generateSessionsInTxn(
    DatabaseExecutor txn, {
    required int classId,
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    if (toDate.isBefore(fromDate)) return;

    final dateFormat = DateFormat('yyyy-MM-dd');
    final fromStr = dateFormat.format(fromDate);
    final toStr = dateFormat.format(toDate);

    final schedulesMapList = await txn.query(
      'lich_hoc',
      where: 'id_lop = ?',
      whereArgs: [classId],
    );
    final schedules =
        schedulesMapList.map((m) => ClassSchedule.fromMap(m)).toList();
    if (schedules.isEmpty) return;

    final existingMapList = await txn.query(
      'buoi_hoc',
      where: 'id_lop = ? AND ngay >= ? AND ngay <= ?',
      whereArgs: [classId, fromStr, toStr],
    );
    final existingKeys = <String>{};
    for (final e in existingMapList) {
      existingKeys.add('${e['ngay']}_${e['gio_bat_dau']}');
    }

    final nowStr = DateTime.now().toIso8601String();

    for (
      var day = fromDate;
      !day.isAfter(toDate);
      day = DateTime(day.year, day.month, day.day + 1)
    ) {
      final dayStr = dateFormat.format(day);
      final weekday = day.weekday;

      final dailySchedules = schedules.where((s) {
        if (s.thuTrongTuan != weekday) return false;
        if (dayStr.compareTo(s.hieuLucTu) < 0) return false;
        if (s.hieuLucDen != null && dayStr.compareTo(s.hieuLucDen!) > 0) {
          return false;
        }
        return true;
      }).toList();

      for (final s in dailySchedules) {
        final key = '${dayStr}_${s.gioBatDau}';
        if (existingKeys.contains(key)) {
          continue;
        }

        await txn.insert('buoi_hoc', {
          'id_lop': classId,
          'id_lich_hoc': s.id,
          'ngay': dayStr,
          'gio_bat_dau': s.gioBatDau,
          'gio_ket_thuc': s.gioKetThuc,
          'loai': 'CHINH',
          'trang_thai': 'DU_KIEN',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
        existingKeys.add(key);
      }
    }
  }

  Future<List<ClassSchedule>> getSchedulesForClass(int classId) async {
    return _scheduleRepo.getByClass(classId);
  }

  Future<ClassSchedule?> getScheduleById(int id) async {
    return _scheduleRepo.getById(id);
  }

  // --- Assignment Management ---

  Future<List<StudentShiftAssignment>> getAssignmentsForStudent(
    int studentId,
  ) async {
    return _assignmentRepo.getByStudent(studentId);
  }

  Future<List<StudentShiftAssignment>> getAssignmentsForClass(
    int classId,
  ) async {
    return _assignmentRepo.getByClass(classId);
  }

  Future<List<StudentShiftAssignment>> getActiveAssignmentsForClass(
    int classId,
    DateTime date,
  ) async {
    final dateFormat = DateFormat('yyyy-MM-dd');
    final dateStr = dateFormat.format(date);
    return _assignmentRepo.getActiveForClass(classId, dateStr);
  }

  Future<List<Student>> getAssignmentCandidates(
    int classId,
    DateTime date,
  ) async {
    final activeIds = await _membershipService.getActiveStudentIdsInClass(
      classId,
      date,
    );
    final allStudents = await _studentService.getStudents();
    return allStudents
        .where((s) => !s.daLuuTru && activeIds.contains(s.id))
        .toList();
  }

  // Bulk Candidate Query with Date Interval Overlap Filtering
  Future<List<Student>> getBulkAssignmentCandidates({
    required int classId,
    required int scheduleId,
    required DateTime startDate,
  }) async {
    final cls = await _classService.getClassById(classId);
    if (cls == null) throw Exception('Không tìm thấy lớp học');
    if (cls.daLuuTru) {
      throw Exception('Không thể phân ca vào lớp đã lưu trữ');
    }

    final schedule = await _scheduleRepo.getById(scheduleId);
    if (schedule == null) throw Exception('Không tìm thấy lịch học');
    if (schedule.idLop != classId) {
      throw Exception('Lịch học không thuộc lớp này');
    }

    final dateFormat = DateFormat('yyyy-MM-dd');
    final startStr = dateFormat.format(startDate);

    if (startStr.compareTo(schedule.hieuLucTu) < 0) {
      throw Exception(
        'Ngày phân ca ($startStr) trước khi lịch học có hiệu lực (${schedule.hieuLucTu})',
      );
    }
    if (schedule.hieuLucDen != null &&
        startStr.compareTo(schedule.hieuLucDen!) > 0) {
      throw Exception(
        'Ngày phân ca ($startStr) sau khi lịch học hết hiệu lực (${schedule.hieuLucDen})',
      );
    }

    // Include students joining after the chosen class-wide start date.
    final memberships = await _membershipService
        .getMembershipsOverlappingDateRange(
          fromDate: startStr,
          toDate: schedule.hieuLucDen ?? '9999-12-31',
          classId: classId,
        );
    final eligibleStudentIds = memberships.map((m) => m.idHocSinh).toSet();

    // 2. Query overlapping assignments for this schedule
    final overlappingAssignments = await _assignmentRepo
        .getOverlappingBySchedule(scheduleId: scheduleId, startDate: startStr);
    final alreadyAssignedStudentIds = overlappingAssignments
        .map((a) => a.idHocSinh)
        .toSet();

    // 3. Load students ONCE
    final allStudents = await _studentService.getStudents();

    // 4. Filter candidates: active membership, NOT in alreadyAssignedStudentIds, not archived
    final candidates = allStudents.where((s) {
      if (s.id == null || s.daLuuTru) return false;
      if (!eligibleStudentIds.contains(s.id)) return false;
      if (alreadyAssignedStudentIds.contains(s.id)) return false;
      return true;
    }).toList();

    // 5. Sort alphabetically by name
    candidates.sort((a, b) => a.hoTen.compareTo(b.hoTen));
    return candidates;
  }

  Future<AssignmentConflictResult> assignStudent({
    required int studentId,
    required int classId,
    required int scheduleId,
    required DateTime startDate,
    DateTime? endDate,
    String? ghiChu,
  }) async {
    final schedule = await _scheduleRepo.getById(scheduleId);
    if (schedule == null) throw Exception('Không tìm thấy lịch học');
    if (schedule.idLop != classId) {
      throw Exception('Lịch học không thuộc lớp này');
    }

    final student = await _studentService.getStudentById(studentId);
    if (student == null) throw Exception('Không tìm thấy học sinh');
    if (student.daLuuTru) {
      throw Exception('Không thể phân ca cho học sinh đã lưu trữ');
    }

    final cls = await _classService.getClassById(classId);
    if (cls != null && cls.daLuuTru) {
      throw Exception('Không thể phân ca vào lớp đã lưu trữ');
    }

    final dateFormat = DateFormat('yyyy-MM-dd');
    final requestedStartStr = dateFormat.format(startDate);
    final endStr = endDate != null ? dateFormat.format(endDate) : null;
    final startStr = await _effectiveAssignmentStart(
      studentId,
      classId,
      requestedStartStr,
    );

    // 1. Boundary Check
    await _validateAssignmentInterval(
      studentId,
      classId,
      schedule,
      startStr,
      endStr,
    );

    // 2. Canonical Conflict Evaluation (Single Source of Truth)
    final conflictResult = await _conflictService.evaluateCandidateAssignment(
      studentId: studentId,
      targetScheduleId: scheduleId,
      startDate: startStr,
      endDate: endStr,
      studentName: student.hoTen,
    );

    if (!conflictResult.canAssign) {
      return AssignmentConflictResult(
        canAssign: false,
        conflictReason: conflictResult.hardConflicts.first.message,
        detailedResult: conflictResult,
      );
    }

    // 3. Persist Assignment
    final newId = await _assignmentRepo.create(
      StudentShiftAssignment(
        idHocSinh: studentId,
        idLop: classId,
        idLichHoc: scheduleId,
        tuNgay: startStr,
        denNgay: endStr,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        ghiChu: ghiChu,
      ),
    );

    return AssignmentConflictResult(
      canAssign: true,
      assignmentId: newId,
      detailedResult: conflictResult,
    );
  }

  // Common Candidate Validation Internal Helper
  Future<BulkAssignmentItemResult> _validateCandidateInternal({
    required int studentId,
    required String studentName,
    required int classId,
    required int scheduleId,
    required ClassSchedule schedule,
    required String startStr,
    String? endStr,
    int? excludeAssignmentId,
  }) async {
    String effectiveStart;
    try {
      effectiveStart = await _effectiveAssignmentStart(
        studentId,
        classId,
        startStr,
      );
    } catch (e) {
      return BulkAssignmentItemResult(
        studentId: studentId,
        studentName: studentName,
        status: BulkAssignmentStatus.invalidBoundary,
        message: e.toString().replaceAll('Exception: ', ''),
      );
    }

    // 1. Check duplicate/overlap for same student & schedule
    final isOverlapping = await _assignmentRepo.hasOverlappingStudentAssignment(
      studentId: studentId,
      scheduleId: scheduleId,
      startDate: effectiveStart,
      endDate: endStr,
      excludeAssignmentId: excludeAssignmentId,
    );
    if (isOverlapping) {
      return BulkAssignmentItemResult(
        studentId: studentId,
        studentName: studentName,
        status: BulkAssignmentStatus.alreadyAssigned,
        message: 'Học sinh đã có phân ca trùng khớp trong thời gian này',
      );
    }

    // 2. Validate membership & schedule boundaries
    try {
      await _validateAssignmentInterval(
        studentId,
        classId,
        schedule,
        effectiveStart,
        endStr,
      );
    } catch (e) {
      return BulkAssignmentItemResult(
        studentId: studentId,
        studentName: studentName,
        status: BulkAssignmentStatus.invalidBoundary,
        message: e.toString().replaceAll('Exception: ', ''),
      );
    }

    // 3. Conflict evaluation via ScheduleConflictService
    final conflictResult = await _conflictService.evaluateCandidateAssignment(
      studentId: studentId,
      targetScheduleId: scheduleId,
      startDate: effectiveStart,
      endDate: endStr,
      excludeAssignmentId: excludeAssignmentId,
    );

    if (!conflictResult.canAssign) {
      return BulkAssignmentItemResult(
        studentId: studentId,
        studentName: studentName,
        status: BulkAssignmentStatus.hardConflict,
        conflictResult: conflictResult,
        message: conflictResult.hardConflicts.isNotEmpty
            ? conflictResult.hardConflicts.first.message
            : 'Xung đột lịch học',
      );
    }

    return BulkAssignmentItemResult(
      studentId: studentId,
      studentName: studentName,
      status: BulkAssignmentStatus.ready,
      conflictResult: conflictResult,
      message: effectiveStart == startStr
          ? null
          : 'Bắt đầu từ ngày tham gia lớp $effectiveStart',
    );
  }

  // Pre-flight Bulk Assignment Preview
  Future<BulkAssignmentPreview> previewBulkAssignment({
    required List<int> studentIds,
    required int classId,
    required int scheduleId,
    required DateTime startDate,
  }) async {
    final cls = await _classService.getClassById(classId);
    if (cls == null) throw Exception('Không tìm thấy lớp học');
    if (cls.daLuuTru) {
      throw Exception('Không thể phân ca vào lớp đã lưu trữ');
    }

    final schedule = await _scheduleRepo.getById(scheduleId);
    if (schedule == null) throw Exception('Không tìm thấy lịch học');
    if (schedule.idLop != classId) {
      throw Exception('Lịch học không thuộc lớp này');
    }

    final dateFormat = DateFormat('yyyy-MM-dd');
    final startStr = dateFormat.format(startDate);

    final uniqueStudentIds = studentIds.toSet().toList();
    final allStudents = await _studentService.getStudents();
    final studentMap = {for (var s in allStudents) s.id!: s};

    final readyStudents = <Student>[];
    final blocked = <BulkAssignmentItemResult>[];
    final warnings = <BulkAssignmentItemResult>[];

    for (final sId in uniqueStudentIds) {
      final student = studentMap[sId];
      final studentName = student?.hoTen ?? 'Học sinh #$sId';

      if (student == null || student.daLuuTru) {
        blocked.add(
          BulkAssignmentItemResult(
            studentId: sId,
            studentName: studentName,
            status: BulkAssignmentStatus.invalidBoundary,
            message: 'Học sinh không tồn tại hoặc đã bị ngừng học',
          ),
        );
        continue;
      }

      final itemResult = await _validateCandidateInternal(
        studentId: sId,
        studentName: studentName,
        classId: classId,
        scheduleId: scheduleId,
        schedule: schedule,
        startStr: startStr,
      );

      if (itemResult.isReady) {
        readyStudents.add(student);
        if (itemResult.hasWarnings) {
          warnings.add(itemResult);
        }
      } else {
        blocked.add(itemResult);
      }
    }

    return BulkAssignmentPreview(
      readyStudents: readyStudents,
      blocked: blocked,
      warnings: warnings,
    );
  }

  // Bulk Assignment Transaction
  Future<BulkAssignmentResult> assignStudentsBulk({
    required List<int> studentIds,
    required int classId,
    required int scheduleId,
    required DateTime startDate,
    String? note,
  }) async {
    final preview = await previewBulkAssignment(
      studentIds: studentIds,
      classId: classId,
      scheduleId: scheduleId,
      startDate: startDate,
    );

    final dateFormat = DateFormat('yyyy-MM-dd');
    final startStr = dateFormat.format(startDate);
    final now = DateTime.now();

    final itemResults = <BulkAssignmentItemResult>[
      ...preview.blocked,
      ...preview.warnings,
    ];

    if (preview.readyStudents.isEmpty) {
      return BulkAssignmentResult(
        totalAttempted: studentIds.toSet().length,
        successCount: 0,
        items: itemResults,
      );
    }

    // Execute ONE SQLite transaction for all valid ready students
    final validStudents = preview.readyStudents;
    final effectiveStarts = <int, String>{};
    for (final student in validStudents) {
      effectiveStarts[student.id!] = await _effectiveAssignmentStart(
        student.id!,
        classId,
        startStr,
      );
    }
    await _assignmentRepo.db.transaction((txn) async {
      for (final student in validStudents) {
        await _assignmentRepo.createInTxn(
          txn,
          StudentShiftAssignment(
            idHocSinh: student.id!,
            idLop: classId,
            idLichHoc: scheduleId,
            tuNgay: effectiveStarts[student.id!]!,
            denNgay: null,
            ghiChu: note,
            createdAt: now,
            updatedAt: now,
          ),
        );
        itemResults.add(
          BulkAssignmentItemResult(
            studentId: student.id!,
            studentName: student.hoTen,
            status: BulkAssignmentStatus.ready,
          ),
        );
      }
    });

    return BulkAssignmentResult(
      totalAttempted: studentIds.toSet().length,
      successCount: validStudents.length,
      items: itemResults,
    );
  }

  Future<void> closeAssignment(int assignmentId, DateTime endDate) async {
    final existing = await _assignmentRepo.getById(assignmentId);
    if (existing == null) throw Exception('Không tìm thấy phân ca');

    final dateFormat = DateFormat('yyyy-MM-dd');
    final endStr = dateFormat.format(endDate);

    if (endStr.compareTo(existing.tuNgay) < 0) {
      throw Exception('Ngày kết thúc không được trước ngày bắt đầu');
    }

    if (existing.denNgay != null) {
      if (endStr == existing.denNgay) return; // Idempotent
      throw Exception(
        'Không thể sửa đổi phân ca đã kết thúc ($endStr != ${existing.denNgay})',
      );
    }

    // Boundary check against membership
    final memberships = await _membershipService.getMembershipHistory(
      existing.idHocSinh,
      classId: existing.idLop,
    );
    final m = memberships.firstWhere(
      (m) =>
          existing.tuNgay.compareTo(m.tuNgay) >= 0 &&
          (m.denNgay == null || existing.tuNgay.compareTo(m.denNgay!) <= 0),
    );
    if (m.denNgay != null && endStr.compareTo(m.denNgay!) > 0) {
      throw Exception(
        'Ngày kết thúc phân ca ($endStr) không được vượt quá ngày nghỉ lớp (${m.denNgay})',
      );
    }

    // Boundary check against schedule
    final schedule = await _scheduleRepo.getById(existing.idLichHoc);
    if (schedule != null &&
        schedule.hieuLucDen != null &&
        endStr.compareTo(schedule.hieuLucDen!) > 0) {
      throw Exception(
        'Ngày kết thúc phân ca không được vượt quá ngày hết hiệu lực của lịch học (${schedule.hieuLucDen})',
      );
    }

    await _assignmentRepo.update(
      existing.copyWith(denNgay: endStr, updatedAt: DateTime.now()),
    );
  }

  Future<void> updateAssignmentStartDate({
    required int assignmentId,
    required DateTime newStartDate,
  }) async {
    final existing = await _assignmentRepo.getById(assignmentId);
    if (existing == null) throw Exception('Không tìm thấy phân ca');

    final dateFormat = DateFormat('yyyy-MM-dd');
    final newStartStr = dateFormat.format(newStartDate);

    if (newStartStr == existing.tuNgay) return;

    final schedule = await _scheduleRepo.getById(existing.idLichHoc);
    if (schedule == null) throw Exception('Không tìm thấy lịch học');

    await _validateAssignmentInterval(
      existing.idHocSinh,
      existing.idLop,
      schedule,
      newStartStr,
      existing.denNgay,
    );

    final db = _scheduleRepo.db;
    final affectedFrom = newStartStr.compareTo(existing.tuNgay) < 0
        ? newStartStr
        : existing.tuNgay;
    final affectedTo = newStartStr.compareTo(existing.tuNgay) < 0
        ? existing.tuNgay
        : newStartStr;

    final sessionsInAffectedRange = await db.query(
      'buoi_hoc',
      where:
          'id_lop = ? AND (id_lich_hoc = ? OR id_lich_hoc IS NULL) AND ngay >= ? AND ngay <= ?',
      whereArgs: [existing.idLop, existing.idLichHoc, affectedFrom, affectedTo],
    );

    for (final sMap in sessionsInAffectedRange) {
      final sessionId = sMap['id'] as int;
      final status = sMap['trang_thai'] as String;

      if (status != 'DU_KIEN') {
        throw Exception(
          'Không thể thay đổi ngày bắt đầu vì phân ca này đã ảnh hưởng đến các buổi học/điểm danh trong lịch sử.',
        );
      }

      final attendanceCount =
          Sqflite.firstIntValue(
            await db.rawQuery(
              'SELECT COUNT(*) FROM diem_danh WHERE id_buoi_hoc = ? AND id_hoc_sinh = ?',
              [sessionId, existing.idHocSinh],
            ),
          ) ??
          0;
      if (attendanceCount > 0) {
        throw Exception(
          'Không thể thay đổi ngày bắt đầu vì phân ca này đã ảnh hưởng đến các buổi học/điểm danh trong lịch sử.',
        );
      }

      final adjustmentCount =
          Sqflite.firstIntValue(
            await db.rawQuery(
              'SELECT COUNT(*) FROM dieu_chinh_buoi_hoc WHERE id_hoc_sinh = ? AND (id_buoi_hoc_goc = ? OR id_buoi_hoc_tham_gia = ?)',
              [existing.idHocSinh, sessionId, sessionId],
            ),
          ) ??
          0;
      if (adjustmentCount > 0) {
        throw Exception(
          'Không thể thay đổi ngày bắt đầu vì phân ca này đã ảnh hưởng đến các buổi học/điểm danh trong lịch sử.',
        );
      }
    }

    final conflictResult = await _conflictService.evaluateCandidateAssignment(
      studentId: existing.idHocSinh,
      targetScheduleId: existing.idLichHoc,
      startDate: newStartStr,
      endDate: existing.denNgay,
      excludeAssignmentId: assignmentId,
    );
    if (!conflictResult.canAssign) {
      throw Exception(conflictResult.hardConflicts.first.message);
    }

    await _assignmentRepo.update(
      existing.copyWith(tuNgay: newStartStr, updatedAt: DateTime.now()),
    );
  }

  Future<void> changeRecurringShift({
    required int studentId,
    required int classId,
    required int oldAssignmentId,
    required int newScheduleId,
    required DateTime effectiveDate,
  }) async {
    final oldAssignment = await _assignmentRepo.getById(oldAssignmentId);
    if (oldAssignment == null) throw Exception('Không tìm thấy phân ca cũ');

    if (oldAssignment.idHocSinh != studentId ||
        oldAssignment.idLop != classId) {
      throw Exception('Thông tin phân ca cũ không khớp với học sinh/lớp');
    }

    final dateFormat = DateFormat('yyyy-MM-dd');
    final startStr = dateFormat.format(effectiveDate);
    final yesterdayStr = dateFormat.format(
      effectiveDate.subtract(const Duration(days: 1)),
    );

    if (yesterdayStr.compareTo(oldAssignment.tuNgay) < 0) {
      throw Exception(
        'Ngày bắt đầu ca mới không hợp lệ (phải sau ngày bắt đầu ca cũ)',
      );
    }

    if (oldAssignment.denNgay != null) {
      throw Exception('Không thể đổi ca từ phân ca đã kết thúc');
    }

    final schedule = await _scheduleRepo.getById(newScheduleId);
    if (schedule == null) throw Exception('Không tìm thấy lịch học');
    if (schedule.idLop != classId) {
      throw Exception('Lịch học không thuộc lớp này');
    }

    // 1. Validate Boundaries
    await _validateAssignmentInterval(
      studentId,
      classId,
      schedule,
      startStr,
      null,
    );

    // 2. Canonical Conflict Evaluation
    final conflictResult = await _conflictService.evaluateCandidateAssignment(
      studentId: studentId,
      targetScheduleId: newScheduleId,
      startDate: startStr,
      endDate: null,
      excludeAssignmentId: oldAssignmentId,
    );
    if (!conflictResult.canAssign) {
      throw Exception(conflictResult.hardConflicts.first.message);
    }

    // 3. Atomic Transaction (Close Old + Insert New)
    await _assignmentRepo.db.transaction((txn) async {
      final updatedOld = oldAssignment.copyWith(
        denNgay: yesterdayStr,
        updatedAt: DateTime.now(),
      );
      final count = await _assignmentRepo.updateInTxn(txn, updatedOld);
      if (count != 1) {
        throw Exception('Cập nhật phân ca cũ thất bại');
      }

      await _assignmentRepo.createInTxn(
        txn,
        StudentShiftAssignment(
          idHocSinh: studentId,
          idLop: classId,
          idLichHoc: newScheduleId,
          tuNgay: startStr,
          denNgay: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
    });
  }

  Future<String> _effectiveAssignmentStart(
    int studentId,
    int classId,
    String requestedStart,
  ) async {
    final memberships = await _membershipService.getMembershipHistory(
      studentId,
      classId: classId,
    );
    final candidates =
        memberships
            .where(
              (m) =>
                  m.denNgay == null ||
                  m.denNgay!.compareTo(requestedStart) >= 0,
            )
            .toList()
          ..sort((a, b) => a.tuNgay.compareTo(b.tuNgay));
    if (candidates.isEmpty) {
      throw Exception(
        'Học sinh không có thời gian tham gia lớp từ ngày $requestedStart',
      );
    }
    final joinDate = candidates.first.tuNgay;
    return requestedStart.compareTo(joinDate) < 0 ? joinDate : requestedStart;
  }

  Future<void> _validateAssignmentInterval(
    int studentId,
    int classId,
    ClassSchedule schedule,
    String startStr,
    String? endStr,
  ) async {
    // 1. Membership Boundary Check
    final memberships = await _membershipService.getMembershipHistory(
      studentId,
      classId: classId,
    );
    final activeMembership = memberships.firstWhere(
      (m) =>
          startStr.compareTo(m.tuNgay) >= 0 &&
          (m.denNgay == null || startStr.compareTo(m.denNgay!) <= 0),
      orElse: () => throw Exception(
        'Học sinh không có tham gia lớp hợp lệ tại ngày bắt đầu phân ca ($startStr)',
      ),
    );

    if (activeMembership.denNgay != null) {
      if (endStr == null) {
        throw Exception(
          'Phân ca không có ngày kết thúc nhưng học sinh sẽ nghỉ lớp vào ngày ${activeMembership.denNgay}',
        );
      }
      if (endStr.compareTo(activeMembership.denNgay!) > 0) {
        throw Exception(
          'Ngày kết thúc phân ca ($endStr) vượt quá ngày nghỉ lớp (${activeMembership.denNgay})',
        );
      }
    }

    // 2. Schedule Boundary Check
    if (startStr.compareTo(schedule.hieuLucTu) < 0) {
      throw Exception(
        'Phân ca không được bắt đầu trước khi lịch học có hiệu lực (${schedule.hieuLucTu})',
      );
    }
    if (schedule.hieuLucDen != null) {
      if (endStr == null) {
        throw Exception(
          'Phân ca không có ngày kết thúc nhưng lịch học sẽ hết hiệu lực vào ngày ${schedule.hieuLucDen}',
        );
      }
      if (endStr.compareTo(schedule.hieuLucDen!) > 0) {
        throw Exception(
          'Phân ca không được kéo dài sau khi lịch học hết hiệu lực (${schedule.hieuLucDen})',
        );
      }
    }
  }

  void _validateSchedule(ClassSchedule schedule) {
    DateAndTimeValidators.validateTimeOrder(
      schedule.gioBatDau,
      schedule.gioKetThuc,
      'gioBatDau',
      'gioKetThuc',
    );
    DateAndTimeValidators.validateDateRange(
      schedule.hieuLucTu,
      schedule.hieuLucDen,
      'hieuLucTu',
      'hieuLucDen',
    );
    if (schedule.thuTrongTuan < 1 || schedule.thuTrongTuan > 7) {
      throw Exception('Thứ trong tuần không hợp lệ (1-7)');
    }
  }
}

class AssignmentConflictResult {
  final bool canAssign;
  final int? assignmentId;
  final String? conflictReason;
  final ScheduleConflictResult? detailedResult;

  const AssignmentConflictResult({
    required this.canAssign,
    this.assignmentId,
    this.conflictReason,
    this.detailedResult,
  });
}

@Riverpod(keepAlive: true)
Future<ScheduleDomainService> classScheduleService(
  ClassScheduleServiceRef ref,
) async {
  final scheduleRepo = await ref.watch(scheduleRepositoryProvider.future);
  final assignmentRepo = await ref.watch(assignmentRepositoryProvider.future);
  final membershipService = await ref.watch(membershipServiceProvider.future);
  final classService = await ref.watch(classServiceProvider.future);
  final studentService = await ref.watch(studentServiceProvider.future);
  final conflictService = await ref.watch(
    scheduleConflictServiceProvider.future,
  );
  return ScheduleDomainService(
    scheduleRepo,
    assignmentRepo,
    membershipService,
    classService,
    studentService,
    conflictService,
  );
}
