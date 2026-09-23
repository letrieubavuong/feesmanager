import 'package:sqflite/sqflite.dart';
import '../domain/session_adjustment.dart';

class SessionAdjustmentRepository {
  final Database _db;

  SessionAdjustmentRepository(this._db);

  Future<int> create(SessionAdjustment adjustment) async {
    return await _db.insert('dieu_chinh_buoi_hoc', adjustment.toMap());
  }

  Future<int> delete(int id) async {
    return await _db.delete(
      'dieu_chinh_buoi_hoc',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<SessionAdjustment?> getById(int id) async {
    final maps = await _db.query(
      'dieu_chinh_buoi_hoc',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return SessionAdjustment.fromMap(maps.first);
  }

  Future<List<SessionAdjustment>> getByTargetSession(int sessionId) async {
    final maps = await _db.query(
      'dieu_chinh_buoi_hoc',
      where: 'id_buoi_hoc_tham_gia = ?',
      whereArgs: [sessionId],
      orderBy: 'created_at ASC',
    );
    return maps.map((m) => SessionAdjustment.fromMap(m)).toList();
  }

  Future<List<SessionAdjustment>> getByOriginalSession(int sessionId) async {
    final maps = await _db.query(
      'dieu_chinh_buoi_hoc',
      where: 'id_buoi_hoc_goc = ?',
      whereArgs: [sessionId],
      orderBy: 'created_at ASC',
    );
    return maps.map((m) => SessionAdjustment.fromMap(m)).toList();
  }

  Future<List<SessionAdjustment>> getByStudent(int studentId) async {
    final maps = await _db.query(
      'dieu_chinh_buoi_hoc',
      where: 'id_hoc_sinh = ?',
      whereArgs: [studentId],
      orderBy: 'created_at ASC',
    );
    return maps.map((m) => SessionAdjustment.fromMap(m)).toList();
  }

  Future<List<SessionAdjustment>> getByTargetSessionIds(
    List<int> sessionIds,
  ) async {
    if (sessionIds.isEmpty) return [];
    final placeholders = List.filled(sessionIds.length, '?').join(',');
    final maps = await _db.query(
      'dieu_chinh_buoi_hoc',
      where: 'id_buoi_hoc_tham_gia IN ($placeholders)',
      whereArgs: sessionIds,
      orderBy: 'created_at ASC',
    );
    return maps.map((m) => SessionAdjustment.fromMap(m)).toList();
  }

  Future<List<SessionAdjustment>> getByOriginalSessionIds(
    List<int> sessionIds,
  ) async {
    if (sessionIds.isEmpty) return [];
    final placeholders = List.filled(sessionIds.length, '?').join(',');
    final maps = await _db.query(
      'dieu_chinh_buoi_hoc',
      where: 'id_buoi_hoc_goc IN ($placeholders)',
      whereArgs: sessionIds,
      orderBy: 'created_at ASC',
    );
    return maps.map((m) => SessionAdjustment.fromMap(m)).toList();
  }

  Future<SessionAdjustment?> getByStudentAndTargetSession(
    int studentId,
    int sessionId,
  ) async {
    final maps = await _db.query(
      'dieu_chinh_buoi_hoc',
      where: 'id_hoc_sinh = ? AND id_buoi_hoc_tham_gia = ?',
      whereArgs: [studentId, sessionId],
    );
    if (maps.isEmpty) return null;
    return SessionAdjustment.fromMap(maps.first);
  }

  Future<SessionAdjustment?> getByStudentAndOriginalSession(
    int studentId,
    int sessionId,
  ) async {
    final maps = await _db.query(
      'dieu_chinh_buoi_hoc',
      where: 'id_hoc_sinh = ? AND id_buoi_hoc_goc = ?',
      whereArgs: [studentId, sessionId],
    );
    if (maps.isEmpty) return null;
    return SessionAdjustment.fromMap(maps.first);
  }
}
