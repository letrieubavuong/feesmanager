import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/attendance_service.dart';
import '../domain/attendance_sheet.dart';
import '../domain/attendance_state.dart';

part 'attendance_controller.g.dart';

@riverpod
class AttendanceController extends _$AttendanceController {
  @override
  FutureOr<AttendanceSheet> build(int sessionId) async {
    final service = await ref.watch(attendanceServiceProvider.future);
    return service.getAttendanceForSession(sessionId);
  }

  // Local draft state to avoid DB writes on every radio tap
  Map<int, AttendanceState>? _draft;

  Map<int, AttendanceState> get draft {
    if (_draft == null && state.hasValue) {
      _draft = {
        for (var m in state.value!.members) m.rosterMember.student.id!: m.state,
      };
    }
    return _draft ?? {};
  }

  void updateLocalDraft(int studentId, AttendanceState newState) {
    final currentDraft = Map<int, AttendanceState>.from(draft);
    currentDraft[studentId] = newState;
    _draft = currentDraft;
    ref.notifyListeners();
  }

  void markAllPresent() {
    if (!state.hasValue) return;
    final currentDraft = Map<int, AttendanceState>.from(draft);
    for (var m in state.value!.members) {
      currentDraft[m.rosterMember.student.id!] = AttendanceState.CO_MAT;
    }
    _draft = currentDraft;
    ref.notifyListeners();
  }

  void undoChanges() {
    _draft = null;
    ref.notifyListeners();
  }

  Future<void> save() async {
    if (_draft == null) return;
    final service = await ref.read(attendanceServiceProvider.future);

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await service.saveDraft(sessionId, _draft!);
      _draft = null;
      return service.getAttendanceForSession(sessionId);
    });
  }

  Future<void> finalize({bool allowIncomplete = false}) async {
    // Save draft first if exists
    if (_draft != null) {
      await save();
    }

    final service = await ref.read(attendanceServiceProvider.future);

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await service.finalizeSessionAttendance(
        sessionId,
        allowIncomplete: allowIncomplete,
      );
      return service.getAttendanceForSession(sessionId);
    });
  }
}
