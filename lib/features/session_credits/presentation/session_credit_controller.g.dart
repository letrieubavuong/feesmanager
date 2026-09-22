// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_credit_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$sessionCreditControllerHash() =>
    r'dcb4bf9286077151670c5468b31b4cae65940b9a';

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

abstract class _$SessionCreditController
    extends BuildlessAutoDisposeAsyncNotifier<MonthlyCreditSummary> {
  late final int studentId;
  late final int classId;
  late final String month;

  FutureOr<MonthlyCreditSummary> build(
    int studentId,
    int classId,
    String month,
  );
}

/// See also [SessionCreditController].
@ProviderFor(SessionCreditController)
const sessionCreditControllerProvider = SessionCreditControllerFamily();

/// See also [SessionCreditController].
class SessionCreditControllerFamily
    extends Family<AsyncValue<MonthlyCreditSummary>> {
  /// See also [SessionCreditController].
  const SessionCreditControllerFamily();

  /// See also [SessionCreditController].
  SessionCreditControllerProvider call(
    int studentId,
    int classId,
    String month,
  ) {
    return SessionCreditControllerProvider(studentId, classId, month);
  }

  @override
  SessionCreditControllerProvider getProviderOverride(
    covariant SessionCreditControllerProvider provider,
  ) {
    return call(provider.studentId, provider.classId, provider.month);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'sessionCreditControllerProvider';
}

/// See also [SessionCreditController].
class SessionCreditControllerProvider
    extends
        AutoDisposeAsyncNotifierProviderImpl<
          SessionCreditController,
          MonthlyCreditSummary
        > {
  /// See also [SessionCreditController].
  SessionCreditControllerProvider(int studentId, int classId, String month)
    : this._internal(
        () => SessionCreditController()
          ..studentId = studentId
          ..classId = classId
          ..month = month,
        from: sessionCreditControllerProvider,
        name: r'sessionCreditControllerProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$sessionCreditControllerHash,
        dependencies: SessionCreditControllerFamily._dependencies,
        allTransitiveDependencies:
            SessionCreditControllerFamily._allTransitiveDependencies,
        studentId: studentId,
        classId: classId,
        month: month,
      );

  SessionCreditControllerProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.studentId,
    required this.classId,
    required this.month,
  }) : super.internal();

  final int studentId;
  final int classId;
  final String month;

  @override
  FutureOr<MonthlyCreditSummary> runNotifierBuild(
    covariant SessionCreditController notifier,
  ) {
    return notifier.build(studentId, classId, month);
  }

  @override
  Override overrideWith(SessionCreditController Function() create) {
    return ProviderOverride(
      origin: this,
      override: SessionCreditControllerProvider._internal(
        () => create()
          ..studentId = studentId
          ..classId = classId
          ..month = month,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        studentId: studentId,
        classId: classId,
        month: month,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<
    SessionCreditController,
    MonthlyCreditSummary
  >
  createElement() {
    return _SessionCreditControllerProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SessionCreditControllerProvider &&
        other.studentId == studentId &&
        other.classId == classId &&
        other.month == month;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, studentId.hashCode);
    hash = _SystemHash.combine(hash, classId.hashCode);
    hash = _SystemHash.combine(hash, month.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin SessionCreditControllerRef
    on AutoDisposeAsyncNotifierProviderRef<MonthlyCreditSummary> {
  /// The parameter `studentId` of this provider.
  int get studentId;

  /// The parameter `classId` of this provider.
  int get classId;

  /// The parameter `month` of this provider.
  String get month;
}

class _SessionCreditControllerProviderElement
    extends
        AutoDisposeAsyncNotifierProviderElement<
          SessionCreditController,
          MonthlyCreditSummary
        >
    with SessionCreditControllerRef {
  _SessionCreditControllerProviderElement(super.provider);

  @override
  int get studentId => (origin as SessionCreditControllerProvider).studentId;
  @override
  int get classId => (origin as SessionCreditControllerProvider).classId;
  @override
  String get month => (origin as SessionCreditControllerProvider).month;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
