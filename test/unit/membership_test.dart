import 'package:flutter_test/flutter_test.dart';
import 'package:tuition2027/features/memberships/domain/membership.dart';

void main() {
  group('ClassMembership.isActiveOn', () {
    final membership = ClassMembership(
      idHocSinh: 1,
      idLop: 1,
      tuNgay: '2026-09-01',
      denNgay: '2026-10-15',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    test('should be inactive before join date', () {
      expect(membership.isActiveOn(DateTime(2026, 8, 31)), isFalse);
    });

    test('should be active on join date', () {
      expect(membership.isActiveOn(DateTime(2026, 9, 1)), isTrue);
    });

    test('should be active between dates', () {
      expect(membership.isActiveOn(DateTime(2026, 9, 20)), isTrue);
    });

    test('should be active on end date', () {
      expect(membership.isActiveOn(DateTime(2026, 10, 15)), isTrue);
    });

    test('should be inactive after end date', () {
      expect(membership.isActiveOn(DateTime(2026, 10, 16)), isFalse);
    });

    test('should be active indefinitely if denNgay is null', () {
      final openMembership = ClassMembership(
        idHocSinh: 1,
        idLop: 1,
        tuNgay: '2026-09-01',
        denNgay: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(openMembership.isActiveOn(DateTime(2026, 9, 1)), isTrue);
      expect(openMembership.isActiveOn(DateTime(2099, 12, 31)), isTrue);
    });
  });
}
