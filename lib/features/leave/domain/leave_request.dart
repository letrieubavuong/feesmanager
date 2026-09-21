// ignore_for_file: constant_identifier_names

enum LeaveRequestStatus { CHO_DUYET, DA_DUYET, TU_CHOI }

class LeaveRequest {
  final int? id;
  final int idHocSinh;
  final int idLop;
  final String tuNgay;
  final String denNgay;
  final String? lyDo;
  final LeaveRequestStatus trangThai;
  final String? ghiChu;
  final DateTime createdAt;
  final DateTime updatedAt;

  const LeaveRequest({
    this.id,
    required this.idHocSinh,
    required this.idLop,
    required this.tuNgay,
    required this.denNgay,
    this.lyDo,
    this.trangThai = LeaveRequestStatus.CHO_DUYET,
    this.ghiChu,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'id_hoc_sinh': idHocSinh,
      'id_lop': idLop,
      'tu_ngay': tuNgay,
      'den_ngay': denNgay,
      'ly_do': lyDo,
      'trang_thai': trangThai.name,
      'ghi_chu': ghiChu,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory LeaveRequest.fromMap(Map<String, dynamic> map) {
    return LeaveRequest(
      id: map['id'] as int?,
      idHocSinh: map['id_hoc_sinh'] as int,
      idLop: map['id_lop'] as int,
      tuNgay: map['tu_ngay'] as String,
      denNgay: map['den_ngay'] as String,
      lyDo: map['ly_do'] as String?,
      trangThai: LeaveRequestStatus.values.byName(map['trang_thai'] as String),
      ghiChu: map['ghi_chu'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  LeaveRequest copyWith({
    int? id,
    int? idHocSinh,
    int? idLop,
    String? tuNgay,
    String? denNgay,
    String? lyDo,
    LeaveRequestStatus? trangThai,
    String? ghiChu,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LeaveRequest(
      id: id ?? this.id,
      idHocSinh: idHocSinh ?? this.idHocSinh,
      idLop: idLop ?? this.idLop,
      tuNgay: tuNgay ?? this.tuNgay,
      denNgay: denNgay ?? this.denNgay,
      lyDo: lyDo ?? this.lyDo,
      trangThai: trangThai ?? this.trangThai,
      ghiChu: ghiChu ?? this.ghiChu,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
