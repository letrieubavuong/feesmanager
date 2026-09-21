# Phase 4 Implementation Plan: Session Generation

Implement canonical `buoi_hoc` table, `SessionGenerationService`, and basic session management UI. This allows converting recurring schedules (`lich_hoc`) into actual dated sessions (`buoi_hoc`).

## User Review Required

- **Database Upgrade**: Migration from v5 to v6 will add the `buoi_hoc` table.
- **Generation Logic**: Sessions are generated for a specific date range. If a session already exists (same class, date, and start time), it will not be overwritten, preserving its status (e.g., `HUY`, `NGHI_LE`).
- **UI Changes**: A new "Buổi học" tab will be added to the Class Detail page. The placeholder "Điểm danh" remains as a placeholder or can be replaced if requested, but no attendance logic will be implemented in this phase.

## Proposed Changes

### Database & Migration

#### [app_database.dart](file:///C:/Lap%20trinh%20Android/Tuition2027/lib/core/database/app_database.dart)
- Increment `_dbVersion` to 6.
- Add `_migrateV5ToV6` to create `buoi_hoc` table with constraints and indexes.
- Update `_onCreate` to include v6 migration.

---

### Sessions Feature (New)

#### [NEW] [class_session.dart](file:///C:/Lap%20trinh%20Android/Tuition2027/lib/features/sessions/domain/class_session.dart)
- Define `SessionType` (CHINH, HOC_BU, PHAT_SINH) and `SessionStatus` (DU_KIEN, DA_HOC, HUY, NGHI_LE).
- Define `ClassSession` domain model mapping to `buoi_hoc` table.

#### [NEW] [session_repository.dart](file:///C:/Lap%20trinh%20Android/Tuition2027/lib/features/sessions/data/session_repository.dart)
- CRUD operations for `buoi_hoc`.
- Query methods: `getByClassAndDateRange`, `findByClassDateStart`, etc.

#### [NEW] [session_service.dart](file:///C:/Lap%20trinh%20Android/Tuition2027/lib/features/sessions/domain/session_service.dart)
- Orchestrate session logic (manual creation, status update).
- Validate class archive status before creating new sessions.

#### [NEW] [session_generation_service.dart](file:///C:/Lap%20trinh%20Android/Tuition2027/lib/features/sessions/domain/session_generation_service.dart)
- Implement `generateForClass` logic.
- Ensure idempotency (no duplicates, preserve existing status).
- Handle schedule effective dates and multiple shifts.

#### [NEW] [session_controller.dart](file:///C:/Lap%20trinh%20Android/Tuition2027/lib/features/sessions/presentation/session_controller.dart)
- Riverpod controllers for session list and actions (generate, manual create, cancel).

#### [NEW] [session_tab.dart](file:///C:/Lap%20trinh%20Android/Tuition2027/lib/features/sessions/presentation/session_tab.dart)
- Functional tab in Class Detail.
- List sessions with date, time, type, and status.
- Actions: Generate, Add manual, Mark Cancel/Holiday.

---

### Integration

#### [class_detail_page.dart](file:///C:/Lap%20trinh%20Android/Tuition2027/lib/features/classes/presentation/class_detail_page.dart)
- Add "Buổi học" tab.
- Integrate `SessionTab`.

## Verification Plan

### Automated Tests
- **Migration**: `test/repository/migration_v5_v6_test.dart` (New)
- **Generation Logic**: `test/sessions/session_generation_service_test.dart` (New)
    - Test idempotency, schedule boundaries, multiple shifts.
    - Test status preservation.
- **Domain/Service**: `test/sessions/session_service_test.dart` (New)
    - Manual creation rules, archive block.
- **Widget Tests**: `test/presentation/sessions_ui_test.dart` (New)
    - Test list display, dialog interaction, and summary display.

### Manual Verification
- In Class Detail, open "Buổi học" tab.
- Click "Sinh buổi học", select a range, and verify results.
- Verify that running generation again for the same range doesn't create duplicates.
- Manually create a "HỌC BÙ" session.
- Mark a session as "HỦY" and verify it's preserved after re-running generation.
