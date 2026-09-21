// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$classSessionControllerHash() =>
    r'f94f79425913015c588df8cd507f3d2dd3eaccd8';

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

abstract class _$ClassSessionController
    extends BuildlessAutoDisposeAsyncNotifier<List<ClassSession>> {
  late final int classId;

  FutureOr<List<ClassSession>> build(int classId);
}

/// See also [ClassSessionController].
@ProviderFor(ClassSessionController)
const classSessionControllerProvider = ClassSessionControllerFamily();

/// See also [ClassSessionController].
class ClassSessionControllerFamily
    extends Family<AsyncValue<List<ClassSession>>> {
  /// See also [ClassSessionController].
  const ClassSessionControllerFamily();

  /// See also [ClassSessionController].
  ClassSessionControllerProvider call(int classId) {
    return ClassSessionControllerProvider(classId);
  }

  @override
  ClassSessionControllerProvider getProviderOverride(
    covariant ClassSessionControllerProvider provider,
  ) {
    return call(provider.classId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'classSessionControllerProvider';
}

/// See also [ClassSessionController].
class ClassSessionControllerProvider
    extends
        AutoDisposeAsyncNotifierProviderImpl<
          ClassSessionController,
          List<ClassSession>
        > {
  /// See also [ClassSessionController].
  ClassSessionControllerProvider(int classId)
    : this._internal(
        () => ClassSessionController()..classId = classId,
        from: classSessionControllerProvider,
        name: r'classSessionControllerProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$classSessionControllerHash,
        dependencies: ClassSessionControllerFamily._dependencies,
        allTransitiveDependencies:
            ClassSessionControllerFamily._allTransitiveDependencies,
        classId: classId,
      );

  ClassSessionControllerProvider._internal(
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
  FutureOr<List<ClassSession>> runNotifierBuild(
    covariant ClassSessionController notifier,
  ) {
    return notifier.build(classId);
  }

  @override
  Override overrideWith(ClassSessionController Function() create) {
    return ProviderOverride(
      origin: this,
      override: ClassSessionControllerProvider._internal(
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
  AutoDisposeAsyncNotifierProviderElement<
    ClassSessionController,
    List<ClassSession>
  >
  createElement() {
    return _ClassSessionControllerProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ClassSessionControllerProvider && other.classId == classId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, classId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin ClassSessionControllerRef
    on AutoDisposeAsyncNotifierProviderRef<List<ClassSession>> {
  /// The parameter `classId` of this provider.
  int get classId;
}

class _ClassSessionControllerProviderElement
    extends
        AutoDisposeAsyncNotifierProviderElement<
          ClassSessionController,
          List<ClassSession>
        >
    with ClassSessionControllerRef {
  _ClassSessionControllerProviderElement(super.provider);

  @override
  int get classId => (origin as ClassSessionControllerProvider).classId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
