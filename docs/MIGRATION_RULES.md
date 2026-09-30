# TUITION2027 - LEGACY DATA MIGRATION RULES

> Business contract revision: 2026-09-30. This document specifies the new target behavior: center-wide pricing, beginning-of-month provisional collection, and end-of-month reconciliation. New APIs/schema below are requirements, not a claim that they are already implemented. Update `TUITION2027_DOMAIN_CONSTITUTION.md` consistently before implementation. Preserve legacy invoice/policy/payment history.

## 1. Purpose

This document defines both legacy import into the canonical schema and forward upgrades of an already operating canonical database, without losing history or inventing facts. These are distinct operations.

The legacy database is source material, not the target architecture.

## 2. Safety principles

The migration process must never:

- mutate the legacy database
- drop legacy tables
- renumber student/class IDs without necessity
- invent missing dates
- invent schedules
- convert unknown attendance to present
- silently ignore conflicts
- double-import payments
- duplicate credits

Migration must be repeatable on a disposable target database until reconciliation passes.

## 3. Record classification

Every legacy record or mapping decision belongs to one of three classes.

### SAFE

Meaning is unambiguous and maps directly.

Examples:

- student id
- student name
- class id
- class name
- known parent phone

### NORMALIZABLE

Meaning is clear but representation needs normalization.

Examples:

- integer stored as text
- phone formatting
- Vietnamese attendance synonyms
- old weekday numbering
- whitespace/case differences

### AMBIGUOUS

Meaning cannot be reconstructed safely.

Examples:

- missing join date
- attendance timestamp matching multiple sessions
- global credit for student enrolled in multiple classes
- unclear payment aggregate plus detailed transactions
- conflicting duplicate schedules

Ambiguous data is preserved and reported, not guessed.

## 4. Migration issue tracking

Target database must include an issue log with at least:

- id
- import_run_id
- entity_type
- legacy_table
- legacy_id
- issue_code
- severity: ERROR/WARNING/INFO
- message
- raw_reference/serialized context
- resolved
- created_at

Unresolved ERROR blocks real-data acceptance.

## 5. Import run tracking

Migration must track runs, for example:

- id
- started_at
- finished_at
- source_database_fingerprint
- target_schema_version
- status
- counts

Importer must be idempotent.

Running the same import twice against the same clean target must produce the same canonical data, not duplicates.

## 6. Migration order

Required order:

1. students
2. classes
3. tuition policies if reconstructable
4. memberships
5. recurring schedules
6. schedule assignments
7. actual sessions
8. leave requests
9. session adjustments
10. attendance
11. credit ledger/opening adjustments
12. invoices if trustworthy legacy snapshots exist
13. payments
14. notifications/history if needed
15. reconciliation

Parent entities must exist before children.

## 7. Student migration

Preserve legacy student ID when valid.

Canonical mapping examples:

- `hoc_sinh.ten` -> `hoc_sinh.ho_ten`
- known parent name -> `ten_phu_huynh`
- canonical parent phone -> `sdt_phu_huynh`

If both a legacy parent-phone field and older generic phone field exist:

1. prefer explicit parent-phone value when valid
2. use generic legacy phone only when explicit parent phone is empty and domain meaning is known
3. log normalization provenance when needed

Do not make parent phone unique; siblings may share it.

## 8. Phone normalization

Normalize for lookup without destroying the original display/source value if useful.

Vietnam examples:

- `0905 123 456`
- `0905.123.456`
- `+84 905123456`
- `84905123456`

must resolve to the same canonical lookup form.

Invalid/uncertain phone strings produce a warning rather than fake data.

## 9. Class migration

Preserve class ID and core metadata.

Do not import derived class size as source of truth.

If historical tuition policy cannot be reconstructed, log a warning and require explicit policy bootstrap for future calculations.

## 10. Membership migration

Legacy `lop_hoc_sinh` or equivalent must become membership intervals.

Rules:

- real join date -> `tu_ngay`
- actual leave/end date -> `den_ngay`
- pause/resume creates multiple intervals
- expected resume date is not an actual resume interval

Never use `2020-01-01`, today, or another arbitrary fallback date.

Missing join date -> `MISSING_JOIN_DATE` ERROR/WARNING according to impact.

Ambiguous pause/resume -> `AMBIGUOUS_MEMBERSHIP`.

## 11. Weekday migration

If legacy recurring schedule uses:

