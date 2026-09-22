// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$invoicePaymentSummaryHash() =>
    r'bef96c6529b23768c6ab85f600ade14a368454fc';

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

/// See also [invoicePaymentSummary].
@ProviderFor(invoicePaymentSummary)
const invoicePaymentSummaryProvider = InvoicePaymentSummaryFamily();

/// See also [invoicePaymentSummary].
class InvoicePaymentSummaryFamily
    extends Family<AsyncValue<InvoicePaymentSummary?>> {
  /// See also [invoicePaymentSummary].
  const InvoicePaymentSummaryFamily();

  /// See also [invoicePaymentSummary].
  InvoicePaymentSummaryProvider call((int, int, String) arg) {
    return InvoicePaymentSummaryProvider(arg);
  }

  @override
  InvoicePaymentSummaryProvider getProviderOverride(
    covariant InvoicePaymentSummaryProvider provider,
  ) {
    return call(provider.arg);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'invoicePaymentSummaryProvider';
}

/// See also [invoicePaymentSummary].
class InvoicePaymentSummaryProvider
    extends AutoDisposeFutureProvider<InvoicePaymentSummary?> {
  /// See also [invoicePaymentSummary].
  InvoicePaymentSummaryProvider((int, int, String) arg)
    : this._internal(
        (ref) => invoicePaymentSummary(ref as InvoicePaymentSummaryRef, arg),
        from: invoicePaymentSummaryProvider,
        name: r'invoicePaymentSummaryProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$invoicePaymentSummaryHash,
        dependencies: InvoicePaymentSummaryFamily._dependencies,
        allTransitiveDependencies:
            InvoicePaymentSummaryFamily._allTransitiveDependencies,
        arg: arg,
      );

  InvoicePaymentSummaryProvider._internal(
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
    FutureOr<InvoicePaymentSummary?> Function(InvoicePaymentSummaryRef provider)
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: InvoicePaymentSummaryProvider._internal(
        (ref) => create(ref as InvoicePaymentSummaryRef),
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
  AutoDisposeFutureProviderElement<InvoicePaymentSummary?> createElement() {
    return _InvoicePaymentSummaryProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is InvoicePaymentSummaryProvider && other.arg == arg;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, arg.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin InvoicePaymentSummaryRef
    on AutoDisposeFutureProviderRef<InvoicePaymentSummary?> {
  /// The parameter `arg` of this provider.
  (int, int, String) get arg;
}

class _InvoicePaymentSummaryProviderElement
    extends AutoDisposeFutureProviderElement<InvoicePaymentSummary?>
    with InvoicePaymentSummaryRef {
  _InvoicePaymentSummaryProviderElement(super.provider);

  @override
  (int, int, String) get arg => (origin as InvoicePaymentSummaryProvider).arg;
}

String _$invoicePaymentsHash() => r'63fc2006ca1d63e5909e768e74edd409c865fd9e';

/// See also [invoicePayments].
@ProviderFor(invoicePayments)
const invoicePaymentsProvider = InvoicePaymentsFamily();

/// See also [invoicePayments].
class InvoicePaymentsFamily extends Family<AsyncValue<List<Payment>>> {
  /// See also [invoicePayments].
  const InvoicePaymentsFamily();

  /// See also [invoicePayments].
  InvoicePaymentsProvider call((int, int, String) arg) {
    return InvoicePaymentsProvider(arg);
  }

  @override
  InvoicePaymentsProvider getProviderOverride(
    covariant InvoicePaymentsProvider provider,
  ) {
    return call(provider.arg);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'invoicePaymentsProvider';
}

/// See also [invoicePayments].
class InvoicePaymentsProvider extends AutoDisposeFutureProvider<List<Payment>> {
  /// See also [invoicePayments].
  InvoicePaymentsProvider((int, int, String) arg)
    : this._internal(
        (ref) => invoicePayments(ref as InvoicePaymentsRef, arg),
        from: invoicePaymentsProvider,
        name: r'invoicePaymentsProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$invoicePaymentsHash,
        dependencies: InvoicePaymentsFamily._dependencies,
        allTransitiveDependencies:
            InvoicePaymentsFamily._allTransitiveDependencies,
        arg: arg,
      );

  InvoicePaymentsProvider._internal(
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
    FutureOr<List<Payment>> Function(InvoicePaymentsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: InvoicePaymentsProvider._internal(
        (ref) => create(ref as InvoicePaymentsRef),
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
  AutoDisposeFutureProviderElement<List<Payment>> createElement() {
    return _InvoicePaymentsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is InvoicePaymentsProvider && other.arg == arg;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, arg.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin InvoicePaymentsRef on AutoDisposeFutureProviderRef<List<Payment>> {
  /// The parameter `arg` of this provider.
  (int, int, String) get arg;
}

class _InvoicePaymentsProviderElement
    extends AutoDisposeFutureProviderElement<List<Payment>>
    with InvoicePaymentsRef {
  _InvoicePaymentsProviderElement(super.provider);

  @override
  (int, int, String) get arg => (origin as InvoicePaymentsProvider).arg;
}

String _$paymentControllerHash() => r'e3d049c3ef39ab300b51eb86886decf84ff1625d';

/// See also [PaymentController].
@ProviderFor(PaymentController)
final paymentControllerProvider =
    AutoDisposeAsyncNotifierProvider<PaymentController, void>.internal(
      PaymentController.new,
      name: r'paymentControllerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$paymentControllerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$PaymentController = AutoDisposeAsyncNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
