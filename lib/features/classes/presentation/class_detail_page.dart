import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/common_widgets/app_feedback.dart';
import '../../../app/common_widgets/navy_components.dart';
import '../../../app/common_widgets/parent_contact_actions.dart';
import '../../../app/common_widgets/student_avatar.dart';
import '../../../app/design_system/app_theme.dart';
import '../../../app/navigation/app_global_drawer.dart';
import '../../../app/navigation/ui_keys.dart';
import '../../../core/utils/date_formatter.dart';
import '../../attendance/domain/class_attendance_timeline_item.dart';
import '../../attendance/domain/attendance_service.dart';
import '../../attendance/presentation/attendance_page.dart';
import '../../attendance/presentation/class_attendance_timeline_controller.dart';
import '../../leave/presentation/leave_request_page.dart';
import '../../memberships/domain/membership.dart';
import '../../memberships/domain/membership_service.dart';
import '../../memberships/presentation/enroll_student_bottom_sheet.dart';
import '../../memberships/presentation/leave_class_bottom_sheet.dart';
import '../../memberships/presentation/membership_providers.dart';
import '../../memberships/presentation/re_enroll_student_bottom_sheet.dart';
import '../../schedule/presentation/assignment_tab.dart';
import '../../schedule/presentation/schedule_tab.dart';
import '../../sessions/domain/class_session.dart';
import '../../sessions/presentation/session_tab.dart';
import '../../students/presentation/student_detail_page.dart';
import '../../tuition/presentation/class_tuition_tab.dart';
import '../../tuition/presentation/create_tuition_policy_bottom_sheet.dart';
import '../../tuition/domain/tuition_policy_service.dart';
import '../../tuition/presentation/tuition_controller.dart';
import '../domain/class.dart';
import '../domain/class_service.dart';
import 'class_controller.dart';
import 'class_form_bottom_sheet.dart';

class ClassDetailPage extends ConsumerStatefulWidget {
  final int classId;
  const ClassDetailPage({super.key, required this.classId});

  @override
  ConsumerState<ClassDetailPage> createState() => _ClassDetailPageState();
}

