import 'package:sqflite/sqflite.dart';
import '../domain/student_shift_assignment.dart';

class AssignmentRepository {
  final Database _db;

  AssignmentRepository(this._db);

  Database get db => _db;

  Future<int> create(StudentShiftAssignment assignment) async {
    return await _db.insert('phan_ca_hoc_sinh', assignment.toMap());
  }

  Future<int> update(StudentShiftAssignment assignment) async {
    return await _db.update(
      'phan_ca_hoc_sinh',
      assignment.toMap(),
      where: 'id = ?',
      whereArgs: [assignment.id],
    );
  }

  Future<List<StudentShiftAssignment>> getByStudent(int studentId) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      'phan_ca_hoc_sinh',
      where: 'id_hoc_sinh = ?',
      whereArgs: [studentId],
      orderBy: 'tu_ngay DESC',
    );
    return List.generate(maps.length, (i) => StudentShiftAssignment.fromMap(maps[i]));
  }

  Future<List<StudentShiftAssignment>> getByClass(int classId) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      'phan_ca_hoc_sinh',
      where: 'id_lop = ?',
      whereArgs: [classId],
      orderBy: 'tu_ngay DESC',
    );
    return List.generate(maps.length, (i) => StudentShiftAssignment.fromMap(maps[i]));
  }

  Future<List<StudentShiftAssignment>> getBySchedule(int scheduleId) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      'phan_ca_hoc_sinh',
      where: 'id_lich_hoc = ?',
      whereArgs: [scheduleId],
      orderBy: 'tu_ngay DESC',
    );
    return List.generate(maps.length, (i) => StudentShiftAssignment.fromMap(maps[i]));
  }

  Future<List<StudentShiftAssignment>> getActiveByStudent(int studentId, String dateStr) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      'phan_ca_hoc_sinh',
      where: 'id_hoc_sinh = ? AND tu_ngay <= ? AND (den_ngay IS NULL OR den_ngay >= ?)',
      whereArgs: [studentId, dateStr, dateStr],
      orderBy: 'tu_ngay DESC',
    );
    return List.generate(maps.length, (i) => StudentShiftAssignment.fromMap(maps[i]));
  }

  Future<StudentShiftAssignment?> getById(int id) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      'phan_ca_hoc_sinh',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return StudentShiftAssignment.fromMap(maps.first);
  }
}
