// ignore_for_file: constant_identifier_names

import 'package:flutter/material.dart';

import '../../../app/design_system/app_theme.dart';
import '../../payments/domain/invoice_payment_summary.dart';
import '../../students/domain/student.dart';
import 'tuition_invoice.dart';
import 'tuition_preview.dart';

enum ClassStudentTuitionState {
  PREVIEW_READY,
  PENDING_ATTENDANCE,
  FINALIZED_UNPAID,
  PARTIALLY_PAID,
  PAID,
  NEEDS_RECALCULATION,
  ERROR,
}

class ClassMonthTuitionStudentRow {
  final Student student;
  final TuitionPreview? preview;
  final TuitionInvoice? invoice;
  final InvoicePaymentSummary? paymentSummary;
  final ClassStudentTuitionState state;
  final String? pendingReason;

  ClassMonthTuitionStudentRow({
    required this.student,
    this.preview,
    this.invoice,
    this.paymentSummary,
    required this.state,
    this.pendingReason,
  });

  bool get isFinalized => invoice?.trangThai.isFinalizedSnapshot == true;

  bool get isBlocked =>
      state == ClassStudentTuitionState.PENDING_ATTENDANCE ||
      state == ClassStudentTuitionState.ERROR;

  String get stateLabel {
    switch (state) {
      case ClassStudentTuitionState.PREVIEW_READY:
        return 'Tạm tính (chờ chốt)';
      case ClassStudentTuitionState.PENDING_ATTENDANCE:
        return 'Chờ hoàn tất buổi';
      case ClassStudentTuitionState.FINALIZED_UNPAID:
        return 'Chưa thanh toán';
      case ClassStudentTuitionState.PARTIALLY_PAID:
        return 'Thanh toán một phần';
      case ClassStudentTuitionState.PAID:
        return 'Đã thanh toán';
      case ClassStudentTuitionState.NEEDS_RECALCULATION:
        return 'Cần tính lại';
      case ClassStudentTuitionState.ERROR:
        return 'Lỗi cấu hình';
    }
  }

  Color get stateColor {
    switch (state) {
      case ClassStudentTuitionState.PREVIEW_READY:
        return AppColors.cyanAccent;
      case ClassStudentTuitionState.PENDING_ATTENDANCE:
        return AppColors.warning;
      case ClassStudentTuitionState.FINALIZED_UNPAID:
        return AppColors.error;
      case ClassStudentTuitionState.PARTIALLY_PAID:
        return AppColors.warning;
      case ClassStudentTuitionState.PAID:
        return AppColors.success;
      case ClassStudentTuitionState.NEEDS_RECALCULATION:
        return AppColors.warning;
      case ClassStudentTuitionState.ERROR:
        return AppColors.error;
    }
  }

  bool get hasKnownAmount => isFinalized || preview != null;

  // A failed calculation is unknown, never evidence of payment.
  bool get isFullyPaid =>
      isFinalized &&
      hasKnownAmount &&
      amountDue > 0 &&
      amountPaid >= amountDue &&
      !isBlocked;

  bool get needsCollectionOrResolution => !isFullyPaid;

  String get collectionLabel {
    if (isBlocked) return 'Chưa đủ dữ liệu';
    if (!hasKnownAmount) return 'Chưa tính được';
    if (amountDue == 0) return 'Không phát sinh học phí';
    if (isFullyPaid) return 'Đã thu';
    if (!isFinalized) return 'Tạm tính';
    return amountPaid > 0 ? 'Đã thu một phần' : 'Chưa thanh toán';
  }

  int get amountDue {
    if (isFinalized) {
      return invoice!.soTienPhaiThu;
    }
    return preview?.soTienPhaiThu ?? 0;
  }

  int get amountPaid => paymentSummary?.totalPaid ?? 0;

  int get remainingDebt {
    if (isFinalized) {
      return paymentSummary?.remainingDebt ?? (amountDue - amountPaid);
    }
    return amountDue;
  }
}

class ClassMonthTuitionOverview {
  final int classId;
  final String month;
  final int previewTotalDue;
  final int finalizedTotalDue;
  final int totalPaid;
  final int remainingDebt;

  final int previewStudentCount;
  final int finalizedStudentCount;
  final int pendingStudentCount;

  final List<ClassMonthTuitionStudentRow> studentRows;

  ClassMonthTuitionOverview({
    required this.classId,
    required this.month,
    required this.previewTotalDue,
    required this.finalizedTotalDue,
    required this.totalPaid,
    required this.remainingDebt,
    required this.previewStudentCount,
    required this.finalizedStudentCount,
    required this.pendingStudentCount,
    required this.studentRows,
  });
}
