import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tuition2027/features/attendance/data/attendance_repository.dart';
import 'package:tuition2027/features/attendance/domain/attendance_state.dart';
import 'package:tuition2027/features/classes/data/class_repository.dart';
import 'package:tuition2027/features/classes/domain/class_service.dart';
import 'package:tuition2027/features/memberships/data/membership_repository.dart';
import 'package:tuition2027/features/memberships/domain/membership_service.dart';
import 'package:tuition2027/features/roster/domain/roster_service.dart';
import 'package:tuition2027/features/schedule/data/assignment_repository.dart';
import 'package:tuition2027/features/schedule/data/schedule_repository.dart';
import 'package:tuition2027/features/schedule/domain/schedule_service.dart';
import 'package:tuition2027/features/session_adjustments/data/session_adjustment_repository.dart';
import 'package:tuition2027/features/session_credits/data/session_credit_repository.dart';
import 'package:tuition2027/features/session_credits/domain/credit_ledger_reason.dart';
import 'package:tuition2027/features/session_credits/domain/session_credit_service.dart';
import 'package:tuition2027/features/sessions/data/session_repository.dart';
import 'package:tuition2027/features/sessions/domain/session_service.dart';
import 'package:tuition2027/features/students/data/student_repository.dart';
import 'package:tuition2027/features/students/domain/student_service.dart';
import '../sessions/test_db_helper_v6.dart';