- 1 Sunday
- 2 Monday
- 3 Tuesday
- 4 Wednesday
- 5 Thursday
- 6 Friday
- 7 Saturday

convert explicitly to canonical:

- 1 -> 7
- 2 -> 1
- 3 -> 2
- 4 -> 3
- 5 -> 4
- 6 -> 5
- 7 -> 6

Text weekday names must also normalize to canonical 1..7 Monday..Sunday.

Unknown weekday -> migration issue. Never default to Monday.

## 12. Schedule deduplication

Legacy may contain multiple schedule systems such as old class schedule, common schedule, or personal assignments.

Canonical recurring schedule identity should consider:

- class
- canonical weekday
- normalized start time
- normalized end time
- effective interval

Equivalent records are deduplicated.

Conflicting records are preserved as separate effective intervals when history is clear; otherwise log `CONFLICTING_SCHEDULE`.

## 13. Schedule assignment migration

Map personal assignment sources into `phan_ca_hoc_sinh`.

Prefer stable schedule relationships over fuzzy matching.

If a legacy assignment cannot be mapped uniquely to a canonical schedule:

`UNMAPPED_SCHEDULE_ASSIGNMENT`.

Do not invent an assignment start date. If legacy start is unknown, preserve that uncertainty explicitly rather than silently choosing an arbitrary date.

## 14. Session generation for historical migration

Do not create a session using attendance timestamp as its start time by default.

Historical sessions should be reconstructed from:

- recurring schedule
- class/date
- effective schedule interval
- known legacy session evidence

Generate only the date ranges required for history/reconciliation.

## 15. Attendance session mapping

For each legacy attendance record:

1. identify class
2. identify date
3. find canonical session candidates
4. use exact known relationship if available
5. if exactly one valid candidate exists, map it
6. if multiple valid candidates exist, log `AMBIGUOUS_ATTENDANCE_SESSION`
7. if no candidate exists, log `UNMAPPED_ATTENDANCE`

Do not select `candidate.first` when multiple candidates exist.

Do not create a fake zero-duration session merely to force mapping.

## 16. Attendance status normalization

Known mappings include:

- `Có mặt`, `CO_MAT` -> `CO_MAT`
- `Trễ`, `Muộn`, `TRE` -> `TRE`
- `Nghỉ có phép`, `Vắng có phép`, `NGHI_CO_PHEP` -> `NGHI_CO_PHEP`
- `Nghỉ không phép`, `Vắng không phép`, `NGHI_KHONG_PHEP` -> `NGHI_KHONG_PHEP`
- `Học bù`, `HOC_BU` -> `HOC_BU`

Unknown value -> `UNKNOWN_ATTENDANCE_STATUS`.

Unknown attendance must never be converted to `CO_MAT`.

## 17. Credit migration

Legacy global student credit is not automatically assignable to multiple classes.

If student has exactly one relevant class and provenance is clear, an opening ledger adjustment may be created with reason `MIGRATION`.

If student has multiple classes and legacy credit is global:

`AMBIGUOUS_CREDIT_MIGRATION`.

Do not duplicate the same global balance into every class.

## 18. Payment migration

Payment migration must distinguish:

- monthly aggregate paid amount
- detailed payment transactions
- bank notification transactions

Never import aggregate plus its underlying detailed transactions as separate money received.

If detailed transactions fully explain the aggregate, import the detailed transactions.

If only aggregate paid amount is trustworthy, create one migrated payment entry with explicit provenance such as `MIGRATED_LEGACY_AGGREGATE`.

If the relationship is unclear -> `PAYMENT_SOURCE_UNCLEAR`.

## 19. Invoice migration

Only migrate historical invoices if the legacy database contains a trustworthy finalized snapshot.

If legacy tuition was only dynamically recomputed, prefer rebuilding a clearly marked migration snapshot after reconciliation, not pretending it was historically finalized.

## 20. Reconciliation requirements

Reconciliation must compare semantics, not just row counts.

At minimum compare:

- student IDs and core fields
- class IDs and names
- student-class relationships
- membership intervals
- recurring schedule mappings
- schedule assignments
- attendance mapped/ambiguous/unmapped
- attendance totals by student/class/month
- payment totals by student/class/month
- credit opening balances and unresolved ambiguity
- unresolved migration issues

A membership row count may legitimately differ because one legacy row can become multiple pause/resume intervals.

