import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuition2027/features/attendance/presentation/attendance_page.dart';
import 'package:tuition2027/features/attendance/presentation/attendance_controller.dart';
import 'package:tuition2027/features/attendance/domain/attendance_sheet.dart';
import 'package:tuition2027/features/attendance/domain/attendance_state.dart';
import 'package:tuition2027/features/attendance/domain/attendance_record.dart';
import 'package:tuition2027/features/sessions/domain/class_session.dart';
import 'package:tuition2027/features/students/domain/student.dart';
import 'package:tuition2027/features/memberships/domain/membership.dart';
import 'package:tuition2027/features/roster/domain/roster_member.dart';
import 'package:tuition2027/features/roster/domain/roster_result.dart';
import 'package:tuition2027/features/session_adjustments/domain/session_adjustment.dart';
import 'package:tuition2027/features/sessions/presentation/session_tab.dart';
import 'package:tuition2027/features/sessions/presentation/session_controller.dart';

void main() {
  final now = DateTime.now();
  final testSession = ClassSession(
    id: 1,
    idLop: 1,
    ngay: '2026-09-21',
    gioBatDau: '17:30',
    gioKetThuc: '19:00',
    loai: SessionType.CHINH,
    trangThai: SessionStatus.DU_KIEN,
    createdAt: now,
    updatedAt: now,
  );

  final testStudent = Student(
    id: 101,
    hoTen: 'Test Student',
    createdAt: now,
    updatedAt: now,
  );

  final testMembership = ClassMembership(
    idHocSinh: 101,
    idLop: 1,
    tuNgay: '2026-01-01',
    createdAt: now,
    updatedAt: now,
  );

  final testRosterMember = RosterMember(
    student: testStudent,
    membership: testMembership,
    source: RosterInclusionSource.SINGLE_SHIFT_MEMBERSHIP,
  );

  testWidgets('AttendancePage shows roster students and supports marking', (
    tester,
  ) async {
    final sheet = AttendanceSheet(
      session: testSession,
      members: [
        AttendanceSheetMember(
          rosterMember: testRosterMember,
          state: AttendanceState.CHUA_DIEM_DANH,
        ),
      ],
      issues: [],
      isRosterValid: true,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          attendanceControllerProvider(
            1,
          ).overrideWith(() => MockAttendanceController(sheet)),
        ],
        child: const MaterialApp(home: AttendancePage(sessionId: 1)),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Test Student'), findsOneWidget);
    expect(find.text('Chưa điểm danh'), findsAtLeast(1));

    // Verify NO HOC_BU ChoiceChip
    expect(find.widgetWithText(ChoiceChip, 'Học bù'), findsNothing);

    // Mark as CO_MAT (using ChoiceChip)
    await tester.tap(find.text('Có mặt'));
    await tester.pumpAndSettle();

    // Verify draft state change in UI (Chip selection)
    final choiceChip = tester.widget<ChoiceChip>(
      find.ancestor(of: find.text('Có mặt'), matching: find.byType(ChoiceChip)),
    );
    expect(choiceChip.selected, isTrue);
  });

  testWidgets('AttendancePage bulk Mark All Present and Undo', (tester) async {
    final sheet = AttendanceSheet(
      session: testSession,
      members: [
        AttendanceSheetMember(
          rosterMember: testRosterMember,
          state: AttendanceState.CHUA_DIEM_DANH,
        ),
      ],
      issues: [],
      isRosterValid: true,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          attendanceControllerProvider(
            1,
          ).overrideWith(() => MockAttendanceController(sheet)),
        ],
        child: const MaterialApp(home: AttendancePage(sessionId: 1)),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.text('Có mặt hết'));
    await tester.pumpAndSettle();

    var choiceChip = tester.widget<ChoiceChip>(
      find.ancestor(of: find.text('Có mặt'), matching: find.byType(ChoiceChip)),
    );
    expect(choiceChip.selected, isTrue);

    // Undo
    await tester.tap(find.byIcon(Icons.undo));
    await tester.pumpAndSettle();

    choiceChip = tester.widget<ChoiceChip>(
      find.ancestor(of: find.text('Có mặt'), matching: find.byType(ChoiceChip)),
    );
    expect(choiceChip.selected, isFalse);
  });

  testWidgets('AttendancePage blocks editing for HUY session', (tester) async {
    final huySession = testSession.copyWith(trangThai: SessionStatus.HUY);
    final sheet = AttendanceSheet(
      session: huySession,
      members: [
        AttendanceSheetMember(
          rosterMember: testRosterMember,
          state: AttendanceState.CHUA_DIEM_DANH,
        ),
      ],
      issues: [],
      isRosterValid: true,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          attendanceControllerProvider(
            1,
          ).overrideWith(() => MockAttendanceController(sheet)),
        ],
        child: const MaterialApp(home: AttendancePage(sessionId: 1)),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.textContaining('HUY'), findsOneWidget);
    expect(find.textContaining('Không thể chỉnh sửa'), findsOneWidget);
    expect(find.byType(ChoiceChip), findsNothing);
  });

  testWidgets('AttendancePage blocks editing for NGHI_LE session', (
    tester,
  ) async {
    final nghiLeSession = testSession.copyWith(
      trangThai: SessionStatus.NGHI_LE,
    );
    final sheet = AttendanceSheet(
      session: nghiLeSession,
      members: [
        AttendanceSheetMember(
          rosterMember: testRosterMember,
          state: AttendanceState.CHUA_DIEM_DANH,
        ),
      ],
      issues: [],
      isRosterValid: true,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          attendanceControllerProvider(
            1,
          ).overrideWith(() => MockAttendanceController(sheet)),
        ],
        child: const MaterialApp(home: AttendancePage(sessionId: 1)),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.textContaining('NGHI_LE'), findsOneWidget);
    expect(find.textContaining('Không thể chỉnh sửa'), findsOneWidget);
    expect(find.byType(ChoiceChip), findsNothing);
  });

  testWidgets('AttendancePage blocks editing for HOC_BU session', (
    tester,
  ) async {
    final hbSession = testSession.copyWith(loai: SessionType.HOC_BU);
    final sheet = AttendanceSheet(
      session: hbSession,
      members: [],
      issues: [],
      isRosterValid: true,
      requiresOneOffAdjustments: true,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          attendanceControllerProvider(
            1,
          ).overrideWith(() => MockAttendanceController(sheet)),
        ],
        child: const MaterialApp(home: AttendancePage(sessionId: 1)),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.textContaining('Buổi học bù'), findsOneWidget);
    expect(find.byType(ChoiceChip), findsNothing);
  });

  testWidgets('AttendancePage blocks editing for PHAT_SINH session', (
    tester,
  ) async {
    final psSession = testSession.copyWith(loai: SessionType.PHAT_SINH);
    final sheet = AttendanceSheet(
      session: psSession,
      members: [],
      issues: [],
      isRosterValid: true,
      requiresOneOffAdjustments: true,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          attendanceControllerProvider(
            1,
          ).overrideWith(() => MockAttendanceController(sheet)),
        ],
        child: const MaterialApp(home: AttendancePage(sessionId: 1)),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.textContaining('chưa có danh sách tham gia'), findsOneWidget);
    expect(find.byType(ChoiceChip), findsNothing);
  });

  testWidgets('AttendancePage shows error dialog on save failure', (
    tester,
  ) async {
    final sheet = AttendanceSheet(
      session: testSession,
      members: [
        AttendanceSheetMember(
          rosterMember: testRosterMember,
          state: AttendanceState.CHUA_DIEM_DANH,
        ),
      ],
      issues: [],
      isRosterValid: true,
    );

    final controller = MockAttendanceController(sheet, failSave: true);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          attendanceControllerProvider(1).overrideWith(() => controller),
        ],
        child: const MaterialApp(home: AttendancePage(sessionId: 1)),
      ),
    );

    await tester.pumpAndSettle();

    // Tap to create a draft
    await tester.tap(find.text('Có mặt'));
    await tester.pumpAndSettle();

    // Save
    await tester.tap(find.text('Lưu nháp'));
    await tester.pump(); // Start save
    await tester.pumpAndSettle();

    // Verify error dialog
    expect(find.text('Lỗi'), findsOneWidget);
    expect(find.textContaining('Save failed'), findsAtLeast(1));

    // Verify success snackbar NOT shown
    expect(find.text('Đã lưu dữ liệu điểm danh'), findsNothing);
  });

  testWidgets('AttendancePage blocks editing for DA_HOC session', (
    tester,
  ) async {
    final finalizedSession = testSession.copyWith(
      trangThai: SessionStatus.DA_HOC,
    );
    final sheet = AttendanceSheet(
      session: finalizedSession,
      members: [
        AttendanceSheetMember(
          rosterMember: testRosterMember,
          state: AttendanceState.CO_MAT,
        ),
      ],
      issues: [],
      isRosterValid: true,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          attendanceControllerProvider(
            1,
          ).overrideWith(() => MockAttendanceController(sheet)),
        ],
        child: const MaterialApp(home: AttendancePage(sessionId: 1)),
      ),
    );

    await tester.pumpAndSettle();

    // No editable controls (ChoiceChips)
    expect(find.byType(ChoiceChip), findsNothing);
    // Static status text visible
    expect(find.textContaining('Trạng thái: Có mặt'), findsOneWidget);
  });

  testWidgets(
    'AttendancePage displays roster issue detail and blocks editing',
    (tester) async {
      final sheet = AttendanceSheet(
        session: testSession,
        members: [
          AttendanceSheetMember(
            rosterMember: testRosterMember,
            state: AttendanceState.CHUA_DIEM_DANH,
          ),
        ],
        issues: [],
        isRosterValid: false,
        rosterIssues: [
          const RosterIssue(
            code: RosterIssueCode.SESSION_SCHEDULE_NOT_EFFECTIVE,
            message: 'Lịch học gốc không còn hiệu lực tại ngày của buổi học.',
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            attendanceControllerProvider(
              1,
            ).overrideWith(() => MockAttendanceController(sheet)),
          ],
          child: const MaterialApp(home: AttendancePage(sessionId: 1)),
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.text('Lịch học gốc không còn hiệu lực tại ngày của buổi học.'),
        findsOneWidget,
      );
      expect(find.byType(ChoiceChip), findsNothing);
    },
  );

  testWidgets(
    'AttendancePage displays ATTENDANCE_OUTSIDE_ROSTER issue and blocks editing',
    (tester) async {
      final sheet = AttendanceSheet(
        session: testSession,
        members: [
          AttendanceSheetMember(
            rosterMember: testRosterMember,
            state: AttendanceState.CHUA_DIEM_DANH,
          ),
        ],
        issues: [
          const AttendanceSheetIssue(
            code: AttendanceSheetIssueCode.ATTENDANCE_OUTSIDE_ROSTER,
            message:
                'Học sinh (ID: 999) có dữ liệu điểm danh nhưng không thuộc danh sách lớp buổi này.',
          ),
        ],
        isRosterValid: true,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            attendanceControllerProvider(
              1,
            ).overrideWith(() => MockAttendanceController(sheet)),
          ],
          child: const MaterialApp(home: AttendancePage(sessionId: 1)),
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.textContaining('Học sinh (ID: 999) có dữ liệu điểm danh'),
        findsOneWidget,
      );
      expect(find.byType(ChoiceChip), findsNothing);
    },
  );

  testWidgets(
    'AttendancePage incomplete warning dialog cancel and override paths',
    (tester) async {
      final sheet = AttendanceSheet(
        session: testSession,
        members: [
          AttendanceSheetMember(
            rosterMember: testRosterMember,
            state: AttendanceState.CHUA_DIEM_DANH,
          ),
        ],
        issues: [],
        isRosterValid: true,
      );

      final controller = MockAttendanceController(sheet);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            attendanceControllerProvider(1).overrideWith(() => controller),
          ],
          child: const MaterialApp(home: AttendancePage(sessionId: 1)),
        ),
      );

      await tester.pumpAndSettle();

      // Tap Finalize button
      await tester.tap(find.text('Hoàn tất'));
      await tester.pumpAndSettle();

      // Dialog appears
      expect(find.text('Chưa điểm danh hết'), findsOneWidget);

      // Cancel path
      await tester.tap(find.text('Hủy'));
      await tester.pumpAndSettle();

      expect(controller.finalizeCalls, 0);

      // Tap Finalize button again
      await tester.tap(find.text('Hoàn tất'));
      await tester.pumpAndSettle();

      // Override path
      await tester.tap(find.text('Vẫn hoàn tất'));
      await tester.pumpAndSettle();

      expect(controller.finalizeCalls, 1);
      expect(controller.lastAllowIncomplete, isTrue);
    },
  );

  testWidgets('AttendancePage shows error dialog on finalize failure', (
    tester,
  ) async {
    final sheet = AttendanceSheet(
      session: testSession,
      members: [
        AttendanceSheetMember(
          rosterMember: testRosterMember,
          state: AttendanceState.CO_MAT,
        ),
      ],
      issues: [],
      isRosterValid: true,
    );

    final controller = MockAttendanceController(sheet, failFinalize: true);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          attendanceControllerProvider(1).overrideWith(() => controller),
        ],
        child: const MaterialApp(home: AttendancePage(sessionId: 1)),
      ),
    );

    await tester.pumpAndSettle();

    // Tap Finalize
    await tester.tap(find.text('Hoàn tất'));
    await tester.pumpAndSettle();

    // Confirm dialog
    await tester.tap(find.text('Xác nhận'));
    await tester.pumpAndSettle();

    // Verify error dialog shown
    expect(find.text('Lỗi'), findsOneWidget);
    expect(find.textContaining('Finalize failed'), findsAtLeast(1));

    // Verify success snackbar NOT shown
    expect(find.text('Đã hoàn tất buổi học'), findsNothing);
  });

  testWidgets('SessionTab popup menu for DA_HOC session is absent', (
    tester,
  ) async {
    final daHocSession = testSession.copyWith(trangThai: SessionStatus.DA_HOC);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          classSessionControllerProvider(
            1,
          ).overrideWith(() => MockSessionController([daHocSession])),
        ],
        child: const MaterialApp(home: SessionTab(classId: 1)),
      ),
    );

    await tester.pumpAndSettle();

    // PopupMenuButton should NOT be rendered for DA_HOC session
    expect(find.byType(PopupMenuButton<SessionStatus>), findsNothing);
  });

  test('AttendanceController dirty draft state regression', () async {
    final sheet = AttendanceSheet(
      session: testSession,
      members: [
        AttendanceSheetMember(
          rosterMember: testRosterMember,
          state: AttendanceState.CHUA_DIEM_DANH,
        ),
      ],
      issues: [],
      isRosterValid: true,
    );

    final container = ProviderContainer(
      overrides: [
        attendanceControllerProvider(
          1,
        ).overrideWith(() => MockAttendanceController(sheet)),
      ],
    );
    addTearDown(container.dispose);

    final controller = container.read(attendanceControllerProvider(1).notifier);
    await container.read(attendanceControllerProvider(1).future);

    // 1. Immediately after load
    expect(controller.hasDirtyDraft, isFalse);

    // 2. Read effective state
    final eff = controller.effectiveStateFor(101);
    expect(eff, AttendanceState.CHUA_DIEM_DANH);
    expect(controller.hasDirtyDraft, isFalse);

    // 3. updateLocalDraft
    controller.updateLocalDraft(101, AttendanceState.CO_MAT);
    expect(controller.hasDirtyDraft, isTrue);
    expect(controller.effectiveStateFor(101), AttendanceState.CO_MAT);

    // 4. undoChanges
    controller.undoChanges();
    expect(controller.hasDirtyDraft, isFalse);
    expect(controller.effectiveStateFor(101), AttendanceState.CHUA_DIEM_DANH);
  });

  testWidgets('Xếp học bù button hidden on DU_KIEN session', (tester) async {
    final duKienSession = testSession.copyWith(
      trangThai: SessionStatus.DU_KIEN,
    );
    final sheetDuKien = AttendanceSheet(
      session: duKienSession,
      members: [
        AttendanceSheetMember(
          rosterMember: testRosterMember,
          state: AttendanceState.NGHI_CO_PHEP,
        ),
      ],
      issues: [],
      isRosterValid: true,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          attendanceControllerProvider(
            1,
          ).overrideWith(() => MockAttendanceController(sheetDuKien)),
        ],
        child: const MaterialApp(home: AttendancePage(sessionId: 1)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Xếp học bù'), findsNothing);
  });

  testWidgets('Xếp học bù button visible on DA_HOC session', (tester) async {
    final daHocSession = testSession.copyWith(trangThai: SessionStatus.DA_HOC);
    final sheetDaHoc = AttendanceSheet(
      session: daHocSession,
      members: [
        AttendanceSheetMember(
          rosterMember: testRosterMember,
          state: AttendanceState.NGHI_CO_PHEP,
        ),
      ],
      issues: [],
      isRosterValid: true,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          attendanceControllerProvider(
            2,
          ).overrideWith(() => MockAttendanceController(sheetDaHoc)),
        ],
        child: const MaterialApp(home: AttendancePage(sessionId: 2)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Xếp học bù'), findsOneWidget);
  });

  testWidgets('Đổi ca button hidden when persistedRecord exists', (
    tester,
  ) async {
    final sheet = AttendanceSheet(
      session: testSession,
      members: [
        AttendanceSheetMember(
          rosterMember: testRosterMember,
          state: AttendanceState.CO_MAT,
          persistedRecord: AttendanceRecord(
            idBuoiHoc: 1,
            idHocSinh: 101,
            idLopGoc: 1,
            trangThai: AttendanceStatus.CO_MAT,
            loaiThamGia: AttendanceParticipationType.CHINH,
            createdAt: now,
            updatedAt: now,
          ),
        ),
      ],
      issues: [],
      isRosterValid: true,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          attendanceControllerProvider(
            1,
          ).overrideWith(() => MockAttendanceController(sheet)),
        ],
        child: const MaterialApp(home: AttendancePage(sessionId: 1)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Đổi ca'), findsNothing);
  });

  testWidgets(
    'Dirty draft blocks roster changing actions (Đổi ca, Thêm học sinh)',
    (tester) async {
      final sheet = AttendanceSheet(
        session: testSession,
        members: [
          AttendanceSheetMember(
            rosterMember: testRosterMember,
            state: AttendanceState.CHUA_DIEM_DANH,
          ),
        ],
        issues: [],
        isRosterValid: true,
      );

      final controller = MockAttendanceController(sheet);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            attendanceControllerProvider(1).overrideWith(() => controller),
          ],
          child: const MaterialApp(home: AttendancePage(sessionId: 1)),
        ),
      );
      await tester.pumpAndSettle();

      // Create a dirty draft by tapping "Có mặt"
      await tester.tap(find.text('Có mặt'));
      await tester.pumpAndSettle();
      expect(controller.hasDirtyDraft, isTrue);

      // Tap "Đổi ca" button
      await tester.tap(find.text('Đổi ca'));
      await tester.pumpAndSettle();

      // Verify blocking warning dialog appears
      expect(find.text('Có thay đổi điểm danh chưa lưu'), findsOneWidget);
      expect(
        find.textContaining('Vui lòng Lưu nháp hoặc Hoàn tác'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'HOC_BU session shows Học bù hết bulk action and HOC_BU choice chips',
    (tester) async {
      final hbSession = testSession.copyWith(loai: SessionType.HOC_BU);
      final hbRosterMember = RosterMember(
        student: testStudent,
        membership: testMembership,
        adjustment: SessionAdjustment(
          id: 1,
          idHocSinh: 101,
          idLopGoc: 1,
          idBuoiHocThamGia: 1,
          loai: SessionAdjustmentType.HOC_BU,
          createdAt: now,
        ),
        source: RosterInclusionSource.HOC_BU,
      );

      final sheet = AttendanceSheet(
        session: hbSession,
        members: [
          AttendanceSheetMember(
            rosterMember: hbRosterMember,
            state: AttendanceState.CHUA_DIEM_DANH,
          ),
        ],
        issues: [],
        isRosterValid: true,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            attendanceControllerProvider(
              1,
            ).overrideWith(() => MockAttendanceController(sheet)),
          ],
          child: const MaterialApp(home: AttendancePage(sessionId: 1)),
        ),
      );
      await tester.pumpAndSettle();

      // Verify "Học bù hết" button is present and "Có mặt hết" is absent
      expect(find.text('Học bù hết'), findsOneWidget);
      expect(find.text('Có mặt hết'), findsNothing);

      // Verify Choice Chips: "Học bù", "Nghỉ có phép", "Nghỉ không phép" present
      expect(find.widgetWithText(ChoiceChip, 'Học bù'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'Nghỉ có phép'), findsOneWidget);
      expect(
        find.widgetWithText(ChoiceChip, 'Nghỉ không phép'),
        findsOneWidget,
      );

      // Verify Choice Chips: "Có mặt", "Trễ" ABSENT
      expect(find.widgetWithText(ChoiceChip, 'Có mặt'), findsNothing);
      expect(find.widgetWithText(ChoiceChip, 'Trễ'), findsNothing);
    },
  );

  testWidgets(
    'DOI_CA participant shows normal Choice Chips without Học bù chip',
    (tester) async {
      final doiCaMember = RosterMember(
        student: testStudent,
        membership: testMembership,
        adjustment: SessionAdjustment(
          id: 1,
          idHocSinh: 101,
          idLopGoc: 1,
          idBuoiHocThamGia: 1,
          loai: SessionAdjustmentType.DOI_CA,
          createdAt: now,
        ),
        source: RosterInclusionSource.DOI_CA,
      );

      final sheet = AttendanceSheet(
        session: testSession,
        members: [
          AttendanceSheetMember(
            rosterMember: doiCaMember,
            state: AttendanceState.CHUA_DIEM_DANH,
          ),
        ],
        issues: [],
        isRosterValid: true,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            attendanceControllerProvider(
              1,
            ).overrideWith(() => MockAttendanceController(sheet)),
          ],
          child: const MaterialApp(home: AttendancePage(sessionId: 1)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.widgetWithText(ChoiceChip, 'Có mặt'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'Trễ'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'Học bù'), findsNothing);
    },
  );

  testWidgets(
    'PHAT_SINH participant shows normal Choice Chips without Học bù chip',
    (tester) async {
      final psSession = testSession.copyWith(loai: SessionType.PHAT_SINH);
      final psMember = RosterMember(
        student: testStudent,
        membership: testMembership,
        adjustment: SessionAdjustment(
          id: 1,
          idHocSinh: 101,
          idLopGoc: 1,
          idBuoiHocThamGia: 1,
          loai: SessionAdjustmentType.PHAT_SINH,
          createdAt: now,
        ),
        source: RosterInclusionSource.PHAT_SINH,
      );

      final sheet = AttendanceSheet(
        session: psSession,
        members: [
          AttendanceSheetMember(
            rosterMember: psMember,
            state: AttendanceState.CHUA_DIEM_DANH,
          ),
        ],
        issues: [],
        isRosterValid: true,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            attendanceControllerProvider(
              1,
            ).overrideWith(() => MockAttendanceController(sheet)),
          ],
          child: const MaterialApp(home: AttendancePage(sessionId: 1)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.widgetWithText(ChoiceChip, 'Có mặt'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'Trễ'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'Học bù'), findsNothing);
    },
  );
}

class MockAttendanceController extends AttendanceController {
  final AttendanceSheet initialSheet;
  final bool failSave;
  final bool failFinalize;
  int finalizeCalls = 0;
  bool? lastAllowIncomplete;

  MockAttendanceController(
    this.initialSheet, {
    this.failSave = false,
    this.failFinalize = false,
  });

  @override
  FutureOr<AttendanceSheet> build(int sessionId) => initialSheet;

  @override
  Future<void> save() async {
    if (failSave) {
      state = AsyncError(Exception('Save failed'), StackTrace.current);
      throw Exception('Save failed');
    }
    return super.save();
  }

  @override
  Future<void> finalize({bool allowIncomplete = false}) async {
    finalizeCalls++;
    lastAllowIncomplete = allowIncomplete;
    if (failFinalize) {
      state = AsyncError(Exception('Finalize failed'), StackTrace.current);
      throw Exception('Finalize failed');
    }
    return super.finalize(allowIncomplete: allowIncomplete);
  }
}

class MockSessionController extends ClassSessionController {
  final List<ClassSession> data;
  MockSessionController(this.data);

  @override
  FutureOr<List<ClassSession>> build(int classId) => data;
}
