import 'package:intl/intl.dart';

class ClassSchedule {
  final int? id;
  final int idLop;
  final int thuTrongTuan; // 1-7 (Mon-Sun)
  final String gioBatDau; // HH:mm
  final String gioKetThuc; // HH:mm
  final String hieuLucTu; // YYYY-MM-DD
  final String? hieuLucDen; // YYYY-MM-DD
  final String? ghiChu;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ClassSchedule({
    this.id,
    required this.idLop,
    required this.thuTrongTuan,
    required this.gioBatDau,
    required this.gioKetThuc,
    required this.hieuLucTu,
    this.hieuLucDen,
    this.ghiChu,
    required this.createdAt,
    required this.updatedAt,
  });

  bool isEffectiveOn(DateTime date) {
    final dateFormat = DateFormat('yyyy-MM-dd');
    final queryDateStr = dateFormat.format(date);

    if (queryDateStr.compareTo(hieuLucTu) < 0) return false;
    if (hieuLucDen == null) return true;
    return queryDateStr.compareTo(hieuLucDen!) <= 0;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'id_lop': idLop,
      'thu_trong_tuan': thuTrongTuan,
      'gio_bat_dau': gioBatDau,
      'gio_ket_thuc': gioKetThuc,
      'hieu_luc_tu': hieuLucTu,
      'hieu_luc_den': hieuLucDen,
      'ghi_chu': ghiChu,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory ClassSchedule.fromMap(Map<String, dynamic> map) {
    return ClassSchedule(
      id: map['id'] as int?,
      idLop: map['id_lop'] as int,
      thuTrongTuan: map['thu_trong_tuan'] as int,
      gioBatDau: map['gio_bat_dau'] as String,
      gioKetThuc: map['gio_ket_thuc'] as String,
      hieuLucTu: map['hieu_luc_tu'] as String,
      hieuLucDen: map['hieu_luc_den'] as String?,
      ghiChu: map['ghi_chu'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  ClassSchedule copyWith({
    int? id,
    int? idLop,
    int? thuTrongTuan,
    String? gioBatDau,
    String? gioKetThuc,
    String? hieuLucTu,
    String? hieuLucDen,
    String? ghiChu,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ClassSchedule(
      id: id ?? this.id,
      idLop: idLop ?? this.idLop,
      thuTrongTuan: thuTrongTuan ?? this.thuTrongTuan,
      gioBatDau: gioBatDau ?? this.gioBatDau,
      gioKetThuc: gioKetThuc ?? this.gioKetThuc,
      hieuLucTu: hieuLucTu ?? this.hieuLucTu,
      hieuLucDen: hieuLucDen ?? this.hieuLucDen,
      ghiChu: ghiChu ?? this.ghiChu,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
