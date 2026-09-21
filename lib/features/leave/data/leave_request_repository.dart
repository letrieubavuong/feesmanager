import 'package:sqflite/sqflite.dart';
import '../domain/leave_request.dart';

class LeaveRequestRepository {
  final Database _db;

  LeaveRequestRepository(this._db);

  Future<int> create(LeaveRequest request) async {
    return await _db.insert('don_nghi_hoc', request.toMap());
  }

  Future<int> update(LeaveRequest request) async {
    return await _db.update(
      'don_nghi_hoc',
      request.toMap(),
      where: 'id = ?',
      whereArgs: [request.id],
    );
  }

  Future<LeaveRequest?> getById(int id) async {
    final maps = await _db.query(
      'don_nghi_hoc',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return LeaveRequest.fromMap(maps.first);
  }

  Future<List<LeaveRequest>> getByStudentAndClass(
    int studentId,
    int classId,
  ) async {
    final maps = await _db.query(
      'don_nghi_hoc',
      where: 'id_hoc_sinh = ? AND id_lop = ?',
      whereArgs: [studentId, classId],
      orderBy: 'tu_ngay DESC',
    );
    return maps.map((m) => LeaveRequest.fromMap(m)).toList();
  }

  Future<List<LeaveRequest>> getByClass(int classId) async {
    final maps = await _db.query(
      'don_nghi_hoc',
      where: 'id_lop = ?',
      whereArgs: [classId],
      orderBy: 'tu_ngay DESC',
    );
    return maps.map((m) => LeaveRequest.fromMap(m)).toList();
  }

  Future<List<LeaveRequest>> getByClassAndDateRange(
    int classId,
    String fromDate,
    String toDate,
  ) async {
    final maps = await _db.query(
      'don_nghi_hoc',
      where: 'id_lop = ? AND den_ngay >= ? AND tu_ngay <= ?',
      whereArgs: [classId, fromDate, toDate],
      orderBy: 'tu_ngay ASC',
    );
    return maps.map((m) => LeaveRequest.fromMap(m)).toList();
  }

  Future<List<LeaveRequest>> findOverlappingActiveRequests(
    int studentId,
    int classId,
    String tuNgay,
    String denNgay, {
    int? excludeId,
  }) async {
    final whereClause = StringBuffer(
      'id_hoc_sinh = ? AND id_lop = ? AND trang_thai IN (\'CHO_DUYET\', \'DA_DUYET\') AND den_ngay >= ? AND tu_ngay <= ?',
    );
    final whereArgs = <dynamic>[studentId, classId, tuNgay, denNgay];

    if (excludeId != null) {
      whereClause.write(' AND id != ?');
      whereArgs.add(excludeId);
    }

    final maps = await _db.query(
      'don_nghi_hoc',
      where: whereClause.toString(),
      whereArgs: whereArgs,
    );
    return maps.map((m) => LeaveRequest.fromMap(m)).toList();
  }

  Future<LeaveRequest?> findApprovedLeave(
    int studentId,
    int classId,
    String date,
  ) async {
    final maps = await _db.query(
      'don_nghi_hoc',
      where:
          'id_hoc_sinh = ? AND id_lop = ? AND trang_thai = \'DA_DUYET\' AND ? BETWEEN tu_ngay AND den_ngay',
      whereArgs: [studentId, classId, date],
      orderBy: 'created_at DESC',
    );
    if (maps.isEmpty) return null;
    return LeaveRequest.fromMap(maps.first);
  }
}
