// ignore_for_file: constant_identifier_names

enum PaymentMethod { TIEN_MAT, CHUYEN_KHOAN, KHAC }

extension PaymentMethodX on PaymentMethod {
  String get displayName => switch (this) {
    PaymentMethod.TIEN_MAT => 'Tiền mặt',
    PaymentMethod.CHUYEN_KHOAN => 'Chuyển khoản',
    PaymentMethod.KHAC => 'Khác',
  };
}
