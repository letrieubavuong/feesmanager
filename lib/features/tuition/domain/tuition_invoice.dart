// ignore_for_file: constant_identifier_names

enum TuitionInvoiceStatus { NHAP, DA_CHOT, DA_THANH_TOAN, CON_NO }

extension TuitionInvoiceStatusX on TuitionInvoiceStatus {
  bool get isFinalizedSnapshot =>
      this == TuitionInvoiceStatus.DA_CHOT ||
      this == TuitionInvoiceStatus.DA_THANH_TOAN ||
      this == TuitionInvoiceStatus.CON_NO;
}

class TuitionInvoice {
  final int? id;
  final int idHocSinh;
  final int idLop;
  final String thang; // YYYY-MM
  final int idChinhSachHocPhi;
  final int soBuoiEligible;
  final int soBuoiDuKien;
  final int soBuoiTinhPhi;
  final int creditOpening;
  final int creditEarned;
  final int creditUsed;
  final int creditClosing;
  final int tongTruocGiam;
  final int giamPhanTram;
  final int giamSoTien;
  final int soTienPhaiThu;
  final TuitionInvoiceStatus trangThai;
  final DateTime? chotLuc;
  final String? ghiChu;
  final DateTime createdAt;
  final DateTime updatedAt;

  TuitionInvoice({
    this.id,
    required this.idHocSinh,
    required this.idLop,
    required this.thang,
    required this.idChinhSachHocPhi,
    required this.soBuoiEligible,
    this.soBuoiDuKien = 0,
    required this.soBuoiTinhPhi,
    required this.creditOpening,
    required this.creditEarned,
    required this.creditUsed,
    required this.creditClosing,
    required this.tongTruocGiam,
    required this.giamPhanTram,
    required this.giamSoTien,
    required this.soTienPhaiThu,
    required this.trangThai,
    this.chotLuc,
    this.ghiChu,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'id_hoc_sinh': idHocSinh,
    'id_lop': idLop,
    'thang': thang,
    'id_chinh_sach_hoc_phi': idChinhSachHocPhi,
    'so_buoi_eligible': soBuoiEligible,
    'so_buoi_du_kien': soBuoiDuKien,
    'so_buoi_tinh_phi': soBuoiTinhPhi,
    'credit_opening': creditOpening,
    'credit_earned': creditEarned,
    'credit_used': creditUsed,
    'credit_closing': creditClosing,
    'tong_truoc_giam': tongTruocGiam,
    'giam_phan_tram': giamPhanTram,
    'giam_so_tien': giamSoTien,
    'so_tien_phai_thu': soTienPhaiThu,
    'trang_thai': trangThai.name,
    'chot_luc': chotLuc?.toIso8601String(),
    'ghi_chu': ghiChu,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory TuitionInvoice.fromMap(Map<String, dynamic> map) => TuitionInvoice(
    id: map['id'] as int?,
    idHocSinh: map['id_hoc_sinh'] as int,
    idLop: map['id_lop'] as int,
    thang: map['thang'] as String,
    idChinhSachHocPhi: map['id_chinh_sach_hoc_phi'] as int,
    soBuoiEligible: map['so_buoi_eligible'] as int,
    soBuoiDuKien: map['so_buoi_du_kien'] as int? ?? 0,
    soBuoiTinhPhi: map['so_buoi_tinh_phi'] as int,
    creditOpening: map['credit_opening'] as int,
    creditEarned: map['credit_earned'] as int,
    creditUsed: map['credit_used'] as int,
    creditClosing: map['credit_closing'] as int,
    tongTruocGiam: map['tong_truoc_giam'] as int,
    giamPhanTram: map['giam_phan_tram'] as int? ?? 0,
    giamSoTien: map['giam_so_tien'] as int? ?? 0,
    soTienPhaiThu: map['so_tien_phai_thu'] as int,
    trangThai: TuitionInvoiceStatus.values.byName(map['trang_thai'] as String),
    chotLuc: map['chot_luc'] != null
        ? DateTime.parse(map['chot_luc'] as String)
        : null,
    ghiChu: map['ghi_chu'] as String?,
    createdAt: DateTime.parse(map['created_at'] as String),
    updatedAt: DateTime.parse(map['updated_at'] as String),
  );

  TuitionInvoice copyWith({
    int? id,
    int? idHocSinh,
    int? idLop,
    String? thang,
    int? idChinhSachHocPhi,
    int? soBuoiEligible,
    int? soBuoiDuKien,
    int? soBuoiTinhPhi,
    int? creditOpening,
    int? creditEarned,
    int? creditUsed,
    int? creditClosing,
    int? tongTruocGiam,
    int? giamPhanTram,
    int? giamSoTien,
    int? soTienPhaiThu,
    TuitionInvoiceStatus? trangThai,
    DateTime? chotLuc,
    String? ghiChu,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TuitionInvoice(
      id: id ?? this.id,
      idHocSinh: idHocSinh ?? this.idHocSinh,
      idLop: idLop ?? this.idLop,
      thang: thang ?? this.thang,
      idChinhSachHocPhi: idChinhSachHocPhi ?? this.idChinhSachHocPhi,
      soBuoiEligible: soBuoiEligible ?? this.soBuoiEligible,
      soBuoiDuKien: soBuoiDuKien ?? this.soBuoiDuKien,
      soBuoiTinhPhi: soBuoiTinhPhi ?? this.soBuoiTinhPhi,
      creditOpening: creditOpening ?? this.creditOpening,
      creditEarned: creditEarned ?? this.creditEarned,
      creditUsed: creditUsed ?? this.creditUsed,
      creditClosing: creditClosing ?? this.creditClosing,
      tongTruocGiam: tongTruocGiam ?? this.tongTruocGiam,
      giamPhanTram: giamPhanTram ?? this.giamPhanTram,
      giamSoTien: giamSoTien ?? this.giamSoTien,
      soTienPhaiThu: soTienPhaiThu ?? this.soTienPhaiThu,
      trangThai: trangThai ?? this.trangThai,
      chotLuc: chotLuc ?? this.chotLuc,
      ghiChu: ghiChu ?? this.ghiChu,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
