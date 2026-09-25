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

  Future<int> updateInvoiceStatusInTxn(
    Transaction txn,
    int invoiceId,
    TuitionInvoiceStatus status,
    DateTime updatedAt,
  ) async {
    return await txn.update(
      'hoc_phi_thang',
      {'trang_thai': status.name, 'updated_at': updatedAt.toIso8601String()},
      where: 'id = ?',
      whereArgs: [invoiceId],
    );
  }

  Future<TuitionInvoice?> getInvoiceById(int id) async {
    final maps = await _db.query(
      'hoc_phi_thang',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return TuitionInvoice.fromMap(maps.first);
  }

  Future<List<TuitionInvoice>> getInvoicesByIds(List<int> ids) async {
    if (ids.isEmpty) return [];
    final placeholders = List.filled(ids.length, '?').join(',');
    final maps = await _db.query(
      'hoc_phi_thang',
      where: 'id IN ($placeholders)',
      whereArgs: ids,
    );
    return maps.map((m) => TuitionInvoice.fromMap(m)).toList();
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

  Future<TuitionInvoice?> getInvoiceInTxn(
    Transaction txn,
    int studentId,
    int classId,
    String month,
  ) async {
    final maps = await txn.query(
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

  Future<List<TuitionInvoice>> getInvoicesInMonthRange({
    required String fromMonth,
    required String toMonth,
    int? classId,
    int? studentId,
  }) async {
    final whereClauses = <String>[
      'thang >= ?',
      'thang <= ?',
      "trang_thai != 'NHAP'",
    ];
    final whereArgs = <dynamic>[fromMonth, toMonth];

    if (classId != null) {
      whereClauses.add('id_lop = ?');
      whereArgs.add(classId);
    }
    if (studentId != null) {
      whereClauses.add('id_hoc_sinh = ?');
      whereArgs.add(studentId);
    }

    final maps = await _db.query(
      'hoc_phi_thang',
      where: whereClauses.join(' AND '),
      whereArgs: whereArgs,
      orderBy: 'thang DESC, id DESC',
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

  Future<bool> hasFinalizedInvoiceForClassFromMonth(
    int classId,
    String fromMonth, {
    String? toMonth,
  }) async {
    final whereClause = toMonth != null
        ? "id_lop = ? AND trang_thai != 'NHAP' AND thang >= ? AND thang <= ?"
        : "id_lop = ? AND trang_thai != 'NHAP' AND thang >= ?";
    final whereArgs = toMonth != null
        ? [classId, fromMonth, toMonth]
        : [classId, fromMonth];

    final maps = await _db.query(
      'hoc_phi_thang',
      where: whereClause,
      whereArgs: whereArgs,
      limit: 1,
    );
    return maps.isNotEmpty;
  }
}
