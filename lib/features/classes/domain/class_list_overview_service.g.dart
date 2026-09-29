// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'class_list_overview_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$classListOverviewServiceHash() =>
    r'8b1a24d396796265aea698a893369ec4408ba1d7';

/// See also [classListOverviewService].
@ProviderFor(classListOverviewService)
final classListOverviewServiceProvider =
    AutoDisposeFutureProvider<ClassListOverviewService>.internal(
      classListOverviewService,
      name: r'classListOverviewServiceProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$classListOverviewServiceHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef ClassListOverviewServiceRef =
    AutoDisposeFutureProviderRef<ClassListOverviewService>;
String _$classListOverviewHash() => r'e13d745cf75b304df77b471f95746e10fbad7506';

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

/// See also [classListOverview].
@ProviderFor(classListOverview)
const classListOverviewProvider = ClassListOverviewFamily();

/// See also [classListOverview].
class ClassListOverviewFamily extends Family<AsyncValue<ClassListOverview>> {
  /// See also [classListOverview].
  const ClassListOverviewFamily();

  /// See also [classListOverview].
  ClassListOverviewProvider call(ClassFilter filter) {
    return ClassListOverviewProvider(filter);
  }

  @override
  ClassListOverviewProvider getProviderOverride(
    covariant ClassListOverviewProvider provider,
  ) {
    return call(provider.filter);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'classListOverviewProvider';
}

/// See also [classListOverview].
class ClassListOverviewProvider
    extends AutoDisposeFutureProvider<ClassListOverview> {
  /// See also [classListOverview].
  ClassListOverviewProvider(ClassFilter filter)
    : this._internal(
        (ref) => classListOverview(ref as ClassListOverviewRef, filter),
        from: classListOverviewProvider,
        name: r'classListOverviewProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$classListOverviewHash,
        dependencies: ClassListOverviewFamily._dependencies,
        allTransitiveDependencies:
            ClassListOverviewFamily._allTransitiveDependencies,
        filter: filter,
      );

  ClassListOverviewProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.filter,
  }) : super.internal();

  final ClassFilter filter;

  @override
  Override overrideWith(
    FutureOr<ClassListOverview> Function(ClassListOverviewRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ClassListOverviewProvider._internal(
        (ref) => create(ref as ClassListOverviewRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        filter: filter,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<ClassListOverview> createElement() {
    return _ClassListOverviewProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ClassListOverviewProvider && other.filter == filter;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, filter.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin ClassListOverviewRef on AutoDisposeFutureProviderRef<ClassListOverview> {
  /// The parameter `filter` of this provider.
  ClassFilter get filter;
}

class _ClassListOverviewProviderElement
    extends AutoDisposeFutureProviderElement<ClassListOverview>
    with ClassListOverviewRef {
  _ClassListOverviewProviderElement(super.provider);

  @override
  ClassFilter get filter => (origin as ClassListOverviewProvider).filter;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
