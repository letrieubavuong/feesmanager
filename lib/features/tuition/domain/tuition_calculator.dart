class FeeCalculationResult {
  final int billedSessions;
  final int grossAmount;
  final int cappedAmount;
  final int discountAmount;
  final int netAmount;

  const FeeCalculationResult({
    required this.billedSessions,
    required this.grossAmount,
    required this.cappedAmount,
    required this.discountAmount,
    required this.netAmount,
  });
}

FeeCalculationResult calculateTuitionFee({
  required int sessions,
  required int standardLimit,
  required int unitPrice,
  required int discountPercent,
  int? monthlyCap,
}) {
  if (sessions < 0 ||
      standardLimit <= 0 ||
      unitPrice < 0 ||
      discountPercent < 0 ||
      discountPercent > 100 ||
      (monthlyCap != null && monthlyCap < 0)) {
    throw ArgumentError('Thông số học phí không hợp lệ');
  }

  final billed = sessions > standardLimit ? standardLimit : sessions;
  final gross = billed * unitPrice;
  final capped = (monthlyCap != null && gross > monthlyCap) ? monthlyCap : gross;
  final discount = (capped * discountPercent) ~/ 100;
  final net = capped - discount;

  return FeeCalculationResult(
    billedSessions: billed,
    grossAmount: gross,
    cappedAmount: capped,
    discountAmount: discount,
    netAmount: net,
  );
}
