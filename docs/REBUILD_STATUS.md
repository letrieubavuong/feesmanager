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
- [x] Database Migration (v1 -> v2)
- [x] Class canonical table and CRUD
- [x] Membership interval-based logic (no status fields)
- [x] Multiple classes per student support
- [x] Pause/Resume/Leave history
- [x] Blocking student archive if active in classes
- [x] Derived class size based on reference date
- [x] Class roster UI with membership management
- [x] Student detail UI with class history
- [x] Tests for migration, logic, and business rules

## Phase 3: Schedule + Session - NOT STARTED

---

## Technical Details
- **Database**: `tuition_next.db` (Version 1)
- **State Management**: Riverpod (Generator used)
- **Navigation**: Manual shell implementation (Responsive)
- **Tests**:
  - `test/unit/phone_normalizer_test.dart`
  - `test/repository/student_repository_test.dart`
- **Quality Gate**:
  - `dart analyze`: Clean (except deprecated generated code and minor lint warnings)
  - `flutter test`: 100% Pass
