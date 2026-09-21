import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuition2027/features/classes/presentation/class_list_page.dart';
import 'package:tuition2027/features/classes/presentation/class_controller.dart';
import 'package:tuition2027/features/classes/domain/class_service.dart';
import 'package:tuition2027/features/classes/domain/class.dart';
import 'package:tuition2027/features/memberships/domain/membership_service.dart';
import 'package:tuition2027/features/memberships/presentation/membership_providers.dart';

void main() {
  testWidgets('ClassListPage shows active classes by default', (tester) async {
    final activeClass = ClassEntity(id: 2, tenLop: 'Active Class', daLuuTru: false, createdAt: DateTime.now(), updatedAt: DateTime.now());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          classListControllerProvider.overrideWith(() => MockClassListController([activeClass])),
          classSizeProvider.overrideWith((ref, id) => 5),
        ],
        child: const MaterialApp(home: ClassListPage()),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Active Class'), findsOneWidget);
  });
}

class MockClassListController extends ClassListController {
  final List<ClassEntity> classes;
  MockClassListController(this.classes);

  @override
  FutureOr<List<ClassEntity>> build() => classes;
}
