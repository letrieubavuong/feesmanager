import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/student.dart';
import '../domain/student_service.dart';
import '../../memberships/domain/membership.dart';
import '../../memberships/domain/membership_service.dart';
import '../../classes/presentation/class_controller.dart';
import 'student_form_page.dart';
import 'student_controller.dart';

import 'package:tuition2027/core/utils/date_formatter.dart';
import '../../schedule/domain/student_shift_assignment.dart';
import '../../schedule/domain/schedule_service.dart';
import '../../schedule/domain/class_schedule.dart';

part 'student_detail_page.g.dart';

class StudentDetailPage extends ConsumerWidget {
  final int studentId;
  const StudentDetailPage({super.key, required this.studentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentAsync = ref.watch(studentDetailProvider(studentId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết học sinh'),
        actions: [
          studentAsync.when(
            data: (student) => student == null
                ? const SizedBox.shrink()
                : IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>
                              StudentFormPage(student: student),
                        ),
                      );
                    },
                  ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          IconButton(
            icon: const Icon(Icons.archive_outlined),
            onPressed: () => _confirmArchive(context, ref),
          ),
        ],
      ),
      body: studentAsync.when(
        data: (student) {
          if (student == null)
            return const Center(child: Text('Không tìm thấy học sinh'));
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, student),
                const SizedBox(height: 24),
                _buildSectionTitle(context, 'Thông tin cá nhân'),
                _buildInfoTile(
                  Icons.cake,
                  'Ngày sinh',
                  student.ngaySinh ?? 'Chưa cập nhật',
                ),
                _buildInfoTile(
                  Icons.location_on,
                  'Địa chỉ',
                  student.diaChi ?? 'Chưa cập nhật',
                ),
                _buildInfoTile(
                  Icons.facebook,
                  'Facebook',
                  student.facebook ?? 'Chưa cập nhật',
                ),
                const SizedBox(height: 16),
                _buildSectionTitle(context, 'Liên hệ'),
                _buildInfoTile(
                  Icons.person,
                  'Phụ huynh',
                  student.tenPhuHuynh ?? 'Chưa cập nhật',
                ),
                _buildInfoTile(
                  Icons.phone,
                  'SĐT Phụ huynh',
                  student.sdtPhuHuynh ?? 'Chưa cập nhật',
                ),
                _buildInfoTile(
                  Icons.phone_android,
                  'SĐT Học sinh',
                  student.sdtHocSinh ?? 'Chưa cập nhật',
                ),
                _buildInfoTile(
                  Icons.email,
                  'Email',
                  student.email ?? 'Chưa cập nhật',
                ),
                const SizedBox(height: 16),
                _buildSectionTitle(context, 'Khác'),
                _buildInfoTile(
                  Icons.note,
                  'Ghi chú',
                  student.ghiChu ?? 'Không có ghi chú',
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                _buildMembershipSection(context, ref, student.id!),
                const SizedBox(height: 16),
                _buildScheduleSection(context, ref, student.id!),
                _buildPlaceholderSection(context, 'Lịch sử điểm danh'),
                _buildPlaceholderSection(context, 'Học phí & Thanh toán'),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
      ),
    );
  }

