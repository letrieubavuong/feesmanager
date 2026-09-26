# TUITION2027 REBUILD STATUS

## Phase 0: Project Skeleton - COMPLETE
- [x] Feature-based directory structure
- [x] App shell with responsive navigation (Sidebar/BottomBar)
- [x] Light/Dark theme support
- [x] SQLite integration with `tuition_next.db`
- [x] Riverpod state management setup

## Phase 1: Student Module - COMPLETE
- [x] Canonical `hoc_sinh` table schema
- [x] Student domain model
- [x] Phone normalization utility
- [x] Student repository with CRUD and Search
- [x] Student service with business logic (validation, normalization)
- [x] Student list page with search and filter
- [x] Student form page for create/edit
- [x] Student detail page with profile info
- [x] Archive/Restore functionality (no hard delete)
- [x] Unit and Repository tests passing

## Phase 2: Class + Membership - COMPLETE
- [x] Database Migration (v1 -> v3) with `CHECK` constraints and Foreign Keys fixed.
- [x] Real file-based migration tests (v1->v3, v2->v3) including FK verification.
- [x] Membership overlap prevention logic with exhaustive unit tests.
- [x] Three-state Class Archive filter (Active, Archived, All).
- [x] Full membership history UI (closed + active) in Class and Student details.
- [x] Widget tests for main UI flows.

## Phase 3: Schedule + Student Shift Assignment - COMPLETE
- [x] Database Migration (v1 -> v5) with duplicate assignment protection.
- [x] Strict boundary enforcement (Membership & Schedule intervals).
- [x] Advanced future conflict detection (interval overlap algorithm).
- [x] Atomic shift changes (transacted close old, open new).
- [x] Presentation hardening (no direct repository calls).
- [x] Standardized Vietnamese weekday formatting.
- [x] GitHub Actions CI workflow implemented.
- [x] Quality Gate: 54 tests passing.

## Phase 4: Session Generation - COMPLETE
- [x] Database Migration (v5 -> v6) with canonical `buoi_hoc` table.
- [x] Idempotent session generation from recurring schedules.
- [x] Time snapshotting (Preserve historical session times if schedule changes).
- [x] Manual session creation (Học bù, Phát sinh) with strict validation.
- [x] Status management (Dự kiến, Hủy, Nghỉ lễ) with confirmation.
- [x] Class Detail UI integration with "Buổi học" tab and range filter.
- [x] Canonical session identity/conflict protection by class + date + start time.
- [x] Comprehensive Tests (88 tests passing).

## Phase 5: Canonical Session Roster - COMPLETE
- [x] Roster domain/read models (`RosterMember`, `RosterResult`).
- [x] Canonical `getRosterForSession(idBuoiHoc)` engine implementation.
- [x] Support for Single-shift (automatic) and Multi-shift (explicit) modes.
- [x] Integrity diagnostics (missing schedule, unassigned students, multiple assignments).
- [x] Historical integrity preserved (archived students/classes included).
- [x] Read-only Roster UI integrated into Session management.
- [x] Comprehensive Tests (116 tests passing).

## Phase 6: Attendance - COMPLETE
- [x] Database Migration (v6 -> v7) with canonical `diem_danh` table.
- [x] Attendance domain models and enums (CO_MAT, TRE, etc.).
- [x] Canonical `AttendanceService` built on top of `RosterService`.
- [x] Implementation of "Missing row = CHUA_DIEM_DANH" logic.
- [x] Atomic draft saving with SQLite transactions and strict validation.
- [x] Session finalization (DU_KIEN -> DA_HOC) with incomplete warnings and teacher override.
- [x] Status protection: DA_HOC sessions are immutable for generic status changes.
- [x] Bulk action "Mark All Present" and "Undo" support.
- [x] Mobile-friendly Attendance UI with ChoiceChips.
- [x] Comprehensive Tests (147 tests passing).

## Phase 7: Leave / Shift Change / Makeup - COMPLETE
- [x] Database Migration (v7 -> v8) with `don_nghi_hoc` and `dieu_chinh_buoi_hoc` tables.
- [x] Leave Request domain, repository, and service (`don_nghi_hoc`).
- [x] Session Adjustment domain, repository, and service (`dieu_chinh_buoi_hoc`).
- [x] Approved Leave suggestions integrated with `AttendanceService` without auto-persisting.
- [x] One-off Shift Changes (`DOI_CA`), Makeups (`HOC_BU`), and Ad-hoc participation (`PHAT_SINH`).
- [x] RosterService hardened as single canonical owner of final rosters with fail-closed integrity checks on read.
- [x] Session finalization API hardened with required `oneOffRosterResolved` parameter.
- [x] HOC_BU original session restricted to CHINH, with historical membership validation on original missed session date.
- [x] Cross-class HOC_BU and PHAT_SINH support in domain & presentation.
- [x] HOC_BU attendance state restrictions enforced (`CO_MAT` / `TRE` rejected for HOC_BU roster members).
- [x] Bulk action "Học bù hết" implemented for HOC_BU sessions.
- [x] Controller error propagation fixed (rethrow exceptions for UI error dialogs).
- [x] Live Attendance Sheet refresh after adjustment creation/removal.
- [x] Data safety & dirty draft protection: roster-changing actions (`Đổi ca`, `Thêm học sinh`, `Hủy điều chỉnh`) blocked if unsaved attendance changes exist.
- [x] `Xếp học bù` action restricted to finalized (`DA_HOC`) original sessions.
- [x] Mobile UI for Leave management and Session Adjustments with complete navigation entry points.
- [x] Comprehensive Tests (190 tests passing).

