import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuition2027/features/roster/presentation/session_roster_view.dart';
import 'package:tuition2027/features/roster/presentation/roster_controller.dart';
import 'package:tuition2027/features/roster/domain/roster_result.dart';
import 'package:tuition2027/features/roster/domain/roster_member.dart';
import 'package:tuition2027/features/sessions/domain/class_session.dart';
import 'package:tuition2027/features/students/domain/student.dart';
import 'package:tuition2027/features/memberships/domain/membership.dart';

void main() {
  final now = DateTime.now();
  final testSession = ClassSession(
    id: 1,
    idLop: 1,
    ngay: '2026-09-07',
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
}
