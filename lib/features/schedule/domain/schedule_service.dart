import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:intl/intl.dart';
import '../../../core/database/database_provider.dart';
import '../data/schedule_repository.dart';
import '../data/assignment_repository.dart';
import 'class_schedule.dart';
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
  final ScheduleConflictService? _conflictService;

  ScheduleDomainService(
    this._scheduleRepo,
    this._assignmentRepo,
    this._membershipService,
    this._classService,
    this._studentService, [
    this._conflictService,
  ]);

  // --- Schedule Management ---

  Future<ClassSchedule> createSchedule(ClassSchedule schedule) async {
    final cls = await _classService.getClassById(schedule.idLop);
    if (cls == null) throw Exception('Không tìm thấy lớp học');
    if (cls.daLuuTru) {
      throw Exception('Không thể tạo lịch học cho lớp đã lưu trữ');
    }

    _validateSchedule(schedule);

    final id = await _scheduleRepo.create(schedule);
    return schedule.copyWith(id: id);
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

    await _scheduleRepo.update(
      existing.copyWith(hieuLucDen: endStr, updatedAt: DateTime.now()),
    );
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
    final startStr = dateFormat.format(startDate);
    final endStr = endDate != null ? dateFormat.format(endDate) : null;

    ScheduleConflictResult? conflictResult;
    if (_conflictService != null) {
      conflictResult = await _conflictService.evaluateCandidateAssignment(
        studentId: studentId,
        targetScheduleId: scheduleId,
        startDate: startStr,
        endDate: endStr,
      );

      if (!conflictResult.canAssign) {
        return AssignmentConflictResult(
          canAssign: false,
          conflictReason: conflictResult.hardConflicts.first.message,
          detailedResult: conflictResult,
        );
      }
    }

    await _validateAssignmentInterval(
      studentId,
      classId,
      schedule,
      startStr,
      endStr,
    );

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

    await _validateAssignmentInterval(
      studentId,
      classId,
      schedule,
      startStr,
      null,
      excludeAssignmentId: oldAssignmentId,
    );

    await closeAssignment(
      oldAssignmentId,
      effectiveDate.subtract(const Duration(days: 1)),
    );

    await _assignmentRepo.create(
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
  }

  Future<void> _validateAssignmentInterval(
    int studentId,
    int classId,
    ClassSchedule schedule,
    String startStr,
    String? endStr, {
    int? excludeAssignmentId,
  }) async {
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

    // 3. Conflict Check
    if (_conflictService != null) {
      final result = await _conflictService.evaluateCandidateAssignment(
        studentId: studentId,
        targetScheduleId: schedule.id!,
        startDate: startStr,
        endDate: endStr,
        excludeAssignmentId: excludeAssignmentId,
      );
      if (!result.canAssign) {
        throw Exception(result.hardConflicts.first.message);
      }
    } else {
      final existingAssignments = await _assignmentRepo.getByStudent(studentId);
      for (final assignment in existingAssignments) {
        if (assignment.id == excludeAssignmentId) continue;

        bool dateOverlap = true;
        if (assignment.denNgay != null &&
            startStr.compareTo(assignment.denNgay!) > 0) {
          dateOverlap = false;
        }
        if (endStr != null && assignment.tuNgay.compareTo(endStr) > 0) {
          dateOverlap = false;
        }

        if (dateOverlap) {
          final existingSchedule = await _scheduleRepo.getById(
            assignment.idLichHoc,
          );
          if (existingSchedule == null) continue;

          if (existingSchedule.thuTrongTuan == schedule.thuTrongTuan) {
            if (_isTimeOverlap(
              existingSchedule.gioBatDau,
              existingSchedule.gioKetThuc,
              schedule.gioBatDau,
              schedule.gioKetThuc,
            )) {
              throw Exception(
                'Trùng lịch: ${existingSchedule.gioBatDau}-${existingSchedule.gioKetThuc} (Thứ ${existingSchedule.thuTrongTuan}) tại lớp khác.',
              );
            }
          }
        }
      }
    }
  }

  void _validateSchedule(ClassSchedule schedule) {
    if (schedule.thuTrongTuan < 1 || schedule.thuTrongTuan > 7) {
      throw Exception('Thứ trong tuần không hợp lệ (1-7)');
    }
    if (schedule.gioBatDau.compareTo(schedule.gioKetThuc) >= 0) {
      throw Exception('Giờ kết thúc phải sau giờ bắt đầu');
    }
    if (schedule.hieuLucDen != null &&
        schedule.hieuLucTu.compareTo(schedule.hieuLucDen!) > 0) {
      throw Exception('Ngày kết thúc hiệu lực không được trước ngày bắt đầu');
    }
  }

  bool _isTimeOverlap(String s1, String e1, String s2, String e2) {
    return s1.compareTo(e2) < 0 && s2.compareTo(e1) < 0;
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
