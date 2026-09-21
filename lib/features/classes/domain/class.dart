class ClassEntity {
  final int? id;
  final String tenLop;
  final int? khoi;
  final String? monHoc;
  final int? siSoToiDa;
  final String? ghiChu;
  final bool daLuuTru;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ClassEntity({
    this.id,
    required this.tenLop,
    this.khoi,
    this.monHoc,
    this.siSoToiDa,
    this.ghiChu,
    this.daLuuTru = false,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ten_lop': tenLop.trim(),
      'khoi': khoi,
      'mon_hoc': monHoc,
      'si_so_toi_da': siSoToiDa,
      'ghi_chu': ghiChu,
      'da_luu_tru': daLuuTru ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory ClassEntity.fromMap(Map<String, dynamic> map) {
    return ClassEntity(
      id: map['id'] as int?,
      tenLop: map['ten_lop'] as String,
      khoi: map['khoi'] as int?,
      monHoc: map['mon_hoc'] as String?,
      siSoToiDa: map['si_so_toi_da'] as int?,
      ghiChu: map['ghi_chu'] as String?,
      daLuuTru: (map['da_luu_tru'] as int) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  ClassEntity copyWith({
    int? id,
    String? tenLop,
    int? khoi,
    String? monHoc,
    int? siSoToiDa,
    String? ghiChu,
    bool? daLuuTru,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ClassEntity(
      id: id ?? this.id,
      tenLop: tenLop ?? this.tenLop,
      khoi: khoi ?? this.khoi,
      monHoc: monHoc ?? this.monHoc,
      siSoToiDa: siSoToiDa ?? this.siSoToiDa,
      ghiChu: ghiChu ?? this.ghiChu,
      daLuuTru: daLuuTru ?? this.daLuuTru,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
