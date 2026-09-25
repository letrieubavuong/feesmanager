import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuition2027/features/students/presentation/student_form_page.dart';
import '../test_helper.dart';

void main() {
  group('Phase 13A Dirty Form Protection Widget Tests', () {
    testWidgets('StudentFormPage tracks edits and prompts discard warning on back pop', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          home: const StudentFormPage(),
        ),
      );

      await tester.pumpAndSettle();

      // Enter text into Full Name field -> makes form dirty
      await tester.enterText(find.byType(TextFormField).first, 'Nguyễn Văn Test');
      await tester.pumpAndSettle();

      // Attempt Android Back / Pop -> triggers PopScope confirmation dialog
      final dynamic widgetsAppState = tester.state(find.byType(WidgetsApp));
      widgetsAppState.didPopRoute();
      await tester.pumpAndSettle();

      expect(find.text('Rời khỏi trang?'), findsOneWidget);
      expect(find.text('Bỏ thay đổi'), findsOneWidget);
      expect(find.text('Tiếp tục chỉnh sửa'), findsOneWidget);

      // Tap 'Tiếp tục chỉnh sửa' -> keeps user on StudentFormPage
      await tester.tap(find.text('Tiếp tục chỉnh sửa'));
      await tester.pumpAndSettle();

      expect(find.byType(StudentFormPage), findsOneWidget);
    });

    testWidgets('StudentFormPage prompt allows discarding changes and leaving page', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          home: const Scaffold(body: StudentFormPage()),
        ),
      );

      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'Nguyễn Văn Test');
      await tester.pumpAndSettle();

      // Pop route
      final dynamic widgetsAppState = tester.state(find.byType(WidgetsApp));
      widgetsAppState.didPopRoute();
      await tester.pumpAndSettle();

      // Tap 'Bỏ thay đổi' -> discards and pops route
      await tester.tap(find.text('Bỏ thay đổi'));
      await tester.pumpAndSettle();

      expect(find.byType(StudentFormPage), findsNothing);
    });
  });
}
