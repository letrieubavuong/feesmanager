import 'package:flutter/material.dart';
import '../../features/attendance/domain/attendance_record.dart';
import '../../l10n/app_localizations.dart';
import '../design_system/app_theme.dart';

class AttendanceStatusIcon extends StatelessWidget {
  final AttendanceStatus? status;
  final double size;

  const AttendanceStatusIcon({super.key, required this.status, this.size = 18});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final (icon, color, label) = _getDetails(status, l10n);

    return Semantics(
      label: label,
      child: Tooltip(
        message: label,
        child: Container(
          padding: EdgeInsets.all(size * 0.2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: size),
        ),
      ),
    );
  }

  static (IconData, Color, String) _getDetails(
    AttendanceStatus? status,
    AppLocalizations l10n,
  ) {
    if (status == null) {
      return (
        Icons.help_outline_rounded,
        AppColors.textMuted,
        l10n.attendanceNotMarked,
      );
    }
    switch (status) {
      case AttendanceStatus.CO_MAT:
        return (Icons.check_rounded, AppColors.success, l10n.attendancePresent);
      case AttendanceStatus.TRE:
        return (Icons.schedule_rounded, AppColors.warning, l10n.attendanceLate);
      case AttendanceStatus.NGHI_CO_PHEP:
        return (
          Icons.event_busy_outlined,
          AppColors.cyanAccent,
          l10n.attendanceExcused,
        );
      case AttendanceStatus.NGHI_KHONG_PHEP:
        return (Icons.close_rounded, AppColors.error, l10n.attendanceUnexcused);
      case AttendanceStatus.HOC_BU:
        return (Icons.event_repeat_rounded, AppColors.primary, 'Học bù');
    }
  }
}
