import 'report_scope.dart';

class AttendanceReportSummary {
  final int totalSessions; // Actual completed session count
  final int totalEligibleParticipations; // Student-attendance opportunities
  final int totalPresent;
  final int totalLate;
  final int totalExcusedAbsence;
  final int totalUnexcusedAbsence;
  final double attendanceRatePercentage;

  const AttendanceReportSummary({
    required this.totalSessions,
    required this.totalEligibleParticipations,
    required this.totalPresent,
    required this.totalLate,
    required this.totalExcusedAbsence,
    required this.totalUnexcusedAbsence,
    required this.attendanceRatePercentage,
  });

  factory AttendanceReportSummary.zero() => const AttendanceReportSummary(
    totalSessions: 0,
    totalEligibleParticipations: 0,
    totalPresent: 0,
    totalLate: 0,
    totalExcusedAbsence: 0,
    totalUnexcusedAbsence: 0,
    attendanceRatePercentage: 0.0,
  );
}

class FinancialReportSummary {
  final int totalInvoiced;
  final int totalPaid;
  final int totalOutstandingDebt;

  const FinancialReportSummary({
    required this.totalInvoiced,
    required this.totalPaid,
    required this.totalOutstandingDebt,
  });

  factory FinancialReportSummary.zero() => const FinancialReportSummary(
    totalInvoiced: 0,
    totalPaid: 0,
    totalOutstandingDebt: 0,
  );
}

class ClassReportSummary {
  final int classId;
  final String className;
  final int studentCountInScope;
  final AttendanceReportSummary attendance;
  final FinancialReportSummary financial;

  const ClassReportSummary({
    required this.classId,
    required this.className,
    required this.studentCountInScope,
    required this.attendance,
    required this.financial,
  });
}

class StudentReportSummary {
  final int studentId;
  final String studentName;
  final List<String> enrolledClassNames;
  final AttendanceReportSummary attendance;
  final FinancialReportSummary financial;

  const StudentReportSummary({
    required this.studentId,
    required this.studentName,
    required this.enrolledClassNames,
    required this.attendance,
    required this.financial,
  });
}

class ReportSummary {
  final ReportScope scope;
  final DateTime generatedAt;
  final AttendanceReportSummary attendance;
  final FinancialReportSummary financial;
  final List<ClassReportSummary> classSummaries;
  final List<StudentReportSummary> studentSummaries;

  const ReportSummary({
    required this.scope,
    required this.generatedAt,
    required this.attendance,
    required this.financial,
    required this.classSummaries,
    required this.studentSummaries,
  });

  bool get isEmpty =>
      attendance.totalEligibleParticipations == 0 &&
      financial.totalInvoiced == 0 &&
      financial.totalPaid == 0 &&
      classSummaries.isEmpty &&
      studentSummaries.isEmpty;
}
