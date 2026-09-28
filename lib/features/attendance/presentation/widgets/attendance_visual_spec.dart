import 'package:flutter/material.dart';
import '../../../../app/design_system/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/attendance_record.dart';
import '../../domain/attendance_state.dart';

class AttendanceVisualSpec {
  final IconData icon;
  final Color color;
  final String label;

  const AttendanceVisualSpec({
    required this.icon,
    required this.color,
    required this.label,
  });

  static AttendanceVisualSpec forStatus(
    AttendanceStatus? status,
    AppLocalizations l10n,
  ) {
    if (status == null) {
      return AttendanceVisualSpec(
        icon: Icons.help_outline_rounded,
        color: AppColors.textMuted,
        label: l10n.attendanceNotMarked,
      );
    }
    switch (status) {
      case AttendanceStatus.CO_MAT:
        return AttendanceVisualSpec(
          icon: Icons.check_rounded,
          color: AppColors.success,
          label: l10n.attendancePresent,
        );
      case AttendanceStatus.TRE:
        return AttendanceVisualSpec(
          icon: Icons.schedule_rounded,
          color: AppColors.warning,
          label: l10n.attendanceLate,
        );
      case AttendanceStatus.NGHI_CO_PHEP:
        return AttendanceVisualSpec(
          icon: Icons.event_busy_outlined,
          color: AppColors.cyanAccent,
          label: l10n.attendanceExcused,
        );
      case AttendanceStatus.NGHI_KHONG_PHEP:
        return AttendanceVisualSpec(
          icon: Icons.close_rounded,
          color: AppColors.error,
          label: l10n.attendanceUnexcused,
        );
      case AttendanceStatus.HOC_BU:
        return AttendanceVisualSpec(
          icon: Icons.event_repeat_rounded,
          color: AppColors.primary,
          label: l10n.attendanceMakeup,
        );
    }
  }

  static AttendanceVisualSpec forState(
    AttendanceState state,
    AppLocalizations l10n,
  ) {
    switch (state) {
      case AttendanceState.CHUA_DIEM_DANH:
        return AttendanceVisualSpec(
          icon: Icons.help_outline_rounded,
          color: AppColors.textMuted,
          label: l10n.attendanceNotMarked,
        );
      case AttendanceState.CO_MAT:
        return AttendanceVisualSpec(
          icon: Icons.check_rounded,
          color: AppColors.success,
          label: l10n.attendancePresent,
        );
      case AttendanceState.TRE:
        return AttendanceVisualSpec(
          icon: Icons.schedule_rounded,
          color: AppColors.warning,
          label: l10n.attendanceLate,
        );
      case AttendanceState.NGHI_CO_PHEP:
        return AttendanceVisualSpec(
          icon: Icons.event_busy_outlined,
          color: AppColors.cyanAccent,
          label: l10n.attendanceExcused,
        );
      case AttendanceState.NGHI_KHONG_PHEP:
        return AttendanceVisualSpec(
          icon: Icons.close_rounded,
          color: AppColors.error,
          label: l10n.attendanceUnexcused,
        );
      case AttendanceState.HOC_BU:
        return AttendanceVisualSpec(
          icon: Icons.event_repeat_rounded,
          color: AppColors.primary,
          label: l10n.attendanceMakeup,
        );
    }
  }
}
