import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuition2027/features/sessions/presentation/session_tab.dart';
import 'package:tuition2027/features/sessions/presentation/session_controller.dart';
import 'package:tuition2027/features/sessions/presentation/widgets/session_timeline_item.dart';
import 'package:tuition2027/features/sessions/domain/class_session.dart';

import '../test_helper.dart';

void main() {
  final now = DateTime.now();

  final s1 = ClassSession(
    id: 1,
    idLop: 1,
    ngay: '2026-09-30',
    gioBatDau: '19:00',
    gioKetThuc: '20:30',
    loai: SessionType.CHINH,
    trangThai: SessionStatus.DU_KIEN,
    createdAt: now,
    updatedAt: now,
  );

  final s2 = ClassSession(
    id: 2,
    idLop: 1,
    ngay: '2026-07-02',
    gioBatDau: '08:00',
    gioKetThuc: '09:30',
    loai: SessionType.CHINH,
    trangThai: SessionStatus.DA_HOC,
    createdAt: now,
    updatedAt: now,
  );

  final s3 = ClassSession(
    id: 3,
    idLop: 1,
    ngay: '2026-09-28',
    gioBatDau: '17:30',
    gioKetThuc: '19:00',
    loai: SessionType.HOC_BU,
    trangThai: SessionStatus.DU_KIEN,
    createdAt: now,
    updatedAt: now,
  );

  final s4 = ClassSession(
    id: 4,
    idLop: 1,
    ngay: '2026-07-02',
    gioBatDau: '10:00',
    gioKetThuc: '11:30',
    loai: SessionType.PHAT_SINH,
    trangThai: SessionStatus.HUY,
    createdAt: now,
    updatedAt: now,
  );

  final s5 = ClassSession(
    id: 5,
    idLop: 1,
    ngay: '2026-08-15',
    gioBatDau: '14:00',
    gioKetThuc: '15:30',
    loai: SessionType.CHINH,
    trangThai: SessionStatus.NGHI_LE,
    createdAt: now,
    updatedAt: now,
  );

  testWidgets('SessionTab displays sessions in chronological ASCENDING order', (
    tester,
  ) async {
    // Input order: s1 (30/09), s2 (02/07 08:00), s3 (28/09), s4 (02/07 10:00), s5 (15/08)
    final unordered = [s1, s2, s3, s4, s5];

    await tester.pumpWidget(
      createTestApp(
        overrides: [
          classSessionControllerProvider(
            1,
          ).overrideWith(() => MockSessionController(unordered)),
        ],
        home: const SessionTab(classId: 1),
      ),
    );
    await tester.pumpAndSettle();

    final timelineItems = tester
        .widgetList<SessionTimelineItem>(find.byType(SessionTimelineItem))
        .toList();

    expect(timelineItems.length, 5);
    expect(timelineItems[0].session.id, 2); // 02/07/2026 08:00
    expect(timelineItems[1].session.id, 4); // 02/07/2026 10:00
    expect(timelineItems[2].session.id, 5); // 15/08/2026 14:00
    expect(timelineItems[3].session.id, 3); // 28/09/2026 17:30
    expect(timelineItems[4].session.id, 1); // 30/09/2026 19:00
  });

  testWidgets(
    'SessionTab groups months in ASCENDING order (THÁNG 07, THÁNG 08, THÁNG 09)',
    (tester) async {
      final unordered = [s1, s2, s3, s5];

      await tester.pumpWidget(
        createTestApp(
          overrides: [
            classSessionControllerProvider(
              1,
            ).overrideWith(() => MockSessionController(unordered)),
          ],
          home: const SessionTab(classId: 1),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('THÁNG 07/2026'), findsOneWidget);
      expect(find.text('THÁNG 08/2026'), findsOneWidget);
      expect(find.text('THÁNG 09/2026'), findsOneWidget);

      final julOffset = tester.getTopLeft(find.text('THÁNG 07/2026')).dy;
      final augOffset = tester.getTopLeft(find.text('THÁNG 08/2026')).dy;
      final sepOffset = tester.getTopLeft(find.text('THÁNG 09/2026')).dy;

      expect(julOffset < augOffset, isTrue);
      expect(augOffset < sepOffset, isTrue);
    },
  );

  testWidgets(
    'SessionTimelineItem renders all status types (DU_KIEN, DA_HOC, HUY, NGHI_LE)',
    (tester) async {
      final unordered = [s1, s2, s4, s5];

      await tester.pumpWidget(
        createTestApp(
          overrides: [
            classSessionControllerProvider(
              1,
            ).overrideWith(() => MockSessionController(unordered)),
          ],
          home: const SessionTab(classId: 1),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Đã học'), findsOneWidget);
      expect(find.text('Dự kiến'), findsOneWidget);
      expect(find.text('Hủy'), findsOneWidget);
      expect(find.text('Nghỉ lễ'), findsOneWidget);
    },
  );

  testWidgets(
    'SessionTimelineItem renders all session types (CHINH, HOC_BU, PHAT_SINH)',
    (tester) async {
      final unordered = [s1, s3, s4];

      await tester.pumpWidget(
        createTestApp(
          overrides: [
            classSessionControllerProvider(
              1,
            ).overrideWith(() => MockSessionController(unordered)),
          ],
          home: const SessionTab(classId: 1),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Chính'), findsAtLeast(1));
      expect(find.text('Học bù'), findsOneWidget);
      expect(find.text('Phát sinh'), findsOneWidget);
    },
  );

  testWidgets(
    'Same day sessions are sorted by start time ASC (08:00 before 10:00)',
    (tester) async {
      final sameDay = [s4, s2]; // 10:00, 08:00

      await tester.pumpWidget(
        createTestApp(
          overrides: [
            classSessionControllerProvider(
              1,
            ).overrideWith(() => MockSessionController(sameDay)),
          ],
          home: const SessionTab(classId: 1),
        ),
      );
      await tester.pumpAndSettle();

      final timelineItems = tester
          .widgetList<SessionTimelineItem>(find.byType(SessionTimelineItem))
          .toList();

      expect(timelineItems.length, 2);
      expect(timelineItems[0].session.gioBatDau, '08:00');
      expect(timelineItems[1].session.gioBatDau, '10:00');
    },
  );

  testWidgets(
    '320px narrow device layout test renders timeline without pixel overflow',
    (tester) async {
      final longNoteSession = s1.copyWith(
        ghiChu:
            'Ghi chú rất dài dành cho buổi học để kiểm tra xem dòng ghi chú có bị tràn màn hình không',
      );

      tester.view.physicalSize = const Size(320 * 2.0, 640 * 2.0);
      tester.view.devicePixelRatio = 2.0;

      await tester.pumpWidget(
        createTestApp(
          overrides: [
            classSessionControllerProvider(
              1,
            ).overrideWith(() => MockSessionController([longNoteSession])),
          ],
          home: const SessionTab(classId: 1),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SessionTab), findsOneWidget);
      expect(tester.takeException(), isNull);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    },
  );

  testWidgets(
    'Archived class hides add session action button and status popup menus',
    (tester) async {
      final unordered = [s1, s2];

      await tester.pumpWidget(
        createTestApp(
          overrides: [
            classSessionControllerProvider(
              1,
            ).overrideWith(() => MockSessionController(unordered)),
          ],
          home: const SessionTab(classId: 1, isArchived: true),
        ),
      );
      await tester.pumpAndSettle();

      // No + Buổi học button
      expect(find.text('+ Buổi học'), findsNothing);
      // No popup menu buttons
      expect(find.byIcon(Icons.more_vert_rounded), findsNothing);
      // Timeline items still present
      expect(find.byType(SessionTimelineItem), findsNWidgets(2));
    },
  );

  testWidgets('Stacked small FABs are removed from SessionTab scaffold', (
    tester,
  ) async {
    await tester.pumpWidget(
      createTestApp(
        overrides: [
          classSessionControllerProvider(
            1,
          ).overrideWith(() => MockSessionController([s1])),
        ],
        home: const SessionTab(classId: 1),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(FloatingActionButton), findsNothing);
    expect(find.text('+ Buổi học'), findsOneWidget);
  });
}

class MockSessionController extends ClassSessionController {
  final List<ClassSession> data;
  MockSessionController(this.data);

  @override
  FutureOr<List<ClassSession>> build(int classId) => data;
}
