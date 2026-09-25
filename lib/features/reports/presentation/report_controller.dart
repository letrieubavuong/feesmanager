import 'package:intl/intl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/report_scope.dart';
import '../domain/report_service.dart';
import '../domain/report_summary.dart';

part 'report_controller.g.dart';

@riverpod
class ReportScopeNotifier extends _$ReportScopeNotifier {
  @override
  ReportScope build() {
    final now = DateTime.now();
    final currentMonth = DateFormat('yyyy-MM').format(now);
    return ReportScope.forMonth(month: currentMonth);
  }

  void setScope(ReportScope scope) {
    state = scope;
  }

  void setMonth(String month) {
    state = ReportScope.forMonth(
      month: month,
      classId: state.classId,
      studentId: state.studentId,
    );
  }

  void setCustomRange(String fromDate, String toDate) {
    state = ReportScope.customRange(
      fromDate: fromDate,
      toDate: toDate,
      classId: state.classId,
      studentId: state.studentId,
    );
  }

  void setClassFilter(int? classId) {
    state = state.copyWith(classId: classId, clearClass: classId == null);
  }

  void setStudentFilter(int? studentId) {
    state = state.copyWith(
      studentId: studentId,
      clearStudent: studentId == null,
    );
  }
}

@riverpod
Future<ReportSummary> reportSummary(ReportSummaryRef ref) async {
  final scope = ref.watch(reportScopeNotifierProvider);
  final service = await ref.watch(reportServiceProvider.future);
  return service.generateReport(scope);
}
