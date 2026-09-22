// ignore_for_file: constant_identifier_names

import '../../sessions/domain/class_session.dart';
import '../../attendance/domain/attendance_state.dart';
import 'tuition_policy.dart';

enum TuitionCandidateChargeType {
  CHARGEABLE_ATTENDED, // CO_MAT or TRE
  CHARGEABLE_UNEXCUSED_ABSENCE, // NGHI_KHONG_PHEP
  CHARGEABLE_EXCUSED_WITH_MAKEUP, // NGHI_CO_PHEP + valid makeup
  CHARGEABLE_EXCUSED_WITH_CREDIT, // NGHI_CO_PHEP + credit used
  NON_CHARGEABLE_EXCUSED_UNCOMPENSATED, // NGHI_CO_PHEP without makeup or credit
  NON_CHARGEABLE_EXTRA_SESSION, // Extra session beyond N
}

class TuitionSessionCandidateDetail {
  final ClassSession session;
  final int index; // 1-based index among eligible sessions
  final bool isStandard;
  final bool isExtra;
  final AttendanceState attendanceState;
  final TuitionCandidateChargeType chargeType;
  final bool isCharged;
  final bool usesCredit;
  final int fee;

  TuitionSessionCandidateDetail({
    required this.session,
    required this.index,
    required this.isStandard,
    required this.isExtra,
    required this.attendanceState,
    required this.chargeType,
    required this.isCharged,
    required this.usesCredit,
    required this.fee,
  });
}

class TuitionPreview {
  final int studentId;
  final int classId;
  final String month; // YYYY-MM
  final TuitionPolicy policy;
  final int soBuoiEligible;
  final int soBuoiTinhPhi;
  final int creditOpening;
  final int creditEarned;
  final int creditUsed;
  final int creditClosing;
  final int tongTruocGiam;
  final int giamPhanTram;
  final int giamSoTien;
  final int soTienPhaiThu;
  final List<TuitionSessionCandidateDetail> candidates;

  TuitionPreview({
    required this.studentId,
    required this.classId,
    required this.month,
    required this.policy,
    required this.soBuoiEligible,
    required this.soBuoiTinhPhi,
    required this.creditOpening,
    required this.creditEarned,
    required this.creditUsed,
    required this.creditClosing,
    required this.tongTruocGiam,
    required this.giamPhanTram,
    required this.giamSoTien,
    required this.soTienPhaiThu,
    required this.candidates,
  });
}
