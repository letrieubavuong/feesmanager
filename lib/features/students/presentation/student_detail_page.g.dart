// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'student_detail_page.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$studentDetailHash() => r'ba0de423e0ee292582538a28255294a4f068a107';

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

/// See also [studentDetail].
@ProviderFor(studentDetail)
const studentDetailProvider = StudentDetailFamily();

/// See also [studentDetail].
class StudentDetailFamily extends Family<AsyncValue<Student?>> {
  /// See also [studentDetail].
  const StudentDetailFamily();

  /// See also [studentDetail].
  StudentDetailProvider call(
    int id,
  ) {
    return StudentDetailProvider(
      id,
    );
  }

  @override
  StudentDetailProvider getProviderOverride(
    covariant StudentDetailProvider provider,
  ) {
    return call(
      provider.id,
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
  String? get name => r'studentDetailProvider';
}

/// See also [studentDetail].
class StudentDetailProvider extends AutoDisposeFutureProvider<Student?> {
  /// See also [studentDetail].
  StudentDetailProvider(
    int id,
  ) : this._internal(
          (ref) => studentDetail(
            ref as StudentDetailRef,
            id,
          ),
          from: studentDetailProvider,
          name: r'studentDetailProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$studentDetailHash,
          dependencies: StudentDetailFamily._dependencies,
          allTransitiveDependencies:
              StudentDetailFamily._allTransitiveDependencies,
          id: id,
        );

  StudentDetailProvider._internal(
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
    FutureOr<Student?> Function(StudentDetailRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: StudentDetailProvider._internal(
        (ref) => create(ref as StudentDetailRef),
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
  AutoDisposeFutureProviderElement<Student?> createElement() {
    return _StudentDetailProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is StudentDetailProvider && other.id == id;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, id.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin StudentDetailRef on AutoDisposeFutureProviderRef<Student?> {
  /// The parameter `id` of this provider.
  int get id;
}

class _StudentDetailProviderElement
    extends AutoDisposeFutureProviderElement<Student?> with StudentDetailRef {
  _StudentDetailProviderElement(super.provider);

  @override
  int get id => (origin as StudentDetailProvider).id;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
