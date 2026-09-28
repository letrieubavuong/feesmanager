// lib/dev/demo_data_seeder.dart

import 'package:sqflite/sqflite.dart';
import '../features/attendance/domain/attendance_record.dart';
import '../features/attendance/domain/attendance_service.dart';
import '../features/attendance/domain/attendance_state.dart';
import '../features/classes/domain/class.dart';
import '../features/classes/domain/class_filter.dart';
import '../features/classes/domain/class_service.dart';
import '../features/memberships/domain/membership_service.dart';
import '../features/payments/domain/payment_method.dart';
import '../features/payments/domain/payment_service.dart';
import '../features/schedule/domain/class_schedule.dart';
import '../features/schedule/domain/schedule_service.dart';
import '../features/sessions/domain/class_session.dart';
import '../features/sessions/domain/session_generation_service.dart';
import '../features/sessions/domain/session_service.dart';
import '../features/students/domain/student.dart';
import '../features/students/domain/student_service.dart';
import '../features/tuition/domain/invoice_service.dart';
import '../features/tuition/domain/tuition_policy_service.dart';
import 'demo_seed_config.dart';
import 'demo_seed_result.dart';

class DemoDataSeeder {
  final ClassService classService;
  final StudentService studentService;
  final MembershipService membershipService;
  final ScheduleDomainService scheduleService;
  final SessionGenerationService sessionGenService;
  final SessionService sessionService;
  final AttendanceService attendanceService;
  final TuitionPolicyService tuitionPolicyService;
  final InvoiceService invoiceService;
  final PaymentService paymentService;
  final Database db;

  ClassService get _classService => classService;
  StudentService get _studentService => studentService;
  MembershipService get _membershipService => membershipService;
  ScheduleDomainService get _scheduleService => scheduleService;
  SessionGenerationService get _sessionGenService => sessionGenService;
  SessionService get _sessionService => sessionService;
  AttendanceService get _attendanceService => attendanceService;
  TuitionPolicyService get _tuitionPolicyService => tuitionPolicyService;
  InvoiceService get _invoiceService => invoiceService;
  PaymentService get _paymentService => paymentService;
  Database get _db => db;

  DemoDataSeeder({
    required this.classService,
    required this.studentService,
    required this.membershipService,
    required this.scheduleService,
    required this.sessionGenService,
    required this.sessionService,
    required this.attendanceService,
    required this.tuitionPolicyService,
    required this.invoiceService,
    required this.paymentService,
    required this.db,
  });

