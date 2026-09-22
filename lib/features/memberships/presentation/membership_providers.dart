import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../students/domain/student.dart';
import '../../students/domain/student_service.dart';
import '../domain/membership.dart';
import '../domain/membership_service.dart';

final classSizeProvider = FutureProvider.family<int, int>((ref, classId) async {
  final service = await ref.watch(membershipServiceProvider.future);
  return service.getClassSize(classId);
});

final classRosterProvider =
    FutureProvider.family<List<ClassMembership>, (int, DateTime)>((
      ref,
      arg,
    ) async {
      final service = await ref.watch(membershipServiceProvider.future);
      return service.getRoster(arg.$1, date: arg.$2);
    });

final classMonthMembershipsProvider =
    FutureProvider.family<List<ClassMembership>, (int, String)>((
      ref,
      arg,
    ) async {
      final service = await ref.watch(membershipServiceProvider.future);
      return service.getMembershipsForClassMonth(arg.$1, arg.$2);
    });

final classMonthStudentsProvider =
    FutureProvider.family<List<Student>, (int, String)>((ref, arg) async {
      final membershipService = await ref.watch(
        membershipServiceProvider.future,
      );
      final studentService = await ref.watch(studentServiceProvider.future);

      final studentIds = await membershipService
          .getUniqueStudentIdsForClassMonth(arg.$1, arg.$2);

      final students = <Student>[];
      for (final id in studentIds) {
        final student = await studentService.getStudentById(id);
        if (student != null) students.add(student);
      }
      return students;
    });
