// ignore_for_file: constant_identifier_names

enum TuitionInvoiceStatus { NHAP, DA_CHOT, DA_THANH_TOAN, CON_NO }

class TuitionInvoice {
  final int? id;
  final int idHocSinh;
  final int idLop;
  final String thang; // YYYY-MM
  final int idChinhSachHocPhi;
  final int soBuoiEligible;
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
}
