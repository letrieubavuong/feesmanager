import 'package:intl/intl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../attendance/data/attendance_repository.dart';
import '../../attendance/domain/attendance_record.dart';
import '../../attendance/domain/attendance_service.dart';
import '../../attendance/domain/attendance_state.dart';
import '../../memberships/domain/membership.dart';
import '../../memberships/domain/membership_service.dart';
import '../../payments/domain/payment_service.dart';
import '../../session_adjustments/data/session_adjustment_repository.dart';
import '../../session_adjustments/domain/session_adjustment.dart';
import '../../session_adjustments/domain/session_adjustment_service.dart';
import '../../session_credits/data/session_credit_repository.dart';
import '../../session_credits/domain/credit_ledger_entry.dart';
import '../../session_credits/domain/credit_ledger_reason.dart';
import '../../session_credits/domain/credit_session_candidate.dart';
import '../../session_credits/domain/monthly_credit_summary.dart';
import '../../session_credits/domain/session_credit_service.dart';
import '../../sessions/data/session_repository.dart';
import '../../sessions/domain/class_session.dart';
import '../../sessions/domain/session_service.dart';
import '../../students/data/student_repository.dart';
import '../../students/domain/student_service.dart';
import '../data/tuition_repository.dart';
import 'class_month_tuition_overview.dart';
import 'tuition_invoice.dart';
import 'tuition_policy_service.dart';
import 'tuition_service.dart';

part 'class_month_tuition_overview_service.g.dart';

class ClassMonthTuitionOverviewService {
  final MembershipService _membershipService;
  final StudentRepository _studentRepo;
  final TuitionPolicyService _policyService;
  final SessionService _sessionService;
  final SessionCreditService _creditService;
  final SessionCreditRepository _creditRepo;
  final AttendanceRepository _attendanceRepo;
  final SessionAdjustmentRepository _adjustmentRepo;
  final SessionRepository _sessionRepo;
  final TuitionRepository _tuitionRepo;
  final PaymentService _paymentService;
  final TuitionService _tuitionService;

  ClassMonthTuitionOverviewService(
    this._membershipService,
    this._studentRepo,
    this._policyService,
    this._sessionService,
    this._creditService,
    this._creditRepo,
    this._attendanceRepo,
    this._adjustmentRepo,
    this._sessionRepo,
    this._tuitionRepo,
    this._paymentService,
    this._tuitionService,
  );

