// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attendance_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$attendanceControllerHash() =>
    r'e5b4ba7943f7bf31efac6f0d35b0033ccb6867a1';

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

abstract class _$AttendanceController
    extends BuildlessAutoDisposeAsyncNotifier<AttendanceSheet> {
  late final int sessionId;

  FutureOr<AttendanceSheet> build(int sessionId);
}

/// See also [AttendanceController].
@ProviderFor(AttendanceController)
const attendanceControllerProvider = AttendanceControllerFamily();

/// See also [AttendanceController].
class AttendanceControllerFamily extends Family<AsyncValue<AttendanceSheet>> {
  /// See also [AttendanceController].
  const AttendanceControllerFamily();

  /// See also [AttendanceController].
  AttendanceControllerProvider call(int sessionId) {
    return AttendanceControllerProvider(sessionId);
  }

  @override
  AttendanceControllerProvider getProviderOverride(
    covariant AttendanceControllerProvider provider,
  ) {
    return call(provider.sessionId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'attendanceControllerProvider';
}

/// See also [AttendanceController].
class AttendanceControllerProvider
    extends
        AutoDisposeAsyncNotifierProviderImpl<
          AttendanceController,
          AttendanceSheet
        > {
  /// See also [AttendanceController].
  AttendanceControllerProvider(int sessionId)
    : this._internal(
        () => AttendanceController()..sessionId = sessionId,
        from: attendanceControllerProvider,
        name: r'attendanceControllerProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$attendanceControllerHash,
        dependencies: AttendanceControllerFamily._dependencies,
        allTransitiveDependencies:
            AttendanceControllerFamily._allTransitiveDependencies,
        sessionId: sessionId,
      );

  AttendanceControllerProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.sessionId,
  }) : super.internal();

  final int sessionId;

  @override
  FutureOr<AttendanceSheet> runNotifierBuild(
    covariant AttendanceController notifier,
  ) {
    return notifier.build(sessionId);
  }

  @override
  Override overrideWith(AttendanceController Function() create) {
    return ProviderOverride(
      origin: this,
      override: AttendanceControllerProvider._internal(
        () => create()..sessionId = sessionId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        sessionId: sessionId,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<AttendanceController, AttendanceSheet>
  createElement() {
    return _AttendanceControllerProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is AttendanceControllerProvider &&
        other.sessionId == sessionId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, sessionId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin AttendanceControllerRef
    on AutoDisposeAsyncNotifierProviderRef<AttendanceSheet> {
  /// The parameter `sessionId` of this provider.
  int get sessionId;
}

class _AttendanceControllerProviderElement
    extends
        AutoDisposeAsyncNotifierProviderElement<
          AttendanceController,
          AttendanceSheet
        >
    with AttendanceControllerRef {
  _AttendanceControllerProviderElement(super.provider);

  @override
  int get sessionId => (origin as AttendanceControllerProvider).sessionId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
