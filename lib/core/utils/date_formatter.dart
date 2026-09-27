import 'package:intl/intl.dart';

class DateFormatter {
  static final DateFormat _displayFormat = DateFormat('dd/MM/yyyy');
  static final DateFormat _canonicalFormat = DateFormat('yyyy-MM-dd');

  static String formatVietnameseWeekday(int weekday) {
    switch (weekday) {
      case 1:
        return 'Thứ Hai';
      case 2:
        return 'Thứ Ba';
      case 3:
        return 'Thứ Tư';
      case 4:
        return 'Thứ Năm';
      case 5:
        return 'Thứ Sáu';
      case 6:
        return 'Thứ Bảy';
      case 7:
        return 'Chủ Nhật';
      default:
        return 'Không xác định';
    }
  }

  static String formatDisplayDate(dynamic input) {
    if (input == null) return 'N/A';
    if (input is DateTime) {
      return _displayFormat.format(input);
    }
    if (input is String) {
      if (input.trim().isEmpty) return 'N/A';
      try {
        final parsed = DateTime.parse(input.trim());
        return _displayFormat.format(parsed);
      } catch (_) {
        return input;
      }
    }
    return input.toString();
  }

  static String formatShortDate(String? dateStr) {
    return formatDisplayDate(dateStr);
  }

  static String formatCanonicalDate(DateTime date) {
    return _canonicalFormat.format(date);
  }

  static DateTime? parseCanonicalDate(String? dateStr) {
    if (dateStr == null || dateStr.trim().isEmpty) return null;
    try {
      return DateTime.parse(dateStr.trim());
    } catch (_) {
      return null;
    }
  }
}
