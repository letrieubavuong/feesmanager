import 'package:flutter_test/flutter_test.dart';
import 'package:tuition2027/core/utils/phone_normalizer.dart';

void main() {
  group('PhoneNormalizer', () {
    test('should return null for null or empty input', () {
      expect(PhoneNormalizer.normalize(null), isNull);
      expect(PhoneNormalizer.normalize(''), isNull);
    });

    test('should remove non-digit characters', () {
      expect(PhoneNormalizer.normalize('0905 123 456'), '0905123456');
      expect(PhoneNormalizer.normalize('0905.123.456'), '0905123456');
      expect(PhoneNormalizer.normalize('0905-123-456'), '0905123456');
    });

    test('should handle international format (+84)', () {
      expect(PhoneNormalizer.normalize('+84 905123456'), '0905123456');
      expect(PhoneNormalizer.normalize('84905123456'), '0905123456');
    });

    test('should handle long international format (0084)', () {
      expect(PhoneNormalizer.normalize('0084905123456'), '0905123456');
    });

    test('should preserve valid domestic format', () {
      expect(PhoneNormalizer.normalize('0123456789'), '0123456789');
    });

    test('should return null if no digits found', () {
      expect(PhoneNormalizer.normalize('abc-def'), isNull);
    });
  });
}
