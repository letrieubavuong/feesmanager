// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'student_detail_overview_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$studentDetailOverviewServiceHash() =>
    r'd2785c87f90b800787ba6dea800103d333f8915d';

/// See also [studentDetailOverviewService].
@ProviderFor(studentDetailOverviewService)
final studentDetailOverviewServiceProvider =
    AutoDisposeFutureProvider<StudentDetailOverviewService>.internal(
  studentDetailOverviewService,
  name: r'studentDetailOverviewServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$studentDetailOverviewServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef StudentDetailOverviewServiceRef
    = AutoDisposeFutureProviderRef<StudentDetailOverviewService>;
String _$studentDetailOverviewHash() =>
    r'6a4e53f47f4b46450f487d054b1e87788c8a447c';

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

/// See also [studentDetailOverview].
@ProviderFor(studentDetailOverview)
const studentDetailOverviewProvider = StudentDetailOverviewFamily();

/// See also [studentDetailOverview].
class StudentDetailOverviewFamily
    extends Family<AsyncValue<StudentDetailOverview>> {
  /// See also [studentDetailOverview].
  const StudentDetailOverviewFamily();

  /// See also [studentDetailOverview].
  StudentDetailOverviewProvider call(
    int studentId,
  ) {
    return StudentDetailOverviewProvider(
      studentId,
    );
  }

  @override
  StudentDetailOverviewProvider getProviderOverride(
    covariant StudentDetailOverviewProvider provider,
  ) {
    return call(
      provider.studentId,
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
  String? get name => r'studentDetailOverviewProvider';
}

/// See also [studentDetailOverview].
class StudentDetailOverviewProvider
    extends AutoDisposeFutureProvider<StudentDetailOverview> {
  /// See also [studentDetailOverview].
  StudentDetailOverviewProvider(
    int studentId,
  ) : this._internal(
          (ref) => studentDetailOverview(
            ref as StudentDetailOverviewRef,
            studentId,
          ),
          from: studentDetailOverviewProvider,
          name: r'studentDetailOverviewProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$studentDetailOverviewHash,
          dependencies: StudentDetailOverviewFamily._dependencies,
          allTransitiveDependencies:
              StudentDetailOverviewFamily._allTransitiveDependencies,
          studentId: studentId,
        );

  StudentDetailOverviewProvider._internal(
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
    FutureOr<StudentDetailOverview> Function(StudentDetailOverviewRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: StudentDetailOverviewProvider._internal(
        (ref) => create(ref as StudentDetailOverviewRef),
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
  AutoDisposeFutureProviderElement<StudentDetailOverview> createElement() {
    return _StudentDetailOverviewProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is StudentDetailOverviewProvider &&
        other.studentId == studentId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, studentId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin StudentDetailOverviewRef
    on AutoDisposeFutureProviderRef<StudentDetailOverview> {
  /// The parameter `studentId` of this provider.
  int get studentId;
}

class _StudentDetailOverviewProviderElement
    extends AutoDisposeFutureProviderElement<StudentDetailOverview>
    with StudentDetailOverviewRef {
  _StudentDetailOverviewProviderElement(super.provider);

  @override
  int get studentId => (origin as StudentDetailOverviewProvider).studentId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
