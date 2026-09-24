# Phase 11B One-Off Collision & Status Filtering Test Splitting Walkthrough

Phase 11B test suite splitting and collision test matrix expansion are fully completed.

## Summary of Accomplishments

1. **HOC_BU One-Off Collision Tests Split**
   - Đã tách thành 3 bài test độc lập với persisted adjustments thực tế:
     - `overlapping incoming DOI_CA target participation blocks createHocBu`
     - `overlapping existing HOC_BU participation blocks createHocBu`
     - `overlapping PHAT_SINH participation blocks createHocBu`

2. **PHAT_SINH One-Off Collision Tests Split**
   - Đã tách thành 3 bài test độc lập với persisted adjustments thực tế:
     - `overlapping DOI_CA target participation blocks createPhatSinh`
     - `overlapping HOC_BU participation blocks createPhatSinh`
     - `overlapping PHAT_SINH participation blocks createPhatSinh`

3. **Status Filtering Execution & Controls (HUY, NGHI_LE, DU_KIEN, DA_HOC)**
   - Thực thi riêng biệt:
     - `Status filtering: effective participant + HUY + overlapping time -> no conflict`
     - `Status filtering: effective participant + NGHI_LE + overlapping time -> no conflict`
     - `Status filtering control: effective participant + DU_KIEN / DA_HOC + overlapping time -> hard conflict`

4. **Quality Gate Verification**
   - `dart format .`: Clean.
   - `flutter analyze`: **0 issues found**.
   - `flutter test`: **335 / 335 tests passed** (100% pass).
   - Commit + Push lên `origin/main` commit `50b38f5e96569fa53cf8ef611798672d86b0f4a1`.
