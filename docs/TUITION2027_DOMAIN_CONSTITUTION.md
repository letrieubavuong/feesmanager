# TUITION2027 - DOMAIN CONSTITUTION

## 1. Status and authority

This document is the authoritative business source of truth for Tuition2027.

Code must implement this document. Code does not redefine this document.

If a business rule changes, update this document first, then update schema/services/tests.

## 2. Product purpose

Tuition2027 manages a private tutoring center and must answer consistently:

- who the student is
- who the parent is and how to contact them
- which classes the student attends
- when each class membership started/ended
- which recurring shift the student is assigned to
- which actual sessions exist on a date
- who belongs in each session roster
- attendance status for each student/session
- leave/make-up/one-off shift changes
- session-credit balance per student/class
- tuition due for a month
- actual payments and remaining debt
- schedule conflicts
- notifications to parents/students
- reports and dashboard metrics

Each answer must have one canonical business owner.

## 3. Fundamental laws

### 3.1 One concept, one owner

Do not implement the same rule in multiple screens/services.

### 3.2 Raw versus derived

Raw facts are persisted canonically.

Derived values are calculated by canonical services or stored only as explicit immutable/finalized snapshots.

### 3.3 Historical integrity

Past attendance, invoices, payments, and class membership history must remain explainable after future policy changes.

### 3.4 Unknown is not a valid substitute

Unknown data must never silently become a valid state.

Examples:

- unknown attendance != present
- unknown join date != arbitrary date
- unknown schedule != Monday

## 4. Student profile

A student profile stores personal/contact information only.

Canonical parent contact is `sdt_phu_huynh`.

Siblings may share the same parent phone.

Student profile does not own:

- current class
- join date
- credit balance
- debt

Those belong to other domain entities.

## 5. Parent phone and Zalo

Parent phone is normalized for lookup while preserving appropriate display/source information.

It is the primary contact used to resolve Zalo/contact workflows.

Changing parent phone must not modify class, attendance, tuition, or payment history.

A changed phone may require Zalo relinking/reverification.

## 6. Class

A class stores class identity/metadata.

Current class size is not persisted truth.

Class size on date D equals the number of active memberships on D, optionally filtered by archive/business rules.

## 7. Membership

A student belongs to a class through membership intervals.

A student may attend multiple classes concurrently.

Each class has its own independent membership history.

A membership is active on D when:

`tu_ngay <= D AND (den_ngay IS NULL OR den_ngay >= D)`

Pause/resume is represented by closing one interval and opening another.

Expected resume date does not make a student active.

Leaving a class closes the membership; it does not delete the student or history.

## 8. Tuition policy

Tuition policy is effective-dated per class.

It contains at least:

- standard sessions per month, default 12
- fee per session
- optional monthly maximum

Changing price in the future creates a new effective policy instead of rewriting old history.

## 9. Recurring schedule

A recurring schedule means a rule such as:

"Every Monday 17:30-19:00 from 2026-09-01."

Canonical weekday follows Dart:

1 Monday ... 7 Sunday.

Recurring schedule is not attendance and not an actual dated session.

## 10. Student schedule assignment

If a class has multiple shifts, students are assigned explicitly to a recurring schedule.

Example:

- An -> 17:30 shift
- Binh -> 19:00 shift

Students must not appear in every shift simply because they belong to the same class.

Assignments are effective-dated.

## 11. Actual session

An actual session is a dated event.

Example:

"2026-09-21 17:30-19:00".

Types:

- `CHINH`
- `HOC_BU`
- `PHAT_SINH`

Statuses:

- `DU_KIEN`
- `DA_HOC`
- `HUY`
- `NGHI_LE`

Session generation from recurring schedules is idempotent.

## 12. Canonical roster

There is one canonical operation:

`getRosterForSession(idBuoiHoc)`

Roster composition order:

1. load session
2. find memberships active on session date
3. apply schedule assignment
4. apply one-off shift changes/make-up/ad-hoc adjustments
5. produce final participants
6. left-join attendance

Every screen/report/dashboard uses the same roster result.

## 13. Attendance

Attendance is unique per student + actual session.

Canonical statuses:

- `CO_MAT`
- `TRE`
- `NGHI_CO_PHEP`
- `NGHI_KHONG_PHEP`
- `HOC_BU`

Missing attendance row means `CHUA_DIEM_DANH` in application state.

It is never implicitly present.

## 14. Session completion

A session may be finalized as taught after attendance workflow is completed.

If roster members remain `CHUA_DIEM_DANH`, UI must warn the teacher before finalization.

Teacher may explicitly resolve/override according to product UX, but the system never silently marks them present.

## 15. Leave request

A leave request records requested absence and approval state.

