// ignore_for_file: constant_identifier_names

enum CreditLedgerReason {
  VUOT_SO_BUOI_CHUAN,
  BU_TRU_NGHI_CO_PHEP,
  DIEU_CHINH_THU_CONG,
  MIGRATION;

  String get label {
    switch (this) {
      case CreditLedgerReason.VUOT_SO_BUOI_CHUAN:
        return 'Vượt số buổi chuẩn';
      case CreditLedgerReason.BU_TRU_NGHI_CO_PHEP:
        return 'Bù trừ nghỉ có phép';
      case CreditLedgerReason.DIEU_CHINH_THU_CONG:
        return 'Điều chỉnh thủ công';
      case CreditLedgerReason.MIGRATION:
        return 'Dữ liệu chuyển đổi';
    }
  }

  static CreditLedgerReason fromString(String name) {
    return CreditLedgerReason.values.firstWhere(
      (e) => e.name == name,
      orElse: () => throw ArgumentError('Tên lý do credit không hợp lệ: $name'),
    );
  }
}
