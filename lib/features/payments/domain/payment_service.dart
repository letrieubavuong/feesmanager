import 'package:intl/intl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sqflite/sqflite.dart';
import '../../../core/database/database_provider.dart';
import '../../tuition/data/tuition_repository.dart';
import '../../tuition/domain/tuition_invoice.dart';
import '../../tuition/domain/tuition_service.dart';

import '../data/payment_repository.dart';
import 'invoice_payment_summary.dart';
import 'payment.dart';
import 'payment_method.dart';

part 'payment_service.g.dart';

@Riverpod(keepAlive: true)
Future<PaymentRepository> paymentRepository(PaymentRepositoryRef ref) async {
  final db = await ref.watch(databaseProvider.future);
  return PaymentRepository(db);
}

class PaymentService {
  final PaymentRepository _paymentRepo;
  final TuitionRepository _tuitionRepo;
  final Database _db;

  PaymentService(this._paymentRepo, this._tuitionRepo, this._db);

  Future<Payment> recordPayment({
    required int studentId,
    required int classId,
    required String month, // YYYY-MM
    required int amount,
    required String paymentDate, // YYYY-MM-DD
    required PaymentMethod method,
    String? transactionId,
    String? note,
  }) async {
    _validateIsoMonth(month);
    _validateIsoDate(paymentDate);

    if (amount <= 0) {
      throw Exception('Số tiền thanh toán phải lớn hơn 0');
    }

    final trimmedTxId = transactionId?.trim().isEmpty == true
        ? null
        : transactionId?.trim();

    final invoice = await _tuitionRepo.getInvoice(studentId, classId, month);
    if (invoice == null) {
      throw Exception(
        'Không tìm thấy hóa đơn học phí cho học sinh trong tháng $month',
      );
    }

    if (!invoice.trangThai.isFinalizedSnapshot) {
      throw Exception(
        'Chưa thể ghi nhận thanh toán cho hóa đơn nháp. Vui lòng chốt học phí trước.',
      );
    }

    if (invoice.idHocSinh != studentId ||
        invoice.idLop != classId ||
        invoice.thang != month) {
      throw Exception(
        'Thông tin học sinh, lớp hoặc tháng không khớp với hóa đơn',
      );
    }

    final currentTotalPaid = await _paymentRepo.getTotalPaidForInvoice(
      invoice.id!,
    );
    final remainingDebt = invoice.soTienPhaiThu - currentTotalPaid;

    if (invoice.soTienPhaiThu == 0 || remainingDebt <= 0) {
      throw Exception(
        'Hóa đơn đã được thanh toán đủ. Không thể ghi nhận thêm thanh toán.',
      );
    }

    if (amount > remainingDebt) {
      throw Exception(
        'Số tiền thanh toán (${NumberFormat('#,###').format(amount)}đ) vượt quá dư nợ còn lại (${NumberFormat('#,###').format(remainingDebt)}đ)',
      );
    }

    if (trimmedTxId != null) {
      final existingTx = await _paymentRepo.findByTransactionId(trimmedTxId);
      if (existingTx != null) {
        throw Exception(
          'Mã giao dịch "$trimmedTxId" đã tồn tại trong hệ thống.',
        );
      }
    }

    final newTotalPaid = currentTotalPaid + amount;
    final TuitionInvoiceStatus newStatus;

    if (newTotalPaid == invoice.soTienPhaiThu) {
      newStatus = TuitionInvoiceStatus.DA_THANH_TOAN;
    } else if (newTotalPaid > 0) {
      newStatus = TuitionInvoiceStatus.CON_NO;
    } else {
      newStatus = TuitionInvoiceStatus.DA_CHOT;
    }

    final now = DateTime.now();
    final payment = Payment(
      studentId: studentId,
      classId: classId,
      invoiceId: invoice.id!,
      month: month,
      amount: amount,
      paymentDate: paymentDate,
      method: method,
      transactionId: trimmedTxId,
      note: note?.trim().isEmpty == true ? null : note?.trim(),
      createdAt: now,
    );

    Payment? createdPayment;

    // Single atomic transaction for payment insertion & invoice status update
    await _db.transaction((txn) async {
      final id = await _paymentRepo.insertInTxn(txn, payment);
      await _tuitionRepo.updateInvoiceStatusInTxn(
        txn,
        invoice.id!,
        newStatus,
        now,
      );

      final maps = await txn.query(
        'thanh_toan',
        where: 'id = ?',
        whereArgs: [id],
      );
      createdPayment = Payment.fromMap(maps.first);
    });

    return createdPayment!;
  }

  Future<InvoicePaymentSummary?> getPaymentSummary(
    int studentId,
    int classId,
    String month,
  ) async {
    final invoice = await _tuitionRepo.getInvoice(studentId, classId, month);
    if (invoice == null) return null;

    final payments = await _paymentRepo.getPaymentsForInvoice(invoice.id!);
    return InvoicePaymentSummary.calculate(
      invoice: invoice,
      payments: payments,
    );
  }

  Future<List<Payment>> getPaymentsForStudentClassMonth(
    int studentId,
    int classId,
    String month,
  ) {
    return _paymentRepo.getPaymentsForStudentClassMonth(
      studentId,
      classId,
      month,
    );
  }

  void _validateIsoMonth(String month) {
    final monthRegExp = RegExp(r'^\d{4}-(0[1-9]|1[0-2])$');
    if (!monthRegExp.hasMatch(month)) {
      throw Exception('Định dạng tháng không hợp lệ (YYYY-MM). Ví dụ: 2026-09');
    }
  }

  void _validateIsoDate(String date) {
    try {
      final parsed = DateFormat('yyyy-MM-dd').parseStrict(date);
      final formatted = DateFormat('yyyy-MM-dd').format(parsed);
      if (formatted != date) {
        throw Exception('Ngày không hợp lệ');
      }
    } catch (e) {
      throw Exception('Định dạng ngày không hợp lệ (YYYY-MM-DD)');
    }
  }
}

@Riverpod(keepAlive: true)
Future<PaymentService> paymentService(PaymentServiceRef ref) async {
  final paymentRepo = await ref.watch(paymentRepositoryProvider.future);
  final tuitionRepo = await ref.watch(tuitionRepositoryProvider.future);
  final db = await ref.watch(databaseProvider.future);
  return PaymentService(paymentRepo, tuitionRepo, db);
}
