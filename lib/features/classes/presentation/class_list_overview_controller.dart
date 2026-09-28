import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/class_filter.dart';
import '../domain/class_list_overview.dart';
import '../domain/class_list_overview_service.dart';

part 'class_list_overview_controller.g.dart';

@riverpod
class ClassListOverviewController extends _$ClassListOverviewController {
  ClassFilter _filter = ClassFilter.active;

  @override
  FutureOr<ClassListOverview> build() async {
    final service = await ref.watch(classListOverviewServiceProvider.future);
    return service.getOverview(_filter);
  }

  void setFilter(ClassFilter filter) {
    _filter = filter;
    ref.invalidateSelf();
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}
