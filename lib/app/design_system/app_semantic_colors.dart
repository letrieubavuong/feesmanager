import 'package:flutter/material.dart';

@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  final Color success;
  final Color warning;
  final Color error;
  final Color info;

  // Attendance states
  final Color attendancePresent;
  final Color attendanceLate;
  final Color attendanceExcusedAbsence;
  final Color attendanceUnexcusedAbsence;
  final Color attendanceNotMarked;

  // Tuition states
  final Color tuitionPaid;
  final Color tuitionPartialDebt;
  final Color tuitionDraft;
  final Color tuitionFinalized;

  // Schedule conflict states
  final Color scheduleNormal;
  final Color scheduleSoftWarning;
  final Color scheduleHardConflict;

  const AppSemanticColors({
    required this.success,
    required this.warning,
    required this.error,
    required this.info,
    required this.attendancePresent,
    required this.attendanceLate,
    required this.attendanceExcusedAbsence,
    required this.attendanceUnexcusedAbsence,
    required this.attendanceNotMarked,
    required this.tuitionPaid,
    required this.tuitionPartialDebt,
    required this.tuitionDraft,
    required this.tuitionFinalized,
    required this.scheduleNormal,
    required this.scheduleSoftWarning,
    required this.scheduleHardConflict,
  });

  static const light = AppSemanticColors(
    success: Color(0xFF2E7D32),
    warning: Color(0xFFED6C02),
    error: Color(0xFFD32F2F),
    info: Color(0xFF0288D1),
    attendancePresent: Color(0xFF2E7D32),
    attendanceLate: Color(0xFFE65100),
    attendanceExcusedAbsence: Color(0xFF0288D1),
    attendanceUnexcusedAbsence: Color(0xFFC62828),
    attendanceNotMarked: Color(0xFF757575),
    tuitionPaid: Color(0xFF00796B),
    tuitionPartialDebt: Color(0xFFE65100),
    tuitionDraft: Color(0xFF5C6BC0),
    tuitionFinalized: Color(0xFF283593),
    scheduleNormal: Color(0xFF2E7D32),
    scheduleSoftWarning: Color(0xFFED6C02),
    scheduleHardConflict: Color(0xFFC62828),
  );

  static const dark = AppSemanticColors(
    success: Color(0xFF66BB6A),
    warning: Color(0xFFFFB74D),
    error: Color(0xFFEF5350),
    info: Color(0xFF29B6F6),
    attendancePresent: Color(0xFF81C784),
    attendanceLate: Color(0xFFFFB74D),
    attendanceExcusedAbsence: Color(0xFF4FC3F7),
    attendanceUnexcusedAbsence: Color(0xFFE57373),
    attendanceNotMarked: Color(0xFFBDBDBD),
    tuitionPaid: Color(0xFF4DB6AC),
    tuitionPartialDebt: Color(0xFFFFB74D),
    tuitionDraft: Color(0xFF7986CB),
    tuitionFinalized: Color(0xFF5C6BC0),
    scheduleNormal: Color(0xFF81C784),
    scheduleSoftWarning: Color(0xFFFFB74D),
    scheduleHardConflict: Color(0xFFE57373),
  );

  @override
  AppSemanticColors copyWith({
    Color? success,
    Color? warning,
    Color? error,
    Color? info,
    Color? attendancePresent,
    Color? attendanceLate,
    Color? attendanceExcusedAbsence,
    Color? attendanceUnexcusedAbsence,
    Color? attendanceNotMarked,
    Color? tuitionPaid,
    Color? tuitionPartialDebt,
    Color? tuitionDraft,
    Color? tuitionFinalized,
    Color? scheduleNormal,
    Color? scheduleSoftWarning,
    Color? scheduleHardConflict,
  }) {
    return AppSemanticColors(
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      info: info ?? this.info,
      attendancePresent: attendancePresent ?? this.attendancePresent,
      attendanceLate: attendanceLate ?? this.attendanceLate,
      attendanceExcusedAbsence:
          attendanceExcusedAbsence ?? this.attendanceExcusedAbsence,
      attendanceUnexcusedAbsence:
          attendanceUnexcusedAbsence ?? this.attendanceUnexcusedAbsence,
      attendanceNotMarked: attendanceNotMarked ?? this.attendanceNotMarked,
      tuitionPaid: tuitionPaid ?? this.tuitionPaid,
      tuitionPartialDebt: tuitionPartialDebt ?? this.tuitionPartialDebt,
      tuitionDraft: tuitionDraft ?? this.tuitionDraft,
      tuitionFinalized: tuitionFinalized ?? this.tuitionFinalized,
      scheduleNormal: scheduleNormal ?? this.scheduleNormal,
      scheduleSoftWarning: scheduleSoftWarning ?? this.scheduleSoftWarning,
      scheduleHardConflict: scheduleHardConflict ?? this.scheduleHardConflict,
    );
  }

  @override
  AppSemanticColors lerp(ThemeExtension<AppSemanticColors>? other, double t) {
    if (other is! AppSemanticColors) return this;
    return AppSemanticColors(
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      error: Color.lerp(error, other.error, t)!,
      info: Color.lerp(info, other.info, t)!,
      attendancePresent: Color.lerp(
        attendancePresent,
        other.attendancePresent,
        t,
      )!,
      attendanceLate: Color.lerp(attendanceLate, other.attendanceLate, t)!,
      attendanceExcusedAbsence: Color.lerp(
        attendanceExcusedAbsence,
        other.attendanceExcusedAbsence,
        t,
      )!,
      attendanceUnexcusedAbsence: Color.lerp(
        attendanceUnexcusedAbsence,
        other.attendanceUnexcusedAbsence,
        t,
      )!,
      attendanceNotMarked: Color.lerp(
        attendanceNotMarked,
        other.attendanceNotMarked,
        t,
      )!,
      tuitionPaid: Color.lerp(tuitionPaid, other.tuitionPaid, t)!,
      tuitionPartialDebt: Color.lerp(
        tuitionPartialDebt,
        other.tuitionPartialDebt,
        t,
      )!,
      tuitionDraft: Color.lerp(tuitionDraft, other.tuitionDraft, t)!,
      tuitionFinalized: Color.lerp(
        tuitionFinalized,
        other.tuitionFinalized,
        t,
      )!,
      scheduleNormal: Color.lerp(scheduleNormal, other.scheduleNormal, t)!,
      scheduleSoftWarning: Color.lerp(
        scheduleSoftWarning,
        other.scheduleSoftWarning,
        t,
      )!,
      scheduleHardConflict: Color.lerp(
        scheduleHardConflict,
        other.scheduleHardConflict,
        t,
      )!,
    );
  }
}
