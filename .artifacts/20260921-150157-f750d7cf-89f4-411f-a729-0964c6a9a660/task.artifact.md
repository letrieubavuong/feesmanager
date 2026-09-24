# Task Management - Phase 11B Final Test Suite Closure

- [x] Step 1: Split `HOC_BU` tests into focused tests (recurring overlap, HARD_BLOCK, OTHER_CENTER, SOFT_PREFERENCE, TRAVEL_BUFFER) & add one-off collision tests (DOI_CA, HOC_BU, PHAT_SINH)
- [x] Step 2: Split `PHAT_SINH` tests into focused tests (recurring overlap, HARD_BLOCK, OTHER_CENTER, SOFT_PREFERENCE, TRAVEL_BUFFER, non-overlap, duplicate target) & add one-off collision tests (DOI_CA, HOC_BU, PHAT_SINH)
- [x] Step 3: Expand `HUY` / `NGHI_LE` status filtering tests to explicitly execute `NGHI_LE` and include `DA_HOC` control case
- [x] Step 4: Run Full Quality Gate (`flutter pub get`, `build_runner`, `dart format`, `flutter analyze`, `flutter test`)
- [x] Step 5: Update `docs/REBUILD_STATUS.md` with exact test count
- [x] Step 6: Commit, Push to `main` & Verify Remote CI Status
