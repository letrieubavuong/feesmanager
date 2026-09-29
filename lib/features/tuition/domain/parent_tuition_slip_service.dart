import 'package:intl/intl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../attendance/data/attendance_repository.dart';
import '../../attendance/domain/attendance_record.dart';
import '../../attendance/domain/attendance_service.dart';
import '../../classes/domain/class_service.dart';
import '../../memberships/domain/membership_service.dart';
import '../../payments/domain/payment_service.dart';
import '../../roster/domain/roster_service.dart';
import '../../schedule/domain/schedule_service.dart';
import '../../sessions/domain/class_session.dart';
import '../../sessions/domain/session_service.dart';
import '../../session_credits/domain/session_credit_service.dart';
import '../../settings/domain/bank_account_settings.dart';
import '../../settings/domain/vietqr_generator.dart';
import '../../students/domain/student_service.dart';
import 'invoice_service.dart';
import 'parent_tuition_slip.dart';
import 'tuition_invoice.dart';
import 'tuition_policy_service.dart';

part 'parent_tuition_slip_service.g.dart';

class ParentTuitionSlipService {
  final StudentService _studentService;
  final ClassService _classService;
  final SessionService _sessionService;
  final RosterService _rosterService;
  final ScheduleDomainService _scheduleService;
  final TuitionPolicyService _policyService;
  final SessionCreditService _creditService;
  final AttendanceRepository _attendanceRepo;
  final InvoiceService _invoiceService;
  final PaymentService _paymentService;
  final MembershipService _membershipService;

  ParentTuitionSlipService(
    this._studentService,
    this._classService,
    this._sessionService,
    this._rosterService,
    this._scheduleService,
    this._policyService,
    this._creditService,
    this._attendanceRepo,
    this._invoiceService,
    this._paymentService,
    this._membershipService,
  );

