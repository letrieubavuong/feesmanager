// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_adjustment_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$sessionAdjustmentControllerHash() =>
    r'3c66bb3f35034a734c511aa4df36e053f32878f2';

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

abstract class _$SessionAdjustmentController
    extends BuildlessAutoDisposeAsyncNotifier<List<SessionAdjustment>> {
  late final int sessionId;

  FutureOr<List<SessionAdjustment>> build(
    int sessionId,
  );
}

/// See also [SessionAdjustmentController].
@ProviderFor(SessionAdjustmentController)
const sessionAdjustmentControllerProvider = SessionAdjustmentControllerFamily();

/// See also [SessionAdjustmentController].
class SessionAdjustmentControllerFamily
    extends Family<AsyncValue<List<SessionAdjustment>>> {
  /// See also [SessionAdjustmentController].
  const SessionAdjustmentControllerFamily();

  /// See also [SessionAdjustmentController].
  SessionAdjustmentControllerProvider call(
    int sessionId,
  ) {
    return SessionAdjustmentControllerProvider(
      sessionId,
    );
  }

  @override
  SessionAdjustmentControllerProvider getProviderOverride(
    covariant SessionAdjustmentControllerProvider provider,
  ) {
    return call(
      provider.sessionId,
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
  String? get name => r'sessionAdjustmentControllerProvider';
}

/// See also [SessionAdjustmentController].
class SessionAdjustmentControllerProvider
    extends AutoDisposeAsyncNotifierProviderImpl<SessionAdjustmentController,
        List<SessionAdjustment>> {
  /// See also [SessionAdjustmentController].
  SessionAdjustmentControllerProvider(
    int sessionId,
  ) : this._internal(
          () => SessionAdjustmentController()..sessionId = sessionId,
          from: sessionAdjustmentControllerProvider,
          name: r'sessionAdjustmentControllerProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$sessionAdjustmentControllerHash,
          dependencies: SessionAdjustmentControllerFamily._dependencies,
          allTransitiveDependencies:
              SessionAdjustmentControllerFamily._allTransitiveDependencies,
          sessionId: sessionId,
        );

  SessionAdjustmentControllerProvider._internal(
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
  FutureOr<List<SessionAdjustment>> runNotifierBuild(
    covariant SessionAdjustmentController notifier,
  ) {
    return notifier.build(
      sessionId,
    );
  }

  @override
  Override overrideWith(SessionAdjustmentController Function() create) {
    return ProviderOverride(
      origin: this,
      override: SessionAdjustmentControllerProvider._internal(
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
  AutoDisposeAsyncNotifierProviderElement<SessionAdjustmentController,
      List<SessionAdjustment>> createElement() {
    return _SessionAdjustmentControllerProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SessionAdjustmentControllerProvider &&
        other.sessionId == sessionId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, sessionId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin SessionAdjustmentControllerRef
    on AutoDisposeAsyncNotifierProviderRef<List<SessionAdjustment>> {
  /// The parameter `sessionId` of this provider.
  int get sessionId;
}

class _SessionAdjustmentControllerProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<SessionAdjustmentController,
        List<SessionAdjustment>> with SessionAdjustmentControllerRef {
  _SessionAdjustmentControllerProviderElement(super.provider);

  @override
  int get sessionId =>
      (origin as SessionAdjustmentControllerProvider).sessionId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
