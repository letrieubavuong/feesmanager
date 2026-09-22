import 'package:intl/intl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/database/database_provider.dart';
import '../../classes/domain/class_service.dart';
import '../data/tuition_policy_repository.dart';
import 'tuition_policy.dart';

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

  TuitionPolicyService(this._repo, this._classService);

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
    required String effectiveFrom, // YYYY-MM-DD
    String? effectiveTo, // YYYY-MM-DD
    int standardSessionsPerMonth = 12,
    required int feePerSession,
    int? monthlyMaxFee,
    String? note,
  }) async {
    final cls = await _classService.getClassById(classId);
    if (cls == null) throw Exception('Không tìm thấy lớp học');

    _validateIsoDate(effectiveFrom);
    if (effectiveTo != null && effectiveTo.isNotEmpty) {
      _validateIsoDate(effectiveTo);
      if (effectiveTo.compareTo(effectiveFrom) < 0) {
        throw Exception('Ngày kết thúc phải lớn hơn hoặc bằng ngày bắt đầu');
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

    // Check existing policies for overlap
    final existingPolicies = await _repo.getPoliciesForClass(classId);

    for (final p in existingPolicies) {
      final pTo = p.hieuLucDen ?? '9999-12-31';
      final newTo = effectiveTo ?? '9999-12-31';

      final overlap =
          effectiveFrom.compareTo(pTo) <= 0 &&
          newTo.compareTo(p.hieuLucTu) >= 0;

      if (overlap) {
        // If existing policy is open and starts before new policy, close it day before effectiveFrom
        if (p.hieuLucDen == null && p.hieuLucTu.compareTo(effectiveFrom) < 0) {
          final fromDt = DateTime.parse(effectiveFrom);
          final dayBefore = fromDt.subtract(const Duration(days: 1));
          final closeDateStr = DateFormat('yyyy-MM-dd').format(dayBefore);
          await _repo.closeOpenPolicy(classId, closeDateStr);
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

    final id = await _repo.insert(policy);
    return (await _repo.getById(id))!;
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
  return TuitionPolicyService(repo, classService);
}
