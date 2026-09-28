import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../app/common_widgets/app_feedback.dart';
import '../../../app/common_widgets/navy_components.dart';
import '../../../app/common_widgets/student_avatar.dart';
import '../../../app/design_system/app_theme.dart';
import '../../../app/navigation/app_global_drawer.dart';
import '../../../app/navigation/ui_keys.dart';
import '../../../core/utils/date_formatter.dart';
import '../../attendance/domain/class_attendance_timeline_item.dart';
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
  DateTime _referenceDate = DateTime.now();
  DateTime _timelineMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    1,
  );
  String _attendanceFilter = 'ALL';

  @override
  Widget build(BuildContext context) {
    final classAsync = ref.watch(classDetailProvider(widget.classId));
    final rosterAsync = ref.watch(
      classRosterProvider((widget.classId, _referenceDate)),
    );
    final historyAsync = ref.watch(
      classMembershipHistoryProvider(widget.classId),
    );
    final currentMonth = DateFormatter.currentMonthString();
    final policyAsync = ref.watch(
      effectiveTuitionPolicyProvider((widget.classId, currentMonth)),
    );
    final sizeAsync = ref.watch(classSizeProvider(widget.classId));

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const AppGlobalDrawer(),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: const BackButton(),
        title: const Text('Chi tiết lớp học'),
        actions: [
          const GlobalMenuButton(),
          classAsync.when(
            data: (cls) => cls == null
                ? const SizedBox.shrink()
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: 'Sửa lớp',
                        onPressed: () async {
                          await showClassFormBottomSheet(context, cls: cls);
                          ref.invalidate(classDetailProvider(widget.classId));
                          ref
                              .read(classListControllerProvider.notifier)
                              .refresh();
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.request_quote_outlined),
                        tooltip: 'Mức học phí',
                        onPressed: () => showCreateTuitionPolicyBottomSheet(
                          context,
                          classId: widget.classId,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.event_note_outlined),
                        tooltip: 'Đơn nghỉ học',
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                LeaveRequestPage(classId: widget.classId),
                          ),
                        ),
                      ),
                      IconButton(
                        key: cls.daLuuTru
                            ? UiKeys.classRestoreAction
                            : UiKeys.classArchiveAction,
                        icon: Icon(
                          cls.daLuuTru
                              ? Icons.restore_rounded
                              : Icons.folder_off_outlined,
                          color: cls.daLuuTru
                              ? AppColors.success
                              : AppColors.error,
                        ),
                        tooltip: cls.daLuuTru
                            ? 'Kích hoạt lại lớp'
                            : 'Ngừng hoạt động lớp',
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
              _buildHeader(context, cls, sizeAsync, policyAsync),
              Expanded(
                child: DefaultTabController(
                  length: 7,
                  child: Column(
                    children: [
                      Container(
                        color: AppColors.surface,
                        child: const TabBar(
                          isScrollable: true,
                          indicatorColor: AppColors.cyanAccent,
                          labelColor: AppColors.cyanAccent,
                          unselectedLabelColor: AppColors.textSecondary,
                          labelStyle: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                          unselectedLabelStyle: TextStyle(fontSize: 13),
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
    AsyncValue<dynamic> policyAsync,
  ) {
    return AppSectionCard(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: cls.daLuuTru
                      ? const Color(0x26FF5964)
                      : const Color(0x260A84FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    cls.tenLop[0].toUpperCase(),
                    style: TextStyle(
                      color: cls.daLuuTru
                          ? AppColors.error
                          : AppColors.cyanAccent,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            cls.tenLop,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        AppActiveStatusBadge(isActive: !cls.daLuuTru),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${cls.monHoc ?? 'Môn chưa xác định'} • Khối ${cls.khoi ?? '?'}',
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
          const SizedBox(height: 10),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.groups_outlined,
                    size: 16,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(width: 6),
                  sizeAsync.when(
                    data: (size) => Text(
                      'Sĩ số hiện tại: $size / ${cls.siSoToiDa ?? '∞'}',
                      style: TextStyle(
                        color: (cls.siSoToiDa != null && size >= cls.siSoToiDa!)
                            ? AppColors.error
                            : AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    loading: () => const Text(
                      '...',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                    error: (_, __) => const Text(
                      '?',
                      style: TextStyle(color: AppColors.error, fontSize: 13),
                    ),
                  ),
                ],
              ),
              policyAsync.when(
                data: (policy) {
                  if (policy == null) {
                    return TextButton(
                      style: TextButton.styleFrom(padding: EdgeInsets.zero),
                      onPressed: () => showCreateTuitionPolicyBottomSheet(
                        context,
                        classId: widget.classId,
                      ),
                      child: const Text(
                        'Thiết lập học phí',
                        style: TextStyle(
                          color: AppColors.warning,
                          fontSize: 12,
                        ),
                      ),
                    );
                  }
                  return Text(
                    '${NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0).format(policy.hocPhiMoiBuoi)}/buổi',
                    style: const TextStyle(
                      color: AppColors.cyanAccent,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
        if (!isArchived)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Danh sách học sinh đang học',
                    style: TextStyle(
                      color: AppColors.cyanAccent,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                  ),
                  onPressed: () => _showAddStudentDialog(context),
                  icon: const Icon(Icons.person_add_outlined, size: 16),
                  label: const Text('Thêm học sinh'),
                ),
              ],
            ),
          ),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
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
        'THÁNG ${DateFormat('MM/yyyy').format(_timelineMonth)}';

    final timelineAsync = ref.watch(
      classAttendanceTimelineProvider(
        classId: widget.classId,
        yearMonth: yearMonth,
      ),
    );

    return Column(
      children: [
        // Month Navigator Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          color: AppColors.surface,
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
              Text(
                monthDisplay,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
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

        // Filter chips bar
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          color: AppColors.background,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildFilterChip('Tất cả', 'ALL'),
              _buildFilterChip('Chưa hoàn tất', 'DU_KIEN'),
              _buildFilterChip('Đã hoàn tất', 'DA_HOC'),
              _buildFilterChip('Khác', 'KHAC'),
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
                } else if (_attendanceFilter == 'KHAC') {
                  return item.session.trangThai == SessionStatus.HUY ||
                      item.session.trangThai == SessionStatus.NGHI_LE;
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

  Widget _buildFilterChip(String label, String code) {
    final isSelected = _attendanceFilter == code;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: AppColors.primary,
        backgroundColor: AppColors.surface,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppColors.textSecondary,
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        onSelected: (selected) {
          if (selected) {
            setState(() => _attendanceFilter = code);
          }
        },
      ),
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
        minimumSize: const Size(0, 32),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 0),
        visualDensity: const VisualDensity(horizontal: -2, vertical: -3),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 0,
      );
    }

    return OutlinedButton.styleFrom(
      foregroundColor: foregroundColor,
      minimumSize: const Size(0, 32),
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
              ],
            ),
          ),
          const SizedBox(width: 8),
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
              ],
            ),
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
