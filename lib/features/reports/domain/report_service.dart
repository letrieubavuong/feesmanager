import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../attendance/domain/attendance_service.dart';
import '../../classes/domain/class_service.dart';
import '../../memberships/domain/membership_service.dart';
import '../../payments/domain/payment_service.dart';
import '../../sessions/domain/session_service.dart';
import '../../students/domain/student_service.dart';
import '../../tuition/domain/tuition_invoice.dart';
import '../../tuition/domain/tuition_service.dart';
import 'report_scope.dart';
import 'report_summary.dart';

part 'report_service.g.dart';

@Riverpod(keepAlive: true)
Future<ReportService> reportService(ReportServiceRef ref) async {
  final classService = await ref.watch(classServiceProvider.future);
  final studentService = await ref.watch(studentServiceProvider.future);
  final membershipService = await ref.watch(membershipServiceProvider.future);
  final sessionService = await ref.watch(sessionServiceProvider.future);
  final attendanceService = await ref.watch(attendanceServiceProvider.future);
  final tuitionService = await ref.watch(tuitionServiceProvider.future);
  final paymentService = await ref.watch(paymentServiceProvider.future);

  return ReportService(
    classService,
    studentService,
    membershipService,
    sessionService,
    attendanceService,
    tuitionService,
    paymentService,
  );
}

class ReportService {
  final ClassService _classService;
  final StudentService _studentService;
  final MembershipService _membershipService;
  final SessionService _sessionService;
  final AttendanceService _attendanceService;
  final TuitionService _tuitionService;
  final PaymentService _paymentService;

  ReportService(
    this._classService,
    this._studentService,
    this._membershipService,
    this._sessionService,
    this._attendanceService,
    this._tuitionService,
    this._paymentService,
  );

