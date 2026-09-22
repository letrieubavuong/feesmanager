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
        existingInvoice.trangThai.isFinalizedSnapshot) {
      throw Exception(
        'Hóa đơn học phí tháng $month của học sinh đã được chốt. Không thể chốt lại.',
      );
    }

    // 1. Calculate missing extra earned credit entries (pure read plan)
    final missingEarnedEntries = await _creditService
        .getMissingEarnedCreditEntriesForStudentClassMonth(
          studentId,
          classId,
          month,
        );

    // 2. Calculate preview (pure read plan)
    final preview = await _tuitionService.previewTuition(
      studentId,
      classId,
      month,
    );

    // 3. Prepare credit consumption ledger entries
    final creditConsumptionEntries = <CreditLedgerEntry>[];
    final now = DateTime.now();

    for (final c in preview.candidates) {
      if (c.usesCredit) {
        creditConsumptionEntries.add(
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

    // 4. Execute ALL mutations in ONE single atomic SQLite transaction
    TuitionInvoice? createdInvoice;

    await _db.transaction((txn) async {
      // 4a. Apply extra earned credits
      if (missingEarnedEntries.isNotEmpty) {
        await _creditRepo.addLedgerEntriesInTxn(txn, missingEarnedEntries);
      }

      // 4b. Apply credit consumption
      if (creditConsumptionEntries.isNotEmpty) {
        await _creditRepo.addLedgerEntriesInTxn(txn, creditConsumptionEntries);
      }

      // 4c. Insert invoice snapshot
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
    if (existingInvoices.any((i) => i.trangThai.isFinalizedSnapshot)) {
      throw Exception(
        'Đã có học sinh trong lớp được chốt học phí tháng $month. Không thể chốt hàng loạt.',
      );
    }

    // Get active memberships in class for month (including mid-month joins)
    final classMonthMemberships = await _membershipService
        .getMembershipsForClassMonth(classId, month);

    final studentIds = classMonthMemberships.map((m) => m.idHocSinh).toSet();

    final studentPlans = <_StudentFinalizationPlan>[];

    for (final sid in studentIds) {
      final missingEarned = await _creditService
          .getMissingEarnedCreditEntriesForStudentClassMonth(
            sid,
            classId,
            month,
          );

      final preview = await _tuitionService.previewTuition(sid, classId, month);

      studentPlans.add(
        _StudentFinalizationPlan(
          studentId: sid,
          missingEarnedEntries: missingEarned,
          preview: preview,
        ),
      );
    }

    final finalizedInvoices = <TuitionInvoice>[];

    // Atomically finalize all invoices in ONE single transaction
    await _db.transaction((txn) async {
      final now = DateTime.now();

      for (final plan in studentPlans) {
        if (plan.missingEarnedEntries.isNotEmpty) {
          await _creditRepo.addLedgerEntriesInTxn(
            txn,
            plan.missingEarnedEntries,
          );
        }

        final creditConsumptionEntries = <CreditLedgerEntry>[];

        for (final c in plan.preview.candidates) {
          if (c.usesCredit) {
            creditConsumptionEntries.add(
              CreditLedgerEntry(
                idHocSinh: plan.studentId,
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

        if (creditConsumptionEntries.isNotEmpty) {
          await _creditRepo.addLedgerEntriesInTxn(
            txn,
            creditConsumptionEntries,
          );
        }

        final invoice = TuitionInvoice(
          idHocSinh: plan.studentId,
          idLop: classId,
          thang: month,
          idChinhSachHocPhi: plan.preview.policy.id!,
          soBuoiEligible: plan.preview.soBuoiEligible,
          soBuoiTinhPhi: plan.preview.soBuoiTinhPhi,
          creditOpening: plan.preview.creditOpening,
          creditEarned: plan.preview.creditEarned,
          creditUsed: plan.preview.creditUsed,
          creditClosing: plan.preview.creditClosing,
          tongTruocGiam: plan.preview.tongTruocGiam,
          giamPhanTram: plan.preview.giamPhanTram,
          giamSoTien: plan.preview.giamSoTien,
          soTienPhaiThu: plan.preview.soTienPhaiThu,
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

class _StudentFinalizationPlan {
  final int studentId;
  final List<CreditLedgerEntry> missingEarnedEntries;
  final TuitionPreview preview;

  _StudentFinalizationPlan({
    required this.studentId,
    required this.missingEarnedEntries,
    required this.preview,
  });
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
