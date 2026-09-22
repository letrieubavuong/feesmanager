import 'package:intl/intl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/database/database_provider.dart';
import '../../attendance/data/attendance_repository.dart';
import '../../attendance/domain/attendance_service.dart';
import '../../attendance/domain/attendance_state.dart';
import '../../classes/domain/class_service.dart';
import '../../roster/domain/roster_service.dart';
import '../../sessions/domain/class_session.dart';
import '../../sessions/domain/session_service.dart';
import '../../students/domain/student_service.dart';
import '../data/session_credit_repository.dart';
import 'credit_ledger_entry.dart';
import 'credit_ledger_reason.dart';
import 'credit_session_candidate.dart';
import 'monthly_credit_summary.dart';

part 'session_credit_service.g.dart';

@Riverpod(keepAlive: true)
Future<SessionCreditRepository> sessionCreditRepository(
  SessionCreditRepositoryRef ref,
) async {
  final db = await ref.watch(databaseProvider.future);
  return SessionCreditRepository(db);
}

class SessionCreditService {
  static const int defaultStandardSessionsPerMonth = 12;

  final SessionCreditRepository _repo;
  final SessionService _sessionService;
  final RosterService _rosterService;
  final AttendanceRepository _attendanceRepo;
  final StudentService _studentService;
  final ClassService _classService;

  SessionCreditService(
    this._repo,
    this._sessionService,
    this._rosterService,
    this._attendanceRepo,
    this._studentService,
    this._classService,
  );

  Future<int> getBalance(int studentId, int classId) =>
      _repo.getBalance(studentId, classId);

  Future<int> getBalanceAsOf(int studentId, int classId, String asOfDate) {
    _validateIsoDate(asOfDate);
    return _repo.getBalanceAsOf(studentId, classId, asOfDate);
  }

  Future<List<CreditLedgerEntry>> getLedger(int studentId, int classId) =>
      _repo.getLedgerForStudentAndClass(studentId, classId);

  Future<List<ClassSession>> getEligibleSessionsForStudentClassMonth(
    int studentId,
    int classId,
    String month, // YYYY-MM
  ) async {
    _validateIsoMonth(month);

    final fromDate = DateTime.parse('$month-01');
    final toDate = DateTime(fromDate.year, fromDate.month + 1, 0);

    final classSessions = await _sessionService.getSessionsForClassAndRange(
      classId,
      fromDate,
      toDate,
    );

    // Filter: SessionType.CHINH and SessionStatus.DA_HOC
    final candidateSessions = classSessions
        .where(
          (s) =>
              s.loai == SessionType.CHINH &&
              s.trangThai == SessionStatus.DA_HOC,
        )
        .toList();

    // Sort deterministically: ngay ASC, gioBatDau ASC, id ASC
    candidateSessions.sort((a, b) {
      final dateCompare = a.ngay.compareTo(b.ngay);
      if (dateCompare != 0) return dateCompare;
      final timeCompare = a.gioBatDau.compareTo(b.gioBatDau);
      if (timeCompare != 0) return timeCompare;
      return (a.id ?? 0).compareTo(b.id ?? 0);
    });

    final eligibleSessions = <ClassSession>[];

    for (final s in candidateSessions) {
      final roster = await _rosterService.getRosterForSession(s.id!);
      if (!roster.isOperationallyValid) {
        throw Exception(
          'Buổi học (${s.ngay} ${s.gioBatDau}) có lỗi Roster không hợp lệ. Không thể đối soát credit.',
        );
      }

      if (roster.participants.any((p) => p.student.id == studentId)) {
        eligibleSessions.add(s);
      }
    }

    return eligibleSessions;
  }

  Future<MonthlyCreditSummary> previewMonth(
    int studentId,
    int classId,
    String month, // YYYY-MM
  ) async {
    _validateIsoMonth(month);

    final eligibleSessions = await getEligibleSessionsForStudentClassMonth(
      studentId,
      classId,
      month,
    );

    final candidates = <CreditSessionCandidate>[];
    int potentialEarned = 0;
    int recordedEarned = 0;

    for (int i = 0; i < eligibleSessions.length; i++) {
      final session = eligibleSessions[i];
      final index = i + 1; // 1-based
      final isStandard = index <= defaultStandardSessionsPerMonth;
      final isExtra = index > defaultStandardSessionsPerMonth;

      final attRecord = await _attendanceRepo.getBySessionAndStudent(
        session.id!,
        studentId,
      );

      final state = attRecord != null
          ? AttendanceState.fromStatus(attRecord.trangThai)
          : AttendanceState.CHUA_DIEM_DANH;

      final earnsCredit =
          isExtra &&
          (state == AttendanceState.CO_MAT || state == AttendanceState.TRE);

      if (earnsCredit) potentialEarned++;

      final existingEarnedEntry = await _repo.getEarnedEntryForSession(
        studentId,
        classId,
        session.id!,
        CreditLedgerReason.VUOT_SO_BUOI_CHUAN,
      );

      if (existingEarnedEntry != null) recordedEarned++;

      candidates.add(
        CreditSessionCandidate(
          session: session,
          index: index,
          isStandard: isStandard,
          isExtra: isExtra,
          attendanceState: state,
          earnsCredit: earnsCredit,
          existingEarnedLedgerEntry: existingEarnedEntry,
        ),
      );
    }

    // Calculate opening balance as of day before $month-01
    final monthStart = DateTime.parse('$month-01');
    final dayBeforeMonth = monthStart.subtract(const Duration(days: 1));
    final openingDateStr = DateFormat('yyyy-MM-dd').format(dayBeforeMonth);

    final openingBalance = await _repo.getBalanceAsOf(
      studentId,
      classId,
      openingDateStr,
    );

    final monthLedger = await _repo.getLedgerForMonth(
      studentId,
      classId,
      month,
    );

    final monthDelta = monthLedger.fold<int>(0, (sum, e) => sum + e.delta);
    final closingBalance = await _repo.getBalance(studentId, classId);

    final standardCount = candidates.where((c) => c.isStandard).length;
    final extraCount = candidates.where((c) => c.isExtra).length;

    return MonthlyCreditSummary(
      studentId: studentId,
      classId: classId,
      month: month,
      standardSessionLimit: defaultStandardSessionsPerMonth,
      eligibleCount: eligibleSessions.length,
      standardCount: standardCount,
      extraCount: extraCount,
      potentialEarned: potentialEarned,
      recordedEarned: recordedEarned,
      openingBalance: openingBalance,
      monthDelta: monthDelta,
      closingBalance: closingBalance,
      candidates: candidates,
    );
  }

