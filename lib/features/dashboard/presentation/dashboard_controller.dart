import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/dashboard_overview.dart';
import '../domain/dashboard_service.dart';

part 'dashboard_controller.g.dart';

@riverpod
class DashboardController extends _$DashboardController {
  @override
  FutureOr<DashboardOverview> build() async {
    final service = await ref.watch(dashboardServiceProvider.future);
    return service.getOverview();
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}
