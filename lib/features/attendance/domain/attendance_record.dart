// ignore_for_file: constant_identifier_names

enum AttendanceStatus { CO_MAT, TRE, NGHI_CO_PHEP, NGHI_KHONG_PHEP, HOC_BU }

enum AttendanceParticipationType { CHINH, DOI_CA, HOC_BU }

class AttendanceRecord {
  final int? id;
  final int idBuoiHoc;
  final int idHocSinh;
  final int idLopGoc;
  final AttendanceStatus trangThai;
  final AttendanceParticipationType loaiThamGia;
  final int? idBuoiVangGoc;
  final String? ghiChu;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  AttendanceRecord({
    this.id,
    required this.idBuoiHoc,
    required this.idHocSinh,
    required this.idLopGoc,
    required this.trangThai,
    this.loaiThamGia = AttendanceParticipationType.CHINH,
    this.idBuoiVangGoc,
    this.ghiChu,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'id_buoi_hoc': idBuoiHoc,
      'id_hoc_sinh': idHocSinh,
      'id_lop_goc': idLopGoc,
      'trang_thai': trangThai.name,
      'loai_tham_gia': loaiThamGia.name,
      'id_buoi_vang_goc': idBuoiVangGoc,
      'ghi_chu': ghiChu,
      'created_at':
          createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  factory AttendanceRecord.fromMap(Map<String, dynamic> map) {
    return AttendanceRecord(
      id: map['id'] as int?,
      idBuoiHoc: map['id_buoi_hoc'] as int,
      idHocSinh: map['id_hoc_sinh'] as int,
      idLopGoc: map['id_lop_goc'] as int,
      trangThai: AttendanceStatus.values.byName(map['trang_thai'] as String),
      loaiThamGia: AttendanceParticipationType.values.byName(
        map['loai_tham_gia'] as String,
      ),
      idBuoiVangGoc: map['id_buoi_vang_goc'] as int?,
      ghiChu: map['ghi_chu'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}
