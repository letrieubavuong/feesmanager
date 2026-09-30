import 'package:intl/intl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'tuition_invoice.dart';
import '../../../core/database/database_provider.dart';
import '../../attendance/data/attendance_repository.dart';
import '../../attendance/domain/attendance_record.dart';
import '../../attendance/domain/attendance_service.dart';
import '../../attendance/domain/attendance_state.dart';
import '../../memberships/domain/membership_service.dart';
import '../../session_adjustments/data/session_adjustment_repository.dart';
import '../../session_adjustments/domain/session_adjustment.dart';
import '../../session_adjustments/domain/session_adjustment_service.dart';
import '../../session_credits/domain/session_credit_service.dart';
import '../../sessions/data/session_repository.dart';
import '../../sessions/domain/class_session.dart';
import '../../sessions/domain/session_service.dart';
import '../data/tuition_repository.dart';
import '../../memberships/domain/membership.dart';
import '../../roster/domain/roster_service.dart';
import '../../session_credits/domain/credit_ledger_entry.dart';
import '../../session_credits/domain/monthly_credit_summary.dart';
import 'tuition_policy.dart';
import 'tuition_policy_service.dart';
import 'tuition_preview.dart';
import 'tuition_calculator.dart';

part 'tuition_service.g.dart';

@Riverpod(keepAlive: true)
Future<TuitionRepository> tuitionRepository(TuitionRepositoryRef ref) async {
  final db = await ref.watch(databaseProvider.future);
  return TuitionRepository(db);
}

class TuitionService {
  final TuitionRepository _tuitionRepo;
  final TuitionPolicyService _policyService;
  final SessionCreditService _creditService;
  final MembershipService _membershipService;
  final AttendanceRepository _attendanceRepo;
  final SessionAdjustmentRepository _adjustmentRepo;
  final SessionRepository _sessionRepo;
  final RosterService? _rosterService;

  TuitionRepository get tuitionRepository => _tuitionRepo;

  TuitionService(
    this._tuitionRepo,
    this._policyService,
    this._creditService,
    this._membershipService,
    this._attendanceRepo,
    this._adjustmentRepo,
    this._sessionRepo, [
    this._rosterService,
  ]);

  Future<TuitionPreview> previewTuition(
    int studentId,
    int classId,
    String month, // YYYY-MM
  ) async {
    _validateIsoMonth(month);

    final monthStart = DateTime.parse('$month-01');
    final monthStartStr = DateFormat('yyyy-MM-dd').format(monthStart);

    final legacyPolicy = await _policyService.getEffectivePolicyForDateStr(
      classId,
      monthStartStr,
    );
    final centerPolicy =
        await _policyService.getEffectiveCenterPolicyForMonth(month);

    final policy = legacyPolicy ??
        (centerPolicy != null
            ? TuitionPolicy(
                idLop: classId,
                hieuLucTu: centerPolicy.hieuLucTu,
                hieuLucDen: centerPolicy.hieuLucDen,
                soBuoiChuanThang: centerPolicy.soBuoiChuanThang,
                hocPhiMoiBuoi: centerPolicy.hocPhiMoiBuoi,
                hocPhiThangToiDa: centerPolicy.hocPhiThangToiDa,
                quyTacNghiCoPhep: centerPolicy.quyTacNghiCoPhep,
                ghiChu: centerPolicy.ghiChu,
                createdAt: centerPolicy.createdAt,
                updatedAt: centerPolicy.updatedAt,
              )
            : null);

    if (policy == null) {
      throw Exception(
        'Trung tâm hoặc lớp chưa có chính sách học phí có hiệu lực tại tháng $month',
      );
    }

    final creditSummary = await _creditService.previewMonth(
      studentId,
      classId,
      month,
    );

    final monthEnd = DateTime(monthStart.year, monthStart.month + 1, 0);
    final monthEndStr = DateFormat('yyyy-MM-dd').format(monthEnd);

    final memberships = await _membershipService
        .getMembershipsForStudentAndClass(studentId, classId);

    final activeMembershipsInMonth = memberships.where((m) {
      final den = m.denNgay ?? '9999-12-31';
      return m.tuNgay.compareTo(monthEndStr) <= 0 &&
          den.compareTo(monthStartStr) >= 0;
    }).toList();

    final validMakeupByOriginalSessionId = <int, bool>{};
    for (final candidate in creditSummary.candidates) {
      if (candidate.isStandard &&
          candidate.attendanceState == AttendanceState.NGHI_CO_PHEP) {
        final hasValid = await _hasValidMakeupAttendance(
          studentId,
          candidate.session.id!,
          classId,
        );
        validMakeupByOriginalSessionId[candidate.session.id!] = hasValid;
      }
    }

    final studentLedgerEntries = await _creditService.getLedger(
      studentId,
      classId,
    );

    final holidaySessions = <ClassSession>[];
    if (_rosterService != null) {
      final monthSessions = await _sessionRepo.getByClassAndDateRange(
        classId,
        monthStartStr,
        monthEndStr,
      );
      for (final session in monthSessions.where(
        (s) =>
            s.loai == SessionType.CHINH && s.trangThai == SessionStatus.NGHI_LE,
      )) {
        final roster = await _rosterService.getBaseRosterForSession(
          session.id!,
        );
        if (roster.participants.any((p) => p.student.id == studentId)) {
          holidaySessions.add(session);
        }
      }
    }

    return calculatePreviewFromResolvedData(
      studentId: studentId,
      classId: classId,
      month: month,
      policy: policy,
      creditSummary: creditSummary,
      activeMembershipsInMonth: activeMembershipsInMonth,
      validMakeupByOriginalSessionId: validMakeupByOriginalSessionId,
      studentLedgerEntries: studentLedgerEntries,
      holidaySessions: holidaySessions,
    );
  }

