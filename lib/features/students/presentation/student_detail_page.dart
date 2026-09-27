import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../app/common_widgets/app_feedback.dart';
import '../../../app/common_widgets/navy_components.dart';
import '../../../app/common_widgets/searchable_selectors.dart';
import '../../../app/common_widgets/student_avatar.dart';
import '../../../app/design_system/app_theme.dart';
import '../../../app/navigation/app_global_drawer.dart';
import '../../../app/navigation/ui_keys.dart';
import '../../memberships/presentation/enroll_student_bottom_sheet.dart';
import '../domain/student.dart';
import '../domain/student_service.dart';
import '../../memberships/domain/membership.dart';
import '../../memberships/domain/membership_service.dart';
import '../../classes/presentation/class_controller.dart';
import '../../schedule_conflicts/domain/schedule_constraint.dart';
import '../../schedule_conflicts/presentation/schedule_conflict_providers.dart';
import '../../schedule_conflicts/presentation/schedule_constraint_dialogs.dart';
import 'student_form_page.dart';
import 'student_controller.dart';

import 'package:tuition2027/core/utils/date_formatter.dart';
import '../../schedule/domain/student_shift_assignment.dart';
import '../../schedule/domain/schedule_service.dart';
import '../../schedule/domain/class_schedule.dart';
import '../../session_credits/presentation/session_credit_page.dart';

part 'student_detail_page.g.dart';

