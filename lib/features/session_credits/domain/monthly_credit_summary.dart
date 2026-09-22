import 'credit_session_candidate.dart';

class MonthlyCreditSummary {
  final int studentId;
  final int classId;
  final String month; // YYYY-MM
  final int standardSessionLimit; // Default 12

  final int eligibleCount;
  final int standardCount;
  final int extraCount;

  final int potentialEarned;
  final int recordedEarned;

  final int openingBalance;
  final int monthDelta;
  final int closingBalance;

  final List<CreditSessionCandidate> candidates;

  const MonthlyCreditSummary({
    required this.studentId,
    required this.classId,
    required this.month,
    required this.standardSessionLimit,
    required this.eligibleCount,
    required this.standardCount,
    required this.extraCount,
    required this.potentialEarned,
    required this.recordedEarned,
    required this.openingBalance,
    required this.monthDelta,
    required this.closingBalance,
    required this.candidates,
  });
}
