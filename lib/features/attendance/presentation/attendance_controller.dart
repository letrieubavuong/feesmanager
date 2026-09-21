import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../roster/domain/roster_member.dart';
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

  bool get hasDirtyDraft => _draft != null;

  AttendanceState effectiveStateFor(int studentId) {
    return _draft?[studentId] ??
        state.value?.members
            .where((m) => m.rosterMember.student.id == studentId)
            .firstOrNull
            ?.state ??
        AttendanceState.CHUA_DIEM_DANH;
  }

  void _ensureDraft() {
    if (_draft == null && state.hasValue) {
      _draft = {
        for (var m in state.value!.members) m.rosterMember.student.id!: m.state,
      };
    }
  }

  void updateLocalDraft(int studentId, AttendanceState newState) {
    _ensureDraft();
    final currentDraft = Map<int, AttendanceState>.from(_draft!);
    currentDraft[studentId] = newState;
    _draft = currentDraft;
    ref.notifyListeners();
  }

  void markAllPresent() {
    if (!state.hasValue) return;
    _ensureDraft();
    final currentDraft = Map<int, AttendanceState>.from(_draft!);
    for (var m in state.value!.members) {
      currentDraft[m.rosterMember.student.id!] = AttendanceState.CO_MAT;
    }
    _draft = currentDraft;
    ref.notifyListeners();
  }

  void markAllHocBu() {
    if (!state.hasValue) return;
    _ensureDraft();
    final currentDraft = Map<int, AttendanceState>.from(_draft!);
    for (var m in state.value!.members) {
      if (m.rosterMember.source == RosterInclusionSource.HOC_BU) {
        currentDraft[m.rosterMember.student.id!] = AttendanceState.HOC_BU;
      }
    }
    _draft = currentDraft;
    ref.notifyListeners();
  }

  void undoChanges() {
    _draft = null;
    ref.notifyListeners();
  }

  Future<void> reload() async {
    final service = await ref.read(attendanceServiceProvider.future);
    _draft = null;
    final newSheet = await service.getAttendanceForSession(sessionId);
    state = AsyncValue.data(newSheet);
  }

  int unresolvedCountFromDraft() {
    if (_draft != null) {
      return _draft!.values
          .where((v) => v == AttendanceState.CHUA_DIEM_DANH)
          .length;
    }
    return state.value?.unresolvedCount ?? 0;
  }

  Future<void> save() async {
    if (_draft == null) return;
    final service = await ref.read(attendanceServiceProvider.future);

    final prevState = state;
    state = const AsyncValue.loading();
    try {
      await service.saveDraft(sessionId, _draft!);
      _draft = null;
      final newSheet = await service.getAttendanceForSession(sessionId);
      state = AsyncValue.data(newSheet);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      if (prevState.hasValue) {
        state = AsyncValue.data(prevState.value!);
      }
      rethrow;
    }
  }

  Future<void> finalize({bool allowIncomplete = false}) async {
    // Save draft first if exists
    if (_draft != null) {
      await save();
    }

    final service = await ref.read(attendanceServiceProvider.future);

    final prevState = state;
    state = const AsyncValue.loading();
    try {
      await service.finalizeSessionAttendance(
        sessionId,
        allowIncomplete: allowIncomplete,
      );
      final newSheet = await service.getAttendanceForSession(sessionId);
      state = AsyncValue.data(newSheet);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      if (prevState.hasValue) {
        state = AsyncValue.data(prevState.value!);
      }
      rethrow;
    }
  }
}
