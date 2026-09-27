import 'package:flutter_test/flutter_test.dart';
import 'package:tuition2027/core/utils/date_formatter.dart';

void main() {
  group('DateFormatter Unit Tests', () {
    test(
      'formatDisplayDate converts ISO string and DateTime to dd/MM/yyyy',
      () {
        expect(
          DateFormatter.formatDisplayDate('2026-09-08'),
          equals('08/09/2026'),
        );
        expect(
          DateFormatter.formatDisplayDate(DateTime(2026, 9, 8)),
          equals('08/09/2026'),
        );
        expect(DateFormatter.formatDisplayDate(null), equals('N/A'));
      },
    );

    test('formatCanonicalDate converts DateTime to yyyy-MM-dd', () {
      expect(
        DateFormatter.formatCanonicalDate(DateTime(2026, 9, 8)),
        equals('2026-09-08'),
      );
    });

    test(
      'formatVietnameseWeekday returns correct Vietnamese weekday label',
      () {
        expect(DateFormatter.formatVietnameseWeekday(1), equals('Thứ Hai'));
        expect(DateFormatter.formatVietnameseWeekday(7), equals('Chủ Nhật'));
      },
    );
  });
}