  TuitionPreview calculatePreviewFromResolvedData({
    required int studentId,
    required int classId,
    required String month,
    required TuitionPolicy policy,
    required MonthlyCreditSummary creditSummary,
    required List<ClassMembership> activeMembershipsInMonth,
    required Map<int, bool> validMakeupByOriginalSessionId,
    List<CreditLedgerEntry> studentLedgerEntries = const [],
    List<ClassSession> holidaySessions = const [],
  }) {
    if (activeMembershipsInMonth.isEmpty) {
      throw Exception(
        'Học sinh không có quá trình học hợp lệ tại lớp trong tháng $month',
      );
    }

    final discountPercentages = activeMembershipsInMonth
        .map((m) => m.mienGiamPhanTram)
        .toSet();
    if (discountPercentages.length > 1) {
      throw Exception(
        'Không thể xác định tỷ lệ giảm giá duy nhất do học sinh có nhiều khoảng học trong tháng với mức giảm giá khác nhau',
      );
    }
    final discountPercent = discountPercentages.first;

    int proposedCreditUsed = 0;
    final candidateDetails = <TuitionSessionCandidateDetail>[];

    for (final candidate in creditSummary.candidates) {
      final session = candidate.session;
      final index = candidate.index;
      final isStandard = candidate.isStandard;
      final attState = candidate.attendanceState;

      if (isStandard) {
        if (attState == AttendanceState.CHUA_DIEM_DANH) {
          throw Exception(
            'Buổi học (${session.ngay} ${session.gioBatDau}) chưa điểm danh. Không thể tính học phí.',
          );
        }

        TuitionCandidateChargeType chargeType;
        bool isCharged;
        bool usesCredit = false;
        int fee;

        if (attState == AttendanceState.CO_MAT ||
            attState == AttendanceState.TRE) {
          chargeType = TuitionCandidateChargeType.CHARGEABLE_ATTENDED;
          isCharged = true;
          fee = policy.hocPhiMoiBuoi;
        } else if (attState == AttendanceState.NGHI_KHONG_PHEP) {
          chargeType = TuitionCandidateChargeType.CHARGEABLE_UNEXCUSED_ABSENCE;
          isCharged = true;
          fee = policy.hocPhiMoiBuoi;
        } else if (attState == AttendanceState.NGHI_CO_PHEP) {
          if (policy.quyTacNghiCoPhep == ExcusedAbsenceFeeRule.tinhPhi) {
            chargeType =
                TuitionCandidateChargeType.CHARGEABLE_EXCUSED_BY_POLICY;
            isCharged = true;
            fee = policy.hocPhiMoiBuoi;
          } else if (policy.quyTacNghiCoPhep ==
              ExcusedAbsenceFeeRule.khongTinhPhi) {
            chargeType =
                TuitionCandidateChargeType.NON_CHARGEABLE_EXCUSED_UNCOMPENSATED;
            isCharged = false;
            fee = 0;
          } else {
            final hasValidMakeup =
                validMakeupByOriginalSessionId[session.id!] ?? false;

            if (hasValidMakeup) {
              chargeType =
                  TuitionCandidateChargeType.CHARGEABLE_EXCUSED_WITH_MAKEUP;
              isCharged = true;
              fee = policy.hocPhiMoiBuoi;
            } else {
              final rawBalanceAsOf = studentLedgerEntries.isEmpty
                  ? creditSummary.openingBalance
                  : studentLedgerEntries
                        .where(
                          (e) => e.ngayHieuLuc.compareTo(session.ngay) <= 0,
                        )
                        .fold<int>(0, (sum, e) => sum + e.delta);

              final usableCreditAtDate = rawBalanceAsOf - proposedCreditUsed;

              if (usableCreditAtDate > 0) {
                chargeType =
                    TuitionCandidateChargeType.CHARGEABLE_EXCUSED_WITH_CREDIT;
                isCharged = true;
                usesCredit = true;
                proposedCreditUsed++;
                fee = policy.hocPhiMoiBuoi;
              } else {
                chargeType = TuitionCandidateChargeType
                    .NON_CHARGEABLE_EXCUSED_UNCOMPENSATED;
                isCharged = false;
                fee = 0;
              }
            }
          }
        } else {
          chargeType = TuitionCandidateChargeType.CHARGEABLE_ATTENDED;
          isCharged = true;
          fee = policy.hocPhiMoiBuoi;
        }

        candidateDetails.add(
          TuitionSessionCandidateDetail(
            session: session,
            index: index,
            isStandard: true,
            isExtra: false,
            attendanceState: attState,
            chargeType: chargeType,
            isCharged: isCharged,
            usesCredit: usesCredit,
            fee: fee,
          ),
        );
      } else {
        candidateDetails.add(
          TuitionSessionCandidateDetail(
            session: session,
            index: index,
            isStandard: false,
            isExtra: true,
            attendanceState: attState,
            chargeType: TuitionCandidateChargeType.NON_CHARGEABLE_EXTRA_SESSION,
            isCharged: false,
            usesCredit: false,
            fee: 0,
          ),
        );
      }
    }

    holidaySessions.sort((a, b) {
      final byDate = a.ngay.compareTo(b.ngay);
      return byDate != 0 ? byDate : a.gioBatDau.compareTo(b.gioBatDau);
    });
    for (final session in holidaySessions) {
      final rawBalanceAsOf = studentLedgerEntries.isEmpty
          ? creditSummary.openingBalance
          : studentLedgerEntries
                .where(
                  (entry) => entry.ngayHieuLuc.compareTo(session.ngay) <= 0,
                )
                .fold<int>(0, (sum, entry) => sum + entry.delta);
      final usableCreditAtDate = rawBalanceAsOf - proposedCreditUsed;
      if (usableCreditAtDate <= 0) continue;
      proposedCreditUsed++;
      candidateDetails.add(
        TuitionSessionCandidateDetail(
          session: session,
          index: candidateDetails.length + 1,
          isStandard: true,
          isExtra: false,
          attendanceState: AttendanceState.CHUA_DIEM_DANH,
          chargeType: TuitionCandidateChargeType.CHARGEABLE_HOLIDAY_WITH_CREDIT,
          isCharged: true,
          usesCredit: true,
          fee: policy.hocPhiMoiBuoi,
        ),
      );
    }

    final soBuoiEligible = creditSummary.eligibleCount;
    final soBuoiTinhPhi = candidateDetails.where((c) => c.isCharged).length;
    final creditUsed = candidateDetails.where((c) => c.usesCredit).length;

    final creditOpening = creditSummary.openingBalance;
    final creditEarned = creditSummary.potentialEarned;

    if (creditSummary.recordedEarned > creditSummary.potentialEarned) {
      throw Exception(
        'Lỗi bất biến sổ cái: Số buổi dư đã ghi nhận (${creditSummary.recordedEarned}) vượt quá số buổi dư đủ điều kiện (${creditSummary.potentialEarned})',
      );
    }

    final missingEarned =
        creditSummary.potentialEarned - creditSummary.recordedEarned;
    final creditClosing =
        creditSummary.closingBalance + missingEarned - creditUsed;

    final feeResult = calculateTuitionFee(
      sessions: soBuoiTinhPhi,
      standardLimit: policy.soBuoiChuanThang,
      unitPrice: policy.hocPhiMoiBuoi,
      discountPercent: discountPercent,
      monthlyCap: policy.hocPhiThangToiDa,
    );

    final tongTruocGiam = feeResult.grossAmount;
    final giamPhanTram = discountPercent;
    final giamSoTien = feeResult.discountAmount;
    final soTienPhaiThu = feeResult.netAmount;

    return TuitionPreview(
      studentId: studentId,
      classId: classId,
      month: month,
      policy: policy,
      soBuoiEligible: soBuoiEligible,
      soBuoiDuKien: soBuoiEligible + holidaySessions.length,
      soBuoiTinhPhi: soBuoiTinhPhi,
      creditOpening: creditOpening,
      creditEarned: creditEarned,
      creditUsed: creditUsed,
      creditClosing: creditClosing,
      tongTruocGiam: tongTruocGiam,
      giamPhanTram: giamPhanTram,
      giamSoTien: giamSoTien,
      soTienPhaiThu: soTienPhaiThu,
      candidates: candidateDetails,
    );
  }

