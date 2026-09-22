import 'package:intl/intl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
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
import 'tuition_policy_service.dart';
import 'tuition_preview.dart';

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

  TuitionRepository get tuitionRepository => _tuitionRepo;

  TuitionService(
    this._tuitionRepo,
    this._policyService,
    this._creditService,
    this._membershipService,
    this._attendanceRepo,
    this._adjustmentRepo,
    this._sessionRepo,
  );

  Future<TuitionPreview> previewTuition(
    int studentId,
    int classId,
    String month, // YYYY-MM
  ) async {
    _validateIsoMonth(month);

    final monthStart = DateTime.parse('$month-01');
    final monthStartStr = DateFormat('yyyy-MM-dd').format(monthStart);

    final policy = await _policyService.getEffectivePolicyForDateStr(
      classId,
      monthStartStr,
    );

    if (policy == null) {
      throw Exception(
        'Lớp chưa có chính sách học phí có hiệu lực tại tháng $month',
      );
    }

    // Single canonical owner: Consume previewMonth result from SessionCreditService
    final creditSummary = await _creditService.previewMonth(
      studentId,
      classId,
      month,
    );

    // Fetch student class memberships active during month
    final monthEnd = DateTime(monthStart.year, monthStart.month + 1, 0);
    final monthEndStr = DateFormat('yyyy-MM-dd').format(monthEnd);

    final memberships = await _membershipService
        .getMembershipsForStudentAndClass(studentId, classId);

    final activeMembershipsInMonth = memberships.where((m) {
      final den = m.denNgay ?? '9999-12-31';
      return m.tuNgay.compareTo(monthEndStr) <= 0 &&
          den.compareTo(monthStartStr) >= 0;
    }).toList();

    if (activeMembershipsInMonth.isEmpty) {
      throw Exception(
        'Học sinh không có quá trình học hợp lệ tại lớp trong tháng $month',
      );
    }

    // Resolve discount percentage
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

      final attRecord = await _attendanceRepo.getBySessionAndStudent(
        session.id!,
        studentId,
      );

      final attState = attRecord != null
          ? AttendanceState.fromStatus(attRecord.trangThai)
          : AttendanceState.CHUA_DIEM_DANH;

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
          // Check if valid completed makeup session exists
          final hasValidMakeup = await _hasValidMakeupAttendance(
            studentId,
            session.id!,
            classId,
          );

          if (hasValidMakeup) {
            chargeType =
                TuitionCandidateChargeType.CHARGEABLE_EXCUSED_WITH_MAKEUP;
            isCharged = true;
            fee = policy.hocPhiMoiBuoi;
          } else {
            // Usable credit balance as-of this session date minus proposed credit used on/before this session
            final rawBalanceAsOf = await _creditService.getBalanceAsOf(
              studentId,
              classId,
              session.ngay,
            );

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
        } else {
          // Fallback
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
        // Extra session beyond N
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

    final tongTruocGiam = soBuoiTinhPhi * policy.hocPhiMoiBuoi;
    final giamPhanTram = discountPercent;
    final giamSoTien = (tongTruocGiam * giamPhanTram) ~/ 100;
    final amountAfterDiscount = tongTruocGiam - giamSoTien;

    final soTienPhaiThu =
        (policy.hocPhiThangToiDa != null &&
            amountAfterDiscount > policy.hocPhiThangToiDa!)
        ? policy.hocPhiThangToiDa!
        : amountAfterDiscount;

    return TuitionPreview(
      studentId: studentId,
      classId: classId,
      month: month,
      policy: policy,
      soBuoiEligible: soBuoiEligible,
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

  return TuitionService(
    repo,
    policyService,
    creditService,
    membershipService,
    attendanceRepo,
    adjustmentRepo,
    sessionRepo,
  );
}