  Future<ParentTuitionSlip> generateSlip({
    required int studentId,
    required int classId,
    required String month, // YYYY-MM
    required BankAccountSettings bankSettings,
  }) async {
    final student = await _studentService.getStudentById(studentId);
    final cls = await _classService.getClassById(classId);

    if (student == null || cls == null) {
      return ParentTuitionSlip(
        studentId: studentId,
        classId: classId,
        month: month,
        studentName: student?.hoTen ?? 'Học sinh #$studentId',
        className: cls?.tenLop ?? 'Lớp #$classId',
        status: ParentTuitionSlipStatus.error,
        errorMessage: 'Không tìm thấy thông tin học sinh hoặc lớp học',
        bank: bankSettings,
      );
    }

    // 0. Student Membership Check for Billing Month
    final monthParts = month.split('-');
    final year = int.parse(monthParts[0]);
    final monthNum = int.parse(monthParts[1]);
    final monthStart = DateTime(year, monthNum, 1);
    final monthEnd = DateTime(year, monthNum + 1, 0);
    final monthStartStr = DateFormat('yyyy-MM-dd').format(monthStart);
    final monthEndStr = DateFormat('yyyy-MM-dd').format(monthEnd);

    final memberships = await _membershipService
        .getMembershipsForStudentAndClass(studentId, classId);
    final activeMembershipsInMonth = memberships.where((m) {
      final tu = m.tuNgay.length >= 10 ? m.tuNgay.substring(0, 10) : m.tuNgay;
      final den = m.denNgay != null
          ? (m.denNgay!.length >= 10 ? m.denNgay!.substring(0, 10) : m.denNgay!)
          : '9999-12-31';
      return tu.compareTo(monthEndStr) <= 0 &&
          den.compareTo(monthStartStr) >= 0;
    }).toList();

    if (activeMembershipsInMonth.isEmpty) {
      return ParentTuitionSlip(
        studentId: studentId,
        classId: classId,
        month: month,
        studentName: student.hoTen,
        className: cls.tenLop,
        status: ParentTuitionSlipStatus.studentNotEnrolled,
        errorMessage: 'Học sinh không có tham gia lớp trong tháng $month',
        bank: bankSettings,
      );
    }

    if (!bankSettings.isConfigured) {
      return ParentTuitionSlip(
        studentId: studentId,
        classId: classId,
        month: month,
        studentName: student.hoTen,
        className: cls.tenLop,
        status: ParentTuitionSlipStatus.bankNotConfigured,
        errorMessage: 'Chưa thiết lập tài khoản nhận học phí',
        bank: bankSettings,
      );
    }

    // A finalized invoice is the immutable billing source. Its payment slip
    // must remain available even if the recurring schedule or policy changes.
    final finalizedInvoice = await _invoiceService.getInvoice(
      studentId,
      classId,
      month,
    );
    if (finalizedInvoice != null &&
        finalizedInvoice.trangThai.isFinalizedSnapshot) {
      final summary = await _paymentService.getPaymentSummary(
        studentId,
        classId,
        month,
      );
      final amountDue = summary?.amountDue ?? finalizedInvoice.soTienPhaiThu;
      final totalPaid = summary?.totalPaid ?? 0;
      final remainingDebt = summary?.remainingDebt ?? (amountDue - totalPaid);
      final transferContent = VietQrGenerator.formatTransferContent(
        template: bankSettings.transferTemplate,
        studentCode: studentId.toString(),
        studentName: student.hoTen,
        className: cls.tenLop,
        month: month,
      );
      final qrPayload = remainingDebt > 0
          ? VietQrGenerator.generateEmvCoPayload(
              settings: bankSettings,
              amount: remainingDebt,
              transferContent: transferContent,
            )
          : '';
      return ParentTuitionSlip(
        studentId: studentId,
        classId: classId,
        month: month,
        studentName: student.hoTen,
        className: cls.tenLop,
        status: ParentTuitionSlipStatus.ready,
        amountDue: amountDue,
        totalPaid: totalPaid,
        remainingDebt: remainingDebt,
        bank: bankSettings,
        transferContent: transferContent,
        qrPayload: qrPayload,
      );
    }

    // 1. Policy & Limits
    final policy = await _policyService.getEffectivePolicyForDateStr(
      classId,
      monthStartStr,
    );

    if (policy == null) {
      return ParentTuitionSlip(
        studentId: studentId,
        classId: classId,
        month: month,
        studentName: student.hoTen,
        className: cls.tenLop,
        status: ParentTuitionSlipStatus.missingTuitionPolicy,
        errorMessage: 'Chưa có chính sách học phí có hiệu lực tháng $month',
        bank: bankSettings,
      );
    }

    final standardSessionLimit = policy.soBuoiChuanThang;
    final feePerSession = policy.hocPhiMoiBuoi;
    final monthlyMaxFee = policy.hocPhiThangToiDa;

    // 2. Schedule Check & Session Generation Coverage Check
    final classSchedules = await _scheduleService.getSchedulesForClass(classId);
    final activeSchedulesInMonth = classSchedules.where((s) {
      final tu = s.hieuLucTu.length >= 10
          ? s.hieuLucTu.substring(0, 10)
          : s.hieuLucTu;
      final den = s.hieuLucDen != null
          ? (s.hieuLucDen!.length >= 10
                ? s.hieuLucDen!.substring(0, 10)
                : s.hieuLucDen!)
          : '9999-12-31';
      return tu.compareTo(monthEndStr) <= 0 &&
          den.compareTo(monthStartStr) >= 0;
    }).toList();

    final monthSessions = await _sessionService.getSessionsForMonth(
      classId,
      month,
    );

    final generatedChinhSessions = monthSessions
        .where((s) => s.loai == SessionType.CHINH)
        .toList();

    if (activeSchedulesInMonth.isEmpty && generatedChinhSessions.isEmpty) {
      return ParentTuitionSlip(
        studentId: studentId,
        classId: classId,
        month: month,
        studentName: student.hoTen,
        className: cls.tenLop,
        status: ParentTuitionSlipStatus.missingSchedule,
        errorMessage: 'Lớp chưa có lịch học hiệu lực trong tháng này',
        standardSessionLimit: standardSessionLimit,
        feePerSession: feePerSession,
        monthlyMaxFee: monthlyMaxFee,
        bank: bankSettings,
      );
    }

    // Calculate expected schedule occurrences count in month
    int expectedSessionCount = 0;
    for (
      var date = monthStart;
      !date.isAfter(monthEnd);
      date = date.add(const Duration(days: 1))
    ) {
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      for (final schedule in activeSchedulesInMonth) {
        if (schedule.thuTrongTuan == date.weekday) {
          final tu = schedule.hieuLucTu.length >= 10
              ? schedule.hieuLucTu.substring(0, 10)
              : schedule.hieuLucTu;
          final den = schedule.hieuLucDen != null
              ? (schedule.hieuLucDen!.length >= 10
                    ? schedule.hieuLucDen!.substring(0, 10)
                    : schedule.hieuLucDen!)
              : '9999-12-31';
          if (tu.compareTo(dateStr) <= 0 && den.compareTo(dateStr) >= 0) {
            expectedSessionCount++;
          }
        }
      }
    }

    if (expectedSessionCount > 0 &&
        generatedChinhSessions.length < expectedSessionCount) {
      return ParentTuitionSlip(
        studentId: studentId,
        classId: classId,
        month: month,
        studentName: student.hoTen,
        className: cls.tenLop,
        status: ParentTuitionSlipStatus.projectedSessionsNotGenerated,
        errorMessage:
            'Chưa sinh đủ buổi học tháng $month (thiếu ${expectedSessionCount - generatedChinhSessions.length} buổi)',
        standardSessionLimit: standardSessionLimit,
        feePerSession: feePerSession,
        monthlyMaxFee: monthlyMaxFee,
        bank: bankSettings,
      );
    }

    if (generatedChinhSessions.isEmpty) {
      return ParentTuitionSlip(
        studentId: studentId,
        classId: classId,
        month: month,
        studentName: student.hoTen,
        className: cls.tenLop,
        status: ParentTuitionSlipStatus.projectedSessionsNotGenerated,
        errorMessage: 'Chưa sinh buổi học tháng $month',
        standardSessionLimit: standardSessionLimit,
        feePerSession: feePerSession,
        monthlyMaxFee: monthlyMaxFee,
        bank: bankSettings,
      );
    }

    // Candidate teaching sessions for student projected count
    final candidateSessions = monthSessions
        .where(
          (s) =>
              s.loai == SessionType.CHINH &&
              s.trangThai != SessionStatus.HUY &&
              s.trangThai != SessionStatus.NGHI_LE,
        )
        .toList();

    int projectedSessionCount = 0;
    for (final session in candidateSessions) {
      final roster = await _rosterService.getBaseRosterForSession(session.id!);
      if (roster.participants.any((p) => p.student.id == studentId)) {
        projectedSessionCount++;
      }
    }

    final projectedExtraCount = (projectedSessionCount - standardSessionLimit)
        .clamp(0, 9999);

    // 3. Opening Credit Balance as of day before month start
    final dayBeforeMonth = monthStart.subtract(const Duration(days: 1));
    final dayBeforeStr = DateFormat('yyyy-MM-dd').format(dayBeforeMonth);

    final openingCreditBalance = await _creditService.getBalanceAsOf(
      studentId,
      classId,
      dayBeforeStr,
    );

    // 4. Reconciliation Month Attendance Summary (Month PRIOR to billing month)
    final recMonthDate = DateTime(year, monthNum - 1, 1);
    final recMonth = DateFormat('yyyy-MM').format(recMonthDate);

    final recMonthSessions = await _sessionService.getSessionsForMonth(
      classId,
      recMonth,
    );

    final completedRecSessions = recMonthSessions
        .where((s) => s.trangThai == SessionStatus.DA_HOC)
        .toList();

    int presentCount = 0;
    int lateCount = 0;
    int excusedAbsenceCount = 0;
    int unexcusedAbsenceCount = 0;
    int makeupCompletedCount = 0;
    String? reconciliationAsOfDate;

    if (completedRecSessions.isNotEmpty) {
      final sessionMap = {for (final s in completedRecSessions) s.id!: s};
      final completedSessionIds = sessionMap.keys.toList();

      final attRecords = await _attendanceRepo.getByStudentAndSessionIds(
        studentId,
        completedSessionIds,
      );

      final validRecords = attRecords
          .where((r) => r.idLopGoc == classId)
          .toList();

      DateTime? latestDate;

      for (final attRecord in validRecords) {
        final session = sessionMap[attRecord.idBuoiHoc];
        if (session == null) continue;

        final sDate = DateTime.tryParse(session.ngay);
        if (sDate != null &&
            (latestDate == null || sDate.isAfter(latestDate))) {
          latestDate = sDate;
        }

        if (session.loai == SessionType.HOC_BU &&
            attRecord.loaiThamGia == AttendanceParticipationType.HOC_BU &&
            attRecord.trangThai == AttendanceStatus.HOC_BU) {
          makeupCompletedCount++;
        } else {
          switch (attRecord.trangThai) {
            case AttendanceStatus.CO_MAT:
              presentCount++;
              break;
            case AttendanceStatus.TRE:
              lateCount++;
              break;
            case AttendanceStatus.NGHI_CO_PHEP:
              excusedAbsenceCount++;
              break;
            case AttendanceStatus.NGHI_KHONG_PHEP:
              unexcusedAbsenceCount++;
              break;
            case AttendanceStatus.HOC_BU:
              makeupCompletedCount++;
              break;
          }

          if (attRecord.loaiThamGia == AttendanceParticipationType.HOC_BU &&
              attRecord.trangThai != AttendanceStatus.HOC_BU) {
            makeupCompletedCount++;
          }
        }
      }

      if (latestDate != null) {
        reconciliationAsOfDate = DateFormat('dd/MM/yyyy').format(latestDate);
      }
    }

    // No finalized invoice: keep the projection for the in-app explanation,
    // but never issue a payment QR from a provisional amount.
    return ParentTuitionSlip(
      studentId: studentId,
      classId: classId,
      month: month,
      billingMonth: month,
      reconciliationMonth: recMonth,
      studentName: student.hoTen,
      className: cls.tenLop,
      status: ParentTuitionSlipStatus.noInvoiceFinalized,
      errorMessage: 'Chưa chốt học phí tháng $month cho học sinh này',
      projectedSessionCount: projectedSessionCount,
      standardSessionLimit: standardSessionLimit,
      projectedExtraCount: projectedExtraCount,
      feePerSession: feePerSession,
      monthlyMaxFee: monthlyMaxFee,
      openingCreditBalance: openingCreditBalance,
      presentCount: presentCount,
      lateCount: lateCount,
      excusedAbsenceCount: excusedAbsenceCount,
      unexcusedAbsenceCount: unexcusedAbsenceCount,
      makeupCompletedCount: makeupCompletedCount,
      reconciliationAsOfDate: reconciliationAsOfDate,
      bank: bankSettings,
    );
  }
}

@Riverpod(keepAlive: true)
Future<ParentTuitionSlipService> parentTuitionSlipService(
  ParentTuitionSlipServiceRef ref,
) async {
  final studentService = await ref.watch(studentServiceProvider.future);
  final classService = await ref.watch(classServiceProvider.future);
  final sessionService = await ref.watch(sessionServiceProvider.future);
  final rosterService = await ref.watch(rosterServiceProvider.future);
  final scheduleService = await ref.watch(classScheduleServiceProvider.future);
  final policyService = await ref.watch(tuitionPolicyServiceProvider.future);
  final creditService = await ref.watch(sessionCreditServiceProvider.future);
  final attendanceRepo = await ref.watch(attendanceRepositoryProvider.future);
  final invoiceService = await ref.watch(invoiceServiceProvider.future);
  final paymentService = await ref.watch(paymentServiceProvider.future);
  final membershipService = await ref.watch(membershipServiceProvider.future);

  return ParentTuitionSlipService(
    studentService,
    classService,
    sessionService,
    rosterService,
    scheduleService,
    policyService,
    creditService,
    attendanceRepo,
    invoiceService,
    paymentService,
    membershipService,
  );
}
