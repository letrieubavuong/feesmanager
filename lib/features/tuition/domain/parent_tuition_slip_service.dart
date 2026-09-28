import 'package:intl/intl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../attendance/data/attendance_repository.dart';
import '../../attendance/domain/attendance_record.dart';
import '../../attendance/domain/attendance_service.dart';
import '../../classes/domain/class_service.dart';
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

    // 1. Policy & Limits
    final policyDateStr = '$month-01';
    final policy = await _policyService.getEffectivePolicyForDateStr(
      classId,
      policyDateStr,
    );

    final standardSessionLimit = policy?.soBuoiChuanThang ?? 12;
    final feePerSession = policy?.hocPhiMoiBuoi ?? 0;
    final monthlyMaxFee = policy?.hocPhiThangToiDa;

    // 2. Projected Sessions in Month
    final monthSessions = await _sessionService.getSessionsForMonth(
      classId,
      month,
    );

    final candidateSessions = monthSessions
        .where(
          (s) =>
              s.loai == SessionType.CHINH &&
              s.trangThai != SessionStatus.HUY &&
              s.trangThai != SessionStatus.NGHI_LE,
        )
        .toList();

    if (candidateSessions.isEmpty) {
      final classSchedules = await _scheduleService.getSchedulesForClass(
        classId,
      );
      final activeSchedules = classSchedules
          .where(
            (s) =>
                s.hieuLucDen == null ||
                s.hieuLucDen!.compareTo('$month-01') >= 0,
          )
          .toList();
      if (activeSchedules.isNotEmpty) {
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
    }

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
    final monthStart = DateTime.parse('$month-01');
    final dayBeforeMonth = monthStart.subtract(const Duration(days: 1));
    final dayBeforeStr = DateFormat('yyyy-MM-dd').format(dayBeforeMonth);

    final openingCreditBalance = await _creditService.getBalanceAsOf(
      studentId,
      classId,
      dayBeforeStr,
    );

    // 4. Attendance & Absences (Only completed DA_HOC sessions in month)
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final completedSessions = monthSessions
        .where(
          (s) =>
              s.trangThai == SessionStatus.DA_HOC &&
              s.ngay.compareTo(todayStr) <= 0,
        )
        .toList();

    int presentCount = 0;
    int lateCount = 0;
    int excusedAbsenceCount = 0;
    int unexcusedAbsenceCount = 0;
    int makeupCompletedCount = 0;

    DateTime? latestAttendanceDate;

    for (final session in completedSessions) {
      final roster = await _rosterService.getBaseRosterForSession(session.id!);
      final isMember = roster.participants.any(
        (p) => p.student.id == studentId,
      );
      if (!isMember) continue;

      final attRecord = await _attendanceRepo.getBySessionAndStudent(
        session.id!,
        studentId,
      );

      if (attRecord != null) {
        final sessionDate = DateTime.tryParse(session.ngay);
        if (sessionDate != null &&
            (latestAttendanceDate == null ||
                sessionDate.isAfter(latestAttendanceDate))) {
          latestAttendanceDate = sessionDate;
        }

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

    final asOfDate = latestAttendanceDate ?? DateTime.now();
    final attendanceAsOfDate = DateFormat('dd/MM/yyyy').format(asOfDate);

    // 5. Financial Section
    final invoice = await _invoiceService.getInvoice(studentId, classId, month);
    if (invoice == null || !invoice.trangThai.isFinalizedSnapshot) {
      return ParentTuitionSlip(
        studentId: studentId,
        classId: classId,
        month: month,
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
        attendanceAsOfDate: attendanceAsOfDate,
        bank: bankSettings,
      );
    }

    final summary = await _paymentService.getPaymentSummary(
      studentId,
      classId,
      month,
    );

    final amountDue = summary?.amountDue ?? invoice.soTienPhaiThu;
    final totalPaid = summary?.totalPaid ?? 0;
    final remainingDebt = summary?.remainingDebt ?? (amountDue - totalPaid);

    // 6. Transfer Content & QR
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
      attendanceAsOfDate: attendanceAsOfDate,
      amountDue: amountDue,
      totalPaid: totalPaid,
      remainingDebt: remainingDebt,
      bank: bankSettings,
      transferContent: transferContent,
      qrPayload: qrPayload,
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
  );
}
