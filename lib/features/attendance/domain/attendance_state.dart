// ignore_for_file: constant_identifier_names

import 'attendance_record.dart';

enum AttendanceState {
  CHUA_DIEM_DANH,
  CO_MAT,
  TRE,
  NGHI_CO_PHEP,
  NGHI_KHONG_PHEP,
  HOC_BU;

  String get label {
    switch (this) {
      case AttendanceState.CHUA_DIEM_DANH:
        return 'Chưa điểm danh';
      case AttendanceState.CO_MAT:
        return 'Có mặt';
      case AttendanceState.TRE:
        return 'Trễ';
      case AttendanceState.NGHI_CO_PHEP:
        return 'Nghỉ có phép';
      case AttendanceState.NGHI_KHONG_PHEP:
        return 'Nghỉ không phép';
      case AttendanceState.HOC_BU:
        return 'Học bù';
    }
  }

  AttendanceStatus? toStatus() {
    switch (this) {
      case AttendanceState.CO_MAT:
        return AttendanceStatus.CO_MAT;
      case AttendanceState.TRE:
        return AttendanceStatus.TRE;
      case AttendanceState.NGHI_CO_PHEP:
        return AttendanceStatus.NGHI_CO_PHEP;
      case AttendanceState.NGHI_KHONG_PHEP:
        return AttendanceStatus.NGHI_KHONG_PHEP;
      case AttendanceState.HOC_BU:
        return AttendanceStatus.HOC_BU;
      case AttendanceState.CHUA_DIEM_DANH:
        return null;
    }
  }

  bool get countsAsPresent =>
      this == AttendanceState.CO_MAT ||
      this == AttendanceState.TRE ||
      this == AttendanceState.HOC_BU;

  bool get isLate => this == AttendanceState.TRE;

  bool get isExcusedAbsence => this == AttendanceState.NGHI_CO_PHEP;

  bool get isUnexcusedAbsence => this == AttendanceState.NGHI_KHONG_PHEP;

  bool get isUnresolved => this == AttendanceState.CHUA_DIEM_DANH;

  factory AttendanceState.fromStatus(AttendanceStatus? status) {
    if (status == null) return AttendanceState.CHUA_DIEM_DANH;
    switch (status) {
      case AttendanceStatus.CO_MAT:
        return AttendanceState.CO_MAT;
      case AttendanceStatus.TRE:
        return AttendanceState.TRE;
      case AttendanceStatus.NGHI_CO_PHEP:
        return AttendanceState.NGHI_CO_PHEP;
      case AttendanceStatus.NGHI_KHONG_PHEP:
        return AttendanceState.NGHI_KHONG_PHEP;
      case AttendanceStatus.HOC_BU:
        return AttendanceState.HOC_BU;
    }
  }
}