## 21. Acceptance gate

Real-data migration is READY only when:

- target schema created successfully
- importer is idempotent
- no unresolved ERROR-level issue remains
- data integrity check passes
- reconciliation is accepted
- payment totals reconcile
- attendance mapping quality is reviewed
- legacy database remains untouched

Otherwise status is NOT_READY.

## 22. Rollback strategy

Until acceptance:

- legacy database remains available read-only
- only a disposable test/import target with no production writes may be deleted/recreated from the read-only source
- an operational canonical database must never be deleted/recreated to apply an upgrade
- no production workflow depends exclusively on partially migrated V2 data

Never delete the recovery path during migration development.

## 23. Forward upgrade: class pricing to center pricing

This is an upgrade of operating data, not permission to rerun an importer/reset a live database.

1. Identify actual source schema version from app_database.dart/migrations; back up the populated database with a restorable path.
2. Add center_tuition_policy with monthly boundaries and overlap protection; keep legacy chinh_sach_hoc_phi and historical FK links.
3. Preserve all invoice pricing snapshots. Rebuild any legacy NOT NULL policy reference constraint only through a tested forward migration; copy IDs and verify row/FK counts.
4. If old classes have different prices, log CENTER_POLICY_SETUP_REQUIRED and ask for explicit center setup. Do not choose first/latest arbitrary class or assign today's rate to every historical month.
5. Existing open or historical unfinalized periods need a documented resolver: legacy-period rules or an explicitly configured retroactive center version. Missing provenance is an issue, not a zero fee.
6. Preserve membership-specific discount values and intervals; no relocation of discount data in this migration.
7. Creating a class after the switch must not create a new class-specific policy.

Center price versions start on the first day of the selected billing month. Changing settings must not silently rewrite prior finalized snapshots or actual receipts.

## 24. Statement lifecycle and provisional receipts

- Preserve hoc_phi_thang IDs, created_at, student/class/month unique identity and all thanh_toan foreign keys.
- Map legacy NHAP to PROVISIONAL; DA_CHOT/DA_THANH_TOAN/CON_NO to FINALIZED. Settlement is derived separately from payments.
- Add immutable snapshot/revision provenance and a needs-reconciliation marker. Do not fabricate original historical snapshot dates.
- A provisional statement may receive partial/full payment without completion of future sessions.
- Lower reconciled fee with paid>due is OVERPAID; preserve all receipts and show the difference. Do not fail migration solely for that arithmetic relationship. Validate provenance of existing anomalies; unexplained historical data still requires review.
- Refund/carry-forward requires explicit linked monetary events, never duplicate receipts, credit-ledger entries or silent cross-class money movements.
- Read models/validators/reports must migrate consistently; simply removing recordPayment's finalized guard while leaving read validators unchanged is invalid.

## 25. Schedule interval upgrades and history protection

Schedules already have effective from/to fields. Improving editing is not grounds to rewrite attended sessions or invent assignment dates.

For a schedule-change command: read dependency batches, preview protected sessions/conflicts and assignment intersections, verify revision, then apply schedule versions, assignment splits and safe regenerated planned sessions in one transaction. Preserve holiday/cancellation rules and references. A failed command rolls back every mutation.

Exact assignment-start equality with membership start is not required; containment of the valid interval is required. Do not fix invalid assignments by inventing historical join dates.

## 26. Required upgrade acceptance tests

Use a real SQLite file with students, different class policies, mid-month memberships/discounts, both shifts, holiday/canceled sessions, attendance, credit entries, finalized/draft statements and partial payments.

Assert after upgrade:

- IDs, FK links, receipt amounts/payment dates and totals unchanged;
- archived entities and historical snapshots still readable;
- provisional collection works with planned sessions, without invented attendance;
- 7 sessions ×50,000 with10% discount ->315,000; paid200,000 ->remaining115,000;
- actual fee270,000 after receipt315,000 ->overpaid45,000;
- reconcile/reopen/retry does not duplicate receipts, revisions or credit events;
- policy ambiguity is reported, not guessed;
- transaction failure leaves the original data intact;
- upgrade is not rerun on reopening and backup recovery is verified.

Compare semantics and monetary totals as well as row counts. Mark READY only after tests and Android upgrade acceptance, with commit/version evidence. Keep the source backup/recovery path; do not tell users to uninstall or clear app data as a migration strategy.
