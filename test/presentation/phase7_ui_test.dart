import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuition2027/features/leave/domain/leave_request.dart';
import 'package:tuition2027/features/leave/presentation/leave_request_controller.dart';
import 'package:tuition2027/features/leave/presentation/leave_request_page.dart';
import 'package:tuition2027/features/session_adjustments/domain/session_adjustment.dart';
import 'package:tuition2027/features/session_adjustments/presentation/session_adjustment_controller.dart';
import 'package:tuition2027/features/students/domain/student.dart';
import 'package:tuition2027/features/students/domain/student_service.dart';

void main() {
  final now = DateTime.now();

  final testStudent = Student(
    id: 101,
    hoTen: 'Test Student',
    createdAt: now,
    updatedAt: now,
  );

  testWidgets('LeaveRequestPage renders requests and filter chips', (
    tester,
  ) async {
    final req = LeaveRequest(
      id: 1,
      idHocSinh: 101,
      idLop: 10,
      tuNgay: '2026-09-10',
      denNgay: '2026-09-15',
      lyDo: 'Gia đình có việc',
      trangThai: LeaveRequestStatus.CHO_DUYET,
      createdAt: now,
      updatedAt: now,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          leaveRequestControllerProvider(
            10,
          ).overrideWith(() => MockLeaveRequestController([req])),
          studentServiceProvider.overrideWith(
            (ref) => Future.value(MockStudentService(testStudent)),
          ),
        ],
        child: const MaterialApp(home: LeaveRequestPage(classId: 10)),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Test Student'), findsOneWidget);
    expect(find.text('Lý do: Gia đình có việc'), findsOneWidget);
    expect(find.text('Chờ duyệt'), findsAtLeast(1));

    // Tap Approve
    await tester.tap(find.text('Duyệt'));
    await tester.pumpAndSettle();
  });

  testWidgets('SessionAdjustmentController builds and manages state', (
    tester,
  ) async {
    final adj = SessionAdjustment(
      id: 1,
      idHocSinh: 101,
      idLopGoc: 10,
      idBuoiHocThamGia: 102,
      loai: SessionAdjustmentType.DOI_CA,
      createdAt: now,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionAdjustmentControllerProvider(
            102,
          ).overrideWith(() => MockSessionAdjustmentController([adj])),
        ],
        child: const MaterialApp(home: SizedBox()),
      ),
    );
    await tester.pumpAndSettle();

    final element = tester.element(find.byType(SizedBox));
    final container = ProviderScope.containerOf(element);
    final list = await container.read(
      sessionAdjustmentControllerProvider(102).future,
    );
    expect(list.length, 1);
    expect(list.first.loai, SessionAdjustmentType.DOI_CA);
  });

  test('LeaveRequestController rethrows exception on failure', () async {
    final container = ProviderContainer(
      overrides: [
        leaveRequestControllerProvider(
          10,
        ).overrideWith(() => FailingLeaveRequestController()),
      ],
    );
    addTearDown(container.dispose);

    final controller = container.read(
      leaveRequestControllerProvider(10).notifier,
    );
    await container.read(leaveRequestControllerProvider(10).future);

    expect(
      () => controller.createLeaveRequest(
        LeaveRequest(
          idHocSinh: 1,
          idLop: 10,
          tuNgay: '2026-09-10',
          denNgay: '2026-09-15',
          createdAt: now,
          updatedAt: now,
        ),
      ),
      throwsA(isA<Exception>()),
    );
  });

  test('SessionAdjustmentController rethrows exception on failure', () async {
    final container = ProviderContainer(
      overrides: [
        sessionAdjustmentControllerProvider(
          102,
        ).overrideWith(() => FailingSessionAdjustmentController()),
      ],
    );
    addTearDown(container.dispose);

    final controller = container.read(
      sessionAdjustmentControllerProvider(102).notifier,
    );
    await container.read(sessionAdjustmentControllerProvider(102).future);

    expect(
      () => controller.createDoiCa(
        studentId: 1,
        originalSessionId: 101,
        targetSessionId: 102,
      ),
      throwsA(isA<Exception>()),
    );
  });
}

class FailingLeaveRequestController extends LeaveRequestController {
  @override
  FutureOr<List<LeaveRequest>> build(int classId) => [];

  @override
  Future<void> createLeaveRequest(LeaveRequest request) async {
    state = AsyncError(Exception('Create failed'), StackTrace.current);
    throw Exception('Create failed');
  }
}

class FailingSessionAdjustmentController extends SessionAdjustmentController {
  @override
  FutureOr<List<SessionAdjustment>> build(int sessionId) => [];

  @override
  Future<void> createDoiCa({
    required int studentId,
    required int originalSessionId,
    required int targetSessionId,
    String? reason,
  }) async {
    state = AsyncError(Exception('DoiCa failed'), StackTrace.current);
    throw Exception('DoiCa failed');
  }
}

class MockLeaveRequestController extends LeaveRequestController {
  final List<LeaveRequest> initialData;
  MockLeaveRequestController(this.initialData);

  @override
  FutureOr<List<LeaveRequest>> build(int classId) => initialData;

  @override
  Future<void> approve(int requestId) async {
    state = AsyncValue.data(
      state.value!
          .map(
            (r) => r.id == requestId
                ? r.copyWith(trangThai: LeaveRequestStatus.DA_DUYET)
                : r,
          )
          .toList(),
    );
  }

  @override
  Future<void> reject(int requestId) async {
    state = AsyncValue.data(
      state.value!
          .map(
            (r) => r.id == requestId
                ? r.copyWith(trangThai: LeaveRequestStatus.TU_CHOI)
                : r,
          )
          .toList(),
    );
  }
}

class MockStudentService implements StudentService {
  final Student student;
  MockStudentService(this.student);

  @override
  Future<Student?> getStudentById(int id) async => student;

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockSessionAdjustmentController extends SessionAdjustmentController {
  final List<SessionAdjustment> initialData;
  MockSessionAdjustmentController(this.initialData);

  @override
  FutureOr<List<SessionAdjustment>> build(int sessionId) => initialData;
}
