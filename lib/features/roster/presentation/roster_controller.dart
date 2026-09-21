import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/roster_service.dart';
import '../domain/roster_result.dart';

part 'roster_controller.g.dart';

@riverpod
Future<RosterResult> sessionRoster(SessionRosterRef ref, int sessionId) async {
  final service = await ref.watch(rosterServiceProvider.future);
  return service.getRosterForSession(sessionId);
}