  Future<bool> _hasValidMakeupAttendance(
    int studentId,
    int originalSessionId,
    int classId,
  ) async {
    final adjustment = await _adjustmentRepo.getByStudentAndOriginalSession(
      studentId,
      originalSessionId,
    );

    if (adjustment == null ||
        adjustment.loai != SessionAdjustmentType.HOC_BU ||
        adjustment.idLopGoc != classId ||
        adjustment.idHocSinh != studentId ||
        adjustment.idBuoiHocGoc != originalSessionId) {
      return false;
    }

    final targetSessionId = adjustment.idBuoiHocThamGia;
    final targetSession = await _sessionRepo.getById(targetSessionId);

    // Target session must exist and be DA_HOC (taught & finalized)
    if (targetSession == null ||
        targetSession.trangThai != SessionStatus.DA_HOC ||
        targetSession.loai != SessionType.HOC_BU) {
      return false;
    }

    // Attendance record in target session
    final targetAtt = await _attendanceRepo.getBySessionAndStudent(
      targetSessionId,
      studentId,
    );

    if (targetAtt == null) return false;

    // Strict fail-closed makeup validation:
    // MUST be AttendanceStatus.HOC_BU and AttendanceParticipationType.HOC_BU
    // MUST have idBuoiVangGoc == originalSessionId and idLopGoc == classId
    if (targetAtt.trangThai != AttendanceStatus.HOC_BU ||
        targetAtt.loaiThamGia != AttendanceParticipationType.HOC_BU ||
        targetAtt.idBuoiVangGoc != originalSessionId ||
        targetAtt.idLopGoc != classId) {
      return false;
    }

    return true;
  }

