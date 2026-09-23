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

  Future<List<ScheduleConstraint>> getActiveRecurringForStudent(
    int studentId,
  ) async {
    final rows = await _db.query(
      'rang_buoc_lich_hoc_sinh',
      where: 'id_hoc_sinh = ? AND kieu = ? AND trang_thai = ?',
      whereArgs: [
        studentId,
        OccurrenceType.DINH_KY.dbValue,
        ConstraintStatus.HOAT_DONG.dbValue,
      ],
      orderBy: 'created_at DESC',
    );
    return rows.map((r) => ScheduleConstraint.fromRow(r)).toList();
  }

  Future<List<ScheduleConstraint>> getActiveForStudentAndDate(
    int studentId,
    String dateStr,
    int weekday,
  ) async {
    final rows = await _db.query(
      'rang_buoc_lich_hoc_sinh',
      where:
          'id_hoc_sinh = ? AND trang_thai = ? AND ('
          '(kieu = ? AND thu_trong_tuan = ? AND hieu_luc_tu <= ? AND (hieu_luc_den IS NULL OR hieu_luc_den >= ?))'
          ' OR '
          '(kieu = ? AND ngay_cu_the = ?)'
          ')',
      whereArgs: [
        studentId,
        ConstraintStatus.HOAT_DONG.dbValue,
        OccurrenceType.DINH_KY.dbValue,
        weekday,
        dateStr,
        dateStr,
        OccurrenceType.MOT_LAN.dbValue,
        dateStr,
      ],
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
