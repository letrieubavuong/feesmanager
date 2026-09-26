// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'student_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$studentListControllerHash() =>
    r'629e6b304196a6a7b7fb4636f24b9759943c9bc9';

/// See also [StudentListController].
@ProviderFor(StudentListController)
final studentListControllerProvider =
    AutoDisposeAsyncNotifierProvider<
      StudentListController,
      List<Student>
    >.internal(
      StudentListController.new,
      name: r'studentListControllerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$studentListControllerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$StudentListController = AutoDisposeAsyncNotifier<List<Student>>;
String _$studentFormControllerHash() =>
    r'8420301bf06469a141c05e355681763ea1cf3951';

/// See also [StudentFormController].
@ProviderFor(StudentFormController)
final studentFormControllerProvider =
    AutoDisposeNotifierProvider<StudentFormController, void>.internal(
      StudentFormController.new,
      name: r'studentFormControllerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$studentFormControllerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$StudentFormController = AutoDisposeNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
