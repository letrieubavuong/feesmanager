import 'package:sqflite/sqflite.dart';
import '../domain/attendance_correction_audit_record.dart';
import '../domain/attendance_record.dart';

class AttendanceRepository {
  final Database _db;

  AttendanceRepository(this._db);

  Database get db => _db;

  Future<List<AttendanceRecord>> getBySession(int sessionId) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      'diem_danh',
      where: 'id_buoi_hoc = ?',
      whereArgs: [sessionId],
    );

    return maps.map((map) => AttendanceRecord.fromMap(map)).toList();
  }

  Future<AttendanceRecord?> getBySessionAndStudent(
    int sessionId,
    int studentId,
  ) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      'diem_danh',
      where: 'id_buoi_hoc = ? AND id_hoc_sinh = ?',
      whereArgs: [sessionId, studentId],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return AttendanceRecord.fromMap(maps.first);
  }

  Future<List<AttendanceRecord>> getRecentByStudent(
    int studentId, {
    int limit = 3,
  }) async {
    final List<Map<String, dynamic>> maps = await _db.rawQuery(
      '''
      SELECT d.*
      FROM diem_danh d
      JOIN buoi_hoc b ON d.id_buoi_hoc = b.id
      WHERE d.id_hoc_sinh = ?
      ORDER BY b.ngay DESC, b.gio_bat_dau DESC, b.id DESC
      LIMIT ?
      ''',
      [studentId, limit],
    );

    return maps.map((map) => AttendanceRecord.fromMap(map)).toList();
  }

  Future<void> upsert(AttendanceRecord record) async {
    final existing = await getBySessionAndStudent(
      record.idBuoiHoc,
      record.idHocSinh,
    );

    if (existing != null) {
      await _db.update(
        'diem_danh',
        record.toMap()..['created_at'] = existing.createdAt?.toIso8601String(),
        where: 'id = ?',
        whereArgs: [existing.id],
      );
    } else {
      await _db.insert('diem_danh', record.toMap());
    }
  }

  Future<void> deleteForStudent(int sessionId, int studentId) async {
    await _db.delete(
      'diem_danh',
      where: 'id_buoi_hoc = ? AND id_hoc_sinh = ?',
      whereArgs: [sessionId, studentId],
    );
  }

  Future<List<AttendanceRecord>> getBySessionIds(List<int> sessionIds) async {
    if (sessionIds.isEmpty) return [];

    final result = <AttendanceRecord>[];
    const chunkSize = 500;

    for (var i = 0; i < sessionIds.length; i += chunkSize) {
      final chunk = sessionIds.sublist(
        i,
        i + chunkSize > sessionIds.length ? sessionIds.length : i + chunkSize,
      );
      final placeholders = List.filled(chunk.length, '?').join(',');
      final maps = await _db.query(
        'diem_danh',
        where: 'id_buoi_hoc IN ($placeholders)',
        whereArgs: chunk,
      );
      result.addAll(maps.map((map) => AttendanceRecord.fromMap(map)));
    }

    return result;
  }

  Future<List<AttendanceRecord>> getByStudentAndSessionIds(
    int studentId,
    List<int> sessionIds,
  ) async {
    if (sessionIds.isEmpty) return [];

    final result = <AttendanceRecord>[];
    const chunkSize = 500;

    for (var i = 0; i < sessionIds.length; i += chunkSize) {
      final chunk = sessionIds.sublist(
        i,
        i + chunkSize > sessionIds.length ? sessionIds.length : i + chunkSize,
      );
      final placeholders = List.filled(chunk.length, '?').join(',');
      final maps = await _db.query(
        'diem_danh',
        where: 'id_hoc_sinh = ? AND id_buoi_hoc IN ($placeholders)',
        whereArgs: [studentId, ...chunk],
      );
      result.addAll(maps.map((map) => AttendanceRecord.fromMap(map)));
    }

    return result;
  }

  Future<Set<int>> getSessionsWithCorrectionHistory(
    List<int> sessionIds,
  ) async {
    if (sessionIds.isEmpty) return {};

    final result = <int>{};
    const chunkSize = 500;

    for (var i = 0; i < sessionIds.length; i += chunkSize) {
      final chunk = sessionIds.sublist(
        i,
        i + chunkSize > sessionIds.length ? sessionIds.length : i + chunkSize,
      );
      final placeholders = List.filled(chunk.length, '?').join(',');
      final maps = await _db.rawQuery(
        'SELECT DISTINCT id_buoi_hoc FROM diem_danh_chinh_sua WHERE id_buoi_hoc IN ($placeholders)',
        chunk,
      );
      for (final map in maps) {
        result.add(map['id_buoi_hoc'] as int);
      }
    }

    return result;
  }

  Future<void> insertCorrectionAudit(
    DatabaseExecutor txn,
    AttendanceCorrectionAuditRecord record,
  ) async {
    await txn.insert('diem_danh_chinh_sua', record.toMap());
  }

  Future<List<AttendanceCorrectionAuditRecord>> getCorrectionAuditsForSession(
    int sessionId,
  ) async {
    final maps = await _db.rawQuery(
      '''
      SELECT a.*, hs.ho_ten
      FROM diem_danh_chinh_sua a
      JOIN hoc_sinh hs ON a.id_hoc_sinh = hs.id
      WHERE a.id_buoi_hoc = ?
      ORDER BY a.id DESC
      ''',
      [sessionId],
    );

    return maps.map((m) => AttendanceCorrectionAuditRecord.fromMap(m)).toList();
  }

  Future<void> batchSave(
    int sessionId,
    List<AttendanceRecord> toUpsert,
    List<int> toDeleteIds,
  ) async {
    await _db.transaction((txn) async {
      for (final record in toUpsert) {
        final List<Map<String, dynamic>> existing = await txn.query(
          'diem_danh',
          where: 'id_buoi_hoc = ? AND id_hoc_sinh = ?',
          whereArgs: [sessionId, record.idHocSinh],
          limit: 1,
        );

        if (existing.isNotEmpty) {
          final map = record.toMap();
          map['created_at'] = existing.first['created_at'];
          await txn.update(
            'diem_danh',
            map,
            where: 'id = ?',
            whereArgs: [existing.first['id']],
          );
        } else {
          await txn.insert('diem_danh', record.toMap());
        }
      }

      for (final studentId in toDeleteIds) {
        await txn.delete(
          'diem_danh',
          where: 'id_buoi_hoc = ? AND id_hoc_sinh = ?',
          whereArgs: [sessionId, studentId],
        );
      }
    });
  }
}