  Future<ReportSummary> generateReport(ReportScope scope) async {
    final fromMonth = scope.fromDate.substring(0, 7);
    final toMonth = scope.toDate.substring(0, 7);

    // 1. Load completed sessions only in date range (trangThai == DA_HOC)
    final completedSessions = await _sessionService.getCompletedSessionsInRange(
      fromDate: scope.fromDate,
      toDate: scope.toDate,
      classId: scope.classId,
    );

    int totalParticipations = 0;
    int totalPresent = 0;
    int totalLate = 0;
    int totalExcused = 0;
    int totalUnexcused = 0;

    final overallSessionIds = <int>{};
    final classSessionIdsMap = <int, Set<int>>{};
    final studentSessionIdsMap = <int, Set<int>>{};

    final classAttendanceMap = <int, _AttendanceAccumulator>{};
    final studentAttendanceMap = <int, _AttendanceAccumulator>{};

    for (final s in completedSessions) {
      final sheet = await _attendanceService.getAttendanceForSession(s.id!);

      for (final m in sheet.members) {
        final p = m.rosterMember;
        final stId = p.student.id!;
        if (scope.studentId != null && stId != scope.studentId) continue;

        overallSessionIds.add(s.id!);
        classSessionIdsMap.putIfAbsent(s.idLop, () => <int>{}).add(s.id!);
        studentSessionIdsMap.putIfAbsent(stId, () => <int>{}).add(s.id!);

        totalParticipations++;
        final classAcc = classAttendanceMap.putIfAbsent(
          s.idLop,
          () => _AttendanceAccumulator(),
        );
        final studentAcc = studentAttendanceMap.putIfAbsent(
          stId,
          () => _AttendanceAccumulator(),
        );

        classAcc.participations++;
        studentAcc.participations++;

        final state = m.state;

        if (state.countsAsPresent) {
          totalPresent++;
          classAcc.present++;
          studentAcc.present++;
        }
        if (state.isLate) {
          totalLate++;
          classAcc.lateCount++;
          studentAcc.lateCount++;
        }
        if (state.isExcusedAbsence) {
          totalExcused++;
          classAcc.excused++;
          studentAcc.excused++;
        }
        if (state.isUnexcusedAbsence) {
          totalUnexcused++;
          classAcc.unexcused++;
          studentAcc.unexcused++;
        }
      }
    }

    final overallAttendanceRate = totalParticipations > 0
        ? (totalPresent / totalParticipations) * 100
        : 0.0;

    final attendanceSummary = AttendanceReportSummary(
      totalSessions: overallSessionIds.length,
      totalEligibleParticipations: totalParticipations,
      totalPresent: totalPresent,
      totalLate: totalLate,
      totalExcusedAbsence: totalExcused,
      totalUnexcusedAbsence: totalUnexcused,
      attendanceRatePercentage: overallAttendanceRate,
    );

    // 2. Query finalized invoices in month range & evaluate canonical settlement summaries
    final invoices = await _tuitionService.getFinalizedInvoicesInMonthRange(
      fromMonth: fromMonth,
      toMonth: toMonth,
      classId: scope.classId,
      studentId: scope.studentId,
    );

    final settlementSummaries = await _paymentService
        .getPaymentSummariesForInvoices(invoices);

    int totalInvoiced = 0;
    int totalOutstandingDebt = 0;

    final classInvoicedMap = <int, int>{};
    final classDebtMap = <int, int>{};
    final studentInvoicedMap = <int, int>{};
    final studentDebtMap = <int, int>{};

    for (final summary in settlementSummaries) {
      final inv = summary.invoice;
      final amountDue = summary.amountDue;
      final remainingDebt = summary.remainingDebt;

      totalInvoiced += amountDue;
      totalOutstandingDebt += remainingDebt;

      classInvoicedMap[inv.idLop] =
          (classInvoicedMap[inv.idLop] ?? 0) + amountDue;
      classDebtMap[inv.idLop] = (classDebtMap[inv.idLop] ?? 0) + remainingDebt;

      studentInvoicedMap[inv.idHocSinh] =
          (studentInvoicedMap[inv.idHocSinh] ?? 0) + amountDue;
      studentDebtMap[inv.idHocSinh] =
          (studentDebtMap[inv.idHocSinh] ?? 0) + remainingDebt;
    }

    // 3. Query validated actual cash payments in date range
    final payments = await _paymentService.getValidatedPaymentsInDateRange(
      fromDate: scope.fromDate,
      toDate: scope.toDate,
      classId: scope.classId,
      studentId: scope.studentId,
    );

    int totalPaid = 0;
    final classPaidMap = <int, int>{};
    final studentPaidMap = <int, int>{};

    for (final p in payments) {
      totalPaid += p.amount;
      classPaidMap[p.classId] = (classPaidMap[p.classId] ?? 0) + p.amount;
      studentPaidMap[p.studentId] =
          (studentPaidMap[p.studentId] ?? 0) + p.amount;
    }

    final financialSummary = FinancialReportSummary(
      totalInvoiced: totalInvoiced,
      totalPaid: totalPaid,
      totalOutstandingDebt: totalOutstandingDebt,
    );

    // 4. Collect all distinct active + historical archived class & student IDs in report scope
    final rangeMemberships = await _membershipService
        .getMembershipsOverlappingDateRange(
          fromDate: scope.fromDate,
          toDate: scope.toDate,
          classId: scope.classId,
          studentId: scope.studentId,
        );

    final classIds = <int>{
      ...completedSessions.map((s) => s.idLop),
      ...invoices.map((TuitionInvoice i) => i.idLop),
      ...payments.map((p) => p.classId),
      ...rangeMemberships.map((m) => m.idLop),
    };
    if (scope.classId != null) classIds.add(scope.classId!);

    final studentIds = <int>{
      ...invoices.map((TuitionInvoice i) => i.idHocSinh),
      ...payments.map((p) => p.studentId),
      ...rangeMemberships.map((m) => m.idHocSinh),
      ...studentAttendanceMap.keys,
    };
    if (scope.studentId != null) studentIds.add(scope.studentId!);

    // Batch load classes and students (includes historical archived ones!)
    final classesList = await _classService.getClassesByIds(classIds.toList());
    final studentsList = await _studentService.getStudentsByIds(
      studentIds.toList(),
    );

    // Map memberships by class and by student for range-aware calculations
    final classMembershipsMap = <int, Set<int>>{};
    final studentRangeClassesMap = <int, Set<int>>{};

    for (final m in rangeMemberships) {
      classMembershipsMap.putIfAbsent(m.idLop, () => <int>{}).add(m.idHocSinh);
      studentRangeClassesMap
          .putIfAbsent(m.idHocSinh, () => <int>{})
          .add(m.idLop);
    }

    // 5. Build Class Summaries
    final classSummaries = <ClassReportSummary>[];
    for (final cls in classesList) {
      final cId = cls.id!;
      final cAcc = classAttendanceMap[cId] ?? _AttendanceAccumulator();
      final cAttRate = cAcc.participations > 0
          ? (cAcc.present / cAcc.participations) * 100
          : 0.0;
      final studentCountInScope = classMembershipsMap[cId]?.length ?? 0;
      final classSessionCount = (classSessionIdsMap[cId] ?? {}).length;

      classSummaries.add(
        ClassReportSummary(
          classId: cId,
          className: cls.tenLop,
          studentCountInScope: studentCountInScope,
          attendance: AttendanceReportSummary(
            totalSessions: classSessionCount,
            totalEligibleParticipations: cAcc.participations,
            totalPresent: cAcc.present,
            totalLate: cAcc.lateCount,
            totalExcusedAbsence: cAcc.excused,
            totalUnexcusedAbsence: cAcc.unexcused,
            attendanceRatePercentage: cAttRate,
          ),
          financial: FinancialReportSummary(
            totalInvoiced: classInvoicedMap[cId] ?? 0,
            totalPaid: classPaidMap[cId] ?? 0,
            totalOutstandingDebt: classDebtMap[cId] ?? 0,
          ),
        ),
      );
    }

    // 6. Build Student Summaries
    final studentSummaries = <StudentReportSummary>[];
    for (final st in studentsList) {
      final stId = st.id!;
      final sAcc = studentAttendanceMap[stId] ?? _AttendanceAccumulator();

      final hasActivity =
          sAcc.participations > 0 ||
          (studentInvoicedMap[stId] ?? 0) > 0 ||
          (studentPaidMap[stId] ?? 0) > 0;

      if (scope.studentId == null && !hasActivity) continue;

      // Range-aware enrolled class names
      final enrolledClassIds = studentRangeClassesMap[stId] ?? {};
      final enrolledClasses = classesList
          .where((c) => enrolledClassIds.contains(c.id))
          .map((c) => c.tenLop)
          .toList();

      final sAttRate = sAcc.participations > 0
          ? (sAcc.present / sAcc.participations) * 100
          : 0.0;
      final studentSessionCount = (studentSessionIdsMap[stId] ?? {}).length;

      studentSummaries.add(
        StudentReportSummary(
          studentId: stId,
          studentName: st.hoTen,
          enrolledClassNames: enrolledClasses,
          attendance: AttendanceReportSummary(
            totalSessions: studentSessionCount,
            totalEligibleParticipations: sAcc.participations,
            totalPresent: sAcc.present,
            totalLate: sAcc.lateCount,
            totalExcusedAbsence: sAcc.excused,
            totalUnexcusedAbsence: sAcc.unexcused,
            attendanceRatePercentage: sAttRate,
          ),
          financial: FinancialReportSummary(
            totalInvoiced: studentInvoicedMap[stId] ?? 0,
            totalPaid: studentPaidMap[stId] ?? 0,
            totalOutstandingDebt: studentDebtMap[stId] ?? 0,
          ),
        ),
      );
    }

    return ReportSummary(
      scope: scope,
      generatedAt: DateTime.now(),
      attendance: attendanceSummary,
      financial: financialSummary,
      classSummaries: classSummaries,
      studentSummaries: studentSummaries,
    );
  }
}

class _AttendanceAccumulator {
  int participations = 0;
  int present = 0;
  int lateCount = 0;
  int excused = 0;
  int unexcused = 0;
}
