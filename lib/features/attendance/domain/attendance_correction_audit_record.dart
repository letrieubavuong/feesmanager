class AttendanceCorrectionAuditRecord {
  final int? id;
  final int? idDiemDanh;
  final int idBuoiHoc;
  final int idHocSinh;
  final String? trangThaiCu;
  final String trangThaiMoi;
  final String lyDo;
  final DateTime changedAt;
  final String? studentName;

  const AttendanceCorrectionAuditRecord({
    this.id,
    this.idDiemDanh,
    required this.idBuoiHoc,
    required this.idHocSinh,
    this.trangThaiCu,
    required this.trangThaiMoi,
    required this.lyDo,
    required this.changedAt,
    this.studentName,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (idDiemDanh != null) 'id_diem_danh': idDiemDanh,
      'id_buoi_hoc': idBuoiHoc,
      'id_hoc_sinh': idHocSinh,
      'trang_thai_cu': trangThaiCu,
      'trang_thai_moi': trangThaiMoi,
      'ly_do': lyDo,
      'changed_at': changedAt.toIso8601String(),
    };
  }

  factory AttendanceCorrectionAuditRecord.fromMap(Map<String, dynamic> map) {
    return AttendanceCorrectionAuditRecord(
      id: map['id'] as int?,
      idDiemDanh: map['id_diem_danh'] as int?,
      idBuoiHoc: map['id_buoi_hoc'] as int,
      idHocSinh: map['id_hoc_sinh'] as int,
      trangThaiCu: map['trang_thai_cu'] as String?,
      trangThaiMoi: map['trang_thai_moi'] as String,
      lyDo: map['ly_do'] as String,
      changedAt: DateTime.parse(map['changed_at'] as String),
      studentName: map['ho_ten'] as String?,
    );
  }
}
