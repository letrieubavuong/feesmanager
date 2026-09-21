# TUITION2027 - MANDATORY PROJECT INSTRUCTIONS

> Applies to the whole repository unless a deeper `AGENTS.md` adds stricter local rules.

## 1. Mandatory reading order

Before planning, editing, refactoring, debugging, migrating data, changing schema, or adding a feature, read these files in order:

1. `docs/TUITION2027_DOMAIN_CONSTITUTION.md`
2. `docs/DATABASE_SCHEMA.md`
3. `docs/MIGRATION_RULES.md` when legacy data or schema conversion is involved
4. `docs/ARCHITECTURE.md`
5. The nearest deeper `AGENTS.md`, if present

The domain constitution is the highest authority for business behavior.

If existing code, comments, tests, README files, old database fields, Firebase nodes, or legacy services conflict with the constitution, do not silently preserve the conflict. Report it and implement the constitution unless the user explicitly changes the business rule.

## 2. Core product rule

Tuition2027 must have one canonical owner for each business concept.

Do not create duplicate concepts, duplicate tables, duplicate formulas, duplicate status vocabularies, or duplicate foreign-key names.

Required flow:

`UI -> Controller / Use Case -> Domain Service -> Repository -> SQLite`

Screens and widgets are presentation code. They must not own business formulas.

## 3. Source-of-truth rules

Raw operational truth includes:

- students
- classes
- student-class memberships
- tuition policies
- recurring schedules
- schedule assignments
- actual sessions
- leave requests
- one-off session adjustments
- attendance
- session-credit ledger entries
- monthly tuition invoices
- payments
- schedule constraints
- notification delivery records

Derived values include:

- active class size
- eligible session count
- attendance rate
- current session-credit balance
- amount due
- amount paid
- debt
- dashboard metrics

Derived values must be recalculable from canonical raw data or from an explicit immutable snapshot such as a finalized monthly invoice.

## 4. Canonical identifiers

Use one SQLite naming convention only:

- `hoc_sinh.id` -> `id_hoc_sinh`
- `lop.id` -> `id_lop`
- `tham_gia_lop.id` -> `id_tham_gia_lop`
- `lich_hoc.id` -> `id_lich_hoc`
- `buoi_hoc.id` -> `id_buoi_hoc`
- `chinh_sach_hoc_phi.id` -> `id_chinh_sach_hoc_phi`

Do not introduce aliases such as `student_id`, `hs_id`, `id_hs`, `hocSinhId`, `class_id`, `_key`, or equivalent duplicates inside the canonical SQLite schema.

Dart may use camelCase properties, but serialization must map to canonical SQLite columns.

## 5. Membership rule

Class membership is owned only by `tham_gia_lop`.

A student may attend multiple classes, each with an independent start/end history.

Pause/resume is represented by multiple membership intervals, not by an ever-growing set of status/date columns.

Never invent missing legacy dates such as `2020-01-01` or today's date.

Unknown migration facts must be preserved and reported.

## 6. Schedule and session rule

`lich_hoc` is a recurring schedule rule.

`buoi_hoc` is a dated actual/planned session.

Canonical weekday is Dart-compatible:

- 1 Monday
- 2 Tuesday
- 3 Wednesday
- 4 Thursday
- 5 Friday
- 6 Saturday
- 7 Sunday

Do not identify an actual session by fuzzy attendance timestamp when `id_buoi_hoc` exists.

## 7. Roster rule

There is exactly one canonical roster engine:

`getRosterForSession(idBuoiHoc)`

It must account for:

- active membership on the session date
- active schedule assignment
- one-off shift changes
- make-up attendance
- other session adjustments

No screen, report, dashboard, or PDF exporter may reconstruct roster logic independently.

## 8. Attendance rule

Attendance identity is:

`id_buoi_hoc + id_hoc_sinh`

Missing attendance row means `CHUA_DIEM_DANH`.

Missing attendance never means `CO_MAT`.

Unknown legacy attendance statuses must never default to present.

## 9. Session-credit rule

Session credit belongs to `student + class`, never globally to a student.

The ledger is the source of truth.

No screen or report may recalculate credits independently.

## 10. Tuition rule

There is exactly one canonical tuition engine.

Screens, dashboards, reports, and PDF code must consume the canonical result instead of implementing their own formulas.

Monthly finalized tuition must be stored as an explicit invoice snapshot so historical months do not change when future prices or policies change.

Payments are actual money received. Debt is derived from finalized/preview amount due minus actual payments.

## 11. Data safety

Never use destructive shortcuts on user data.

Do not:

- reset the production database
- drop history tables to fix schema problems
- renumber existing student/class IDs without a proven migration need
- hard-delete students/classes with history
- silently repair ambiguous data
- default unknown attendance to present
- silently discard rows using `ConflictAlgorithm.ignore`

Prefer archive/soft-delete and explicit migration issues.

## 12. Legacy database

The legacy database is read-only source material during rebuild/migration.

Migration classifies legacy records as:

- SAFE
- NORMALIZABLE
- AMBIGUOUS

Ambiguous records must be preserved and reported for review.

## 13. Firebase and web

Until local SQLite correctness is explicitly approved:

- SQLite is the operational source of truth for Flutter
- do not enable two-way Firebase sync
- do not convert Firebase into the operational truth
- do not redesign Next.js data semantics independently

Cloud/web migration is a later phase.

## 14. Generated files

Never hand-edit Riverpod generated files ending in `.g.dart`.

After annotation changes run:

`dart run build_runner build --delete-conflicting-outputs`

## 15. Test requirement

Any change affecting membership, schedules, roster, attendance, credits, tuition, invoices, payments, migration, or data integrity must add/update tests.

A test containing comments but no meaningful execution/assertion is not a valid test.

Before declaring completion, run as applicable:

- `dart format .`
- `dart run build_runner build --delete-conflicting-outputs`
- `flutter analyze`
- `flutter test`

Do not claim success unless commands were actually run and results were checked.

## 16. Non-trivial change protocol

Before editing:

1. Identify affected domain entities.
2. Trace UI -> controller -> service -> repository -> SQLite.
3. Search for all duplicate implementations of the same business rule.
4. Check downstream consumers: dashboard, reports, PDF, attendance, tuition, notifications.
5. Check persistence compatibility and migration needs.
6. Preserve historical data.
7. Prefer fixing the canonical owner rather than adding a workaround.

## 17. Definition of done

A task is not complete merely because the UI appears to work.

It is complete only when:

- behavior follows the domain constitution
- no duplicate business formula is introduced
- persisted data remains safe
- relevant tests exist and pass
- `flutter analyze` has no new errors
- `flutter test` passes for the affected scope
- legacy/cloud compatibility implications are documented
