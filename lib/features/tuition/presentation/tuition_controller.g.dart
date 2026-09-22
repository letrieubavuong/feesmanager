// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tuition_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$classTuitionPoliciesHash() =>
    r'ff46de4cff2baedde5a5b535c5d09dbfecfceac0';

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

/// See also [classTuitionPolicies].
@ProviderFor(classTuitionPolicies)
const classTuitionPoliciesProvider = ClassTuitionPoliciesFamily();

/// See also [classTuitionPolicies].
class ClassTuitionPoliciesFamily
    extends Family<AsyncValue<List<TuitionPolicy>>> {
  /// See also [classTuitionPolicies].
  const ClassTuitionPoliciesFamily();

  /// See also [classTuitionPolicies].
  ClassTuitionPoliciesProvider call(int classId) {
    return ClassTuitionPoliciesProvider(classId);
  }

  @override
  ClassTuitionPoliciesProvider getProviderOverride(
    covariant ClassTuitionPoliciesProvider provider,
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
  String? get name => r'classTuitionPoliciesProvider';
}

/// See also [classTuitionPolicies].
class ClassTuitionPoliciesProvider
    extends AutoDisposeFutureProvider<List<TuitionPolicy>> {
  /// See also [classTuitionPolicies].
  ClassTuitionPoliciesProvider(int classId)
    : this._internal(
        (ref) => classTuitionPolicies(ref as ClassTuitionPoliciesRef, classId),
        from: classTuitionPoliciesProvider,
        name: r'classTuitionPoliciesProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$classTuitionPoliciesHash,
        dependencies: ClassTuitionPoliciesFamily._dependencies,
        allTransitiveDependencies:
            ClassTuitionPoliciesFamily._allTransitiveDependencies,
        classId: classId,
      );

  ClassTuitionPoliciesProvider._internal(
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
  Override overrideWith(
    FutureOr<List<TuitionPolicy>> Function(ClassTuitionPoliciesRef provider)
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ClassTuitionPoliciesProvider._internal(
        (ref) => create(ref as ClassTuitionPoliciesRef),
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
  AutoDisposeFutureProviderElement<List<TuitionPolicy>> createElement() {
    return _ClassTuitionPoliciesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ClassTuitionPoliciesProvider && other.classId == classId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, classId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin ClassTuitionPoliciesRef
    on AutoDisposeFutureProviderRef<List<TuitionPolicy>> {
  /// The parameter `classId` of this provider.
  int get classId;
}

class _ClassTuitionPoliciesProviderElement
    extends AutoDisposeFutureProviderElement<List<TuitionPolicy>>
    with ClassTuitionPoliciesRef {
  _ClassTuitionPoliciesProviderElement(super.provider);

  @override
  int get classId => (origin as ClassTuitionPoliciesProvider).classId;
}

String _$studentInvoiceHash() => r'cd475ed1892e9a8ad12a70c1fcb7832761a0d175';

/// See also [studentInvoice].
@ProviderFor(studentInvoice)
const studentInvoiceProvider = StudentInvoiceFamily();

/// See also [studentInvoice].
class StudentInvoiceFamily extends Family<AsyncValue<TuitionInvoice?>> {
  /// See also [studentInvoice].
  const StudentInvoiceFamily();

  /// See also [studentInvoice].
  StudentInvoiceProvider call(int studentId, int classId, String month) {
    return StudentInvoiceProvider(studentId, classId, month);
  }

  @override
  StudentInvoiceProvider getProviderOverride(
    covariant StudentInvoiceProvider provider,
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
  String? get name => r'studentInvoiceProvider';
}

/// See also [studentInvoice].
class StudentInvoiceProvider
    extends AutoDisposeFutureProvider<TuitionInvoice?> {
  /// See also [studentInvoice].
  StudentInvoiceProvider(int studentId, int classId, String month)
    : this._internal(
        (ref) =>
            studentInvoice(ref as StudentInvoiceRef, studentId, classId, month),
        from: studentInvoiceProvider,
        name: r'studentInvoiceProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$studentInvoiceHash,
        dependencies: StudentInvoiceFamily._dependencies,
        allTransitiveDependencies:
            StudentInvoiceFamily._allTransitiveDependencies,
        studentId: studentId,
        classId: classId,
        month: month,
      );

  StudentInvoiceProvider._internal(
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
  Override overrideWith(
    FutureOr<TuitionInvoice?> Function(StudentInvoiceRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: StudentInvoiceProvider._internal(
        (ref) => create(ref as StudentInvoiceRef),
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
  AutoDisposeFutureProviderElement<TuitionInvoice?> createElement() {
    return _StudentInvoiceProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is StudentInvoiceProvider &&
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

mixin StudentInvoiceRef on AutoDisposeFutureProviderRef<TuitionInvoice?> {
  /// The parameter `studentId` of this provider.
  int get studentId;

  /// The parameter `classId` of this provider.
  int get classId;

  /// The parameter `month` of this provider.
  String get month;
}

class _StudentInvoiceProviderElement
    extends AutoDisposeFutureProviderElement<TuitionInvoice?>
    with StudentInvoiceRef {
  _StudentInvoiceProviderElement(super.provider);

  @override
  int get studentId => (origin as StudentInvoiceProvider).studentId;
  @override
  int get classId => (origin as StudentInvoiceProvider).classId;
  @override
  String get month => (origin as StudentInvoiceProvider).month;
}

String _$tuitionPreviewControllerHash() =>
    r'2108cbb0fcdd65bba0d5dab5620358affb1fb458';

abstract class _$TuitionPreviewController
    extends BuildlessAutoDisposeAsyncNotifier<TuitionPreview> {
  late final int studentId;
  late final int classId;
  late final String month;

  FutureOr<TuitionPreview> build(int studentId, int classId, String month);
}

/// See also [TuitionPreviewController].
@ProviderFor(TuitionPreviewController)
const tuitionPreviewControllerProvider = TuitionPreviewControllerFamily();

/// See also [TuitionPreviewController].
class TuitionPreviewControllerFamily
    extends Family<AsyncValue<TuitionPreview>> {
  /// See also [TuitionPreviewController].
  const TuitionPreviewControllerFamily();

  /// See also [TuitionPreviewController].
  TuitionPreviewControllerProvider call(
    int studentId,
    int classId,
    String month,
  ) {
    return TuitionPreviewControllerProvider(studentId, classId, month);
  }

  @override
  TuitionPreviewControllerProvider getProviderOverride(
    covariant TuitionPreviewControllerProvider provider,
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
  String? get name => r'tuitionPreviewControllerProvider';
}

/// See also [TuitionPreviewController].
class TuitionPreviewControllerProvider
    extends
        AutoDisposeAsyncNotifierProviderImpl<
          TuitionPreviewController,
          TuitionPreview
        > {
  /// See also [TuitionPreviewController].
  TuitionPreviewControllerProvider(int studentId, int classId, String month)
    : this._internal(
        () => TuitionPreviewController()
          ..studentId = studentId
          ..classId = classId
          ..month = month,
        from: tuitionPreviewControllerProvider,
        name: r'tuitionPreviewControllerProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$tuitionPreviewControllerHash,
        dependencies: TuitionPreviewControllerFamily._dependencies,
        allTransitiveDependencies:
            TuitionPreviewControllerFamily._allTransitiveDependencies,
        studentId: studentId,
        classId: classId,
        month: month,
      );

  TuitionPreviewControllerProvider._internal(
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
  FutureOr<TuitionPreview> runNotifierBuild(
    covariant TuitionPreviewController notifier,
  ) {
    return notifier.build(studentId, classId, month);
  }

  @override
  Override overrideWith(TuitionPreviewController Function() create) {
    return ProviderOverride(
      origin: this,
      override: TuitionPreviewControllerProvider._internal(
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
    TuitionPreviewController,
    TuitionPreview
  >
  createElement() {
    return _TuitionPreviewControllerProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is TuitionPreviewControllerProvider &&
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

mixin TuitionPreviewControllerRef
    on AutoDisposeAsyncNotifierProviderRef<TuitionPreview> {
  /// The parameter `studentId` of this provider.
  int get studentId;

  /// The parameter `classId` of this provider.
  int get classId;

  /// The parameter `month` of this provider.
  String get month;
}

class _TuitionPreviewControllerProviderElement
    extends
        AutoDisposeAsyncNotifierProviderElement<
          TuitionPreviewController,
          TuitionPreview
        >
    with TuitionPreviewControllerRef {
  _TuitionPreviewControllerProviderElement(super.provider);

  @override
  int get studentId => (origin as TuitionPreviewControllerProvider).studentId;
  @override
  int get classId => (origin as TuitionPreviewControllerProvider).classId;
  @override
  String get month => (origin as TuitionPreviewControllerProvider).month;
}

String _$invoiceControllerHash() => r'96888a3cd8cc496703af1e77f431bc44a2c0d6aa';

/// See also [InvoiceController].
@ProviderFor(InvoiceController)
final invoiceControllerProvider =
    AutoDisposeAsyncNotifierProvider<InvoiceController, void>.internal(
      InvoiceController.new,
      name: r'invoiceControllerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$invoiceControllerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$InvoiceController = AutoDisposeAsyncNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
