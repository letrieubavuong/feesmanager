import 'package:sqflite/sqflite.dart';

class SchoolRepository {
  final Database db;
  SchoolRepository(this.db);

  Future<List<String>> list() async {
    final rows = await db.query(
      'truong_hoc',
      columns: ['ten'],
      orderBy: 'ten COLLATE NOCASE',
    );
    return rows.map((row) => row['ten'] as String).toList();
  }

  Future<void> add(String name) async {
    await db.insert('truong_hoc', {
      'ten': name,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> remove(String name) async {
    await db.delete(
      'truong_hoc',
      where: 'ten = ? COLLATE NOCASE',
      whereArgs: [name],
    );
  }
}
