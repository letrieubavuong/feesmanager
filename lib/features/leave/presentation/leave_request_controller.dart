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
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await service.createLeaveRequest(request);
      return service.getByClass(request.idLop);
    });
  }

  Future<void> approve(int requestId) async {
    final service = await ref.read(leaveRequestServiceProvider.future);
    final req = await service.getById(requestId);
    if (req == null) return;

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await service.updateStatus(requestId, LeaveRequestStatus.DA_DUYET);
      return service.getByClass(req.idLop);
    });
  }

  Future<void> reject(int requestId) async {
    final service = await ref.read(leaveRequestServiceProvider.future);
    final req = await service.getById(requestId);
    if (req == null) return;

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await service.updateStatus(requestId, LeaveRequestStatus.TU_CHOI);
      return service.getByClass(req.idLop);
    });
  }
}
