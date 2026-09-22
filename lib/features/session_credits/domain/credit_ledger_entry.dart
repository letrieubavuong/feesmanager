import 'credit_ledger_reason.dart';

class CreditLedgerEntry {
  final int? id;
  final int idHocSinh;
  final int idLop;
  final int? idBuoiHoc;
  final String ngayHieuLuc; // YYYY-MM-DD
  final int delta;
  final CreditLedgerReason lyDo;
  final String? ghiChu;
  final DateTime createdAt;

  const CreditLedgerEntry({
    this.id,
    required this.idHocSinh,
    required this.idLop,
    this.idBuoiHoc,
    required this.ngayHieuLuc,
    required this.delta,
    required this.lyDo,
    this.ghiChu,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'id_hoc_sinh': idHocSinh,
      'id_lop': idLop,
      'id_buoi_hoc': idBuoiHoc,
      'ngay_hieu_luc': ngayHieuLuc,
      'delta': delta,
      'ly_do': lyDo.name,
      'ghi_chu': ghiChu,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory CreditLedgerEntry.fromMap(Map<String, dynamic> map) {
    return CreditLedgerEntry(
      id: map['id'] as int?,
      idHocSinh: map['id_hoc_sinh'] as int,
      idLop: map['id_lop'] as int,
      idBuoiHoc: map['id_buoi_hoc'] as int?,
      ngayHieuLuc: map['ngay_hieu_luc'] as String,
      delta: map['delta'] as int,
      lyDo: CreditLedgerReason.fromString(map['ly_do'] as String),
      ghiChu: map['ghi_chu'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  CreditLedgerEntry copyWith({
    int? id,
    int? idHocSinh,
    int? idLop,
    int? idBuoiHoc,
    String? ngayHieuLuc,
    int? delta,
    CreditLedgerReason? lyDo,
    String? ghiChu,
    DateTime? createdAt,
  }) {
    return CreditLedgerEntry(
      id: id ?? this.id,
      idHocSinh: idHocSinh ?? this.idHocSinh,
      idLop: idLop ?? this.idLop,
      idBuoiHoc: idBuoiHoc ?? this.idBuoiHoc,
      ngayHieuLuc: ngayHieuLuc ?? this.ngayHieuLuc,
      delta: delta ?? this.delta,
      lyDo: lyDo ?? this.lyDo,
      ghiChu: ghiChu ?? this.ghiChu,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
