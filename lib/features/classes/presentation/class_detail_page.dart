import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'class_controller.dart';
import 'class_form_page.dart';
import '../domain/class.dart';
import '../domain/class_service.dart';
import '../../memberships/domain/membership_service.dart';
import '../../memberships/domain/membership.dart';
import '../../memberships/presentation/add_student_to_class_dialog.dart';
import '../../memberships/presentation/membership_providers.dart';
import '../../students/presentation/student_detail_page.dart';

import '../../schedule/presentation/schedule_tab.dart';
import '../../schedule/presentation/assignment_tab.dart';
import '../../sessions/presentation/session_tab.dart';
import '../../leave/presentation/leave_request_page.dart';

class ClassDetailPage extends ConsumerStatefulWidget {
  final int classId;
  const ClassDetailPage({super.key, required this.classId});

  @override
  ConsumerState<ClassDetailPage> createState() => _ClassDetailPageState();
}

class _ClassDetailPageState extends ConsumerState<ClassDetailPage> {
  DateTime _referenceDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final classAsync = ref.watch(classDetailProvider(widget.classId));
    final rosterAsync = ref.watch(
      classRosterProvider((widget.classId, _referenceDate)),
    );
    final historyAsync = ref.watch(
      classMembershipHistoryProvider(widget.classId),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết lớp học'),
        actions: [
          classAsync.when(
            data: (cls) => cls == null
                ? const SizedBox.shrink()
                : Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => ClassFormPage(cls: cls),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.event_note),
                        tooltip: 'Đơn nghỉ học',
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                LeaveRequestPage(classId: widget.classId),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          cls.daLuuTru ? Icons.unarchive : Icons.archive,
                        ),
                        onPressed: () => _handleArchiveToggle(context, cls),
                      ),
                    ],
                  ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: classAsync.when(
        data: (cls) {
          if (cls == null) {
            return const Center(child: Text('Không tìm thấy lớp học'));
          }
          return Column(
            children: [
              _buildHeader(context, cls),
              Expanded(
                child: DefaultTabController(
                  length: 6,
                  child: Column(
                    children: [
                      const TabBar(
                        isScrollable: true,
                        tabs: [
                          Tab(text: 'Sĩ số'),
                          Tab(text: 'Lịch sử'),
                          Tab(text: 'Lịch học'),
                          Tab(text: 'Phân ca'),
                          Tab(text: 'Buổi học'),
                          Tab(text: 'Học phí'),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            Column(
                              children: [
                                _buildDateSelector(context),
                                Expanded(
                                  child: _buildRosterTab(context, rosterAsync),
                                ),
                              ],
                            ),
                            _buildHistoryTab(context, historyAsync),
                            ScheduleTab(classId: widget.classId),
                            AssignmentTab(classId: widget.classId),
                            SessionTab(classId: widget.classId),
                            _buildPlaceholder('Học phí'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddStudentDialog(context),
        child: const Icon(Icons.person_add),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ClassEntity cls) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            child: Text(
              cls.tenLop[0].toUpperCase(),
              style: const TextStyle(fontSize: 24),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cls.tenLop,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${cls.monHoc ?? 'Môn chưa xác định'} • Khối ${cls.khoi ?? '?'}',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Xem danh sách tại ngày: '),
          TextButton.icon(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _referenceDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );
              if (picked != null) setState(() => _referenceDate = picked);
            },
            icon: const Icon(Icons.calendar_today, size: 16),
            label: Text(DateFormat('dd/MM/yyyy').format(_referenceDate)),
          ),
        ],
      ),
    );
  }

  Widget _buildRosterTab(
    BuildContext context,
    AsyncValue<List<ClassMembership>> rosterAsync,
  ) {
    return rosterAsync.when(
      data: (memberships) {
        if (memberships.isEmpty) {
          return const Center(
            child: Text('Không có học sinh nào trong ngày này.'),
          );
        }
        return ListView.builder(
          itemCount: memberships.length,
          itemBuilder: (context, index) {
            final m = memberships[index];
            return RosterItem(membership: m);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Lỗi: $e')),
    );
  }

  Widget _buildHistoryTab(
    BuildContext context,
    AsyncValue<List<ClassMembership>> historyAsync,
  ) {
    return historyAsync.when(
      data: (memberships) {
        if (memberships.isEmpty) {
          return const Center(child: Text('Không có lịch sử tham gia nào.'));
        }
        return ListView.builder(
          itemCount: memberships.length,
          itemBuilder: (context, index) {
            final m = memberships[index];
            return HistoryItem(membership: m);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Lỗi: $e')),
    );
  }

  Widget _buildPlaceholder(String title) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.construction, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'Chức năng $title',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const Text('Sẽ được triển khai ở phase sau.'),
        ],
      ),
    );
  }

  void _handleArchiveToggle(BuildContext context, ClassEntity cls) async {
    if (!cls.daLuuTru) {
      final activeCount = await ref
          .read(classServiceProvider.future)
          .then((s) => s.getActiveMemberCount(cls.id!));
      if (activeCount > 0 && context.mounted) {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Lưu trữ lớp học'),
            content: Text(
              'Lớp hiện còn $activeCount học sinh đang học. Bạn vẫn muốn lưu trữ lớp này?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Hủy'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Vẫn lưu trữ'),
              ),
            ],
          ),
        );
        if (confirm != true) return;
      }
      await ref.read(classListControllerProvider.notifier).archive(cls.id!);
    } else {
      await ref.read(classListControllerProvider.notifier).restore(cls.id!);
    }
    if (context.mounted) {
      ref.invalidate(classDetailProvider(cls.id!));
    }
  }

  void _showAddStudentDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AddStudentToClassDialog(
        classId: widget.classId,
        onSuccess: () {
          ref.invalidate(classRosterProvider);
          ref.invalidate(classSizeProvider);
          ref.invalidate(classMembershipHistoryProvider);
        },
      ),
    );
  }
}

