import 'package:sqflite/sqflite.dart';

import '../domain/membership.dart';

class MembershipRepository {
  final Database _db;

  MembershipRepository(this._db);

  Future<int> create(ClassMembership membership) async {
    return await _db.insert('tham_gia_lop', membership.toMap());
  }

  /// Validates the whole selection before inserting, so a failed enrollment
  /// never leaves only some students in the class.
  Future<void> createBatch(List<ClassMembership> memberships) async {
    if (memberships.isEmpty) return;
    await _db.transaction((txn) async {
      final first = memberships.first;
      final classRows = await txn.query(
        'lop',
        columns: ['si_so_toi_da', 'da_luu_tru'],
        where: 'id = ?',
        whereArgs: [first.idLop],
        limit: 1,
      );
      if (classRows.isEmpty || classRows.first['da_luu_tru'] == 1) {
        throw Exception('Lớp không tồn tại hoặc đã ngừng hoạt động');
      }
      final capacity = classRows.first['si_so_toi_da'] as int?;
      if (capacity != null) {
        final count =
            Sqflite.firstIntValue(
              await txn.rawQuery(
                'SELECT COUNT(DISTINCT id_hoc_sinh) FROM tham_gia_lop '
                'WHERE id_lop = ? AND tu_ngay <= ? AND (den_ngay IS NULL OR den_ngay >= ?)',
                [first.idLop, first.tuNgay, first.tuNgay],
              ),
            ) ??
            0;
        if (count + memberships.length > capacity) {
          throw Exception(
            'Sĩ số tối đa $capacity; chỉ còn ${capacity - count} chỗ',
          );
        }
      }
      final ids = <int>{};
      for (final membership in memberships) {
        if (membership.idLop != first.idLop ||
            membership.tuNgay != first.tuNgay ||
            !ids.add(membership.idHocSinh)) {
          throw Exception('Danh sách học sinh không hợp lệ hoặc bị trùng');
        }
        final student = await txn.query(
          'hoc_sinh',
          columns: ['da_luu_tru'],
          where: 'id = ?',
          whereArgs: [membership.idHocSinh],
          limit: 1,
        );
        if (student.isEmpty || student.first['da_luu_tru'] == 1) {
          throw Exception(
            'Học sinh #${membership.idHocSinh} không còn hoạt động',
          );
        }
        final existing = await txn.query(
          'tham_gia_lop',
          columns: ['id'],
          where:
              'id_hoc_sinh = ? AND id_lop = ? AND (den_ngay IS NULL OR den_ngay >= ?)',
          whereArgs: [membership.idHocSinh, first.idLop, first.tuNgay],
          limit: 1,
        );
        if (existing.isNotEmpty) {
          throw Exception(
            'Học sinh #${membership.idHocSinh} đã tham gia lớp trong khoảng thời gian này',
          );
        }
      }
      for (final membership in memberships) {
        await txn.insert('tham_gia_lop', membership.toMap());
      }
    });
  }

  Future<int> update(ClassMembership membership) async {
    return await _db.update(
      'tham_gia_lop',
      membership.toMap(),
      where: 'id = ?',
      whereArgs: [membership.id],
    );
  }

  Future<bool> hasFinalizedInvoiceSince(ClassMembership membership) async {
    final rows = await _db.query(
      'hoc_phi_thang',
      columns: ['id'],
      where:
          'id_hoc_sinh = ? AND id_lop = ? AND thang >= ? AND trang_thai != ?',
      whereArgs: [
        membership.idHocSinh,
        membership.idLop,
        membership.tuNgay.substring(0, 7),
        'NHAP',
      ],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<void> changeJoinDate(
    ClassMembership membership,
    String newDate,
  ) async {
    await _db.transaction((txn) async {
      final recorded =
          Sqflite.firstIntValue(
            await txn.rawQuery(
              'SELECT COUNT(*) FROM diem_danh d JOIN buoi_hoc b ON b.id = d.id_buoi_hoc '
              'WHERE d.id_hoc_sinh = ? AND b.id_lop = ? AND b.ngay >= ? AND b.ngay < ?',
              [
                membership.idHocSinh,
                membership.idLop,
                newDate.compareTo(membership.tuNgay) < 0
                    ? newDate
                    : membership.tuNgay,
                newDate.compareTo(membership.tuNgay) > 0
                    ? newDate
                    : membership.tuNgay,
              ],
            ),
          ) ??
          0;
      if (recorded > 0) {
        throw Exception(
          'Đã có điểm danh trong khoảng ngày bỏ đi; hãy xử lý điểm danh trước',
        );
      }
      final invoices =
          Sqflite.firstIntValue(
            await txn.rawQuery(
              'SELECT COUNT(*) FROM hoc_phi_thang WHERE id_hoc_sinh = ? AND id_lop = ? '
              'AND thang >= ? AND thang <= ?',
              [
                membership.idHocSinh,
                membership.idLop,
                (newDate.compareTo(membership.tuNgay) < 0
                        ? newDate
                        : membership.tuNgay)
                    .substring(0, 7),
                (newDate.compareTo(membership.tuNgay) > 0
                        ? newDate
                        : membership.tuNgay)
                    .substring(0, 7),
              ],
            ),
          ) ??
          0;
      if (invoices > 0) {
        throw Exception(
          'Khoảng ngày thay đổi đã có hóa đơn học phí; hãy xử lý hóa đơn trước',
        );
      }
      await txn.update(
        'tham_gia_lop',
        {'tu_ngay': newDate, 'updated_at': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [membership.id],
      );
    });
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

  Future<List<ClassMembership>> getActiveOnDate(String dateStr) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      'tham_gia_lop',
      where: 'tu_ngay <= ? AND (den_ngay IS NULL OR den_ngay >= ?)',
      whereArgs: [dateStr, dateStr],
      orderBy: 'tu_ngay DESC',
    );

    return List.generate(maps.length, (i) => ClassMembership.fromMap(maps[i]));
  }

  Future<List<ClassMembership>> getOverlappingDateRange({
    required String fromDate,
    required String toDate,
    int? classId,
    int? studentId,
  }) async {
    final whereClauses = <String>[
      'tu_ngay <= ?',
      '(den_ngay IS NULL OR den_ngay >= ?)',
    ];
    final whereArgs = <dynamic>[toDate, fromDate];

    if (classId != null) {
      whereClauses.add('id_lop = ?');
      whereArgs.add(classId);
    }
    if (studentId != null) {
      whereClauses.add('id_hoc_sinh = ?');
      whereArgs.add(studentId);
    }

    final maps = await _db.query(
      'tham_gia_lop',
      where: whereClauses.join(' AND '),
      whereArgs: whereArgs,
      orderBy: 'tu_ngay ASC',
    );
    return maps.map((m) => ClassMembership.fromMap(m)).toList();
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
