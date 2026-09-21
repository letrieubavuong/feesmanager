import 'package:sqflite/sqflite.dart';
import '../domain/student.dart';

class StudentRepository {
  final Database _db;

  StudentRepository(this._db);

  Future<int> create(Student student) async {
    return await _db.insert('hoc_sinh', student.toMap());
  }

  Future<int> update(Student student) async {
    return await _db.update(
      'hoc_sinh',
      student.toMap(),
      where: 'id = ?',
      whereArgs: [student.id],
    );
  }

  Future<Student?> getById(int id) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      'hoc_sinh',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return Student.fromMap(maps.first);
  }

  Future<List<Student>> getAll({bool includeArchived = false}) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      'hoc_sinh',
      where: includeArchived ? null : 'da_luu_tru = 0',
      orderBy: 'ho_ten ASC',
    );

    return List.generate(maps.length, (i) => Student.fromMap(maps[i]));
  }

  Future<List<Student>> search(String query, {bool includeArchived = false}) async {
    final String whereClause = includeArchived
        ? '(ho_ten LIKE ? OR sdt_phu_huynh LIKE ? OR sdt_hoc_sinh LIKE ? OR truong_dang_hoc LIKE ?)'
        : '(ho_ten LIKE ? OR sdt_phu_huynh LIKE ? OR sdt_hoc_sinh LIKE ? OR truong_dang_hoc LIKE ?) AND da_luu_tru = 0';
    
    final String likeQuery = '%$query%';
    final List<dynamic> whereArgs = [likeQuery, likeQuery, likeQuery, likeQuery];

    final List<Map<String, dynamic>> maps = await _db.query(
      'hoc_sinh',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'ho_ten ASC',
    );

    return List.generate(maps.length, (i) => Student.fromMap(maps[i]));
  }

  Future<int> setArchiveStatus(int id, bool archive) async {
    return await _db.update(
      'hoc_sinh',
      {
        'da_luu_tru': archive ? 1 : 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
