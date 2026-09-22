import 'package:intl/intl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sqflite/sqflite.dart';
import '../../../core/database/database_provider.dart';
import '../../classes/domain/class_service.dart';
import '../../session_credits/data/session_credit_repository.dart';
import '../../session_credits/domain/credit_ledger_reason.dart';
import '../../session_credits/domain/session_credit_service.dart';
import '../data/tuition_policy_repository.dart';
import '../data/tuition_repository.dart';
import 'tuition_policy.dart';
import 'tuition_service.dart';

part 'tuition_policy_service.g.dart';

@Riverpod(keepAlive: true)
Future<TuitionPolicyRepository> tuitionPolicyRepository(
  TuitionPolicyRepositoryRef ref,
) async {
  final db = await ref.watch(databaseProvider.future);
  return TuitionPolicyRepository(db);
}

class TuitionPolicyService {
  final TuitionPolicyRepository _repo;
  final ClassService _classService;
  final TuitionRepository _tuitionRepo;
  final SessionCreditRepository _creditRepo;
  final Database _db;

  SessionCreditRepository get creditRepository => _creditRepo;

  TuitionPolicyService(
    this._repo,
    this._classService,
    this._tuitionRepo,
    this._creditRepo,
    this._db,
  );

  Future<TuitionPolicy?> getEffectivePolicy(int classId, DateTime date) {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    return _repo.getEffectivePolicy(classId, dateStr);
  }

  Future<TuitionPolicy?> getEffectivePolicyForDateStr(
    int classId,
    String dateStr,
  ) {
    _validateIsoDate(dateStr);
    return _repo.getEffectivePolicy(classId, dateStr);
  }

  Future<List<TuitionPolicy>> getPoliciesForClass(int classId) =>
      _repo.getPoliciesForClass(classId);

