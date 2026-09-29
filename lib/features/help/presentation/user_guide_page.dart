import 'package:flutter/material.dart';

import '../../../app/common_widgets/navy_components.dart';
import '../../../app/design_system/app_theme.dart';
import '../../../app/navigation/app_global_drawer.dart';
import '../../../app/navigation/ui_keys.dart';
import '../../../l10n/app_localizations.dart';

class UserGuidePage extends StatefulWidget {
  const UserGuidePage({super.key});

  @override
  State<UserGuidePage> createState() => _UserGuidePageState();
}

class _UserGuidePageState extends State<UserGuidePage> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vi = Localizations.localeOf(context).languageCode == 'vi';
    final sections = vi ? _vietnameseSections : _englishSections;
    final query = _query.trim().toLowerCase();
    final filtered = sections.where((section) {
      if (query.isEmpty) return true;
      return section.title.toLowerCase().contains(query) ||
          section.summary.toLowerCase().contains(query) ||
          section.steps.any((step) => step.toLowerCase().contains(query));
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const AppGlobalDrawer(),
      appBar: AppBar(
        leading: const GlobalMenuButton(),
        title: Text(AppLocalizations.of(context)!.navGuide),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(6, 16, 6, 32),
        children: [
          AppSectionCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.auto_stories_outlined,
                  color: AppColors.cyanAccent,
                  size: 26,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vi ? 'Bắt đầu từ đâu?' : 'Where do I start?',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        vi
                            ? 'Thiết lập lớp và chính sách học phí → thêm học sinh → xếp lịch, phân ca → điểm danh → xem tạm tính, chốt học phí → thu tiền.'
                            : 'Set up a class and tuition policy → add students → plan schedules and shifts → record attendance → review estimates and finalize tuition → collect payments.',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          height: 1.4,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            key: UiKeys.guideSearch,
            controller: _searchController,
            onChanged: (value) => setState(() => _query = value),
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: vi
                  ? 'Tìm thao tác hoặc nghiệp vụ...'
                  : 'Search tasks or topics...',
              prefixIcon: const Icon(Icons.search, color: AppColors.cyanAccent),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      tooltip: vi ? 'Xóa tìm kiếm' : 'Clear search',
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _query = '');
                      },
                    ),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 36),
              child: Center(
                child: Text(
                  vi
                      ? 'Không tìm thấy nội dung phù hợp.'
                      : 'No matching topics.',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ),
          for (final section in filtered)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AppSectionCard(
                padding: EdgeInsets.zero,
                child: ExpansionTile(
                  key: ValueKey(section.title),
                  initiallyExpanded: query.isNotEmpty,
                  tilePadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 2,
                  ),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                  leading: Icon(section.icon, color: AppColors.cyanAccent),
                  title: Text(
                    section.title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    section.summary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  children: [
                    for (var index = 0; index < section.steps.length; index++)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(
                                  alpha: 0.15,
                                ),
                                borderRadius: BorderRadius.circular(7),
                              ),
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  color: AppColors.cyanAccent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                section.steps[index],
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
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
}

class _GuideSection {
  final String title;
  final String summary;
  final IconData icon;
  final List<String> steps;

  const _GuideSection(this.title, this.summary, this.icon, this.steps);
}

const _vietnameseSections = <_GuideSection>[
  _GuideSection(
    'Thiết lập ban đầu',
    'Lớp học và chính sách học phí',
    Icons.tune_outlined,
    [
      'Vào Lớp học, tạo lớp và kiểm tra tên lớp, sĩ số tối đa.',
      'Mở chi tiết lớp → Học phí trong hàng nút truy cập nhanh để thiết lập chính sách. Nếu đã có mức học phí, ứng dụng điền mức cũ và mặc định đề xuất thay đổi từ tháng tiếp theo.',
      'Chọn tháng hiệu lực, nhập mức mới và xem màn hình xác nhận mức cũ/mới trước khi lưu. Các tháng trước tháng hiệu lực vẫn giữ mức cũ.',
      'Nếu tháng bị ảnh hưởng đã có hóa đơn chốt, hoặc thời gian hiệu lực trùng chính sách khác, ứng dụng sẽ từ chối và báo rõ trên biểu mẫu. Không sửa trực tiếp hóa đơn hay phiếu thu đã phát.',
      'Vào Cài đặt để chọn ngôn ngữ và giao diện phù hợp.',
    ],
  ),
  _GuideSection(
    'Học sinh và ghi danh',
    'Thông tin phụ huynh và lớp đang học',
    Icons.people_outline,
    [
      'Vào Học sinh, nhấn nút + để thêm hồ sơ. Nhập tên và số điện thoại phụ huynh để tiện liên hệ.',
      'Mở chi tiết lớp → Sĩ số → nút + để ghi danh học sinh. Một học sinh có thể tham gia nhiều lớp.',
      'Khi học sinh nghỉ lớp, dùng thao tác cho nghỉ lớp để giữ lại lịch sử tham gia.',
    ],
  ),
  _GuideSection(
    'Lịch học và phân ca',
    'Lịch định kỳ, ca học và buổi thực tế',
    Icons.event_note_outlined,
    [
      'Mở chi tiết lớp → Lịch học → nút + để thêm lịch định kỳ theo thứ và giờ.',
      'Nếu lớp có nhiều ca, vào Phân ca để kiểm tra số lượng và danh sách học sinh của từng ca.',
      'Vào Buổi học để xem các buổi theo ngày. Lịch định kỳ là quy tắc; buổi học là buổi thực tế dùng cho điểm danh.',
    ],
  ),
  _GuideSection(
    'Điểm danh từng buổi',
    'Ghi nhận tình trạng tham gia',
    Icons.fact_check_outlined,
    [
      'Mở chi tiết lớp → Điểm danh, chọn tháng và lọc buổi chưa hoàn tất hoặc đã hoàn tất.',
      'Chọn một buổi, kiểm tra danh sách học sinh và cập nhật trạng thái điểm danh cho từng em.',
      'Lưu nháp khi chưa xong; chỉ hoàn tất sau khi đã kiểm tra đầy đủ. Học sinh chưa được điểm danh không được xem là có mặt.',
    ],
  ),
  _GuideSection(
    'Đơn nghỉ, đổi ca và học bù',
    'Điều chỉnh đúng buổi và đúng học sinh',
    Icons.event_repeat_outlined,
    [
      'Trong chi tiết lớp, chọn Đơn nghỉ để ghi nhận hoặc xem yêu cầu nghỉ học.',
      'Khi cần đổi ca hoặc học bù, kiểm tra buổi học và học sinh liên quan trước khi xác nhận điều chỉnh.',
      'Kiểm tra lại điểm danh và học phí sau khi thay đổi buổi học; lịch sử đã chốt cần được xử lý theo luồng điều chỉnh của ứng dụng.',
    ],
  ),
  _GuideSection(
    'Tính và chốt học phí',
    'Phân biệt tạm tính với khoản nợ đã chốt',
    Icons.receipt_long_outlined,
    [
      'Mở chi tiết lớp → Học phí và chọn đúng tháng. Tạm tính là số tiền dự kiến, chưa phải hóa đơn đã chốt.',
      'Kiểm tra điểm danh, chính sách học phí và các học sinh bị chặn vì thiếu dữ liệu trước khi chọn Chốt học phí.',
      'Dự kiến còn thu gồm tiền tạm tính chưa chốt cộng với tiền chưa thanh toán của hóa đơn đã chốt. Chỉ hóa đơn đã chốt mới là căn cứ thu tiền.',
    ],
  ),
  _GuideSection(
    'Thu tiền và theo dõi',
    'Thu tiền, mã QR và lịch sử thanh toán',
    Icons.payments_outlined,
    [
      'Trong card học sinh ở tab Học phí, mở dấu ba chấm → Thu tiền để ghi nhận khoản đã nhận thực tế.',
      'Chọn Tạo mã QR khi cần gửi thông tin thanh toán; kiểm tra số tiền trước khi chia sẻ.',
      'Sau khi thu, kiểm tra tổng Đã thu, khoản còn thu và Lịch sử thu. Học sinh đóng một phần vẫn còn số dư chưa thanh toán.',
    ],
  ),
  _GuideSection(
    'Báo cáo và tra cứu',
    'Theo dõi tình hình lớp và học phí',
    Icons.bar_chart_outlined,
    [
      'Vào Trang chủ để xem lịch dạy và việc cần làm hôm nay.',
      'Vào Báo cáo để xem số liệu tổng hợp; đối chiếu với tháng và lớp đang chọn trước khi sử dụng.',
      'Dùng tìm kiếm trong danh sách Học sinh hoặc Lớp học để mở hồ sơ cần kiểm tra.',
    ],
  ),
];

const _englishSections = <_GuideSection>[
  _GuideSection(
    'Initial setup',
    'Classes and tuition policies',
    Icons.tune_outlined,
    [
      'Open Classes, create a class and check its name and maximum size.',
      'Open the class → Tuition to set the per-session tuition policy. Check the effective policy before finalizing tuition.',
      'Open Settings to choose a language and display mode.',
    ],
  ),
  _GuideSection(
    'Students and enrollment',
    'Parent contact details and class history',
    Icons.people_outline,
    [
      'Open Students and tap + to add a profile. Add a parent phone number for contact.',
      'Open a class → Roster → + to enroll a student. A student may belong to multiple classes.',
      'Use the leave-class action when a student leaves so participation history remains available.',
    ],
  ),
  _GuideSection(
    'Schedules and shifts',
    'Recurring rules and actual sessions',
    Icons.event_note_outlined,
    [
      'Open a class → Schedule → + to set a recurring weekday and time.',
      'For classes with multiple shifts, use Shift assignment to check students in each shift.',
      'Open Sessions to review dated sessions. A recurring schedule is a rule; a session is used for attendance.',
    ],
  ),
  _GuideSection(
    'Attendance',
    'Record each student for each session',
    Icons.fact_check_outlined,
    [
      'Open a class → Attendance, select a month and choose incomplete or completed sessions.',
      'Open a session, check its roster and set each student’s attendance status.',
      'Save a draft if unfinished. Finalize only after review; missing attendance does not mean present.',
    ],
  ),
  _GuideSection(
    'Leave and makeup lessons',
    'Changes to the correct student and session',
    Icons.event_repeat_outlined,
    [
      'In a class, open Leave requests to record or review absences.',
      'For a shift change or makeup lesson, check the affected student and session before confirming.',
      'Review attendance and tuition after changing a session. Use the app’s correction flow for finalized history.',
    ],
  ),
  _GuideSection(
    'Calculate and finalize tuition',
    'Estimates differ from finalized debt',
    Icons.receipt_long_outlined,
    [
      'Open a class → Tuition and select the month. An estimate is not a finalized invoice.',
      'Check attendance, tuition policy and students blocked by missing data before finalizing.',
      'Projected amount to collect includes unfinalized estimates plus remaining finalized debt. Collect against finalized invoices.',
    ],
  ),
  _GuideSection(
    'Collect payments',
    'Payments, QR codes and history',
    Icons.payments_outlined,
    [
      'On a student’s tuition card, open the three-dot menu → Collect payment to record money received.',
      'Use Generate QR if needed, and verify the amount before sharing.',
      'After collecting, check Total collected, the outstanding amount and Payment history. Partial payments leave a balance.',
    ],
  ),
  _GuideSection(
    'Reports and search',
    'Find classes, students and financial summaries',
    Icons.bar_chart_outlined,
    [
      'Open Home for today’s lessons and tasks.',
      'Open Reports to inspect summaries; check the selected month and class before using the figures.',
      'Search Students or Classes to find a specific record.',
    ],
  ),
];
