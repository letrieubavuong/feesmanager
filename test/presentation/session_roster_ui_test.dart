import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:tuition2027/features/roster/presentation/session_roster_view.dart';
import 'package:tuition2027/features/roster/presentation/roster_controller.dart';
import 'package:tuition2027/features/roster/domain/roster_result.dart';
import 'package:tuition2027/features/roster/domain/roster_member.dart';
import 'package:tuition2027/features/sessions/domain/class_session.dart';
import 'package:tuition2027/features/students/domain/student.dart';
import 'package:tuition2027/features/memberships/domain/membership.dart';
import 'package:tuition2027/features/sessions/presentation/session_tab.dart';
import 'package:tuition2027/features/sessions/presentation/session_controller.dart';

void main() {
  final now = DateTime.now();
  final testSession = ClassSession(
    id: 1,
    idLop: 1,
    ngay: DateFormat(
      'yyyy-MM-dd',
    ).format(now), // Use today to pass SessionTab filter
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

  testWidgets('SessionRosterView shows participants', (tester) async {
    final rosterResult = RosterResult(
      session: testSession,
      participants: [
        RosterMember(
          student: testStudent,
          membership: testMembership,
          source: RosterInclusionSource.SINGLE_SHIFT_MEMBERSHIP,
        ),
      ],
      unassignedMembers: [],
      issues: [],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionRosterProvider(1).overrideWith((ref) async => rosterResult),
        ],
        child: const MaterialApp(home: SessionRosterView(sessionId: 1)),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Test Student'), findsOneWidget);
    expect(find.textContaining('Tham gia lớp (1 ca)'), findsOneWidget);
    expect(find.textContaining('Chính thức'), findsOneWidget);
  });

  testWidgets('SessionRosterView shows unassigned warning', (tester) async {
    final rosterResult = RosterResult(
      session: testSession,
      participants: [],
      unassignedMembers: [testStudent],
      issues: [
        const RosterIssue(
          code: RosterIssueCode.UNASSIGNED_IN_MULTI_SHIFT,
          message: 'Học sinh Test Student chưa được phân ca.',
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionRosterProvider(1).overrideWith((ref) async => rosterResult),
        ],
        child: const MaterialApp(home: SessionRosterView(sessionId: 1)),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.textContaining('chưa được phân ca'), findsOneWidget);
    expect(find.text('Học sinh chưa phân ca (1)'), findsOneWidget);
  });

  testWidgets('SessionRosterView shows PHAT_SINH message', (tester) async {
    final phatSinhSession = testSession.copyWith(loai: SessionType.PHAT_SINH);
    final rosterResult = RosterResult(
      session: phatSinhSession,
      participants: [],
      unassignedMembers: [],
      issues: [],
      requiresOneOffAdjustments: true,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionRosterProvider(1).overrideWith((ref) async => rosterResult),
        ],
        child: const MaterialApp(home: SessionRosterView(sessionId: 1)),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.textContaining('cần điều chỉnh buổi học'), findsOneWidget);
  });

  testWidgets('SessionRosterView shows HOC_BU message', (tester) async {
    final hocBuSession = testSession.copyWith(loai: SessionType.HOC_BU);
    final rosterResult = RosterResult(
      session: hocBuSession,
      participants: [],
      unassignedMembers: [],
      issues: [],
      requiresOneOffAdjustments: true,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionRosterProvider(1).overrideWith((ref) async => rosterResult),
        ],
        child: const MaterialApp(home: SessionRosterView(sessionId: 1)),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.textContaining('cần điều chỉnh buổi học'), findsOneWidget);
  });

  testWidgets('SessionRosterView shows blocking integrity issue', (
    tester,
  ) async {
    final rosterResult = RosterResult(
      session: testSession,
      participants: [],
      unassignedMembers: [],
      issues: [
        const RosterIssue(
          code: RosterIssueCode.SESSION_SCHEDULE_NOT_EFFECTIVE,
          message: 'Lịch học gốc không còn hiệu lực.',
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionRosterProvider(1).overrideWith((ref) async => rosterResult),
        ],
        child: const MaterialApp(home: SessionRosterView(sessionId: 1)),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Lịch học gốc không còn hiệu lực.'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
  });

  testWidgets('SessionRosterView displays archived historical student', (
    tester,
  ) async {
    final archivedStudent = testStudent.copyWith(daLuuTru: true);
    final rosterResult = RosterResult(
      session: testSession,
      participants: [
        RosterMember(
          student: archivedStudent,
          membership: testMembership,
          source: RosterInclusionSource.SINGLE_SHIFT_MEMBERSHIP,
        ),
      ],
      unassignedMembers: [],
      issues: [],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionRosterProvider(1).overrideWith((ref) async => rosterResult),
        ],
        child: const MaterialApp(home: SessionRosterView(sessionId: 1)),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Test Student'), findsOneWidget);
    expect(find.text('Lưu trữ'), findsOneWidget);
  });

  testWidgets('SessionRosterView has NO attendance controls', (tester) async {
    final rosterResult = RosterResult(
      session: testSession,
      participants: [
        RosterMember(
          student: testStudent,
          membership: testMembership,
          source: RosterInclusionSource.SINGLE_SHIFT_MEMBERSHIP,
        ),
      ],
      unassignedMembers: [],
      issues: [],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionRosterProvider(1).overrideWith((ref) async => rosterResult),
        ],
        child: const MaterialApp(home: SessionRosterView(sessionId: 1)),
      ),
    );

    await tester.pumpAndSettle();

    // Negative assertions for attendance controls
    expect(find.text('Có mặt'), findsNothing);
    expect(find.text('Vắng'), findsNothing);
    expect(find.text('Trễ'), findsNothing);
    expect(find.text('Hoàn tất điểm danh'), findsNothing);
    expect(find.byType(Checkbox), findsNothing);
    expect(find.byType(Radio), findsNothing);
    expect(find.byType(Switch), findsNothing);
  });

  testWidgets('SessionTab navigates to SessionRosterView', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          classSessionControllerProvider(
            1,
          ).overrideWith(() => MockSessionController([testSession])),
          sessionRosterProvider(1).overrideWith(
            (ref) async => RosterResult(
              session: testSession,
              participants: [],
              unassignedMembers: [],
              issues: [],
            ),
          ),
        ],
        child: const MaterialApp(home: SessionTab(classId: 1)),
      ),
    );

    await tester.pumpAndSettle();

    // Tap on the session list tile
    await tester.tap(find.byType(ListTile).first);
    await tester.pumpAndSettle();

    // Verify navigation
    expect(find.byType(SessionRosterView), findsOneWidget);
    expect(find.text('Danh sách học sinh buổi học'), findsOneWidget);
  });
}

class MockSessionController extends ClassSessionController {
  final List<ClassSession> data;
  MockSessionController(this.data);

  @override
  FutureOr<List<ClassSession>> build(int classId) => data;
}
