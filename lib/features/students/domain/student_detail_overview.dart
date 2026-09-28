import '../../attendance/domain/attendance_record.dart';
import '../../classes/domain/class.dart';
import '../../memberships/domain/membership.dart';
import '../../payments/domain/payment.dart';
import '../../schedule_conflicts/domain/schedule_constraint.dart';
import '../../sessions/domain/class_session.dart';
import 'student.dart';

class StudentActiveClassSummary {
  final ClassEntity classEntity;
  final ClassMembership membership;
  final String shiftText;

  const StudentActiveClassSummary({
    required this.classEntity,
    required this.membership,
    required this.shiftText,
  });
}

enum StudentFinancialDisplayState {
  noFinalizedInvoices,
  unpaid,
  partiallyPaid,
  fullyPaid,
  hasUnfinalizedClasses,
}

class StudentMonthFinancialSummary {
  final String month; // YYYY-MM
  final int finalizedDue;
  final int totalPaid;
  final int remainingDebt;
  final int finalizedInvoiceCount;
  final int unfinalizedClassCount;
  final int previewUnfinalizedAmount;
  final StudentFinancialDisplayState state;
  final Payment? latestPayment;

  const StudentMonthFinancialSummary({
    required this.month,
    required this.finalizedDue,
    required this.totalPaid,
    required this.remainingDebt,
    required this.finalizedInvoiceCount,
    required this.unfinalizedClassCount,
    required this.previewUnfinalizedAmount,
    required this.state,
    this.latestPayment,
  });
}

class StudentRecentAttendanceItem {
  final AttendanceRecord attendance;
  final ClassSession session;
  final ClassEntity classEntity;

  const StudentRecentAttendanceItem({
    required this.attendance,
    required this.session,
    required this.classEntity,
  });
}

class StudentDetailOverview {
  final Student student;
  final List<StudentActiveClassSummary> activeClasses;
  final DateTime? firstActiveMembershipDate;
  final StudentMonthFinancialSummary financial;
  final List<StudentRecentAttendanceItem> recentAttendance;
  final List<ScheduleConstraint> activeBusyTimes;

  const StudentDetailOverview({
    required this.student,
    required this.activeClasses,
    this.firstActiveMembershipDate,
    required this.financial,
    required this.recentAttendance,
    required this.activeBusyTimes,
  });
}
