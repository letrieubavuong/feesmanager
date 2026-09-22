# Phase 8 Walkthrough: Session Credit / Buổi Dư

I have implemented canonical Session Credit / Buổi Dư management with `SessionCreditService` as the single source of truth and `buoi_du_ledger` as the auditable persistence ledger.

## Key Accomplishments

### 1. Database Migration (v8 -> v9)
- **`buoi_du_ledger` Table**: Created with foreign keys to `hoc_sinh`, `lop`, `buoi_hoc`, and constraints `delta != 0` and reason enum validation.
- **Partial Unique Index**: `idx_buoi_du_auto_event_unique` prevents duplicate automated credit earning events on `(id_hoc_sinh, id_lop, id_buoi_hoc, ly_do)`.
- **Full Preservation**: Migration v8->v9 tested and preserves 100% of Phase 0-7 data.

### 2. Canonical Business Logic (`SessionCreditService`)
- **Scoped Balance**: Derived strictly via `SUM(delta)` for a `student + class` pair.
- **Eligible CHINH Sessions**: Filters `SessionType.CHINH` + `SessionStatus.DA_HOC` sessions where student belongs to canonical `RosterService` roster. Fails closed if roster is operationally invalid.
- **Standard vs Extra Classification**: 1-based indexing (1..12 standard, 13+ extra). Default 12 sessions limit isolated in `defaultStandardSessionsPerMonth`.
- **Credit Earning Rules**: Extra candidates earn +1 credit if attendance is `CO_MAT` or `TRE`. `HOC_BU` and `PHAT_SINH` sessions earn 0.
- **Idempotent Reconciliation**: Reconciling writes missing earned credits in an atomic transaction. Repeated runs create 0 duplicate rows.
- **Read Purity**: `previewMonth`, `getBalance`, `getLedger` are 100% read-only.
- **Manual Adjustments**: Append-only `DIEU_CHINH_THU_CONG` entry with mandatory non-empty note and strict `YYYY-MM-DD` date validation.

### 3. Presentation UI & Entry Points
- **`SessionCreditPage`**: Displays class-scoped balance, month selector, monthly summary stats, candidate list, reconciliation preview & action, manual adjustment action, and ledger history.
- **Navigation**: Integrated into `StudentDetailPage` per-class membership tile.

## Verification Summary

### Automated Tests
- **Total Tests**: 202
- **Pass Rate**: 100%

### Static Analysis
`flutter analyze` returned **No issues found!**.

### CI/CD
Pushed to `main` (Commit SHA: `b2f908493d742b0f67d0d397f040fe416e480e73`).
GitHub Actions Workflow Run [35681890123](https://github.com/letrieubavuong/feesmanager/actions/runs/35681890123) is **SUCCESS**.

**PHASE 8 READY FOR ACCEPTANCE**
