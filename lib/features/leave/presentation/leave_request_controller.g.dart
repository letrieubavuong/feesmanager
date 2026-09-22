// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'leave_request_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$leaveRequestControllerHash() =>
    r'7c42a02779201633ccd3b69a7320f90520bad4b0';

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

abstract class _$LeaveRequestController
    extends BuildlessAutoDisposeAsyncNotifier<List<LeaveRequest>> {
  late final int classId;

  FutureOr<List<LeaveRequest>> build(int classId);
}

/// See also [LeaveRequestController].
@ProviderFor(LeaveRequestController)
const leaveRequestControllerProvider = LeaveRequestControllerFamily();

/// See also [LeaveRequestController].
class LeaveRequestControllerFamily
    extends Family<AsyncValue<List<LeaveRequest>>> {
  /// See also [LeaveRequestController].
  const LeaveRequestControllerFamily();

  /// See also [LeaveRequestController].
  LeaveRequestControllerProvider call(int classId) {
    return LeaveRequestControllerProvider(classId);
  }

  @override
  LeaveRequestControllerProvider getProviderOverride(
    covariant LeaveRequestControllerProvider provider,
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
  String? get name => r'leaveRequestControllerProvider';
}

/// See also [LeaveRequestController].
class LeaveRequestControllerProvider
    extends
        AutoDisposeAsyncNotifierProviderImpl<
          LeaveRequestController,
          List<LeaveRequest>
        > {
  /// See also [LeaveRequestController].
  LeaveRequestControllerProvider(int classId)
    : this._internal(
        () => LeaveRequestController()..classId = classId,
        from: leaveRequestControllerProvider,
        name: r'leaveRequestControllerProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$leaveRequestControllerHash,
        dependencies: LeaveRequestControllerFamily._dependencies,
        allTransitiveDependencies:
            LeaveRequestControllerFamily._allTransitiveDependencies,
        classId: classId,
      );

  LeaveRequestControllerProvider._internal(
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
  FutureOr<List<LeaveRequest>> runNotifierBuild(
    covariant LeaveRequestController notifier,
  ) {
    return notifier.build(classId);
  }

  @override
  Override overrideWith(LeaveRequestController Function() create) {
    return ProviderOverride(
      origin: this,
      override: LeaveRequestControllerProvider._internal(
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
    LeaveRequestController,
    List<LeaveRequest>
  >
  createElement() {
    return _LeaveRequestControllerProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is LeaveRequestControllerProvider && other.classId == classId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, classId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin LeaveRequestControllerRef
    on AutoDisposeAsyncNotifierProviderRef<List<LeaveRequest>> {
  /// The parameter `classId` of this provider.
  int get classId;
}

class _LeaveRequestControllerProviderElement
    extends
        AutoDisposeAsyncNotifierProviderElement<
          LeaveRequestController,
          List<LeaveRequest>
        >
    with LeaveRequestControllerRef {
  _LeaveRequestControllerProviderElement(super.provider);

  @override
  int get classId => (origin as LeaveRequestControllerProvider).classId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
