// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'schedule_conflict_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$scheduleConstraintRepositoryHash() =>
    r'b25949327b27573ca3b37301a945044c3473c646';

/// See also [scheduleConstraintRepository].
@ProviderFor(scheduleConstraintRepository)
final scheduleConstraintRepositoryProvider =
    FutureProvider<ScheduleConstraintRepository>.internal(
      scheduleConstraintRepository,
      name: r'scheduleConstraintRepositoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$scheduleConstraintRepositoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef ScheduleConstraintRepositoryRef =
    FutureProviderRef<ScheduleConstraintRepository>;
String _$scheduleConflictServiceHash() =>
    r'd0cb19b0f08ee8d369b6bf683171e0a2a3bce471';

/// See also [scheduleConflictService].
@ProviderFor(scheduleConflictService)
final scheduleConflictServiceProvider =
    FutureProvider<ScheduleConflictService>.internal(
      scheduleConflictService,
      name: r'scheduleConflictServiceProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$scheduleConflictServiceHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef ScheduleConflictServiceRef = FutureProviderRef<ScheduleConflictService>;
String _$studentConstraintsHash() =>
    r'ca9183f2c5e450a6d6a220006535dddce147b65f';

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

/// See also [studentConstraints].
@ProviderFor(studentConstraints)
const studentConstraintsProvider = StudentConstraintsFamily();

/// See also [studentConstraints].
class StudentConstraintsFamily
    extends Family<AsyncValue<List<ScheduleConstraint>>> {
  /// See also [studentConstraints].
  const StudentConstraintsFamily();

  /// See also [studentConstraints].
  StudentConstraintsProvider call(int studentId) {
    return StudentConstraintsProvider(studentId);
  }

  @override
  StudentConstraintsProvider getProviderOverride(
    covariant StudentConstraintsProvider provider,
  ) {
    return call(provider.studentId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'studentConstraintsProvider';
}

/// See also [studentConstraints].
class StudentConstraintsProvider
    extends AutoDisposeFutureProvider<List<ScheduleConstraint>> {
  /// See also [studentConstraints].
  StudentConstraintsProvider(int studentId)
    : this._internal(
        (ref) => studentConstraints(ref as StudentConstraintsRef, studentId),
        from: studentConstraintsProvider,
        name: r'studentConstraintsProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$studentConstraintsHash,
        dependencies: StudentConstraintsFamily._dependencies,
        allTransitiveDependencies:
            StudentConstraintsFamily._allTransitiveDependencies,
        studentId: studentId,
      );

  StudentConstraintsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.studentId,
  }) : super.internal();

  final int studentId;

  @override
  Override overrideWith(
    FutureOr<List<ScheduleConstraint>> Function(StudentConstraintsRef provider)
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: StudentConstraintsProvider._internal(
        (ref) => create(ref as StudentConstraintsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        studentId: studentId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<ScheduleConstraint>> createElement() {
    return _StudentConstraintsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is StudentConstraintsProvider && other.studentId == studentId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, studentId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin StudentConstraintsRef
    on AutoDisposeFutureProviderRef<List<ScheduleConstraint>> {
  /// The parameter `studentId` of this provider.
  int get studentId;
}

class _StudentConstraintsProviderElement
    extends AutoDisposeFutureProviderElement<List<ScheduleConstraint>>
    with StudentConstraintsRef {
  _StudentConstraintsProviderElement(super.provider);

  @override
  int get studentId => (origin as StudentConstraintsProvider).studentId;
}

String _$assignmentConflictPreviewHash() =>
    r'364c063c384fa3fb0a5f63a10ba1fff719f8e87f';

/// See also [assignmentConflictPreview].
@ProviderFor(assignmentConflictPreview)
const assignmentConflictPreviewProvider = AssignmentConflictPreviewFamily();

/// See also [assignmentConflictPreview].
class AssignmentConflictPreviewFamily
    extends Family<AsyncValue<ScheduleConflictResult>> {
  /// See also [assignmentConflictPreview].
  const AssignmentConflictPreviewFamily();

  /// See also [assignmentConflictPreview].
  AssignmentConflictPreviewProvider call(
    (int, int, String, String?, int?) arg,
  ) {
    return AssignmentConflictPreviewProvider(arg);
  }

  @override
  AssignmentConflictPreviewProvider getProviderOverride(
    covariant AssignmentConflictPreviewProvider provider,
  ) {
    return call(provider.arg);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'assignmentConflictPreviewProvider';
}

/// See also [assignmentConflictPreview].
class AssignmentConflictPreviewProvider
    extends AutoDisposeFutureProvider<ScheduleConflictResult> {
  /// See also [assignmentConflictPreview].
  AssignmentConflictPreviewProvider((int, int, String, String?, int?) arg)
    : this._internal(
        (ref) =>
            assignmentConflictPreview(ref as AssignmentConflictPreviewRef, arg),
        from: assignmentConflictPreviewProvider,
        name: r'assignmentConflictPreviewProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$assignmentConflictPreviewHash,
        dependencies: AssignmentConflictPreviewFamily._dependencies,
        allTransitiveDependencies:
            AssignmentConflictPreviewFamily._allTransitiveDependencies,
        arg: arg,
      );

  AssignmentConflictPreviewProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.arg,
  }) : super.internal();

  final (int, int, String, String?, int?) arg;

  @override
  Override overrideWith(
    FutureOr<ScheduleConflictResult> Function(
      AssignmentConflictPreviewRef provider,
    )
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: AssignmentConflictPreviewProvider._internal(
        (ref) => create(ref as AssignmentConflictPreviewRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        arg: arg,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<ScheduleConflictResult> createElement() {
    return _AssignmentConflictPreviewProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is AssignmentConflictPreviewProvider && other.arg == arg;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, arg.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin AssignmentConflictPreviewRef
    on AutoDisposeFutureProviderRef<ScheduleConflictResult> {
  /// The parameter `arg` of this provider.
  (int, int, String, String?, int?) get arg;
}

class _AssignmentConflictPreviewProviderElement
    extends AutoDisposeFutureProviderElement<ScheduleConflictResult>
    with AssignmentConflictPreviewRef {
  _AssignmentConflictPreviewProviderElement(super.provider);

  @override
  (int, int, String, String?, int?) get arg =>
      (origin as AssignmentConflictPreviewProvider).arg;
}

String _$oneOffConflictPreviewHash() =>
    r'9f0f6546bc16270ec221bab7c8ef7af6385b26fd';

/// See also [oneOffConflictPreview].
@ProviderFor(oneOffConflictPreview)
const oneOffConflictPreviewProvider = OneOffConflictPreviewFamily();

/// See also [oneOffConflictPreview].
class OneOffConflictPreviewFamily
    extends Family<AsyncValue<ScheduleConflictResult>> {
  /// See also [oneOffConflictPreview].
  const OneOffConflictPreviewFamily();

  /// See also [oneOffConflictPreview].
  OneOffConflictPreviewProvider call((int, String, String, String, int?) arg) {
    return OneOffConflictPreviewProvider(arg);
  }

  @override
  OneOffConflictPreviewProvider getProviderOverride(
    covariant OneOffConflictPreviewProvider provider,
  ) {
    return call(provider.arg);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'oneOffConflictPreviewProvider';
}

/// See also [oneOffConflictPreview].
class OneOffConflictPreviewProvider
    extends AutoDisposeFutureProvider<ScheduleConflictResult> {
  /// See also [oneOffConflictPreview].
  OneOffConflictPreviewProvider((int, String, String, String, int?) arg)
    : this._internal(
        (ref) => oneOffConflictPreview(ref as OneOffConflictPreviewRef, arg),
        from: oneOffConflictPreviewProvider,
        name: r'oneOffConflictPreviewProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$oneOffConflictPreviewHash,
        dependencies: OneOffConflictPreviewFamily._dependencies,
        allTransitiveDependencies:
            OneOffConflictPreviewFamily._allTransitiveDependencies,
        arg: arg,
      );

  OneOffConflictPreviewProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.arg,
  }) : super.internal();

  final (int, String, String, String, int?) arg;

  @override
  Override overrideWith(
    FutureOr<ScheduleConflictResult> Function(OneOffConflictPreviewRef provider)
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: OneOffConflictPreviewProvider._internal(
        (ref) => create(ref as OneOffConflictPreviewRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        arg: arg,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<ScheduleConflictResult> createElement() {
    return _OneOffConflictPreviewProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is OneOffConflictPreviewProvider && other.arg == arg;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, arg.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin OneOffConflictPreviewRef
    on AutoDisposeFutureProviderRef<ScheduleConflictResult> {
  /// The parameter `arg` of this provider.
  (int, String, String, String, int?) get arg;
}

class _OneOffConflictPreviewProviderElement
    extends AutoDisposeFutureProviderElement<ScheduleConflictResult>
    with OneOffConflictPreviewRef {
  _OneOffConflictPreviewProviderElement(super.provider);

  @override
  (int, String, String, String, int?) get arg =>
      (origin as OneOffConflictPreviewProvider).arg;
}

String _$scheduleConstraintControllerHash() =>
    r'64e0b20253041f92a2d3a2c7c9647ed6a66b21ee';

/// See also [ScheduleConstraintController].
@ProviderFor(ScheduleConstraintController)
final scheduleConstraintControllerProvider =
    AsyncNotifierProvider<ScheduleConstraintController, void>.internal(
      ScheduleConstraintController.new,
      name: r'scheduleConstraintControllerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$scheduleConstraintControllerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$ScheduleConstraintController = AsyncNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