  Future<ClassMonthTuitionOverview> getOverview(
    int classId,
    String month, // YYYY-MM
  ) async {
    // 1. Load class-month memberships ONCE
    final classMonthMemberships = await _membershipService
        .getMembershipsForClassMonth(classId, month);

    // 2. Derive unique studentIds
    final studentIdsSet = classMonthMemberships.map((m) => m.idHocSinh).toSet();
    final studentIds = studentIdsSet.toList();

    // 3. Load students ONCE
    final students = await _studentRepo.getByIds(studentIds);
    final studentMap = {for (final s in students) s.id!: s};

    // 4. Load effective policy ONCE
    final monthStart = DateTime.parse('$month-01');
    final monthStartStr = DateFormat('yyyy-MM-dd').format(monthStart);
    final monthEndDt = DateTime(monthStart.year, monthStart.month + 1, 0);
    final monthEndStr = DateFormat('yyyy-MM-dd').format(monthEndDt);

    final policy = await _policyService.getEffectivePolicyForDateStr(
      classId,
      monthStartStr,
    );

    // 5. Load class sessions ONCE
    final classSessions = await _sessionService.getSessionsForClassAndRange(
      classId,
      monthStart,
      monthEndDt,
    );

    // 6. Build eligibleSessionsByStudent using getEligibleSessionsForStudentsClassMonth()
    final eligibleSessionsByStudent = await _creditService
        .getEligibleSessionsForStudentsClassMonth(
          studentIdsSet,
          classId,
          month,
        );

    // 7. Collect relevant session IDs
    final allClassSessionIds = classSessions.map((s) => s.id!).toList();

    // 8. Load attendance ONCE using getBySessionIds()
    final attendanceList = await _attendanceRepo.getBySessionIds(
      allClassSessionIds,
    );
    final attendanceMap = <String, AttendanceRecord>{
      for (final att in attendanceList)
        '${att.idBuoiHoc}_${att.idHocSinh}': att,
    };

    // 9. Load adjustments for original sessions ONCE
    final adjustments = await _adjustmentRepo.getByOriginalSessionIds(
      allClassSessionIds,
    );
    final makeupAdjustments = adjustments
        .where(
          (a) =>
              a.loai == SessionAdjustmentType.HOC_BU &&
              a.idLopGoc == classId &&
              studentIdsSet.contains(a.idHocSinh),
        )
        .toList();

    // 10. Batch-load makeup target sessions ONCE
    final targetSessionIds = makeupAdjustments
        .map((a) => a.idBuoiHocThamGia)
        .toSet()
        .toList();
    final targetSessions = await _sessionRepo.getByIds(targetSessionIds);
    final targetSessionMap = {for (final s in targetSessions) s.id!: s};

    // 11. Batch-load target attendance together
    final targetAttendanceList = await _attendanceRepo.getBySessionIds(
      targetSessionIds,
    );
    final targetAttendanceMap = <String, AttendanceRecord>{
      for (final att in targetAttendanceList)
        '${att.idBuoiHoc}_${att.idHocSinh}': att,
    };

    // 12. Load credit ledger for all students ONCE
    final ledgerEntries = await _creditRepo
        .getLedgerForClassStudentsThroughDate(classId, studentIds, monthEndStr);
    final ledgerByStudent = <int, List<CreditLedgerEntry>>{};
    for (final entry in ledgerEntries) {
      ledgerByStudent.putIfAbsent(entry.idHocSinh, () => []).add(entry);
    }

    // 13. Load invoices ONCE
    final invoices = await _tuitionRepo.getInvoicesForClassMonth(
      classId,
      month,
    );

    // 14. Load payments for those invoices ONCE
    final paymentSummaryList = await _paymentService
        .getPaymentSummariesForInvoices(invoices);
    final paymentSummaries = {
      for (final summary in paymentSummaryList)
        summary.invoice.idHocSinh: summary,
    };
    final invoiceMap = {for (final inv in invoices) inv.idHocSinh: inv};

    // Group memberships by student for fast lookup
    final membershipsByStudent = <int, List<ClassMembership>>{};
    for (final m in classMonthMemberships) {
      membershipsByStudent.putIfAbsent(m.idHocSinh, () => []).add(m);
    }

    // Group adjustments by student for fast lookup
    final adjustmentsByStudent = <int, List<SessionAdjustment>>{};
    for (final a in makeupAdjustments) {
      adjustmentsByStudent.putIfAbsent(a.idHocSinh, () => []).add(a);
    }

    int previewTotalDue = 0;
    int finalizedTotalDue = 0;
    int totalPaid = 0;
    int remainingDebt = 0;

    int previewStudentCount = 0;
    int finalizedStudentCount = 0;
    int pendingStudentCount = 0;

    final studentRows = <ClassMonthTuitionStudentRow>[];

    // 15 & 16. PER-STUDENT PREPARATION & PURE CALCULATION (ZERO DB QUERIES IN LOOP!)
    for (final sid in studentIds) {
      final student = studentMap[sid];
      if (student == null) continue;

      final invoice = invoiceMap[sid];
      final summary = paymentSummaries[sid];

      if (invoice != null && invoice.trangThai.isFinalizedSnapshot) {
        finalizedStudentCount++;
        finalizedTotalDue += invoice.soTienPhaiThu;
        final pPaid = summary?.totalPaid ?? 0;
        final rDebt = summary?.remainingDebt ?? (invoice.soTienPhaiThu - pPaid);
        totalPaid += pPaid;
        remainingDebt += rDebt;

        ClassStudentTuitionState st;
        if (rDebt <= 0) {
          st = ClassStudentTuitionState.PAID;
        } else if (pPaid > 0) {
          st = ClassStudentTuitionState.PARTIALLY_PAID;
        } else {
          st = ClassStudentTuitionState.FINALIZED_UNPAID;
        }

        studentRows.add(
          ClassMonthTuitionStudentRow(
            student: student,
            invoice: invoice,
            paymentSummary: summary,
            state: st,
          ),
        );
      } else {
        try {
          if (policy == null) {
            throw Exception(
              'Lớp chưa có chính sách học phí có hiệu lực tại tháng $month',
            );
          }

          final studentMemberships = membershipsByStudent[sid] ?? [];
          final activeMembershipsInMonth = studentMemberships.where((m) {
            final den = m.denNgay ?? '9999-12-31';
            return m.tuNgay.compareTo(monthEndStr) <= 0 &&
                den.compareTo(monthStartStr) >= 0;
          }).toList();

          if (activeMembershipsInMonth.isEmpty) {
            throw Exception(
              'Học sinh không có quá trình học hợp lệ tại lớp trong tháng $month',
            );
          }

          final eligibleSessions = eligibleSessionsByStudent[sid] ?? [];
          if (eligibleSessions.isEmpty &&
              classSessions.any((s) =>
                  s.loai == SessionType.CHINH &&
                  s.trangThai == SessionStatus.DA_HOC &&
                  attendanceMap.containsKey('${s.id}_$sid'))) {
            throw Exception(
              'Đã có điểm danh tháng $month nhưng học sinh không thuộc danh sách buổi học hợp lệ. Kiểm tra ngày tham gia lớp và phân ca.',
            );
          }
          final studentLedgerEntries = ledgerByStudent[sid] ?? [];

          final standardLimit = policy.soBuoiChuanThang;
          final candidates = <CreditSessionCandidate>[];
          int potentialEarned = 0;
          int recordedEarned = 0;

          for (int i = 0; i < eligibleSessions.length; i++) {
            final session = eligibleSessions[i];
            final index = i + 1;
            final isStandard = index <= standardLimit;
            final isExtra = index > standardLimit;

            final attRecord = attendanceMap['${session.id}_$sid'];
            final state = attRecord != null
                ? AttendanceState.fromStatus(attRecord.trangThai)
                : AttendanceState.CHUA_DIEM_DANH;

            final earnsCredit =
                isExtra &&
                (state == AttendanceState.CO_MAT ||
                    state == AttendanceState.TRE);

            if (earnsCredit) potentialEarned++;

            final existingEarnedEntry = studentLedgerEntries
                .cast<CreditLedgerEntry?>()
                .firstWhere(
                  (e) =>
                      e != null &&
                      e.idBuoiHoc == session.id &&
                      e.lyDo == CreditLedgerReason.VUOT_SO_BUOI_CHUAN,
                  orElse: () => null,
                );

            if (existingEarnedEntry != null) recordedEarned++;

            candidates.add(
              CreditSessionCandidate(
                session: session,
                index: index,
                isStandard: isStandard,
                isExtra: isExtra,
                attendanceState: state,
                earnsCredit: earnsCredit,
                existingEarnedLedgerEntry: existingEarnedEntry,
              ),
            );
          }

          final dayBeforeMonthStr = DateFormat(
            'yyyy-MM-dd',
          ).format(monthStart.subtract(const Duration(days: 1)));

          final openingBalance = studentLedgerEntries
              .where((e) => e.ngayHieuLuc.compareTo(dayBeforeMonthStr) <= 0)
              .fold<int>(0, (sum, e) => sum + e.delta);

          final monthLedger = studentLedgerEntries.where(
            (e) =>
                e.ngayHieuLuc.compareTo(monthStartStr) >= 0 &&
                e.ngayHieuLuc.compareTo(monthEndStr) <= 0,
          );
          final monthDelta = monthLedger.fold<int>(
            0,
            (sum, e) => sum + e.delta,
          );

          final closingBalance = studentLedgerEntries
              .where((e) => e.ngayHieuLuc.compareTo(monthEndStr) <= 0)
              .fold<int>(0, (sum, e) => sum + e.delta);

          final creditSummary = MonthlyCreditSummary(
            studentId: sid,
            classId: classId,
            month: month,
            standardSessionLimit: standardLimit,
            eligibleCount: eligibleSessions.length,
            standardCount: candidates.where((c) => c.isStandard).length,
            extraCount: candidates.where((c) => c.isExtra).length,
            potentialEarned: potentialEarned,
            recordedEarned: recordedEarned,
            openingBalance: openingBalance,
            monthDelta: monthDelta,
            closingBalance: closingBalance,
            candidates: candidates,
          );

          final validMakeupByOriginalSessionId = <int, bool>{};
          final studentAdjustments = adjustmentsByStudent[sid] ?? [];

          for (final candidate in candidates) {
            if (candidate.isStandard &&
                candidate.attendanceState == AttendanceState.NGHI_CO_PHEP) {
              final origSessionId = candidate.session.id!;
              final adj = studentAdjustments
                  .cast<SessionAdjustment?>()
                  .firstWhere(
                    (a) => a != null && a.idBuoiHocGoc == origSessionId,
                    orElse: () => null,
                  );

              bool isValidMakeup = false;
              if (adj != null &&
                  adj.loai == SessionAdjustmentType.HOC_BU &&
                  adj.idLopGoc == classId &&
                  adj.idHocSinh == sid &&
                  adj.idBuoiHocGoc == origSessionId) {
                final targetSession = targetSessionMap[adj.idBuoiHocThamGia];
                if (targetSession != null &&
                    targetSession.trangThai == SessionStatus.DA_HOC &&
                    targetSession.loai == SessionType.HOC_BU) {
                  final targetAtt =
                      targetAttendanceMap['${targetSession.id}_$sid'];
                  if (targetAtt != null &&
                      targetAtt.trangThai == AttendanceStatus.HOC_BU &&
                      targetAtt.loaiThamGia ==
                          AttendanceParticipationType.HOC_BU &&
                      targetAtt.idBuoiVangGoc == origSessionId &&
                      targetAtt.idLopGoc == classId) {
                    isValidMakeup = true;
                  }
                }
              }

              validMakeupByOriginalSessionId[origSessionId] = isValidMakeup;
            }
          }

          final preview = _tuitionService.calculatePreviewFromResolvedData(
            studentId: sid,
            classId: classId,
            month: month,
            policy: policy,
            creditSummary: creditSummary,
            activeMembershipsInMonth: activeMembershipsInMonth,
            validMakeupByOriginalSessionId: validMakeupByOriginalSessionId,
            studentLedgerEntries: studentLedgerEntries,
          );

          previewStudentCount++;
          previewTotalDue += preview.soTienPhaiThu;

          studentRows.add(
            ClassMonthTuitionStudentRow(
              student: student,
              preview: preview,
              state: ClassStudentTuitionState.PREVIEW_READY,
            ),
          );
        } catch (e) {
          pendingStudentCount++;
          final errMessage = e.toString().replaceAll('Exception: ', '');
          studentRows.add(
            ClassMonthTuitionStudentRow(
              student: student,
              state: errMessage.contains('chính sách')
                  ? ClassStudentTuitionState.ERROR
                  : ClassStudentTuitionState.PENDING_ATTENDANCE,
              pendingReason: errMessage,
            ),
          );
        }
      }
    }

    return ClassMonthTuitionOverview(
      classId: classId,
      month: month,
      previewTotalDue: previewTotalDue,
      finalizedTotalDue: finalizedTotalDue,
      totalPaid: totalPaid,
      remainingDebt: remainingDebt,
      previewStudentCount: previewStudentCount,
      finalizedStudentCount: finalizedStudentCount,
      pendingStudentCount: pendingStudentCount,
      studentRows: studentRows,
    );
  }
}

