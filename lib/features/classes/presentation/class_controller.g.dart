// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'class_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$classDetailHash() => r'a8a2a1437ea9a6bf39c4ab0a8492d6cfd3f16dd0';

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

/// See also [classDetail].
@ProviderFor(classDetail)
const classDetailProvider = ClassDetailFamily();

/// See also [classDetail].
class ClassDetailFamily extends Family<AsyncValue<ClassEntity?>> {
  /// See also [classDetail].
  const ClassDetailFamily();

  /// See also [classDetail].
  ClassDetailProvider call(int id) {
    return ClassDetailProvider(id);
  }

  @override
  ClassDetailProvider getProviderOverride(
    covariant ClassDetailProvider provider,
  ) {
    return call(provider.id);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'classDetailProvider';
}

/// See also [classDetail].
class ClassDetailProvider extends AutoDisposeFutureProvider<ClassEntity?> {
  /// See also [classDetail].
  ClassDetailProvider(int id)
    : this._internal(
        (ref) => classDetail(ref as ClassDetailRef, id),
        from: classDetailProvider,
        name: r'classDetailProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$classDetailHash,
        dependencies: ClassDetailFamily._dependencies,
        allTransitiveDependencies: ClassDetailFamily._allTransitiveDependencies,
        id: id,
      );

  ClassDetailProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.id,
  }) : super.internal();

  final int id;

  @override
  Override overrideWith(
    FutureOr<ClassEntity?> Function(ClassDetailRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ClassDetailProvider._internal(
        (ref) => create(ref as ClassDetailRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        id: id,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<ClassEntity?> createElement() {
    return _ClassDetailProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ClassDetailProvider && other.id == id;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, id.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin ClassDetailRef on AutoDisposeFutureProviderRef<ClassEntity?> {
  /// The parameter `id` of this provider.
  int get id;
}

class _ClassDetailProviderElement
    extends AutoDisposeFutureProviderElement<ClassEntity?>
    with ClassDetailRef {
  _ClassDetailProviderElement(super.provider);

  @override
  int get id => (origin as ClassDetailProvider).id;
}

String _$classListControllerHash() =>
    r'0ef9ab73add1be0da2b0e76c9fa54d4ee3290179';

/// See also [ClassListController].
@ProviderFor(ClassListController)
final classListControllerProvider =
    AutoDisposeAsyncNotifierProvider<
      ClassListController,
      List<ClassEntity>
    >.internal(
      ClassListController.new,
      name: r'classListControllerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$classListControllerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$ClassListController = AutoDisposeAsyncNotifier<List<ClassEntity>>;
String _$classFormControllerHash() =>
    r'94f485b96b14c8381981de2362d55058bbc46261';

/// See also [ClassFormController].
@ProviderFor(ClassFormController)
final classFormControllerProvider =
    AutoDisposeNotifierProvider<ClassFormController, void>.internal(
      ClassFormController.new,
      name: r'classFormControllerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$classFormControllerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$ClassFormController = AutoDisposeNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