Statuses:

- `CHO_DUYET`
- `DA_DUYET`
- `TU_CHOI`

An approved leave may prefill an attendance draft as `NGHI_CO_PHEP` when a matching session occurs.

The leave request itself is not the final attendance record.

## 16. One-off shift change

A one-day shift change does not alter the recurring assignment.

The adjustment links:

- original session if applicable
- actual attended session
- student
- original class

The next normal session returns to the recurring assignment automatically.

## 17. Make-up attendance

A make-up session must identify the original missed session when it compensates one.

Make-up attendance does not rewrite the recurring schedule.

## 18. Eligible sessions for a student/month

All tuition and credit calculations start from the student's eligible sessions, not from all class sessions.

Eligibility considers:

- membership interval
- recurring assignment
- actual sessions
- session status
- one-off adjustments

A student joining mid-month is not eligible for sessions before joining.

A student paused during a date interval is not eligible during the pause.

## 19. Standard and extra sessions

For each student + class + month:

1. collect eligible `CHINH` sessions with status `DA_HOC`
2. order by date then time
3. first N sessions, where N is the effective tuition policy standard (default 12), are standard candidates
4. sessions N+1 onward are extra candidates

Session index is based on eligible sessions, not on attendance rows.

Missing attendance does not shift session numbering.

## 20. Earning session credits

For an extra candidate session:

- `CO_MAT` -> earn +1
- `TRE` -> earn +1
- `NGHI_CO_PHEP` -> earn 0
- `NGHI_KHONG_PHEP` -> earn 0
- `CHUA_DIEM_DANH` -> earn 0

A make-up session does not automatically earn an extra credit unless explicitly defined by future policy.

Each earned event is written once to the ledger.

## 21. Credit scope and ledger

Credit is scoped to student + class.

It is not a global student balance.

Balance equals `SUM(delta)` in `buoi_du_ledger` for that student/class.

Ledger reasons include:

- earned because of extra standard-overflow attendance
- used to compensate approved absence
- manual adjustment
- migration opening adjustment

Every balance must be explainable from ledger rows.

## 22. Using credits

Default policy for the rebuild:

A credit may compensate an approved absence in a standard eligible session when:

- absence is `NGHI_CO_PHEP`
- it has not already been compensated by valid make-up attendance
- credit is available before/according to finalized monthly policy

Using a credit creates a negative ledger entry.

`NGHI_KHONG_PHEP` does not consume credit.

Make-up attendance does not consume credit when it validly compensates the missed session.

Holiday/canceled sessions do not consume credit.

Joining mid-month never consumes credit merely to force the month up to 12 sessions.

## 23. Tuition preview

`TuitionService` is the canonical preview calculator.

Input:

- student
- class
- month

It resolves:

- effective membership
- effective tuition policy
- eligible standard sessions
- attendance/make-up outcomes
- credit usage policy
- membership-specific discount
- applicable monthly cap
- payments only for paid/remaining presentation, not to change gross tuition logic

## 24. Charge rules per standard eligible session

Default rebuild policy:

- `CO_MAT` -> charged
- `TRE` -> charged
- `NGHI_KHONG_PHEP` -> charged
- `NGHI_CO_PHEP` + valid make-up -> charged
- `NGHI_CO_PHEP` + credit used -> charged and consumes 1 credit
- `NGHI_CO_PHEP` + no make-up + no usable credit -> not charged
- canceled/holiday session -> not eligible and not charged

Extra sessions beyond the standard monthly count do not increase tuition under the default policy; attended extra sessions may earn credits.

## 25. Mid-month join example

Fee per session: 50,000.

Student joins on the 15th and has seven eligible standard sessions remaining.

If all seven are chargeable:

`7 x 50,000 = 350,000` before discount/cap rules.

Do not force the student to pay 12 sessions.

## 26. Discount

Discount is membership-specific by default.

Example:

A student can have 10% discount in one class and 0% in another.

Discount does not belong globally to student profile unless a future rule explicitly says so.

## 27. Monthly cap

If policy defines a monthly maximum, gross tuition cannot exceed it.

Apply policy consistently and test boundary cases.

## 28. Monthly invoice

Preview calculations may change as attendance is completed during the month.

When tuition is finalized, create/update a monthly invoice snapshot.

Invoice captures:

- eligible session count
- charged session count
- credit opening/earned/used/closing
- gross amount
- discount
- final amount due
- policy reference
- finalized timestamp/status

After finalization, historical amount must not silently change because a future class price changes.

Corrections require an explicit adjustment/re-finalization workflow.

## 29. Payment

Each payment row represents actual money received.

A student may make multiple partial payments for one month.

Example:

- 300,000
- 200,000
- 100,000