  Future<DemoSeedResult> seed() async {
    final warnings = <String>[];
    int classesCreated = 0;
    int classesReused = 0;
    int studentsCreated = 0;
    int studentsReused = 0;
    int membershipsCreated = 0;
    int schedulesCreated = 0;
    int sessionsCreated = 0;
    int sessionsExisting = 0;
    int attendanceRecordsCreatedOrUpdated = 0;
    int sessionsFinalized = 0;
    int holidaySessions = 0;
    int stoppedStudentsCount = 0;
    int tuitionPoliciesCreated = 0;
    int invoicesCreated = 0;
    int paymentsCreated = 0;

    // 1. Seed / Reuse 5 Demo Classes
    final classMap = <String, int>{};
    for (final spec in DemoSeedConfig.classes) {
      final existing = await _classService.searchClasses(
        spec.tenLop,
        filter: ClassFilter.all,
      );
      final demoMatch = existing
          .where((c) => c.tenLop == spec.tenLop)
          .firstOrNull;

      if (demoMatch != null) {
        classMap[spec.tenLop] = demoMatch.id!;
        classesReused++;
      } else {
        final newClass = ClassEntity(
          tenLop: spec.tenLop,
          khoi: spec.khoi,
          monHoc: spec.monHoc,
          siSoToiDa: spec.siSoToiDa,
          ghiChu: demoSeedMarker,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        final id = await _classService.saveClass(newClass);
        classMap[spec.tenLop] = id;
        classesCreated++;
      }
    }
    // print log
    // ignore: avoid_print
    print('[DEMO SEED] classes 5/5');

    // 2. Seed / Reuse 80 Demo Students
    final seededStudents = <Student>[];
    for (final spec in DemoSeedConfig.students) {
      final existingList = await _studentService.searchStudents(
        spec.hoTen,
        includeArchived: true,
      );
      final demoMatch = existingList
          .where(
            (s) =>
                s.hoTen == spec.hoTen &&
                (s.sdtPhuHuynh == spec.sdtPhuHuynh ||
                    s.ghiChu?.contains(demoSeedMarker) == true),
          )
          .firstOrNull;

      if (demoMatch != null) {
        seededStudents.add(demoMatch);
        studentsReused++;
      } else {
        final newStudent = Student(
          hoTen: spec.hoTen,
          gioiTinh: spec.gioiTinh,
          ngaySinh: '${spec.birthYear}-01-01',
          sdtPhuHuynh: spec.sdtPhuHuynh,
          truongDangHoc: spec.truongDangHoc,
          ghiChu: demoSeedMarker,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        final id = await _studentService.saveStudent(newStudent);
        final saved = await _studentService.getStudentById(id);
        seededStudents.add(saved!);
        studentsCreated++;
      }
    }
    // ignore: avoid_print
    print('[DEMO SEED] students 80/80');

    // 3. Seed Memberships (100 total)
    // Group A (0..17) -> Toán 6
    // Group B (18..35) -> KHTN 8
    // Group C (36..53) -> Vật lí 12
    // Group D (54..73) -> Toán 9 AND KHTN 9
    // Group E (74..76) -> Toán 9
    // Group F (77..79) -> KHTN 9
    final startDate = DateTime.parse(DemoSeedConfig.startDate);

    Future<void> enrollIfMissing(Student s, String className) async {
      final classId = classMap[className]!;
      final history = await _membershipService.getMembershipHistory(
        s.id!,
        classId: classId,
      );
      if (history.isEmpty) {
        await _membershipService.enrollStudent(
          studentId: s.id!,
          classId: classId,
          joinDate: startDate,
          ghiChu: demoSeedMarker,
        );
        membershipsCreated++;
      }
    }

    for (int i = 0; i < 18; i++) {
      await enrollIfMissing(seededStudents[i], 'Toán 6');
    }
    for (int i = 18; i < 36; i++) {
      await enrollIfMissing(seededStudents[i], 'KHTN 8');
    }
    for (int i = 36; i < 54; i++) {
      await enrollIfMissing(seededStudents[i], 'Vật lí 12');
    }
    for (int i = 54; i < 74; i++) {
      await enrollIfMissing(seededStudents[i], 'Toán 9');
      await enrollIfMissing(seededStudents[i], 'KHTN 9');
    }
    for (int i = 74; i < 77; i++) {
      await enrollIfMissing(seededStudents[i], 'Toán 9');
    }
    for (int i = 77; i < 80; i++) {
      await enrollIfMissing(seededStudents[i], 'KHTN 9');
    }
    // ignore: avoid_print
    print('[DEMO SEED] memberships 100/100');

    // 4. Seed 4 Stopped Students (End membership 2026-08-31 & archive)
    final leaveDate = DateTime.parse(DemoSeedConfig.leaveDateForStopped);
    final stoppedIndices = [0, 18, 36, 54];

    for (final idx in stoppedIndices) {
      final s = seededStudents[idx];
      final freshStudent = await _studentService.getStudentById(s.id!);
      if (freshStudent != null && freshStudent.daLuuTru) {
        stoppedStudentsCount++;
        continue;
      }

      final memberships = await _membershipService.getMembershipHistory(s.id!);
      final openMemberships = memberships
          .where((m) => m.denNgay == null)
          .toList();

      for (final m in openMemberships) {
        await _membershipService.leaveClass(
          studentId: s.id!,
          classId: m.idLop,
          endDate: leaveDate,
          reason: 'Nghỉ học demo',
        );
      }

      await _studentService.archiveStudent(s.id!);
      stoppedStudentsCount++;
    }

    // 5. Seed Schedules (11 total)
    for (final spec in DemoSeedConfig.schedules) {
      final classId = classMap[spec.tenLop]!;
      final existingSchedules = await _scheduleService.getSchedulesForClass(
        classId,
      );

      final match = existingSchedules
          .where(
            (s) =>
                s.thuTrongTuan == spec.thuTrongTuan &&
                s.gioBatDau == spec.gioBatDau &&
                s.gioKetThuc == spec.gioKetThuc &&
                s.hieuLucTu == DemoSeedConfig.startDate,
          )
          .firstOrNull;

      if (match == null) {
        final now = DateTime.now();
        await _scheduleService.createSchedule(
          ClassSchedule(
            idLop: classId,
            thuTrongTuan: spec.thuTrongTuan,
            gioBatDau: spec.gioBatDau,
            gioKetThuc: spec.gioKetThuc,
            hieuLucTu: DemoSeedConfig.startDate,
            ghiChu: demoSeedMarker,
            createdAt: now,
            updatedAt: now,
          ),
        );
        schedulesCreated++;
      }
    }
    // ignore: avoid_print
    print('[DEMO SEED] schedules 11/11');

    // 6. Generate Class Sessions
    // ignore: avoid_print
    print('[DEMO SEED] generating sessions...');
    final fromDate = DateTime.parse(DemoSeedConfig.startDate);
    final toDate = DateTime.parse('2026-09-30');

    for (final entry in classMap.entries) {
      final res = await _sessionGenService.generateForClass(
        classId: entry.value,
        fromDate: fromDate,
        toDate: toDate,
      );
      sessionsCreated += res.createdCount;
      sessionsExisting += res.existingCount;
    }

    // 7. National Holiday test data (2026-09-02)
    for (final entry in classMap.entries) {
      final monthSessions = await _sessionService.getSessionsForMonth(
        entry.value,
        '2026-09',
      );
      final holidayS = monthSessions
          .where((s) => s.ngay == '2026-09-02')
          .firstOrNull;
      if (holidayS != null && holidayS.trangThai != SessionStatus.NGHI_LE) {
        await _sessionService.updateStatus(holidayS.id!, SessionStatus.NGHI_LE);
        holidaySessions++;
      }
    }

    // 8. Attendance Seeding & Finalization
    // ignore: avoid_print
    print('[DEMO SEED] attendance...');
    const refDateStr = DemoSeedConfig.referenceDate;

    for (final entry in classMap.entries) {
      final className = entry.key;
      final classId = entry.value;

      final allJuly = await _sessionService.getSessionsForMonth(
        classId,
        '2026-07',
      );
      final allAugust = await _sessionService.getSessionsForMonth(
        classId,
        '2026-08',
      );
      final allSeptember = await _sessionService.getSessionsForMonth(
        classId,
        '2026-09',
      );

      final allSessions = [...allJuly, ...allAugust, ...allSeptember];

      for (final session in allSessions) {
        if (session.trangThai == SessionStatus.HUY ||
            session.trangThai == SessionStatus.NGHI_LE) {
          continue;
        }

        final sessionDate = session.ngay;

        if (sessionDate.compareTo(refDateStr) < 0) {
          // Historical session -> generate deterministic attendance & finalize
          if (session.trangThai != SessionStatus.DA_HOC) {
            final sheet = await _attendanceService.getAttendanceForSession(
              session.id!,
            );
            final states = <int, AttendanceState>{};

            for (final m in sheet.members) {
              final stId = m.rosterMember.student.id!;
              final score = (stId * 37 + session.id! * 17) % 100;
              AttendanceState state;
              if (score <= 2) {
                state = AttendanceState.NGHI_KHONG_PHEP;
              } else if (score <= 9) {
                state = AttendanceState.NGHI_CO_PHEP;
              } else if (score <= 14) {
                state = AttendanceState.TRE;
              } else {
                state = AttendanceState.CO_MAT;
              }
              states[stId] = state;
            }

            await _attendanceService.saveDraft(session.id!, states);
            await _attendanceService.finalizeSessionAttendance(
              session.id!,
              allowIncomplete: true,
            );
            sessionsFinalized++;
            attendanceRecordsCreatedOrUpdated += states.length;
          }
        } else if (sessionDate == refDateStr) {
          // Today: 28/09/2026
          if (className == 'Toán 6' && session.gioBatDau == '08:00') {
            if (session.trangThai != SessionStatus.DA_HOC) {
              final sheet = await _attendanceService.getAttendanceForSession(
                session.id!,
              );
              final states = <int, AttendanceState>{};
              for (final m in sheet.members) {
                final stId = m.rosterMember.student.id!;
                final score = (stId * 37 + session.id! * 17) % 100;
                states[stId] = score <= 10
                    ? AttendanceState.TRE
                    : AttendanceState.CO_MAT;
              }
              await _attendanceService.saveDraft(session.id!, states);
              await _attendanceService.finalizeSessionAttendance(
                session.id!,
                allowIncomplete: true,
              );
              sessionsFinalized++;
              attendanceRecordsCreatedOrUpdated += states.length;
            }
          }
          // Other classes on today (KHTN 8, Toán 9, KHTN 9) remain DU_KIEN
        }
      }
    }

    // 9. Attendance Correction (1 row on Vật lí 12)
    final vatLiId = classMap['Vật lí 12']!;
    final vlSessions = await _sessionService.getSessionsForMonth(
      vatLiId,
      '2026-09',
    );
    final completedVl = vlSessions
        .where(
          (s) =>
              s.trangThai == SessionStatus.DA_HOC &&
              s.ngay.compareTo('2026-09-27') <= 0,
        )
        .toList();
    if (completedVl.isNotEmpty) {
      completedVl.sort((a, b) => b.ngay.compareTo(a.ngay));
      final targetSession = completedVl.first;
      final sheet = await _attendanceService.getAttendanceForSession(
        targetSession.id!,
      );
      final coMatMember = sheet.members
          .where((m) => m.persistedRecord?.trangThai == AttendanceStatus.CO_MAT)
          .firstOrNull;

      if (coMatMember != null) {
        final stId = coMatMember.rosterMember.student.id!;
        final auditRows = await _db.rawQuery(
          'SELECT COUNT(*) FROM diem_danh_chinh_sua WHERE id_buoi_hoc = ? AND id_hoc_sinh = ?',
          [targetSession.id, stId],
        );
        if (Sqflite.firstIntValue(auditRows) == 0) {
          await _attendanceService.correctFinalizedAttendance(
            sessionId: targetSession.id!,
            states: {stId: AttendanceState.TRE},
            reason: 'Dữ liệu demo: điều chỉnh trạng thái điểm danh',
          );
        }
      }
    }

    // 10. Tuition Policies (5 total)
    for (final spec in DemoSeedConfig.policies) {
      final classId = classMap[spec.tenLop]!;
      final existingPolicies = await _tuitionPolicyService.getPoliciesForClass(
        classId,
      );

      final match = existingPolicies
          .where((p) => p.hieuLucTu == '2026-07-01')
          .firstOrNull;
      if (match == null) {
        await _tuitionPolicyService.createPolicy(
          classId: classId,
          effectiveFrom: '2026-07-01',
          standardSessionsPerMonth: spec.standardSessionsPerMonth,
          feePerSession: spec.feePerSession,
          note: demoSeedMarker,
        );
        tuitionPoliciesCreated++;
      }
    }

    // 11. September Invoices & Payments for Toán 6
    final toan6Id = classMap['Toán 6']!;
    try {
      final finalizedInvoices = await _invoiceService.finalizeClassInvoices(
        toan6Id,
        '2026-09',
      );
      invoicesCreated += finalizedInvoices.length;

      for (int i = 0; i < finalizedInvoices.length; i++) {
        final inv = finalizedInvoices[i];
        final amountDue = inv.soTienPhaiThu;

        int payAmount = 0;
        if (i % 4 == 0 || i % 4 == 1) {
          payAmount = amountDue; // FULL
        } else if (i % 4 == 2) {
          payAmount = (amountDue * 0.5 / 1000).round() * 1000; // PARTIAL ~50%
        } // i % 4 == 3 => UNPAID (0)

        if (payAmount > 0) {
          final method = i % 2 == 0
              ? PaymentMethod.TIEN_MAT
              : PaymentMethod.CHUYEN_KHOAN;
          final txId = method == PaymentMethod.CHUYEN_KHOAN
              ? 'DEMO-T6-202609-${inv.idHocSinh}'
              : null;

          final paymentSummary = await _paymentService.getPaymentSummary(
            inv.idHocSinh,
            toan6Id,
            '2026-09',
          );

          if (paymentSummary == null || paymentSummary.payments.isEmpty) {
            await _paymentService.recordPayment(
              studentId: inv.idHocSinh,
              classId: toan6Id,
              month: '2026-09',
              amount: payAmount,
              paymentDate: '2026-09-28',
              method: method,
              transactionId: txId,
              note: demoSeedMarker,
            );
            paymentsCreated++;
          }
        }
      }
    } catch (e) {
      warnings.add('Toán 6 September invoice finalization skipped: $e');
    }

    // 12. Database Validation
    // ignore: avoid_print
    print('[DEMO SEED] validation...');
    final fkCheck = await _db.rawQuery('PRAGMA foreign_key_check');
    if (fkCheck.isNotEmpty) {
      warnings.add(
        'PRAGMA foreign_key_check found ${fkCheck.length} violations',
      );
    }

    final result = DemoSeedResult(
      studentsCreated: studentsCreated,
      studentsReused: studentsReused,
      classesCreated: classesCreated,
      classesReused: classesReused,
      membershipsCreated: membershipsCreated,
      schedulesCreated: schedulesCreated,
      sessionsCreated: sessionsCreated,
      sessionsExisting: sessionsExisting,
      attendanceRecordsCreatedOrUpdated: attendanceRecordsCreatedOrUpdated,
      sessionsFinalized: sessionsFinalized,
      holidaySessions: holidaySessions,
      stoppedStudents: stoppedStudentsCount,
      tuitionPoliciesCreated: tuitionPoliciesCreated,
      invoicesCreated: invoicesCreated,
      paymentsCreated: paymentsCreated,
      warnings: warnings,
    );

    // ignore: avoid_print
    print('[DEMO SEED] COMPLETE');
    return result;
  }
}
