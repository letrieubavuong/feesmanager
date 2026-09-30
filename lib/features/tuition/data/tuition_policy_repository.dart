import 'package:sqflite/sqflite.dart';
import '../domain/center_tuition_policy.dart';
import '../domain/tuition_policy.dart';

class TuitionPolicyRepository {
  final Database _db;

  TuitionPolicyRepository(this._db);

  Future<int> insert(TuitionPolicy policy) async {
    return await _db.insert('chinh_sach_hoc_phi', policy.toMap());
  }

  Future<int> insertInTxn(Transaction txn, TuitionPolicy policy) async {
    return await txn.insert('chinh_sach_hoc_phi', policy.toMap());
  }

  Future<void> update(TuitionPolicy policy) async {
    await _db.update(
      'chinh_sach_hoc_phi',
      policy.toMap(),
      where: 'id = ?',
      whereArgs: [policy.id],
    );
  }

  Future<TuitionPolicy?> getById(int id) async {
    final maps = await _db.query(
      'chinh_sach_hoc_phi',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return TuitionPolicy.fromMap(maps.first);
  }

  Future<TuitionPolicy?> getByIdInTxn(Transaction txn, int id) async {
    final maps = await txn.query(
      'chinh_sach_hoc_phi',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return TuitionPolicy.fromMap(maps.first);
  }

  Future<List<TuitionPolicy>> getPoliciesForClass(int classId) async {
    final maps = await _db.query(
      'chinh_sach_hoc_phi',
      where: 'id_lop = ?',
      whereArgs: [classId],
      orderBy: 'hieu_luc_tu DESC',
    );
    return maps.map((m) => TuitionPolicy.fromMap(m)).toList();
  }

  Future<TuitionPolicy?> getEffectivePolicy(int classId, String date) async {
    final maps = await _db.query(
      'chinh_sach_hoc_phi',
      where:
          'id_lop = ? AND hieu_luc_tu <= ? AND (hieu_luc_den IS NULL OR hieu_luc_den >= ?)',
      whereArgs: [classId, date, date],
      orderBy: 'hieu_luc_tu DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return TuitionPolicy.fromMap(maps.first);
  }

  Future<void> closeOpenPolicy(int classId, String closeDate) async {
    await _db.update(
      'chinh_sach_hoc_phi',
      {
        'hieu_luc_den': closeDate,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id_lop = ? AND hieu_luc_den IS NULL',
      whereArgs: [classId],
    );
  }

  Future<void> closeOpenPolicyInTxn(
    Transaction txn,
    int classId,
    String closeDate,
  ) async {
    await txn.update(
      'chinh_sach_hoc_phi',
      {
        'hieu_luc_den': closeDate,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id_lop = ? AND hieu_luc_den IS NULL',
      whereArgs: [classId],
    );
  }

  Future<Set<int>> getClassIdsWithEffectivePolicyOnDate(
    List<int> classIds,
    String date,
  ) async {
    if (classIds.isEmpty) return {};
    final placeholders = List.filled(classIds.length, '?').join(',');
    final maps = await _db.rawQuery(
      '''
      SELECT DISTINCT id_lop
      FROM chinh_sach_hoc_phi
      WHERE id_lop IN ($placeholders)
        AND hieu_luc_tu <= ?
        AND (hieu_luc_den IS NULL OR hieu_luc_den >= ?)
      ''',
      [...classIds, date, date],
    );
    return maps.map((m) => m['id_lop'] as int).toSet();
  }

  // --- Center Tuition Policy Operations ---

  Future<int> insertCenterPolicy(CenterTuitionPolicy policy) async {
    return await _db.insert('center_tuition_policy', policy.toMap());
  }

  Future<CenterTuitionPolicy?> getCenterPolicyById(int id) async {
    final maps = await _db.query(
      'center_tuition_policy',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return CenterTuitionPolicy.fromMap(maps.first);
  }

  Future<List<CenterTuitionPolicy>> getAllCenterPolicies() async {
    final maps = await _db.query(
      'center_tuition_policy',
      orderBy: 'hieu_luc_tu DESC',
    );
    return maps.map((m) => CenterTuitionPolicy.fromMap(m)).toList();
  }

  Future<CenterTuitionPolicy?> getEffectiveCenterPolicyForDate(String date) async {
    final maps = await _db.query(
      'center_tuition_policy',
      where: 'hieu_luc_tu <= ? AND (hieu_luc_den IS NULL OR hieu_luc_den >= ?)',
      whereArgs: [date, date],
      orderBy: 'hieu_luc_tu DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return CenterTuitionPolicy.fromMap(maps.first);
  }

  Future<CenterTuitionPolicy?> getEffectiveCenterPolicyForMonth(String month) async {
    final date = '$month-01';
    return getEffectiveCenterPolicyForDate(date);
  }

  Future<void> closeOpenCenterPolicy(String closeDate) async {
    await _db.update(
      'center_tuition_policy',
      {
        'hieu_luc_den': closeDate,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'hieu_luc_den IS NULL',
    );
  }
}
