# Phase 11A Final Closure Walkthrough

Phase 11A core schedule conflict engine final closure is complete and verified against all domain constitution and persistence rules.

## Core Refactor & Hardening Summary

1. **Strict SQLite Time & Date CHECK Constraints (DB v13)**
   - Updated `AppDatabase._migrateV12ToV13` so time columns `gio_bat_dau` and `gio_ket_thuc` strictly require `00:00`..`23:59` via `(GLOB '[0-1][0-9]:[0-5][0-9]' OR GLOB '2[0-3]:[0-5][0-9]')` and `gio_ket_thuc > gio_bat_dau`.
   - Added strict `YYYY-MM-DD` shape checks on `ngay_cu_the`, `hieu_luc_tu`, `hieu_luc_den` with month 01..12 and day 01..31 validation via `GLOB` and `substr`.

2. **Date Validator Century Fix**
   - Fixed `DateAndTimeValidators._dateRegExp` to accept any 4-digit year (`^\d{4}-...`) while maintaining round-trip `DateTime.parse` calendar verification (rejecting invalid dates like `2026-02-31` and allowing future years like `2100-01-01`).

3. **Narrow Targeted Constraint Queries**
   - Implemented `getActiveForRecurringCandidate` in `ScheduleConstraintRepository` and integrated into `ScheduleConflictService.evaluateCandidateAssignment`. SQL now filters for relevant candidate constraints directly instead of loading all active constraints.

4. **Expanded Migration & Domain Test Matrix**
   - Expanded `test/repository/migration_v12_v13_test.dart` asserting raw DB rejects `25:00`, `24:00`, `24:01`, invalid status, invalid kieu, invalid loai, invalid weekday, negative travel buffer, `end <= start`, DINH_KY missing `effectiveFrom`, DINH_KY with `specificDate`, MOT_LAN missing `specificDate`, MOT_LAN with `weekday`, MOT_LAN carrying `effectiveFrom`/`effectiveTo`, malformed date shape `2026/10/15`, invalid month shape `2026-13-01`, and `effectiveTo < effectiveFrom`.
   - Added `DateAndTimeValidators` edge case tests in `test/schedule_conflicts/schedule_conflict_service_test.dart`.

5. **Quality Gate Verification**
   - `dart format .`: Clean.
   - `flutter analyze`: **0 issues found** (No issues found).
   - `flutter test`: **300 / 300 tests passed** (100% pass).
   - Commit pushed to `origin/main` commit `6139ce9e27012c9c619dd240d91859f88c29ab29`.
