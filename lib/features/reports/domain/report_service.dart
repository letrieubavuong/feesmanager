import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/database/database_provider.dart';
import '../../attendance/data/attendance_repository.dart';
import '../../attendance/domain/attendance_record.dart';
import '../../classes/domain/class_service.dart';
import '../../memberships/domain/membership_service.dart';
import '../../payments/data/payment_repository.dart';
import '../../roster/domain/roster_service.dart';
import '../../sessions/data/session_repository.dart';
import '../../students/domain/student_service.dart';
import '../../tuition/data/tuition_repository.dart';
import 'report_scope.dart';
import 'report_summary.dart';

part 'report_service.g.dart';

@Riverpod(keepAlive: true)
Future<ReportService> reportService(ReportServiceRef ref) async {
  final db = await ref.watch(databaseProvider.future);
  final classService = await ref.watch(classServiceProvider.future);
  final studentService = await ref.watch(studentServiceProvider.future);
  final membershipService = await ref.watch(membershipServiceProvider.future);
  final rosterService = await ref.watch(rosterServiceProvider.future);
  final sessionRepo = SessionRepository(db);
  final attendanceRepo = AttendanceRepository(db);
  final tuitionRepo = TuitionRepository(db);
  final paymentRepo = PaymentRepository(db);

  return ReportService(
    classService,
    studentService,
    membershipService,
    sessionRepo,
    rosterService,
    attendanceRepo,
    tuitionRepo,
    paymentRepo,
  );
}

class ReportService {
  final ClassService _classService;
  final StudentService _studentService;
  final MembershipService _membershipService;
  final SessionRepository _sessionRepo;
  final RosterService _rosterService;
  final AttendanceRepository _attendanceRepo;
  final TuitionRepository _tuitionRepo;
  final PaymentRepository _paymentRepo;

  ReportService(
    this._classService,
    this._studentService,
    this._membershipService,
    this._sessionRepo,
    this._rosterService,
    this._attendanceRepo,
    this._tuitionRepo,
    this._paymentRepo,
  );

