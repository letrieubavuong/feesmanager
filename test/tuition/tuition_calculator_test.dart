import 'package:flutter_test/flutter_test.dart';
import 'package:tuition2027/features/tuition/domain/tuition_calculator.dart';

void main() {
  group('Canonical Tuition Calculator Tests', () {
    test('12 sessions, 50k unit, standard 12, cap 600k, 10% discount -> 540k net', () {
      final res = calculateTuitionFee(
        sessions: 12,
        standardLimit: 12,
        unitPrice: 50000,
        discountPercent: 10,
        monthlyCap: 600000,
      );
      expect(res.billedSessions, equals(12));
      expect(res.grossAmount, equals(600000));
      expect(res.cappedAmount, equals(600000));
      expect(res.discountAmount, equals(60000));
      expect(res.netAmount, equals(540000));
    });

    test('7 sessions, 50k unit, standard 12, cap 600k, 10% discount -> 315k net', () {
      final res = calculateTuitionFee(
        sessions: 7,
        standardLimit: 12,
        unitPrice: 50000,
        discountPercent: 10,
        monthlyCap: 600000,
      );
      expect(res.billedSessions, equals(7));
      expect(res.grossAmount, equals(350000));
      expect(res.cappedAmount, equals(350000));
      expect(res.discountAmount, equals(35000));
      expect(res.netAmount, equals(315000));
    });

    test('0 sessions -> 0 net', () {
      final res = calculateTuitionFee(
        sessions: 0,
        standardLimit: 12,
        unitPrice: 50000,
        discountPercent: 10,
        monthlyCap: 600000,
      );
      expect(res.billedSessions, equals(0));
      expect(res.netAmount, equals(0));
    });

    test('100% discount -> 0 net', () {
      final res = calculateTuitionFee(
        sessions: 12,
        standardLimit: 12,
        unitPrice: 50000,
        discountPercent: 100,
        monthlyCap: 600000,
      );
      expect(res.netAmount, equals(0));
      expect(res.discountAmount, equals(600000));
    });

    test('cap 400k with gross 600k and 10% discount -> 360k net (discount on capped base)', () {
      final res = calculateTuitionFee(
        sessions: 12,
        standardLimit: 12,
        unitPrice: 50000,
        discountPercent: 10,
        monthlyCap: 400000,
      );
      expect(res.grossAmount, equals(600000));
      expect(res.cappedAmount, equals(400000));
      expect(res.discountAmount, equals(40000));
      expect(res.netAmount, equals(360000));
    });

    test('overflow sessions beyond standard limit billed up to limit', () {
      final res = calculateTuitionFee(
        sessions: 15,
        standardLimit: 12,
        unitPrice: 50000,
        discountPercent: 0,
        monthlyCap: null,
      );
      expect(res.billedSessions, equals(12));
      expect(res.grossAmount, equals(600000));
      expect(res.netAmount, equals(600000));
    });

    test('invalid inputs throw ArgumentError', () {
      expect(
        () => calculateTuitionFee(
          sessions: -1,
          standardLimit: 12,
          unitPrice: 50000,
          discountPercent: 0,
        ),
        throwsArgumentError,
      );
      expect(
        () => calculateTuitionFee(
          sessions: 10,
          standardLimit: 0,
          unitPrice: 50000,
          discountPercent: 0,
        ),
        throwsArgumentError,
      );
      expect(
        () => calculateTuitionFee(
          sessions: 10,
          standardLimit: 12,
          unitPrice: -500,
          discountPercent: 0,
        ),
        throwsArgumentError,
      );
      expect(
        () => calculateTuitionFee(
          sessions: 10,
          standardLimit: 12,
          unitPrice: 50000,
          discountPercent: 105,
        ),
        throwsArgumentError,
      );
    });
  });
}
