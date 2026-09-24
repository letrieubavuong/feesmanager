# Task Management - Phase 11B Final Closure Production Fix & Test Refinement

- [x] Step 1: Implement strict DOI_CA replacement relationship validation in `ScheduleConflictService.evaluateOneOffSessionCandidate`
- [x] Step 2: Implement direct regression tests for `evaluateOneOffSessionCandidate` (different date, different class, original == target, non-CHINH target, valid DOI_CA, arbitrary historical session exclusion attempt)
- [x] Step 3: Refine `HOC_BU` and `PHAT_SINH` test suites into focused, independent tests for recurring overlap, HARD_BLOCK, OTHER_CENTER, SOFT_PREFERENCE, and TRAVEL_BUFFER
- [x] Step 4: Refine `HUY` / `NGHI_LE` test to establish active effective participation and compare against a `DU_KIEN` control case
- [x] Step 5: Run Full Quality Gate (`flutter pub get`, `build_runner`, `dart format`, `flutter analyze`, `flutter test`)
- [x] Step 6: Commit and Push to `main`
- [x] Step 7: Verify Remote CI & Report Final Status