## Phase 8: Session Credit - COMPLETE
- [x] Forward Database Migration (v9 -> v10) with hardened reason-specific `CHECK` constraints on `buoi_du_ledger`.
- [x] Credit Ledger domain models (`CreditLedgerEntry`, `CreditLedgerReason`).
- [x] Canonical `SessionCreditService` as single owner of credit rules and balance calculations.
- [x] Monthly eligible CHINH session calculation using canonical `RosterService`.
- [x] Standard (1..12) vs Extra (13+) session indexing classification.
- [x] Extra session credit earning rules (`CO_MAT`/`TRE` -> +1, others -> 0).
- [x] Exclusion of `HOC_BU` and `PHAT_SINH` sessions from automatic extra credit earning.
- [x] Idempotent credit reconciliation (`reconcileEarnedCreditsForStudentClassMonth` & `reconcileEarnedCreditsForClassMonth` fail-closed atomic transaction).
- [x] Class-scoped credit balance derivation (`SUM(delta)` per student + class).
- [x] Historical month balance accuracy (`openingBalance`, `monthDelta`, `closingBalance` as-of month end).
- [x] Manual credit adjustment with mandatory reason note (`DIEU_CHINH_THU_CONG`).
- [x] Mobile-friendly Session Credit UI (`SessionCreditPage`) with active month selector and "Số dư cuối tháng" header label.
- [x] Comprehensive Tests (230 tests passing).

## Phase 9: Tuition Policy + Invoice - COMPLETE
- [x] Forward Database Migration (v10 -> v11) creating `chinh_sach_hoc_phi` and `hoc_phi_thang` tables with strict `CHECK` constraints, Foreign Keys, and partial UNIQUE indexes.
- [x] Tuition Policy domain, repository, service (`TuitionPolicyService`), and providers.
- [x] Standard session count `N` dynamically resolved from effective policy with fallback to `TuitionPolicyDefaults.standardSessionsPerMonth = 12`.
- [x] Single canonical ownership for N & credit candidates in `SessionCreditService`.
- [x] Canonical formula for `creditClosing` in `TuitionService` preventing double-counting of pre-reconciled ledger entries.
- [x] Month-boundary policy enforcement (`YYYY-MM-01` start, last day of month end).
- [x] Finite policies cannot overlap and truncate an existing open policy; open-policy continuity is preserved unconditionally.
- [x] Canonical finalized snapshot status definitions: `DA_CHOT`, `DA_THANH_TOAN`, `CON_NO` (`TuitionInvoiceStatusX.isFinalizedSnapshot`). `NHAP` is the only draft status.
- [x] Protection of existing credit ledger entries from retroactive $N$ policy changes.
- [x] Fail-closed strict makeup attendance validation (`_hasValidMakeupAttendance`).
- [x] Batch student lookup in `StudentRepository` (`getByIds`) eliminating N+1 query overhead.
- [x] Unique student class-month population (`getUniqueStudentIdsForClassMonth`) ensuring pause/rejoin students appear once.
- [x] Canonical `effectiveTuitionPolicyProvider` replacing duplicate UI filtering.
- [x] `TuitionPolicyController` managing policy creation and orchestrating live provider invalidation across previews and policies.
- [x] Complete UI provider invalidation across all student invoices & previews upon batch finalization.
- [x] Comprehensive Tests (249 tests passing).

## Phase 10: Payment + Debt - COMPLETE
- [x] Forward Database Migration (v11 -> v12) creating `thanh_toan` table with Foreign Keys (`ON DELETE RESTRICT`), `CHECK (so_tien > 0)`, `CHECK (phuong_thuc IN ('TIEN_MAT', 'CHUYEN_KHOAN', 'KHAC'))`, partial UNIQUE index on non-empty `ma_giao_dich`, and performance indexes.
- [x] Real v11 -> v12 database migration test on real SQLite file (`test/repository/migration_v11_v12_test.dart`) asserting data preservation and `ON DELETE RESTRICT` foreign key enforcement.
- [x] Payment domain models (`Payment`, `PaymentMethod`, `InvoicePaymentSummary`).
- [x] Single canonical owner `PaymentSettlementRules` for all payment & settlement status calculations (`NHAP` -> `DA_CHOT` -> `CON_NO` -> `DA_THANH_TOAN`).
- [x] Persistence in `PaymentRepository` with transaction-aware `InTxn` methods and `getPaymentsForInvoiceIds` batch lookups.
- [x] In-Transaction Command Execution (`PaymentService.recordPayment`).
- [x] Fail-closed integrity checks.
- [x] Snapshot Immutability.
- [x] Batch Read Model watched ONCE in `ClassTuitionTab`.
- [x] Live Provider Invalidation in `PaymentController`.
- [x] Comprehensive Tests (277 tests passing).

