import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuition2027/app/common_widgets/app_empty_state.dart';
import 'package:tuition2027/app/common_widgets/app_error_state.dart';
import 'package:tuition2027/app/common_widgets/app_loading_state.dart';

void main() {
  group('Phase 13A Standard UI States Component Tests', () {
    testWidgets(
      'AppLoadingState renders progress indicator and optional message',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: AppLoadingState(message: 'Đang xử lý...')),
          ),
        );

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('Đang xử lý...'), findsOneWidget);
      },
    );

    testWidgets(
      'AppEmptyState renders icon, title, message and action button',
      (tester) async {
        bool actionTapped = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AppEmptyState(
                icon: Icons.inbox,
                title: 'Chưa có lớp học',
                message: 'Vui lòng bấm nút bên dưới để tạo lớp mới',
                actionLabel: 'Tạo lớp ngay',
                onAction: () => actionTapped = true,
              ),
            ),
          ),
        );

        expect(find.text('Chưa có lớp học'), findsOneWidget);
        expect(
          find.text('Vui lòng bấm nút bên dưới để tạo lớp mới'),
          findsOneWidget,
        );
        expect(find.text('Tạo lớp ngay'), findsOneWidget);

        await tester.tap(find.text('Tạo lớp ngay'));
        expect(actionTapped, isTrue);
      },
    );

    testWidgets('AppErrorState renders error message and retry button', (
      tester,
    ) async {
      bool retried = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppErrorState(
              error: 'Không thể kết nối SQLite',
              onRetry: () => retried = true,
            ),
          ),
        ),
      );

      expect(find.text('Đã xảy ra lỗi'), findsOneWidget);
      expect(find.text('Không thể kết nối SQLite'), findsOneWidget);
      expect(find.text('Thử lại'), findsOneWidget);

      await tester.tap(find.text('Thử lại'));
      expect(retried, isTrue);
    });
  });
}
