# TUITION2027 - APPLICATION ARCHITECTURE

## 1. Purpose

This document defines how the Tuition2027 codebase should be structured so business rules remain centralized, testable, and safe.

The domain constitution defines *what* the product must do. This document defines *where* that behavior belongs in code.

## 2. Target architecture

Primary runtime path:

`UI -> Controller / Use Case -> Domain Service -> Repository -> SQLite`

Supporting paths:

- reports consume canonical read models/services
- PDFs render already-computed canonical results
- notifications consume domain events/results
- Firebase/cloud replication consumes local canonical changes only after local correctness is approved

## 3. Suggested Flutter structure

```text
lib/
  app/
    routing/
    theme/
    bootstrap/
  domain/
    students/
    classes/
    memberships/
    schedules/
    sessions/
    attendance/
    leave/
    credits/
    tuition/
    payments/
    notifications/
    reports/
  data/
    db/
    repositories/
    migrations/
    legacy_import/
  controllers/
  screens/
  widgets/
  adapters/
  utils/
```

Exact paths may vary, but responsibilities must not.

## 4. Domain modules

### 4.1 Students

Owns:

- student profile
- parent contact
- phone normalization
- archive state

Must not own class membership or credit balance.

### 4.2 Classes

Owns:

- class profile
- subject/grade metadata
- archive state

Class size is derived from membership and reference date.

### 4.3 Memberships

Owns:

- student-class relationship intervals
- join/leave/pause/resume semantics
- class membership history
- membership-specific tuition discount

Canonical query:

`isStudentActiveInClass(student, class, date)`

### 4.4 Tuition policy

Owns effective-dated pricing:

- fee per session
- standard sessions per month
- monthly maximum if used

Historical months must resolve the policy active at that time.

### 4.5 Schedules

Owns recurring class schedules and student schedule assignments.

Does not own dated session completion.

### 4.6 Sessions

Owns dated instances generated from schedules or created as make-up/ad-hoc sessions.

Generation must be deterministic and idempotent.

### 4.7 Roster

`RosterService` is the only canonical owner of session roster composition.

Inputs:

- session
- membership intervals
- schedule assignments
- one-off adjustments

Output example:

```text
RosterEntry {
  student
  sourceMembership
  participationType
  attendanceState
  warnings
}
```

### 4.8 Attendance

Owns attendance commands and session-level attendance records.

Missing record is a valid state: `CHUA_DIEM_DANH`.

### 4.9 Leave requests

Owns parent/student leave requests and approval state.

An approved leave may prefill an attendance draft but does not itself become attendance history.

### 4.10 Session adjustments

Owns one-off changes:

- shift change
- make-up attendance
- ad-hoc participation

Never mutate the student's recurring assignment for a one-day exception.

### 4.11 Session credits

`SessionCreditService` is the only owner of credit earning and usage.

Credit balance is ledger-derived and scoped to student + class.

### 4.12 Tuition

`TuitionService` computes preview amounts from canonical domain inputs.

`InvoiceService` finalizes monthly snapshots and later adjustments.

Reports never recompute tuition formulas independently.

### 4.13 Payments

`PaymentService` records actual money received and rejects duplicate transaction identifiers.

Debt is derived from invoice minus payments.

### 4.14 Schedule conflicts

`ScheduleConflictService` evaluates hard conflicts, soft warnings, and travel-buffer rules.

### 4.15 Notifications

`NotificationService` prepares/sends messages from canonical domain events.

It must not become a source of student or tuition truth.

### 4.16 Reports

`ReportService` composes canonical outputs.

Reports do not own formulas.

## 5. Controller rules

Controllers:

- load domain results
- expose UI state
- execute commands
- handle optimistic/loading/error state

Controllers do not own domain calculations.

If two screens need the same metric, create a domain/read-model service instead of duplicating calculations in controllers.

## 6. Repository rules

Repository methods should express domain intent, for example:

- `getStudentById`
- `getActiveMembershipsForClass(date)`
- `getSchedulesForClass(date)`
- `getSessionsForClass(range)`
- `getAttendanceForSession`
- `getPaymentsForStudentClassMonth`

Avoid exposing generic raw SQL helpers to screens/controllers.

## 7. Read models

Use dedicated read models for complex screens to avoid N+1 queries and repeated business reconstruction.

Examples:

### ClassListItem

- class
- activeStudentCount
- nextSession
- unpaidCount

### StudentOverview

- student
- activeClasses
- upcomingSessions
- currentDebt
- attendanceSummary

### SessionRosterView

- session
- roster entries
- attendance completion status
- unresolved warnings

Read models remain derived and must not become independent persisted truth.

## 8. Adapters and compatibility

During rebuild, legacy UI or legacy models may need adapters.

Rules:

- adapters live in an explicit `adapters/` or `compat/` folder
- adapters may translate representation, not business meaning
- adapters must have a retirement plan
- do not let legacy aliases leak back into canonical SQLite

## 9. Date/time conventions

Persist dates as ISO-8601 date strings where date-only semantics are intended:

`YYYY-MM-DD`

Persist month as:

`YYYY-MM`

Persist local class times as:

`HH:mm`

Canonical weekday follows Dart `DateTime.weekday` 1..7 Monday..Sunday.

Avoid locale-formatted strings in persistence.

## 10. Status vocabularies

Statuses are canonical enums/vocabularies, not arbitrary strings.

Unknown legacy values must be normalized at migration boundaries or reported.

Do not add alternate spelling variants to core services as permanent compatibility logic.

## 11. Transactions

Use database transactions for multi-row business commands such as:

- finalizing invoice + credit usage
- applying session adjustment + attendance link
- importing a deterministic batch

A failed command should not leave partial business state.

## 12. Soft delete and archive

Students/classes with history are archived, not hard-deleted.

Historical records remain queryable for past reports.

## 13. Events and notifications

After local correctness is stable, consider explicit domain events such as:

- `AttendanceFinalized`
- `StudentAbsentWithoutPermission`
- `InvoiceFinalized`
- `PaymentRecorded`

Notification delivery subscribes to these events instead of embedding notification code inside repositories.

## 14. Firebase/web boundary

Before sync phase:

- Flutter SQLite is operational truth
- Firebase is not a second business engine
- web must not invent different rules

Later sync should replicate canonical entities using stable sync IDs/revisions, not local integer IDs as cross-device identity.

## 15. Build and quality gates

For every non-trivial change:

1. format
2. regenerate generated code if needed
3. analyze
4. run unit/domain tests
5. run repository/SQLite tests
6. run affected integration-style tests

No feature moves to the next rebuild phase if the current phase has compile errors.

## 16. Rebuild sequence

Recommended rebuild order:

1. schema + database access
2. students/classes
3. memberships
4. tuition policy
5. schedules + assignments
6. session generation
7. roster
8. attendance + leave
9. session adjustments
10. credits
11. tuition preview
12. invoice finalization
13. payments/debt
14. schedule conflicts
15. reports
16. notifications
17. legacy importer
18. real-data reconciliation
19. cloud/web sync

## 17. Architectural definition of done

A module is ready when:

- it has one canonical owner
- persistence schema is explicit
- read/write API is typed
- edge cases are covered by tests
- UI does not duplicate its rules
- historical data semantics are preserved
- downstream consumers use the same canonical output
