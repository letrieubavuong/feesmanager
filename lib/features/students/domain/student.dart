class Student {
  final int? id;
  final String hoTen;
  final String? ngaySinh;
  final String? gioiTinh;
  final String? tenPhuHuynh;
  final String? sdtPhuHuynh;
  final String? sdtHocSinh;
  final String? email;
  final String? truongDangHoc;
  final int? khoi;
  final String? diaChi;
  final String? facebook;
  final String? ghiChu;
  final String? zaloUserId;
  final String? zaloDisplayName;
  final String zaloLinkStatus;
  final bool daLuuTru;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Student({
    this.id,
    required this.hoTen,
    this.ngaySinh,
    this.gioiTinh,
    this.tenPhuHuynh,
    this.sdtPhuHuynh,
    this.sdtHocSinh,
    this.email,
    this.truongDangHoc,
    this.khoi,
    this.diaChi,
    this.facebook,
    this.ghiChu,
    this.zaloUserId,
    this.zaloDisplayName,
    this.zaloLinkStatus = 'CHUA_LIEN_KET',
    this.daLuuTru = false,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ho_ten': hoTen.trim(),
      'ngay_sinh': ngaySinh,
      'gioi_tinh': gioiTinh,
      'ten_phu_huynh': tenPhuHuynh,
      'sdt_phu_huynh': sdtPhuHuynh,
      'sdt_hoc_sinh': sdtHocSinh,
      'email': email,
      'truong_dang_hoc': truongDangHoc,
      'khoi': khoi,
      'dia_chi': diaChi,
      'facebook': facebook,
      'ghi_chu': ghiChu,
      'zalo_user_id': zaloUserId,
      'zalo_display_name': zaloDisplayName,
      'zalo_link_status': zaloLinkStatus,
      'da_luu_tru': daLuuTru ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      id: map['id'] as int?,
      hoTen: map['ho_ten'] as String,
      ngaySinh: map['ngay_sinh'] as String?,
      gioiTinh: map['gioi_tinh'] as String?,
      tenPhuHuynh: map['ten_phu_huynh'] as String?,
      sdtPhuHuynh: map['sdt_phu_huynh'] as String?,
      sdtHocSinh: map['sdt_hoc_sinh'] as String?,
      email: map['email'] as String?,
      truongDangHoc: map['truong_dang_hoc'] as String?,
      khoi: map['khoi'] as int?,
      diaChi: map['dia_chi'] as String?,
      facebook: map['facebook'] as String?,
      ghiChu: map['ghi_chu'] as String?,
      zaloUserId: map['zalo_user_id'] as String?,
      zaloDisplayName: map['zalo_display_name'] as String?,
      zaloLinkStatus: map['zalo_link_status'] as String,
      daLuuTru: (map['da_luu_tru'] as int) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Student copyWith({
    int? id,
    String? hoTen,
    String? ngaySinh,
    String? gioiTinh,
    String? tenPhuHuynh,
    String? sdtPhuHuynh,
    String? sdtHocSinh,
    String? email,
    String? truongDangHoc,
    int? khoi,
    String? diaChi,
    String? facebook,
    String? ghiChu,
    String? zaloUserId,
    String? zaloDisplayName,
    String? zaloLinkStatus,
    bool? daLuuTru,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Student(
      id: id ?? this.id,
      hoTen: hoTen ?? this.hoTen,
      ngaySinh: ngaySinh ?? this.ngaySinh,
      gioiTinh: gioiTinh ?? this.gioiTinh,
      tenPhuHuynh: tenPhuHuynh ?? this.tenPhuHuynh,
      sdtPhuHuynh: sdtPhuHuynh ?? this.sdtPhuHuynh,
      sdtHocSinh: sdtHocSinh ?? this.sdtHocSinh,
      email: email ?? this.email,
      truongDangHoc: truongDangHoc ?? this.truongDangHoc,
      khoi: khoi ?? this.khoi,
      diaChi: diaChi ?? this.diaChi,
      facebook: facebook ?? this.facebook,
      ghiChu: ghiChu ?? this.ghiChu,
      zaloUserId: zaloUserId ?? this.zaloUserId,
      zaloDisplayName: zaloDisplayName ?? this.zaloDisplayName,
      zaloLinkStatus: zaloLinkStatus ?? this.zaloLinkStatus,
      daLuuTru: daLuuTru ?? this.daLuuTru,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