Total paid is the sum.

Transaction identifier, when present, prevents duplicate bank recording.

## 30. Debt

Debt is derived:

`invoice amount due - sum(actual payments)`

Do not persist another independent debt source of truth.

## 31. Schedule conflicts

ScheduleConflictService evaluates:

- exact overlap
- partial overlap
- contained overlap
- hard blocked schedule
- soft preference
- other center classes
- travel buffer
- effective-date overlap
- one-off specific-date constraints

Output includes:

- `canAssign`
- `hardConflicts`
- `softWarnings`
- `reasonCodes`

## 32. Notifications

Canonical triggers include:

- absence
- unexcused absence
- late attendance
- exam/grade notice
- urgent notice
- tuition reminder
- learning feedback

Notification records track delivery but do not become business truth.

Default tuition reminder policy retained unless changed explicitly:

- unpaid after day 15 -> reminder on day 16
- still unpaid -> reminder on day 26

Do not remind when fully paid.

## 33. Dashboard

Dashboard consumes canonical read services.

It may show:

- today's sessions
- upcoming sessions
- sessions not fully attended/finalized
- absences
- tuition debt
- urgent notices
- scheduling warnings

Dashboard must not reconstruct attendance or tuition rules independently.

## 34. Student detail

Recommended sections:

- profile
- active/history classes
- schedule
- attendance
- session credits
- tuition invoices
- payments
- feedback
- notifications

All values come from canonical services/read models.

## 35. Class detail

Recommended sections:

- overview
- students
- schedules/assignments
- sessions/attendance
- tuition
- evaluations
- reports

Class size is always reference-date aware.

## 36. Attendance screen

Flow:

1. choose date/class/session
2. load canonical roster
3. edit attendance draft
4. optional bulk action
5. save/finalize

Bulk action must support appropriate undo before finalization.

## 37. Reports

Reports consume canonical results from attendance, tuition/invoice, payment, and other domain services.

Supported scopes may include:

- month
- arbitrary date range
- one class
- all classes
- one student
- attendance
- debt
- revenue

Reports must not contain a private copy of formulas.

## 38. Data integrity

System integrity checks must be able to detect at least:

- foreign-key orphan
- overlapping memberships
- multiple open memberships for same student/class
- invalid effective intervals
- duplicate sessions
- duplicate attendance
- attendance outside canonical roster
- invalid schedule assignment
- duplicate credit event
- duplicate transaction
- invalid status vocabulary
- invalid date/time
- invoice/payment mismatch
- unresolved migration error

## 39. Deletion policy

Students/classes with history are archived rather than hard-deleted.

Attendance, invoices, payments, credits, and historical sessions are preserved.

## 40. Legacy migration

Legacy data is imported under `MIGRATION_RULES.md`.

Never invent missing facts merely to make migration pass.

## 41. Local-first gate

The rebuild must prove local SQLite correctness before two-way cloud sync or web semantic migration begins.

## 42. Mandatory business tests

At minimum test:

- siblings sharing parent phone
- missing parent phone
- student in multiple classes
- independent join dates
- mid-month join
- leave/end mid-month
- pause/resume
- one-shift class
- two shifts same day
- explicit assignments
- one-off shift change
- make-up attendance
- present
- late
- excused absence
- unexcused absence
- missing attendance
- holiday
- canceled session
- schedule change mid-month
- 12 eligible sessions
- 13 eligible sessions
- 14 eligible sessions
- extra session late
- extra session absence
- split payments
- duplicate bank transaction
- hard schedule conflict
- soft conflict
- travel buffer
- importer idempotency
- session generator idempotency

## 43. Cross-screen consistency

On the same dataset:

- class list size == class detail size for same reference date
- attendance screen roster == RosterService result
- attendance summary in student/class/dashboard/report must agree
- tuition shown in student/tuition/report must agree
- payment/debt shown across screens must agree

Any divergence is a system defect.

## 44. Prohibited architecture

Do not:

- create multiple FK names for the same concept
- place raw SQL in screens
- calculate class size in screens
- calculate roster in screens
- calculate tuition in screens
- calculate credit in reports
- use fuzzy time matching as normal session identity
- mutate data inside read methods
- treat missing attendance as present
- default unknown statuses to valid statuses
- invent migration dates
- hard-delete historical entities
- double-count payment
- double-count credit

## 45. Domain acceptance gate

The rebuilt data core is accepted only when:

- compile/analyze is clean for the affected scope
- domain tests pass
- migration tests pass
- data integrity passes
- cross-screen consistency passes
- legacy reconciliation is accepted
- credits are fully explainable from ledger
- historical invoices remain stable
- legacy data remains recoverable

Cloud sync starts only after this gate is explicitly approved.
