// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'parent_tuition_slip_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$parentTuitionSlipHash() => r'9b523aa06d679ca4f19c9cd91533931417108f6c';

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

/// See also [parentTuitionSlip].
@ProviderFor(parentTuitionSlip)
const parentTuitionSlipProvider = ParentTuitionSlipFamily();

/// See also [parentTuitionSlip].
class ParentTuitionSlipFamily extends Family<AsyncValue<ParentTuitionSlip>> {
  /// See also [parentTuitionSlip].
  const ParentTuitionSlipFamily();

  /// See also [parentTuitionSlip].
  ParentTuitionSlipProvider call(
    (int, int, String) arg,
  ) {
    return ParentTuitionSlipProvider(
      arg,
    );
  }

  @override
  ParentTuitionSlipProvider getProviderOverride(
    covariant ParentTuitionSlipProvider provider,
  ) {
    return call(
      provider.arg,
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
  String? get name => r'parentTuitionSlipProvider';
}

/// See also [parentTuitionSlip].
class ParentTuitionSlipProvider
    extends AutoDisposeFutureProvider<ParentTuitionSlip> {
  /// See also [parentTuitionSlip].
  ParentTuitionSlipProvider(
    (int, int, String) arg,
  ) : this._internal(
          (ref) => parentTuitionSlip(
            ref as ParentTuitionSlipRef,
            arg,
          ),
          from: parentTuitionSlipProvider,
          name: r'parentTuitionSlipProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$parentTuitionSlipHash,
          dependencies: ParentTuitionSlipFamily._dependencies,
          allTransitiveDependencies:
              ParentTuitionSlipFamily._allTransitiveDependencies,
          arg: arg,
        );

  ParentTuitionSlipProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.arg,
  }) : super.internal();

  final (int, int, String) arg;

  @override
  Override overrideWith(
    FutureOr<ParentTuitionSlip> Function(ParentTuitionSlipRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ParentTuitionSlipProvider._internal(
        (ref) => create(ref as ParentTuitionSlipRef),
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
  AutoDisposeFutureProviderElement<ParentTuitionSlip> createElement() {
    return _ParentTuitionSlipProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ParentTuitionSlipProvider && other.arg == arg;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, arg.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin ParentTuitionSlipRef on AutoDisposeFutureProviderRef<ParentTuitionSlip> {
  /// The parameter `arg` of this provider.
  (int, int, String) get arg;
}

class _ParentTuitionSlipProviderElement
    extends AutoDisposeFutureProviderElement<ParentTuitionSlip>
    with ParentTuitionSlipRef {
  _ParentTuitionSlipProviderElement(super.provider);

  @override
  (int, int, String) get arg => (origin as ParentTuitionSlipProvider).arg;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
