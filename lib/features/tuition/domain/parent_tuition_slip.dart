import '../../settings/domain/bank_account_settings.dart';

enum ParentTuitionSlipStatus {
  ready,
  projectedSessionsNotGenerated,
  noInvoiceFinalized,
  bankNotConfigured,
  error,
}

class ParentTuitionSlip {
  final int studentId;
  final int classId;
  final String month; // YYYY-MM

  final String studentName;
  final String className;

  final ParentTuitionSlipStatus status;
  final String? errorMessage;

  final int projectedSessionCount;
  final int standardSessionLimit;
  final int projectedExtraCount;
  final int feePerSession;
  final int? monthlyMaxFee;

  final int openingCreditBalance;

  final int presentCount;
  final int lateCount;
  final int excusedAbsenceCount;
  final int unexcusedAbsenceCount;
  final int makeupCompletedCount;

  final String attendanceAsOfDate; // dd/MM/yyyy

  final int amountDue;
  final int totalPaid;
  final int remainingDebt;

  final BankAccountSettings bank;
  final String transferContent;
  final String qrPayload;

  const ParentTuitionSlip({
    required this.studentId,
    required this.classId,
    required this.month,
    required this.studentName,
    required this.className,
    required this.status,
    this.errorMessage,
    this.projectedSessionCount = 0,
    this.standardSessionLimit = 12,
    this.projectedExtraCount = 0,
    this.feePerSession = 0,
    this.monthlyMaxFee,
    this.openingCreditBalance = 0,
    this.presentCount = 0,
    this.lateCount = 0,
    this.excusedAbsenceCount = 0,
    this.unexcusedAbsenceCount = 0,
    this.makeupCompletedCount = 0,
    this.attendanceAsOfDate = '',
    this.amountDue = 0,
    this.totalPaid = 0,
    this.remainingDebt = 0,
    required this.bank,
    this.transferContent = '',
    this.qrPayload = '',
  });

  bool get isReady => status == ParentTuitionSlipStatus.ready;
}
