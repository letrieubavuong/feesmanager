# Task Management - Phase 11B: One-Off Schedule Conflict Integration

- [x] Step 1: Make `ScheduleConflictService` a REQUIRED non-nullable dependency in `SessionAdjustmentService` (and update provider & tests)
- [x] Step 2: Implement Batch Adjustment Repository APIs (`getByTargetSessionIds`, `getByOriginalSessionIds` in `SessionAdjustmentRepository`)
- [x] Step 3: Implement `evaluateOneOffSessionCandidate` in `ScheduleConflictService` with Session ID, Exact DOI_CA replacement semantics, Multi-shift accuracy, Effective Roster resolution, Batch Class/Adjustment queries, Deduplication & Fail-closed integrity
- [x] Step 4: Refactor `SessionAdjustmentService` (`createDoiCa`, `createHocBu`, `createPhatSinh`) to consume canonical `evaluateOneOffSessionCandidate` API and re-check conflicts before persistence
- [x] Step 5: Update `SessionAdjustmentDialogs` / UI Providers to adapt to the canonical `evaluateOneOffSessionCandidate` API without expanding UI scope
- [x] Step 6: Comprehensive Unit Tests in `test/session_adjustments/session_adjustment_service_test.dart` and `test/schedule_conflicts/schedule_conflict_service_test.dart` (DOI_CA, HOC_BU, PHAT_SINH, Multi-shift, Outgoing DOI_CA, Rollback, Edge cases)
- [x] Step 7: Update `docs/REBUILD_STATUS.md` & Quality Gate Verification (`flutter pub get`, `build_runner`, `dart format`, `flutter analyze`, `flutter test`)
- [x] Step 8: Commit, Push to `main` & Report Remote CI Status
