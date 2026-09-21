import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/leave_request.dart';
import '../domain/leave_request_service.dart';

part 'leave_request_controller.g.dart';

@riverpod
class LeaveRequestController extends _$LeaveRequestController {
  @override
  FutureOr<List<LeaveRequest>> build(int classId) async {
    final service = await ref.watch(leaveRequestServiceProvider.future);
    return service.getByClass(classId);
  }

  Future<void> createLeaveRequest(LeaveRequest request) async {
    final service = await ref.read(leaveRequestServiceProvider.future);
    try {
      await service.createLeaveRequest(request);
      state = AsyncData(await service.getByClass(request.idLop));
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> approve(int requestId) async {
    final service = await ref.read(leaveRequestServiceProvider.future);
    final req = await service.getById(requestId);
    if (req == null) return;

    try {
      await service.updateStatus(requestId, LeaveRequestStatus.DA_DUYET);
      state = AsyncData(await service.getByClass(req.idLop));
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> reject(int requestId) async {
    final service = await ref.read(leaveRequestServiceProvider.future);
    final req = await service.getById(requestId);
    if (req == null) return;

    try {
      await service.updateStatus(requestId, LeaveRequestStatus.TU_CHOI);
      state = AsyncData(await service.getByClass(req.idLop));
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}
