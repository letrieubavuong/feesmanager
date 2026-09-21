// ignore_for_file: constant_identifier_names

enum SessionType { CHINH, HOC_BU, PHAT_SINH }

enum SessionStatus { DU_KIEN, DA_HOC, HUY, NGHI_LE }

class ClassSession {
  final int? id;
  final int idLop;
  final int? idLichHoc;
  final String ngay; // YYYY-MM-DD
  final String gioBatDau; // HH:mm
  final String gioKetThuc; // HH:mm
  final SessionType loai;
  final SessionStatus trangThai;
  final String? ghiChu;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ClassSession({
    this.id,
    required this.idLop,
    this.idLichHoc,
    required this.ngay,
    required this.gioBatDau,
    required this.gioKetThuc,
    required this.loai,
    this.trangThai = SessionStatus.DU_KIEN,
    this.ghiChu,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'id_lop': idLop,
      'id_lich_hoc': idLichHoc,
      'ngay': ngay,
      'gio_bat_dau': gioBatDau,
      'gio_ket_thuc': gioKetThuc,
      'loai': loai.name,
      'trang_thai': trangThai.name,
      'ghi_chu': ghiChu,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory ClassSession.fromMap(Map<String, dynamic> map) {
    return ClassSession(
      id: map['id'] as int?,
      idLop: map['id_lop'] as int,
      idLichHoc: map['id_lich_hoc'] as int?,
      ngay: map['ngay'] as String,
      gioBatDau: map['gio_bat_dau'] as String,
      gioKetThuc: map['gio_ket_thuc'] as String,
      loai: SessionType.values.byName(map['loai'] as String),
      trangThai: SessionStatus.values.byName(map['trang_thai'] as String),
      ghiChu: map['ghi_chu'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  ClassSession copyWith({
    int? id,
    int? idLop,
    int? idLichHoc,
    String? ngay,
    String? gioBatDau,
    String? gioKetThuc,
    SessionType? loai,
    SessionStatus? trangThai,
    String? ghiChu,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ClassSession(
      id: id ?? this.id,
      idLop: idLop ?? this.idLop,
      idLichHoc: idLichHoc ?? this.idLichHoc,
      ngay: ngay ?? this.ngay,
      gioBatDau: gioBatDau ?? this.gioBatDau,
      gioKetThuc: gioKetThuc ?? this.gioKetThuc,
      loai: loai ?? this.loai,
      trangThai: trangThai ?? this.trangThai,
      ghiChu: ghiChu ?? this.ghiChu,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
