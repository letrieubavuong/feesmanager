import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuition2027/features/classes/domain/class.dart';
import 'package:tuition2027/features/classes/presentation/class_controller.dart';
import 'package:tuition2027/features/session_credits/domain/credit_ledger_entry.dart';
import 'package:tuition2027/features/session_credits/domain/credit_ledger_reason.dart';
import 'package:tuition2027/features/session_credits/domain/monthly_credit_summary.dart';
import 'package:tuition2027/features/session_credits/domain/session_credit_service.dart';
import 'package:tuition2027/features/session_credits/presentation/session_credit_controller.dart';
import 'package:tuition2027/features/session_credits/presentation/session_credit_page.dart';
import 'package:tuition2027/features/students/domain/student.dart';
import 'package:tuition2027/features/students/presentation/student_detail_page.dart';

void main() {
  final now = DateTime.now();
  final testStudent = Student(
    id: 1,
    hoTen: 'Nguyen Van A',
    createdAt: now,
    updatedAt: now,
  );
  final testClass = ClassEntity(
    id: 10,
    tenLop: 'Class 10A',
    createdAt: now,
    updatedAt: now,
  );

  const testSummary = MonthlyCreditSummary(
    studentId: 1,
    classId: 10,
    month: '2026-09',
    standardSessionLimit: 12,
    eligibleCount: 14,
    standardCount: 12,
    extraCount: 2,
    potentialEarned: 2,
    recordedEarned: 0,
    openingBalance: 0,
    monthDelta: 0,
    closingBalance: 0,
    candidates: [],
  );

  testWidgets(
    'SessionCreditPage renders student name, class name and summary stats',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sessionCreditControllerProvider(
              1,
              10,
              '2026-09',
            ).overrideWith(() => MockSessionCreditController(testSummary)),
            studentDetailProvider(1).overrideWith((ref) async => testStudent),
            classDetailProvider(10).overrideWith((ref) async => testClass),
            sessionCreditServiceProvider.overrideWith(
              (ref) => Future.value(MockSessionCreditService([])),
            ),
          ],
          child: const MaterialApp(
            home: SessionCreditPage(
              studentId: 1,
              classId: 10,
              initialMonth: '2026-09',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Nguyen Van A'), findsOneWidget);
      expect(find.text('Lớp: Class 10A'), findsOneWidget);
      expect(find.text('Đối soát buổi dư tháng này'), findsOneWidget);
      expect(find.text('Điều chỉnh thủ công'), findsOneWidget);
    },
  );

  testWidgets('SessionCreditPage reconciliation preview dialog opens', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionCreditControllerProvider(
            1,
            10,
            '2026-09',
          ).overrideWith(() => MockSessionCreditController(testSummary)),
          studentDetailProvider(1).overrideWith((ref) async => testStudent),
          classDetailProvider(10).overrideWith((ref) async => testClass),
          sessionCreditServiceProvider.overrideWith(
            (ref) => Future.value(MockSessionCreditService([])),
          ),
        ],
        child: const MaterialApp(
          home: SessionCreditPage(
            studentId: 1,
            classId: 10,
            initialMonth: '2026-09',
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Tap "Đối soát buổi dư tháng này"
    await tester.tap(find.text('Đối soát buổi dư tháng này'));
    await tester.pumpAndSettle();

    expect(find.text('Đối soát buổi dư'), findsOneWidget);
    expect(find.textContaining('Sẽ ghi thêm +2 credit'), findsOneWidget);
  });

  test('SessionCreditController rethrows exception on failure', () async {
    final container = ProviderContainer(
      overrides: [
        sessionCreditControllerProvider(
          1,
          10,
          '2026-09',
        ).overrideWith(() => FailingSessionCreditController(testSummary)),
      ],
    );
    addTearDown(container.dispose);

    final controller = container.read(
      sessionCreditControllerProvider(1, 10, '2026-09').notifier,
    );
    await container.read(
      sessionCreditControllerProvider(1, 10, '2026-09').future,
    );

    expect(() => controller.reconcile(), throwsA(isA<Exception>()));
  });

  testWidgets(
    'SessionCreditPage month navigation updates month display and loads month-specific summary provider',
    (tester) async {
      const septSummary = testSummary;
      final octSummary = testSummary.copyWith(
        month: '2026-10',
        potentialEarned: 7,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sessionCreditControllerProvider(
              1,
              10,
              '2026-09',
            ).overrideWith(() => MockSessionCreditController(septSummary)),
            sessionCreditControllerProvider(
              1,
              10,
              '2026-10',
            ).overrideWith(() => MockSessionCreditController(octSummary)),
            studentDetailProvider(1).overrideWith((ref) async => testStudent),
            classDetailProvider(10).overrideWith((ref) async => testClass),
            sessionCreditServiceProvider.overrideWith(
              (ref) => Future.value(MockSessionCreditService([])),
            ),
          ],
          child: const MaterialApp(
            home: SessionCreditPage(
              studentId: 1,
              classId: 10,
              initialMonth: '2026-09',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tháng 09/2026'), findsOneWidget);
      expect(find.text('+2'), findsOneWidget); // Sept potentialEarned = 2

      // Tap next month
      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pumpAndSettle();

      expect(find.text('Tháng 10/2026'), findsOneWidget);
      expect(find.text('+7'), findsOneWidget); // Oct potentialEarned = 7
    },
  );

  testWidgets(
    'SessionCreditPage reconcile failure displays error message without false success',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sessionCreditControllerProvider(
              1,
              10,
              '2026-09',
            ).overrideWith(() => FailingSessionCreditController(testSummary)),
            studentDetailProvider(1).overrideWith((ref) async => testStudent),
            classDetailProvider(10).overrideWith((ref) async => testClass),
            sessionCreditServiceProvider.overrideWith(
              (ref) => Future.value(MockSessionCreditService([])),
            ),
          ],
          child: const MaterialApp(
            home: SessionCreditPage(
              studentId: 1,
              classId: 10,
              initialMonth: '2026-09',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Đối soát buổi dư tháng này'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Xác nhận đối soát'));
      await tester.pumpAndSettle();

      expect(find.text('Lỗi').first, findsOneWidget);
      expect(find.textContaining('Reconcile failed').first, findsOneWidget);
    },
  );

  testWidgets('SessionCreditPage manual adjustment validation and execution', (
    tester,
  ) async {
    final mockService = MockSessionCreditService([]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionCreditControllerProvider(
            1,
            10,
            '2026-09',
          ).overrideWith(() => MockSessionCreditController(testSummary)),
          studentDetailProvider(1).overrideWith((ref) async => testStudent),
          classDetailProvider(10).overrideWith((ref) async => testClass),
          sessionCreditServiceProvider.overrideWith(
            (ref) => Future.value(mockService),
          ),
        ],
        child: const MaterialApp(
          home: SessionCreditPage(
            studentId: 1,
            classId: 10,
            initialMonth: '2026-09',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Open Manual Adjustment dialog
    await tester.tap(find.text('Điều chỉnh thủ công'));
    await tester.pumpAndSettle();

    expect(find.text('Điều chỉnh credit thủ công'), findsOneWidget);

    // Enter delta = 0
    final textFields = find.byType(TextField);
    await tester.enterText(textFields.at(0), '0');
    await tester.enterText(textFields.at(2), 'Ghi chú');
    await tester.tap(find.text('Lưu điều chỉnh'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Số lượng điều chỉnh phải khác 0').first,
      findsOneWidget,
    );
    await tester.tap(find.text('Đóng'));
    await tester.pumpAndSettle();

    // Enter blank note with delta = 1
    await tester.enterText(textFields.at(0), '1');
    await tester.enterText(textFields.at(2), '   ');
    await tester.tap(find.text('Lưu điều chỉnh'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Vui lòng nhập ghi chú').first, findsOneWidget);
    await tester.tap(find.text('Đóng'));
    await tester.pumpAndSettle();

    // Enter valid +1 adjustment
    await tester.enterText(textFields.at(0), '1');
    await tester.enterText(textFields.at(2), 'Thưởng học sinh');
    await tester.tap(find.text('Lưu điều chỉnh'));
    await tester.pumpAndSettle();

    expect(mockService.addManualCalls, 1);
    expect(mockService.lastDelta, 1);
  });

  testWidgets(
    'SessionCreditPage class scope displays Class A closing balance',
    (tester) async {
      final classASummary = testSummary.copyWith(closingBalance: 3);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sessionCreditControllerProvider(
              1,
              10,
              '2026-09',
            ).overrideWith(() => MockSessionCreditController(classASummary)),
            studentDetailProvider(1).overrideWith((ref) async => testStudent),
            classDetailProvider(10).overrideWith((ref) async => testClass),
            sessionCreditServiceProvider.overrideWith(
              (ref) => Future.value(MockSessionCreditService([])),
            ),
          ],
          child: const MaterialApp(
            home: SessionCreditPage(
              studentId: 1,
              classId: 10,
              initialMonth: '2026-09',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('+3 buổi'), findsOneWidget);
    },
  );

  testWidgets(
    'SessionCreditPage class scope displays Class B closing balance independently',
    (tester) async {
      final classBSummary = testSummary.copyWith(
        classId: 20,
        closingBalance: 1,
      );
      final testClassB = ClassEntity(
        id: 20,
        tenLop: 'Class 20B',
        createdAt: now,
        updatedAt: now,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sessionCreditControllerProvider(
              1,
              20,
              '2026-09',
            ).overrideWith(() => MockSessionCreditController(classBSummary)),
            studentDetailProvider(1).overrideWith((ref) async => testStudent),
            classDetailProvider(20).overrideWith((ref) async => testClassB),
            sessionCreditServiceProvider.overrideWith(
              (ref) => Future.value(MockSessionCreditService([])),
            ),
          ],
          child: const MaterialApp(
            home: SessionCreditPage(
              studentId: 1,
              classId: 20,
              initialMonth: '2026-09',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('+1 buổi'), findsOneWidget);
    },
  );

  testWidgets(
    'SessionCreditPage reconcile execution calls controller reconcile',
    (tester) async {
      final controller = MockSessionCreditController(testSummary);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sessionCreditControllerProvider(
              1,
              10,
              '2026-09',
            ).overrideWith(() => controller),
            studentDetailProvider(1).overrideWith((ref) async => testStudent),
            classDetailProvider(10).overrideWith((ref) async => testClass),
            sessionCreditServiceProvider.overrideWith(
              (ref) => Future.value(MockSessionCreditService([])),
            ),
          ],
          child: const MaterialApp(
            home: SessionCreditPage(
              studentId: 1,
              classId: 10,
              initialMonth: '2026-09',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Đối soát
      await tester.tap(find.text('Đối soát buổi dư tháng này'));
      await tester.pumpAndSettle();

      // Tap Confirm
      await tester.tap(find.text('Xác nhận đối soát'));
      await tester.pumpAndSettle();

      expect(controller.reconcileCalls, 1);
    },
  );

  testWidgets(
    'SessionCreditPage negative balance renders true value without clamping',
    (tester) async {
      final negSummary = testSummary.copyWith(closingBalance: -1);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sessionCreditControllerProvider(
              1,
              10,
              '2026-09',
            ).overrideWith(() => MockSessionCreditController(negSummary)),
            studentDetailProvider(1).overrideWith((ref) async => testStudent),
            classDetailProvider(10).overrideWith((ref) async => testClass),
            sessionCreditServiceProvider.overrideWith(
              (ref) => Future.value(MockSessionCreditService([])),
            ),
          ],
          child: const MaterialApp(
            home: SessionCreditPage(
              studentId: 1,
              classId: 10,
              initialMonth: '2026-09',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('-1 buổi'), findsOneWidget);
    },
  );

  testWidgets(
    'SessionCreditPage ledger history renders without edit or delete buttons',
    (tester) async {
      final entry = CreditLedgerEntry(
        id: 1,
        idHocSinh: 1,
        idLop: 10,
        ngayHieuLuc: '2026-09-10',
        delta: 1,
        lyDo: CreditLedgerReason.VUOT_SO_BUOI_CHUAN,
        ghiChu: 'Auto earned',
        createdAt: now,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sessionCreditControllerProvider(
              1,
              10,
              '2026-09',
            ).overrideWith(() => MockSessionCreditController(testSummary)),
            studentDetailProvider(1).overrideWith((ref) async => testStudent),
            classDetailProvider(10).overrideWith((ref) async => testClass),
            sessionCreditServiceProvider.overrideWith(
              (ref) => Future.value(MockSessionCreditService([entry])),
            ),
          ],
          child: const MaterialApp(
            home: SessionCreditPage(
              studentId: 1,
              classId: 10,
              initialMonth: '2026-09',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Vượt số buổi chuẩn'), findsOneWidget);
      expect(find.text('Edit'), findsNothing);
      expect(find.text('Delete'), findsNothing);
      expect(find.text('Sửa'), findsNothing);
      expect(find.text('Xóa'), findsNothing);
    },
  );
}

extension on MonthlyCreditSummary {
  MonthlyCreditSummary copyWith({
    String? month,
    int? classId,
    int? potentialEarned,
    int? closingBalance,
  }) {
    return MonthlyCreditSummary(
      studentId: studentId,
      classId: classId ?? this.classId,
      month: month ?? this.month,
      standardSessionLimit: standardSessionLimit,
      eligibleCount: eligibleCount,
      standardCount: standardCount,
      extraCount: extraCount,
      potentialEarned: potentialEarned ?? this.potentialEarned,
      recordedEarned: recordedEarned,
      openingBalance: openingBalance,
      monthDelta: monthDelta,
      closingBalance: closingBalance ?? this.closingBalance,
      candidates: candidates,
    );
  }
}

class MockSessionCreditController extends SessionCreditController {
  final MonthlyCreditSummary summary;
  int reconcileCalls = 0;

  MockSessionCreditController(this.summary);

  @override
  FutureOr<MonthlyCreditSummary> build(
    int studentId,
    int classId,
    String month,
  ) => summary;

  @override
  Future<void> reconcile() async {
    reconcileCalls++;
  }
}

class FailingSessionCreditController extends SessionCreditController {
  final MonthlyCreditSummary summary;
  FailingSessionCreditController(this.summary);

  @override
  FutureOr<MonthlyCreditSummary> build(
    int studentId,
    int classId,
    String month,
  ) => summary;

  @override
  Future<void> reconcile() async {
    state = AsyncError(Exception('Reconcile failed'), StackTrace.current);
    throw Exception('Reconcile failed');
  }
}

class MockSessionCreditService implements SessionCreditService {
  final List<CreditLedgerEntry> entries;
  int addManualCalls = 0;
  int? lastDelta;

  MockSessionCreditService(this.entries);

  @override
  Future<List<CreditLedgerEntry>> getLedger(int studentId, int classId) async =>
      entries;

  @override
  Future<void> addManualAdjustment({
    required int studentId,
    required int classId,
    required int delta,
    required String effectiveDate,
    required String note,
  }) async {
    if (note.trim().isEmpty) {
      throw Exception('Vui lòng nhập ghi chú nguyên nhân điều chỉnh thủ công');
    }
    addManualCalls++;
    lastDelta = delta;
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
