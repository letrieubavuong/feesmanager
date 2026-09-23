class DateAndTimeValidators {
  static final RegExp _timeRegExp = RegExp(r'^([01]\d|2[0-3]):[0-5]\d$');
  static final RegExp _dateRegExp = RegExp(
    r'^\d{4}-(0[1-9]|1[0-2])-(0[1-9]|[12]\d|3[01])$',
  );

  /// Validates HH:mm canonical time string.
  static void validateTimeStr(String timeStr, [String fieldName = 'time']) {
    if (!_timeRegExp.hasMatch(timeStr)) {
      throw FormatException(
        'Định dạng thời gian không hợp lệ ($fieldName): $timeStr. Yêu cầu HH:mm (00:00 - 23:59).',
      );
    }
  }

  /// Converts HH:mm time string to minutes from midnight.
  static int timeToMinutes(String timeStr, [String fieldName = 'time']) {
    validateTimeStr(timeStr, fieldName);
    final parts = timeStr.split(':');
    final hours = int.parse(parts[0]);
    final minutes = int.parse(parts[1]);
    return hours * 60 + minutes;
  }

  /// Validates time order: end must be strictly greater than start.
  static void validateTimeOrder(
    String startTime,
    String endTime, [
    String startName = 'gioBatDau',
    String endName = 'gioKetThuc',
  ]) {
    final startMin = timeToMinutes(startTime, startName);
    final endMin = timeToMinutes(endTime, endName);
    if (endMin <= startMin) {
      throw FormatException(
        'Thời gian kết thúc ($endTime) phải lớn hơn thời gian bắt đầu ($startTime).',
      );
    }
  }

  /// Validates YYYY-MM-DD canonical date string.
  static void validateDateStr(String dateStr, [String fieldName = 'date']) {
    if (!_dateRegExp.hasMatch(dateStr)) {
      throw FormatException(
        'Định dạng ngày không hợp lệ ($fieldName): $dateStr. Yêu cầu YYYY-MM-DD.',
      );
    }
    try {
      final dt = DateTime.parse(dateStr);
      final formatted =
          '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
      if (formatted != dateStr) {
        throw FormatException(
          'Ngày không tồn tại trong lịch ($fieldName): $dateStr',
        );
      }
    } catch (e) {
      if (e is FormatException) rethrow;
      throw FormatException(
        'Không thể parse ngày ($fieldName): $dateStr. Lỗi: $e',
      );
    }
  }

  /// Validates date range order: effectiveTo must be null or >= effectiveFrom.
  static void validateDateRange(
    String effectiveFrom,
    String? effectiveTo, [
    String fromName = 'effectiveFrom',
    String toName = 'effectiveTo',
  ]) {
    validateDateStr(effectiveFrom, fromName);
    if (effectiveTo != null) {
      validateDateStr(effectiveTo, toName);
      if (effectiveTo.compareTo(effectiveFrom) < 0) {
        throw FormatException(
          'Ngày kết thúc ($toName: $effectiveTo) không được trước ngày bắt đầu ($fromName: $effectiveFrom).',
        );
      }
    }
  }
}
