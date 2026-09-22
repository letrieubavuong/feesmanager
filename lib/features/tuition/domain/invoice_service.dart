import 'package:sqflite/sqflite.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/database/database_provider.dart';
import '../../memberships/domain/membership_service.dart';
import '../../session_credits/data/session_credit_repository.dart';
import '../../session_credits/domain/credit_ledger_entry.dart';
import '../../session_credits/domain/credit_ledger_reason.dart';
import '../../session_credits/domain/session_credit_service.dart';
import '../data/tuition_repository.dart';
import 'tuition_invoice.dart';
import 'tuition_preview.dart';
import 'tuition_service.dart';

part 'invoice_service.g.dart';

class InvoiceService {
  final TuitionRepository _tuitionRepo;
  final TuitionService _tuitionService;
  final SessionCreditService _creditService;
  final SessionCreditRepository _creditRepo;
  final MembershipService _membershipService;
  final Database _db;

  InvoiceService(
    this._tuitionRepo,
    this._tuitionService,
    this._creditService,
    this._creditRepo,
    this._membershipService,
    this._db,
  );

  Future<TuitionInvoice?> getInvoice(
    int studentId,
    int classId,
    String month,
  ) => _tuitionRepo.getInvoice(studentId, classId, month);

  Future<List<TuitionInvoice>> getInvoicesForClassMonth(
    int classId,
    String month,
  ) => _tuitionRepo.getInvoicesForClassMonth(classId, month);

  Future<TuitionInvoice> finalizeStudentInvoice(
    int studentId,
    int classId,
    String month,
  ) async {
    final existingInvoice = await getInvoice(studentId, classId, month);
    if (existingInvoice != null &&
        existingInvoice.trangThai == TuitionInvoiceStatus.DA_CHOT) {
      throw Exception(
        'Hóa đơn học phí tháng $month của học sinh đã được chốt. Không thể chốt lại.',
      );
    }

    // Reconcile extra earned credits for month
    await _creditService.reconcileEarnedCreditsForStudentClassMonth(
      studentId,
      classId,
      month,
    );

    // Calculate preview
    final preview = await _tuitionService.previewTuition(
      studentId,
      classId,
      month,
    );

    // Prepare credit consumption ledger entries
    final creditLedgerEntriesToCreate = <CreditLedgerEntry>[];
    final now = DateTime.now();

    for (final c in preview.candidates) {
      if (c.usesCredit) {
        creditLedgerEntriesToCreate.add(
          CreditLedgerEntry(
            idHocSinh: studentId,
            idLop: classId,
            idBuoiHoc: c.session.id,
            ngayHieuLuc: c.session.ngay,
            delta: -1,
            lyDo: CreditLedgerReason.BU_TRU_NGHI_CO_PHEP,
            ghiChu:
                'Bù trừ credit tự động khi chốt học phí tháng $month cho buổi nghỉ (${c.session.ngay})',
            createdAt: now,
          ),
        );
      }
    }

    // Execute atomic SQLite transaction
    TuitionInvoice? createdInvoice;

    await _db.transaction((txn) async {
      // 1. Consume credits if needed
      if (creditLedgerEntriesToCreate.isNotEmpty) {
        await _creditRepo.addLedgerEntriesInTxn(
          txn,
          creditLedgerEntriesToCreate,
        );
      }

      // 2. Build invoice snapshot
      final invoice = TuitionInvoice(
        idHocSinh: studentId,
        idLop: classId,
        thang: month,
        idChinhSachHocPhi: preview.policy.id!,
        soBuoiEligible: preview.soBuoiEligible,
        soBuoiTinhPhi: preview.soBuoiTinhPhi,
        creditOpening: preview.creditOpening,
        creditEarned: preview.creditEarned,
        creditUsed: preview.creditUsed,
        creditClosing: preview.creditClosing,
        tongTruocGiam: preview.tongTruocGiam,
        giamPhanTram: preview.giamPhanTram,
        giamSoTien: preview.giamSoTien,
        soTienPhaiThu: preview.soTienPhaiThu,
        trangThai: TuitionInvoiceStatus.DA_CHOT,
        chotLuc: now,
        ghiChu: 'Chốt học phí tự động tháng $month',
        createdAt: now,
        updatedAt: now,
      );

      final id = await _tuitionRepo.insertInvoiceInTxn(txn, invoice);
      final maps = await txn.query(
        'hoc_phi_thang',
        where: 'id = ?',
        whereArgs: [id],
      );
      createdInvoice = TuitionInvoice.fromMap(maps.first);
    });

    return createdInvoice!;
  }

