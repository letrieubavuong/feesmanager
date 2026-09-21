import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:intl/intl.dart';
import '../../../core/database/database_provider.dart';
import '../data/schedule_repository.dart';
import '../data/assignment_repository.dart';
import 'class_schedule.dart';
import 'student_shift_assignment.dart';
import '../../memberships/domain/membership_service.dart';

part 'schedule_service.g.dart';

@Riverpod(keepAlive: true)
Future<ScheduleRepository> scheduleRepository(ScheduleRepositoryRef ref) async {
  final db = await ref.watch(databaseProvider.future);
  return ScheduleRepository(db);
}

@Riverpod(keepAlive: true)
Future<AssignmentRepository> assignmentRepository(AssignmentRepositoryRef ref) async {
  final db = await ref.watch(databaseProvider.future);
  return AssignmentRepository(db);
}

class ScheduleService {
  final ScheduleRepository _scheduleRepo;
  final AssignmentRepository _assignmentRepo;
  final MembershipService _membershipService;

  ScheduleService(this._scheduleRepo, this._assignmentRepo, this._membershipService);

  // --- Schedule Management ---

  Future<void> createSchedule(ClassSchedule schedule) async {
    _validateSchedule(schedule);
    await _scheduleRepo.create(schedule.copyWith(
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));
  }

  Future<void> updateScheduleMetadata(ClassSchedule schedule) async {
    // Only metadata, not affecting history (time/weekday/start remain same)
    final existing = await _scheduleRepo.getById(schedule.id!);
    if (existing == null) throw Exception('Không tìm thấy lịch học');

    if (existing.thuTrongTuan != schedule.thuTrongTuan ||
        existing.gioBatDau != schedule.gioBatDau ||
        existing.gioKetThuc != schedule.gioKetThuc ||
        existing.hieuLucTu != schedule.hieuLucTu) {
      throw Exception('Cập nhật thay đổi lịch sử không được phép. Hãy đóng lịch cũ và tạo lịch mới.');
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

    await _scheduleRepo.update(existing.copyWith(
      hieuLucDen: endDateStr,
      updatedAt: DateTime.now(),
    ));
  }

  Future<List<ClassSchedule>> getSchedulesForClass(int classId, {DateTime? date}) async {
    if (date != null) {
      final dateFormat = DateFormat('yyyy-MM-dd');
      return _scheduleRepo.getEffectiveByClass(classId, dateFormat.format(date));
    }
    return _scheduleRepo.getByClass(classId);
  }

  // --- Assignment Management ---

  Future<AssignmentConflictResult> assignStudent({
    required int studentId,
    required int classId,
    required int scheduleId,
    required DateTime joinDate,
    String? ghiChu,
  }) async {
    final schedule = await _scheduleRepo.getById(scheduleId);
    if (schedule == null) throw Exception('Không tìm thấy lịch học');
    if (schedule.idLop != classId) throw Exception('Lịch học không thuộc lớp này');

    final dateFormat = DateFormat('yyyy-MM-dd');
    final joinDateStr = dateFormat.format(joinDate);

    // 1. Check Membership Boundary
    final memberships = await _membershipService.getMembershipHistory(studentId, classId: classId);
    final activeMembership = memberships.any((m) => 
       joinDateStr.compareTo(m.tuNgay) >= 0 && (m.denNgay == null || joinDateStr.compareTo(m.denNgay!) <= 0)
    );
    if (!activeMembership) {
      throw Exception('Học sinh không có membership hoạt động tại ngày bắt đầu phân ca ($joinDateStr)');
    }

    // 2. Check for Conflicts (Same weekday, overlapping time, overlapping effective dates)
    final existingAssignments = await _assignmentRepo.getActiveByStudent(studentId, joinDateStr);
    for (final assignment in existingAssignments) {
      final existingSchedule = await _scheduleRepo.getById(assignment.idLichHoc);
      if (existingSchedule == null) continue;

      if (existingSchedule.thuTrongTuan == schedule.thuTrongTuan) {
        if (_isTimeOverlap(existingSchedule.gioBatDau, existingSchedule.gioKetThuc, schedule.gioBatDau, schedule.gioKetThuc)) {
           return AssignmentConflictResult(
             canAssign: false, 
             conflictReason: 'Trùng lịch với lớp khác: ${existingSchedule.gioBatDau}-${existingSchedule.gioKetThuc} (Thứ ${existingSchedule.thuTrongTuan})'
           );
        }
      }
    }

    await _assignmentRepo.create(StudentShiftAssignment(
      idHocSinh: studentId,
      idLop: classId,
      idLichHoc: scheduleId,
      tuNgay: joinDateStr,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      ghiChu: ghiChu,
    ));

    return const AssignmentConflictResult(canAssign: true);
  }

  void _validateSchedule(ClassSchedule schedule) {
    if (schedule.thuTrongTuan < 1 || schedule.thuTrongTuan > 7) {
      throw Exception('Thứ trong tuần không hợp lệ (1-7)');
    }
    if (schedule.gioBatDau.compareTo(schedule.gioKetThuc) >= 0) {
      throw Exception('Giờ kết thúc phải sau giờ bắt đầu');
    }
    if (schedule.hieuLucDen != null && schedule.hieuLucTu.compareTo(schedule.hieuLucDen!) > 0) {
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
  const AssignmentConflictResult({required this.canAssign, this.conflictReason});
}

@Riverpod(keepAlive: true)
Future<ScheduleService> scheduleService(ScheduleServiceRef ref) async {
  final scheduleRepo = await ref.watch(scheduleRepositoryProvider.future);
  final assignmentRepo = await ref.watch(assignmentRepositoryProvider.future);
  final membershipService = await ref.watch(membershipServiceProvider.future);
  return ScheduleService(scheduleRepo, assignmentRepo, membershipService);
}