  Future<ReportSummary> generateReport(ReportScope scope) async {
    final fromMonth = scope.fromDate.substring(0, 7);
    final toMonth = scope.toDate.substring(0, 7);

    // 1. Query sessions in date range
    final sessions = await _sessionRepo.getByDateRange(
      fromDate: scope.fromDate,
      toDate: scope.toDate,
      classId: scope.classId,
    );

    int totalEligible = 0;
    int totalPresent = 0;
    int totalExcused = 0;
    int totalUnexcused = 0;

    final classAttendanceMap = <int, _AttendanceAccumulator>{};
    final studentAttendanceMap = <int, _AttendanceAccumulator>{};

    for (final s in sessions) {
      final roster = await _rosterService.getRosterForSession(s.id!);
      final records = await _attendanceRepo.getBySession(s.id!);
      final recordMap = {for (var r in records) r.idHocSinh: r};

      for (final p in roster.participants) {
        final stId = p.student.id!;
        if (scope.studentId != null && stId != scope.studentId) continue;

        totalEligible++;
        final classAcc = classAttendanceMap.putIfAbsent(
          s.idLop,
          () => _AttendanceAccumulator(),
        );
        final studentAcc = studentAttendanceMap.putIfAbsent(
          stId,
          () => _AttendanceAccumulator(),
        );

        classAcc.eligible++;
        studentAcc.eligible++;

        final rec = recordMap[stId];
        if (rec != null) {
          switch (rec.trangThai) {
            case AttendanceStatus.CO_MAT:
            case AttendanceStatus.TRE:
            case AttendanceStatus.HOC_BU:
              totalPresent++;
              classAcc.present++;
              studentAcc.present++;
              break;
            case AttendanceStatus.NGHI_CO_PHEP:
              totalExcused++;
              classAcc.excused++;
              studentAcc.excused++;
              break;
            case AttendanceStatus.NGHI_KHONG_PHEP:
              totalUnexcused++;
              classAcc.unexcused++;
              studentAcc.unexcused++;
              break;
          }
        }
      }
    }

    final overallAttendanceRate = totalEligible > 0
        ? (totalPresent / totalEligible) * 100
        : 0.0;

    final attendanceSummary = AttendanceReportSummary(
      totalEligibleSessions: totalEligible,
      totalPresent: totalPresent,
      totalExcusedAbsence: totalExcused,
      totalUnexcusedAbsence: totalUnexcused,
      attendanceRatePercentage: overallAttendanceRate,
    );

    // 2. Query finalized invoices in month range
    final invoices = await _tuitionRepo.getInvoicesInMonthRange(
      fromMonth: fromMonth,
      toMonth: toMonth,
      classId: scope.classId,
      studentId: scope.studentId,
    );

    int totalInvoiced = 0;
    int totalOutstandingDebt = 0;

    final classInvoicedMap = <int, int>{};
    final classDebtMap = <int, int>{};
    final studentInvoicedMap = <int, int>{};
    final studentDebtMap = <int, int>{};

    for (final inv in invoices) {
      final invAmount = inv.soTienPhaiThu;
      totalInvoiced += invAmount;

      classInvoicedMap[inv.idLop] =
          (classInvoicedMap[inv.idLop] ?? 0) + invAmount;
      studentInvoicedMap[inv.idHocSinh] =
          (studentInvoicedMap[inv.idHocSinh] ?? 0) + invAmount;

      final totalPaidForInv = await _paymentRepo.getTotalPaidForInvoice(
        inv.id!,
      );
      final invDebt = (invAmount - totalPaidForInv).clamp(0, invAmount);

      totalOutstandingDebt += invDebt;
      classDebtMap[inv.idLop] = (classDebtMap[inv.idLop] ?? 0) + invDebt;
      studentDebtMap[inv.idHocSinh] =
          (studentDebtMap[inv.idHocSinh] ?? 0) + invDebt;
    }

    // 3. Query actual payments in date range (actual cash revenue received)
    final payments = await _paymentRepo.getPaymentsInDateRange(
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

    // 4. Build Class Summaries
    final classSummaries = <ClassReportSummary>[];
    final classes = await _classService.getClasses();
    final filteredClasses = scope.classId == null
        ? classes
        : classes.where((c) => c.id == scope.classId).toList();

    for (final cls in filteredClasses) {
      final cId = cls.id!;
      final targetDate = DateTime.tryParse(scope.toDate) ?? DateTime.now();
      final activeMemberships = await _membershipService
          .getActiveMembershipsOnDate(targetDate);
      final classActiveMemberships = activeMemberships
          .where((m) => m.idLop == cId)
          .toList();

      final cAcc = classAttendanceMap[cId] ?? _AttendanceAccumulator();
      final cAttRate = cAcc.eligible > 0
          ? (cAcc.present / cAcc.eligible) * 100
          : 0.0;

      classSummaries.add(
        ClassReportSummary(
          classId: cId,
          className: cls.tenLop,
          activeStudentCount: classActiveMemberships.length,
          attendance: AttendanceReportSummary(
            totalEligibleSessions: cAcc.eligible,
            totalPresent: cAcc.present,
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

    // 5. Build Student Summaries
    final studentSummaries = <StudentReportSummary>[];
    final students = await _studentService.getStudents();
    final filteredStudents = scope.studentId == null
        ? students
        : students.where((s) => s.id == scope.studentId).toList();

    for (final st in filteredStudents) {
      final stId = st.id!;
      final sAcc = studentAttendanceMap[stId] ?? _AttendanceAccumulator();

      final hasActivity =
          sAcc.eligible > 0 ||
          (studentInvoicedMap[stId] ?? 0) > 0 ||
          (studentPaidMap[stId] ?? 0) > 0;

      if (scope.studentId == null && !hasActivity) continue;

      final memberships = await _membershipService.getMembershipHistory(stId);
      final enrolledClassNames = <String>[];
      for (final m in memberships) {
        final c = await _classService.getClassById(m.idLop);
        if (c != null && !enrolledClassNames.contains(c.tenLop)) {
          enrolledClassNames.add(c.tenLop);
        }
      }

      final sAttRate = sAcc.eligible > 0
          ? (sAcc.present / sAcc.eligible) * 100
          : 0.0;

      studentSummaries.add(
        StudentReportSummary(
          studentId: stId,
          studentName: st.hoTen,
          enrolledClassNames: enrolledClassNames,
          attendance: AttendanceReportSummary(
            totalEligibleSessions: sAcc.eligible,
            totalPresent: sAcc.present,
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
  int eligible = 0;
  int present = 0;
  int excused = 0;
  int unexcused = 0;
}
