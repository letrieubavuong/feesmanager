import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/attendance_correction_audit_record.dart';
import '../domain/attendance_service.dart';

part 'session_correction_audits_controller.g.dart';

@riverpod
Future<List<AttendanceCorrectionAuditRecord>> sessionCorrectionAudits(
  SessionCorrectionAuditsRef ref,
  int sessionId,
) async {
  final service = await ref.watch(attendanceServiceProvider.future);
  return service.getCorrectionAuditsForSession(sessionId);
}
