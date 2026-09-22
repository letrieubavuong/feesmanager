class TuitionPolicy {
  final int? id;
  final int idLop;
  final String hieuLucTu; // YYYY-MM-DD
  final String? hieuLucDen; // YYYY-MM-DD
  final int soBuoiChuanThang;
  final int hocPhiMoiBuoi;
  final int? hocPhiThangToiDa;
  final String? ghiChu;
  final DateTime createdAt;
  final DateTime updatedAt;

  TuitionPolicy({
    this.id,
    required this.idLop,
    required this.hieuLucTu,
    this.hieuLucDen,
    this.soBuoiChuanThang = 12,
    required this.hocPhiMoiBuoi,
    this.hocPhiThangToiDa,
    this.ghiChu,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'id_lop': idLop,
    'hieu_luc_tu': hieuLucTu,
    'hieu_luc_den': hieuLucDen,
    'so_buoi_chuan_thang': soBuoiChuanThang,
    'hoc_phi_moi_buoi': hocPhiMoiBuoi,
    'hoc_phi_thang_toi_da': hocPhiThangToiDa,
    'ghi_chu': ghiChu,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory TuitionPolicy.fromMap(Map<String, dynamic> map) => TuitionPolicy(
    id: map['id'] as int?,
    idLop: map['id_lop'] as int,
    hieuLucTu: map['hieu_luc_tu'] as String,
    hieuLucDen: map['hieu_luc_den'] as String?,
    soBuoiChuanThang: map['so_buoi_chuan_thang'] as int? ?? 12,
    hocPhiMoiBuoi: map['hoc_phi_moi_buoi'] as int? ?? 0,
    hocPhiThangToiDa: map['hoc_phi_thang_toi_da'] as int?,
    ghiChu: map['ghi_chu'] as String?,
    createdAt: DateTime.parse(map['created_at'] as String),
    updatedAt: DateTime.parse(map['updated_at'] as String),
  );
}
