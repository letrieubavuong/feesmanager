// ignore_for_file: constant_identifier_names

enum SessionAdjustmentType { DOI_CA, HOC_BU, PHAT_SINH }

class SessionAdjustment {
  final int? id;
  final int idHocSinh;
  final int idLopGoc;
  final int? idBuoiHocGoc;
  final int idBuoiHocThamGia;
  final SessionAdjustmentType loai;
  final String? lyDo;
  final DateTime createdAt;

  const SessionAdjustment({
    this.id,
    required this.idHocSinh,
    required this.idLopGoc,
    this.idBuoiHocGoc,
    required this.idBuoiHocThamGia,
    required this.loai,
    this.lyDo,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'id_hoc_sinh': idHocSinh,
      'id_lop_goc': idLopGoc,
      'id_buoi_hoc_goc': idBuoiHocGoc,
      'id_buoi_hoc_tham_gia': idBuoiHocThamGia,
      'loai': loai.name,
      'ly_do': lyDo,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory SessionAdjustment.fromMap(Map<String, dynamic> map) {
    return SessionAdjustment(
      id: map['id'] as int?,
      idHocSinh: map['id_hoc_sinh'] as int,
      idLopGoc: map['id_lop_goc'] as int,
      idBuoiHocGoc: map['id_buoi_hoc_goc'] as int?,
      idBuoiHocThamGia: map['id_buoi_hoc_tham_gia'] as int,
      loai: SessionAdjustmentType.values.byName(map['loai'] as String),
      lyDo: map['ly_do'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  SessionAdjustment copyWith({
    int? id,
    int? idHocSinh,
    int? idLopGoc,
    int? idBuoiHocGoc,
    int? idBuoiHocThamGia,
    SessionAdjustmentType? loai,
    String? lyDo,
    DateTime? createdAt,
  }) {
    return SessionAdjustment(
      id: id ?? this.id,
      idHocSinh: idHocSinh ?? this.idHocSinh,
      idLopGoc: idLopGoc ?? this.idLopGoc,
      idBuoiHocGoc: idBuoiHocGoc ?? this.idBuoiHocGoc,
      idBuoiHocThamGia: idBuoiHocThamGia ?? this.idBuoiHocThamGia,
      loai: loai ?? this.loai,
      lyDo: lyDo ?? this.lyDo,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