  Future<List<TuitionInvoice>> finalizeClassInvoices(
    int classId,
    String month,
  ) async {
    final existingInvoices = await getInvoicesForClassMonth(classId, month);
    if (existingInvoices.any(
      (i) => i.trangThai == TuitionInvoiceStatus.DA_CHOT,
    )) {
      throw Exception(
        'Đã có học sinh trong lớp được chốt học phí tháng $month. Không thể chốt hàng loạt.',
      );
    }

    // Reconcile extra earned credits for class month
    await _creditService.reconcileEarnedCreditsForClassMonth(classId, month);

    // Get active memberships in class
    final memberships = await _membershipService.getRoster(
      classId,
      date: DateTime.parse('$month-01'),
    );

    final studentIds = memberships.map((m) => m.idHocSinh).toSet();
    final previews = <TuitionPreview>[];

    for (final sid in studentIds) {
      final p = await _tuitionService.previewTuition(sid, classId, month);
      previews.add(p);
    }

    final finalizedInvoices = <TuitionInvoice>[];

    // Atomically finalize all invoices in ONE single transaction
    await _db.transaction((txn) async {
      final now = DateTime.now();

      for (final preview in previews) {
        final creditLedgerEntriesToCreate = <CreditLedgerEntry>[];

        for (final c in preview.candidates) {
          if (c.usesCredit) {
            creditLedgerEntriesToCreate.add(
              CreditLedgerEntry(
                idHocSinh: preview.studentId,
                idLop: classId,
                idBuoiHoc: c.session.id,
                ngayHieuLuc: c.session.ngay,
                delta: -1,
                lyDo: CreditLedgerReason.BU_TRU_NGHI_CO_PHEP,
                ghiChu:
                    'Bù trừ credit tự động khi chốt học phí tháng $month cho buổi nghỉ (${c.session.ngay})',
                createdAt: now,
              ),
            );
          }
        }

        if (creditLedgerEntriesToCreate.isNotEmpty) {
          await _creditRepo.addLedgerEntriesInTxn(
            txn,
            creditLedgerEntriesToCreate,
          );
        }

        final invoice = TuitionInvoice(
          idHocSinh: preview.studentId,
          idLop: classId,
          thang: month,
          idChinhSachHocPhi: preview.policy.id!,
          soBuoiEligible: preview.soBuoiEligible,
          soBuoiTinhPhi: preview.soBuoiTinhPhi,
          creditOpening: preview.creditOpening,
          creditEarned: preview.creditEarned,
          creditUsed: preview.creditUsed,
          creditClosing: preview.creditClosing,
          tongTruocGiam: preview.tongTruocGiam,
          giamPhanTram: preview.giamPhanTram,
          giamSoTien: preview.giamSoTien,
          soTienPhaiThu: preview.soTienPhaiThu,
          trangThai: TuitionInvoiceStatus.DA_CHOT,
          chotLuc: now,
          ghiChu: 'Chốt học phí cả lớp tháng $month',
          createdAt: now,
          updatedAt: now,
        );

        final id = await _tuitionRepo.insertInvoiceInTxn(txn, invoice);
        final maps = await txn.query(
          'hoc_phi_thang',
          where: 'id = ?',
          whereArgs: [id],
        );
        finalizedInvoices.add(TuitionInvoice.fromMap(maps.first));
      }
    });

    return finalizedInvoices;
  }
}

@Riverpod(keepAlive: true)
Future<InvoiceService> invoiceService(InvoiceServiceRef ref) async {
  final tuitionRepo = await ref.watch(tuitionRepositoryProvider.future);
  final tuitionService = await ref.watch(tuitionServiceProvider.future);
  final creditService = await ref.watch(sessionCreditServiceProvider.future);
  final creditRepo = await ref.watch(sessionCreditRepositoryProvider.future);
  final membershipService = await ref.watch(membershipServiceProvider.future);
  final db = await ref.watch(databaseProvider.future);

  return InvoiceService(
    tuitionRepo,
    tuitionService,
    creditService,
    creditRepo,
    membershipService,
    db,
  );
}
