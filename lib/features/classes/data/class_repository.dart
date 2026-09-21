import 'package:sqflite/sqflite.dart';
import '../domain/class.dart';

class ClassRepository {
  final Database _db;

  ClassRepository(this._db);

  Future<int> create(ClassEntity classEntity) async {
    return await _db.insert('lop', classEntity.toMap());
  }

  Future<int> update(ClassEntity classEntity) async {
    return await _db.update(
      'lop',
      classEntity.toMap(),
      where: 'id = ?',
      whereArgs: [classEntity.id],
    );
  }

  Future<ClassEntity?> getById(int id) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      'lop',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return ClassEntity.fromMap(maps.first);
  }

  Future<List<ClassEntity>> getAll({bool includeArchived = false}) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      'lop',
      where: includeArchived ? null : 'da_luu_tru = 0',
      orderBy: 'ten_lop ASC',
    );

    return List.generate(maps.length, (i) => ClassEntity.fromMap(maps[i]));
  }

  Future<List<ClassEntity>> search(String query, {bool includeArchived = false}) async {
    final String whereClause = includeArchived
        ? '(ten_lop LIKE ? OR mon_hoc LIKE ?)'
        : '(ten_lop LIKE ? OR mon_hoc LIKE ?) AND da_luu_tru = 0';
    
    final String likeQuery = '%$query%';
    final List<dynamic> whereArgs = [likeQuery, likeQuery];

    final List<Map<String, dynamic>> maps = await _db.query(
      'lop',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'ten_lop ASC',
    );

    return List.generate(maps.length, (i) => ClassEntity.fromMap(maps[i]));
  }

  Future<int> setArchiveStatus(int id, bool archive) async {
    return await _db.update(
      'lop',
      {
        'da_luu_tru': archive ? 1 : 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