## Phase 11: Schedule Conflicts - COMPLETE
- [x] Phase 11A Core Schedule Conflict Engine: COMPLETE.
- [x] Phase 11B One-Off Schedule Conflict Integration: COMPLETE.
- [x] Phase 11C Schedule Conflict UI + Constraint UI Integration: COMPLETE.
- [x] Phase 11D Final Audit & Hardening: COMPLETE.
- [x] Forward Database Migration (v12 -> v13) creating `rang_buoc_lich_hoc_sinh` table.
- [x] Real v12 -> v13 database migration test on real SQLite file.
- [x] Single Canonical Owner `ScheduleConflictService`.
- [x] Consumer Refactoring & Double-Gate Protection.
- [x] Presentation & UI Integration.
- [x] Comprehensive Tests (379 tests passing).

## Phase 12: Reports - COMPLETE
- [x] Phase 12A Canonical Report Foundation + Report UI: COMPLETE.
- [x] Phase 12B PDF Export: COMPLETE.

## Phase 13A: Android App Foundation (Final Persistence Proof) - COMPLETE
- [x] CI SDK Compatibility Fix:
  - Configured Flutter version `3.47.5` in `.github/workflows/flutter_ci.yml` for both `build` and `android-integration-test` jobs (Dart ^3.12.0 compliant).
- [x] True Nested Global Navigation Matrix:
  - All 7 required nested operational screens (`StudentDetailPage`, `StudentFormPage`, `ClassDetailPage`, `ClassFormPage`, `AttendancePage`, `LeaveRequestPage`, `SessionCreditPage`) provide a leading `BackButton`, `GlobalMenuButton`, and `AppGlobalDrawer`.
  - Executable test matrix in `test/app/nested_pages_matrix_test.dart` (7/7 passing).
- [x] Dirty Form Global Navigation Safety:
  - `DirtyFormScope.isFormDirty(context)` and `AppPageScaffold.confirmCanLeave` guard global menu navigation.
  - Cancel keeps user on form; Discard closes nested route stack cleanly and switches destination.
  - Tested in `test/app/dirty_form_test.dart` (4/4 passing).
- [x] Fixed False Bottom Nav Selection:
  - Non-bottom secondary global pages (`Reports`, `Settings`) hide `NavigationBar`.
- [x] Fully Localized Shared UI & Tooltips:
  - Tooltip on `GlobalMenuButton` localized via `l10n.globalMenu`. Zero hardcoded bilingual branching.
- [x] Real ProviderScope & Application Widget-Tree Recreation Persistence Proof:
  - `integration_test/phase13a_android_smoke_test.dart` re-runs `app.main()` to recreate `ProviderScope` and application widget tree without setting provider state manually.
  - Asserts automatically reloaded state from `SharedPreferences` on disk: ThemeMode `Dark` (`brightness == Brightness.dark`), Emerald palette (`colorScheme.primary == Color(0xFF00875A)`), and English locale (`'Home'`, `'Classes'`, `'Students'`, `'Tuition'`).
- [x] Emulator Evidence Distinction:
  - **Local Emulator**: `emulator-5554` (`sdk gphone64 x86_64`), Android 13, API 33.
  - **Exact-SHA CI Emulator**: `reactivecircus/android-emulator-runner@v2`, Pixel 6, Android API 31.
- [x] Debug APK (`app-debug.apk`) built successfully (`build/app/outputs/flutter-apk/app-debug.apk`).

---

## Technical Details
- **Database**: `tuition_next.db`
- **Version**: 13
- **Flutter SDK**: `3.47.5`
- **State Management**: Riverpod (Generator used)
- **Navigation**: Centralized `AppDestination` + Riverpod `NavigationController` + `AppGlobalDrawer` + `AppPageScaffold`
- **Tests**: 447 tests passing (100% PASS)
- **Quality Gate**:
  - `dart format`: Passed (0 changed)
  - `flutter analyze`: Clean (0 errors, 0 warnings)
  - `flutter test`: 100% Pass (447 tests)
  - `flutter build apk --debug`: Passed (`app-debug.apk`)
  - `integration_test`: 100% Pass on Local Android Emulator (`emulator-5554`, API 33) and CI Emulator (API 31)
