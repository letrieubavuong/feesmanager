# Task Management - Phase 11B Core Refactoring & Fail-Closed Hardening

- [x] Step 1: Refactor `ScheduleConflictService.evaluateOneOffCandidateInternal` to perform strict fail-closed relationship validation on persisted adjustments & batch load referenced sessions/classes
- [x] Step 2: Implement conflict deduplication between recurring assignment and generated `CHINH` session
- [x] Step 3: Implement comprehensive fail-closed corruption checks & relationship assertions for `DOI_CA`, `HOC_BU`, `PHAT_SINH`
- [x] Step 4: Split misnamed test in `test/session_adjustments/session_adjustment_service_test.dart` into separate `HARD_BLOCK` and `SOFT_PREFERENCE` tests
- [x] Step 5: Add full suite of tests in `test/session_adjustments/session_adjustment_service_test.dart` and `test/schedule_conflicts/schedule_conflict_service_test.dart`:
	- DOI_CA matrix tests (16 tests)
	- HOC_BU matrix tests (11 tests)
	- PHAT_SINH matrix tests (10 tests)
	- Multi-shift roster precision test
	- Outgoing & Incoming DOI_CA effective roster test
	- Fail-closed corruption tests
	- Deduplication conflict count test
- [x] Step 6: Update `docs/REBUILD_STATUS.md`
- [x] Step 7: Quality Gate & Push to `main` (`flutter pub get`, `build_runner`, `dart format`, `flutter analyze`, `flutter test`, `git push`)
