// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get appName => 'Tuition2027';

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
  String get dashboardGreeting => 'Xin chào, Thầy/Cô!';

  @override
  String get dashboardToday => 'Lịch học hôm nay';

  @override
  String get dashboardQuickActions => 'Thao tác nhanh';

  @override
  String get dashboardOverview => 'Tổng quan trung tâm';

  @override
  String get dashboardSearchPlaceholder => 'Tìm học sinh hoặc lớp học...';

  @override
  String get dashboardNoSessionsToday => 'Hôm nay không có buổi học nào.';

  @override
  String get dashboardActiveClasses => 'Lớp học đang mở';

  @override
  String get dashboardActiveStudents => 'Học sinh đang học';

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
  String get appVersion => 'Phiên bản: 1.0.0+1';

  @override
  String get dbVersion => 'Cơ sở dữ liệu: v13';

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
  String get reportsKpiOutstanding => 'Còn nợ';

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
}
