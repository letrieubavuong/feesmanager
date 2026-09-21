// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'assignment_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$classAssignmentControllerHash() =>
    r'0aed890afdc1d42683246f9df0d6cbb825b2ce81';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

abstract class _$ClassAssignmentController
    extends BuildlessAutoDisposeAsyncNotifier<List<StudentShiftAssignment>> {
  late final int classId;

  FutureOr<List<StudentShiftAssignment>> build(
    int classId,
  );
}

/// See also [ClassAssignmentController].
@ProviderFor(ClassAssignmentController)
const classAssignmentControllerProvider = ClassAssignmentControllerFamily();

/// See also [ClassAssignmentController].
class ClassAssignmentControllerFamily
    extends Family<AsyncValue<List<StudentShiftAssignment>>> {
  /// See also [ClassAssignmentController].
  const ClassAssignmentControllerFamily();

  /// See also [ClassAssignmentController].
  ClassAssignmentControllerProvider call(
    int classId,
  ) {
    return ClassAssignmentControllerProvider(
      classId,
    );
  }

  @override
  ClassAssignmentControllerProvider getProviderOverride(
    covariant ClassAssignmentControllerProvider provider,
  ) {
    return call(
      provider.classId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'classAssignmentControllerProvider';
}

/// See also [ClassAssignmentController].
class ClassAssignmentControllerProvider
    extends AutoDisposeAsyncNotifierProviderImpl<ClassAssignmentController,
        List<StudentShiftAssignment>> {
  /// See also [ClassAssignmentController].
  ClassAssignmentControllerProvider(
    int classId,
  ) : this._internal(
          () => ClassAssignmentController()..classId = classId,
          from: classAssignmentControllerProvider,
          name: r'classAssignmentControllerProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$classAssignmentControllerHash,
          dependencies: ClassAssignmentControllerFamily._dependencies,
          allTransitiveDependencies:
              ClassAssignmentControllerFamily._allTransitiveDependencies,
          classId: classId,
        );

  ClassAssignmentControllerProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.classId,
  }) : super.internal();

  final int classId;

  @override
  FutureOr<List<StudentShiftAssignment>> runNotifierBuild(
    covariant ClassAssignmentController notifier,
  ) {
    return notifier.build(
      classId,
    );
  }

  @override
  Override overrideWith(ClassAssignmentController Function() create) {
    return ProviderOverride(
      origin: this,
      override: ClassAssignmentControllerProvider._internal(
        () => create()..classId = classId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        classId: classId,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<ClassAssignmentController,
      List<StudentShiftAssignment>> createElement() {
    return _ClassAssignmentControllerProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ClassAssignmentControllerProvider &&
        other.classId == classId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, classId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin ClassAssignmentControllerRef
    on AutoDisposeAsyncNotifierProviderRef<List<StudentShiftAssignment>> {
  /// The parameter `classId` of this provider.
  int get classId;
}

class _ClassAssignmentControllerProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<ClassAssignmentController,
        List<StudentShiftAssignment>> with ClassAssignmentControllerRef {
  _ClassAssignmentControllerProviderElement(super.provider);

  @override
  int get classId => (origin as ClassAssignmentControllerProvider).classId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
