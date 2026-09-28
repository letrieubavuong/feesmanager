import 'payment_method.dart';

class Payment {
  final int? id;
  final int studentId;
  final int classId;
  final int? invoiceId;
  final String month; // YYYY-MM
  final int amount;
  final String paymentDate; // YYYY-MM-DD
  final PaymentMethod method;
  final String? transactionId;
  final String? note;
  final DateTime createdAt;

  Payment({
    this.id,
    required this.studentId,
    required this.classId,
    this.invoiceId,
    required this.month,
    required this.amount,
    required this.paymentDate,
    required this.method,
    this.transactionId,
    this.note,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'id_hoc_sinh': studentId,
    'id_lop': classId,
    'id_hoc_phi_thang': invoiceId,
    'thang': month,
    'so_tien': amount,
    'ngay_thanh_toan': paymentDate,
    'phuong_thuc': method.name,
    'ma_giao_dich': transactionId,
    'ghi_chu': note,
    'created_at': createdAt.toIso8601String(),
  };

  factory Payment.fromMap(Map<String, dynamic> map) => Payment(
    id: map['id'] as int?,
    studentId: map['id_hoc_sinh'] as int,
    classId: map['id_lop'] as int,
    invoiceId: map['id_hoc_phi_thang'] as int?,
    month: map['thang'] as String,
    amount: map['so_tien'] as int,
    paymentDate: map['ngay_thanh_toan'] as String,
    method: PaymentMethod.values.byName(map['phuong_thuc'] as String),
    transactionId: map['ma_giao_dich'] as String?,
    note: map['ghi_chu'] as String?,
    createdAt: DateTime.parse(map['created_at'] as String),
  );

  Payment copyWith({
    int? id,
    int? studentId,
    int? classId,
    int? invoiceId,
    String? month,
    int? amount,
    String? paymentDate,
    PaymentMethod? method,
    String? transactionId,
    String? note,
    DateTime? createdAt,
  }) {
    return Payment(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      classId: classId ?? this.classId,
      invoiceId: invoiceId ?? this.invoiceId,
      month: month ?? this.month,
      amount: amount ?? this.amount,
      paymentDate: paymentDate ?? this.paymentDate,
      method: method ?? this.method,
      transactionId: transactionId ?? this.transactionId,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
