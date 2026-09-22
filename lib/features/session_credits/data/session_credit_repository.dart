import 'package:sqflite/sqflite.dart';
import '../domain/credit_ledger_entry.dart';
import '../domain/credit_ledger_reason.dart';

class SessionCreditRepository {
  final Database _db;

  SessionCreditRepository(this._db);

  Future<int> addLedgerEntry(CreditLedgerEntry entry) async {
    return await _db.insert('buoi_du_ledger', entry.toMap());
  }

  Future<void> addLedgerEntriesInTransaction(
    List<CreditLedgerEntry> entries,
  ) async {
    if (entries.isEmpty) return;
    await _db.transaction((txn) async {
      for (final entry in entries) {
        await txn.insert('buoi_du_ledger', entry.toMap());
      }
    });
  }

  Future<void> addLedgerEntriesInTxn(
    Transaction txn,
    List<CreditLedgerEntry> entries,
  ) async {
    for (final entry in entries) {
      await txn.insert('buoi_du_ledger', entry.toMap());
    }
  }

  Future<List<CreditLedgerEntry>> getLedgerForStudentAndClass(
    int studentId,
    int classId,
  ) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      'buoi_du_ledger',
      where: 'id_hoc_sinh = ? AND id_lop = ?',
      whereArgs: [studentId, classId],
      orderBy: 'ngay_hieu_luc ASC, created_at ASC, id ASC',
    );
    return List.generate(
      maps.length,
      (i) => CreditLedgerEntry.fromMap(maps[i]),
    );
  }

  Future<List<CreditLedgerEntry>> getLedgerForMonth(
    int studentId,
    int classId,
    String month, // YYYY-MM
  ) async {
    final fromDate = '$month-01';
    final toDate = '$month-31';

    final List<Map<String, dynamic>> maps = await _db.query(
      'buoi_du_ledger',
      where: 'id_hoc_sinh = ? AND id_lop = ? AND ngay_hieu_luc BETWEEN ? AND ?',
      whereArgs: [studentId, classId, fromDate, toDate],
      orderBy: 'ngay_hieu_luc ASC, created_at ASC, id ASC',
    );
    return List.generate(
      maps.length,
      (i) => CreditLedgerEntry.fromMap(maps[i]),
    );
  }

  Future<int> getBalance(int studentId, int classId) async {
    final result = await _db.rawQuery(
      'SELECT COALESCE(SUM(delta), 0) AS total FROM buoi_du_ledger WHERE id_hoc_sinh = ? AND id_lop = ?',
      [studentId, classId],
    );
    if (result.isEmpty) return 0;
    return (result.first['total'] as num).toInt();
  }

  Future<int> getBalanceAsOf(
    int studentId,
    int classId,
    String asOfDate, // YYYY-MM-DD
  ) async {
    final result = await _db.rawQuery(
      'SELECT COALESCE(SUM(delta), 0) AS total FROM buoi_du_ledger WHERE id_hoc_sinh = ? AND id_lop = ? AND ngay_hieu_luc <= ?',
      [studentId, classId, asOfDate],
    );
    if (result.isEmpty) return 0;
    return (result.first['total'] as num).toInt();
  }

  Future<CreditLedgerEntry?> getEarnedEntryForSession(
    int studentId,
    int classId,
    int sessionId,
    CreditLedgerReason reason,
  ) async {
    final maps = await _db.query(
      'buoi_du_ledger',
      where: 'id_hoc_sinh = ? AND id_lop = ? AND id_buoi_hoc = ? AND ly_do = ?',
      whereArgs: [studentId, classId, sessionId, reason.name],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return CreditLedgerEntry.fromMap(maps.first);
  }
}
