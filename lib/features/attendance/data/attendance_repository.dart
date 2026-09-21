import 'package:sqflite/sqflite.dart';
import '../domain/attendance_record.dart';

class AttendanceRepository {
  final Database _db;

  AttendanceRepository(this._db);

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
