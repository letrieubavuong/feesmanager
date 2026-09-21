import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuition2027/features/sessions/presentation/session_tab.dart';
import 'package:tuition2027/features/sessions/presentation/session_controller.dart';
import 'package:tuition2027/features/sessions/domain/class_session.dart';
import 'package:tuition2027/features/sessions/domain/session_generation_service.dart';
import 'package:intl/intl.dart';

void main() {
  final now = DateTime.now();
  final testSession = ClassSession(
    id: 1,
    idLop: 1,
    ngay: DateFormat('yyyy-MM-dd').format(now),
    gioBatDau: '17:30',
    gioKetThuc: '19:00',
    loai: SessionType.CHINH,
    trangThai: SessionStatus.DU_KIEN,
    createdAt: now,
    updatedAt: now,
  );

  testWidgets('SessionTab shows empty state', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          classSessionControllerProvider(1)
              .overrideWith(() => MockSessionController([])),
        ],
        child: const MaterialApp(home: Scaffold(body: SessionTab(classId: 1))),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.textContaining('Không có buổi học nào'), findsOneWidget);
  });

  testWidgets('SessionTab shows session list', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          classSessionControllerProvider(1)
              .overrideWith(() => MockSessionController([testSession])),
        ],
        child: const MaterialApp(home: Scaffold(body: SessionTab(classId: 1))),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.textContaining('17:30 - 19:00'), findsOneWidget);
    expect(find.textContaining('Chính thức'), findsOneWidget);
  });

  testWidgets('Open Generate Dialog', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          classSessionControllerProvider(1)
              .overrideWith(() => MockSessionController([])),
        ],
        child: const MaterialApp(home: Scaffold(body: SessionTab(classId: 1))),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.auto_awesome));
    await tester.pumpAndSettle();

    expect(find.text('Sinh buổi học tự động'), findsOneWidget);
    expect(find.text('Sinh buổi học'), findsOneWidget);
  });

  testWidgets('Open Manual Dialog', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          classSessionControllerProvider(1)
              .overrideWith(() => MockSessionController([])),
        ],
        child: const MaterialApp(home: Scaffold(body: SessionTab(classId: 1))),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.text('Thêm buổi học thủ công'), findsOneWidget);
    expect(find.text('Loại buổi học'), findsOneWidget);
  });

  testWidgets('Show generation summary after success', (tester) async {
    final mockController = MockSessionController([]);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          classSessionControllerProvider(1).overrideWith(() => mockController),
        ],
        child: const MaterialApp(home: Scaffold(body: SessionTab(classId: 1))),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.auto_awesome));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sinh buổi học'));
    await tester.pumpAndSettle();

    expect(find.text('Kết quả sinh buổi học'), findsOneWidget);
    expect(find.textContaining('Đã tạo mới: 10'), findsOneWidget);
  });

  testWidgets('Mark HUY with confirmation', (tester) async {
    final mockController = MockSessionController([testSession]);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          classSessionControllerProvider(1).overrideWith(() => mockController),
        ],
        child: const MaterialApp(home: Scaffold(body: SessionTab(classId: 1))),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.byType(PopupMenuButton<SessionStatus>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đánh dấu: HỦY'));
    await tester.pumpAndSettle();

    expect(find.text('Xác nhận thay đổi'), findsOneWidget);
    expect(find.textContaining('muốn đánh dấu buổi học này là HỦY'),
        findsOneWidget);

    await tester.tap(find.text('Xác nhận'));
    await tester.pumpAndSettle();

    expect(mockController.lastUpdatedStatus, SessionStatus.HUY);
  });

  testWidgets('Restore DU_KIEN with confirmation', (tester) async {
    final sessionHuy = testSession.copyWith(trangThai: SessionStatus.HUY);
    final mockController = MockSessionController([sessionHuy]);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          classSessionControllerProvider(1).overrideWith(() => mockController),
        ],
        child: const MaterialApp(home: Scaffold(body: SessionTab(classId: 1))),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.byType(PopupMenuButton<SessionStatus>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đánh dấu: DỰ KIẾN'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Xác nhận'));
    await tester.pumpAndSettle();

    expect(mockController.lastUpdatedStatus, SessionStatus.DU_KIEN);
  });

  testWidgets('Range filter works', (tester) async {
    // Using fixed dates for test consistency if possible, 
    // but the widget defaults relative to "now".
    final date1 = DateTime.now().subtract(const Duration(days: 2));
    final date2 = DateTime.now().add(const Duration(days: 2));
    
    final sValid1 = testSession.copyWith(id: 1, ngay: DateFormat('yyyy-MM-dd').format(date1));
    final sValid2 = testSession.copyWith(id: 2, ngay: DateFormat('yyyy-MM-dd').format(date2));
    
    final mockController = MockSessionController([sValid1, sValid2]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          classSessionControllerProvider(1).overrideWith(() => mockController),
        ],
        child: const MaterialApp(home: Scaffold(body: SessionTab(classId: 1))),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.textContaining(DateFormat('dd/MM/yyyy').format(date1)), findsOneWidget);
    expect(find.textContaining(DateFormat('dd/MM/yyyy').format(date2)), findsOneWidget);
  });
}

class MockSessionController extends ClassSessionController {
  final List<ClassSession> data;
  SessionStatus? lastUpdatedStatus;

  MockSessionController(this.data);

  @override
  FutureOr<List<ClassSession>> build(int classId) => data;

  @override
  Future<SessionGenerationResult> generate({
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    return const SessionGenerationResult(
      createdCount: 10,
      existingCount: 5,
      conflictCount: 0,
    );
  }

  @override
  Future<void> updateStatus(int sessionId, SessionStatus status) async {
    lastUpdatedStatus = status;
  }
}
