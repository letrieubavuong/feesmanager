import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuition2027/features/classes/domain/class.dart';
import 'package:tuition2027/features/classes/domain/class_filter.dart';
import 'package:tuition2027/features/classes/presentation/class_controller.dart';
import 'package:tuition2027/features/classes/presentation/class_list_page.dart';
import 'package:tuition2027/features/memberships/presentation/membership_providers.dart';
import '../test_helper.dart';

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
      createTestApp(
        home: const ClassListPage(),
        overrides: [
          classListControllerProvider.overrideWith(
            () => MockClassListController([activeClass]),
          ),
          classSizeProvider.overrideWith((ref, id) => 5),
        ],
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
      createTestApp(
        home: const ClassListPage(),
        overrides: [
          classListControllerProvider.overrideWith(() => controller),
          classSizeProvider.overrideWith((ref, id) => 5),
        ],
      ),
    );

    await tester.pumpAndSettle();

    // Inject archived data for mock
    controller.data = [archivedClass];

    // Tap FilterChip 'Đã lưu trữ'
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
    ref.invalidateSelf();
  }
}