import 'package:tuition2027/features/schedule_conflicts/data/schedule_constraint_repository.dart';
import 'package:tuition2027/features/schedule_conflicts/domain/schedule_conflict_service.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database db;
  late SessionCreditService creditService;
  late SessionCreditRepository creditRepo;
  late SessionService sessionService;
  late RosterService rosterService;

  final nowStr = DateTime.now().toIso8601String();

  setUp(() async {
    db = await TestDbHelperV6.createLatest();

    final studentRepo = StudentRepository(db);
    final membershipRepo = MembershipRepository(db);
    final classRepo = ClassRepository(db);
    final sessionRepo = SessionRepository(db);
    final scheduleRepo = ScheduleRepository(db);
    final assignmentRepo = AssignmentRepository(db);
    final attendanceRepo = AttendanceRepository(db);
    final adjustmentRepo = SessionAdjustmentRepository(db);

    final membershipService = MembershipService(membershipRepo);
    final studentService = StudentService(studentRepo, membershipService);
    final classService = ClassService(classRepo, membershipService);

    final constraintRepo = ScheduleConstraintRepository(db);
    final conflictService = ScheduleConflictService(
      constraintRepo,
      scheduleRepo,
      assignmentRepo,
      sessionRepo,
      adjustmentRepo,
      classService,
    );

    sessionService = SessionService(sessionRepo, classService);
    final scheduleService = ScheduleDomainService(
      scheduleRepo,
      assignmentRepo,
      membershipService,
      classService,
      studentService,
      conflictService,
    );
    rosterService = RosterService(
      sessionService,
      membershipService,
      scheduleService,
      studentService,
      adjustmentRepo,
    );

    creditRepo = SessionCreditRepository(db);
    creditService = SessionCreditService(
      creditRepo,
      sessionService,
      rosterService,
      attendanceRepo,
      studentService,
      classService,
    );
  });

  tearDown(() async => await db.close());

  group('SessionCreditService Domain Tests', () {
    test(
      'Class-scoped credit balance derivation is independent per class',
      () async {
        await db.insert('hoc_sinh', {
          'id': 1,
          'ho_ten': 'Student 1',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
        await db.insert('lop', {
          'id': 10,
          'ten_lop': 'Class A',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
        await db.insert('lop', {
          'id': 20,
          'ten_lop': 'Class B',
          'created_at': nowStr,
          'updated_at': nowStr,
        });

        await creditService.addManualAdjustment(
          studentId: 1,
          classId: 10,
          delta: 3,
          effectiveDate: '2026-09-10',
          note: 'Init A',
        );
        await creditService.addManualAdjustment(
          studentId: 1,
          classId: 20,
          delta: 1,
          effectiveDate: '2026-09-15',
          note: 'Init B',
        );

        expect(await creditService.getBalance(1, 10), 3);
        expect(await creditService.getBalance(1, 20), 1);
      },
    );

    test(
      'Standard (1..12) vs Extra (13+) indexing and attendance credit earning rules',
      () async {
        await db.insert('hoc_sinh', {
          'id': 1,
          'ho_ten': 'S1',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
        await db.insert('lop', {
          'id': 10,
          'ten_lop': 'C10',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
        await db.insert('tham_gia_lop', {
          'id': 100,
          'id_hoc_sinh': 1,
          'id_lop': 10,
          'tu_ngay': '2026-01-01',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
        for (int w = 1; w <= 7; w++) {
          await db.insert('lich_hoc', {
            'id': w,
            'id_lop': 10,
            'thu_trong_tuan': w,
            'gio_bat_dau': '17:30',
            'gio_ket_thuc': '19:00',
            'hieu_luc_tu': '2026-01-01',
            'created_at': nowStr,
            'updated_at': nowStr,
          });
        }

        // Create 15 CHINH DA_HOC sessions in Sept 2026
        for (int day = 1; day <= 15; day++) {
          final dateStr = '2026-09-${day.toString().padLeft(2, '0')}';
          final sessionDate = DateTime.parse(dateStr);
          await db.insert('buoi_hoc', {
            'id': 100 + day,
            'id_lop': 10,
            'id_lich_hoc': sessionDate.weekday,
            'ngay': dateStr,
            'gio_bat_dau': '17:30',
            'gio_ket_thuc': '19:00',
            'loai': 'CHINH',
            'trang_thai': 'DA_HOC',
            'created_at': nowStr,
            'updated_at': nowStr,
          });

          // Set attendance for extra sessions
          if (day == 13) {
            // Extra #13: CO_MAT -> earns credit
            await db.insert('diem_danh', {
              'id_buoi_hoc': 113,
              'id_hoc_sinh': 1,
              'id_lop_goc': 10,
              'trang_thai': 'CO_MAT',
              'loai_tham_gia': 'CHINH',
              'created_at': nowStr,
              'updated_at': nowStr,
            });
          } else if (day == 14) {
            // Extra #14: TRE -> earns credit
            await db.insert('diem_danh', {
              'id_buoi_hoc': 114,
              'id_hoc_sinh': 1,
              'id_lop_goc': 10,
              'trang_thai': 'TRE',
              'loai_tham_gia': 'CHINH',
              'created_at': nowStr,
              'updated_at': nowStr,
            });
          } else if (day == 15) {
            // Extra #15: NGHI_CO_PHEP -> earns 0
            await db.insert('diem_danh', {
              'id_buoi_hoc': 115,
              'id_hoc_sinh': 1,
              'id_lop_goc': 10,
              'trang_thai': 'NGHI_CO_PHEP',
              'loai_tham_gia': 'CHINH',
              'created_at': nowStr,
              'updated_at': nowStr,
            });
          }
        }

        // Preview month
        final preview = await creditService.previewMonth(1, 10, '2026-09');
        expect(preview.eligibleCount, 15);
        expect(preview.standardCount, 12);
        expect(preview.extraCount, 3);
        expect(preview.potentialEarned, 2); // Sessions #13 and #14
        expect(preview.recordedEarned, 0);

        // Verify standard candidates (#1..#12) do NOT earn credit even if present
        expect(preview.candidates.first.isStandard, isTrue);
        expect(preview.candidates.first.earnsCredit, isFalse);

        // Verify extra candidates
        final extra13 = preview.candidates[12]; // index 13
        expect(extra13.isExtra, isTrue);
        expect(extra13.earnsCredit, isTrue);

        final extra14 = preview.candidates[13]; // index 14
        expect(extra14.isExtra, isTrue);
        expect(extra14.earnsCredit, isTrue);

        final extra15 = preview.candidates[14]; // index 15
        expect(extra15.isExtra, isTrue);
        expect(extra15.earnsCredit, isFalse);

        // Reconcile
        await creditService.reconcileEarnedCreditsForStudentClassMonth(
          1,
          10,
          '2026-09',
        );
        expect(await creditService.getBalance(1, 10), 2);

        // Reconcile again (idempotency check)
        await creditService.reconcileEarnedCreditsForStudentClassMonth(
          1,
          10,
          '2026-09',
        );
        expect(await creditService.getBalance(1, 10), 2);

        final ledger = await creditService.getLedger(1, 10);
        expect(ledger.length, 2);
        expect(
          ledger.every((e) => e.lyDo == CreditLedgerReason.VUOT_SO_BUOI_CHUAN),
          isTrue,
        );
      },
    );

    test(
      'HOC_BU and PHAT_SINH sessions are excluded from credit candidate indexing',
      () async {
        await db.insert('hoc_sinh', {
          'id': 1,
          'ho_ten': 'S1',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
        await db.insert('lop', {
          'id': 10,
          'ten_lop': 'C10',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
        await db.insert('tham_gia_lop', {
          'id': 100,
          'id_hoc_sinh': 1,
          'id_lop': 10,
          'tu_ngay': '2026-01-01',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
        for (int w = 1; w <= 7; w++) {
          await db.insert('lich_hoc', {
            'id': w,
            'id_lop': 10,
            'thu_trong_tuan': w,
            'gio_bat_dau': '17:30',
            'gio_ket_thuc': '19:00',
            'hieu_luc_tu': '2026-01-01',
            'created_at': nowStr,
            'updated_at': nowStr,
          });
        }

        // 12 CHINH DA_HOC
        for (int i = 1; i <= 12; i++) {
          final dateStr = '2026-09-${i.toString().padLeft(2, '0')}';
          final sessionDate = DateTime.parse(dateStr);
          await db.insert('buoi_hoc', {
            'id': 100 + i,
            'id_lop': 10,
            'id_lich_hoc': sessionDate.weekday,
            'ngay': dateStr,
            'gio_bat_dau': '17:30',
            'gio_ket_thuc': '19:00',
            'loai': 'CHINH',
            'trang_thai': 'DA_HOC',
            'created_at': nowStr,
            'updated_at': nowStr,
          });
        }

        // 1 HOC_BU DA_HOC & 1 PHAT_SINH DA_HOC
        await db.insert('buoi_hoc', {
          'id': 201,
          'id_lop': 10,
          'ngay': '2026-09-25',
          'gio_bat_dau': '17:30',
          'gio_ket_thuc': '19:00',
          'loai': 'HOC_BU',
          'trang_thai': 'DA_HOC',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
        await db.insert('buoi_hoc', {
          'id': 202,
          'id_lop': 10,
          'ngay': '2026-09-26',
          'gio_bat_dau': '17:30',
          'gio_ket_thuc': '19:00',
          'loai': 'PHAT_SINH',
          'trang_thai': 'DA_HOC',
          'created_at': nowStr,
          'updated_at': nowStr,
        });

        final preview = await creditService.previewMonth(1, 10, '2026-09');
        expect(preview.eligibleCount, 12);
        expect(preview.extraCount, 0);
      },
    );

    test('Pure reads do not mutate buoi_du_ledger table', () async {
      await db.insert('hoc_sinh', {
        'id': 1,
        'ho_ten': 'S1',
        'created_at': nowStr,
        'updated_at': nowStr,
      });
      await db.insert('lop', {
        'id': 10,
        'ten_lop': 'C10',
        'created_at': nowStr,
        'updated_at': nowStr,
      });

      await creditService.previewMonth(1, 10, '2026-09');
      await creditService.getBalance(1, 10);
      await creditService.getBalanceAsOf(1, 10, '2026-09-30');
      await creditService.getLedger(1, 10);

      final rows = await db.query('buoi_du_ledger');
      expect(rows, isEmpty);
    });

    test('Manual adjustment validation and audit trailing', () async {
      await db.insert('hoc_sinh', {
        'id': 1,
        'ho_ten': 'S1',
        'created_at': nowStr,
        'updated_at': nowStr,
      });
      await db.insert('lop', {
        'id': 10,
        'ten_lop': 'C10',
        'created_at': nowStr,
        'updated_at': nowStr,
      });

      // 1. Delta = 0 -> REJECT
      await expectLater(
        creditService.addManualAdjustment(
          studentId: 1,
          classId: 10,
          delta: 0,
          effectiveDate: '2026-09-21',
          note: 'Note',
        ),
        throwsA(isA<Exception>()),
      );

      // 2. Empty note -> REJECT
      await expectLater(
        creditService.addManualAdjustment(
          studentId: 1,
          classId: 10,
          delta: 1,
          effectiveDate: '2026-09-21',
          note: '   ',
        ),
        throwsA(isA<Exception>()),
      );

      // 3. Valid adjustment -> ACCEPT
      await creditService.addManualAdjustment(
        studentId: 1,
        classId: 10,
        delta: 2,
        effectiveDate: '2026-09-21',
        note: 'Thưởng học sinh giỏi',
      );
      expect(await creditService.getBalance(1, 10), 2);

      // 4. Negative adjustment -> ALLOWS negative balance
      await creditService.addManualAdjustment(
        studentId: 1,
        classId: 10,
        delta: -3,
        effectiveDate: '2026-09-22',
        note: 'Điều chỉnh giảm',
      );
      expect(await creditService.getBalance(1, 10), -1);

      // History is append-only
      final ledger = await creditService.getLedger(1, 10);
      expect(ledger.length, 2);
    });

    test('getBalanceAsOf date filtering regression', () async {
      await db.insert('hoc_sinh', {
        'id': 1,
        'ho_ten': 'S1',
        'created_at': nowStr,
        'updated_at': nowStr,
      });
      await db.insert('lop', {
        'id': 10,
        'ten_lop': 'C10',
        'created_at': nowStr,
        'updated_at': nowStr,
      });

      await creditService.addManualAdjustment(
        studentId: 1,
        classId: 10,
        delta: 1,
        effectiveDate: '2026-09-10',
        note: 'A',
      );
      await creditService.addManualAdjustment(
        studentId: 1,
        classId: 10,
        delta: 1,
        effectiveDate: '2026-09-20',
        note: 'B',
      );
      await creditService.addManualAdjustment(
        studentId: 1,
        classId: 10,
        delta: -1,
        effectiveDate: '2026-10-01',
        note: 'C',
      );

      expect(await creditService.getBalanceAsOf(1, 10, '2026-09-15'), 1);
      expect(await creditService.getBalanceAsOf(1, 10, '2026-09-30'), 2);
      expect(await creditService.getBalanceAsOf(1, 10, '2026-10-01'), 1);
    });

    test(
      'Historical month closingBalance ignores entries after selected month',
      () async {
        await db.insert('hoc_sinh', {
          'id': 1,
          'ho_ten': 'S1',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
        await db.insert('lop', {
          'id': 10,
          'ten_lop': 'C10',
          'created_at': nowStr,
          'updated_at': nowStr,
        });

        await creditService.addManualAdjustment(
          studentId: 1,
          classId: 10,
          delta: 1,
          effectiveDate: '2026-08-31',
          note: 'August',
        );
        await creditService.addManualAdjustment(
          studentId: 1,
          classId: 10,
          delta: 1,
          effectiveDate: '2026-09-10',
          note: 'Sept 1',
        );
        await creditService.addManualAdjustment(
          studentId: 1,
          classId: 10,
          delta: 1,
          effectiveDate: '2026-09-20',
          note: 'Sept 2',
        );
        await creditService.addManualAdjustment(
          studentId: 1,
          classId: 10,
          delta: -1,
          effectiveDate: '2026-10-01',
          note: 'October',
        );

        final summary = await creditService.previewMonth(1, 10, '2026-09');
        expect(summary.openingBalance, 1);
        expect(summary.monthDelta, 2);
        expect(
          summary.closingBalance,
          3,
        ); // October -1 does NOT lower September closing balance!
        expect(
          summary.closingBalance,
          summary.openingBalance + summary.monthDelta,
        );
      },
    );

    test(
      'Reconciliation fails closed on blocking canonical roster issue without writing partial ledger',
      () async {
        await db.insert('hoc_sinh', {
          'id': 1,
          'ho_ten': 'S1',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
        await db.insert('lop', {
          'id': 10,
          'ten_lop': 'C10',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
        await db.insert('tham_gia_lop', {
          'id': 100,
          'id_hoc_sinh': 1,
          'id_lop': 10,
          'tu_ngay': '2026-01-01',
          'created_at': nowStr,
          'updated_at': nowStr,
        });

        // Session without schedule link (causes SESSION_SCHEDULE_MISSING issue)
        await db.insert('buoi_hoc', {
          'id': 101,
          'id_lop': 10,
          'id_lich_hoc': null,
          'ngay': '2026-09-21',
          'gio_bat_dau': '17:30',
          'gio_ket_thuc': '19:00',
          'loai': 'CHINH',
          'trang_thai': 'DA_HOC',
          'created_at': nowStr,
          'updated_at': nowStr,
        });

        await expectLater(
          creditService.previewMonth(1, 10, '2026-09'),
          throwsA(isA<Exception>()),
        );

        await expectLater(
          creditService.reconcileEarnedCreditsForStudentClassMonth(
            1,
            10,
            '2026-09',
          ),
          throwsA(isA<Exception>()),
        );

        await expectLater(
          creditService.reconcileEarnedCreditsForClassMonth(10, '2026-09'),
          throwsA(isA<Exception>()),
        );

        final ledger = await db.query('buoi_du_ledger');
        expect(ledger, isEmpty);
      },
    );

    test(
      'Strict month string format validation rejects invalid formats',
      () async {
        await db.insert('hoc_sinh', {
          'id': 1,
          'ho_ten': 'S1',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
        await db.insert('lop', {
          'id': 10,
          'ten_lop': 'C10',
          'created_at': nowStr,
          'updated_at': nowStr,
        });

        for (final invalidMonth in [
          '2026-9',
          '09/2026',
          '2026-00',
          '2026-13',
          'abc',
        ]) {
          await expectLater(
            creditService.previewMonth(1, 10, invalidMonth),
            throwsA(isA<Exception>()),
          );
        }
      },
    );

    test(
      'Reconciliation does NOT auto-consume credits for approved leave in Phase 8',
      () async {
        await db.insert('hoc_sinh', {
          'id': 1,
          'ho_ten': 'S1',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
        await db.insert('lop', {
          'id': 10,
          'ten_lop': 'C10',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
        await db.insert('tham_gia_lop', {
          'id': 100,
          'id_hoc_sinh': 1,
          'id_lop': 10,
          'tu_ngay': '2026-01-01',
          'created_at': nowStr,
          'updated_at': nowStr,
        });

        await creditService.addManualAdjustment(
          studentId: 1,
          classId: 10,
          delta: 5,
          effectiveDate: '2026-09-01',
          note: 'Initial credit',
        );

        await creditService.reconcileEarnedCreditsForStudentClassMonth(
          1,
          10,
          '2026-09',
        );

        final ledger = await creditService.getLedger(1, 10);
        expect(
          ledger.any((e) => e.lyDo == CreditLedgerReason.BU_TRU_NGHI_CO_PHEP),
          isFalse,
        );
      },
    );

    test(
      'DOI_CA counts student exactly once in eligible indexing and earns credit if 13th session',
      () async {
        await db.insert('hoc_sinh', {
          'id': 1,
          'ho_ten': 'S1',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
        await db.insert('lop', {
          'id': 10,
          'ten_lop': 'C10',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
        await db.insert('tham_gia_lop', {
          'id': 100,
          'id_hoc_sinh': 1,
          'id_lop': 10,
          'tu_ngay': '2026-01-01',
          'created_at': nowStr,
          'updated_at': nowStr,
        });

        // 7 schedules for 7 weekdays
        for (int w = 1; w <= 7; w++) {
          await db.insert('lich_hoc', {
            'id': w,
            'id_lop': 10,
            'thu_trong_tuan': w,
            'gio_bat_dau': '17:30',
            'gio_ket_thuc': '19:00',
            'hieu_luc_tu': '2026-01-01',
            'created_at': nowStr,
            'updated_at': nowStr,
          });
        }
        // Single shift assignment for Student 1 to schedule 7 (Sunday Shift A)
        await db.insert('phan_ca_hoc_sinh', {
          'id': 7,
          'id_hoc_sinh': 1,
          'id_lop': 10,
          'id_lich_hoc': 7,
          'tu_ngay': '2026-01-01',
          'created_at': nowStr,
          'updated_at': nowStr,
        });

        // Second shift on Sunday (weekday 7) effective only on 2026-09-13
        await db.insert('lich_hoc', {
          'id': 17,
          'id_lop': 10,
          'thu_trong_tuan': 7,
          'gio_bat_dau': '19:30',
          'gio_ket_thuc': '21:00',
          'hieu_luc_tu': '2026-09-13',
          'hieu_luc_den': '2026-09-13',
          'created_at': nowStr,
          'updated_at': nowStr,
        });

        // Create 12 CHINH DA_HOC sessions on shift 1..12
        for (int i = 1; i <= 12; i++) {
          final dateStr = '2026-09-${i.toString().padLeft(2, '0')}';
          final w = DateTime.parse(dateStr).weekday;
          await db.insert('buoi_hoc', {
            'id': 100 + i,
            'id_lop': 10,
            'id_lich_hoc': w,
            'ngay': dateStr,
            'gio_bat_dau': '17:30',
            'gio_ket_thuc': '19:00',
            'loai': 'CHINH',
            'trang_thai': 'DA_HOC',
            'created_at': nowStr,
            'updated_at': nowStr,
          });
        }

        // On 2026-09-13 (Sunday): Shift A (1013, lich_hoc 7) & Shift B (2013, lich_hoc 17)
        await db.insert('buoi_hoc', {
          'id': 1013,
          'id_lop': 10,
          'id_lich_hoc': 7,
          'ngay': '2026-09-13',
          'gio_bat_dau': '17:30',
          'gio_ket_thuc': '19:00',
          'loai': 'CHINH',
          'trang_thai': 'DA_HOC',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
        await db.insert('buoi_hoc', {
          'id': 2013,
          'id_lop': 10,
          'id_lich_hoc': 17,
          'ngay': '2026-09-13',
          'gio_bat_dau': '19:30',
          'gio_ket_thuc': '21:00',
          'loai': 'CHINH',
          'trang_thai': 'DA_HOC',
          'created_at': nowStr,
          'updated_at': nowStr,
        });

        // DOI_CA from Shift A (1013) to Shift B (2013)
        await db.insert('dieu_chinh_buoi_hoc', {
          'id_hoc_sinh': 1,
          'id_lop_goc': 10,
          'id_buoi_hoc_goc': 1013,
          'id_buoi_hoc_tham_gia': 2013,
          'loai': 'DOI_CA',
          'created_at': nowStr,
        });
        await db.insert('diem_danh', {
          'id_buoi_hoc': 2013,
          'id_hoc_sinh': 1,
          'id_lop_goc': 10,
          'trang_thai': 'CO_MAT',
          'loai_tham_gia': 'DOI_CA',
          'created_at': nowStr,
          'updated_at': nowStr,
        });

        final preview = await creditService.previewMonth(1, 10, '2026-09');
        // Eligible count = 13 (NOT 14!)
        expect(preview.eligibleCount, 13);
        expect(preview.candidates.length, 13);
        final c13 = preview.candidates[12];
        expect(c13.session.id, 2013);
        expect(c13.isExtra, isTrue);
        expect(c13.earnsCredit, isTrue);

        await creditService.reconcileEarnedCreditsForStudentClassMonth(
          1,
          10,
          '2026-09',
        );
        final ledger = await creditService.getLedger(1, 10);
        expect(ledger.length, 1);
        expect(ledger.first.idBuoiHoc, 2013);
      },
    );

    test('Mid-month join excludes sessions before join date', () async {
      await db.insert('hoc_sinh', {
        'id': 1,
        'ho_ten': 'S1',
        'created_at': nowStr,
        'updated_at': nowStr,
      });
      await db.insert('lop', {
        'id': 10,
        'ten_lop': 'C10',
        'created_at': nowStr,
        'updated_at': nowStr,
      });
      // Membership starts on 2026-09-15
      await db.insert('tham_gia_lop', {
        'id': 100,
        'id_hoc_sinh': 1,
        'id_lop': 10,
        'tu_ngay': '2026-09-15',
        'created_at': nowStr,
        'updated_at': nowStr,
      });
      for (int w = 1; w <= 7; w++) {
        await db.insert('lich_hoc', {
          'id': w,
          'id_lop': 10,
          'thu_trong_tuan': w,
          'gio_bat_dau': '17:30',
          'gio_ket_thuc': '19:00',
          'hieu_luc_tu': '2026-01-01',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
        await db.insert('phan_ca_hoc_sinh', {
          'id': w,
          'id_hoc_sinh': 1,
          'id_lop': 10,
          'id_lich_hoc': w,
          'tu_ngay': '2026-09-15',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
      }

      // 7 sessions before Sept 15, 7 sessions from Sept 15
      for (int i = 1; i <= 7; i++) {
        final dateStr = '2026-09-${i.toString().padLeft(2, '0')}';
        final w = DateTime.parse(dateStr).weekday;
        await db.insert('buoi_hoc', {
          'id': 100 + i,
          'id_lop': 10,
          'id_lich_hoc': w,
          'ngay': dateStr,
          'gio_bat_dau': '17:30',
          'gio_ket_thuc': '19:00',
          'loai': 'CHINH',
          'trang_thai': 'DA_HOC',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
      }
      for (int i = 15; i <= 21; i++) {
        final dateStr = '2026-09-$i';
        final w = DateTime.parse(dateStr).weekday;
        await db.insert('buoi_hoc', {
          'id': 100 + i,
          'id_lop': 10,
          'id_lich_hoc': w,
          'ngay': dateStr,
          'gio_bat_dau': '17:30',
          'gio_ket_thuc': '19:00',
          'loai': 'CHINH',
          'trang_thai': 'DA_HOC',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
      }

      final preview = await creditService.previewMonth(1, 10, '2026-09');
      expect(preview.eligibleCount, 7);
      expect(preview.standardCount, 7);
      expect(preview.extraCount, 0);
    });

    test('Membership gap excludes sessions inside inactive gap', () async {
      await db.insert('hoc_sinh', {
        'id': 1,
        'ho_ten': 'S1',
        'created_at': nowStr,
        'updated_at': nowStr,
      });
      await db.insert('lop', {
        'id': 10,
        'ten_lop': 'C10',
        'created_at': nowStr,
        'updated_at': nowStr,
      });
      // Active Sept 1..10, paused Sept 11..20, resumed Sept 21
      await db.insert('tham_gia_lop', {
        'id': 100,
        'id_hoc_sinh': 1,
        'id_lop': 10,
        'tu_ngay': '2026-09-01',
        'den_ngay': '2026-09-10',
        'created_at': nowStr,
        'updated_at': nowStr,
      });
      await db.insert('tham_gia_lop', {
        'id': 200,
        'id_hoc_sinh': 1,
        'id_lop': 10,
        'tu_ngay': '2026-09-21',
        'created_at': nowStr,
        'updated_at': nowStr,
      });
      for (int w = 1; w <= 7; w++) {
        await db.insert('lich_hoc', {
          'id': w,
          'id_lop': 10,
          'thu_trong_tuan': w,
          'gio_bat_dau': '17:30',
          'gio_ket_thuc': '19:00',
          'hieu_luc_tu': '2026-01-01',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
        await db.insert('phan_ca_hoc_sinh', {
          'id': w,
          'id_hoc_sinh': 1,
          'id_lop': 10,
          'id_lich_hoc': w,
          'tu_ngay': '2026-09-01',
          'den_ngay': '2026-09-10',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
        await db.insert('phan_ca_hoc_sinh', {
          'id': 10 + w,
          'id_hoc_sinh': 1,
          'id_lop': 10,
          'id_lich_hoc': w,
          'tu_ngay': '2026-09-21',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
      }

      // Session on 09-05 (active), 09-15 (in gap), 09-25 (active)
      await db.insert('buoi_hoc', {
        'id': 101,
        'id_lop': 10,
        'id_lich_hoc': DateTime.parse('2026-09-05').weekday,
        'ngay': '2026-09-05',
        'gio_bat_dau': '17:30',
        'gio_ket_thuc': '19:00',
        'loai': 'CHINH',
        'trang_thai': 'DA_HOC',
        'created_at': nowStr,
        'updated_at': nowStr,
      });
      await db.insert('buoi_hoc', {
        'id': 102,
        'id_lop': 10,
        'id_lich_hoc': DateTime.parse('2026-09-15').weekday,
        'ngay': '2026-09-15',
        'gio_bat_dau': '17:30',
        'gio_ket_thuc': '19:00',
        'loai': 'CHINH',
        'trang_thai': 'DA_HOC',
        'created_at': nowStr,
        'updated_at': nowStr,
      });
      await db.insert('buoi_hoc', {
        'id': 103,
        'id_lop': 10,
        'id_lich_hoc': DateTime.parse('2026-09-25').weekday,
        'ngay': '2026-09-25',
        'gio_bat_dau': '17:30',
        'gio_ket_thuc': '19:00',
        'loai': 'CHINH',
        'trang_thai': 'DA_HOC',
        'created_at': nowStr,
        'updated_at': nowStr,
      });

      final preview = await creditService.previewMonth(1, 10, '2026-09');
      expect(preview.eligibleCount, 2);
      expect(
        preview.candidates.map((c) => c.session.id).toList(),
        equals([101, 103]),
      );
    });

    test(
      'Default 12 boundary explicit tests: 12 eligible vs 13 eligible',
      () async {
        await db.insert('hoc_sinh', {
          'id': 1,
          'ho_ten': 'S1',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
        await db.insert('lop', {
          'id': 10,
          'ten_lop': 'C10',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
        await db.insert('tham_gia_lop', {
          'id': 100,
          'id_hoc_sinh': 1,
          'id_lop': 10,
          'tu_ngay': '2026-01-01',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
        for (int w = 1; w <= 7; w++) {
          await db.insert('lich_hoc', {
            'id': w,
            'id_lop': 10,
            'thu_trong_tuan': w,
            'gio_bat_dau': '17:30',
            'gio_ket_thuc': '19:00',
            'hieu_luc_tu': '2026-01-01',
            'created_at': nowStr,
            'updated_at': nowStr,
          });
        }

        for (int i = 1; i <= 12; i++) {
          final dateStr = '2026-09-${i.toString().padLeft(2, '0')}';
          await db.insert('buoi_hoc', {
            'id': 100 + i,
            'id_lop': 10,
            'id_lich_hoc': DateTime.parse(dateStr).weekday,
            'ngay': dateStr,
            'gio_bat_dau': '17:30',
            'gio_ket_thuc': '19:00',
            'loai': 'CHINH',
            'trang_thai': 'DA_HOC',
            'created_at': nowStr,
            'updated_at': nowStr,
          });
        }

        var preview = await creditService.previewMonth(1, 10, '2026-09');
        expect(preview.standardCount, 12);
        expect(preview.extraCount, 0);

        // Add 13th
        await db.insert('buoi_hoc', {
          'id': 113,
          'id_lop': 10,
          'id_lich_hoc': DateTime.parse('2026-09-13').weekday,
          'ngay': '2026-09-13',
          'gio_bat_dau': '17:30',
          'gio_ket_thuc': '19:00',
          'loai': 'CHINH',
          'trang_thai': 'DA_HOC',
          'created_at': nowStr,
          'updated_at': nowStr,
        });

        preview = await creditService.previewMonth(1, 10, '2026-09');
        expect(preview.standardCount, 12);
        expect(preview.extraCount, 1);
      },
    );

    test('Full extra attendance matrix for 13th session', () async {
      await db.insert('hoc_sinh', {
        'id': 1,
        'ho_ten': 'S1',
        'created_at': nowStr,
        'updated_at': nowStr,
      });
      await db.insert('lop', {
        'id': 10,
        'ten_lop': 'C10',
        'created_at': nowStr,
        'updated_at': nowStr,
      });
      await db.insert('tham_gia_lop', {
        'id': 100,
        'id_hoc_sinh': 1,
        'id_lop': 10,
        'tu_ngay': '2026-01-01',
        'created_at': nowStr,
        'updated_at': nowStr,
      });
      for (int w = 1; w <= 7; w++) {
        await db.insert('lich_hoc', {
          'id': w,
          'id_lop': 10,
          'thu_trong_tuan': w,
          'gio_bat_dau': '17:30',
          'gio_ket_thuc': '19:00',
          'hieu_luc_tu': '2026-01-01',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
      }

      for (int i = 1; i <= 13; i++) {
        final dateStr = '2026-09-${i.toString().padLeft(2, '0')}';
        await db.insert('buoi_hoc', {
          'id': 100 + i,
          'id_lop': 10,
          'id_lich_hoc': DateTime.parse(dateStr).weekday,
          'ngay': dateStr,
          'gio_bat_dau': '17:30',
          'gio_ket_thuc': '19:00',
          'loai': 'CHINH',
          'trang_thai': 'DA_HOC',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
      }

      // Matrix states for session 113:
      // 1. CO_MAT -> earns
      await db.insert('diem_danh', {
        'id_buoi_hoc': 113,
        'id_hoc_sinh': 1,
        'id_lop_goc': 10,
        'trang_thai': 'CO_MAT',
        'loai_tham_gia': 'CHINH',
        'created_at': nowStr,
        'updated_at': nowStr,
      });
      expect(
        (await creditService.previewMonth(
          1,
          10,
          '2026-09',
        )).candidates.last.earnsCredit,
        isTrue,
      );

      // 2. TRE -> earns
      await db.update('diem_danh', {
        'trang_thai': 'TRE',
      }, where: 'id_buoi_hoc = 113 AND id_hoc_sinh = 1');
      expect(
        (await creditService.previewMonth(
          1,
          10,
          '2026-09',
        )).candidates.last.earnsCredit,
        isTrue,
      );

      // 3. NGHI_CO_PHEP -> earns 0
      await db.update('diem_danh', {
        'trang_thai': 'NGHI_CO_PHEP',
      }, where: 'id_buoi_hoc = 113 AND id_hoc_sinh = 1');
      expect(
        (await creditService.previewMonth(
          1,
          10,
          '2026-09',
        )).candidates.last.earnsCredit,
        isFalse,
      );

      // 4. NGHI_KHONG_PHEP -> earns 0
      await db.update('diem_danh', {
        'trang_thai': 'NGHI_KHONG_PHEP',
      }, where: 'id_buoi_hoc = 113 AND id_hoc_sinh = 1');
      expect(
        (await creditService.previewMonth(
          1,
          10,
          '2026-09',
        )).candidates.last.earnsCredit,
        isFalse,
      );

      // 5. CHUA_DIEM_DANH (no row) -> earns 0
      await db.delete(
        'diem_danh',
        where: 'id_buoi_hoc = 113 AND id_hoc_sinh = 1',
      );
      expect(
        (await creditService.previewMonth(
          1,
          10,
          '2026-09',
        )).candidates.last.earnsCredit,
        isFalse,
      );
    });

    test(
      'Missing attendance on earlier session does not shift 13th session candidate index',
      () async {
        await db.insert('hoc_sinh', {
          'id': 1,
          'ho_ten': 'S1',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
        await db.insert('lop', {
          'id': 10,
          'ten_lop': 'C10',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
        await db.insert('tham_gia_lop', {
          'id': 100,
          'id_hoc_sinh': 1,
          'id_lop': 10,
          'tu_ngay': '2026-01-01',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
        for (int w = 1; w <= 7; w++) {
          await db.insert('lich_hoc', {
            'id': w,
            'id_lop': 10,
            'thu_trong_tuan': w,
            'gio_bat_dau': '17:30',
            'gio_ket_thuc': '19:00',
            'hieu_luc_tu': '2026-01-01',
            'created_at': nowStr,
            'updated_at': nowStr,
          });
        }

        for (int i = 1; i <= 13; i++) {
          final dateStr = '2026-09-${i.toString().padLeft(2, '0')}';
          await db.insert('buoi_hoc', {
            'id': 100 + i,
            'id_lop': 10,
            'id_lich_hoc': DateTime.parse(dateStr).weekday,
            'ngay': dateStr,
            'gio_bat_dau': '17:30',
            'gio_ket_thuc': '19:00',
            'loai': 'CHINH',
            'trang_thai': 'DA_HOC',
            'created_at': nowStr,
            'updated_at': nowStr,
          });
        }

        // Session #5 has no diem_danh row (CHUA_DIEM_DANH). Session #13 = CO_MAT.
        await db.insert('diem_danh', {
          'id_buoi_hoc': 113,
          'id_hoc_sinh': 1,
          'id_lop_goc': 10,
          'trang_thai': 'CO_MAT',
          'loai_tham_gia': 'CHINH',
          'created_at': nowStr,
          'updated_at': nowStr,
        });

        final preview = await creditService.previewMonth(1, 10, '2026-09');
        expect(preview.candidates[4].index, 5);
        expect(
          preview.candidates[4].attendanceState,
          AttendanceState.CHUA_DIEM_DANH,
        );

        expect(preview.candidates[12].index, 13);
        expect(preview.candidates[12].isExtra, isTrue);
        expect(preview.candidates[12].earnsCredit, isTrue);
      },
    );

    test(
      'Session status filter: only CHINH DA_HOC enters candidate sequence',
      () async {
        await db.insert('hoc_sinh', {
          'id': 1,
          'ho_ten': 'S1',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
        await db.insert('lop', {
          'id': 10,
          'ten_lop': 'C10',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
        await db.insert('tham_gia_lop', {
          'id': 100,
          'id_hoc_sinh': 1,
          'id_lop': 10,
          'tu_ngay': '2026-01-01',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
        await db.insert('lich_hoc', {
          'id': 1,
          'id_lop': 10,
          'thu_trong_tuan': 1,
          'gio_bat_dau': '17:30',
          'gio_ket_thuc': '19:00',
          'hieu_luc_tu': '2026-01-01',
          'created_at': nowStr,
          'updated_at': nowStr,
        });

        await db.insert('buoi_hoc', {
          'id': 101,
          'id_lop': 10,
          'id_lich_hoc': 1,
          'ngay': '2026-09-07',
          'gio_bat_dau': '17:30',
          'gio_ket_thuc': '19:00',
          'loai': 'CHINH',
          'trang_thai': 'DA_HOC',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
        await db.insert('buoi_hoc', {
          'id': 102,
          'id_lop': 10,
          'id_lich_hoc': 1,
          'ngay': '2026-09-14',
          'gio_bat_dau': '17:30',
          'gio_ket_thuc': '19:00',
          'loai': 'CHINH',
          'trang_thai': 'DU_KIEN',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
        await db.insert('buoi_hoc', {
          'id': 103,
          'id_lop': 10,
          'id_lich_hoc': 1,
          'ngay': '2026-09-21',
          'gio_bat_dau': '17:30',
          'gio_ket_thuc': '19:00',
          'loai': 'CHINH',
          'trang_thai': 'HUY',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
        await db.insert('buoi_hoc', {
          'id': 104,
          'id_lop': 10,
          'id_lich_hoc': 1,
          'ngay': '2026-09-28',
          'gio_bat_dau': '17:30',
          'gio_ket_thuc': '19:00',
          'loai': 'CHINH',
          'trang_thai': 'NGHI_LE',
          'created_at': nowStr,
          'updated_at': nowStr,
        });

        final preview = await creditService.previewMonth(1, 10, '2026-09');
        expect(preview.eligibleCount, 1);
        expect(preview.candidates.first.session.id, 101);
      },
    );

    test(
      'HOC_BU with HOC_BU attendance and PHAT_SINH with CO_MAT attendance are excluded',
      () async {
        await db.insert('hoc_sinh', {
          'id': 1,
          'ho_ten': 'S1',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
        await db.insert('lop', {
          'id': 10,
          'ten_lop': 'C10',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
        await db.insert('tham_gia_lop', {
          'id': 100,
          'id_hoc_sinh': 1,
          'id_lop': 10,
          'tu_ngay': '2026-01-01',
          'created_at': nowStr,
          'updated_at': nowStr,
        });

        await db.insert('buoi_hoc', {
          'id': 201,
          'id_lop': 10,
          'ngay': '2026-09-25',
          'gio_bat_dau': '17:30',
          'gio_ket_thuc': '19:00',
          'loai': 'HOC_BU',
          'trang_thai': 'DA_HOC',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
        await db.insert('diem_danh', {
          'id_buoi_hoc': 201,
          'id_hoc_sinh': 1,
          'id_lop_goc': 10,
          'trang_thai': 'HOC_BU',
          'loai_tham_gia': 'HOC_BU',
          'created_at': nowStr,
          'updated_at': nowStr,
        });

        await db.insert('buoi_hoc', {
          'id': 202,
          'id_lop': 10,
          'ngay': '2026-09-26',
          'gio_bat_dau': '17:30',
          'gio_ket_thuc': '19:00',
          'loai': 'PHAT_SINH',
          'trang_thai': 'DA_HOC',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
        await db.insert('diem_danh', {
          'id_buoi_hoc': 202,
          'id_hoc_sinh': 1,
          'id_lop_goc': 10,
          'trang_thai': 'CO_MAT',
          'loai_tham_gia': 'CHINH',
          'created_at': nowStr,
          'updated_at': nowStr,
        });

        final preview = await creditService.previewMonth(1, 10, '2026-09');
        expect(preview.eligibleCount, 0);
      },
    );

    test(
      'Late finalization regression recomputes candidate sequence idempotently',
      () async {
        await db.insert('hoc_sinh', {
          'id': 1,
          'ho_ten': 'S1',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
        await db.insert('lop', {
          'id': 10,
          'ten_lop': 'C10',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
        await db.insert('tham_gia_lop', {
          'id': 100,
          'id_hoc_sinh': 1,
          'id_lop': 10,
          'tu_ngay': '2026-01-01',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
        for (int w = 1; w <= 7; w++) {
          await db.insert('lich_hoc', {
            'id': w,
            'id_lop': 10,
            'thu_trong_tuan': w,
            'gio_bat_dau': '17:30',
            'gio_ket_thuc': '19:00',
            'hieu_luc_tu': '2026-01-01',
            'created_at': nowStr,
            'updated_at': nowStr,
          });
        }

        // Session #1 on 2026-09-01 is DU_KIEN
        await db.insert('buoi_hoc', {
          'id': 101,
          'id_lop': 10,
          'id_lich_hoc': DateTime.parse('2026-09-01').weekday,
          'ngay': '2026-09-01',
          'gio_bat_dau': '17:30',
          'gio_ket_thuc': '19:00',
          'loai': 'CHINH',
          'trang_thai': 'DU_KIEN',
          'created_at': nowStr,
          'updated_at': nowStr,
        });

        // Sessions #2..#13 on 2026-09-02..2026-09-13 are DA_HOC
        for (int i = 2; i <= 13; i++) {
          final dateStr = '2026-09-${i.toString().padLeft(2, '0')}';
          await db.insert('buoi_hoc', {
            'id': 100 + i,
            'id_lop': 10,
            'id_lich_hoc': DateTime.parse(dateStr).weekday,
            'ngay': dateStr,
            'gio_bat_dau': '17:30',
            'gio_ket_thuc': '19:00',
            'loai': 'CHINH',
            'trang_thai': 'DA_HOC',
            'created_at': nowStr,
            'updated_at': nowStr,
          });
          await db.insert('diem_danh', {
            'id_buoi_hoc': 100 + i,
            'id_hoc_sinh': 1,
            'id_lop_goc': 10,
            'trang_thai': 'CO_MAT',
            'loai_tham_gia': 'CHINH',
            'created_at': nowStr,
            'updated_at': nowStr,
          });
        }

        // Initial preview: 12 eligible sessions (102..113), 0 extra candidates
        var preview = await creditService.previewMonth(1, 10, '2026-09');
        expect(preview.eligibleCount, 12);
        expect(preview.extraCount, 0);

        // Now finalize session #1 on 2026-09-01
        await db.update('buoi_hoc', {
          'trang_thai': 'DA_HOC',
        }, where: 'id = 101');
        await db.insert('diem_danh', {
          'id_buoi_hoc': 101,
          'id_hoc_sinh': 1,
          'id_lop_goc': 10,
          'trang_thai': 'CO_MAT',
          'loai_tham_gia': 'CHINH',
          'created_at': nowStr,
          'updated_at': nowStr,
        });

        // Re-run preview: 13 eligible sessions, session 101 is index 1, session 113 is index 13 (extra!)
        preview = await creditService.previewMonth(1, 10, '2026-09');
        expect(preview.eligibleCount, 13);
        expect(preview.candidates.first.session.id, 101);
        expect(preview.candidates.last.session.id, 113);
        expect(preview.candidates.last.isExtra, isTrue);
        expect(preview.candidates.last.earnsCredit, isTrue);

        // Reconcile
        await creditService.reconcileEarnedCreditsForStudentClassMonth(
          1,
          10,
          '2026-09',
        );
        expect(await creditService.getBalance(1, 10), 1);
      },
    );

    test(
      'Class reconciliation atomicity & fail-closed on roster corruption',
      () async {
        await db.insert('hoc_sinh', {
          'id': 1,
          'ho_ten': 'S1',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
        await db.insert('hoc_sinh', {
          'id': 2,
          'ho_ten': 'S2',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
        await db.insert('lop', {
          'id': 10,
          'ten_lop': 'C10',
          'created_at': nowStr,
          'updated_at': nowStr,
        });

        await db.insert('tham_gia_lop', {
          'id': 100,
          'id_hoc_sinh': 1,
          'id_lop': 10,
          'tu_ngay': '2026-01-01',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
        await db.insert('tham_gia_lop', {
          'id': 200,
          'id_hoc_sinh': 2,
          'id_lop': 10,
          'tu_ngay': '2026-01-01',
          'created_at': nowStr,
          'updated_at': nowStr,
        });

        for (int w = 1; w <= 7; w++) {
          await db.insert('lich_hoc', {
            'id': w,
            'id_lop': 10,
            'thu_trong_tuan': w,
            'gio_bat_dau': '17:30',
            'gio_ket_thuc': '19:00',
            'hieu_luc_tu': '2026-01-01',
            'created_at': nowStr,
            'updated_at': nowStr,
          });
        }

        // Student 1 has 13 valid eligible sessions, 13th = CO_MAT (would earn +1)
        for (int i = 1; i <= 13; i++) {
          final dateStr = '2026-09-${i.toString().padLeft(2, '0')}';
          await db.insert('buoi_hoc', {
            'id': 100 + i,
            'id_lop': 10,
            'id_lich_hoc': DateTime.parse(dateStr).weekday,
            'ngay': dateStr,
            'gio_bat_dau': '17:30',
            'gio_ket_thuc': '19:00',
            'loai': 'CHINH',
            'trang_thai': 'DA_HOC',
            'created_at': nowStr,
            'updated_at': nowStr,
          });
          await db.insert('diem_danh', {
            'id_buoi_hoc': 100 + i,
            'id_hoc_sinh': 1,
            'id_lop_goc': 10,
            'trang_thai': 'CO_MAT',
            'loai_tham_gia': 'CHINH',
            'created_at': nowStr,
            'updated_at': nowStr,
          });
        }

        // Session 200 is CHINH + DA_HOC on 2026-09-20 but missing schedule (corrupted roster)
        await db.insert('buoi_hoc', {
          'id': 200,
          'id_lop': 10,
          'id_lich_hoc': null,
          'ngay': '2026-09-20',
          'gio_bat_dau': '17:30',
          'gio_ket_thuc': '19:00',
          'loai': 'CHINH',
          'trang_thai': 'DA_HOC',
          'created_at': nowStr,
          'updated_at': nowStr,
        });

        final countBefore = (await db.query('buoi_du_ledger')).length;

        await expectLater(
          creditService.reconcileEarnedCreditsForClassMonth(10, '2026-09'),
          throwsA(isA<Exception>()),
        );

        final countAfter = (await db.query('buoi_du_ledger')).length;
        expect(countAfter, equals(countBefore));
        expect(await creditService.getBalance(1, 10), 0);
      },
    );

    test(
      'Class reconciliation success writes all missing entries for all students idempotently',
      () async {
        await db.insert('hoc_sinh', {
          'id': 1,
          'ho_ten': 'S1',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
        await db.insert('hoc_sinh', {
          'id': 2,
          'ho_ten': 'S2',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
        await db.insert('lop', {
          'id': 10,
          'ten_lop': 'C10',
          'created_at': nowStr,
          'updated_at': nowStr,
        });

        await db.insert('tham_gia_lop', {
          'id': 100,
          'id_hoc_sinh': 1,
          'id_lop': 10,
          'tu_ngay': '2026-01-01',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
        await db.insert('tham_gia_lop', {
          'id': 200,
          'id_hoc_sinh': 2,
          'id_lop': 10,
          'tu_ngay': '2026-01-01',
          'created_at': nowStr,
          'updated_at': nowStr,
        });

        for (int w = 1; w <= 7; w++) {
          await db.insert('lich_hoc', {
            'id': w,
            'id_lop': 10,
            'thu_trong_tuan': w,
            'gio_bat_dau': '17:30',
            'gio_ket_thuc': '19:00',
            'hieu_luc_tu': '2026-01-01',
            'created_at': nowStr,
            'updated_at': nowStr,
          });
        }

        // 13 sessions for both students
        for (int i = 1; i <= 13; i++) {
          final dateStr = '2026-09-${i.toString().padLeft(2, '0')}';
          await db.insert('buoi_hoc', {
            'id': 100 + i,
            'id_lop': 10,
            'id_lich_hoc': DateTime.parse(dateStr).weekday,
            'ngay': dateStr,
            'gio_bat_dau': '17:30',
            'gio_ket_thuc': '19:00',
            'loai': 'CHINH',
            'trang_thai': 'DA_HOC',
            'created_at': nowStr,
            'updated_at': nowStr,
          });
          await db.insert('diem_danh', {
            'id_buoi_hoc': 100 + i,
            'id_hoc_sinh': 1,
            'id_lop_goc': 10,
            'trang_thai': 'CO_MAT',
            'loai_tham_gia': 'CHINH',
            'created_at': nowStr,
            'updated_at': nowStr,
          });
          await db.insert('diem_danh', {
            'id_buoi_hoc': 100 + i,
            'id_hoc_sinh': 2,
            'id_lop_goc': 10,
            'trang_thai': 'CO_MAT',
            'loai_tham_gia': 'CHINH',
            'created_at': nowStr,
            'updated_at': nowStr,
          });
        }

        await creditService.reconcileEarnedCreditsForClassMonth(10, '2026-09');

        expect(await creditService.getBalance(1, 10), 1);
        expect(await creditService.getBalance(2, 10), 1);

        // Reconcile again -> 0 new rows
        await creditService.reconcileEarnedCreditsForClassMonth(10, '2026-09');
        final rows = await db.query('buoi_du_ledger');
        expect(rows.length, 2);
      },
    );

    test(
      'Manual adjustment validation for invalid student, class or date',
      () async {
        await db.insert('hoc_sinh', {
          'id': 1,
          'ho_ten': 'S1',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
        await db.insert('lop', {
          'id': 10,
          'ten_lop': 'C10',
          'created_at': nowStr,
          'updated_at': nowStr,
        });

        // Nonexistent student
        await expectLater(
          creditService.addManualAdjustment(
            studentId: 999,
            classId: 10,
            delta: 1,
            effectiveDate: '2026-09-21',
            note: 'A',
          ),
          throwsA(isA<Exception>()),
        );

        // Nonexistent class
        await expectLater(
          creditService.addManualAdjustment(
            studentId: 1,
            classId: 999,
            delta: 1,
            effectiveDate: '2026-09-21',
            note: 'A',
          ),
          throwsA(isA<Exception>()),
        );

        // Invalid dates
        for (final invalidDate in [
          '2026-02-30',
          '2026-9-1',
          '01/09/2026',
          'abc',
        ]) {
          await expectLater(
            creditService.addManualAdjustment(
              studentId: 1,
              classId: 10,
              delta: 1,
              effectiveDate: invalidDate,
              note: 'A',
            ),
            throwsA(isA<Exception>()),
          );
        }

        final rows = await db.query('buoi_du_ledger');
        expect(rows, isEmpty);
      },
    );
  });
}
