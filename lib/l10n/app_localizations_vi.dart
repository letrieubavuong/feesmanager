// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get appName => 'Quản lý học phí';

  @override
  String get navHome => 'Trang chủ';

  @override
  String get navClasses => 'Lớp học';

  @override
  String get navStudents => 'Học sinh';

  @override
  String get navTuition => 'Học phí';

  @override
  String get navReports => 'Báo cáo';

  @override
  String get navSettings => 'Cài đặt';

  @override
  String get navGuide => 'Hướng dẫn sử dụng';

  @override
  String get globalMenu => 'Menu điều hướng';

  @override
  String get menuTitle => 'Danh mục chức năng';

  @override
  String get menuSubtitle => 'Quản lý trung tâm dạy thêm';

  @override
  String get palettePhysicsBlue => 'Xanh Vật lý';

  @override
  String get paletteEmerald => 'Xanh Ngọc Emerald';

  @override
  String get paletteIndigo => 'Xanh Chàm Indigo';

  @override
  String get paletteAmber => 'Vàng Hổ Phách';

  @override
  String get paletteSlate => 'Xám Đá Slate';

  @override
  String get paletteOceanCyan => 'Xanh Lam Cyan';

  @override
  String get paletteBurgundy => 'Đỏ Rượu Burgundy';

  @override
  String get paletteHighContrast => 'Tương Phản Cao';

  @override
  String get dashboardTitle => 'Trang chủ';

  @override
  String get dashboardGreeting => 'Xin chào!';

  @override
  String get dashboardGreetingSubtitle => 'Chúc một ngày dạy học hiệu quả!';

  @override
  String get dashboardTodaySessions => 'Buổi hôm nay';

  @override
  String get dashboardPendingAttendance => 'Cần điểm danh';

  @override
  String get dashboardUnfinalizedTuition => 'Chưa chốt học phí';

  @override
  String get dashboardOutstandingDebt => 'Nợ cần xử lý';

  @override
  String get dashboardTasks => 'Việc cần làm hôm nay';

  @override
  String get dashboardAttendanceNow => 'Điểm danh ngay';

  @override
  String get dashboardGenerateSessions => 'Sinh buổi học';

  @override
  String get dashboardFinalizeTuition => 'Chốt học phí tháng';

  @override
  String get dashboardExportReport => 'Xuất báo cáo PDF';

  @override
  String get dashboardExportReportSubtitle => 'Báo cáo học phí & điểm danh';

  @override
  String get dashboardGenerateSessionsSubtitle =>
      'Tạo buổi từ lịch học định kỳ';

  @override
  String get dashboardNoPendingSessions => 'Không có buổi cần điểm danh';

  @override
  String get dashboardTodaySchedule => 'Lịch dạy hôm nay';

  @override
  String get dashboardDone => 'Đã xong';

  @override
  String get dashboardNeedsAttendance => 'Cần điểm danh';

  @override
  String get dashboardUpcoming => 'Sắp diễn ra';

  @override
  String get dashboardInProgress => 'Đang diễn ra';

  @override
  String get dashboardCanceled => 'Đã hủy';

  @override
  String get dashboardHoliday => 'Nghỉ lễ';

  @override
  String get dashboardWarnings => 'Cảnh báo nghiệp vụ';

  @override
  String get dashboardRecentActivity => 'Cập nhật gần đây';

  @override
  String get dashboardNoTasks => 'Không có công việc cần làm.';

  @override
  String get dashboardNoWarnings => 'Không có cảnh báo nghiệp vụ nào.';

  @override
  String get dashboardNoSessions => 'Hôm nay không có buổi dạy nào.';

  @override
  String get dashboardNoActivity => 'Chưa có hoạt động gần đây.';

  @override
  String get actionAddStudent => 'Thêm học sinh';

  @override
  String get actionAddClass => 'Thêm lớp học';

  @override
  String get actionManageClasses => 'Quản lý lớp học';

  @override
  String get actionViewTuition => 'Xem học phí';

  @override
  String get actionViewReports => 'Xem báo cáo';

  @override
  String get searchResults => 'Kết quả tìm kiếm';

  @override
  String get searchNoResults => 'Không tìm thấy học sinh hoặc lớp học nào.';

  @override
  String get settingsTitle => 'Cài đặt';

  @override
  String get settingsAppearance => 'GIAO DIỆN & CHỦ ĐỀ';

  @override
  String get settingsThemeMode => 'Chế độ hiển thị';

  @override
  String get themeSystem => 'Theo hệ thống';

  @override
  String get themeLight => 'Sáng';

  @override
  String get themeDark => 'Tối';

  @override
  String get settingsPalette => 'Tông màu ứng dụng';

  @override
  String get settingsLanguage => 'NGÔN NGỮ';

  @override
  String get langSystem => 'Theo hệ thống';

  @override
  String get langVietnamese => 'Tiếng Việt';

  @override
  String get langEnglish => 'English';

  @override
  String get settingsAppInfo => 'THÔNG TIN ỨNG DỤNG';

  @override
  String get appVersion => '2.6';

  @override
  String get dbVersion => 'Cơ sở dữ liệu: v15';

  @override
  String get studentFormTitleAdd => 'Thêm học sinh';

  @override
  String get studentFormTitleEdit => 'Sửa thông tin học sinh';

  @override
  String get studentFullName => 'Họ và tên *';

  @override
  String get studentGrade => 'Khối';

  @override
  String studentGradeItem(Object grade) {
    return 'Khối $grade';
  }

  @override
  String get studentGender => 'Giới tính';

  @override
  String get studentGenderMale => 'Nam';

  @override
  String get studentGenderFemale => 'Nữ';

  @override
  String get studentGenderOther => 'Khác';

  @override
  String get studentSchool => 'Trường đang học';

  @override
  String get studentParentSection => 'Thông tin phụ huynh';

  @override
  String get studentParentName => 'Tên phụ huynh';

  @override
  String get studentParentPhone => 'SĐT phụ huynh';

  @override
  String studentCardParentPhone(Object phone) {
    return 'PH • $phone';
  }

  @override
  String get studentOtherContactSection => 'Liên hệ khác';

  @override
  String get studentPhone => 'SĐT học sinh';

  @override
  String get studentEmail => 'Email';

  @override
  String get studentAddress => 'Địa chỉ';

  @override
  String get studentFacebook => 'Facebook';

  @override
  String get studentNotes => 'Ghi chú';

  @override
  String get studentValidationName => 'Vui lòng nhập họ tên';

  @override
  String get classFormTitleAdd => 'Thêm lớp học';

  @override
  String get classFormTitleEdit => 'Sửa lớp học';

  @override
  String get className => 'Tên lớp học *';

  @override
  String get classSubject => 'Môn học';

  @override
  String get classMaxStudents => 'Sĩ số tối đa';

  @override
  String get classNotes => 'Ghi chú';

  @override
  String get classValidationName => 'Vui lòng nhập tên lớp';

  @override
  String get filterActive => 'Đang hoạt động';

  @override
  String get filterArchived => 'Ngừng hoạt động';

  @override
  String get filterAll => 'Tất cả';

  @override
  String get studentFilterActive => 'Đang học';

  @override
  String get studentFilterStopped => 'Ngừng học';

  @override
  String get studentEmptyActive => 'Không có học sinh đang học phù hợp.';

  @override
  String get studentEmptyStopped => 'Không có học sinh ngừng học phù hợp.';

  @override
  String get classFilterActive => 'Đang hoạt động';

  @override
  String get classFilterStopped => 'Ngừng hoạt động';

  @override
  String get classEmptyActive => 'Không có lớp đang hoạt động phù hợp.';

  @override
  String get classEmptyStopped => 'Không có lớp ngừng hoạt động phù hợp.';

  @override
  String get membershipTitle => 'Học sinh trong lớp';

  @override
  String get membershipActive => 'Đang tham gia';

  @override
  String get membershipHistory => 'Lịch sử tham gia';

  @override
  String get actionEnrollStudent => 'Thêm học sinh vào lớp';

  @override
  String get actionEndMembership => 'Kết thúc tham gia';

  @override
  String get membershipStartDate => 'Ngày bắt đầu (YYYY-MM-DD)';

  @override
  String get membershipEndDate => 'Ngày kết thúc (YYYY-MM-DD)';

  @override
  String get membershipEndTitle => 'Kết thúc tham gia lớp?';

  @override
  String get membershipEndPrompt =>
      'Xác nhận kết thúc tham gia lớp học của học sinh này từ ngày chọn?';

  @override
  String get selectStudent => 'Chọn học sinh *';

  @override
  String get selectClass => 'Chọn lớp học *';

  @override
  String get studentSearchPlaceholder => 'Tìm tên học sinh...';

  @override
  String get classSearchPlaceholder => 'Tìm tên lớp...';

  @override
  String get noStudentsFound => 'Không tìm thấy học sinh nào.';

  @override
  String get noClassesFound => 'Không tìm thấy lớp học nào.';

  @override
  String get policyTitle => 'Chính sách học phí';

  @override
  String get policyEffective => 'Chính sách hiện tại';

  @override
  String get policyHistory => 'Lịch sử chính sách';

  @override
  String get actionCreatePolicy => 'Tạo chính sách mới';

  @override
  String get policyStandardSessions => 'Số buổi chuẩn N/tháng *';

  @override
  String get policyFeePerSession => 'Học phí/buổi (VNĐ) *';

  @override
  String get policyStartMonth => 'Tháng bắt đầu (YYYY-MM) *';

  @override
  String get policyEndMonth => 'Tháng kết thúc (YYYY-MM)';

  @override
  String get policyStatusActive => 'Đang áp dụng';

  @override
  String get policyStatusExpired => 'Đã hết hạn';

  @override
  String get policyStatusFuture => 'Sắp áp dụng';

  @override
  String get policyValidationSessions => 'Nhập số buổi hợp lệ (> 0)';

  @override
  String get policyValidationFee => 'Nhập học phí hợp lệ (>= 0)';

  @override
  String get policyValidationMonth => 'Nhập tháng đúng định dạng YYYY-MM';

  @override
  String get actionArchive => 'Lưu trữ';

  @override
  String get actionRestore => 'Khôi phục';

  @override
  String get actionEdit => 'Chỉnh sửa';

  @override
  String get actionDetail => 'Chi tiết';

  @override
  String get actionConfirmArchive => 'Lưu trữ mục này?';

  @override
  String get actionConfirmRestore => 'Khôi phục mục này?';

  @override
  String get commonLoading => 'Đang tải dữ liệu...';

  @override
  String get commonEmpty => 'Chưa có dữ liệu.';

  @override
  String get commonError => 'Đã xảy ra lỗi';

  @override
  String get commonRetry => 'Thử lại';

  @override
  String get commonConfirm => 'Xác nhận';

  @override
  String get commonCancel => 'Hủy';

  @override
  String get commonSave => 'Lưu';

  @override
  String get dirtyFormTitle => 'Rời khỏi trang?';

  @override
  String get dirtyFormMessage =>
      'Bạn có thay đổi chưa lưu. Bạn có chắc muốn rời đi và bỏ các thay đổi này không?';

  @override
  String get dirtyFormDiscard => 'Bỏ thay đổi';

  @override
  String get dirtyFormKeepEditing => 'Tiếp tục chỉnh sửa';

  @override
  String get settingsPaymentQr => 'THANH TOÁN & QR';

  @override
  String get settingsBankAccount => 'Tài khoản nhận học phí';

  @override
  String get settingsBankAccountSubtitle =>
      'Cấu hình thông tin ngân hàng và mã VietQR nhận học phí';

  @override
  String get bankAccountTitle => 'THÔNG TIN TÀI KHOẢN NGÂN HÀNG';

  @override
  String get bankName => 'Ngân hàng';

  @override
  String get bankAccountNumber => 'Số tài khoản';

  @override
  String get bankAccountHolder => 'Tên chủ tài khoản';

  @override
  String get bankTransferTemplate => 'Mẫu nội dung chuyển khoản';

  @override
  String bankTransferTemplateHelper(Object maHocSinh, Object thang) {
    return 'Dùng $maHocSinh cho mã/ID học sinh, $thang cho tháng';
  }

  @override
  String get bankAccountSaveSuccess =>
      'Đã lưu thông tin tài khoản nhận học phí';

  @override
  String get bankAccountValidationNumber => 'Vui lòng nhập số tài khoản';

  @override
  String get bankAccountValidationHolder => 'Vui lòng nhập tên chủ tài khoản';

  @override
  String get bankAccountValidationTemplate =>
      'Vui lòng nhập mẫu nội dung chuyển khoản';

  @override
  String get vietQrPreviewTitle => 'XEM TRƯỚC VIETQR';

  @override
  String get vietQrPreviewSample =>
      'Nội dung mẫu (Ví dụ 500.000đ, HS001, 09/2026):';

  @override
  String get vietQrNotConfigured =>
      'Nhập số tài khoản và tên chủ tài khoản để tạo mã VietQR xem trước.';

  @override
  String get reportsTitle => 'Báo cáo';

  @override
  String get reportsFilterTitle => 'BỘ LỌC BÁO CÁO';

  @override
  String get reportsMode => 'Chế độ xem';

  @override
  String get reportsModeMonth => 'Theo tháng';

  @override
  String get reportsModeCustomRange => 'Khoảng ngày';

  @override
  String get reportsSelectMonth => 'Chọn tháng báo cáo';

  @override
  String get reportsFromDate => 'Từ';

  @override
  String get reportsToDate => 'Đến';

  @override
  String get reportsFilterClass => 'Lớp học';

  @override
  String get reportsFilterStudent => 'Học sinh';

  @override
  String get reportsAllClasses => 'Tất cả các lớp';

  @override
  String get reportsAllStudents => 'Tất cả học sinh';

  @override
  String get reportsApplyFilter => 'Áp dụng';

  @override
  String get reportsClearFilter => 'Xóa bộ lọc';

  @override
  String get reportsFilteredClass => 'Đã lọc lớp';

  @override
  String get reportsFilteredStudent => 'Đã lọc học sinh';

  @override
  String get reportsExportPdf => 'Xuất báo cáo PDF';

  @override
  String reportsExportPdfError(Object error) {
    return 'Lỗi xuất PDF: $error';
  }

  @override
  String get reportsKpiAttendanceRate => 'Tỷ lệ đi học';

  @override
  String get reportsKpiInvoiced => 'Học phí đã chốt';

  @override
  String get reportsKpiPaid => 'Thực nhận';

  @override
  String get reportsKpiOutstanding => 'Chưa thanh toán';

  @override
  String get reportsSectionAttendance => 'A. ĐIỂM DANH';

  @override
  String get reportsSectionFinancial => 'B. HỌC PHÍ';

  @override
  String get reportsSectionSessions => 'C. BUỔI HỌC';

  @override
  String get reportsSectionClassBreakdown => 'D. CHI TIẾT THEO LỚP HỌC';

  @override
  String get reportsSectionStudentBreakdown => 'CHI TIẾT THEO HỌC SINH';

  @override
  String get reportsAttendanceOverallRate => 'Tỷ lệ đi học tổng thể';

  @override
  String get reportsAttendancePresent => 'Có mặt';

  @override
  String get reportsAttendanceLate => 'Đi trễ';

  @override
  String get reportsAttendanceExcused => 'Có phép';

  @override
  String get reportsAttendanceUnexcused => 'Vắng x.phép';

  @override
  String get reportsFinancialInvoiced => 'Chốt hóa đơn';

  @override
  String get reportsFinancialPaid => 'Đã thu';

  @override
  String get reportsFinancialDebt => 'Dư nợ';

  @override
  String get reportsTotalSessions => 'Tổng số buổi';

  @override
  String get reportsTotalParticipations => 'Tổng lượt học';

  @override
  String get reportsNoData =>
      'Chưa có dữ liệu báo cáo trong khoảng thời gian đã chọn.';

  @override
  String get enrollStudentTitle => 'THÊM HỌC SINH VÀO LỚP';

  @override
  String get enrollOptionExisting => 'Chọn HS có sẵn';

  @override
  String get enrollOptionNew => 'Thêm HS mới';

  @override
  String get enrollJoinDate => 'Ngày tham gia';

  @override
  String get enrollDiscount => 'Mức giảm giá (%)';

  @override
  String get enrollPartialSuccess =>
      'Học sinh đã được tạo nhưng ghi danh chưa hoàn tất.';

  @override
  String get busyTimeTitle => 'THÊM GIỜ BẬN CỦA HỌC SINH';

  @override
  String get busyTimeType => 'Loại giờ bận';

  @override
  String get busyTimeFrequency => 'Tần suất';

  @override
  String get busyTimeWeekly => 'Hằng tuần';

  @override
  String get busyTimeOneTime => 'Một lần';

  @override
  String get busyTimeDayOfWeek => 'Thứ trong tuần';

  @override
  String get busyTimeDate => 'Ngày bận';

  @override
  String get busyTimeStartTime => 'Từ giờ';

  @override
  String get busyTimeEndTime => 'Đến giờ';

  @override
  String get busyTimeEffectiveFrom => 'Hiệu lực từ ngày';

  @override
  String get busyTimeEffectiveTo => 'Hiệu lực đến ngày';

  @override
  String get busyTimeDeleteConfirm => 'Bạn có chắc muốn xóa giờ bận này?';

  @override
  String get settingsTuitionPolicySection => 'CHÍNH SÁCH HỌC PHÍ';

  @override
  String get settingsTuitionPolicyTitle => 'Chính sách học phí các lớp';

  @override
  String get settingsTuitionPolicySubtitle =>
      'Thiết lập đơn giá và số buổi chuẩn tháng cho từng lớp';

  @override
  String get creditsTitle => 'Buổi dư & Credit';

  @override
  String get creditsHeaderStudent => 'Học sinh';

  @override
  String get creditsHeaderClass => 'Lớp học';

  @override
  String get creditsClosingBalance => 'Số dư cuối tháng';

  @override
  String get creditsSummaryTitle => 'Thống kê buổi học theo chuẩn';

  @override
  String get creditsMaxStandard => 'Tối đa chuẩn';

  @override
  String get creditsEligible => 'Đủ điều kiện';

  @override
  String get creditsStandard => 'Buổi chuẩn';

  @override
  String get creditsExtra => 'Buổi dư';

  @override
  String get creditsPotential => 'Đủ ĐK ghi sổ';

  @override
  String get creditsRecorded => 'Đã ghi sổ';

  @override
  String get creditsMonthDelta => 'Thay đổi trong kỳ';

  @override
  String get creditsReconcile => 'Đối soát buổi dư';

  @override
  String get creditsManualAdjustment => 'Điều chỉnh thủ công';

  @override
  String get creditsCandidatesTitle => 'Danh sách buổi học đủ điều kiện';

  @override
  String get creditsCandidatesEmpty =>
      'Không có buổi học chính thức đã hoàn tất nào trong tháng này.';

  @override
  String get creditsLedgerTitle => 'Lịch sử sổ dư credit (Ledger)';

  @override
  String get creditsLedgerEmpty => 'Chưa có lịch sử biến động credit nào.';

  @override
  String get creditsStandardTag => 'Chuẩn';

  @override
  String get creditsExtraTag => 'Vượt chuẩn';

  @override
  String get creditsEarnedTag => 'Đã ghi +1';

  @override
  String get creditsCanEarnTag => 'Có thể ghi +1';

  @override
  String get assignmentTitle => 'Phân ca học sinh';

  @override
  String get assignmentBulkBtn => 'Phân ca nhiều HS';

  @override
  String get assignmentAddStudent => 'Thêm học sinh';

  @override
  String assignmentStudentCount(Object count) {
    return '$count học sinh';
  }

  @override
  String get assignmentNoStudentsInShift => 'Chưa có học sinh trong ca này';

  @override
  String get assignmentNoSchedules =>
      'Chưa có lịch học định kỳ nào để phân ca.';

  @override
  String get assignmentStatusActive => 'Đang học';

  @override
  String get assignmentStatusClosed => 'Kết thúc';

  @override
  String get assignmentEditStartDate => 'Sửa ngày bắt đầu';

  @override
  String get assignmentChangeShift => 'Chuyển ca';

  @override
  String get assignmentCloseShift => 'Kết thúc phân ca';

  @override
  String get assignmentCloseConfirmTitle => 'CHỌN NGÀY KẾT THÚC PHÂN CA';

  @override
  String get assignmentCloseSuccess => 'Đã kết thúc phân ca học sinh';

  @override
  String get bulkAssignmentSheetTitle => 'Phân ca hàng loạt học sinh';

  @override
  String get bulkAssignmentSelectShift => 'Chọn ca học *';

  @override
  String get bulkAssignmentStartDate => 'Ngày bắt đầu phân ca';

  @override
  String get bulkAssignmentCandidateHeader => 'Danh sách học sinh đủ điều kiện';

  @override
  String get bulkAssignmentSearchPlaceholder => 'Tìm tên học sinh...';

  @override
  String get bulkAssignmentAllAssigned =>
      'Tất cả học sinh đủ điều kiện đã được phân vào ca này.';

  @override
  String bulkAssignmentSelectAll(Object count) {
    return 'Chọn tất cả ($count)';
  }

  @override
  String bulkAssignmentSubmit(Object count) {
    return 'Phân ca $count học sinh';
  }

  @override
  String get bulkAssignmentProcessing => 'Đang xử lý...';

  @override
  String bulkAssignmentSuccess(Object count) {
    return 'Đã phân ca thành công $count học sinh';
  }

  @override
  String get bulkAssignmentPreviewTitle => 'KẾT QUẢ KIỂM TRA PHÂN CA';

  @override
  String bulkAssignmentPreviewReady(Object count) {
    return 'Hợp lệ sẵn sàng phân ca: $count học sinh';
  }

  @override
  String bulkAssignmentPreviewBlocked(Object count) {
    return 'Không thể phân ca: $count học sinh';
  }

  @override
  String bulkAssignmentPreviewWarnings(Object count) {
    return 'Cảnh báo không ưu tiên: $count học sinh';
  }

  @override
  String bulkAssignmentPreviewConfirmBtn(Object count) {
    return 'Phân ca $count HS hợp lệ';
  }

  @override
  String get editStartDateTitle => 'Sửa ngày bắt đầu phân ca';

  @override
  String get editStartDateNew => 'Ngày bắt đầu phân ca mới';

  @override
  String get editStartDateSuccess => 'Cập nhật ngày bắt đầu phân ca thành công';

  @override
  String get changeShiftTitle => 'Chuyển ca học định kỳ';

  @override
  String get changeShiftSelectNew => 'Chọn ca học mới';

  @override
  String get changeShiftEffectiveDate => 'Ngày áp dụng ca mới';

  @override
  String get changeShiftSuccess => 'Chuyển ca học sinh thành công';

  @override
  String get changeShiftValidationSelect => 'Vui lòng chọn ca học mới';

  @override
  String get weekdayMonday => 'Thứ 2';

  @override
  String get weekdayTuesday => 'Thứ 3';

  @override
  String get weekdayWednesday => 'Thứ 4';

  @override
  String get weekdayThursday => 'Thứ 5';

  @override
  String get weekdayFriday => 'Thứ 6';

  @override
  String get weekdaySaturday => 'Thứ 7';

  @override
  String get weekdaySunday => 'Chủ Nhật';

  @override
  String get attendanceTitle => 'Điểm danh buổi học';

  @override
  String get attendanceShortTitle => 'Điểm danh';

  @override
  String get attendanceCompleted => 'Đã hoàn tất';

  @override
  String get attendanceEditingCompleted => 'Đang sửa điểm danh đã hoàn tất';

  @override
  String get attendanceStudents => 'HỌC SINH';

  @override
  String get attendanceLegend => 'Chú thích điểm danh';

  @override
  String get attendanceEdit => 'Sửa điểm danh';

  @override
  String get attendanceSaveCorrection => 'Lưu chỉnh sửa';

  @override
  String get attendanceCancelCorrection => 'Hủy chỉnh sửa';

  @override
  String get attendanceApprovedLeave => 'Đơn nghỉ đã duyệt';

  @override
  String get attendanceApplySuggestion => 'Áp dụng';

  @override
  String get attendanceMakeup => 'Học bù';

  @override
  String get attendanceFinalizeShort => 'Hoàn tất';

  @override
  String get attendanceMarkAllPresent => 'Có mặt hết';

  @override
  String get attendanceMarkAllMakeup => 'Học bù hết';

  @override
  String get attendanceUndo => 'Hoàn tác';

  @override
  String get attendanceDraftSave => 'Lưu nháp';

  @override
  String get attendanceFinalizeSession => 'Hoàn tất buổi học';

  @override
  String get attendanceChangeShift => 'Đổi ca';

  @override
  String get attendanceScheduleMakeup => 'Xếp học bù';

  @override
  String get attendanceCancelAdjustment => 'Hủy điều chỉnh';

  @override
  String get attendanceAddStudent => 'Thêm học sinh';

  @override
  String get attendancePresent => 'Có mặt';

  @override
  String get attendanceLate => 'Trễ';

  @override
  String get attendanceExcused => 'Có phép';

  @override
  String get attendanceUnexcused => 'Không phép';

  @override
  String get attendanceNotMarked => 'Chưa điểm danh';

  @override
  String get tuitionKpiPreview => 'Tạm tính';

  @override
  String get tuitionKpiFinalized => 'Đã chốt';

  @override
  String get tuitionKpiPaid => 'Đã thu';

  @override
  String get tuitionKpiDebt => 'Chưa thanh toán';

  @override
  String get tuitionFinalizeMonth => 'Chốt học phí tháng';

  @override
  String get tuitionRecalculate => 'Tính lại học phí';

  @override
  String get tuitionPaymentHistory => 'Lịch sử thu';

  @override
  String get tuitionPaymentAction => 'Thanh toán';

  @override
  String get tuitionQrAction => 'QR';

  @override
  String get tuitionPendingAttendance => 'Chưa đủ dữ liệu tính học phí';

  @override
  String get tuitionWaitingCompletion => 'Đang chờ hoàn tất buổi học';

  @override
  String get tuitionFinalizeFirstNotice => 'Chốt học phí trước khi thu tiền.';

  @override
  String get tuitionMonthlyCap => 'Trần học phí tháng';

  @override
  String get tuitionEffectiveFrom => 'Hiệu lực từ ngày';

  @override
  String get paymentHistoryTitle => 'Lịch sử thu tiền';

  @override
  String get paymentEditTitle => 'Sửa khoản thu';

  @override
  String get paymentRecordTitle => 'Ghi nhận thanh toán';

  @override
  String get paymentEditReason => 'Lý do sửa';

  @override
  String get paymentEditReasonValidation => 'Vui lòng nhập lý do sửa khoản thu';

  @override
  String get paymentEditSuccess => 'Đã cập nhật khoản thu thành công';

  @override
  String get studentDetailTitle => 'Chi tiết học sinh';

  @override
  String get studentStatusActive => 'Đang học';

  @override
  String get studentStatusStopped => 'Ngừng học';

  @override
  String studentJoinedFrom(Object date) {
    return 'Tham gia từ: $date';
  }

  @override
  String studentActiveClassesCount(Object count) {
    return '$count lớp đang tham gia';
  }

  @override
  String studentOutstandingDebt(Object amount) {
    return 'Chưa thanh toán: $amount';
  }

  @override
  String get studentEditProfile => 'Sửa hồ sơ';

  @override
  String get studentAddToClass => 'Thêm vào lớp';

  @override
  String get studentBusyTime => 'Giờ bận';

  @override
  String get studentRecordPayment => 'Ghi nhận thu';

  @override
  String get studentActiveClasses => 'Lớp đang tham gia';

  @override
  String studentTuitionMonth(Object month) {
    return 'Học phí tháng $month';
  }

  @override
  String get studentFinalizedDue => 'Đã chốt';

  @override
  String get studentPaid => 'Đã thu';

  @override
  String get studentDebt => 'Chưa thanh toán';

  @override
  String get studentTuitionPartiallyPaid => 'Đã thanh toán một phần';

  @override
  String get studentTuitionPaid => 'Đã thanh toán';

  @override
  String get studentTuitionUnpaid => 'Chưa thanh toán';

  @override
  String get studentTuitionPendingFinalization => 'Còn lớp chưa chốt';

  @override
  String get studentLatestPayment => 'Khoản thu gần nhất';

  @override
  String get studentNoPayment => 'Chưa có khoản thu trong tháng này';

  @override
  String get studentRecentAttendance => 'Điểm danh gần đây';

  @override
  String get studentSeeAll => 'Xem tất cả';

  @override
  String get studentBusyTimes => 'Giờ bận';

  @override
  String get studentNoActiveClasses => 'Chưa tham gia lớp nào';

  @override
  String get studentNoDebtToRecord =>
      'Không có khoản học phí đã chốt cần thanh toán.';

  @override
  String get studentSelectTuitionInvoice => 'Chọn khoản học phí cần thanh toán';

  @override
  String get classKpiActive => 'Lớp hoạt động';

  @override
  String get classKpiTodaySessions => 'Buổi hôm nay';

  @override
  String get classKpiPendingAttendance => 'Cần điểm danh';

  @override
  String get classKpiMissingTuition => 'Chưa có học phí';

  @override
  String get classListTitle => 'Danh sách lớp';

  @override
  String classCountActive(Object count) {
    return '$count lớp đang hoạt động';
  }

  @override
  String classCountStopped(Object count) {
    return '$count lớp ngừng hoạt động';
  }

  @override
  String get classStatusNeedsAttendance => 'Cần điểm danh';

  @override
  String get classStatusInProgress => 'Đang diễn ra';

  @override
  String get classStatusUpcoming => 'Sắp diễn ra';

  @override
  String get classStatusCompleted => 'Đã hoàn tất';

  @override
  String get classStatusMissingTuition => 'Chưa có học phí';

  @override
  String get classStatusDebt => 'Chưa thanh toán';

  @override
  String get classNeedsAction => 'Cần xử lý';

  @override
  String get classSeeAll => 'Xem tất cả';

  @override
  String classWarningMissingTuition(Object count) {
    return '$count lớp chưa thiết lập học phí';
  }

  @override
  String classWarningOverdueAttendance(Object count) {
    return '$count buổi quá giờ cần điểm danh';
  }

  @override
  String classWarningMissingSessions(Object count) {
    return '$count lớp chưa sinh buổi tuần này';
  }

  @override
  String classStudentCount(Object count) {
    return '$count học sinh';
  }

  @override
  String classMultipleShifts(Object count) {
    return '$count ca đang áp dụng';
  }

  @override
  String get classEmptyActiveTitle => 'Chưa có lớp đang hoạt động.';

  @override
  String get classEmptyStoppedTitle => 'Chưa có lớp ngừng hoạt động.';

  @override
  String get tuitionTitle => 'Quản lý Học phí';

  @override
  String tuitionFilterUnpaid(Object count) {
    return 'Chưa nộp ($count)';
  }

  @override
  String tuitionFilterPaid(Object count) {
    return 'Đã nộp ($count)';
  }

  @override
  String tuitionUnpaidCount(Object count) {
    return 'Chưa nộp ($count)';
  }

  @override
  String tuitionPaidCount(Object count) {
    return 'Đã nộp ($count)';
  }

  @override
  String get tuitionCollected => 'Đã thu';

  @override
  String get tuitionRemainingDebt => 'Chưa thanh toán';

  @override
  String tuitionUnfinalizedStudents(Object unfinalizedCount) {
    return '$unfinalizedCount học sinh chưa chốt học phí';
  }

  @override
  String tuitionUnfinalizedWithBlocked(
    Object blockedCount,
    Object unfinalizedCount,
  ) {
    return '$unfinalizedCount chưa chốt • $blockedCount chưa đủ dữ liệu';
  }

  @override
  String get tuitionFinalizeNow => 'Chốt học phí';

  @override
  String get tuitionCollect => 'Thu tiền';

  @override
  String get tuitionDetails => 'Chi tiết học phí';

  @override
  String get tuitionNoUnpaid => 'Không còn học sinh cần thu học phí.';

  @override
  String get tuitionNoPaid => 'Chưa có học sinh đã nộp đủ.';

  @override
  String tuitionPartialPayment(Object paid, Object remaining) {
    return 'Đã thu $paid • Còn $remaining';
  }

  @override
  String get qrPaymentTitle => 'Mã QR Thanh Toán';

  @override
  String get qrShareImage => 'Chia sẻ ảnh';

  @override
  String get qrCopyTransferContent => 'Sao chép nội dung CK';

  @override
  String get qrCardTitle => 'THÔNG TIN HỌC PHÍ';

  @override
  String qrCardMonth(Object month) {
    return 'Tháng $month';
  }

  @override
  String qrCardStudent(Object name) {
    return 'Học sinh: $name';
  }

  @override
  String qrCardClass(Object className) {
    return 'Lớp: $className';
  }

  @override
  String get qrCardAmount => 'SỐ TIỀN CẦN CHUYỂN';

  @override
  String get qrCardBank => 'Ngân hàng';

  @override
  String get qrCardAccountNumber => 'Số TK';

  @override
  String get qrCardAccountHolder => 'Chủ TK';

  @override
  String get qrCardTransferContent => 'Nội dung chuyển khoản';

  @override
  String get qrCardInstruction =>
      'Vui lòng chuyển đúng số tiền và nội dung trên.';

  @override
  String get sessionTabTitle => 'Buổi học';

  @override
  String get sessionFrom => 'Từ';

  @override
  String get sessionTo => 'Đến';

  @override
  String get sessionAddAction => '+ Buổi học';

  @override
  String get sessionGenerateOption => 'Sinh buổi từ lịch học';

  @override
  String get sessionAddManualOption => 'Thêm buổi học bù/phát sinh';

  @override
  String get sessionNoSessionsTitle => 'Chưa có buổi học.';

  @override
  String get sessionNoSessionsSubtitle =>
      'Sinh buổi học từ lịch định kỳ để bắt đầu.';

  @override
  String get sessionNoFilteredTitle =>
      'Không có buổi học trong khoảng thời gian đã chọn.';

  @override
  String sessionMonthHeader(Object monthYear) {
    return 'THÁNG $monthYear';
  }

  @override
  String get sessionToday => 'Hôm nay';

  @override
  String get sessionTypeMain => 'Chính';

  @override
  String get sessionTypeMakeup => 'Học bù';

  @override
  String get sessionTypeExtra => 'Phát sinh';

  @override
  String get sessionStatusUpcoming => 'Dự kiến';

  @override
  String get sessionStatusCompleted => 'Đã học';

  @override
  String get sessionStatusCanceled => 'Hủy';

  @override
  String get sessionStatusHoliday => 'Nghỉ lễ';

  @override
  String get sessionMarkUpcoming => 'Đánh dấu: DỰ KIẾN';

  @override
  String get sessionMarkCanceled => 'Đánh dấu: HỦY';

  @override
  String get sessionMarkHoliday => 'Đánh dấu: NGHỈ LỄ';

  @override
  String dashboardRecentCount(Object count) {
    return '$count cập nhật';
  }

  @override
  String dashboardLatestActivity(Object time) {
    return 'Mới nhất: $time';
  }

  @override
  String classGradeHeader(Object grade) {
    return 'KHỐI $grade';
  }

  @override
  String get classUnknownGrade => 'CHƯA XẾP KHỐI';

  @override
  String get studentLoadDetailError => 'Không tải được thông tin học sinh.';
}
