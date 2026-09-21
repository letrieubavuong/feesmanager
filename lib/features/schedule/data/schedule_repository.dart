import 'package:sqflite/sqflite.dart';
import '../domain/class_schedule.dart';

class ScheduleRepository {
  final Database _db;

  ScheduleRepository(this._db);

  Future<int> create(ClassSchedule schedule) async {
    return await _db.insert('lich_hoc', schedule.toMap());
  }

  Future<int> update(ClassSchedule schedule) async {
    return await _db.update(
      'lich_hoc',
      schedule.toMap(),
      where: 'id = ?',
      whereArgs: [schedule.id],
    );
  }

  Future<ClassSchedule?> getById(int id) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      'lich_hoc',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return ClassSchedule.fromMap(maps.first);
  }

  Future<List<ClassSchedule>> getByClass(int classId) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      'lich_hoc',
      where: 'id_lop = ?',
      whereArgs: [classId],
      orderBy: 'hieu_luc_tu DESC, thu_trong_tuan ASC, gio_bat_dau ASC',
    );
    return List.generate(maps.length, (i) => ClassSchedule.fromMap(maps[i]));
  }

  Future<List<ClassSchedule>> getEffectiveByClass(int classId, String dateStr) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      'lich_hoc',
      where: 'id_lop = ? AND hieu_luc_tu <= ? AND (hieu_luc_den IS NULL OR hieu_luc_den >= ?)',
      whereArgs: [classId, dateStr, dateStr],
      orderBy: 'thu_trong_tuan ASC, gio_bat_dau ASC',
    );
    return List.generate(maps.length, (i) => ClassSchedule.fromMap(maps[i]));
  }
}
