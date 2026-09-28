// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'class_attendance_timeline_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$classAttendanceTimelineHash() =>
    r'0fa8deb5e4178d8fc06850335c5b64c4acc06a09';

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

/// See also [classAttendanceTimeline].
@ProviderFor(classAttendanceTimeline)
const classAttendanceTimelineProvider = ClassAttendanceTimelineFamily();

/// See also [classAttendanceTimeline].
class ClassAttendanceTimelineFamily
    extends Family<AsyncValue<List<ClassAttendanceTimelineItem>>> {
  /// See also [classAttendanceTimeline].
  const ClassAttendanceTimelineFamily();

  /// See also [classAttendanceTimeline].
  ClassAttendanceTimelineProvider call({
    required int classId,
    required String yearMonth,
  }) {
    return ClassAttendanceTimelineProvider(
      classId: classId,
      yearMonth: yearMonth,
    );
  }

  @override
  ClassAttendanceTimelineProvider getProviderOverride(
    covariant ClassAttendanceTimelineProvider provider,
  ) {
    return call(classId: provider.classId, yearMonth: provider.yearMonth);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'classAttendanceTimelineProvider';
}

/// See also [classAttendanceTimeline].
class ClassAttendanceTimelineProvider
    extends AutoDisposeFutureProvider<List<ClassAttendanceTimelineItem>> {
  /// See also [classAttendanceTimeline].
  ClassAttendanceTimelineProvider({
    required int classId,
    required String yearMonth,
  }) : this._internal(
         (ref) => classAttendanceTimeline(
           ref as ClassAttendanceTimelineRef,
           classId: classId,
           yearMonth: yearMonth,
         ),
         from: classAttendanceTimelineProvider,
         name: r'classAttendanceTimelineProvider',
         debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
             ? null
             : _$classAttendanceTimelineHash,
         dependencies: ClassAttendanceTimelineFamily._dependencies,
         allTransitiveDependencies:
             ClassAttendanceTimelineFamily._allTransitiveDependencies,
         classId: classId,
         yearMonth: yearMonth,
       );

  ClassAttendanceTimelineProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.classId,
    required this.yearMonth,
  }) : super.internal();

  final int classId;
  final String yearMonth;

  @override
  Override overrideWith(
    FutureOr<List<ClassAttendanceTimelineItem>> Function(
      ClassAttendanceTimelineRef provider,
    )
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ClassAttendanceTimelineProvider._internal(
        (ref) => create(ref as ClassAttendanceTimelineRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        classId: classId,
        yearMonth: yearMonth,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<ClassAttendanceTimelineItem>>
  createElement() {
    return _ClassAttendanceTimelineProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ClassAttendanceTimelineProvider &&
        other.classId == classId &&
        other.yearMonth == yearMonth;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, classId.hashCode);
    hash = _SystemHash.combine(hash, yearMonth.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin ClassAttendanceTimelineRef
    on AutoDisposeFutureProviderRef<List<ClassAttendanceTimelineItem>> {
  /// The parameter `classId` of this provider.
  int get classId;

  /// The parameter `yearMonth` of this provider.
  String get yearMonth;
}

class _ClassAttendanceTimelineProviderElement
    extends AutoDisposeFutureProviderElement<List<ClassAttendanceTimelineItem>>
    with ClassAttendanceTimelineRef {
  _ClassAttendanceTimelineProviderElement(super.provider);

  @override
  int get classId => (origin as ClassAttendanceTimelineProvider).classId;
  @override
  String get yearMonth => (origin as ClassAttendanceTimelineProvider).yearMonth;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
