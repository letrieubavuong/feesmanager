import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuition2027/features/attendance/presentation/attendance_page.dart';
import 'package:tuition2027/features/attendance/presentation/attendance_controller.dart';
import 'package:tuition2027/features/attendance/domain/attendance_sheet.dart';
import 'package:tuition2027/features/attendance/domain/attendance_state.dart';
import 'package:tuition2027/features/sessions/domain/class_session.dart';
import 'package:tuition2027/features/students/domain/student.dart';
import 'package:tuition2027/features/memberships/domain/membership.dart';
import 'package:tuition2027/features/roster/domain/roster_member.dart';

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

    // Mark as CO_MAT (using ChoiceChip)
    await tester.tap(find.text('Có mặt'));
    await tester.pumpAndSettle();

    // Verify draft state change in UI (Chip selection)
    final choiceChip = tester.widget<ChoiceChip>(
      find.ancestor(of: find.text('Có mặt'), matching: find.byType(ChoiceChip)),
    );
    expect(choiceChip.selected, isTrue);
  });

  testWidgets('AttendancePage bulk Mark All Present', (tester) async {
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

    final choiceChip = tester.widget<ChoiceChip>(
      find.ancestor(of: find.text('Có mặt'), matching: find.byType(ChoiceChip)),
    );
    expect(choiceChip.selected, isTrue);
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

    expect(find.textContaining('Không thể chỉnh sửa'), findsOneWidget);
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
}

class MockAttendanceController extends AttendanceController {
  final AttendanceSheet initialSheet;
  final bool failSave;

  MockAttendanceController(this.initialSheet, {this.failSave = false});

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
}
