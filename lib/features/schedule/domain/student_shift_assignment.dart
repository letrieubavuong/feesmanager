class StudentShiftAssignment {
  final int? id;
  final int idHocSinh;
  final int idLop;
  final int idLichHoc;
  final String tuNgay; // YYYY-MM-DD
  final String? denNgay; // YYYY-MM-DD
  final String? nguon;
  final String? ghiChu;
  final DateTime createdAt;
  final DateTime updatedAt;

  const StudentShiftAssignment({
    this.id,
    required this.idHocSinh,
    required this.idLop,
    required this.idLichHoc,
    required this.tuNgay,
    this.denNgay,
    this.nguon,
    this.ghiChu,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'id_hoc_sinh': idHocSinh,
      'id_lop': idLop,
      'id_lich_hoc': idLichHoc,
      'tu_ngay': tuNgay,
      'den_ngay': denNgay,
      'nguon': nguon,
      'ghi_chu': ghiChu,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory StudentShiftAssignment.fromMap(Map<String, dynamic> map) {
    return StudentShiftAssignment(
      id: map['id'] as int?,
      idHocSinh: map['id_hoc_sinh'] as int,
      idLop: map['id_lop'] as int,
      idLichHoc: map['id_lich_hoc'] as int,
      tuNgay: map['tu_ngay'] as String,
      denNgay: map['den_ngay'] as String?,
      nguon: map['nguon'] as String?,
      ghiChu: map['ghi_chu'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  StudentShiftAssignment copyWith({
    int? id,
    int? idHocSinh,
    int? idLop,
    int? idLichHoc,
    String? tuNgay,
    String? denNgay,
    String? nguon,
    String? ghiChu,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StudentShiftAssignment(
      id: id ?? this.id,
      idHocSinh: idHocSinh ?? this.idHocSinh,
      idLop: idLop ?? this.idLop,
      idLichHoc: idLichHoc ?? this.idLichHoc,
      tuNgay: tuNgay ?? this.tuNgay,
      denNgay: denNgay ?? this.denNgay,
      nguon: nguon ?? this.nguon,
      ghiChu: ghiChu ?? this.ghiChu,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
