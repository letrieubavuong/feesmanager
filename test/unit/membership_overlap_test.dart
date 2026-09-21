import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tuition2027/features/memberships/data/membership_repository.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database db;
  late MembershipRepository repository;

  setUp(() async {
    db = await openDatabase(
      inMemoryDatabasePath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
        CREATE TABLE tham_gia_lop (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          id_hoc_sinh INTEGER NOT NULL,
          id_lop INTEGER NOT NULL,
          tu_ngay TEXT NOT NULL,
          den_ngay TEXT NULL
        )
      ''');
      },
    );
    repository = MembershipRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('Membership Overlap Logic', () {
    // Helper to insert existing membership
    Future<void> insert(String start, String? end) async {
      await db.insert('tham_gia_lop', {
        'id_hoc_sinh': 1,
        'id_lop': 1,
        'tu_ngay': start,
        'den_ngay': end,
      });
    }

    test('Overlap: 01/09-15/10 vs 01/10-NULL -> REJECT', () async {
      await insert('2026-09-01', '2026-10-15');
      expect(
        await repository.hasOverlappingMembership(1, 1, '2026-10-01', null),
        isTrue,
      );
    });

    test(
      'Overlap: 01/09-15/10 vs 15/10-NULL -> REJECT (border touch)',
      () async {
        await insert('2026-09-01', '2026-10-15');
        expect(
          await repository.hasOverlappingMembership(1, 1, '2026-10-15', null),
          isTrue,
        );
      },
    );

    test('Valid: 01/09-15/10 vs 16/10-NULL -> VALID', () async {
      await insert('2026-09-01', '2026-10-15');
      expect(
        await repository.hasOverlappingMembership(1, 1, '2026-10-16', null),
        isFalse,
      );
    });

    test('Overlap: 10/10-NULL vs 01/10-15/10 -> REJECT', () async {
      await insert('2026-10-10', null);
      expect(
        await repository.hasOverlappingMembership(
          1,
          1,
          '2026-10-01',
          '2026-10-15',
        ),
        isTrue,
      );
    });

    test('Overlap: 10/10-NULL vs 10/10-10/10 -> REJECT', () async {
      await insert('2026-10-10', null);
      expect(
        await repository.hasOverlappingMembership(
          1,
          1,
          '2026-10-10',
          '2026-10-10',
        ),
        isTrue,
      );
    });

    test('Valid: 10/10-NULL vs 01/10-09/10 -> VALID', () async {
      await insert('2026-10-10', null);
      expect(
        await repository.hasOverlappingMembership(
          1,
          1,
          '2026-10-01',
          '2026-10-09',
        ),
        isFalse,
      );
    });

    test('Overlap: two open intervals -> REJECT', () async {
      await insert('2026-09-01', null);
      expect(
        await repository.hasOverlappingMembership(1, 1, '2026-10-01', null),
        isTrue,
      );
    });

    test('Different classes or students -> VALID', () async {
      await insert('2026-09-01', '2026-10-15');
      expect(
        await repository.hasOverlappingMembership(2, 1, '2026-09-10', null),
        isFalse,
      );
      expect(
        await repository.hasOverlappingMembership(1, 2, '2026-09-10', null),
        isFalse,
      );
    });
  });
}
