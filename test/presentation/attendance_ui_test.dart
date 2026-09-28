import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuition2027/app/common_widgets/attendance_status_icon.dart';
import 'package:tuition2027/features/attendance/presentation/attendance_page.dart';
import 'package:tuition2027/features/attendance/presentation/attendance_controller.dart';
import 'package:tuition2027/features/attendance/presentation/widgets/attendance_state_selector.dart';
import 'package:tuition2027/features/attendance/domain/attendance_sheet.dart';
import 'package:tuition2027/features/attendance/domain/attendance_state.dart';
import 'package:tuition2027/features/attendance/domain/attendance_record.dart';
import 'package:tuition2027/features/sessions/domain/class_session.dart';
import 'package:tuition2027/features/students/domain/student.dart';
import 'package:tuition2027/features/memberships/domain/membership.dart';
import 'package:tuition2027/features/roster/domain/roster_member.dart';
import 'package:tuition2027/features/session_adjustments/domain/session_adjustment.dart';

import '../test_helper.dart';

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
    hoTen: 'Nguyễn Văn Học Sinh Dài Tên Rất Dài Để Kiểm Thử Layout',
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

  testWidgets(
    'AttendancePage AppBar has compact title Điểm danh and no drawer icon',
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

      await tester.pumpWidget(
        createTestApp(
          overrides: [
            attendanceControllerProvider(
              1,
            ).overrideWith(() => MockAttendanceController(sheet)),
          ],
          home: const AttendancePage(sessionId: 1),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Điểm danh'), findsOneWidget);
      expect(find.byIcon(Icons.menu), findsNothing);
    },
  );

  testWidgets(
    'Finalized DA_HOC session view shows check icon, edit icon, and NO text status pill',
    (tester) async {
      final daHocSession = testSession.copyWith(
        trangThai: SessionStatus.DA_HOC,
      );
      final sheet = AttendanceSheet(
        session: daHocSession,
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
        createTestApp(
          overrides: [
            attendanceControllerProvider(
              1,
            ).overrideWith(() => MockAttendanceController(sheet)),
          ],
          home: const AttendancePage(sessionId: 1),
        ),
      );
      await tester.pumpAndSettle();

      // Check AppBar edit icon and history icon
      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
      expect(find.byIcon(Icons.history), findsOneWidget);

      // Read-only attendance icon present
      expect(find.byType(AttendanceStatusIcon), findsOneWidget);
      expect(find.byIcon(Icons.check_rounded), findsAtLeast(1));

      // No editable selector
      expect(find.byType(AttendanceStateSelector), findsNothing);

      // No bottom action bar (null bottomNavigationBar)
      expect(find.text('Hoàn tất'), findsNothing);
    },
  );

  testWidgets(
    'DU_KIEN draft view shows AttendanceStateSelector and bulk action toolbar',
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

      await tester.pumpWidget(
        createTestApp(
          overrides: [
            attendanceControllerProvider(
              1,
            ).overrideWith(() => MockAttendanceController(sheet)),
          ],
          home: const AttendancePage(sessionId: 1),
        ),
      );
      await tester.pumpAndSettle();

      // Bulk toolbar actions
      expect(find.text('Có mặt hết'), findsOneWidget);

      // State selector widget present
      expect(find.byType(AttendanceStateSelector), findsOneWidget);

      // Verify 5 state icon buttons inside selector
      final selector = tester.widget<AttendanceStateSelector>(
        find.byType(AttendanceStateSelector),
      );
      expect(selector.allowedStates.length, 5);
      expect(selector.allowedStates, contains(AttendanceState.CHUA_DIEM_DANH));
      expect(selector.allowedStates, contains(AttendanceState.CO_MAT));
      expect(selector.allowedStates, contains(AttendanceState.TRE));
      expect(selector.allowedStates, contains(AttendanceState.NGHI_CO_PHEP));
      expect(selector.allowedStates, contains(AttendanceState.NGHI_KHONG_PHEP));
      expect(selector.allowedStates, isNot(contains(AttendanceState.HOC_BU)));

      // Bottom finalize bar present
      expect(find.text('Hoàn tất'), findsOneWidget);
    },
  );

  testWidgets(
    'Correction mode in DA_HOC session disables CHUA_DIEM_DANH state and shows bottom Save/Cancel',
    (tester) async {
      final daHocSession = testSession.copyWith(
        trangThai: SessionStatus.DA_HOC,
      );
      final sheet = AttendanceSheet(
        session: daHocSession,
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
        createTestApp(
          overrides: [
            attendanceControllerProvider(
              1,
            ).overrideWith(() => MockAttendanceController(sheet)),
          ],
          home: const AttendancePage(sessionId: 1),
        ),
      );
      await tester.pumpAndSettle();

      // Tap edit icon in AppBar to trigger correction dialog
      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();

      // Enter reason
      await tester.enterText(find.byType(TextField), 'Nhập nhầm học sinh');
      await tester.tap(find.text('Bắt đầu chỉnh sửa'));
      await tester.pumpAndSettle();

      // State selector is now shown
      expect(find.byType(AttendanceStateSelector), findsOneWidget);
      final selector = tester.widget<AttendanceStateSelector>(
        find.byType(AttendanceStateSelector),
      );
      expect(
        selector.allowedStates,
        isNot(contains(AttendanceState.CHUA_DIEM_DANH)),
      );
      expect(selector.allowedStates, contains(AttendanceState.CO_MAT));
      expect(selector.allowedStates, contains(AttendanceState.TRE));

      // Bottom bar has Save Correction and Cancel Correction
      expect(find.text('Lưu chỉnh sửa'), findsOneWidget);
      expect(find.text('Hủy chỉnh sửa'), findsOneWidget);
    },
  );

  testWidgets(
    'HOC_BU participant allows HOC_BU state and excludes CO_MAT/TRE',
    (tester) async {
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
        session: testSession,
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
        createTestApp(
          overrides: [
            attendanceControllerProvider(
              1,
            ).overrideWith(() => MockAttendanceController(sheet)),
          ],
          home: const AttendancePage(sessionId: 1),
        ),
      );
      await tester.pumpAndSettle();

      final selector = tester.widget<AttendanceStateSelector>(
        find.byType(AttendanceStateSelector),
      );
      expect(selector.allowedStates, contains(AttendanceState.HOC_BU));
      expect(selector.allowedStates, isNot(contains(AttendanceState.CO_MAT)));
      expect(selector.allowedStates, isNot(contains(AttendanceState.TRE)));
    },
  );

  testWidgets(
    '320px narrow device layout test renders student row without pixel overflow',
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

      // Set 320px width physical view size
      tester.view.physicalSize = const Size(320 * 2.0, 640 * 2.0);
      tester.view.devicePixelRatio = 2.0;

      await tester.pumpWidget(
        createTestApp(
          overrides: [
            attendanceControllerProvider(
              1,
            ).overrideWith(() => MockAttendanceController(sheet)),
          ],
          home: const AttendancePage(sessionId: 1),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AttendancePage), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Reset view size after test
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    },
  );

  testWidgets('Student row overflow menu shows roster actions when tapped', (
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
      createTestApp(
        overrides: [
          attendanceControllerProvider(
            1,
          ).overrideWith(() => MockAttendanceController(sheet)),
        ],
        home: const AttendancePage(sessionId: 1),
      ),
    );
    await tester.pumpAndSettle();

    // Tap overflow popup menu button (more_vert)
    await tester.tap(find.byIcon(Icons.more_vert_rounded));
    await tester.pumpAndSettle();

    // Menu options presented
    expect(find.text('Đổi ca'), findsOneWidget);
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
      createTestApp(
        overrides: [
          attendanceControllerProvider(
            1,
          ).overrideWith(() => MockAttendanceController(sheet)),
        ],
        home: const AttendancePage(sessionId: 1),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      sheet.isOperationallyValid,
      isTrue,
    ); // HUY session has no roster issues
    expect(sheet.session.trangThai, SessionStatus.HUY);
    expect(find.byType(AttendanceStateSelector), findsNothing);
  });

  test('AttendanceController draft state logic unit test', () async {
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

    expect(controller.hasDirtyDraft, isFalse);
    expect(controller.effectiveStateFor(101), AttendanceState.CHUA_DIEM_DANH);

    controller.updateLocalDraft(101, AttendanceState.CO_MAT);
    expect(controller.hasDirtyDraft, isTrue);
    expect(controller.effectiveStateFor(101), AttendanceState.CO_MAT);

    controller.undoChanges();
    expect(controller.hasDirtyDraft, isFalse);
    expect(controller.effectiveStateFor(101), AttendanceState.CHUA_DIEM_DANH);
  });
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
