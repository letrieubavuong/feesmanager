import 'package:sqflite/sqflite.dart';
import '../domain/class_session.dart';

class SessionRepository {
  final Database _db;

  SessionRepository(this._db);

  Future<int> create(ClassSession session) async {
    return await _db.insert('buoi_hoc', session.toMap());
  }

  Future<int> update(ClassSession session) async {
    return await _db.update(
      'buoi_hoc',
      session.toMap(),
      where: 'id = ?',
      whereArgs: [session.id],
    );
  }

  Future<ClassSession?> getById(int id) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      'buoi_hoc',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return ClassSession.fromMap(maps.first);
  }

  Future<List<ClassSession>> getByIds(List<int> ids) async {
    if (ids.isEmpty) return [];
    final placeholders = List.filled(ids.length, '?').join(',');
    final List<Map<String, dynamic>> maps = await _db.query(
      'buoi_hoc',
      where: 'id IN ($placeholders)',
      whereArgs: ids,
    );
    return List.generate(maps.length, (i) => ClassSession.fromMap(maps[i]));
  }

  Future<List<ClassSession>> getByClass(int classId) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      'buoi_hoc',
      where: 'id_lop = ?',
      whereArgs: [classId],
      orderBy: 'ngay DESC, gio_bat_dau DESC',
    );
    return List.generate(maps.length, (i) => ClassSession.fromMap(maps[i]));
  }

  Future<List<ClassSession>> getByClassAndDateRange(
    int classId,
    String from,
    String to,
  ) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      'buoi_hoc',
      where: 'id_lop = ? AND ngay BETWEEN ? AND ?',
      whereArgs: [classId, from, to],
      orderBy: 'ngay ASC, gio_bat_dau ASC',
    );
    return List.generate(maps.length, (i) => ClassSession.fromMap(maps[i]));
  }

  Future<List<ClassSession>> getByDate(String date) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      'buoi_hoc',
      where: 'ngay = ?',
      whereArgs: [date],
      orderBy: 'gio_bat_dau ASC',
    );
    return List.generate(maps.length, (i) => ClassSession.fromMap(maps[i]));
  }

  Future<List<ClassSession>> getUpcomingHocBuSessions({
    required String fromDate,
    required String toDate,
  }) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      'buoi_hoc',
      where:
          'loai = \'HOC_BU\' AND trang_thai = \'DU_KIEN\' AND ngay >= ? AND ngay <= ?',
      whereArgs: [fromDate, toDate],
      orderBy: 'ngay ASC, gio_bat_dau ASC',
    );
    return List.generate(maps.length, (i) => ClassSession.fromMap(maps[i]));
  }

  Future<ClassSession?> findByClassDateStart(
    int classId,
    String date,
    String startTime,
  ) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      'buoi_hoc',
      where: 'id_lop = ? AND ngay = ? AND gio_bat_dau = ?',
      whereArgs: [classId, date, startTime],
    );
    if (maps.isEmpty) return null;
    return ClassSession.fromMap(maps.first);
  }

  Future<void> batchInsert(List<ClassSession> sessions) async {
    if (sessions.isEmpty) return;
    await _db.transaction((txn) async {
      for (final session in sessions) {
        await txn.insert('buoi_hoc', session.toMap());
      }
    });
  }
}
