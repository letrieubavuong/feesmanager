# Implementation Plan - Phase 8: Session Credit / Buổi Dư

Implement canonical Session Credit / Buổi Dư management with `SessionCreditService` as the single source of truth and `buoi_du_ledger` as the auditable persistence ledger.

## User Review Required

> [!IMPORTANT]
> **Key Architecture Decisions**:
> 1. **Credit Scope**: Credit belongs strictly to `student + class` (never global student balance).
> 2. **No Stored Balance Column**: Credit balance is derived exclusively via `SUM(delta)` from `buoi_du_ledger`.
> 3. **Default Standard Sessions**: Default limit is 12 sessions per month, isolated in `SessionCreditService.defaultStandardSessionsPerMonth`.
> 4. **No Automatic Credit Consumption**: Approved absences (`NGHI_CO_PHEP`) do NOT auto-consume credits in Phase 8 (`BU_TRU_NGHI_CO_PHEP` reason is in schema/enum for Phase 9 tuition integration).
> 5. **Read Purity**: All preview and balance queries are 100% read-only. Reconciliation is an explicit write action.

## Proposed Changes

### Database Migration (v8 -> v9)

#### [app_database.dart](file:///C:/Lap%20trinh%20Android/Tuition2027/lib/core/database/app_database.dart)
- Upgrade `_version` to 9.
- Implement `_migrateV8ToV9`:
  - Create table `buoi_du_ledger`.
  - Create partial unique index `idx_buoi_du_auto_event_unique`.
  - Create indexes for `(id_hoc_sinh, id_lop, ngay_hieu_luc)`, `(id_lop, ngay_hieu_luc)`, and `(id_buoi_hoc)`.

---

### Session Credits Module

#### [NEW] [credit_ledger_reason.dart](file:///C:/Lap%20trinh%20Android/Tuition2027/lib/features/session_credits/domain/credit_ledger_reason.dart)
- Define `CreditLedgerReason` enum: `VUOT_SO_BUOI_CHUAN`, `BU_TRU_NGHI_CO_PHEP`, `DIEU_CHINH_THU_CONG`, `MIGRATION`.

#### [NEW] [credit_ledger_entry.dart](file:///C:/Lap%20trinh%20Android/Tuition2027/lib/features/session_credits/domain/credit_ledger_entry.dart)
- Typed model for `buoi_du_ledger` rows.

#### [NEW] [credit_session_candidate.dart](file:///C:/Lap%20trinh%20Android/Tuition2027/lib/features/session_credits/domain/credit_session_candidate.dart)
- Typed read model for monthly session classification (`isStandard`, `isExtra`, `earnsCredit`, `existingEarnedLedgerEntry`).

#### [NEW] [monthly_credit_summary.dart](file:///C:/Lap%20trinh%20Android/Tuition2027/lib/features/session_credits/domain/monthly_credit_summary.dart)
- Read model for monthly credit status and preview.

#### [NEW] [session_credit_repository.dart](file:///C:/Lap%20trinh%20Android/Tuition2027/lib/features/session_credits/data/session_credit_repository.dart)
- Persistence layer for `buoi_du_ledger`.

#### [NEW] [session_credit_service.dart](file:///C:/Lap%20trinh%20Android/Tuition2027/lib/features/session_credits/domain/session_credit_service.dart)
- Single canonical business owner of credit rules, eligibility calculation, standard vs extra classification, previewing, and idempotent reconciliation.

#### [NEW] [session_credit_controller.dart](file:///C:/Lap%20trinh%20Android/Tuition2027/lib/features/session_credits/presentation/session_credit_controller.dart)
- Riverpod notifier managing credit state and commands.

#### [NEW] [session_credit_page.dart](file:///C:/Lap%20trinh%20Android/Tuition2027/lib/features/session_credits/presentation/session_credit_page.dart)
- Mobile-friendly UI for credit summary, candidate preview, reconciliation, manual adjustment, and ledger history.

#### [student_detail_page.dart](file:///C:/Lap%20trinh%20Android/Tuition2027/lib/features/students/presentation/student_detail_page.dart)
- Add navigation entry point to `SessionCreditPage` per class.

---

### Documentation

#### [DATABASE_SCHEMA.md](file:///C:/Lap%20trinh%20Android/Tuition2027/docs/DATABASE_SCHEMA.md)
- Update with implemented v9 schema details.

#### [ARCHITECTURE.md](file:///C:/Lap%20trinh%20Android/Tuition2027/docs/ARCHITECTURE.md)
- Document `SessionCreditService` canonical ownership.

#### [REBUILD_STATUS.md](file:///C:/Lap%20trinh%20Android/Tuition2027/docs/REBUILD_STATUS.md)
- Mark Phase 8 COMPLETE with exact test count.

---

### Verification Plan

#### Automated Tests
1. **Migration Tests** (`test/repository/migration_v8_v9_test.dart`):
   - Upgrade v8->v9 preserving Phase 0-7 data.
   - Fresh v9 install with clean foreign key check.
   - SQLite `CHECK` and `UNIQUE` constraint tests.
2. **Domain & Service Unit Tests** (`test/session_credits/session_credit_service_test.dart`):
   - Eligible sessions calculation (CHINH + DA_HOC + RosterService participant).
   - Standard (1..12) vs Extra (13+) classification.
   - Earning rules (`CO_MAT`/`TRE` -> +1, others -> 0).
   - Exclusion of `HOC_BU` and `PHAT_SINH`.
   - Idempotent reconciliation.
   - Class-scoped balance and `getBalanceAsOf` date filtering.
   - Manual adjustment validation and audit trail.
   - Pure read verification.
3. **Widget & Presentation Tests** (`test/presentation/session_credits_ui_test.dart`):
   - Credit page rendering, reconciliation preview, manual adjustment form, error propagation.

#### Full Quality Gate Commands
```bash
dart format .
dart run build_runner build --delete-conflicting-outputs
git ls-files '*.dart' ':!:**/*.g.dart' | ForEach-Object { dart format --output=none --set-exit-if-changed $_ }
flutter analyze
flutter test
```
