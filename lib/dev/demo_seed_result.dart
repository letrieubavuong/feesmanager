// lib/dev/demo_seed_result.dart

class DemoSeedResult {
  final int studentsCreated;
  final int studentsReused;
  final int classesCreated;
  final int classesReused;
  final int membershipsCreated;
  final int schedulesCreated;
  final int sessionsCreated;
  final int sessionsExisting;
  final int attendanceRecordsCreatedOrUpdated;
  final int sessionsFinalized;
  final int holidaySessions;
  final int stoppedStudents;
  final int tuitionPoliciesCreated;
  final int invoicesCreated;
  final int paymentsCreated;
  final List<String> warnings;

  const DemoSeedResult({
    this.studentsCreated = 0,
    this.studentsReused = 0,
    this.classesCreated = 0,
    this.classesReused = 0,
    this.membershipsCreated = 0,
    this.schedulesCreated = 0,
    this.sessionsCreated = 0,
    this.sessionsExisting = 0,
    this.attendanceRecordsCreatedOrUpdated = 0,
    this.sessionsFinalized = 0,
    this.holidaySessions = 0,
    this.stoppedStudents = 0,
    this.tuitionPoliciesCreated = 0,
    this.invoicesCreated = 0,
    this.paymentsCreated = 0,
    this.warnings = const [],
  });

  @override
  String toString() {
    final activeStudents = studentsCreated + studentsReused - stoppedStudents;
    return '[DEMO SEED RESULT]\n'
        'Classes: $classesCreated created, $classesReused reused (Total: ${classesCreated + classesReused})\n'
        'Students: $studentsCreated created, $studentsReused reused (Active: $activeStudents, Stopped: $stoppedStudents, Total: ${studentsCreated + studentsReused})\n'
        'Memberships: $membershipsCreated\n'
        'Schedules: $schedulesCreated\n'
        'Sessions: $sessionsCreated created, $sessionsExisting existing (Holiday: $holidaySessions, Finalized: $sessionsFinalized)\n'
        'Attendance Records: $attendanceRecordsCreatedOrUpdated\n'
        'Tuition Policies: $tuitionPoliciesCreated\n'
        'Invoices: $invoicesCreated, Payments: $paymentsCreated\n'
        'Warnings: ${warnings.isEmpty ? "None" : warnings.join("; ")}';
  }
}
