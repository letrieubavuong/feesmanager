import 'package:sqflite/sqflite.dart';
import '../domain/tuition_invoice.dart';

class TuitionRepository {
  final Database _db;

  TuitionRepository(this._db);

  Future<int> insertInvoice(TuitionInvoice invoice) async {
    return await _db.insert('hoc_phi_thang', invoice.toMap());
  }

  Future<int> insertInvoiceInTxn(
    Transaction txn,
    TuitionInvoice invoice,
  ) async {
    return await txn.insert('hoc_phi_thang', invoice.toMap());
  }

  Future<TuitionInvoice?> getInvoice(
    int studentId,
    int classId,
    String month,
  ) async {
    final maps = await _db.query(
      'hoc_phi_thang',
      where: 'id_hoc_sinh = ? AND id_lop = ? AND thang = ?',
      whereArgs: [studentId, classId, month],
    );
    if (maps.isEmpty) return null;
    return TuitionInvoice.fromMap(maps.first);
  }

  Future<List<TuitionInvoice>> getInvoicesForClassMonth(
    int classId,
    String month,
  ) async {
    final maps = await _db.query(
      'hoc_phi_thang',
      where: 'id_lop = ? AND thang = ?',
      whereArgs: [classId, month],
    );
    return maps.map((m) => TuitionInvoice.fromMap(m)).toList();
  }

  Future<List<TuitionInvoice>> getInvoicesForStudentClass(
    int studentId,
    int classId,
  ) async {
    final maps = await _db.query(
      'hoc_phi_thang',
      where: 'id_hoc_sinh = ? AND id_lop = ?',
      whereArgs: [studentId, classId],
      orderBy: 'thang DESC',
    );
    return maps.map((m) => TuitionInvoice.fromMap(m)).toList();
  }
}