class _ClassDetailPageState extends ConsumerState<ClassDetailPage> {
  Future<void> _changeClassTuitionPolicy() async {
    try {
      final service = await ref.read(tuitionPolicyServiceProvider.future);
      final policies = await service.getPoliciesForClass(widget.classId);
      if (!mounted) return;
      final latest = policies.isEmpty ? null : policies.first;
      final now = DateTime.now();
      final latestStart = latest == null
          ? now
          : DateTime.parse(latest.hieuLucTu);
      final baseMonth = latestStart.isAfter(now) ? latestStart : now;
      final start = latest == null
          ? DateTime(now.year, now.month, 1)
          : DateTime(baseMonth.year, baseMonth.month + 1, 1);
      final saved = await showCreateTuitionPolicyBottomSheet(
        context,
        classId: widget.classId,
        initialMonth: DateFormat('yyyy-MM').format(start),
        previousPolicy: latest,
      );
      if (saved == true) {
        ref.invalidate(classTuitionPoliciesProvider(widget.classId));
      }
    } catch (e) {
      if (!mounted) return;
      AppFeedback.showErrorSnackBar(
        context,
        e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  DateTime _referenceDate = DateTime.now();
  DateTime _timelineMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    1,
  );
  String _attendanceFilter = 'DU_KIEN';

  Future<void> _showHistoricalAttendanceSheet() async {
    final month = DateTime(_timelineMonth.year, _timelineMonth.month);
    final start = DateFormat('yyyy-MM-dd').format(month);
    final end = DateFormat(
      'yyyy-MM-dd',
    ).format(DateTime(month.year, month.month + 1, 0));
    final service = await ref.read(attendanceServiceProvider.future);
    if (!mounted) return;
    HistoricalAttendancePreview? preview;
    String? error;
    try {
      preview = await service.backfillHistoricalAttendance(
        classId: widget.classId,
        fromDate: start,
        toDate: end,
      );
    } catch (e) {
      error = e.toString().replaceFirst('Invalid argument(s): ', '');
    }
    if (!mounted) return;
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Điểm danh bù',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Tháng ${DateFormat('MM/yyyy').format(month)}',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              Text(
                error ??
                    '${preview!.sessionCount} buổi, ${preview.studentCount} lượt học sinh chưa điểm danh; ${preview.excusedCount} lượt nghỉ có phép đã duyệt. Bỏ qua ${preview.skippedCount} buổi hủy, nghỉ lễ, đã hoàn tất hoặc dữ liệu chưa hợp lệ.',
                style: const TextStyle(color: AppColors.textPrimary),
              ),
              const SizedBox(height: 12),
              const Text(
                'Các lượt còn thiếu sẽ được đánh dấu Có mặt, riêng đơn nghỉ đã duyệt là Nghỉ có phép. Điểm danh đã lưu được giữ nguyên. Hãy kiểm tra và sửa từng buổi nếu thực tế khác.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(sheetContext, false),
                    child: const Text('Đóng'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: error != null || preview!.studentCount == 0
                        ? null
                        : () => Navigator.pop(sheetContext, true),
                    child: const Text('Lưu điểm danh bù'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmed != true) return;
    try {
      final result = await service.backfillHistoricalAttendance(
        classId: widget.classId,
        fromDate: start,
        toDate: end,
        save: true,
      );
      if (!mounted) return;
      ref.invalidate(
        classAttendanceTimelineProvider(
          classId: widget.classId,
          yearMonth: DateFormat('yyyy-MM').format(month),
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Đã cập nhật ${result.studentCount} lượt trong ${result.sessionCount} buổi.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Không thể điểm danh bù: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final classAsync = ref.watch(classDetailProvider(widget.classId));
    final rosterAsync = ref.watch(
      classRosterProvider((widget.classId, _referenceDate)),
    );
    final historyAsync = ref.watch(
      classMembershipHistoryProvider(widget.classId),
    );
    final sizeAsync = ref.watch(classSizeProvider(widget.classId));

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const AppGlobalDrawer(),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: const BackButton(),
        title: classAsync.when(
          data: (cls) => Text(
            cls == null
                ? 'Chi tiết lớp học'
                : '${cls.tenLop} - Sĩ số: ${sizeAsync.valueOrNull ?? '…'}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          loading: () => const Text('Đang tải lớp học'),
          error: (_, __) => const Text('Chi tiết lớp học'),
        ),
        actions: const [GlobalMenuButton()],
      ),
      body: classAsync.when(
        data: (cls) {
          if (cls == null) {
            return const Center(
              child: Text(
                'Không tìm thấy lớp học',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            );
          }
          final isStopped = cls.daLuuTru;
          return Column(
            children: [
              if (isStopped)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  color: AppColors.error.withValues(alpha: 0.15),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppColors.error,
                        size: 20,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Lớp đã ngừng hoạt động. Dữ liệu lịch sử vẫn được giữ nguyên. Kích hoạt lại lớp để tiếp tục hoạt động.',
                          style: TextStyle(
                            color: AppColors.error,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              _buildHeader(context, cls, sizeAsync),
              Expanded(
                child: DefaultTabController(
                  length: 7,
                  child: Builder(
                    builder: (tabContext) {
                      final tabs = DefaultTabController.of(tabContext);
                      return AnimatedBuilder(
                        animation: tabs,
                        builder: (context, _) => Stack(
                          children: [
                            Column(
                              children: [
                                Container(
                                  color: AppColors.surface,
                                  child: const TabBar(
                                    isScrollable: true,
                                    indicatorColor: AppColors.cyanAccent,
                                    labelColor: AppColors.cyanAccent,
                                    unselectedLabelColor:
                                        AppColors.textSecondary,
                                    labelStyle: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    unselectedLabelStyle: TextStyle(
                                      fontSize: 13,
                                    ),
                                    tabs: [
                                      Tab(text: 'Sĩ số'),
                                      Tab(text: 'Lịch học'),
                                      Tab(text: 'Phân ca'),
                                      Tab(text: 'Buổi học'),
                                      Tab(text: 'Điểm danh'),
                                      Tab(text: 'Học phí'),
                                      Tab(text: 'Lịch sử'),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: TabBarView(
                                    children: [
                                      Column(
                                        children: [
                                          _buildDateSelector(context),
                                          Expanded(
                                            child: _buildRosterTab(
                                              context,
                                              rosterAsync,
                                              isStopped,
                                            ),
                                          ),
                                        ],
                                      ),
                                      ScheduleTab(
                                        classId: widget.classId,
                                        isArchived: isStopped,
                                      ),
                                      AssignmentTab(
                                        classId: widget.classId,
                                        isArchived: isStopped,
                                      ),
                                      SessionTab(
                                        classId: widget.classId,
                                        isArchived: isStopped,
                                      ),
                                      _buildAttendanceTab(context),
                                      ClassTuitionTab(classId: widget.classId),
                                      _buildHistoryTab(context, historyAsync),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (!isStopped &&
                                (tabs.index == 0 || tabs.index == 1))
                              Positioned(
                                right: 20,
                                bottom: 20,
                                child: FloatingActionButton(
                                  heroTag: 'class-detail-add-${widget.classId}',
                                  tooltip: tabs.index == 0
                                      ? 'Thêm học sinh'
                                      : 'Thêm lịch học',
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  onPressed: () => tabs.index == 0
                                      ? _showAddStudentDialog(context)
                                      : showScheduleFormBottomSheet(
                                          context,
                                          classId: widget.classId,
                                        ),
                                  child: Icon(
                                    tabs.index == 0
                                        ? Icons.person_add_outlined
                                        : Icons.event_available_outlined,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
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

  Widget _buildHeader(
    BuildContext context,
    ClassEntity cls,
    AsyncValue<int> sizeAsync,
  ) {
    return AppSectionCard(
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 2),
          Row(
            children: [
              _headerAction(Icons.edit_outlined, 'Sửa lớp', () async {
                await showClassFormBottomSheet(context, cls: cls);
                ref.invalidate(classDetailProvider(widget.classId));
                ref.read(classListControllerProvider.notifier).refresh();
              }),
              _headerAction(
                Icons.request_quote_outlined,
                'Học phí',
                _changeClassTuitionPolicy,
              ),
              _headerAction(
                Icons.event_note_outlined,
                'Đơn nghỉ',
                () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => LeaveRequestPage(classId: widget.classId),
                  ),
                ),
              ),
              _headerAction(
                cls.daLuuTru
                    ? Icons.restore_rounded
                    : Icons.folder_off_outlined,
                cls.daLuuTru ? 'Kích hoạt' : 'Ngừng lớp',
                () => _handleArchiveToggle(context, cls),
                key: cls.daLuuTru
                    ? UiKeys.classRestoreAction
                    : UiKeys.classArchiveAction,
                color: cls.daLuuTru ? AppColors.success : AppColors.error,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerAction(
    IconData icon,
    String label,
    VoidCallback onPressed, {
    Key? key,
    Color color = AppColors.cyanAccent,
  }) {
    return Expanded(
      child: InkWell(
        key: key,
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(height: 5),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateSelector(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Text(
            'Sĩ số tại ngày:',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.border),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _referenceDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );
              if (picked != null) setState(() => _referenceDate = picked);
            },
            icon: const Icon(
              Icons.calendar_today,
              size: 14,
              color: AppColors.cyanAccent,
            ),
            label: Text(
              DateFormat('dd/MM/yyyy').format(_referenceDate),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRosterTab(
    BuildContext context,
    AsyncValue<List<ClassMembership>> rosterAsync,
    bool isArchived,
  ) {
    return Column(
      children: [
        Expanded(
          child: rosterAsync.when(
            data: (memberships) {
              if (memberships.isEmpty) {
                return const Center(
                  child: Text(
                    'Không có học sinh nào tham gia trong ngày này.',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                itemCount: memberships.length,
                itemBuilder: (context, index) {
                  final m = memberships[index];
                  return RosterItem(membership: m);
                },
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
        ),
      ],
    );
  }

  Widget _buildAttendanceTab(BuildContext context) {
    final yearMonth = DateFormat('yyyy-MM').format(_timelineMonth);
    final monthDisplay =
        'Tháng ${DateFormat('MM/yyyy').format(_timelineMonth)}';

    final timelineAsync = ref.watch(
      classAttendanceTimelineProvider(
        classId: widget.classId,
        yearMonth: yearMonth,
      ),
    );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
          child: AppSectionCard(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.chevron_left,
                    color: AppColors.cyanAccent,
                  ),
                  onPressed: () {
                    setState(() {
                      _timelineMonth = DateTime(
                        _timelineMonth.year,
                        _timelineMonth.month - 1,
                        1,
                      );
                    });
                  },
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.calendar_month_outlined,
                      color: AppColors.cyanAccent,
                      size: 17,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      monthDisplay,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  tooltip: 'Điểm danh bù tháng đang xem',
                  icon: const Icon(
                    Icons.fact_check_outlined,
                    color: AppColors.cyanAccent,
                  ),
                  onPressed: _showHistoricalAttendanceSheet,
                ),
                IconButton(
                  icon: const Icon(
                    Icons.chevron_right,
                    color: AppColors.cyanAccent,
                  ),
                  onPressed: () {
                    setState(() {
                      _timelineMonth = DateTime(
                        _timelineMonth.year,
                        _timelineMonth.month + 1,
                        1,
                      );
                    });
                  },
                ),
              ],
            ),
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          child: Row(
            children: [
              const Text(
                'Trạng thái',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Chưa hoàn tất',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
              ),
              Switch.adaptive(
                value: _attendanceFilter == 'DA_HOC',
                onChanged: (done) => setState(
                  () => _attendanceFilter = done ? 'DA_HOC' : 'DU_KIEN',
                ),
              ),
              const Text(
                'Đã hoàn tất',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
              ),
            ],
          ),
        ),

        const Divider(color: AppColors.border, height: 1),

        // Timeline Content
        Expanded(
          child: timelineAsync.when(
            data: (items) {
              if (items.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Text(
                      'Tháng này chưa có buổi học.',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                );
              }

              final filtered = items.where((item) {
                if (_attendanceFilter == 'DU_KIEN') {
                  return item.session.trangThai == SessionStatus.DU_KIEN;
                } else if (_attendanceFilter == 'DA_HOC') {
                  return item.session.trangThai == SessionStatus.DA_HOC;
                }
                return true;
              }).toList();

              if (filtered.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Text(
                      'Không có buổi học phù hợp bộ lọc.',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final item = filtered[index];
                  final isLast = index == filtered.length - 1;
                  return _buildTimelineRow(context, item, isLast, yearMonth);
                },
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
        ),
      ],
    );
  }

  ButtonStyle _compactTimelineButtonStyle({
    required bool filled,
    Color? backgroundColor,
    Color? foregroundColor,
  }) {
    if (filled) {
      return ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        minimumSize: const Size(0, 28),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 0),
        visualDensity: const VisualDensity(horizontal: -2, vertical: -3),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 0,
      );
    }

    return OutlinedButton.styleFrom(
      foregroundColor: foregroundColor,
      minimumSize: const Size(0, 28),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 0),
      visualDensity: const VisualDensity(horizontal: -2, vertical: -3),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      side: const BorderSide(color: AppColors.border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  Widget _buildTimelineRow(
    BuildContext context,
    ClassAttendanceTimelineItem item,
    bool isLast,
    String yearMonth,
  ) {
    final session = item.session;
    final date = DateTime.parse(session.ngay);
    final dayStr = DateFormat('dd/MM').format(date);
    final weekdayStr =
        '${DateFormatter.formatVietnameseWeekday(date.weekday)} • ${session.gioBatDau}–${session.gioKetThuc}';

    Color nodeColor;
    String statusText;
    switch (session.trangThai) {
      case SessionStatus.DU_KIEN:
        nodeColor = AppColors.warning;
        statusText = '◷ Chưa hoàn tất';
        break;
      case SessionStatus.DA_HOC:
        nodeColor = AppColors.success;
        statusText = '✓ Đã hoàn tất';
        break;
      case SessionStatus.HUY:
        nodeColor = AppColors.error;
        statusText = 'Đã hủy';
        break;
      case SessionStatus.NGHI_LE:
        nodeColor = AppColors.textMuted;
        statusText = 'Nghỉ lễ';
        break;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left Rail Column
          SizedBox(
            width: 54,
            child: Column(
              children: [
                Text(
                  dayStr,
                  style: TextStyle(
                    color: nodeColor,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: nodeColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: nodeColor.withValues(alpha: 0.4),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  Expanded(child: Container(width: 2, color: AppColors.border)),
              ],
            ),
          ),

          // Right Card
          Expanded(
            child: AppSectionCard(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          weekdayStr,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      AppStatusChip(
                        label: statusText,
                        color: nodeColor,
                        compact: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      AppStatusChip(
                        label: session.loai.displayName,
                        color: AppColors.cyanAccent,
                        compact: true,
                      ),
                      if (item.hasCorrectionHistory)
                        const AppStatusChip(
                          label: 'Đã chỉnh sửa',
                          color: AppColors.cyanAccent,
                          compact: true,
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (session.trangThai != SessionStatus.HUY &&
                      session.trangThai != SessionStatus.NGHI_LE) ...[
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _buildSummaryBadge(
                          'Có mặt ${item.presentCount}',
                          AppColors.success,
                        ),
                        _buildSummaryBadge(
                          'Trễ ${item.lateCount}',
                          AppColors.warning,
                        ),
                        _buildSummaryBadge(
                          'Có phép ${item.excusedCount}',
                          AppColors.cyanAccent,
                        ),
                        _buildSummaryBadge(
                          'Không phép ${item.unexcusedCount}',
                          AppColors.error,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                  ],

                  // Action Buttons
                  if (session.trangThai == SessionStatus.DU_KIEN)
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        style: _compactTimelineButtonStyle(
                          filled: true,
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  AttendancePage(sessionId: session.id!),
                            ),
                          );
                          ref.invalidate(
                            classAttendanceTimelineProvider(
                              classId: widget.classId,
                              yearMonth: yearMonth,
                            ),
                          );
                        },
                        icon: const Icon(Icons.fact_check_outlined, size: 13),
                        label: const Text(
                          'Điểm danh',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    )
                  else if (session.trangThai == SessionStatus.DA_HOC)
                    Align(
                      alignment: Alignment.centerRight,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            OutlinedButton(
                              style: _compactTimelineButtonStyle(
                                filled: false,
                                foregroundColor: AppColors.textSecondary,
                              ),
                              onPressed: () async {
                                await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        AttendancePage(sessionId: session.id!),
                                  ),
                                );
                                ref.invalidate(
                                  classAttendanceTimelineProvider(
                                    classId: widget.classId,
                                    yearMonth: yearMonth,
                                  ),
                                );
                              },
                              child: const Text(
                                'Xem',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            ElevatedButton.icon(
                              style: _compactTimelineButtonStyle(
                                filled: true,
                                backgroundColor: AppColors.warning,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () async {
                                await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        AttendancePage(sessionId: session.id!),
                                  ),
                                );
                                ref.invalidate(
                                  classAttendanceTimelineProvider(
                                    classId: widget.classId,
                                    yearMonth: yearMonth,
                                  ),
                                );
                              },
                              icon: const Icon(
                                Icons.edit_note_rounded,
                                size: 13,
                              ),
                              label: const Text(
                                'Sửa điểm danh',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildHistoryTab(
    BuildContext context,
    AsyncValue<List<ClassMembership>> historyAsync,
  ) {
    return historyAsync.when(
      data: (memberships) {
        if (memberships.isEmpty) {
          return const Center(
            child: Text(
              'Không có lịch sử tham gia nào.',
              style: TextStyle(
                color: AppColors.textMuted,
                fontStyle: FontStyle.italic,
              ),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          itemCount: memberships.length,
          itemBuilder: (context, index) {
            final m = memberships[index];
            return HistoryItem(membership: m);
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (e, _) => Center(
        child: Text('Lỗi: $e', style: const TextStyle(color: AppColors.error)),
      ),
    );
  }

  void _handleArchiveToggle(BuildContext context, ClassEntity cls) async {
    final isStopped = cls.daLuuTru;
    try {
      if (!isStopped) {
        final activeCount = await ref
            .read(classServiceProvider.future)
            .then((s) => s.getActiveMemberCount(cls.id!));
        if (activeCount > 0) {
          if (context.mounted) {
            AppFeedback.showErrorSnackBar(
              context,
              'Lớp hiện có $activeCount học sinh đang học. Hãy kết thúc các membership trước khi ngừng hoạt động lớp.',
            );
          }
          return;
        }
        if (!context.mounted) return;
        final confirm = await AppFeedback.showConfirmBottomSheet(
          context,
          title: 'Ngừng hoạt động lớp học',
          message:
              'Ngừng hoạt động lớp "${cls.tenLop}" nghĩa là lớp tạm thời không nhận học sinh mới.\n\n'
              '• Toàn bộ dữ liệu lịch sử, điểm danh và học phí vẫn được GIỮ NGUYÊN.\n'
              '• Lớp sẽ chuyển sang danh sách Ngừng hoạt động.\n'
              '• Bạn có thể kích hoạt lại lớp bất kỳ lúc nào.',
          confirmLabel: 'Ngừng hoạt động',
          isDestructive: true,
        );
        if (confirm != true || !context.mounted) return;
        await ref.read(classListControllerProvider.notifier).archive(cls.id!);
      } else {
        final confirm = await AppFeedback.showConfirmBottomSheet(
          context,
          title: 'Kích hoạt lại lớp học',
          message: 'Bạn có chắc chắn muốn kích hoạt lại lớp "${cls.tenLop}"?',
          confirmLabel: 'Kích hoạt lại',
        );
        if (confirm != true || !context.mounted) return;
        await ref.read(classListControllerProvider.notifier).restore(cls.id!);
      }
      if (context.mounted) {
        ref.invalidate(classDetailProvider(cls.id!));
        ref.read(classListControllerProvider.notifier).refresh();
        AppFeedback.showSuccessSnackBar(
          context,
          isStopped ? 'Đã kích hoạt lại lớp học' : 'Đã ngừng hoạt động lớp học',
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

  void _showAddStudentDialog(BuildContext context) async {
    final success = await showEnrollStudentBottomSheet(
      context,
      classId: widget.classId,
      allowMultiple: true,
    );
    if (success == true) {
      ref.invalidate(classRosterProvider);
      ref.invalidate(classSizeProvider);
      ref.invalidate(classMembershipHistoryProvider);
    }
  }
}

class HistoryItem extends ConsumerWidget {
  final ClassMembership membership;
  const HistoryItem({super.key, required this.membership});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentAsync = ref.watch(studentDetailProvider(membership.idHocSinh));
    final isActive = membership.isActiveOn(DateTime.now());

    return AppSectionCard(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => StudentDetailPage(studentId: membership.idHocSinh),
        ),
      ),
      child: Row(
        children: [
          studentAsync.when(
            data: (s) => StudentAvatar(
              gioiTinh: s?.gioiTinh,
              studentName: s?.hoTen,
              radius: 20,
            ),
            loading: () => const CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.surfaceHigh,
              child: Icon(Icons.history, size: 18),
            ),
            error: (_, __) => const CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.surfaceHigh,
              child: Icon(Icons.history, size: 18),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                studentAsync.when(
                  data: (s) => Text(
                    s?.hoTen ?? 'Chưa rõ tên',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  loading: () => const Text(
                    'Đang tải...',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                  ),
                  error: (_, __) => const Text(
                    'Lỗi',
                    style: TextStyle(color: AppColors.error, fontSize: 14),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Tham gia: ${DateFormatter.formatDisplayDate(membership.tuNgay)}${membership.denNgay != null ? ' - ${DateFormatter.formatDisplayDate(membership.denNgay!)}' : ''}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                if (membership.lyDoKetThuc != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Lý do: ${membership.lyDoKetThuc}',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontStyle: FontStyle.italic,
                      fontSize: 11,
                    ),
                  ),
                ],
                if (studentAsync.valueOrNull?.sdtPhuHuynh?.trim().isNotEmpty ==
                    true) ...[
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ParentContactActions(
                      phone: studentAsync.valueOrNull?.sdtPhuHuynh,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.edit_calendar_outlined, size: 20),
            tooltip: 'Sửa ngày tham gia lớp',
            onPressed: () => editMembershipJoinDate(context, ref, membership),
          ),
          if (!isActive)
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                side: const BorderSide(color: AppColors.border),
              ),
              onPressed: () => _showReEnrollDialog(context, ref),
              child: const Text(
                'Học lại',
                style: TextStyle(color: AppColors.cyanAccent, fontSize: 12),
              ),
            )
          else
            const AppStatusChip(
              label: 'Đang học',
              color: AppColors.success,
              compact: true,
            ),
        ],
      ),
    );
  }

  void _showReEnrollDialog(BuildContext context, WidgetRef ref) async {
    final success = await showReEnrollStudentBottomSheet(
      context,
      studentId: membership.idHocSinh,
      classId: membership.idLop,
      defaultDiscount: membership.mienGiamPhanTram,
    );
    if (success == true) {
      ref.invalidate(classRosterProvider);
      ref.invalidate(classSizeProvider);
      ref.invalidate(classMembershipHistoryProvider);
    }
  }
}

class RosterItem extends ConsumerWidget {
  final ClassMembership membership;
  const RosterItem({super.key, required this.membership});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentAsync = ref.watch(studentDetailProvider(membership.idHocSinh));

    return AppSectionCard(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => StudentDetailPage(studentId: membership.idHocSinh),
        ),
      ),
      child: Row(
        children: [
          studentAsync.when(
            data: (s) => StudentAvatar(
              gioiTinh: s?.gioiTinh,
              studentName: s?.hoTen,
              radius: 20,
            ),
            loading: () => const CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.surfaceHigh,
              child: Icon(Icons.person, size: 18),
            ),
            error: (_, __) => const CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.surfaceHigh,
              child: Icon(Icons.person, size: 18),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                studentAsync.when(
                  data: (s) => Text(
                    s?.hoTen ?? 'Chưa rõ tên',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  loading: () => const Text(
                    'Đang tải...',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                  ),
                  error: (_, __) => const Text(
                    'Lỗi',
                    style: TextStyle(color: AppColors.error, fontSize: 14),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Tham gia từ: ${DateFormatter.formatDisplayDate(membership.tuNgay)}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                if (studentAsync.valueOrNull?.sdtPhuHuynh?.trim().isNotEmpty ==
                    true) ...[
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ParentContactActions(
                      phone: studentAsync.valueOrNull?.sdtPhuHuynh,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_calendar_outlined, size: 20),
            tooltip: 'Sửa ngày tham gia lớp',
            onPressed: () => editMembershipJoinDate(context, ref, membership),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.error, size: 20),
            tooltip: 'Cho nghỉ lớp',
            onPressed: () => _showLeaveDialog(context, ref),
          ),
        ],
      ),
    );
  }

  void _showLeaveDialog(BuildContext context, WidgetRef ref) async {
    final student = ref.read(studentDetailProvider(membership.idHocSinh)).value;
    final success = await showLeaveClassBottomSheet(
      context,
      studentId: membership.idHocSinh,
      classId: membership.idLop,
      studentName: student?.hoTen ?? 'học sinh',
    );
    if (success == true) {
      ref.invalidate(classRosterProvider);
      ref.invalidate(classSizeProvider);
      ref.invalidate(classMembershipHistoryProvider);
    }
  }
}

final classMembershipHistoryProvider =
    FutureProvider.family<List<ClassMembership>, int>((ref, classId) async {
      final repo = await ref.watch(membershipRepositoryProvider.future);
      return repo.getByClass(classId);
    });

Future<void> editMembershipJoinDate(
  BuildContext context,
  WidgetRef ref,
  ClassMembership membership,
) async {
  final current = DateTime.parse(membership.tuNgay);
  final selected = await showDatePicker(
    context: context,
    initialDate: current,
    firstDate: DateTime(2020),
    lastDate: membership.denNgay == null
        ? DateTime(2100)
        : DateTime.parse(membership.denNgay!),
    helpText: 'Ngày tham gia lớp',
  );
  if (!context.mounted || selected == null || selected == current) return;
  try {
    final service = await ref.read(membershipServiceProvider.future);
    await service.changeJoinDate(membership: membership, joinDate: selected);
    ref.invalidate(classRosterProvider);
    ref.invalidate(classSizeProvider);
    ref.invalidate(classMembershipHistoryProvider);
    if (context.mounted) {
      AppFeedback.showSuccessSnackBar(context, 'Đã cập nhật ngày tham gia lớp');
    }
  } catch (error) {
    if (context.mounted) {
      AppFeedback.showErrorSnackBar(
        context,
        error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }
}
