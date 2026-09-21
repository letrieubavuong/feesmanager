import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/membership_service.dart';
import '../domain/membership.dart';

final classSizeProvider = FutureProvider.family<int, int>((ref, classId) async {
  final service = await ref.watch(membershipServiceProvider.future);
  return service.getClassSize(classId);
});

final classRosterProvider = FutureProvider.family<List<ClassMembership>, (int, DateTime)>((ref, arg) async {
  final service = await ref.watch(membershipServiceProvider.future);
  return service.getRoster(arg.$1, date: arg.$2);
});