@Riverpod(keepAlive: true)
Future<ClassMonthTuitionOverviewService> classMonthTuitionOverviewService(
  ClassMonthTuitionOverviewServiceRef ref,
) async {
  final membershipService = await ref.watch(membershipServiceProvider.future);
  final studentRepo = await ref.watch(studentRepositoryProvider.future);
  final policyService = await ref.watch(tuitionPolicyServiceProvider.future);
  final sessionService = await ref.watch(sessionServiceProvider.future);
  final creditService = await ref.watch(sessionCreditServiceProvider.future);
  final creditRepo = await ref.watch(sessionCreditRepositoryProvider.future);
  final attendanceRepo = await ref.watch(attendanceRepositoryProvider.future);
  final adjustmentRepo = await ref.watch(
    sessionAdjustmentRepositoryProvider.future,
  );
  final sessionRepo = await ref.watch(sessionRepositoryProvider.future);
  final tuitionRepo = await ref.watch(tuitionRepositoryProvider.future);
  final paymentService = await ref.watch(paymentServiceProvider.future);
  final tuitionService = await ref.watch(tuitionServiceProvider.future);

  return ClassMonthTuitionOverviewService(
    membershipService,
    studentRepo,
    policyService,
    sessionService,
    creditService,
    creditRepo,
    attendanceRepo,
    adjustmentRepo,
    sessionRepo,
    tuitionRepo,
    paymentService,
    tuitionService,
  );
}
