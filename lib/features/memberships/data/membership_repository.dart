import 'package:sqflite/sqflite.dart';
import '../domain/membership.dart';

class MembershipRepository {
  final Database _db;

  MembershipRepository(this._db);

  Future<int> create(ClassMembership membership) async {
    return await _db.insert('tham_gia_lop', membership.toMap());
  }

  Future<int> update(ClassMembership membership) async {
    return await _db.update(
      'tham_gia_lop',
      membership.toMap(),
      where: 'id = ?',
      whereArgs: [membership.id],
    );
  }

  Future<List<ClassMembership>> getByStudent(int studentId) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      'tham_gia_lop',
      where: 'id_hoc_sinh = ?',
      whereArgs: [studentId],
      orderBy: 'tu_ngay DESC',
    );

    return List.generate(maps.length, (i) => ClassMembership.fromMap(maps[i]));
  }

  Future<List<ClassMembership>> getByClass(int classId) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      'tham_gia_lop',
      where: 'id_lop = ?',
      whereArgs: [classId],
      orderBy: 'tu_ngay DESC',
    );

    return List.generate(maps.length, (i) => ClassMembership.fromMap(maps[i]));
  }

  Future<List<ClassMembership>> getActiveByClass(
    int classId,
    String dateStr,
  ) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      'tham_gia_lop',
      where:
          'id_lop = ? AND tu_ngay <= ? AND (den_ngay IS NULL OR den_ngay >= ?)',
      whereArgs: [classId, dateStr, dateStr],
      orderBy: 'tu_ngay DESC',
    );

    return List.generate(maps.length, (i) => ClassMembership.fromMap(maps[i]));
  }

  Future<List<ClassMembership>> getActiveByStudent(
    int studentId,
    String dateStr,
  ) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      'tham_gia_lop',
      where:
          'id_hoc_sinh = ? AND tu_ngay <= ? AND (den_ngay IS NULL OR den_ngay >= ?)',
      whereArgs: [studentId, dateStr, dateStr],
      orderBy: 'tu_ngay DESC',
    );

    return List.generate(maps.length, (i) => ClassMembership.fromMap(maps[i]));
  }

  Future<ClassMembership?> getOpenMembership(int studentId, int classId) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      'tham_gia_lop',
      where: 'id_hoc_sinh = ? AND id_lop = ? AND den_ngay IS NULL',
      whereArgs: [studentId, classId],
    );

    if (maps.isEmpty) return null;
    return ClassMembership.fromMap(maps.first);
  }

  Future<ClassMembership?> getActiveMembership(
    int studentId,
    int classId,
    String dateStr,
  ) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      'tham_gia_lop',
      where:
          'id_hoc_sinh = ? AND id_lop = ? AND tu_ngay <= ? AND (den_ngay IS NULL OR den_ngay >= ?)',
      whereArgs: [studentId, classId, dateStr, dateStr],
    );

    if (maps.isEmpty) return null;
    return ClassMembership.fromMap(maps.first);
  }

  Future<bool> hasOverlappingMembership(
    int studentId,
    int classId,
    String start,
    String? end, {
    int? excludeId,
  }) async {
    String whereClause = 'id_hoc_sinh = ? AND id_lop = ?';
    List<dynamic> whereArgs = [studentId, classId];

    if (excludeId != null) {
      whereClause += ' AND id != ?';
      whereArgs.add(excludeId);
    }

    final List<Map<String, dynamic>> existing = await _db.query(
      'tham_gia_lop',
      where: whereClause,
      whereArgs: whereArgs,
    );

    for (final map in existing) {
      final eStart = map['tu_ngay'] as String;
      final eEnd = map['den_ngay'] as String?;

      bool overlap = true;
      if (eEnd != null && start.compareTo(eEnd) > 0) overlap = false;
      if (end != null && eStart.compareTo(end) > 0) overlap = false;

      if (overlap) return true;
    }

    return false;
  }

  Future<int> getClassSize(int classId, String dateStr) async {
    final result = await _db.rawQuery(
      'SELECT COUNT(*) as count FROM tham_gia_lop WHERE id_lop = ? AND tu_ngay <= ? AND (den_ngay IS NULL OR den_ngay >= ?)',
      [classId, dateStr, dateStr],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
