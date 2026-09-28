// lib/dev/demo_seed_bootstrap.dart

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/database/database_provider.dart';
import '../features/attendance/data/attendance_repository.dart';
import '../features/attendance/domain/attendance_service.dart';
import '../features/classes/data/class_repository.dart';
import '../features/classes/domain/class_service.dart';
import '../features/leave/data/leave_request_repository.dart';
import '../features/leave/domain/leave_request_service.dart';
import '../features/memberships/data/membership_repository.dart';
import '../features/memberships/domain/membership_service.dart';
import '../features/payments/data/payment_repository.dart';
import '../features/payments/domain/payment_service.dart';
import '../features/roster/domain/roster_service.dart';
import '../features/schedule/data/assignment_repository.dart';
import '../features/schedule/data/schedule_repository.dart';
import '../features/schedule/domain/schedule_service.dart';
import '../features/schedule_conflicts/data/schedule_constraint_repository.dart';
import '../features/schedule_conflicts/domain/schedule_conflict_service.dart';
import '../features/session_adjustments/data/session_adjustment_repository.dart';
import '../features/session_credits/data/session_credit_repository.dart';
import '../features/session_credits/domain/session_credit_service.dart';
import '../features/sessions/data/session_repository.dart';
import '../features/sessions/domain/session_generation_service.dart';
import '../features/sessions/domain/session_service.dart';
import '../features/students/data/student_repository.dart';
import '../features/students/domain/student_service.dart';
import '../features/tuition/data/tuition_policy_repository.dart';
import '../features/tuition/data/tuition_repository.dart';
import '../features/tuition/domain/invoice_service.dart';
import '../features/tuition/domain/tuition_policy_service.dart';
import '../features/tuition/domain/tuition_service.dart';
import 'demo_data_seeder.dart';
import 'demo_seed_result.dart';

Future<DemoSeedResult?> runDemoSeedIfEnabled(
  ProviderContainer container,
) async {
  const isSeedEnabled = bool.fromEnvironment('SEED_DEMO_DATA');
  if (!kDebugMode || !isSeedEnabled) {
    return null;
  }

  final db = await container.read(databaseProvider.future);
  final classRepo = ClassRepository(db);
  final membershipRepo = MembershipRepository(db);
  final studentRepo = StudentRepository(db);
  final scheduleRepo = ScheduleRepository(db);
  final assignmentRepo = AssignmentRepository(db);
  final sessionRepo = SessionRepository(db);
  final attendanceRepo = AttendanceRepository(db);
  final leaveRepo = LeaveRequestRepository(db);
  final tuitionPolicyRepo = TuitionPolicyRepository(db);
  final tuitionRepo = TuitionRepository(db);
  final creditRepo = SessionCreditRepository(db);
  final paymentRepo = PaymentRepository(db);
  final adjRepo = SessionAdjustmentRepository(db);
  final constraintRepo = ScheduleConstraintRepository(db);

  final membershipService = MembershipService(membershipRepo);
  final classService = ClassService(classRepo, membershipService);
  final studentService = StudentService(studentRepo, membershipService);
  final tuitionPolicyService = TuitionPolicyService(
    tuitionPolicyRepo,
    classService,
    tuitionRepo,
    creditRepo,
    db,
  );

  final conflictService = ScheduleConflictService(
    constraintRepo,
    scheduleRepo,
    assignmentRepo,
    sessionRepo,
    adjRepo,
    classService,
  );
  final scheduleService = ScheduleDomainService(
    scheduleRepo,
    assignmentRepo,
    membershipService,
    classService,
    studentService,
    conflictService,
  );
  final sessionService = SessionService(sessionRepo, classService);
  final sessionGenService = SessionGenerationService(
    sessionRepo,
    scheduleService,
    classService,
  );
  final rosterService = RosterService(
    sessionService,
    membershipService,
    scheduleService,
    studentService,
    adjRepo,
  );
  final leaveService = LeaveRequestService(
    leaveRepo,
    studentService,
    classService,
    membershipService,
  );
  final attendanceService = AttendanceService(
    attendanceRepo,
    rosterService,
    sessionService,
    leaveService,
  );
  final creditService = SessionCreditService(
    creditRepo,
    sessionService,
    rosterService,
    attendanceRepo,
    studentService,
    classService,
    tuitionPolicyService,
  );
  final tuitionService = TuitionService(
    tuitionRepo,
    tuitionPolicyService,
    creditService,
    membershipService,
    attendanceRepo,
    adjRepo,
    sessionRepo,
  );
  final paymentService = PaymentService(paymentRepo, tuitionRepo, db);
  final invoiceService = InvoiceService(
    tuitionRepo,
    tuitionService,
    creditService,
    creditRepo,
    membershipService,
    paymentRepo,
    sessionService,
    db,
  );

  final seeder = DemoDataSeeder(
    classService: classService,
    studentService: studentService,
    membershipService: membershipService,
    scheduleService: scheduleService,
    sessionGenService: sessionGenService,
    sessionService: sessionService,
    attendanceService: attendanceService,
    tuitionPolicyService: tuitionPolicyService,
    invoiceService: invoiceService,
    paymentService: paymentService,
    db: db,
  );

  final result = await seeder.seed();
  // ignore: avoid_print
  print(result);
  return result;
}
