import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuition2027/features/sessions/presentation/session_tab.dart';
import 'package:tuition2027/features/sessions/presentation/session_controller.dart';
import 'package:tuition2027/features/sessions/domain/class_session.dart';
import 'package:tuition2027/features/sessions/domain/session_generation_service.dart';

void main() {
  final testSession = ClassSession(
    id: 1,
    idLop: 1,
    ngay: '2026-09-07',
    gioBatDau: '17:30',
    gioKetThuc: '19:00',
    loai: SessionType.CHINH,
    trangThai: SessionStatus.DU_KIEN,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  testWidgets('SessionTab shows empty state', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          classSessionControllerProvider(
            1,
          ).overrideWith(() => MockSessionController([])),
        ],
        child: const MaterialApp(home: Scaffold(body: SessionTab(classId: 1))),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Lớp chưa có buổi học nào.'), findsOneWidget);
  });

  testWidgets('SessionTab shows session list', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          classSessionControllerProvider(
            1,
          ).overrideWith(() => MockSessionController([testSession])),
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
          classSessionControllerProvider(
            1,
          ).overrideWith(() => MockSessionController([])),
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
          classSessionControllerProvider(
            1,
          ).overrideWith(() => MockSessionController([])),
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

    // Fill dates (defaults are fine)
    await tester.tap(find.text('Sinh buổi học'));
    await tester.pumpAndSettle();

    // Result dialog should appear
    expect(find.text('Kết quả sinh buổi học'), findsOneWidget);
    expect(find.textContaining('Đã tạo mới: 10'), findsOneWidget);
  });
}

class MockSessionController extends ClassSessionController {
  final List<ClassSession> data;
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
}
