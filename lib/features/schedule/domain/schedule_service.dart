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

  ScheduleDomainService(
    this._scheduleRepo,
    this._assignmentRepo,
    this._membershipService,
    this._classService,
    this._studentService,
  );

  // --- Schedule Management ---

  Future<ClassSchedule?> getScheduleById(int id) {
    return _scheduleRepo.getById(id);
  }

  Future<void> createSchedule(ClassSchedule schedule) async {
    final cls = await _classService.getClassById(schedule.idLop);
    if (cls == null) throw Exception('Không tìm thấy lớp học');
    if (cls.daLuuTru) {
      throw Exception('Không thể tạo lịch học cho lớp đã lưu trữ');
    }

    _validateSchedule(schedule);
    await _scheduleRepo.create(
      schedule.copyWith(createdAt: DateTime.now(), updatedAt: DateTime.now()),
    );
  }

  Future<void> updateScheduleMetadata(ClassSchedule schedule) async {
    final existing = await _scheduleRepo.getById(schedule.id!);
    if (existing == null) throw Exception('Không tìm thấy lịch học');

    if (existing.thuTrongTuan != schedule.thuTrongTuan ||
        existing.gioBatDau != schedule.gioBatDau ||
        existing.gioKetThuc != schedule.gioKetThuc ||
        existing.hieuLucTu != schedule.hieuLucTu) {
      throw Exception(
        'Cập nhật thay đổi lịch sử không được phép. Hãy đóng lịch cũ và tạo lịch mới.',
      );
    }

    await _scheduleRepo.update(schedule.copyWith(updatedAt: DateTime.now()));
  }

  Future<void> closeSchedule(int scheduleId, DateTime endDate) async {
    final existing = await _scheduleRepo.getById(scheduleId);
    if (existing == null) throw Exception('Không tìm thấy lịch học');

    final dateFormat = DateFormat('yyyy-MM-dd');
    final endDateStr = dateFormat.format(endDate);

    if (endDateStr.compareTo(existing.hieuLucTu) < 0) {
      throw Exception('Ngày kết thúc không được trước ngày bắt đầu');
    }

    // BLOCK if there are assignments that outlive the new end date
    final assignments = await _assignmentRepo.getBySchedule(scheduleId);
    final affected = assignments.where(
      (a) => a.denNgay == null || a.denNgay!.compareTo(endDateStr) > 0,
    );

    if (affected.isNotEmpty) {
      throw Exception(
        'Không thể đóng lịch học. Còn ${affected.length} phân ca của học sinh vượt quá ngày kết thúc dự kiến.',
      );
    }

    await _scheduleRepo.update(
      existing.copyWith(hieuLucDen: endDateStr, updatedAt: DateTime.now()),
    );
  }

  Future<List<ClassSchedule>> getSchedulesForClass(
    int classId, {
    DateTime? date,
  }) async {
    if (date != null) {
      final dateFormat = DateFormat('yyyy-MM-dd');
      return _scheduleRepo.getEffectiveByClass(
        classId,
        dateFormat.format(date),
      );
    }
    return _scheduleRepo.getByClass(classId);
  }

  // --- Assignment Management ---

  Future<List<StudentShiftAssignment>> getAssignmentsForClass(int classId) {
    return _assignmentRepo.getByClass(classId);
  }

  Future<List<StudentShiftAssignment>> getAssignmentsForStudent(int studentId) {
    return _assignmentRepo.getByStudent(studentId);
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

    await _validateAssignmentInterval(
      studentId,
      classId,
      schedule,
      startStr,
      endStr,
    );

    await _assignmentRepo.create(
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

    return const AssignmentConflictResult(canAssign: true);
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
      if (endStr.compareTo(existing.denNgay!) > 0) {
        throw Exception(
          'Không thể kéo dài phân ca đã kết thúc ($endStr > ${existing.denNgay})',
        );
      }
      // Note: Truncating an already closed assignment might be allowed in correction flows,
      // but here we follow the strict rule: closeAssignment handles open ones.
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

    // OLD ASSIGNMENT HARDENING: Must be active on day immediately before effectiveDate
    // Effectively: old.tuNgay <= yesterdayStr AND (old.denNgay == null OR old.denNgay >= yesterdayStr)
    if (oldAssignment.denNgay != null &&
        yesterdayStr.compareTo(oldAssignment.denNgay!) > 0) {
      throw Exception(
        'Không thể đổi ca từ phân ca đã kết thúc trước ngày $startStr',
      );
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

    await _assignmentRepo.db.transaction((txn) async {
      await txn.update(
        'phan_ca_hoc_sinh',
        {
          'den_ngay': yesterdayStr,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [oldAssignmentId],
      );

      await txn.insert(
        'phan_ca_hoc_sinh',
        StudentShiftAssignment(
          idHocSinh: studentId,
          idLop: classId,
          idLichHoc: newScheduleId,
          tuNgay: startStr,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ).toMap(),
      );
    });
  }

  Future<void> _validateAssignmentInterval(
    int studentId,
    int classId,
    ClassSchedule schedule,
    String startStr,
    String? endStr, {
    int? excludeAssignmentId,
  }) async {
    if (endStr != null && endStr.compareTo(startStr) < 0) {
      throw Exception('Ngày kết thúc không được trước ngày bắt đầu');
    }

    // 1. Membership Boundary
    final memberships = await _membershipService.getMembershipHistory(
      studentId,
      classId: classId,
    );
    final containingMembership = memberships.firstWhere(
      (m) =>
          startStr.compareTo(m.tuNgay) >= 0 &&
          (m.denNgay == null || startStr.compareTo(m.denNgay!) <= 0),
      orElse: () => throw Exception(
        'Phân ca phải bắt đầu trong một khoảng thời gian tham gia lớp (Membership)',
      ),
    );

    if (endStr == null) {
      if (containingMembership.denNgay != null) {
        throw Exception(
          'Phân ca không có ngày kết thúc nhưng học sinh sẽ nghỉ lớp vào ngày ${containingMembership.denNgay}',
        );
      }
    } else {
      if (containingMembership.denNgay != null &&
          endStr.compareTo(containingMembership.denNgay!) > 0) {
        throw Exception(
          'Phân ca kết thúc vào ngày $endStr nhưng học sinh nghỉ lớp vào ngày ${containingMembership.denNgay}',
        );
      }
    }

    // 2. Schedule Boundary
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

    // 3. Conflict Check (Overlap)
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
  final String? conflictReason;
  const AssignmentConflictResult({
    required this.canAssign,
    this.conflictReason,
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
  return ScheduleDomainService(
    scheduleRepo,
    assignmentRepo,
    membershipService,
    classService,
    studentService,
  );
}
