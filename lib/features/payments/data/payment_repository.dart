import 'package:sqflite/sqflite.dart';
import '../domain/payment.dart';

class PaymentRepository {
  final Database _db;

  PaymentRepository(this._db);

  Future<int> insert(Payment payment) async {
    return await _db.insert('thanh_toan', payment.toMap());
  }

  Future<int> insertInTxn(Transaction txn, Payment payment) async {
    return await txn.insert('thanh_toan', payment.toMap());
  }

  Future<Payment?> getById(int id) async {
    final maps = await _db.query(
      'thanh_toan',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Payment.fromMap(maps.first);
  }

  Future<Payment?> getByIdInTxn(Transaction txn, int id) async {
    final maps = await txn.query(
      'thanh_toan',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Payment.fromMap(maps.first);
  }

  Future<List<Payment>> getPaymentsForInvoice(int invoiceId) async {
    final maps = await _db.query(
      'thanh_toan',
      where: 'id_hoc_phi_thang = ?',
      whereArgs: [invoiceId],
      orderBy: 'ngay_thanh_toan DESC, id DESC',
    );
    return maps.map((m) => Payment.fromMap(m)).toList();
  }

  Future<List<Payment>> getPaymentsForInvoiceInTxn(
    Transaction txn,
    int invoiceId,
  ) async {
    final maps = await txn.query(
      'thanh_toan',
      where: 'id_hoc_phi_thang = ?',
      whereArgs: [invoiceId],
      orderBy: 'ngay_thanh_toan DESC, id DESC',
    );
    return maps.map((m) => Payment.fromMap(m)).toList();
  }

  Future<List<Payment>> getPaymentsForInvoiceIds(List<int> invoiceIds) async {
    if (invoiceIds.isEmpty) return [];
    final placeholders = List.filled(invoiceIds.length, '?').join(',');
    final maps = await _db.query(
      'thanh_toan',
      where: 'id_hoc_phi_thang IN ($placeholders)',
      whereArgs: invoiceIds,
      orderBy: 'ngay_thanh_toan DESC, id DESC',
    );
    return maps.map((m) => Payment.fromMap(m)).toList();
  }

  Future<List<Payment>> getPaymentsForStudentClassMonth(
    int studentId,
    int classId,
    String month,
  ) async {
    final maps = await _db.query(
      'thanh_toan',
      where: 'id_hoc_sinh = ? AND id_lop = ? AND thang = ?',
      whereArgs: [studentId, classId, month],
      orderBy: 'ngay_thanh_toan DESC, id DESC',
    );
    return maps.map((m) => Payment.fromMap(m)).toList();
  }

  Future<List<Payment>> getPaymentsInDateRange({
    required String fromDate,
    required String toDate,
    int? classId,
    int? studentId,
  }) async {
    final whereClauses = <String>[
      'ngay_thanh_toan >= ?',
      'ngay_thanh_toan <= ?',
    ];
    final whereArgs = <dynamic>[fromDate, toDate];

    if (classId != null) {
      whereClauses.add('id_lop = ?');
      whereArgs.add(classId);
    }
    if (studentId != null) {
      whereClauses.add('id_hoc_sinh = ?');
      whereArgs.add(studentId);
    }

    final maps = await _db.query(
      'thanh_toan',
      where: whereClauses.join(' AND '),
      whereArgs: whereArgs,
      orderBy: 'ngay_thanh_toan DESC, id DESC',
    );
    return maps.map((m) => Payment.fromMap(m)).toList();
  }

  Future<int> getTotalPaidForInvoice(int invoiceId) async {
    final result = await _db.rawQuery(
      'SELECT COALESCE(SUM(so_tien), 0) AS total FROM thanh_toan WHERE id_hoc_phi_thang = ?',
      [invoiceId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getTotalPaidForInvoiceInTxn(
    Transaction txn,
    int invoiceId,
  ) async {
    final result = await txn.rawQuery(
      'SELECT COALESCE(SUM(so_tien), 0) AS total FROM thanh_toan WHERE id_hoc_phi_thang = ?',
      [invoiceId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getTotalPaidForStudentClassMonth(
    int studentId,
    int classId,
    String month,
  ) async {
    final result = await _db.rawQuery(
      'SELECT COALESCE(SUM(so_tien), 0) AS total FROM thanh_toan WHERE id_hoc_sinh = ? AND id_lop = ? AND thang = ?',
      [studentId, classId, month],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<Payment?> findByTransactionId(String transactionId) async {
    final trimmed = transactionId.trim();
    if (trimmed.isEmpty) return null;

    final maps = await _db.query(
      'thanh_toan',
      where: 'ma_giao_dich = ?',
      whereArgs: [trimmed],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Payment.fromMap(maps.first);
  }

  Future<Payment?> findByTransactionIdInTxn(
    Transaction txn,
    String transactionId,
  ) async {
    final trimmed = transactionId.trim();
    if (trimmed.isEmpty) return null;

    final maps = await txn.query(
      'thanh_toan',
      where: 'ma_giao_dich = ?',
      whereArgs: [trimmed],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Payment.fromMap(maps.first);
  }
}