  Future<void> reconcileEarnedCreditsForStudentClassMonth(
    int studentId,
    int classId,
    String month,
  ) async {
    final summary = await previewMonth(studentId, classId, month);

    final toCreate = <CreditLedgerEntry>[];
    final now = DateTime.now();

    for (final candidate in summary.candidates) {
      if (candidate.isExtra &&
          candidate.earnsCredit &&
          candidate.existingEarnedLedgerEntry == null) {
        toCreate.add(
          CreditLedgerEntry(
            idHocSinh: studentId,
            idLop: classId,
            idBuoiHoc: candidate.session.id,
            ngayHieuLuc: candidate.session.ngay,
            delta: 1,
            lyDo: CreditLedgerReason.VUOT_SO_BUOI_CHUAN,
            ghiChu:
                'Cộng credit tự động cho buổi học vượt chuẩn thứ ${candidate.index} (${candidate.session.ngay})',
            createdAt: now,
          ),
        );
      }
    }

    if (toCreate.isNotEmpty) {
      await _repo.addLedgerEntriesInTransaction(toCreate);
    }
  }

  Future<void> reconcileEarnedCreditsForClassMonth(
    int classId,
    String month,
  ) async {
    _validateIsoMonth(month);

    final fromDate = DateTime.parse('$month-01');
    final toDate = DateTime(fromDate.year, fromDate.month + 1, 0);

    final classSessions = await _sessionService.getSessionsForClassAndRange(
      classId,
      fromDate,
      toDate,
    );

    final studentIds = <int>{};
    for (final s in classSessions) {
      if (s.loai == SessionType.CHINH && s.trangThai == SessionStatus.DA_HOC) {
        final roster = await _rosterService.getRosterForSession(s.id!);
        if (roster.isOperationallyValid) {
          for (final p in roster.participants) {
            if (p.student.id != null) studentIds.add(p.student.id!);
          }
        }
      }
    }

    for (final studentId in studentIds) {
      await reconcileEarnedCreditsForStudentClassMonth(
        studentId,
        classId,
        month,
      );
    }
  }

  Future<void> addManualAdjustment({
    required int studentId,
    required int classId,
    required int delta,
    required String effectiveDate,
    required String note,
  }) async {
    final student = await _studentService.getStudentById(studentId);
    if (student == null) throw Exception('Không tìm thấy học sinh');

    final cls = await _classService.getClassById(classId);
    if (cls == null) throw Exception('Không tìm thấy lớp học');

    if (delta == 0) {
      throw Exception('Số buổi điều chỉnh (delta) phải khác 0');
    }

    _validateIsoDate(effectiveDate);

    if (note.trim().isEmpty) {
      throw Exception('Vui lòng nhập ghi chú nguyên nhân điều chỉnh thủ công');
    }

    final entry = CreditLedgerEntry(
      idHocSinh: studentId,
      idLop: classId,
      idBuoiHoc: null,
      ngayHieuLuc: effectiveDate,
      delta: delta,
      lyDo: CreditLedgerReason.DIEU_CHINH_THU_CONG,
      ghiChu: note.trim(),
      createdAt: DateTime.now(),
    );

    await _repo.addLedgerEntry(entry);
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
Future<SessionCreditService> sessionCreditService(
  SessionCreditServiceRef ref,
) async {
  final repo = await ref.watch(sessionCreditRepositoryProvider.future);
  final sessionService = await ref.watch(sessionServiceProvider.future);
  final rosterService = await ref.watch(rosterServiceProvider.future);
  final attendanceRepo = await ref.watch(attendanceRepositoryProvider.future);
  final studentService = await ref.watch(studentServiceProvider.future);
  final classService = await ref.watch(classServiceProvider.future);

  return SessionCreditService(
    repo,
    sessionService,
    rosterService,
    attendanceRepo,
    studentService,
    classService,
  );
}
