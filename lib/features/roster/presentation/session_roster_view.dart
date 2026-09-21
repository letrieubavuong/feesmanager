import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../domain/roster_result.dart';
import '../domain/roster_member.dart';
import 'roster_controller.dart';
import '../../../core/utils/date_formatter.dart';
import '../../sessions/domain/class_session.dart';

class SessionRosterView extends ConsumerWidget {
  final int sessionId;
  const SessionRosterView({super.key, required this.sessionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rosterAsync = ref.watch(sessionRosterProvider(sessionId));

    return Scaffold(
      appBar: AppBar(title: const Text('Danh sách học sinh buổi học')),
      body: rosterAsync.when(
        data: (result) => _buildContent(context, result),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
      ),
    );
  }

  Widget _buildContent(BuildContext context, RosterResult result) {
    final s = result.session;
    final date = DateTime.parse(s.ngay);
    final weekday = DateFormatter.formatVietnameseWeekday(date.weekday);
    final formattedDate = DateFormat('dd/MM/yyyy').format(date);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Session Info Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$weekday, $formattedDate | ${s.gioBatDau} - ${s.gioKetThuc}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Loại: ${_getTypeLabel(s.loai)} | Trạng thái: ${_getStatusLabel(s.trangThai)}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),

        // Issues/Warnings Section
        if (result.issues.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: result.issues
                  .map((i) => _buildIssueTile(context, i))
                  .toList(),
            ),
          ),

        if (result.requiresOneOffAdjustments)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              color: Colors.blue.shade50,
              elevation: 0,
              child: const Padding(
                padding: EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Danh sách người tham gia buổi học này cần điều chỉnh buổi học (DOI_CA/HOC_BU) ở phase sau.',
                        style: TextStyle(color: Colors.blue, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Participant List
        Expanded(
          child:
              result.participants.isEmpty && !result.requiresOneOffAdjustments
              ? const Center(
                  child: Text('Không có học sinh nào thuộc buổi học này.'),
                )
              : ListView.builder(
                  itemCount: result.participants.length,
                  itemBuilder: (context, index) {
                    final member = result.participants[index];
                    return _buildMemberTile(context, member);
                  },
                ),
        ),

        // Unassigned Section
        if (result.unassignedMembers.isNotEmpty) ...[
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Học sinh chưa phân ca (${result.unassignedMembers.length})',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
          ),
          ...result.unassignedMembers.map(
            (st) => ListTile(
              dense: true,
              leading: const Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange,
                size: 16,
              ),
              title: Text(st.hoTen),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMemberTile(BuildContext context, RosterMember member) {
    return ListTile(
      leading: const CircleAvatar(child: Icon(Icons.person, size: 16)),
      title: Text(member.student.hoTen),
      subtitle: Text(
        member.source == RosterInclusionSource.SINGLE_SHIFT_MEMBERSHIP
            ? 'Tham gia lớp (1 ca)'
            : 'Phân ca trực tiếp',
        style: const TextStyle(fontSize: 12),
      ),
      trailing: member.student.daLuuTru
          ? const Chip(label: Text('Lưu trữ', style: TextStyle(fontSize: 10)))
          : null,
    );
  }

  Widget _buildIssueTile(BuildContext context, RosterIssue issue) {
    final isBlocking = issue.code != RosterIssueCode.UNASSIGNED_IN_MULTI_SHIFT;
    return Card(
      color: isBlocking ? Colors.red.shade50 : Colors.orange.shade50,
      child: ListTile(
        leading: Icon(
          isBlocking ? Icons.error_outline : Icons.warning_amber_rounded,
          color: isBlocking ? Colors.red : Colors.orange,
        ),
        title: Text(
          issue.message,
          style: TextStyle(
            color: isBlocking ? Colors.red : Colors.orange.shade900,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  String _getTypeLabel(SessionType type) {
    switch (type) {
      case SessionType.CHINH:
        return 'Chính thức';
      case SessionType.HOC_BU:
        return 'Học bù';
      case SessionType.PHAT_SINH:
        return 'Phát sinh';
    }
  }

  String _getStatusLabel(SessionStatus status) {
    switch (status) {
      case SessionStatus.DU_KIEN:
        return 'Dự kiến';
      case SessionStatus.DA_HOC:
        return 'Đã học';
      case SessionStatus.HUY:
        return 'Hủy';
      case SessionStatus.NGHI_LE:
        return 'Nghỉ lễ';
    }
  }
}