class StudentDetailPage extends ConsumerWidget {
  final int studentId;
  const StudentDetailPage({super.key, required this.studentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentAsync = ref.watch(studentDetailProvider(studentId));

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const AppGlobalDrawer(),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: const BackButton(),
        title: const Text('Chi tiết học sinh'),
        actions: [
          const GlobalMenuButton(),
          studentAsync.when(
            data: (student) {
              if (student == null) return const SizedBox.shrink();
              final isStopped = student.daLuuTru;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: 'Sửa thông tin',
                    onPressed: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>
                              StudentFormPage(student: student),
                        ),
                      );
                      ref.invalidate(studentDetailProvider(studentId));
                      ref
                          .read(studentListControllerProvider.notifier)
                          .refresh();
                    },
                  ),
                  IconButton(
                    key: isStopped
                        ? UiKeys.studentRestoreAction
                        : UiKeys.studentArchiveAction,
                    icon: Icon(
                      isStopped
                          ? Icons.restore_rounded
                          : Icons.person_off_outlined,
                      color: isStopped ? AppColors.success : AppColors.error,
                    ),
                    tooltip: isStopped
                        ? 'Cho hoạt động lại'
                        : 'Đánh dấu ngừng học',
                    onPressed: () =>
                        _toggleArchiveStatus(context, ref, student),
                  ),
                ],
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: studentAsync.when(
        data: (student) {
          if (student == null) {
            return const Center(
              child: Text(
                'Không tìm thấy học sinh',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            );
          }
          final isStopped = student.daLuuTru;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, student),
                const SizedBox(height: 16),
                const AppSectionHeader(title: 'Thông tin cá nhân & Liên hệ'),
                AppSectionCard(
                  child: Column(
                    children: [
                      CompactInfoRow(
                        icon: Icons.cake_outlined,
                        label: 'Ngày sinh',
                        value: student.ngaySinh != null
                            ? DateFormatter.formatDisplayDate(student.ngaySinh)
                            : 'Chưa cập nhật',
                      ),
                      CompactInfoRow(
                        icon: Icons.location_on_outlined,
                        label: 'Địa chỉ',
                        value: student.diaChi ?? 'Chưa cập nhật',
                      ),
                      CompactInfoRow(
                        icon: Icons.public_outlined,
                        label: 'Facebook',
                        value: student.facebook ?? 'Chưa cập nhật',
                      ),
                      const Divider(color: AppColors.border, height: 16),
                      CompactInfoRow(
                        icon: Icons.person_outline,
                        label: 'Phụ huynh',
                        value: student.tenPhuHuynh ?? 'Chưa cập nhật',
                      ),
                      CompactInfoRow(
                        icon: Icons.phone_outlined,
                        label: 'SĐT Phụ huynh',
                        value: student.sdtPhuHuynh ?? 'Chưa cập nhật',
                        valueColor: student.sdtPhuHuynh != null
                            ? AppColors.cyanAccent
                            : null,
                      ),
                      CompactInfoRow(
                        icon: Icons.phone_android_outlined,
                        label: 'SĐT Học sinh',
                        value: student.sdtHocSinh ?? 'Chưa cập nhật',
                      ),
                      CompactInfoRow(
                        icon: Icons.email_outlined,
                        label: 'Email',
                        value: student.email ?? 'Chưa cập nhật',
                      ),
                      if (student.ghiChu != null &&
                          student.ghiChu!.isNotEmpty) ...[
                        const Divider(color: AppColors.border, height: 16),
                        CompactInfoRow(
                          icon: Icons.notes_outlined,
                          label: 'Ghi chú',
                          value: student.ghiChu!,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildMembershipSection(context, ref, student.id!, isStopped),
                const SizedBox(height: 16),
                _buildConstraintSection(context, ref, student.id!),
                const SizedBox(height: 16),
                _buildScheduleSection(context, ref, student.id!),
              ],
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(
          child: Text(
            'Lỗi: $e',
            style: const TextStyle(color: AppColors.error),
          ),
        ),
      ),
    );
  }

  Widget _buildMembershipSection(
    BuildContext context,
    WidgetRef ref,
    int studentId,
    bool isStudentStopped,
  ) {
    final membershipsAsync = ref.watch(
      studentMembershipHistoryProvider(studentId),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader(
          title: 'Lớp đang học',
          actionLabel: 'Thêm vào lớp',
          onAction: isStudentStopped
              ? null
              : () async {
                  final classList = await ref.read(
                    classListControllerProvider.future,
                  );
                  if (!context.mounted) return;
                  final activeClasses = classList
                      .where((c) => !c.daLuuTru)
                      .toList();
                  if (activeClasses.isEmpty) {
                    AppFeedback.showErrorSnackBar(
                      context,
                      'Không có lớp học nào đang hoạt động.',
                    );
                    return;
                  }
                  final chosenClass = await showClassSelectorDialog(
                    context,
                    classes: activeClasses,
                  );
                  if (chosenClass != null && context.mounted) {
                    await showEnrollStudentBottomSheet(
                      context,
                      classId: chosenClass.id!,
                      initialStudentId: studentId,
                    );
                    ref.invalidate(studentMembershipHistoryProvider(studentId));
                  }
                },
        ),
        membershipsAsync.when(
          data: (memberships) {
            if (memberships.isEmpty) {
              return const AppSectionCard(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'Học sinh chưa tham gia lớp nào.',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ),
              );
            }
            return Column(
              children: memberships
                  .map((m) => _buildMembershipTile(context, ref, m))
                  .toList(),
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (e, _) => Text(
            'Lỗi tải danh sách lớp: $e',
            style: const TextStyle(color: AppColors.error),
          ),
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
        const AppSectionHeader(title: 'Phân ca lịch học'),
        assignmentsAsync.when(
          data: (assignments) {
            if (assignments.isEmpty) {
              return const AppSectionCard(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'Chưa có ca học nào được phân.',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ),
              );
            }
            return Column(
              children: assignments
                  .map((a) => _buildAssignmentTile(context, ref, a))
                  .toList(),
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (e, _) => Text(
            'Lỗi tải ca học: $e',
            style: const TextStyle(color: AppColors.error),
          ),
        ),
      ],
    );
  }

  Widget _buildConstraintSection(
    BuildContext context,
    WidgetRef ref,
    int studentId,
  ) {
    final constraintsAsync = ref.watch(studentConstraintsProvider(studentId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader(
          title: 'Giờ bận',
          actionLabel: 'Thêm giờ bận',
          onAction: () => showAddConstraintDialog(context, ref, studentId),
        ),
        constraintsAsync.when(
          data: (constraints) {
            if (constraints.isEmpty) {
              return const AppSectionCard(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'Chưa thiết lập giờ bận nào.',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ),
              );
            }
            return Column(
              children: constraints
                  .map((c) => _buildConstraintTile(context, ref, c, studentId))
                  .toList(),
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (e, _) => Text(
            'Lỗi tải giờ bận: $e',
            style: const TextStyle(color: AppColors.error),
          ),
        ),
      ],
    );
  }

  Widget _buildConstraintTile(
    BuildContext context,
    WidgetRef ref,
    ScheduleConstraint c,
    int studentId,
  ) {
    final isCancelled = c.status == ConstraintStatus.DA_HUY;

    var subtitleText = c.occurrenceType == OccurrenceType.DINH_KY
        ? 'Thứ ${c.weekday} (${c.startTime} - ${c.endTime}) | Từ ${DateFormatter.formatDisplayDate(c.effectiveFrom)}${c.effectiveTo != null ? " đến ${DateFormatter.formatDisplayDate(c.effectiveTo!)}" : ""}'
        : 'Ngày ${DateFormatter.formatDisplayDate(c.specificDate)} (${c.startTime} - ${c.endTime})';

    if (c.travelBufferMinutes > 0) {
      subtitleText += ' | Đệm: ${c.travelBufferMinutes} phút';
    }
    if (c.note != null && c.note!.isNotEmpty) {
      subtitleText += ' | Ghi chú: ${c.note}';
    }

    return AppSectionCard(
      margin: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(
            c.type == ConstraintType.HARD_BLOCK
                ? Icons.block
                : c.type == ConstraintType.OTHER_CENTER
                ? Icons.domain
                : Icons.star_border,
            color: isCancelled
                ? AppColors.textMuted
                : (c.type == ConstraintType.HARD_BLOCK
                      ? AppColors.error
                      : AppColors.warning),
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${c.type.displayName}${c.sourceName != null ? " - ${c.sourceName}" : ""}',
                  style: TextStyle(
                    color: isCancelled
                        ? AppColors.textMuted
                        : AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    decoration: isCancelled ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitleText,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (!isCancelled)
            TextButton(
              onPressed: () async {
                final confirm = await AppFeedback.showConfirmBottomSheet(
                  context,
                  title: 'Xóa giờ bận',
                  message: 'Bạn có chắc chắn muốn xóa giờ bận này?',
                  confirmLabel: 'Xóa giờ bận',
                  cancelLabel: 'Không',
                  isDestructive: true,
                );

                if (confirm == true && c.id != null) {
                  await ref
                      .read(scheduleConstraintControllerProvider.notifier)
                      .cancelConstraint(c.id!, studentId);
                }
              },
              child: const Text(
                'Xóa',
                style: TextStyle(color: AppColors.error, fontSize: 13),
              ),
            )
          else
            const AppStatusChip(
              label: 'Đã xóa',
              color: AppColors.textMuted,
              compact: true,
            ),
        ],
      ),
    );
  }

  Widget _buildAssignmentTile(
    BuildContext context,
    WidgetRef ref,
    StudentShiftAssignment a,
  ) {
    return AppSectionCard(
      margin: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          const Icon(
            Icons.calendar_month_outlined,
            color: AppColors.cyanAccent,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Consumer(
                  builder: (context, ref, _) {
                    final scheduleAsync = ref.watch(
                      scheduleDetailProvider(a.idLichHoc),
                    );
                    return scheduleAsync.when(
                      data: (s) => Text(
                        '${DateFormatter.formatVietnameseWeekday(s?.thuTrongTuan ?? 0)}: ${s?.gioBatDau} - ${s?.gioKetThuc}',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      loading: () => const Text(
                        '...',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                      error: (_, __) => const Text(
                        'Lỗi tải lịch',
                        style: TextStyle(color: AppColors.error),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 2),
                Consumer(
                  builder: (context, ref, _) {
                    final classAsync = ref.watch(classDetailProvider(a.idLop));
                    return classAsync.when(
                      data: (c) => Text(
                        'Lớp: ${c?.tenLop ?? 'Không xác định'}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      loading: () => const Text(
                        '...',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                      error: (_, __) => const Text(
                        'Lỗi tải lớp',
                        style: TextStyle(color: AppColors.error),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
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

    return AppSectionCard(
      margin: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: classAsync.when(
                        data: (c) => Text(
                          c?.tenLop ?? 'Lớp không xác định',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            decoration: c?.daLuuTru == true
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        loading: () => const Text(
                          '...',
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                        error: (_, __) => const Text(
                          'Lỗi',
                          style: TextStyle(color: AppColors.error),
                        ),
                      ),
                    ),
                    AppStatusChip(
                      label: isActive ? 'Đang học' : 'Đã nghỉ',
                      color: isActive ? AppColors.success : AppColors.textMuted,
                      compact: true,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Tham gia: ${DateFormatter.formatDisplayDate(m.tuNgay)}${m.denNgay != null ? ' - Nghỉ: ${DateFormatter.formatDisplayDate(m.denNgay!)}' : ''}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                if (m.lyDoKetThuc != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Lý do: ${m.lyDoKetThuc}',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontStyle: FontStyle.italic,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              side: const BorderSide(color: AppColors.border),
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => SessionCreditPage(
                    studentId: m.idHocSinh,
                    classId: m.idLop,
                  ),
                ),
              );
            },
            child: const Text(
              'Buổi dư',
              style: TextStyle(color: AppColors.cyanAccent, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Student student) {
    final isStopped = student.daLuuTru;
    return AppSectionCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          StudentAvatar(
            gioiTinh: student.gioiTinh,
            studentName: student.hoTen,
            radius: 32,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        student.hoTen,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    AppStatusChip(
                      label: isStopped ? 'Ngừng học' : 'Đang hoạt động',
                      color: isStopped ? AppColors.error : AppColors.success,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${student.khoi != null ? 'Khối ${student.khoi}' : 'Chưa xếp khối'} • ${student.truongDangHoc ?? 'Chưa cập nhật trường'}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _toggleArchiveStatus(
    BuildContext context,
    WidgetRef ref,
    Student student,
  ) async {
    final isStopped = student.daLuuTru;
    final confirm = await AppFeedback.showConfirmBottomSheet(
      context,
      title: isStopped ? 'Cho học sinh hoạt động lại' : 'Đánh dấu ngừng học',
      message: isStopped
          ? 'Bạn có chắc chắn muốn cho học sinh "${student.hoTen}" hoạt động lại tại trung tâm?'
          : 'Đánh dấu học sinh "${student.hoTen}" ngừng học nghĩa là dừng mọi hoạt động tại trung tâm.\n\n'
                '• Toàn bộ lịch sử học, điểm danh, học phí và thanh toán được GIỮ NGUYÊN.\n'
                '• Học sinh sẽ chuyển sang mục Ngừng học.\n'
                '• Không thể đánh dấu ngừng học nếu học sinh vẫn còn lớp đang tham gia.\n'
                '• Bạn có thể cho học sinh hoạt động lại bất kỳ lúc nào.',
      confirmLabel: isStopped ? 'Cho hoạt động lại' : 'Đánh dấu ngừng học',
      isDestructive: !isStopped,
    );

    if (!confirm || !context.mounted) return;

    try {
      if (isStopped) {
        await ref
            .read(studentListControllerProvider.notifier)
            .restore(student.id!);
      } else {
        await ref
            .read(studentListControllerProvider.notifier)
            .archive(student.id!);
      }
      ref.invalidate(studentDetailProvider(student.id!));
      ref.read(studentListControllerProvider.notifier).refresh();
      if (context.mounted) {
        AppFeedback.showSuccessSnackBar(
          context,
          isStopped
              ? 'Đã cho học sinh hoạt động lại'
              : 'Đã đánh dấu học sinh ngừng học',
        );
      }
    } catch (e) {
      if (context.mounted) {
        AppFeedback.showErrorSnackBar(
          context,
          e.toString().replaceAll('Exception: ', ''),
        );
      }
    }
  }
}

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
