import '../../attendance/domain/attendance_state.dart';
import '../../sessions/domain/class_session.dart';
import 'credit_ledger_entry.dart';

class CreditSessionCandidate {
  final ClassSession session;
  final int index; // 1-based index among eligible sessions
  final bool isStandard;
  final bool isExtra;
  final AttendanceState attendanceState;
  final bool earnsCredit;
  final CreditLedgerEntry? existingEarnedLedgerEntry;

  const CreditSessionCandidate({
    required this.session,
    required this.index,
    required this.isStandard,
    required this.isExtra,
    required this.attendanceState,
    required this.earnsCredit,
    this.existingEarnedLedgerEntry,
  });
}
