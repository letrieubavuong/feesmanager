import '../../domain/attendance_sheet.dart';
import '../../domain/attendance_state.dart';

class AttendanceUiSummary {
  final int total;
  final int present;
  final int late;
  final int excused;
  final int unexcused;
  final int makeup;
  final int unresolved;

  const AttendanceUiSummary({
    required this.total,
    required this.present,
    required this.late,
    required this.excused,
    required this.unexcused,
    required this.makeup,
    required this.unresolved,
  });

  factory AttendanceUiSummary.fromMembers({
    required List<AttendanceSheetMember> members,
    required AttendanceState Function(int studentId) getEffectiveState,
  }) {
    int present = 0;
    int late = 0;
    int excused = 0;
    int unexcused = 0;
    int makeup = 0;
    int unresolved = 0;

    for (final m in members) {
      final state = getEffectiveState(m.rosterMember.student.id!);
      switch (state) {
        case AttendanceState.CO_MAT:
          present++;
          break;
        case AttendanceState.TRE:
          late++;
          break;
        case AttendanceState.NGHI_CO_PHEP:
          excused++;
          break;
        case AttendanceState.NGHI_KHONG_PHEP:
          unexcused++;
          break;
        case AttendanceState.HOC_BU:
          makeup++;
          break;
        case AttendanceState.CHUA_DIEM_DANH:
          unresolved++;
          break;
      }
    }

    return AttendanceUiSummary(
      total: members.length,
      present: present,
      late: late,
      excused: excused,
      unexcused: unexcused,
      makeup: makeup,
      unresolved: unresolved,
    );
  }
}
