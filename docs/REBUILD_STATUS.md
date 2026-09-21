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
- [x] Comprehensive Tests:
    - `test/schedule/schedule_service_test.dart`
    - `test/schedule/assignment_service_test.dart`
    - `test/repository/real_migration_test.dart`
    - `test/presentation/schedule_assignment_ui_test.dart`
- [x] Quality Gate: 54 tests passing.

## Phase 4: Session Generation - COMPLETE
- [x] Database Migration (v5 -> v6) with canonical `buoi_hoc` table.
- [x] Idempotent session generation from recurring schedules.
- [x] Time snapshotting (Preserve historical session times if schedule changes).
- [x] Manual session creation (Học bù, Phát sinh) with strict validation.
- [x] Status management (Dự kiến, Hủy, Nghỉ lễ) with confirmation.
- [x] Class Detail UI integration with "Buổi học" tab and range filter.
- [x] Canonical session identity/conflict protection by class + date + start time.
- [x] Comprehensive Tests (88 tests passing):
    - `test/sessions/session_generation_service_test.dart`
    - `test/sessions/session_service_test.dart`
    - `test/presentation/sessions_ui_test.dart`
    - `test/repository/migration_v5_v6_test.dart`

## Phase 5: Canonical Session Roster - COMPLETE
- [x] Roster domain/read models (`RosterMember`, `RosterResult`).
- [x] Canonical `getRosterForSession(idBuoiHoc)` engine implementation.
- [x] Support for Single-shift (automatic) and Multi-shift (explicit) modes.
- [x] Integrity diagnostics (missing schedule, unassigned students, multiple assignments).
- [x] Historical integrity preserved (archived students/classes included).
- [x] Read-only Roster UI integrated into Session management.
- [x] Comprehensive Tests (116 tests passing):
    - `test/roster/roster_service_test.dart`
    - `test/presentation/session_roster_ui_test.dart`
    - `test/roster/integrity_corrupted_data_test.dart`

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
- [x] Comprehensive Tests (147 tests passing):
    - `test/attendance/attendance_service_test.dart`
    - `test/presentation/attendance_ui_test.dart`
    - `test/repository/migration_v6_v7_test.dart`

## Phase 7: Leave / Shift Change / Makeup - COMPLETE
- [x] Database Migration (v7 -> v8) with `don_nghi_hoc` and `dieu_chinh_buoi_hoc` tables.
- [x] Leave Request domain, repository, and service (`don_nghi_hoc`).
- [x] Session Adjustment domain, repository, and service (`dieu_chinh_buoi_hoc`).
- [x] Approved Leave suggestions integrated with `AttendanceService` without auto-persisting.
- [x] One-off Shift Changes (`DOI_CA`), Makeups (`HOC_BU`), and Ad-hoc participation (`PHAT_SINH`).
- [x] RosterService integrated as single canonical owner of final rosters.
- [x] Recurring assignments (`phan_ca_hoc_sinh`) strictly preserved and unmutated by adjustments.
- [x] Mobile UI for Leave management and Session Adjustments.
- [x] Comprehensive Tests (161 tests passing):
    - `test/leave/leave_request_service_test.dart`
    - `test/session_adjustments/session_adjustment_service_test.dart`
    - `test/presentation/phase7_ui_test.dart`
    - `test/repository/migration_v7_v8_test.dart`

## Phase 8: Session Credit - NOT STARTED

---

## Technical Details
- **Database**: `tuition_next.db`
- **Version**: 8
- **State Management**: Riverpod (Generator used)
- **Navigation**: Manual shell implementation (Responsive)
- **Tests**:
  - `test/unit/phone_normalizer_test.dart`
  - `test/repository/student_repository_test.dart`
  - `test/repository/membership_logic_test.dart`
  - `test/schedule/schedule_service_test.dart`
  - `test/schedule/assignment_service_test.dart`
  - `test/repository/real_migration_test.dart`
  - `test/presentation/schedule_assignment_ui_test.dart`
  - `test/sessions/session_generation_service_test.dart`
  - `test/sessions/session_service_test.dart`
  - `test/presentation/sessions_ui_test.dart`
  - `test/roster/roster_service_test.dart`
  - `test/presentation/session_roster_ui_test.dart`
  - `test/roster/integrity_corrupted_data_test.dart`
  - `test/attendance/attendance_service_test.dart`
  - `test/presentation/attendance_ui_test.dart`
  - `test/leave/leave_request_service_test.dart`
  - `test/session_adjustments/session_adjustment_service_test.dart`
  - `test/presentation/phase7_ui_test.dart`
  - `test/repository/migration_v5_v6_test.dart`
  - `test/repository/migration_v6_v7_test.dart`
  - `test/repository/migration_v7_v8_test.dart`
- **Quality Gate**:
  - `dart analyze`: Clean (No issues found!)
  - `flutter test`: 100% Pass (161 tests)
