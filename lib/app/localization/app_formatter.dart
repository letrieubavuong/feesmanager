import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppFormatter {
  AppFormatter._();

  static String _resolveLocale(BuildContext? context, String? overrideLocale) {
    if (overrideLocale != null) return overrideLocale;
    if (context != null) {
      return Localizations.localeOf(context).languageCode;
    }
    return 'vi';
  }

  static String formatCurrency(
    num amount, {
    BuildContext? context,
    String? locale,
  }) {
    final lang = _resolveLocale(context, locale);
    if (lang == 'en') {
      return NumberFormat.currency(
        locale: 'en_US',
        symbol: '\$',
        decimalDigits: 0,
      ).format(amount);
    }
    return NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
      decimalDigits: 0,
    ).format(amount);
  }

  static String formatDate(
    DateTime date, {
    BuildContext? context,
    String? locale,
  }) {
    final lang = _resolveLocale(context, locale);
    if (lang == 'en') {
      return DateFormat('MMM dd, yyyy').format(date);
    }
    return DateFormat('dd/MM/yyyy').format(date);
  }

  static String formatShortDate(
    String isoDateStr, {
    BuildContext? context,
    String? locale,
  }) {
    final parsed = DateTime.tryParse(isoDateStr);
    if (parsed == null) return isoDateStr;
    return formatDate(parsed, context: context, locale: locale);
  }

  static String formatMonth(
    String monthStr, {
    BuildContext? context,
    String? locale,
  }) {
    // monthStr: YYYY-MM
    final lang = _resolveLocale(context, locale);
    final parts = monthStr.split('-');
    if (parts.length != 2) return monthStr;
    final year = parts[0];
    final m = parts[1];

    if (lang == 'en') {
      final date = DateTime(int.parse(year), int.parse(m), 1);
      return DateFormat('MMMM yyyy', 'en_US').format(date);
    }
    return 'Tháng $m/$year';
  }

  static String formatWeekday(
    int weekday, {
    BuildContext? context,
    String? locale,
  }) {
    // 1 = Mon, 7 = Sun
    final lang = _resolveLocale(context, locale);
    if (lang == 'en') {
      switch (weekday) {
        case 1:
          return 'Monday';
        case 2:
          return 'Tuesday';
        case 3:
          return 'Wednesday';
        case 4:
          return 'Thursday';
        case 5:
          return 'Friday';
        case 6:
          return 'Saturday';
        case 7:
          return 'Sunday';
        default:
          return 'Day $weekday';
      }
    } else {
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
          return 'Thứ $weekday';
      }
    }
  }

  static String formatNumber(
    num value, {
    BuildContext? context,
    String? locale,
  }) {
    final lang = _resolveLocale(context, locale);
    return NumberFormat.decimalPattern(
      lang == 'en' ? 'en_US' : 'vi_VN',
    ).format(value);
  }

  static String formatPercentage(
    double value, {
    BuildContext? context,
    String? locale,
  }) {
    return '${value.toStringAsFixed(1)}%';
  }
}
