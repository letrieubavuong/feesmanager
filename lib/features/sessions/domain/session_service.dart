import 'package:intl/intl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/database/database_provider.dart';
import '../../classes/domain/class_service.dart';
import '../data/session_repository.dart';
import 'class_session.dart';

part 'session_service.g.dart';

@Riverpod(keepAlive: true)
Future<SessionRepository> sessionRepository(SessionRepositoryRef ref) async {
  final db = await ref.watch(databaseProvider.future);
  return SessionRepository(db);
}

class SessionService {
  final SessionRepository _repo;
  final ClassService _classService;

  SessionService(this._repo, this._classService);

  Future<ClassSession?> getSessionById(int id) => _repo.getById(id);

  Future<List<ClassSession>> getSessionsForClass(int classId) =>
      _repo.getByClass(classId);

  Future<List<ClassSession>> getSessionsForClassAndRange(
    int classId,
    DateTime from,
    DateTime to,
  ) {
    return _repo.getByClassAndDateRange(
      classId,
      from.toIso8601String().substring(0, 10),
      to.toIso8601String().substring(0, 10),
    );
  }

  Future<void> createManualSession(ClassSession session) async {
    final cls = await _classService.getClassById(session.idLop);
    if (cls == null) throw Exception('Không tìm thấy lớp học');
    if (cls.daLuuTru) {
      throw Exception('Không thể tạo buổi học cho lớp đã lưu trữ');
    }

    if (session.loai == SessionType.CHINH) {
      throw Exception('Vui lòng dùng chức năng Sinh buổi học cho loại CHÍNH.');
    }

    if (session.idLichHoc != null) {
      throw Exception('Buổi học thủ công không được gắn với lịch định kỳ.');
    }

    _validateSession(session);

    final existing = await _repo.findByClassDateStart(
      session.idLop,
      session.ngay,
      session.gioBatDau,
    );
    if (existing != null) {
      throw Exception(
        'Đã tồn tại một buổi học vào lúc ${session.gioBatDau} ngày ${session.ngay}',
      );
    }

    await _repo.create(
      session.copyWith(createdAt: DateTime.now(), updatedAt: DateTime.now()),
    );
  }

  Future<void> updateStatus(int id, SessionStatus status) async {
    final existing = await _repo.getById(id);
    if (existing == null) throw Exception('Không tìm thấy buổi học');

    // DA_HOC is reserved for attendance phase
    if (status == SessionStatus.DA_HOC) {
      throw Exception('Trạng thái ĐÃ HỌC chỉ được cập nhật khi điểm danh.');
    }

    await _repo.update(
      existing.copyWith(trangThai: status, updatedAt: DateTime.now()),
    );
  }

  Future<void> markTaughtFromAttendance(int id) async {
    final existing = await _repo.getById(id);
    if (existing == null) throw Exception('Không tìm thấy buổi học');

    await _repo.update(
      existing.copyWith(
        trangThai: SessionStatus.DA_HOC,
        updatedAt: DateTime.now(),
      ),
    );
  }

  void _validateSession(ClassSession session) {
    // 1. Strict Date Validation (No silent normalization)
    try {
      final parsed = DateFormat('yyyy-MM-dd').parseStrict(session.ngay);
      // Double check canonical format to avoid any extra whitespace or weirdness
      final formatted = DateFormat('yyyy-MM-dd').format(parsed);
      if (formatted != session.ngay) {
        throw Exception('Ngày không ở định dạng canonical YYYY-MM-DD');
      }
    } catch (e) {
      throw Exception('Ngày không hợp lệ hoặc sai định dạng (${session.ngay})');
    }

    // 2. Validate time format HH:mm
    final timeRegExp = RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$');
    if (!timeRegExp.hasMatch(session.gioBatDau)) {
      throw Exception('Định dạng giờ bắt đầu không hợp lệ (HH:mm)');
    }
    if (!timeRegExp.hasMatch(session.gioKetThuc)) {
      throw Exception('Định dạng giờ kết thúc không hợp lệ (HH:mm)');
    }

    // 3. Logical Consistency
    if (session.gioBatDau.compareTo(session.gioKetThuc) >= 0) {
      throw Exception('Giờ kết thúc phải sau giờ bắt đầu');
    }
  }
}

@Riverpod(keepAlive: true)
Future<SessionService> sessionService(SessionServiceRef ref) async {
  final repo = await ref.watch(sessionRepositoryProvider.future);
  final classService = await ref.watch(classServiceProvider.future);
  return SessionService(repo, classService);
}
