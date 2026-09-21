import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:intl/intl.dart';
import '../../schedule/domain/schedule_service.dart';
import '../../classes/domain/class_service.dart';
import '../data/session_repository.dart';
import 'class_session.dart';
import 'session_service.dart';

part 'session_generation_service.g.dart';

class SessionGenerationResult {
  final int createdCount;
  final int existingCount;
  final int conflictCount;
  final List<String> warnings;

  const SessionGenerationResult({
    required this.createdCount,
    required this.existingCount,
    required this.conflictCount,
    this.warnings = const [],
  });
}

class SessionGenerationService {
  final SessionRepository _repo;
  final ScheduleDomainService _scheduleService;
  final ClassService _classService;

  SessionGenerationService(
    this._repo,
    this._scheduleService,
    this._classService,
  );

  Future<SessionGenerationResult> generateForClass({
    required int classId,
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    if (toDate.isBefore(fromDate)) {
      throw Exception('Ngày kết thúc không được trước ngày bắt đầu');
    }

    final cls = await _classService.getClassById(classId);
    if (cls == null) throw Exception('Không tìm thấy lớp học');
    if (cls.daLuuTru) {
      throw Exception('Không thể sinh buổi học cho lớp đã lưu trữ');
    }

    final schedules = await _scheduleService.getSchedulesForClass(classId);
    if (schedules.isEmpty) {
      return const SessionGenerationResult(
        createdCount: 0,
        existingCount: 0,
        conflictCount: 0,
        warnings: ['Lớp học chưa có lịch học định kỳ.'],
      );
    }

    int created = 0;
    int existing = 0;
    int conflict = 0;
    final List<String> warnings = [];

    final dateFormat = DateFormat('yyyy-MM-dd');

    // Iterate through each day in range
    for (
      var day = fromDate;
      day.isBefore(toDate.add(const Duration(days: 1)));
      day = day.add(const Duration(days: 1))
    ) {
      final dayStr = dateFormat.format(day);
      final weekday = day.weekday;

      // Find schedules effective on this day and matching this weekday
      final dailySchedules = schedules.where((s) {
        if (s.thuTrongTuan != weekday) return false;
        if (dayStr.compareTo(s.hieuLucTu) < 0) return false;
        if (s.hieuLucDen != null && dayStr.compareTo(s.hieuLucDen!) > 0) {
          return false;
        }
        return true;
      }).toList();

      for (final s in dailySchedules) {
        final existingSession = await _repo.findByClassDateStart(
          classId,
          dayStr,
          s.gioBatDau,
        );

        if (existingSession != null) {
          bool isConflict = false;
          if (existingSession.loai != SessionType.CHINH) {
            isConflict = true;
          } else if (existingSession.idLichHoc != s.id ||
              existingSession.gioKetThuc != s.gioKetThuc) {
            isConflict = true;
          }

          if (isConflict) {
            conflict++;
            warnings.add(
              'Xung đột tại $dayStr ${s.gioBatDau}: Đã có buổi học khác (${existingSession.loai.name}).',
            );
          } else {
            existing++;
          }
          continue;
        }

        // Create new session snapshotting the schedule times
        await _repo.create(
          ClassSession(
            idLop: classId,
            idLichHoc: s.id,
            ngay: dayStr,
            gioBatDau: s.gioBatDau,
            gioKetThuc: s.gioKetThuc,
            loai: SessionType.CHINH,
            trangThai: SessionStatus.DU_KIEN,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
        created++;
      }
    }

    return SessionGenerationResult(
      createdCount: created,
      existingCount: existing,
      conflictCount: conflict,
      warnings: warnings,
    );
  }
}

@Riverpod(keepAlive: true)
Future<SessionGenerationService> sessionGenerationService(
  SessionGenerationServiceRef ref,
) async {
  final repo = await ref.watch(sessionRepositoryProvider.future);
  final scheduleService = await ref.watch(classScheduleServiceProvider.future);
  final classService = await ref.watch(classServiceProvider.future);
  return SessionGenerationService(repo, scheduleService, classService);
}
