import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import '../../../core/database/database_provider.dart';

class School {
  const School({required this.id, required this.name});

  final int id;
  final String name;
}

class SchoolRepository {
  const SchoolRepository(this.db);

  final Database db;

  Future<List<School>> listActive() async {
    final rows = await db.query(
      'truong_hoc',
      columns: ['id', 'ten'],
      where: 'da_luu_tru = 0',
      orderBy: 'ten COLLATE NOCASE ASC',
    );
    return rows
        .map((row) => School(id: row['id'] as int, name: row['ten'] as String))
        .toList();
  }

  Future<void> add(String name) async {
    final normalized = name.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.isEmpty) {
      throw ArgumentError('Tên trường không được để trống');
    }
    final updated = await db.update(
      'truong_hoc',
      {'da_luu_tru': 0},
      where: 'ten = ? COLLATE NOCASE',
      whereArgs: [normalized],
    );
    if (updated == 0) {
      await db.insert('truong_hoc', {
        'ten': normalized,
        'da_luu_tru': 0,
        'created_at': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<void> archive(int id) async {
    await db.update(
      'truong_hoc',
      {'da_luu_tru': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

final schoolRepositoryProvider = FutureProvider<SchoolRepository>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  return SchoolRepository(db);
});

final schoolsProvider = FutureProvider<List<School>>((ref) async {
  final repository = await ref.watch(schoolRepositoryProvider.future);
  return repository.listActive();
});
