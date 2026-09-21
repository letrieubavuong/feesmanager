import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuition2027/features/classes/presentation/class_list_page.dart';
import 'package:tuition2027/features/classes/presentation/class_controller.dart';
import 'package:tuition2027/features/classes/domain/class.dart';
import 'package:tuition2027/features/classes/domain/class_filter.dart';
import 'package:tuition2027/features/memberships/presentation/membership_providers.dart';

void main() {
  testWidgets('ClassListPage shows active classes by default', (tester) async {
    final activeClass = ClassEntity(
      id: 2,
      tenLop: 'Active Class',
      daLuuTru: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          classListControllerProvider.overrideWith(
            () => MockClassListController([activeClass]),
          ),
          classSizeProvider.overrideWith((ref, id) => 5),
        ],
        child: const MaterialApp(home: ClassListPage()),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Active Class'), findsOneWidget);
  });

  testWidgets('ClassListPage filter works (Archived)', (tester) async {
    final archivedClass = ClassEntity(
      id: 1,
      tenLop: 'Archived Class',
      daLuuTru: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final controller = MockClassListController([]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          classListControllerProvider.overrideWith(() => controller),
          classSizeProvider.overrideWith((ref, id) => 5),
        ],
        child: const MaterialApp(home: ClassListPage()),
      ),
    );

    await tester.pumpAndSettle();

    // Change filter via UI
    await tester.tap(find.byIcon(Icons.filter_list));
    await tester.pumpAndSettle();

    // Inject archived data for mock
    controller.data = [archivedClass];

    await tester.tap(find.text('Đã lưu trữ'));
    await tester.pumpAndSettle();

    expect(find.text('Archived Class'), findsOneWidget);
  });
}

class MockClassListController extends ClassListController {
  List<ClassEntity> data;
  MockClassListController(this.data);

  @override
  FutureOr<List<ClassEntity>> build() => data;

  @override
  void setFilter(ClassFilter filter) {
    // In real controller this triggers rebuild, in mock we just simulate if needed
    ref.invalidateSelf();
  }
}
