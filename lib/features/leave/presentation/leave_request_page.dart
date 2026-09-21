import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../memberships/domain/membership_service.dart';
import '../../students/domain/student_service.dart';
import '../domain/leave_request.dart';
import 'leave_request_controller.dart';

class LeaveRequestPage extends ConsumerStatefulWidget {
  final int classId;

  const LeaveRequestPage({super.key, required this.classId});

  @override
  ConsumerState<LeaveRequestPage> createState() => _LeaveRequestPageState();
}

class _LeaveRequestPageState extends ConsumerState<LeaveRequestPage> {
  LeaveRequestStatus? _statusFilter;

  @override
  Widget build(BuildContext context) {
    final listAsync = ref.watch(leaveRequestControllerProvider(widget.classId));

    return Scaffold(
      appBar: AppBar(title: const Text('Đơn nghỉ học')),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: listAsync.when(
              data: (list) {
                final filtered = _statusFilter == null
                    ? list
                    : list.where((r) => r.trangThai == _statusFilter).toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text('Không có đơn nghỉ học nào'));
                }

                return ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final req = filtered[index];
                    return _buildRequestTile(req);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text(err.toString())),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Tạo đơn nghỉ'),
      ),
    );
  }

  Widget _buildFilterBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          FilterChip(
            label: const Text('Tất cả'),
            selected: _statusFilter == null,
            onSelected: (_) => setState(() => _statusFilter = null),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Chờ duyệt'),
            selected: _statusFilter == LeaveRequestStatus.CHO_DUYET,
            onSelected: (_) =>
                setState(() => _statusFilter = LeaveRequestStatus.CHO_DUYET),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Đã duyệt'),
            selected: _statusFilter == LeaveRequestStatus.DA_DUYET,
            onSelected: (_) =>
                setState(() => _statusFilter = LeaveRequestStatus.DA_DUYET),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Từ chối'),
            selected: _statusFilter == LeaveRequestStatus.TU_CHOI,
            onSelected: (_) =>
                setState(() => _statusFilter = LeaveRequestStatus.TU_CHOI),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestTile(LeaveRequest req) {
    return FutureBuilder(
      future: ref
          .read(studentServiceProvider.future)
          .then((s) => s.getStudentById(req.idHocSinh)),
      builder: (context, snapshot) {
        final studentName =
            snapshot.data?.hoTen ?? 'Học sinh ID: ${req.idHocSinh}';

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      studentName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildStatusChip(req.trangThai),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Thời gian: ${req.tuNgay} đến ${req.denNgay}',
                style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
              ),
              if (req.lyDo != null && req.lyDo!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'Lý do: ${req.lyDo}',
                  style: const TextStyle(fontSize: 13),
                ),
              ],
              if (req.trangThai == LeaveRequestStatus.CHO_DUYET) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => _handleReject(req.id!),
                      child: const Text(
                        'Từ chối',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => _handleApprove(req.id!),
                      child: const Text('Duyệt'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(LeaveRequestStatus status) {
    Color color;
    String label;
    switch (status) {
      case LeaveRequestStatus.CHO_DUYET:
        color = Colors.orange;
        label = 'Chờ duyệt';
        break;
      case LeaveRequestStatus.DA_DUYET:
        color = Colors.green;
        label = 'Đã duyệt';
        break;
      case LeaveRequestStatus.TU_CHOI:
        color = Colors.red;
        label = 'Từ chối';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _handleApprove(int id) async {
    try {
      await ref
          .read(leaveRequestControllerProvider(widget.classId).notifier)
          .approve(id);
    } catch (e) {
      if (mounted) _showError(e.toString());
    }
  }

  void _handleReject(int id) async {
    try {
      await ref
          .read(leaveRequestControllerProvider(widget.classId).notifier)
          .reject(id);
    } catch (e) {
      if (mounted) _showError(e.toString());
    }
  }

  void _showCreateDialog(BuildContext context) async {
    final membershipService = await ref.read(membershipServiceProvider.future);
    final studentService = await ref.read(studentServiceProvider.future);

    final rosterMemberships = await membershipService.getRoster(
      widget.classId,
      date: DateTime.now(),
    );
    final students = await studentService.getStudents();
    final studentMap = {for (var s in students) s.id: s};

    final classStudents = rosterMemberships
        .map((m) => studentMap[m.idHocSinh])
        .whereType<dynamic>()
        .toList();

    if (!context.mounted) return;

    int? selectedStudentId = classStudents.isNotEmpty
        ? classStudents.first.id
        : null;
    final tuNgayController = TextEditingController(
      text: DateTime.now().toIso8601String().substring(0, 10),
    );
    final denNgayController = TextEditingController(
      text: DateTime.now().toIso8601String().substring(0, 10),
    );
    final lyDoController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Tạo đơn nghỉ học'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  initialValue: selectedStudentId,
                  decoration: const InputDecoration(labelText: 'Học sinh'),
                  items: classStudents.map((s) {
                    return DropdownMenuItem<int>(
                      value: s.id,
                      child: Text(s.hoTen),
                    );
                  }).toList(),
                  onChanged: (val) =>
                      setDialogState(() => selectedStudentId = val),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: tuNgayController,
                  decoration: const InputDecoration(
                    labelText: 'Từ ngày (YYYY-MM-DD)',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: denNgayController,
                  decoration: const InputDecoration(
                    labelText: 'Đến ngày (YYYY-MM-DD)',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: lyDoController,
                  decoration: const InputDecoration(
                    labelText: 'Lý do xin nghỉ',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: selectedStudentId == null
                  ? null
                  : () async {
                      try {
                        final req = LeaveRequest(
                          idHocSinh: selectedStudentId!,
                          idLop: widget.classId,
                          tuNgay: tuNgayController.text.trim(),
                          denNgay: denNgayController.text.trim(),
                          lyDo: lyDoController.text.trim(),
                          createdAt: DateTime.now(),
                          updatedAt: DateTime.now(),
                        );
                        await ref
                            .read(
                              leaveRequestControllerProvider(
                                widget.classId,
                              ).notifier,
                            )
                            .createLeaveRequest(req);
                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext);
                        }
                      } catch (e) {
                        if (dialogContext.mounted) {
                          _showError(e.toString());
                        }
                      }
                    },
              child: const Text('Tạo đơn'),
            ),
          ],
        ),
      ),
    );
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lỗi'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }
}
