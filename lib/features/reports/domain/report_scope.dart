import 'package:intl/intl.dart';

enum ReportMode { month, customRange }

class ReportScope {
  final ReportMode mode;
  final String fromDate; // YYYY-MM-DD
  final String toDate; // YYYY-MM-DD
  final int? classId; // null = ALL classes
  final int? studentId; // null = ALL students

  ReportScope({
    required this.mode,
    required this.fromDate,
    required this.toDate,
    this.classId,
    this.studentId,
  }) {
    if (fromDate.compareTo(toDate) > 0) {
      throw ArgumentError(
        'Từ ngày ($fromDate) không được lớn hơn Đến ngày ($toDate)',
      );
    }
  }

  factory ReportScope.forMonth({
    required String month, // YYYY-MM
    int? classId,
    int? studentId,
  }) {
    final parts = month.split('-');
    if (parts.length != 2) {
      throw ArgumentError('Định dạng tháng không hợp lệ (cần YYYY-MM): $month');
    }
    final year = int.parse(parts[0]);
    final m = int.parse(parts[1]);
    final firstDay = DateTime(year, m, 1);
    final lastDay = DateTime(year, m + 1, 0);

    final fromStr = DateFormat('yyyy-MM-dd').format(firstDay);
    final toStr = DateFormat('yyyy-MM-dd').format(lastDay);

    return ReportScope(
      mode: ReportMode.month,
      fromDate: fromStr,
      toDate: toStr,
      classId: classId,
      studentId: studentId,
    );
  }

  factory ReportScope.customRange({
    required String fromDate,
    required String toDate,
    int? classId,
    int? studentId,
  }) {
    return ReportScope(
      mode: ReportMode.customRange,
      fromDate: fromDate,
      toDate: toDate,
      classId: classId,
      studentId: studentId,
    );
  }

  ReportScope copyWith({
    ReportMode? mode,
    String? fromDate,
    String? toDate,
    int? classId,
    bool clearClass = false,
    int? studentId,
    bool clearStudent = false,
  }) {
    return ReportScope(
      mode: mode ?? this.mode,
      fromDate: fromDate ?? this.fromDate,
      toDate: toDate ?? this.toDate,
      classId: clearClass ? null : (classId ?? this.classId),
      studentId: clearStudent ? null : (studentId ?? this.studentId),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReportScope &&
          runtimeType == other.runtimeType &&
          mode == other.mode &&
          fromDate == other.fromDate &&
          toDate == other.toDate &&
          classId == other.classId &&
          studentId == other.studentId;

  @override
  int get hashCode =>
      mode.hashCode ^
      fromDate.hashCode ^
      toDate.hashCode ^
      classId.hashCode ^
      studentId.hashCode;
}
