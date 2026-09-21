# Flutter Application Rules

All work under `lib/` must comply with:

- repository root `AGENTS.md`
- `docs/TUITION2027_DOMAIN_CONSTITUTION.md`
- `docs/DATABASE_SCHEMA.md`
- `docs/ARCHITECTURE.md`

## Layer rules

Required dependency direction:

`screen/widget -> controller/use_case -> domain_service -> repository -> database`

A lower layer must never depend on a higher layer.

### Screens and widgets

May:

- render state
- collect user input
- trigger controller actions
- show validation/warnings/errors

Must not:

- run raw SQL
- calculate class size
- determine active membership
- build roster rules
- calculate credits
- calculate tuition or debt
- infer schedule conflicts
- mutate database directly

### Controllers / use cases

May:

- orchestrate services
- manage loading/error/UI state
- combine already-canonical service outputs

Must not duplicate domain formulas.

### Domain services

Own business rules.

Examples:

- `RosterService` owns roster composition
- `AttendanceService` owns attendance commands/validation
- `SessionCreditService` owns credit earning/usage
- `TuitionService` owns tuition preview
- `InvoiceService` owns monthly tuition finalization/adjustments
- `ScheduleConflictService` owns assignment conflict rules

### Repositories

Own persistence access and canonical queries.

Repositories must not contain presentation behavior.

### Database boundary

Normalize values at the boundary.

Do not scatter `CAST`, `TRIM`, fuzzy identifier matching, or legacy aliases across business queries.

## Models

Do not maintain competing model families for the same canonical concept.

When migration/compatibility adapters are temporarily necessary, place them in an explicit adapter/compatibility layer and document their retirement plan.

## Riverpod

Never hand-edit `.g.dart` files.

Regenerate after annotation changes.

## Error handling

Do not silently replace unknown values with a valid business state.

Examples:

- unknown attendance must not become `CO_MAT`
- missing date must not become today's date
- missing join date must not become `2020-01-01`

Return/report a typed error or migration issue instead.

## Historical integrity

Do not hard-delete students, classes, sessions, attendance, invoices, payments, or ledger history once referenced by business history.

Use archive/state transitions and explicit adjustments.

## Tests

For every changed service/repository, add focused tests around its contract and edge cases from the domain constitution.
