import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../settings/presentation/bank_account_settings_controller.dart';
import '../domain/parent_tuition_slip.dart';
import '../domain/parent_tuition_slip_service.dart';

part 'parent_tuition_slip_controller.g.dart';

@riverpod
Future<ParentTuitionSlip> parentTuitionSlip(
  ParentTuitionSlipRef ref,
  (int studentId, int classId, String month) arg,
) async {
  final studentId = arg.$1;
  final classId = arg.$2;
  final month = arg.$3;

  final service = await ref.watch(parentTuitionSlipServiceProvider.future);
  final bankSettings = ref.watch(bankAccountSettingsProvider);

  return service.generateSlip(
    studentId: studentId,
    classId: classId,
    month: month,
    bankSettings: bankSettings,
  );
}
