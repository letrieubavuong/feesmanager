import 'package:intl/intl.dart';

class ClassMembership {
  final int? id;
  final int idHocSinh;
  final int idLop;
  final String tuNgay; // YYYY-MM-DD
  final String? denNgay; // YYYY-MM-DD
  final String? lyDoKetThuc;
  final int mienGiamPhanTram;
  final String? ghiChu;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ClassMembership({
    this.id,
    required this.idHocSinh,
    required this.idLop,
    required this.tuNgay,
    this.denNgay,
    this.lyDoKetThuc,
    this.mienGiamPhanTram = 0,
    this.ghiChu,
    required this.createdAt,
    required this.updatedAt,
  });

  bool isActiveOn(DateTime date) {
    final dateFormat = DateFormat('yyyy-MM-dd');
    final queryDateStr = dateFormat.format(date);
    
    if (queryDateStr.compareTo(tuNgay) < 0) return false;
    if (denNgay == null) return true;
    return queryDateStr.compareTo(denNgay!) <= 0;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'id_hoc_sinh': idHocSinh,
      'id_lop': idLop,
      'tu_ngay': tuNgay,
      'den_ngay': denNgay,
      'ly_do_ket_thuc': lyDoKetThuc,
      'mien_giam_phan_tram': mienGiamPhanTram,
      'ghi_chu': ghiChu,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory ClassMembership.fromMap(Map<String, dynamic> map) {
    return ClassMembership(
      id: map['id'] as int?,
      idHocSinh: map['id_hoc_sinh'] as int,
      idLop: map['id_lop'] as int,
      tuNgay: map['tu_ngay'] as String,
      denNgay: map['den_ngay'] as String?,
      lyDoKetThuc: map['ly_do_ket_thuc'] as String?,
      mienGiamPhanTram: map['mien_giam_phan_tram'] as int,
      ghiChu: map['ghi_chu'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  ClassMembership copyWith({
    int? id,
    int? idHocSinh,
    int? idLop,
    String? tuNgay,
    String? denNgay,
    String? lyDoKetThuc,
    int? mienGiamPhanTram,
    String? ghiChu,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ClassMembership(
      id: id ?? this.id,
      idHocSinh: idHocSinh ?? this.idHocSinh,
      idLop: idLop ?? this.idLop,
      tuNgay: tuNgay ?? this.tuNgay,
      denNgay: denNgay ?? this.denNgay,
      lyDoKetThuc: lyDoKetThuc ?? this.lyDoKetThuc,
      mienGiamPhanTram: mienGiamPhanTram ?? this.mienGiamPhanTram,
      ghiChu: ghiChu ?? this.ghiChu,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
