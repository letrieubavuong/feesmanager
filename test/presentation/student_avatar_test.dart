import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuition2027/app/common_widgets/student_avatar.dart';

void main() {
  group('StudentAvatar Widget Tests', () {
    testWidgets('NAM renders male icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: StudentAvatar(gioiTinh: 'NAM')),
        ),
      );

      expect(find.byIcon(Icons.face_5_outlined), findsOneWidget);
    });

    testWidgets('NU renders female icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: StudentAvatar(gioiTinh: 'NU')),
        ),
      );

      expect(find.byIcon(Icons.face_2_outlined), findsOneWidget);
    });

    testWidgets('KHAC/null renders neutral person icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: StudentAvatar(gioiTinh: null))),
      );

      expect(find.byIcon(Icons.person_outline_rounded), findsOneWidget);
    });
  });
}