class HistoryItem extends ConsumerWidget {
  final ClassMembership membership;
  const HistoryItem({super.key, required this.membership});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentAsync = ref.watch(studentDetailProvider(membership.idHocSinh));
    final isActive = membership.isActiveOn(DateTime.now());

    return ListTile(
      leading: const CircleAvatar(child: Icon(Icons.history)),
      title: studentAsync.when(
        data: (s) => Text(
          s?.hoTen ?? 'Unknown',
          style: TextStyle(fontWeight: isActive ? FontWeight.bold : null),
        ),
        loading: () => const Text('Loading...'),
        error: (_, __) => const Text('Error'),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Từ: ${membership.tuNgay}${membership.denNgay != null ? ' - Đến: ${membership.denNgay}' : ''}',
          ),
          if (membership.lyDoKetThuc != null)
            Text(
              'Lý do nghỉ: ${membership.lyDoKetThuc}',
              style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
            ),
        ],
      ),
      trailing: !isActive
          ? TextButton(
              onPressed: () => _showReEnrollDialog(context, ref),
              child: const Text('Học lại'),
            )
          : const Icon(Icons.check_circle, color: Colors.green, size: 16),
    );
  }

  void _showReEnrollDialog(BuildContext context, WidgetRef ref) {
    final dateController = TextEditingController(
      text: DateFormat('yyyy-MM-dd').format(DateTime.now()),
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Học sinh học lại'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Ngày học lại:'),
            TextField(
              controller: dateController,
              decoration: const InputDecoration(hintText: 'YYYY-MM-DD'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              try {
                final service = await ref.read(
                  membershipServiceProvider.future,
                );
                await service.enrollStudent(
                  studentId: membership.idHocSinh,
                  classId: membership.idLop,
                  joinDate: DateTime.parse(dateController.text),
                  mienGiam: membership.mienGiamPhanTram,
                );
                if (context.mounted) {
                  Navigator.pop(context);
                  ref.invalidate(classRosterProvider);
                  ref.invalidate(classSizeProvider);
                  ref.invalidate(classMembershipHistoryProvider);
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString().replaceAll('Exception: ', '')),
                    ),
                  );
                }
              }
            },
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }
}

class RosterItem extends ConsumerWidget {
  final ClassMembership membership;
  const RosterItem({super.key, required this.membership});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentAsync = ref.watch(studentDetailProvider(membership.idHocSinh));

    return ListTile(
      leading: const CircleAvatar(child: Icon(Icons.person)),
      title: studentAsync.when(
        data: (s) => Text(s?.hoTen ?? 'Unknown'),
        loading: () => const Text('Loading...'),
        error: (_, __) => const Text('Error'),
      ),
      subtitle: Text(
        'Từ: ${membership.tuNgay}${membership.denNgay != null ? ' - Đến: ${membership.denNgay}' : ''}',
      ),
      trailing: IconButton(
        icon: const Icon(Icons.logout),
        onPressed: () => _showLeaveDialog(context, ref),
      ),
    );
  }

  void _showLeaveDialog(BuildContext context, WidgetRef ref) {
    DateTime endDate = DateTime.now();
    String? selectedReason = 'TAM_NGUNG';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Học sinh nghỉ lớp'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Ngày nghỉ (Ngày cuối học)'),
                subtitle: Text(DateFormat('dd/MM/yyyy').format(endDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: endDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setDialogState(() => endDate = picked);
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedReason,
                items: const [
                  DropdownMenuItem(value: 'TAM_NGUNG', child: Text('Tạm nghỉ')),
                  DropdownMenuItem(value: 'NGHI_HOC', child: Text('Nghỉ lớp')),
                ],
                onChanged: (v) => setDialogState(() => selectedReason = v),
                decoration: const InputDecoration(labelText: 'Lý do'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  final service = await ref.read(
                    membershipServiceProvider.future,
                  );
                  await service.leaveClass(
                    studentId: membership.idHocSinh,
                    classId: membership.idLop,
                    endDate: endDate,
                    reason: selectedReason,
                  );
                  if (context.mounted) {
                    Navigator.pop(context);
                    ref.invalidate(classRosterProvider);
                    ref.invalidate(classSizeProvider);
                    ref.invalidate(classMembershipHistoryProvider);
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(e.toString())));
                  }
                }
              },
              child: const Text('Xác nhận'),
            ),
          ],
        ),
      ),
    );
  }
}

final classMembershipHistoryProvider =
    FutureProvider.family<List<ClassMembership>, int>((ref, classId) async {
      final repo = await ref.watch(membershipRepositoryProvider.future);
      return repo.getByClass(classId);
    });
