import 'package:sqflite/sqflite.dart';
import '../domain/schedule_constraint.dart';

class ScheduleConstraintRepository {
  final Database _db;

  ScheduleConstraintRepository(this._db);

  Future<int> createConstraint(ScheduleConstraint constraint) async {
    return await _db.insert('rang_buoc_lich_hoc_sinh', constraint.toMap());
  }

  Future<ScheduleConstraint?> getById(int id) async {
    final rows = await _db.query(
      'rang_buoc_lich_hoc_sinh',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (rows.isEmpty) return null;
    return ScheduleConstraint.fromRow(rows.first);
  }

  Future<List<ScheduleConstraint>> getForStudent(int studentId) async {
    final rows = await _db.query(
      'rang_buoc_lich_hoc_sinh',
      where: 'id_hoc_sinh = ?',
      whereArgs: [studentId],
      orderBy: 'trang_thai ASC, created_at DESC',
    );
    return rows.map((r) => ScheduleConstraint.fromRow(r)).toList();
  }

  Future<List<ScheduleConstraint>> getActiveForStudent(int studentId) async {
    final rows = await _db.query(
      'rang_buoc_lich_hoc_sinh',
      where: 'id_hoc_sinh = ? AND trang_thai = ?',
      whereArgs: [studentId, ConstraintStatus.HOAT_DONG.dbValue],
      orderBy: 'created_at DESC',
    );
    return rows.map((r) => ScheduleConstraint.fromRow(r)).toList();
  }

  Future<void> cancelConstraint(int id) async {
    final count = await _db.update(
      'rang_buoc_lich_hoc_sinh',
      {
        'trang_thai': ConstraintStatus.DA_HUY.dbValue,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    if (count == 0) {
      throw Exception('Không tìm thấy ràng buộc để hủy (id: $id)');
    }
  }
}