  Future<List<TuitionInvoice>> getInvoicesByIds(List<int> ids) =>
      _tuitionRepo.getInvoicesByIds(ids);

  Future<List<TuitionInvoice>> getFinalizedInvoicesInMonthRange({
    required String fromMonth,
    required String toMonth,
    int? classId,
    int? studentId,
  }) async {
    _validateIsoMonth(fromMonth);
    _validateIsoMonth(toMonth);
    return _tuitionRepo.getInvoicesInMonthRange(
      fromMonth: fromMonth,
      toMonth: toMonth,
      classId: classId,
      studentId: studentId,
    );
  }

  void _validateIsoMonth(String month) {
    final monthRegExp = RegExp(r'^\d{4}-(0[1-9]|1[0-2])$');
    if (!monthRegExp.hasMatch(month)) {
      throw Exception('Định dạng tháng không hợp lệ (YYYY-MM). Ví dụ: 2026-09');
    }
  }
}

@Riverpod(keepAlive: true)
Future<TuitionService> tuitionService(TuitionServiceRef ref) async {
  final repo = await ref.watch(tuitionRepositoryProvider.future);
  final policyService = await ref.watch(tuitionPolicyServiceProvider.future);
  final creditService = await ref.watch(sessionCreditServiceProvider.future);
  final membershipService = await ref.watch(membershipServiceProvider.future);
  final attendanceRepo = await ref.watch(attendanceRepositoryProvider.future);
  final adjustmentRepo = await ref.watch(
    sessionAdjustmentRepositoryProvider.future,
  );
  final sessionRepo = await ref.watch(sessionRepositoryProvider.future);
  final rosterService = await ref.watch(rosterServiceProvider.future);

  return TuitionService(
    repo,
    policyService,
    creditService,
    membershipService,
    attendanceRepo,
    adjustmentRepo,
    sessionRepo,
    rosterService,
  );
}