  Future<TuitionPolicy> createPolicy({
    required int classId,
    required String effectiveFrom, // YYYY-MM-DD (must be YYYY-MM-01)
    String? effectiveTo, // YYYY-MM-DD (must be last day of month)
    int standardSessionsPerMonth =
        TuitionPolicyDefaults.standardSessionsPerMonth,
    required int feePerSession,
    int? monthlyMaxFee,
    String? note,
  }) async {
    final cls = await _classService.getClassById(classId);
    if (cls == null) throw Exception('Không tìm thấy lớp học');

    _validateIsoDate(effectiveFrom);
    if (!effectiveFrom.endsWith('-01')) {
      throw Exception(
        'Ngày bắt đầu hiệu lực của chính sách học phí phải là ngày đầu tháng (YYYY-MM-01)',
      );
    }

    if (effectiveTo != null && effectiveTo.isNotEmpty) {
      _validateIsoDate(effectiveTo);
      if (effectiveTo.compareTo(effectiveFrom) < 0) {
        throw Exception('Ngày kết thúc phải lớn hơn hoặc bằng ngày bắt đầu');
      }

      final parsedTo = DateTime.parse(effectiveTo);
      final lastDayDt = DateTime(parsedTo.year, parsedTo.month + 1, 0);
      final lastDayStr = DateFormat('yyyy-MM-dd').format(lastDayDt);
      if (effectiveTo != lastDayStr) {
        throw Exception(
          'Ngày kết thúc hiệu lực của chính sách học phí phải là ngày cuối tháng ($lastDayStr)',
        );
      }
    } else {
      effectiveTo = null;
    }

    if (standardSessionsPerMonth <= 0) {
      throw Exception('Số buổi chuẩn trong tháng phải lớn hơn 0');
    }

    if (feePerSession < 0) {
      throw Exception('Học phí mỗi buổi phải lớn hơn hoặc bằng 0');
    }

    if (monthlyMaxFee != null && monthlyMaxFee < 0) {
      throw Exception('Mức học phí tối đa tháng phải lớn hơn hoặc bằng 0');
    }

    // Safety check 1: Block creating/editing policy if a finalized invoice exists in affected month range
    final fromMonth = effectiveFrom.substring(0, 7);
    final toMonth = effectiveTo?.substring(0, 7);

    final hasFinalized = await _tuitionRepo
        .hasFinalizedInvoiceForClassFromMonth(
          classId,
          fromMonth,
          toMonth: toMonth,
        );

    if (hasFinalized) {
      throw Exception(
        'Lớp đã có hóa đơn học phí đã chốt trong khoảng thời gian bị ảnh hưởng. Không thể tạo hoặc sửa chính sách học phí quá khứ.',
      );
    }

    // Safety check 2: Protect existing credit ledger from retroactive N changes
    // Query buoi_du_ledger for VUOT_SO_BUOI_CHUAN entries for this class in affected month range
    final whereClause = toMonth != null
        ? 'id_lop = ? AND ly_do = ? AND ngay_hieu_luc >= ? AND ngay_hieu_luc <= ?'
        : 'id_lop = ? AND ly_do = ? AND ngay_hieu_luc >= ?';
    final whereArgs = toMonth != null
        ? [
            classId,
            CreditLedgerReason.VUOT_SO_BUOI_CHUAN.name,
            '$fromMonth-01',
            '$toMonth-31',
          ]
        : [
            classId,
            CreditLedgerReason.VUOT_SO_BUOI_CHUAN.name,
            '$fromMonth-01',
          ];

    final existingCreditMaps = await _db.query(
      'buoi_du_ledger',
      where: whereClause,
      whereArgs: whereArgs,
      limit: 1,
    );

    if (existingCreditMaps.isNotEmpty) {
      final sampleEntryDate =
          existingCreditMaps.first['ngay_hieu_luc'] as String;
      final oldEffective = await _repo.getEffectivePolicy(
        classId,
        sampleEntryDate,
      );
      final oldN =
          oldEffective?.soBuoiChuanThang ??
          TuitionPolicyDefaults.standardSessionsPerMonth;

      if (oldN != standardSessionsPerMonth) {
        throw Exception(
          'Khoảng thời gian này đã có lịch sử cộng credit vượt chuẩn (buổi dư). Không thể thay đổi số buổi chuẩn N quá khứ.',
        );
      }
    }

    // Check existing policies for overlap
    final existingPolicies = await _repo.getPoliciesForClass(classId);
    String? closeDateStr;

    for (final p in existingPolicies) {
      final pTo = p.hieuLucDen ?? '9999-12-31';
      final newTo = effectiveTo ?? '9999-12-31';

      final overlap =
          effectiveFrom.compareTo(pTo) <= 0 &&
          newTo.compareTo(p.hieuLucTu) >= 0;

      if (overlap) {
        // If existing policy is open and starts before new policy, close it day before effectiveFrom
        if (p.hieuLucDen == null && p.hieuLucTu.compareTo(effectiveFrom) < 0) {
          // If new policy is finite, closing old policy would leave a gap from effectiveTo+1 onwards.
          // Check if ANY finalized invoice exists anywhere from fromMonth onwards.
          if (effectiveTo != null) {
            final hasFutureFinalized = await _tuitionRepo
                .hasFinalizedInvoiceForClassFromMonth(classId, fromMonth);
            if (hasFutureFinalized) {
              throw Exception(
                'Lớp đã có hóa đơn học phí đã chốt trong khoảng thời gian bị ảnh hưởng. Không thể đóng chính sách mở bằng một chính sách có ngày kết thúc.',
              );
            }
          }

          final fromDt = DateTime.parse(effectiveFrom);
          final dayBefore = fromDt.subtract(const Duration(days: 1));
          closeDateStr = DateFormat('yyyy-MM-dd').format(dayBefore);
        } else {
          throw Exception(
            'Khoảng thời gian hiệu lực trùng lặp với chính sách học phí đã có (${p.hieuLucTu} - ${p.hieuLucDen ?? "hiện tại"})',
          );
        }
      }
    }

    final now = DateTime.now();
    final policy = TuitionPolicy(
      idLop: classId,
      hieuLucTu: effectiveFrom,
      hieuLucDen: effectiveTo,
      soBuoiChuanThang: standardSessionsPerMonth,
      hocPhiMoiBuoi: feePerSession,
      hocPhiThangToiDa: monthlyMaxFee,
      ghiChu: note?.trim().isEmpty == true ? null : note?.trim(),
      createdAt: now,
      updatedAt: now,
    );

    int? createdId;

    // Single SQLite transaction for close-old + insert-new
    await _db.transaction((txn) async {
      if (closeDateStr != null) {
        await _repo.closeOpenPolicyInTxn(txn, classId, closeDateStr);
      }
      createdId = await _repo.insertInTxn(txn, policy);
    });

    return (await _repo.getById(createdId!))!;
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
Future<TuitionPolicyService> tuitionPolicyService(
  TuitionPolicyServiceRef ref,
) async {
  final repo = await ref.watch(tuitionPolicyRepositoryProvider.future);
  final classService = await ref.watch(classServiceProvider.future);
  final tuitionRepo = await ref.watch(tuitionRepositoryProvider.future);
  final creditRepo = await ref.watch(sessionCreditRepositoryProvider.future);
  final db = await ref.watch(databaseProvider.future);
  return TuitionPolicyService(repo, classService, tuitionRepo, creditRepo, db);
}
