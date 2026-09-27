import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuition2027/app/common_widgets/student_avatar.dart';

void main() {
  group('StudentAvatar Widget Tests', () {
    testWidgets('NAM renders male avatar asset', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: StudentAvatar(gioiTinh: 'NAM')),
        ),
      );

      final imageFinder = find.byType(Image);
      expect(imageFinder, findsOneWidget);
      final imageWidget = tester.widget<Image>(imageFinder);
      expect((imageWidget.image as AssetImage).assetName, equals('assets/HSNam.png'));
    });

    testWidgets('NU renders female avatar asset', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: StudentAvatar(gioiTinh: 'NU')),
        ),
      );

      final imageFinder = find.byType(Image);
      expect(imageFinder, findsOneWidget);
      final imageWidget = tester.widget<Image>(imageFinder);
      expect((imageWidget.image as AssetImage).assetName, equals('assets/HSNu.png'));
    });

    testWidgets('KHAC/null renders neutral person icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: StudentAvatar(gioiTinh: null))),
      );

      expect(find.byIcon(Icons.person_outline_rounded), findsOneWidget);
    });
  });
}
