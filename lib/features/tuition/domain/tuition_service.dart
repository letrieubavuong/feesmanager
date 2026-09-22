import 'package:intl/intl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/database/database_provider.dart';
import '../../attendance/data/attendance_repository.dart';
import '../../attendance/domain/attendance_service.dart';
import '../../attendance/domain/attendance_state.dart';
import '../../memberships/domain/membership_service.dart';
import '../../session_adjustments/data/session_adjustment_repository.dart';
import '../../session_adjustments/domain/session_adjustment.dart';
import '../../session_adjustments/domain/session_adjustment_service.dart';
import '../../session_credits/domain/session_credit_service.dart';
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

  TuitionRepository get tuitionRepository => _tuitionRepo;

  TuitionService(
    this._tuitionRepo,
    this._policyService,
    this._creditService,
    this._membershipService,
    this._attendanceRepo,
    this._adjustmentRepo,
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

    final N = policy.soBuoiChuanThang;

    final eligibleSessions = await _creditService
        .getEligibleSessionsForStudentClassMonth(studentId, classId, month);

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

    // Calculate opening credit balance as of day before month start
    final dayBeforeMonth = monthStart.subtract(const Duration(days: 1));
    final openingDateStr = DateFormat('yyyy-MM-dd').format(dayBeforeMonth);
    final creditOpening = await _creditService.getBalanceAsOf(
      studentId,
      classId,
      openingDateStr,
    );

    int availableCredit = creditOpening;
    int creditEarned = 0;

    final candidateDetails = <TuitionSessionCandidateDetail>[];

    for (int i = 0; i < eligibleSessions.length; i++) {
      final session = eligibleSessions[i];
      final index = i + 1; // 1-based index
      final isStandard = index <= N;

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
          // Check if valid makeup session exists
          final makeupAdjustment = await _adjustmentRepo
              .getByStudentAndOriginalSession(studentId, session.id!);

          final hasValidMakeup =
              makeupAdjustment != null &&
              makeupAdjustment.loai == SessionAdjustmentType.HOC_BU;

          if (hasValidMakeup) {
            chargeType =
                TuitionCandidateChargeType.CHARGEABLE_EXCUSED_WITH_MAKEUP;
            isCharged = true;
            fee = policy.hocPhiMoiBuoi;
          } else if (availableCredit > 0) {
            chargeType =
                TuitionCandidateChargeType.CHARGEABLE_EXCUSED_WITH_CREDIT;
            isCharged = true;
            usesCredit = true;
            availableCredit--;
            fee = policy.hocPhiMoiBuoi;
          } else {
            chargeType =
                TuitionCandidateChargeType.NON_CHARGEABLE_EXCUSED_UNCOMPENSATED;
            isCharged = false;
            fee = 0;
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
        final earnsCredit =
            attState == AttendanceState.CO_MAT ||
            attState == AttendanceState.TRE;
        if (earnsCredit) creditEarned++;

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

    final soBuoiEligible = eligibleSessions.length;
    final soBuoiTinhPhi = candidateDetails.where((c) => c.isCharged).length;
    final creditUsed = candidateDetails.where((c) => c.usesCredit).length;
    final creditClosing = creditOpening + creditEarned - creditUsed;

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

  return TuitionService(
    repo,
    policyService,
    creditService,
    membershipService,
    attendanceRepo,
    adjustmentRepo,
  );
}
