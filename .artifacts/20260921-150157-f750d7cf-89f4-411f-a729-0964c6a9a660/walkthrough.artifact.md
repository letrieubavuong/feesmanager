# Phase 11B: One-Off Schedule Conflict Integration Walkthrough

Phase 11B integrates `ScheduleConflictService` into domain commands for `DOI_CA`, `HOC_BU`, and `PHAT_SINH` in `SessionAdjustmentService`.

## Key Accomplishments

1. **REQUIRED Conflict Dependency in `SessionAdjustmentService`**
   - `ScheduleConflictService` is now a REQUIRED non-nullable field in `SessionAdjustmentService`.
   - Null bypass paths removed; all domain commands (`createDoiCa`, `createHocBu`, `createPhatSinh`) recheck conflicts using `evaluateOneOffSessionCandidate` prior to persistence.

2. **Canonical Session-Based One-Off API (`evaluateOneOffSessionCandidate`)**
   - Uses `targetSessionId` as the source of truth for date, start/end times, and class.
   - Handles exact `DOI_CA` replacement semantics by excluding `replacingOriginalSessionId` and its matching recurring schedule `idLichHoc`.

3. **Effective Roster Precision & Multi-Shift Correctness**
   - Resolves effective roster participation: `(isBaseRostered && !hasOutgoingDoiCa) || hasIncomingAdjustment`.
   - Multi-shift classes match base participation via `assignment.idLichHoc == session.idLichHoc` instead of broad class ID.
   - Outgoing `DOI_CA` adjustments release student commitments on the original session date.

4. **N+1 Elimination & Batch Querying**
   - Implemented `getByTargetSessionIds` and `getByOriginalSessionIds` in `SessionAdjustmentRepository`.
   - Single batch queries for adjustments, sessions, and classes on target date.

5. **Exhaustive Unit & Integration Test Suite**
   - Tests covering `DOI_CA` third commitments, `HARD_BLOCK`, `OTHER_CENTER`, `SOFT_PREFERENCE`, `TRAVEL_BUFFER`, `HOC_BU`, `PHAT_SINH`, multi-shift roster precision, and outgoing `DOI_CA` commitment removal.
   - Quality Gate: `dart format .` clean, `flutter analyze` clean (0 issues), `flutter test` **303 / 303 tests passed**.
   - Commit pushed to `origin/main` commit `486e311e86008c953ab3d7e2ea4cd6d643386796`.
