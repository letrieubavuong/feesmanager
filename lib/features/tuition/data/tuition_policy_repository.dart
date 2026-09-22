import 'package:sqflite/sqflite.dart';
import '../domain/tuition_policy.dart';

class TuitionPolicyRepository {
  final Database _db;

  TuitionPolicyRepository(this._db);

  Future<int> insert(TuitionPolicy policy) async {
    return await _db.insert('chinh_sach_hoc_phi', policy.toMap());
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
}
