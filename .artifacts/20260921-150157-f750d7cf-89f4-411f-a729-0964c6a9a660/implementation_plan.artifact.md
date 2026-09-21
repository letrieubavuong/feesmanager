# Phase 5 Implementation Plan: Canonical Session Roster

Implement the canonical roster engine `getRosterForSession(idBuoiHoc)` to determine the list of students for a specific session.

## User Review Required

- **Read-only Roster**: This phase focuses on the roster algorithm and a read-only UI. No attendance actions (e.g., marking present/absent) will be implemented.
- **Derived Data**: The roster is calculated on-the-fly and is not persisted in the database.
- **HOC_BU / PHAT_SINH**: Sessions of these types will show an empty roster for now, with a clear message that participants will be determined in a future phase.

## Proposed Changes

### Domain Layer (New Feature: Roster)

#### [NEW] [roster_member.dart](file:///C:/Lap%20trinh%20Android/Tuition2027/lib/features/roster/domain/roster_member.dart)
- Define `RosterInclusionSource` enum (SINGLE_SHIFT_MEMBERSHIP, EXPLICIT_ASSIGNMENT).
- Define `RosterMember` model containing `Student`, `ClassMembership`, `StudentShiftAssignment?`, and `RosterInclusionSource`.

#### [NEW] [roster_result.dart](file:///C:/Lap%20trinh%20Android/Tuition2027/lib/features/roster/domain/roster_result.dart)
- Define `RosterIssueCode` enum for diagnostics.
- Define `RosterIssue` class.
- Define `RosterResult` containing `ClassSession`, `List<RosterMember>`, `List<Student> unassignedMembers`, `List<RosterIssue>`, and flags `isOperationallyValid`, `requiresOneOffAdjustments`.

#### [NEW] [roster_service.dart](file:///C:/Lap%20trinh%20Android/Tuition2027/lib/features/roster/domain/roster_service.dart)
- Implement `RosterService` with `getRosterForSession(int sessionId)`.
- Use `SessionService`, `MembershipService`, `ScheduleDomainService`, and `StudentService`.
- Logic:
    1. Load session.
    2. Identify shift mode (Single vs Multi).
    3. Filter active memberships on session date.
    4. Apply assignments if Multi-shift.
    5. Detect integrity issues (e.g., missing schedule for CHINH, multiple assignments).
    6. Return deterministic sorted result (by student name).

---

### Presentation Layer

#### [NEW] [roster_controller.dart](file:///C:/Lap%20trinh%20Android/Tuition2027/lib/features/roster/presentation/roster_controller.dart)
- Riverpod provider for `sessionRosterProvider(sessionId)`.

#### [NEW] [session_roster_view.dart](file:///C:/Lap%20trinh%20Android/Tuition2027/lib/features/roster/presentation/session_roster_view.dart)
- Read-only UI to display the roster.
- Shows session info, participant list, unassigned warnings, and integrity errors.

#### [session_tab.dart](file:///C:/Lap%20trinh%20Android/Tuition2027/lib/features/sessions/presentation/session_tab.dart)
- Add action to open `SessionRosterView` for a session.

---

### Verification Plan

#### Automated Tests
- **Domain Tests**: `test/roster/roster_service_test.dart`
    - Test single-shift inclusion.
    - Test multi-shift splitting and unassigned students.
    - Test membership boundaries and pause/resume.
    - Test archived students/classes preservation.
    - Test integrity error detection (missing schedule, class mismatch).
    - Test HOC_BU/PHAT_SINH empty rosters.
    - Test read purity (no mutations).
- **Widget Tests**: `test/presentation/session_roster_ui_test.dart`
    - Test display of participants, source labels, and warnings.
    - Verify no attendance controls exist.

#### Manual Verification
- Navigate to a class with a single shift, open a session roster, and verify all active students are listed.
- Create a multi-shift class, assign students to different shifts, and verify the roster for each shift correctly filters students.
- Archive a student and verify they still appear in historical rosters.
- View the roster of an `HOC_BU` session and verify the explanatory message.