  Widget _buildMembershipSection(
    BuildContext context,
    WidgetRef ref,
    int studentId,
  ) {
    final membershipsAsync = ref.watch(
      studentMembershipHistoryProvider(studentId),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, 'Lớp học'),
        membershipsAsync.when(
          data: (memberships) {
            if (memberships.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Học sinh chưa tham gia lớp nào.',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              );
            }
            return Column(
              children: memberships
                  .map((m) => _buildMembershipTile(context, ref, m))
                  .toList(),
            );
          },
          loading: () => const CircularProgressIndicator(),
          error: (e, _) => Text('Lỗi tải lớp: $e'),
        ),
      ],
    );
  }

  Widget _buildScheduleSection(
    BuildContext context,
    WidgetRef ref,
    int studentId,
  ) {
    final assignmentsAsync = ref.watch(studentScheduleProvider(studentId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, 'Lịch học (Phân ca)'),
        assignmentsAsync.when(
          data: (assignments) {
            if (assignments.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Chưa có lịch học được phân.',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              );
            }
            return Column(
              children: assignments
                  .map((a) => _buildAssignmentTile(context, ref, a))
                  .toList(),
            );
          },
          loading: () => const CircularProgressIndicator(),
          error: (e, _) => Text('Lỗi tải lịch: $e'),
        ),
      ],
    );
  }

  Widget _buildAssignmentTile(
    BuildContext context,
    WidgetRef ref,
    StudentShiftAssignment a,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: const Icon(Icons.calendar_today),
        title: Consumer(
          builder: (context, ref, _) {
            final scheduleAsync = ref.watch(scheduleDetailProvider(a.idLichHoc));
            return scheduleAsync.when(
              data: (s) => Text(
                '${DateFormatter.formatVietnameseWeekday(s?.thuTrongTuan ?? 0)}: ${s?.gioBatDau} - ${s?.gioKetThuc}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              loading: () => const Text('...'),
              error: (_, __) => const Text('Lỗi tải lịch'),
            );
          },
        ),
        subtitle: Consumer(
          builder: (context, ref, _) {
            final classAsync = ref.watch(classDetailProvider(a.idLop));
            return classAsync.when(
              data: (c) => Text('Lớp: ${c?.tenLop ?? 'Unknown'}'),
              loading: () => const Text('...'),
              error: (_, __) => const Text('Lỗi tải lớp'),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMembershipTile(
    BuildContext context,
    WidgetRef ref,
    ClassMembership m,
  ) {
    final classAsync = ref.watch(classDetailProvider(m.idLop));
    final isActive = m.isActiveOn(DateTime.now());

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        title: classAsync.when(
          data: (c) => Text(
            c?.tenLop ?? 'Unknown Class',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              decoration: c?.daLuuTru == true
                  ? TextDecoration.lineThrough
                  : null,
            ),
          ),
          loading: () => const Text('Loading...'),
          error: (_, __) => const Text('Error'),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Từ: ${m.tuNgay}${m.denNgay != null ? ' - Đến: ${m.denNgay}' : ''}',
            ),
            if (m.lyDoKetThuc != null)
              Text(
                'Lý do nghỉ: ${m.lyDoKetThuc}',
                style: const TextStyle(
                  fontStyle: FontStyle.italic,
                  fontSize: 12,
                ),
              ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isActive
                ? Colors.green.withOpacity(0.1)
                : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            isActive ? 'Đang học' : 'Đã nghỉ',
            style: TextStyle(
              color: isActive ? Colors.green : Colors.grey,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, student) {
    return Row(
      children: [
        CircleAvatar(
          radius: 40,
          child: Text(
            student.hoTen[0].toUpperCase(),
            style: const TextStyle(fontSize: 32),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                student.hoTen,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${student.khoi != null ? 'Khối ${student.khoi}' : 'Chưa cập nhật khối'} • ${student.truongDangHoc ?? 'Chưa cập nhật trường'}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Text('$label: ', style: const TextStyle(color: Colors.grey)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildPlaceholderSection(BuildContext context, String title) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'Chức năng sẽ được triển khai ở phase tiếp theo.',
              style: TextStyle(
                color: Theme.of(context).disabledColor,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmArchive(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lưu trữ học sinh'),
        content: const Text('Bạn có chắc chắn muốn lưu trữ học sinh này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await ref
                    .read(studentListControllerProvider.notifier)
                    .archive(studentId);
                if (context.mounted) {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Go back to list
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context); // Close dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString().replaceAll('Exception: ', '')),
                    ),
                  );
                }
              }
            },
            child: const Text('Lưu trữ'),
          ),
        ],
      ),
    );
  }
}

// Additional Provider for Detail
@riverpod
Future<Student?> studentDetail(StudentDetailRef ref, int id) async {
  final service = await ref.watch(studentServiceProvider.future);
  return service.getStudentById(id);
}

@riverpod
Future<List<ClassMembership>> studentMembershipHistory(
  StudentMembershipHistoryRef ref,
  int id,
) async {
  final service = await ref.watch(membershipServiceProvider.future);
  return service.getMembershipHistory(id);
}

@riverpod
Future<List<StudentShiftAssignment>> studentSchedule(
  StudentScheduleRef ref,
  int id,
) async {
  final service = await ref.watch(classScheduleServiceProvider.future);
  return service.getAssignmentsForStudent(id);
}

@riverpod
Future<ClassSchedule?> scheduleDetail(ScheduleDetailRef ref, int id) async {
  final service = await ref.watch(classScheduleServiceProvider.future);
  return service.getScheduleById(id);
}
