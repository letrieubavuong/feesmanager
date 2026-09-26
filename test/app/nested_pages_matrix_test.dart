import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tuition2027/app/navigation/ui_keys.dart';
import 'package:tuition2027/features/attendance/domain/attendance_sheet.dart';
import 'package:tuition2027/features/attendance/presentation/attendance_controller.dart';
import 'package:tuition2027/features/attendance/presentation/attendance_page.dart';
import 'package:tuition2027/features/classes/domain/class.dart';
import 'package:tuition2027/features/classes/presentation/class_controller.dart';
import 'package:tuition2027/features/classes/presentation/class_detail_page.dart';
import 'package:tuition2027/features/classes/presentation/class_form_page.dart';
import 'package:tuition2027/features/leave/domain/leave_request.dart';
import 'package:tuition2027/features/leave/presentation/leave_request_controller.dart';
import 'package:tuition2027/features/leave/presentation/leave_request_page.dart';
import 'package:tuition2027/features/session_credits/domain/monthly_credit_summary.dart';
import 'package:tuition2027/features/session_credits/presentation/session_credit_controller.dart';
import 'package:tuition2027/features/session_credits/presentation/session_credit_page.dart';
import 'package:tuition2027/features/students/domain/student.dart';
import 'package:tuition2027/features/students/presentation/student_detail_page.dart';
import 'package:tuition2027/features/students/presentation/student_form_page.dart';
import '../test_helper.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpNestedScreen(
    WidgetTester tester,
    Widget child, {
    List<Override> overrides = const [],
  }) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      createTestApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => child)),
              child: const Text('Open Page'),
            ),
          ),
        ),
        overrides: overrides,
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Open Page'));
    await tester.pumpAndSettle();
  }

  group('Phase 13A Nested Operational Pages Navigation Matrix Tests', () {
    testWidgets(
      'StudentDetailPage provides Back button and Global Menu button',
      (tester) async {
        final testStudent = Student(
          id: 10,
          hoTen: 'Student Alpha',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await pumpNestedScreen(
          tester,
          const StudentDetailPage(studentId: 10),
          overrides: [
            studentDetailProvider(10).overrideWith((ref) async => testStudent),
          ],
        );

        expect(find.byType(BackButton), findsOneWidget);
        expect(find.byKey(UiKeys.globalMenuButton), findsOneWidget);
      },
    );

    testWidgets('StudentFormPage provides Back button and Global Menu button', (
      tester,
    ) async {
      await pumpNestedScreen(tester, const StudentFormPage());

      expect(find.byType(BackButton), findsOneWidget);
      expect(find.byKey(UiKeys.globalMenuButton), findsOneWidget);
    });

    testWidgets('ClassDetailPage provides Back button and Global Menu button', (
      tester,
    ) async {
      final testClass = ClassEntity(
        id: 20,
        tenLop: 'Class Beta',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await pumpNestedScreen(
        tester,
        const ClassDetailPage(classId: 20),
        overrides: [
          classDetailProvider(20).overrideWith((ref) async => testClass),
        ],
      );

      expect(find.byType(BackButton), findsOneWidget);
      expect(find.byKey(UiKeys.globalMenuButton), findsOneWidget);
    });

    testWidgets('ClassFormPage provides Back button and Global Menu button', (
      tester,
    ) async {
      await pumpNestedScreen(tester, const ClassFormPage());

      expect(find.byType(BackButton), findsOneWidget);
      expect(find.byKey(UiKeys.globalMenuButton), findsOneWidget);
    });

    testWidgets('AttendancePage provides Back button and Global Menu button', (
      tester,
    ) async {
      await pumpNestedScreen(
        tester,
        const AttendancePage(sessionId: 100),
        overrides: [
          attendanceControllerProvider(
            100,
          ).overrideWith(() => MockAttendanceController()),
        ],
      );

      expect(find.byType(BackButton), findsOneWidget);
      expect(find.byKey(UiKeys.globalMenuButton), findsOneWidget);
    });

    testWidgets(
      'LeaveRequestPage provides Back button and Global Menu button',
      (tester) async {
        await pumpNestedScreen(
          tester,
          const LeaveRequestPage(classId: 30),
          overrides: [
            leaveRequestControllerProvider(
              30,
            ).overrideWith(() => MockLeaveRequestController()),
          ],
        );

        expect(find.byType(BackButton), findsOneWidget);
        expect(find.byKey(UiKeys.globalMenuButton), findsOneWidget);
      },
    );

    testWidgets(
      'SessionCreditPage provides Back button and Global Menu button',
      (tester) async {
        await pumpNestedScreen(
          tester,
          const SessionCreditPage(
            studentId: 1,
            classId: 2,
            initialMonth: '2026-10',
          ),
          overrides: [
            sessionCreditControllerProvider(
              1,
              2,
              '2026-10',
            ).overrideWith(() => MockSessionCreditController()),
            studentDetailProvider(1).overrideWith((ref) async => null),
            classDetailProvider(2).overrideWith((ref) async => null),
          ],
        );

        expect(find.byType(BackButton), findsOneWidget);
        expect(find.byKey(UiKeys.globalMenuButton), findsOneWidget);
      },
    );
  });
}

class MockAttendanceController extends AttendanceController {
  @override
  FutureOr<AttendanceSheet> build(int sessionId) async {
    throw UnimplementedError();
  }
}

class MockLeaveRequestController extends LeaveRequestController {
  @override
  FutureOr<List<LeaveRequest>> build(int classId) async => [];
}

class MockSessionCreditController extends SessionCreditController {
  @override
  FutureOr<MonthlyCreditSummary> build(
    int studentId,
    int classId,
    String month,
  ) async {
    return MonthlyCreditSummary(
      studentId: studentId,
      classId: classId,
      month: month,
      openingBalance: 0,
      monthDelta: 0,
      closingBalance: 0,
      standardSessionLimit: 12,
      eligibleCount: 0,
      standardCount: 0,
      extraCount: 0,
      potentialEarned: 0,
      recordedEarned: 0,
      candidates: [],
    );
  }
}
