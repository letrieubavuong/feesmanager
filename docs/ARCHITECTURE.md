# TUITION2027 - APPLICATION ARCHITECTURE

> Business contract revision: 2026-09-30. This document specifies the new target behavior: center-wide pricing, beginning-of-month provisional collection, and end-of-month reconciliation. New APIs/schema below are requirements, not a claim that they are already implemented. Update `TUITION2027_DOMAIN_CONSTITUTION.md` consistently before implementation. Preserve legacy invoice/policy/payment history.

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

### 4.4 Center tuition policy

`TuitionPolicyService` owns effective-month center pricing. New operational pricing applies to all classes/grades; there is no per-class pricing override or policy creation step after creating a class.

Policy fields: standard sessions N, integer VND unit price P, optional monthly cap C, excused-absence fee rule, and effective month interval. New versions start at a month boundary. Resolve the version for the billing month, never today's settings for an old month.

Membership-specific discount remains owned by Memberships. Do not relocate/delete discounts during this change.

Legacy class policies remain available only for historical explanation and explicitly marked legacy-period resolution. Do not delete policies referenced by old invoices or synthesize per-class policies for new classes. If old classes have different prices, require explicit center setup instead of selecting the first policy.

Settings owns the policy editing entry point; SQLite/versioned policies own pricing truth. SharedPreferences may store theme/locale, not authoritative financial policy.

### 4.5 Schedules

Owns recurring schedules and student assignments with inclusive effective-from/effective-to dates; a null end means open-ended.

A schedule-change use case previews conflicts and impacted memberships, assignments and generated sessions before applying a change. Distinguish editing an unused interval from introducing a new version after protected history.

Preview returns typed hard conflicts/soft warnings with student/class, dates, both times and resolution actions. Assignment absence alone does not make a schedule safe to edit: check sessions, attendance, adjustments and historical financial references.

Apply revalidates the revision and atomically versions the schedule, trims/splits assignments against membership, and regenerates safe affected planned sessions. Preserve attended/referenced sessions and holiday/cancellation semantics. Generation errors roll back the command. Extract a pure generation planner or an orchestration service to avoid a ScheduleService/GenerationService circular dependency.

Schedules do not own session completion. Notify downstream read models and reminder planning only after successful commit.

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

`TuitionService` owns one calculator and two explicit read modes:

- PROJECTED: eligible generated main sessions, planned or completed, within membership/assignment/schedule dates; exclude holiday/canceled sessions. Used for beginning-of-month collection.
- ACTUAL: attendance-based fee rules and canonical credit handling. Used for end-of-month reconciliation; missing required data produces an incomplete result, not a finalized zero amount.

Use canonical roster/adjustment semantics so shift changes and cross-class make-up attendance are not charged twice. Make-up for a paid entitlement does not create another tuition charge. Credit preview stays read-only; future attendance never earns credits.

For the retained standard-session/extra-credit rule, q is the chargeable standard-session count before limiting, N is standard limit, P is unit price, C is optional cap and d is membership discount:

```text
billedSessions = min(q, N)
gross = billedSessions * P
cappedBase = C == null ? gross : min(gross, C)
discountAmount = floor(cappedBase * d / 100)
amountDue = cappedBase - discountAmount
```

Use integer VND. When C=N*P, this matches discounted unit price times billed sessions. Applying discount before an independent cap is a different rule and must not remain in another calculation branch.

`InvoiceService` owns stable monthly statements and immutable revisions/snapshots. A provisional statement permits collection before future attendance. End-of-month reconciliation records actual fees and credit events atomically, retaining statement ID and payment links. Corrections after finalization create an auditable revision and mark stale inputs as needing reconciliation.

A student's reconciliation readiness depends on their eligible sessions; unrelated class shifts must not block them. Class reconciliation previews ready/not-ready students and confirms the chosen ready set without silently skipping errors.

Reports, QR, PDFs and UI consume these outputs, never independent fee formulas.

### 4.13 Payments

`PaymentService` records money actually received, including partial payments against a valid provisional statement, and rejects duplicate transaction identifiers.

Separate statement lifecycle (PROVISIONAL/FINALIZED) from settlement status (UNPAID/PARTIAL/PAID/OVERPAID). Paid does not mean reconciled.

```text
paid = sum(valid actual receipts)
signedBalance = amountDue - paid
remainingToCollect = max(signedBalance, 0)
overpaid = max(-signedBalance, 0)
```

A lower reconciled fee can produce valid overpayment. Recalculating tuition must not rewrite receipt amounts or actual payment dates. Refund/carry-forward requires an explicit linked monetary event; session credits are not money credits. Until such an action is implemented, show overpayment accurately and leave its disposition pending.

QR collection uses remainingToCollect, not the full original fee; no collection QR when remaining is zero or inputs/bank configuration are invalid. Provisional parent notices are explicitly labeled as estimates.

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

- creating/updating a provisional statement + recording a receipt
- applying an end-of-month statement revision + credit events
- applying a schedule version + assignment splits + planned-session regeneration
- applying session adjustment + attendance link
- importing a deterministic batch

A failed command should not leave partial business state. Use transaction-aware repositories throughout a command; do not call services that use the outer database from inside a transaction. Precomputed plans need a revision check before commit.

## 12. Soft delete and archive

Students/classes with history are archived, not hard-deleted.

Historical records remain queryable for past reports.

## 13. Events and notifications

After local correctness is stable, consider explicit domain events such as:

- `AttendanceFinalized`
- `StudentAbsentWithoutPermission`
- `ProvisionalStatementUpdated`
- `InvoiceFinalized`
- `TuitionReconciliationRequired`
- `ScheduleChanged`
- `PaymentRecorded`

Notification delivery subscribes to these events instead of embedding notification code inside repositories.

After a successful write affecting payment, attendance, policy, enrollment/discount, holiday or schedule, refresh affected class/month tuition, statement/payment summaries, parent slips, dashboard and reports. Schedule changes also rebuild reminder planning. Centralize affected-scope invalidation; a failed transaction must not be reported as successful.

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
11. projected and actual tuition read models
12. provisional statements and payments
13. end-of-month reconciliation and overpayment handling
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

## 18. Operational acceptance for the revised contract

- Android-first: edit -> hot reload -> verify affected screen immediately. Restart for schema/native/plugin/generated changes when required; hot reload alone is not a migration test.
- Verify an old populated database upgrade, not only a clean installation.
- Example N=12, P=50,000, C=600,000, discount10%: 12 eligible sessions ->540,000; mid-month enrollment with7 sessions ->315,000; paid200,000 ->remaining115,000.
- If reconciled fee becomes270,000 after collection315,000, retain receipts and show overpaid45,000.
- Test schedule from/to changes, clear conflicts, protected history, regeneration idempotency and automatic downstream refresh.
- Full build/test evidence must identify commit, schema version and environment. Previous PASS evidence does not certify the revised contract.
