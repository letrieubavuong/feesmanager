// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'schedule_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$classScheduleControllerHash() =>
    r'422255639f58ab1363106415c664a5a21262f071';

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

abstract class _$ClassScheduleController
    extends BuildlessAutoDisposeAsyncNotifier<List<ClassSchedule>> {
  late final int classId;

  FutureOr<List<ClassSchedule>> build(
    int classId,
  );
}

/// See also [ClassScheduleController].
@ProviderFor(ClassScheduleController)
const classScheduleControllerProvider = ClassScheduleControllerFamily();

/// See also [ClassScheduleController].
class ClassScheduleControllerFamily
    extends Family<AsyncValue<List<ClassSchedule>>> {
  /// See also [ClassScheduleController].
  const ClassScheduleControllerFamily();

  /// See also [ClassScheduleController].
  ClassScheduleControllerProvider call(
    int classId,
  ) {
    return ClassScheduleControllerProvider(
      classId,
    );
  }

  @override
  ClassScheduleControllerProvider getProviderOverride(
    covariant ClassScheduleControllerProvider provider,
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
  String? get name => r'classScheduleControllerProvider';
}

/// See also [ClassScheduleController].
class ClassScheduleControllerProvider
    extends AutoDisposeAsyncNotifierProviderImpl<ClassScheduleController,
        List<ClassSchedule>> {
  /// See also [ClassScheduleController].
  ClassScheduleControllerProvider(
    int classId,
  ) : this._internal(
          () => ClassScheduleController()..classId = classId,
          from: classScheduleControllerProvider,
          name: r'classScheduleControllerProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$classScheduleControllerHash,
          dependencies: ClassScheduleControllerFamily._dependencies,
          allTransitiveDependencies:
              ClassScheduleControllerFamily._allTransitiveDependencies,
          classId: classId,
        );

  ClassScheduleControllerProvider._internal(
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
  FutureOr<List<ClassSchedule>> runNotifierBuild(
    covariant ClassScheduleController notifier,
  ) {
    return notifier.build(
      classId,
    );
  }

  @override
  Override overrideWith(ClassScheduleController Function() create) {
    return ProviderOverride(
      origin: this,
      override: ClassScheduleControllerProvider._internal(
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
  AutoDisposeAsyncNotifierProviderElement<ClassScheduleController,
      List<ClassSchedule>> createElement() {
    return _ClassScheduleControllerProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ClassScheduleControllerProvider && other.classId == classId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, classId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin ClassScheduleControllerRef
    on AutoDisposeAsyncNotifierProviderRef<List<ClassSchedule>> {
  /// The parameter `classId` of this provider.
  int get classId;
}

class _ClassScheduleControllerProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<ClassScheduleController,
        List<ClassSchedule>> with ClassScheduleControllerRef {
  _ClassScheduleControllerProviderElement(super.provider);

  @override
  int get classId => (origin as ClassScheduleControllerProvider).classId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
