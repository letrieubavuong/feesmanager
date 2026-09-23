# Implementation Plan - Phase 11: Schedule Conflicts & Availability Constraints

This plan details the technical changes for Phase 11: upgrading DB to version 13 with `rang_buoc_lich_hoc_sinh`, implementing the canonical `ScheduleConflictService`, transferring conflict ownership from `ScheduleDomainService` and `SessionAdjustmentService`, adding student constraint management UI, integrating real-time conflict/warning previews into assignment and adjustment dialogs, and writing an exhaustive test suite (20+ new tests + real v12->v13 DB migration test).

## Engineering Blueprint

### 1. Database Upgrade v12 -> v13
- In `lib/core/database/app_database.dart`:
  - Increment DB version to 13.
  - Add `_migrateV12ToV13` creating `rang_buoc_lich_hoc_sinh` table with Foreign Key (`ON DELETE RESTRICT`) to `hoc_sinh`, strict `CHECK` constraints on types (`loai`), occurrence shape (`kieu`), time order (`gio_ket_thuc > gio_bat_dau`), non-negative travel buffer, and status (`HOAT_DONG`, `DA_HUY`).
  - Create performance indexes on `(id_hoc_sinh, trang_thai)`, `(id_hoc_sinh, thu_trong_tuan, hieu_luc_tu, hieu_luc_den)`, and `(id_hoc_sinh, ngay_cu_the)`.

### 2. Feature Architecture: `lib/features/schedule_conflicts/`
- **Domain Models**:
  - `schedule_constraint.dart`: Entity mapping to `rang_buoc_lich_hoc_sinh` with `ConstraintType` (`HARD_BLOCK`, `SOFT_PREFERENCE`, `OTHER_CENTER`), `OccurrenceType` (`DINH_KY`, `MOT_LAN`), `ConstraintStatus` (`HOAT_DONG`, `DA_HUY`).
  - `schedule_conflict_reason_code.dart`: Enum `ScheduleConflictReasonCode` (`EXACT_OVERLAP`, `PARTIAL_OVERLAP`, `CONTAINED_OVERLAP`, `HARD_BLOCK`, `SOFT_PREFERENCE`, `OTHER_CENTER_CLASS`, `TRAVEL_BUFFER`, `ONE_OFF_SESSION_CONFLICT`).
  - `schedule_conflict.dart`: Detailed metadata model (`reasonCode`, `isHard`, `message`, `existingClassId`, `existingScheduleId`, `existingSessionId`, `constraintId`, `date`, `weekday`, `startTime`, `endTime`, `sourceDescription`).
  - `schedule_conflict_result.dart`: `ScheduleConflictResult` (`canAssign = hardConflicts.isEmpty`, `hardConflicts`, `softWarnings`, `reasonCodes`).
- **Data Layer**:
  - `schedule_constraint_repository.dart`: SQLite CRUD repository for `rang_buoc_lich_hoc_sinh`.
- **Canonical Service**:
  - `schedule_conflict_service.dart`: Single canonical conflict engine evaluating candidate recurring assignments or one-off sessions against center assignments, constraints, and specific-date session commitments.
  - Correctly classifies `EXACT_OVERLAP`, `PARTIAL_OVERLAP`, `CONTAINED_OVERLAP`.
  - Implements travel buffer semantics (gap < buffer = soft warning `TRAVEL_BUFFER`, gap >= buffer = clear).

### 3. Service Ownership Transfer & Consumer Refactoring
- **`ScheduleDomainService`**:
  - Replaces internal inline `_isTimeOverlap` loop in `_validateAssignmentInterval` with `_conflictService.evaluateCandidateAssignment(...)`.
  - Preserves Phase 3 interval boundaries and atomic shift-change behavior.
- **`SessionAdjustmentService`**:
  - Calls `_conflictService.evaluateOneOffCandidate(...)` before creating `DOI_CA`, `HOC_BU`, or `PHAT_SINH`.
  - Excludes original session for `DOI_CA` to avoid false self-conflicts.

### 4. Presentation & UI Integration
- Constraint management in `StudentDetailPage`: view, create, and cancel constraints (no hard deletes).
- Conflict preview in `AssignStudentDialog` & `ChangeShiftDialog`: displays red banners for hard conflicts (blocks save) and amber banners for soft warnings (allows save).
- Conflict preview in `SessionAdjustmentDialogs` (`Đổi ca`, `Học bù`, `Phát sinh`).

### 5. Exhaustive Verification Suite
- `test/repository/migration_v12_v13_test.dart`: Real SQLite database migration v12 -> v13 asserting data preservation, FK RESTRICT enforcement, `CHECK` constraints, indexes, and clean `PRAGMA foreign_key_check`.
- `test/schedule_conflicts/schedule_conflict_service_test.dart`: Exhaustive test matrix (Tests A..Z and HOC_BU/PHAT_SINH/Phase 3 regressions).

---

## Verification Commands
```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
git ls-files '*.dart' ':!:**/*.g.dart' | ForEach-Object { dart format --output=none --set-exit-if-changed $_ }
flutter analyze
flutter test --no-pub -j 2
```
