import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('vi'),
  ];

  /// No description provided for @appName.
  ///
  /// In vi, this message translates to:
  /// **'Tuition2027'**
  String get appName;

  /// No description provided for @navHome.
  ///
  /// In vi, this message translates to:
  /// **'Trang chủ'**
  String get navHome;

  /// No description provided for @navClasses.
  ///
  /// In vi, this message translates to:
  /// **'Lớp học'**
  String get navClasses;

  /// No description provided for @navStudents.
  ///
  /// In vi, this message translates to:
  /// **'Học sinh'**
  String get navStudents;

  /// No description provided for @navTuition.
  ///
  /// In vi, this message translates to:
  /// **'Học phí'**
  String get navTuition;

  /// No description provided for @navReports.
  ///
  /// In vi, this message translates to:
  /// **'Báo cáo'**
  String get navReports;

  /// No description provided for @navSettings.
  ///
  /// In vi, this message translates to:
  /// **'Cài đặt'**
  String get navSettings;

  /// No description provided for @globalMenu.
  ///
  /// In vi, this message translates to:
  /// **'Menu điều hướng'**
  String get globalMenu;

  /// No description provided for @menuTitle.
  ///
  /// In vi, this message translates to:
  /// **'Danh mục chức năng'**
  String get menuTitle;

  /// No description provided for @menuSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Quản lý trung tâm dạy thêm'**
  String get menuSubtitle;

  /// No description provided for @palettePhysicsBlue.
  ///
  /// In vi, this message translates to:
  /// **'Xanh Vật lý'**
  String get palettePhysicsBlue;

  /// No description provided for @paletteEmerald.
  ///
  /// In vi, this message translates to:
  /// **'Xanh Ngọc Emerald'**
  String get paletteEmerald;

  /// No description provided for @paletteIndigo.
  ///
  /// In vi, this message translates to:
  /// **'Xanh Chàm Indigo'**
  String get paletteIndigo;

  /// No description provided for @paletteAmber.
  ///
  /// In vi, this message translates to:
  /// **'Vàng Hổ Phách'**
  String get paletteAmber;

  /// No description provided for @paletteSlate.
  ///
  /// In vi, this message translates to:
  /// **'Xám Đá Slate'**
  String get paletteSlate;

  /// No description provided for @paletteOceanCyan.
  ///
  /// In vi, this message translates to:
  /// **'Xanh Lam Cyan'**
  String get paletteOceanCyan;

  /// No description provided for @paletteBurgundy.
  ///
  /// In vi, this message translates to:
  /// **'Đỏ Rượu Burgundy'**
  String get paletteBurgundy;

  /// No description provided for @paletteHighContrast.
  ///
  /// In vi, this message translates to:
  /// **'Tương Phản Cao'**
  String get paletteHighContrast;

  /// No description provided for @dashboardTitle.
  ///
  /// In vi, this message translates to:
  /// **'Trang chủ'**
  String get dashboardTitle;

  /// No description provided for @dashboardGreeting.
  ///
  /// In vi, this message translates to:
  /// **'Chào thầy cô!'**
  String get dashboardGreeting;

  /// No description provided for @dashboardGreetingSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Chúc một ngày dạy học hiệu quả!'**
  String get dashboardGreetingSubtitle;

  /// No description provided for @dashboardTodaySessions.
  ///
  /// In vi, this message translates to:
  /// **'Buổi hôm nay'**
  String get dashboardTodaySessions;

  /// No description provided for @dashboardPendingAttendance.
  ///
  /// In vi, this message translates to:
  /// **'Cần điểm danh'**
  String get dashboardPendingAttendance;

  /// No description provided for @dashboardUnfinalizedTuition.
  ///
  /// In vi, this message translates to:
  /// **'Chưa chốt học phí'**
  String get dashboardUnfinalizedTuition;

  /// No description provided for @dashboardOutstandingDebt.
  ///
  /// In vi, this message translates to:
  /// **'Nợ cần xử lý'**
  String get dashboardOutstandingDebt;

  /// No description provided for @dashboardTasks.
  ///
  /// In vi, this message translates to:
  /// **'Việc cần làm hôm nay'**
  String get dashboardTasks;

  /// No description provided for @dashboardAttendanceNow.
  ///
  /// In vi, this message translates to:
  /// **'Điểm danh ngay'**
  String get dashboardAttendanceNow;

  /// No description provided for @dashboardGenerateSessions.
  ///
  /// In vi, this message translates to:
  /// **'Sinh buổi học'**
  String get dashboardGenerateSessions;

  /// No description provided for @dashboardFinalizeTuition.
  ///
  /// In vi, this message translates to:
  /// **'Chốt học phí tháng'**
  String get dashboardFinalizeTuition;

  /// No description provided for @dashboardExportReport.
  ///
  /// In vi, this message translates to:
  /// **'Xuất báo cáo PDF'**
  String get dashboardExportReport;

  /// No description provided for @dashboardExportReportSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Báo cáo học phí & điểm danh'**
  String get dashboardExportReportSubtitle;

  /// No description provided for @dashboardGenerateSessionsSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Tạo buổi từ lịch học định kỳ'**
  String get dashboardGenerateSessionsSubtitle;

  /// No description provided for @dashboardNoPendingSessions.
  ///
  /// In vi, this message translates to:
  /// **'Không có buổi cần điểm danh'**
  String get dashboardNoPendingSessions;

  /// No description provided for @dashboardTodaySchedule.
  ///
  /// In vi, this message translates to:
  /// **'Lịch dạy hôm nay'**
  String get dashboardTodaySchedule;

  /// No description provided for @dashboardDone.
  ///
  /// In vi, this message translates to:
  /// **'Đã xong'**
  String get dashboardDone;

  /// No description provided for @dashboardNeedsAttendance.
  ///
  /// In vi, this message translates to:
  /// **'Cần điểm danh'**
  String get dashboardNeedsAttendance;

  /// No description provided for @dashboardUpcoming.
  ///
  /// In vi, this message translates to:
  /// **'Sắp diễn ra'**
  String get dashboardUpcoming;

  /// No description provided for @dashboardInProgress.
  ///
  /// In vi, this message translates to:
  /// **'Đang diễn ra'**
  String get dashboardInProgress;

  /// No description provided for @dashboardCanceled.
  ///
  /// In vi, this message translates to:
  /// **'Đã hủy'**
  String get dashboardCanceled;

  /// No description provided for @dashboardHoliday.
  ///
  /// In vi, this message translates to:
  /// **'Nghỉ lễ'**
  String get dashboardHoliday;

  /// No description provided for @dashboardWarnings.
  ///
  /// In vi, this message translates to:
  /// **'Cảnh báo nghiệp vụ'**
  String get dashboardWarnings;

  /// No description provided for @dashboardRecentActivity.
  ///
  /// In vi, this message translates to:
  /// **'Cập nhật gần đây'**
  String get dashboardRecentActivity;

  /// No description provided for @dashboardNoTasks.
  ///
  /// In vi, this message translates to:
  /// **'Không có công việc cần làm.'**
  String get dashboardNoTasks;

  /// No description provided for @dashboardNoWarnings.
  ///
  /// In vi, this message translates to:
  /// **'Không có cảnh báo nghiệp vụ nào.'**
  String get dashboardNoWarnings;

  /// No description provided for @dashboardNoSessions.
  ///
  /// In vi, this message translates to:
  /// **'Hôm nay không có buổi dạy nào.'**
  String get dashboardNoSessions;

  /// No description provided for @dashboardNoActivity.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có hoạt động gần đây.'**
  String get dashboardNoActivity;

  /// No description provided for @actionAddStudent.
  ///
  /// In vi, this message translates to:
  /// **'Thêm học sinh'**
  String get actionAddStudent;

  /// No description provided for @actionAddClass.
  ///
  /// In vi, this message translates to:
  /// **'Thêm lớp học'**
  String get actionAddClass;

  /// No description provided for @actionManageClasses.
  ///
  /// In vi, this message translates to:
  /// **'Quản lý lớp học'**
  String get actionManageClasses;

  /// No description provided for @actionViewTuition.
  ///
  /// In vi, this message translates to:
  /// **'Xem học phí'**
  String get actionViewTuition;

  /// No description provided for @actionViewReports.
  ///
  /// In vi, this message translates to:
  /// **'Xem báo cáo'**
  String get actionViewReports;

  /// No description provided for @searchResults.
  ///
  /// In vi, this message translates to:
  /// **'Kết quả tìm kiếm'**
  String get searchResults;

  /// No description provided for @searchNoResults.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy học sinh hoặc lớp học nào.'**
  String get searchNoResults;

  /// No description provided for @settingsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Cài đặt'**
  String get settingsTitle;

  /// No description provided for @settingsAppearance.
  ///
  /// In vi, this message translates to:
  /// **'GIAO DIỆN & CHỦ ĐỀ'**
  String get settingsAppearance;

  /// No description provided for @settingsThemeMode.
  ///
  /// In vi, this message translates to:
  /// **'Chế độ hiển thị'**
  String get settingsThemeMode;

  /// No description provided for @themeSystem.
  ///
  /// In vi, this message translates to:
  /// **'Theo hệ thống'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In vi, this message translates to:
  /// **'Sáng'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In vi, this message translates to:
  /// **'Tối'**
  String get themeDark;

  /// No description provided for @settingsPalette.
  ///
  /// In vi, this message translates to:
  /// **'Tông màu ứng dụng'**
  String get settingsPalette;

  /// No description provided for @settingsLanguage.
  ///
  /// In vi, this message translates to:
  /// **'NGÔN NGỮ'**
  String get settingsLanguage;

  /// No description provided for @langSystem.
  ///
  /// In vi, this message translates to:
  /// **'Theo hệ thống'**
  String get langSystem;

  /// No description provided for @langVietnamese.
  ///
  /// In vi, this message translates to:
  /// **'Tiếng Việt'**
  String get langVietnamese;

  /// No description provided for @langEnglish.
  ///
  /// In vi, this message translates to:
  /// **'English'**
  String get langEnglish;

  /// No description provided for @settingsAppInfo.
  ///
  /// In vi, this message translates to:
  /// **'THÔNG TIN ỨNG DỤNG'**
  String get settingsAppInfo;

  /// No description provided for @appVersion.
  ///
  /// In vi, this message translates to:
  /// **'Phiên bản: 1.0.0+1'**
  String get appVersion;

  /// No description provided for @dbVersion.
  ///
  /// In vi, this message translates to:
  /// **'Cơ sở dữ liệu: v15'**
  String get dbVersion;

  /// No description provided for @studentFormTitleAdd.
  ///
  /// In vi, this message translates to:
  /// **'Thêm học sinh'**
  String get studentFormTitleAdd;

  /// No description provided for @studentFormTitleEdit.
  ///
  /// In vi, this message translates to:
  /// **'Sửa thông tin học sinh'**
  String get studentFormTitleEdit;

  /// No description provided for @studentFullName.
  ///
  /// In vi, this message translates to:
  /// **'Họ và tên *'**
  String get studentFullName;

  /// No description provided for @studentGrade.
  ///
  /// In vi, this message translates to:
  /// **'Khối'**
  String get studentGrade;

  /// No description provided for @studentGradeItem.
  ///
  /// In vi, this message translates to:
  /// **'Khối {grade}'**
  String studentGradeItem(Object grade);

  /// No description provided for @studentGender.
  ///
  /// In vi, this message translates to:
  /// **'Giới tính'**
  String get studentGender;

  /// No description provided for @studentGenderMale.
  ///
  /// In vi, this message translates to:
  /// **'Nam'**
  String get studentGenderMale;

  /// No description provided for @studentGenderFemale.
  ///
  /// In vi, this message translates to:
  /// **'Nữ'**
  String get studentGenderFemale;

  /// No description provided for @studentGenderOther.
  ///
  /// In vi, this message translates to:
  /// **'Khác'**
  String get studentGenderOther;

  /// No description provided for @studentSchool.
  ///
  /// In vi, this message translates to:
  /// **'Trường đang học'**
  String get studentSchool;

  /// No description provided for @studentParentSection.
  ///
  /// In vi, this message translates to:
  /// **'Thông tin phụ huynh'**
  String get studentParentSection;

  /// No description provided for @studentParentName.
  ///
  /// In vi, this message translates to:
  /// **'Tên phụ huynh'**
  String get studentParentName;

  /// No description provided for @studentParentPhone.
  ///
  /// In vi, this message translates to:
  /// **'SĐT phụ huynh'**
  String get studentParentPhone;

  /// No description provided for @studentCardParentPhone.
  ///
  /// In vi, this message translates to:
  /// **'PH • {phone}'**
  String studentCardParentPhone(Object phone);

  /// No description provided for @studentOtherContactSection.
  ///
  /// In vi, this message translates to:
  /// **'Liên hệ khác'**
  String get studentOtherContactSection;

  /// No description provided for @studentPhone.
  ///
  /// In vi, this message translates to:
  /// **'SĐT học sinh'**
  String get studentPhone;

  /// No description provided for @studentEmail.
  ///
  /// In vi, this message translates to:
  /// **'Email'**
  String get studentEmail;

  /// No description provided for @studentAddress.
  ///
  /// In vi, this message translates to:
  /// **'Địa chỉ'**
  String get studentAddress;

  /// No description provided for @studentFacebook.
  ///
  /// In vi, this message translates to:
  /// **'Facebook'**
  String get studentFacebook;

  /// No description provided for @studentNotes.
  ///
  /// In vi, this message translates to:
  /// **'Ghi chú'**
  String get studentNotes;

  /// No description provided for @studentValidationName.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập họ tên'**
  String get studentValidationName;

  /// No description provided for @classFormTitleAdd.
  ///
  /// In vi, this message translates to:
  /// **'Thêm lớp học'**
  String get classFormTitleAdd;

  /// No description provided for @classFormTitleEdit.
  ///
  /// In vi, this message translates to:
  /// **'Sửa lớp học'**
  String get classFormTitleEdit;

  /// No description provided for @className.
  ///
  /// In vi, this message translates to:
  /// **'Tên lớp học *'**
  String get className;

  /// No description provided for @classSubject.
  ///
  /// In vi, this message translates to:
  /// **'Môn học'**
  String get classSubject;

  /// No description provided for @classMaxStudents.
  ///
  /// In vi, this message translates to:
  /// **'Sĩ số tối đa'**
  String get classMaxStudents;

  /// No description provided for @classNotes.
  ///
  /// In vi, this message translates to:
  /// **'Ghi chú'**
  String get classNotes;

  /// No description provided for @classValidationName.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập tên lớp'**
  String get classValidationName;

  /// No description provided for @filterActive.
  ///
  /// In vi, this message translates to:
  /// **'Đang hoạt động'**
  String get filterActive;

  /// No description provided for @filterArchived.
  ///
  /// In vi, this message translates to:
  /// **'Ngừng hoạt động'**
  String get filterArchived;

  /// No description provided for @filterAll.
  ///
  /// In vi, this message translates to:
  /// **'Tất cả'**
  String get filterAll;

  /// No description provided for @studentFilterActive.
  ///
  /// In vi, this message translates to:
  /// **'Đang học'**
  String get studentFilterActive;

  /// No description provided for @studentFilterStopped.
  ///
  /// In vi, this message translates to:
  /// **'Ngừng học'**
  String get studentFilterStopped;

  /// No description provided for @studentEmptyActive.
  ///
  /// In vi, this message translates to:
  /// **'Không có học sinh đang học phù hợp.'**
  String get studentEmptyActive;

  /// No description provided for @studentEmptyStopped.
  ///
  /// In vi, this message translates to:
  /// **'Không có học sinh ngừng học phù hợp.'**
  String get studentEmptyStopped;

  /// No description provided for @classFilterActive.
  ///
  /// In vi, this message translates to:
  /// **'Đang hoạt động'**
  String get classFilterActive;

  /// No description provided for @classFilterStopped.
  ///
  /// In vi, this message translates to:
  /// **'Ngừng hoạt động'**
  String get classFilterStopped;

  /// No description provided for @classEmptyActive.
  ///
  /// In vi, this message translates to:
  /// **'Không có lớp đang hoạt động phù hợp.'**
  String get classEmptyActive;

  /// No description provided for @classEmptyStopped.
  ///
  /// In vi, this message translates to:
  /// **'Không có lớp ngừng hoạt động phù hợp.'**
  String get classEmptyStopped;

  /// No description provided for @membershipTitle.
  ///
  /// In vi, this message translates to:
  /// **'Học sinh trong lớp'**
  String get membershipTitle;

  /// No description provided for @membershipActive.
  ///
  /// In vi, this message translates to:
  /// **'Đang tham gia'**
  String get membershipActive;

  /// No description provided for @membershipHistory.
  ///
  /// In vi, this message translates to:
  /// **'Lịch sử tham gia'**
  String get membershipHistory;

  /// No description provided for @actionEnrollStudent.
  ///
  /// In vi, this message translates to:
  /// **'Thêm học sinh vào lớp'**
  String get actionEnrollStudent;

  /// No description provided for @actionEndMembership.
  ///
  /// In vi, this message translates to:
  /// **'Kết thúc tham gia'**
  String get actionEndMembership;

  /// No description provided for @membershipStartDate.
  ///
  /// In vi, this message translates to:
  /// **'Ngày bắt đầu (YYYY-MM-DD)'**
  String get membershipStartDate;

  /// No description provided for @membershipEndDate.
  ///
  /// In vi, this message translates to:
  /// **'Ngày kết thúc (YYYY-MM-DD)'**
  String get membershipEndDate;

  /// No description provided for @membershipEndTitle.
  ///
  /// In vi, this message translates to:
  /// **'Kết thúc tham gia lớp?'**
  String get membershipEndTitle;

  /// No description provided for @membershipEndPrompt.
  ///
  /// In vi, this message translates to:
  /// **'Xác nhận kết thúc tham gia lớp học của học sinh này từ ngày chọn?'**
  String get membershipEndPrompt;

  /// No description provided for @selectStudent.
  ///
  /// In vi, this message translates to:
  /// **'Chọn học sinh *'**
  String get selectStudent;

  /// No description provided for @selectClass.
  ///
  /// In vi, this message translates to:
  /// **'Chọn lớp học *'**
  String get selectClass;

  /// No description provided for @studentSearchPlaceholder.
  ///
  /// In vi, this message translates to:
  /// **'Tìm tên học sinh...'**
  String get studentSearchPlaceholder;

  /// No description provided for @classSearchPlaceholder.
  ///
  /// In vi, this message translates to:
  /// **'Tìm tên lớp...'**
  String get classSearchPlaceholder;

  /// No description provided for @noStudentsFound.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy học sinh nào.'**
  String get noStudentsFound;

  /// No description provided for @noClassesFound.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy lớp học nào.'**
  String get noClassesFound;

  /// No description provided for @policyTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chính sách học phí'**
  String get policyTitle;

  /// No description provided for @policyEffective.
  ///
  /// In vi, this message translates to:
  /// **'Chính sách hiện tại'**
  String get policyEffective;

  /// No description provided for @policyHistory.
  ///
  /// In vi, this message translates to:
  /// **'Lịch sử chính sách'**
  String get policyHistory;

  /// No description provided for @actionCreatePolicy.
  ///
  /// In vi, this message translates to:
  /// **'Tạo chính sách mới'**
  String get actionCreatePolicy;

  /// No description provided for @policyStandardSessions.
  ///
  /// In vi, this message translates to:
  /// **'Số buổi chuẩn N/tháng *'**
  String get policyStandardSessions;

  /// No description provided for @policyFeePerSession.
  ///
  /// In vi, this message translates to:
  /// **'Học phí/buổi (VNĐ) *'**
  String get policyFeePerSession;

  /// No description provided for @policyStartMonth.
  ///
  /// In vi, this message translates to:
  /// **'Tháng bắt đầu (YYYY-MM) *'**
  String get policyStartMonth;

  /// No description provided for @policyEndMonth.
  ///
  /// In vi, this message translates to:
  /// **'Tháng kết thúc (YYYY-MM)'**
  String get policyEndMonth;

  /// No description provided for @policyStatusActive.
  ///
  /// In vi, this message translates to:
  /// **'Đang áp dụng'**
  String get policyStatusActive;

  /// No description provided for @policyStatusExpired.
  ///
  /// In vi, this message translates to:
  /// **'Đã hết hạn'**
  String get policyStatusExpired;

  /// No description provided for @policyStatusFuture.
  ///
  /// In vi, this message translates to:
  /// **'Sắp áp dụng'**
  String get policyStatusFuture;

  /// No description provided for @policyValidationSessions.
  ///
  /// In vi, this message translates to:
  /// **'Nhập số buổi hợp lệ (> 0)'**
  String get policyValidationSessions;

  /// No description provided for @policyValidationFee.
  ///
  /// In vi, this message translates to:
  /// **'Nhập học phí hợp lệ (>= 0)'**
  String get policyValidationFee;

  /// No description provided for @policyValidationMonth.
  ///
  /// In vi, this message translates to:
  /// **'Nhập tháng đúng định dạng YYYY-MM'**
  String get policyValidationMonth;

  /// No description provided for @actionArchive.
  ///
  /// In vi, this message translates to:
  /// **'Lưu trữ'**
  String get actionArchive;

  /// No description provided for @actionRestore.
  ///
  /// In vi, this message translates to:
  /// **'Khôi phục'**
  String get actionRestore;

  /// No description provided for @actionEdit.
  ///
  /// In vi, this message translates to:
  /// **'Chỉnh sửa'**
  String get actionEdit;

  /// No description provided for @actionDetail.
  ///
  /// In vi, this message translates to:
  /// **'Chi tiết'**
  String get actionDetail;

  /// No description provided for @actionConfirmArchive.
  ///
  /// In vi, this message translates to:
  /// **'Lưu trữ mục này?'**
  String get actionConfirmArchive;

  /// No description provided for @actionConfirmRestore.
  ///
  /// In vi, this message translates to:
  /// **'Khôi phục mục này?'**
  String get actionConfirmRestore;

  /// No description provided for @commonLoading.
  ///
  /// In vi, this message translates to:
  /// **'Đang tải dữ liệu...'**
  String get commonLoading;

  /// No description provided for @commonEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có dữ liệu.'**
  String get commonEmpty;

  /// No description provided for @commonError.
  ///
  /// In vi, this message translates to:
  /// **'Đã xảy ra lỗi'**
  String get commonError;

  /// No description provided for @commonRetry.
  ///
  /// In vi, this message translates to:
  /// **'Thử lại'**
  String get commonRetry;

  /// No description provided for @commonConfirm.
  ///
  /// In vi, this message translates to:
  /// **'Xác nhận'**
  String get commonConfirm;

  /// No description provided for @commonCancel.
  ///
  /// In vi, this message translates to:
  /// **'Hủy'**
  String get commonCancel;

  /// No description provided for @commonSave.
  ///
  /// In vi, this message translates to:
  /// **'Lưu'**
  String get commonSave;

  /// No description provided for @dirtyFormTitle.
  ///
  /// In vi, this message translates to:
  /// **'Rời khỏi trang?'**
  String get dirtyFormTitle;

  /// No description provided for @dirtyFormMessage.
  ///
  /// In vi, this message translates to:
  /// **'Bạn có thay đổi chưa lưu. Bạn có chắc muốn rời đi và bỏ các thay đổi này không?'**
  String get dirtyFormMessage;

  /// No description provided for @dirtyFormDiscard.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ thay đổi'**
  String get dirtyFormDiscard;

  /// No description provided for @dirtyFormKeepEditing.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp tục chỉnh sửa'**
  String get dirtyFormKeepEditing;

  /// No description provided for @settingsPaymentQr.
  ///
  /// In vi, this message translates to:
  /// **'THANH TOÁN & QR'**
  String get settingsPaymentQr;

  /// No description provided for @settingsBankAccount.
  ///
  /// In vi, this message translates to:
  /// **'Tài khoản nhận học phí'**
  String get settingsBankAccount;

  /// No description provided for @settingsBankAccountSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Cấu hình thông tin ngân hàng và mã VietQR nhận học phí'**
  String get settingsBankAccountSubtitle;

  /// No description provided for @bankAccountTitle.
  ///
  /// In vi, this message translates to:
  /// **'THÔNG TIN TÀI KHOẢN NGÂN HÀNG'**
  String get bankAccountTitle;

  /// No description provided for @bankName.
  ///
  /// In vi, this message translates to:
  /// **'Ngân hàng'**
  String get bankName;

  /// No description provided for @bankAccountNumber.
  ///
  /// In vi, this message translates to:
  /// **'Số tài khoản'**
  String get bankAccountNumber;

  /// No description provided for @bankAccountHolder.
  ///
  /// In vi, this message translates to:
  /// **'Tên chủ tài khoản'**
  String get bankAccountHolder;

  /// No description provided for @bankTransferTemplate.
  ///
  /// In vi, this message translates to:
  /// **'Mẫu nội dung chuyển khoản'**
  String get bankTransferTemplate;

  /// No description provided for @bankTransferTemplateHelper.
  ///
  /// In vi, this message translates to:
  /// **'Dùng {maHocSinh} cho mã/ID học sinh, {thang} cho tháng'**
  String bankTransferTemplateHelper(Object maHocSinh, Object thang);

  /// No description provided for @bankAccountSaveSuccess.
  ///
  /// In vi, this message translates to:
  /// **'Đã lưu thông tin tài khoản nhận học phí'**
  String get bankAccountSaveSuccess;

  /// No description provided for @bankAccountValidationNumber.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập số tài khoản'**
  String get bankAccountValidationNumber;

  /// No description provided for @bankAccountValidationHolder.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập tên chủ tài khoản'**
  String get bankAccountValidationHolder;

  /// No description provided for @bankAccountValidationTemplate.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập mẫu nội dung chuyển khoản'**
  String get bankAccountValidationTemplate;

  /// No description provided for @vietQrPreviewTitle.
  ///
  /// In vi, this message translates to:
  /// **'XEM TRƯỚC VIETQR'**
  String get vietQrPreviewTitle;

  /// No description provided for @vietQrPreviewSample.
  ///
  /// In vi, this message translates to:
  /// **'Nội dung mẫu (Ví dụ 500.000đ, HS001, 09/2026):'**
  String get vietQrPreviewSample;

  /// No description provided for @vietQrNotConfigured.
  ///
  /// In vi, this message translates to:
  /// **'Nhập số tài khoản và tên chủ tài khoản để tạo mã VietQR xem trước.'**
  String get vietQrNotConfigured;

  /// No description provided for @reportsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Báo cáo'**
  String get reportsTitle;

  /// No description provided for @reportsFilterTitle.
  ///
  /// In vi, this message translates to:
  /// **'BỘ LỌC BÁO CÁO'**
  String get reportsFilterTitle;

  /// No description provided for @reportsMode.
  ///
  /// In vi, this message translates to:
  /// **'Chế độ xem'**
  String get reportsMode;

  /// No description provided for @reportsModeMonth.
  ///
  /// In vi, this message translates to:
  /// **'Theo tháng'**
  String get reportsModeMonth;

  /// No description provided for @reportsModeCustomRange.
  ///
  /// In vi, this message translates to:
  /// **'Khoảng ngày'**
  String get reportsModeCustomRange;

  /// No description provided for @reportsSelectMonth.
  ///
  /// In vi, this message translates to:
  /// **'Chọn tháng báo cáo'**
  String get reportsSelectMonth;

  /// No description provided for @reportsFromDate.
  ///
  /// In vi, this message translates to:
  /// **'Từ'**
  String get reportsFromDate;

  /// No description provided for @reportsToDate.
  ///
  /// In vi, this message translates to:
  /// **'Đến'**
  String get reportsToDate;

  /// No description provided for @reportsFilterClass.
  ///
  /// In vi, this message translates to:
  /// **'Lớp học'**
  String get reportsFilterClass;

  /// No description provided for @reportsFilterStudent.
  ///
  /// In vi, this message translates to:
  /// **'Học sinh'**
  String get reportsFilterStudent;

  /// No description provided for @reportsAllClasses.
  ///
  /// In vi, this message translates to:
  /// **'Tất cả các lớp'**
  String get reportsAllClasses;

  /// No description provided for @reportsAllStudents.
  ///
  /// In vi, this message translates to:
  /// **'Tất cả học sinh'**
  String get reportsAllStudents;

  /// No description provided for @reportsApplyFilter.
  ///
  /// In vi, this message translates to:
  /// **'Áp dụng'**
  String get reportsApplyFilter;

  /// No description provided for @reportsClearFilter.
  ///
  /// In vi, this message translates to:
  /// **'Xóa bộ lọc'**
  String get reportsClearFilter;

  /// No description provided for @reportsFilteredClass.
  ///
  /// In vi, this message translates to:
  /// **'Đã lọc lớp'**
  String get reportsFilteredClass;

  /// No description provided for @reportsFilteredStudent.
  ///
  /// In vi, this message translates to:
  /// **'Đã lọc học sinh'**
  String get reportsFilteredStudent;

  /// No description provided for @reportsExportPdf.
  ///
  /// In vi, this message translates to:
  /// **'Xuất báo cáo PDF'**
  String get reportsExportPdf;

  /// No description provided for @reportsExportPdfError.
  ///
  /// In vi, this message translates to:
  /// **'Lỗi xuất PDF: {error}'**
  String reportsExportPdfError(Object error);

  /// No description provided for @reportsKpiAttendanceRate.
  ///
  /// In vi, this message translates to:
  /// **'Tỷ lệ đi học'**
  String get reportsKpiAttendanceRate;

  /// No description provided for @reportsKpiInvoiced.
  ///
  /// In vi, this message translates to:
  /// **'Học phí đã chốt'**
  String get reportsKpiInvoiced;

  /// No description provided for @reportsKpiPaid.
  ///
  /// In vi, this message translates to:
  /// **'Thực nhận'**
  String get reportsKpiPaid;

  /// No description provided for @reportsKpiOutstanding.
  ///
  /// In vi, this message translates to:
  /// **'Còn nợ'**
  String get reportsKpiOutstanding;

  /// No description provided for @reportsSectionAttendance.
  ///
  /// In vi, this message translates to:
  /// **'A. ĐIỂM DANH'**
  String get reportsSectionAttendance;

  /// No description provided for @reportsSectionFinancial.
  ///
  /// In vi, this message translates to:
  /// **'B. HỌC PHÍ'**
  String get reportsSectionFinancial;

  /// No description provided for @reportsSectionSessions.
  ///
  /// In vi, this message translates to:
  /// **'C. BUỔI HỌC'**
  String get reportsSectionSessions;

  /// No description provided for @reportsSectionClassBreakdown.
  ///
  /// In vi, this message translates to:
  /// **'D. CHI TIẾT THEO LỚP HỌC'**
  String get reportsSectionClassBreakdown;

  /// No description provided for @reportsSectionStudentBreakdown.
  ///
  /// In vi, this message translates to:
  /// **'CHI TIẾT THEO HỌC SINH'**
  String get reportsSectionStudentBreakdown;

  /// No description provided for @reportsAttendanceOverallRate.
  ///
  /// In vi, this message translates to:
  /// **'Tỷ lệ đi học tổng thể'**
  String get reportsAttendanceOverallRate;

  /// No description provided for @reportsAttendancePresent.
  ///
  /// In vi, this message translates to:
  /// **'Có mặt'**
  String get reportsAttendancePresent;

  /// No description provided for @reportsAttendanceLate.
  ///
  /// In vi, this message translates to:
  /// **'Đi trễ'**
  String get reportsAttendanceLate;

  /// No description provided for @reportsAttendanceExcused.
  ///
  /// In vi, this message translates to:
  /// **'Có phép'**
  String get reportsAttendanceExcused;

  /// No description provided for @reportsAttendanceUnexcused.
  ///
  /// In vi, this message translates to:
  /// **'Vắng x.phép'**
  String get reportsAttendanceUnexcused;

  /// No description provided for @reportsFinancialInvoiced.
  ///
  /// In vi, this message translates to:
  /// **'Chốt hóa đơn'**
  String get reportsFinancialInvoiced;

  /// No description provided for @reportsFinancialPaid.
  ///
  /// In vi, this message translates to:
  /// **'Đã thu'**
  String get reportsFinancialPaid;

  /// No description provided for @reportsFinancialDebt.
  ///
  /// In vi, this message translates to:
  /// **'Dư nợ'**
  String get reportsFinancialDebt;

  /// No description provided for @reportsTotalSessions.
  ///
  /// In vi, this message translates to:
  /// **'Tổng số buổi'**
  String get reportsTotalSessions;

  /// No description provided for @reportsTotalParticipations.
  ///
  /// In vi, this message translates to:
  /// **'Tổng lượt học'**
  String get reportsTotalParticipations;

  /// No description provided for @reportsNoData.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có dữ liệu báo cáo trong khoảng thời gian đã chọn.'**
  String get reportsNoData;

  /// No description provided for @enrollStudentTitle.
  ///
  /// In vi, this message translates to:
  /// **'THÊM HỌC SINH VÀO LỚP'**
  String get enrollStudentTitle;

  /// No description provided for @enrollOptionExisting.
  ///
  /// In vi, this message translates to:
  /// **'Chọn HS có sẵn'**
  String get enrollOptionExisting;

  /// No description provided for @enrollOptionNew.
  ///
  /// In vi, this message translates to:
  /// **'Thêm HS mới'**
  String get enrollOptionNew;

  /// No description provided for @enrollJoinDate.
  ///
  /// In vi, this message translates to:
  /// **'Ngày tham gia'**
  String get enrollJoinDate;

  /// No description provided for @enrollDiscount.
  ///
  /// In vi, this message translates to:
  /// **'Mức giảm giá (%)'**
  String get enrollDiscount;

  /// No description provided for @enrollPartialSuccess.
  ///
  /// In vi, this message translates to:
  /// **'Học sinh đã được tạo nhưng ghi danh chưa hoàn tất.'**
  String get enrollPartialSuccess;

  /// No description provided for @busyTimeTitle.
  ///
  /// In vi, this message translates to:
  /// **'THÊM GIỜ BẬN CỦA HỌC SINH'**
  String get busyTimeTitle;

  /// No description provided for @busyTimeType.
  ///
  /// In vi, this message translates to:
  /// **'Loại giờ bận'**
  String get busyTimeType;

  /// No description provided for @busyTimeFrequency.
  ///
  /// In vi, this message translates to:
  /// **'Tần suất'**
  String get busyTimeFrequency;

  /// No description provided for @busyTimeWeekly.
  ///
  /// In vi, this message translates to:
  /// **'Hằng tuần'**
  String get busyTimeWeekly;

  /// No description provided for @busyTimeOneTime.
  ///
  /// In vi, this message translates to:
  /// **'Một lần'**
  String get busyTimeOneTime;

  /// No description provided for @busyTimeDayOfWeek.
  ///
  /// In vi, this message translates to:
  /// **'Thứ trong tuần'**
  String get busyTimeDayOfWeek;

  /// No description provided for @busyTimeDate.
  ///
  /// In vi, this message translates to:
  /// **'Ngày bận'**
  String get busyTimeDate;

  /// No description provided for @busyTimeStartTime.
  ///
  /// In vi, this message translates to:
  /// **'Từ giờ'**
  String get busyTimeStartTime;

  /// No description provided for @busyTimeEndTime.
  ///
  /// In vi, this message translates to:
  /// **'Đến giờ'**
  String get busyTimeEndTime;

  /// No description provided for @busyTimeEffectiveFrom.
  ///
  /// In vi, this message translates to:
  /// **'Hiệu lực từ ngày'**
  String get busyTimeEffectiveFrom;

  /// No description provided for @busyTimeEffectiveTo.
  ///
  /// In vi, this message translates to:
  /// **'Hiệu lực đến ngày'**
  String get busyTimeEffectiveTo;

  /// No description provided for @busyTimeDeleteConfirm.
  ///
  /// In vi, this message translates to:
  /// **'Bạn có chắc muốn xóa giờ bận này?'**
  String get busyTimeDeleteConfirm;

  /// No description provided for @settingsTuitionPolicySection.
  ///
  /// In vi, this message translates to:
  /// **'CHÍNH SÁCH HỌC PHÍ'**
  String get settingsTuitionPolicySection;

  /// No description provided for @settingsTuitionPolicyTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chính sách học phí các lớp'**
  String get settingsTuitionPolicyTitle;

  /// No description provided for @settingsTuitionPolicySubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Thiết lập đơn giá và số buổi chuẩn tháng cho từng lớp'**
  String get settingsTuitionPolicySubtitle;

  /// No description provided for @creditsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Buổi dư & Credit'**
  String get creditsTitle;

  /// No description provided for @creditsHeaderStudent.
  ///
  /// In vi, this message translates to:
  /// **'Học sinh'**
  String get creditsHeaderStudent;

  /// No description provided for @creditsHeaderClass.
  ///
  /// In vi, this message translates to:
  /// **'Lớp học'**
  String get creditsHeaderClass;

  /// No description provided for @creditsClosingBalance.
  ///
  /// In vi, this message translates to:
  /// **'Số dư cuối tháng'**
  String get creditsClosingBalance;

  /// No description provided for @creditsSummaryTitle.
  ///
  /// In vi, this message translates to:
  /// **'Thống kê buổi học theo chuẩn'**
  String get creditsSummaryTitle;

  /// No description provided for @creditsMaxStandard.
  ///
  /// In vi, this message translates to:
  /// **'Tối đa chuẩn'**
  String get creditsMaxStandard;

  /// No description provided for @creditsEligible.
  ///
  /// In vi, this message translates to:
  /// **'Đủ điều kiện'**
  String get creditsEligible;

  /// No description provided for @creditsStandard.
  ///
  /// In vi, this message translates to:
  /// **'Buổi chuẩn'**
  String get creditsStandard;

  /// No description provided for @creditsExtra.
  ///
  /// In vi, this message translates to:
  /// **'Buổi dư'**
  String get creditsExtra;

  /// No description provided for @creditsPotential.
  ///
  /// In vi, this message translates to:
  /// **'Đủ ĐK ghi sổ'**
  String get creditsPotential;

  /// No description provided for @creditsRecorded.
  ///
  /// In vi, this message translates to:
  /// **'Đã ghi sổ'**
  String get creditsRecorded;

  /// No description provided for @creditsMonthDelta.
  ///
  /// In vi, this message translates to:
  /// **'Thay đổi trong kỳ'**
  String get creditsMonthDelta;

  /// No description provided for @creditsReconcile.
  ///
  /// In vi, this message translates to:
  /// **'Đối soát buổi dư'**
  String get creditsReconcile;

  /// No description provided for @creditsManualAdjustment.
  ///
  /// In vi, this message translates to:
  /// **'Điều chỉnh thủ công'**
  String get creditsManualAdjustment;

  /// No description provided for @creditsCandidatesTitle.
  ///
  /// In vi, this message translates to:
  /// **'Danh sách buổi học đủ điều kiện'**
  String get creditsCandidatesTitle;

  /// No description provided for @creditsCandidatesEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Không có buổi học chính thức đã hoàn tất nào trong tháng này.'**
  String get creditsCandidatesEmpty;

  /// No description provided for @creditsLedgerTitle.
  ///
  /// In vi, this message translates to:
  /// **'Lịch sử sổ dư credit (Ledger)'**
  String get creditsLedgerTitle;

  /// No description provided for @creditsLedgerEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có lịch sử biến động credit nào.'**
  String get creditsLedgerEmpty;

  /// No description provided for @creditsStandardTag.
  ///
  /// In vi, this message translates to:
  /// **'Chuẩn'**
  String get creditsStandardTag;

  /// No description provided for @creditsExtraTag.
  ///
  /// In vi, this message translates to:
  /// **'Vượt chuẩn'**
  String get creditsExtraTag;

  /// No description provided for @creditsEarnedTag.
  ///
  /// In vi, this message translates to:
  /// **'Đã ghi +1'**
  String get creditsEarnedTag;

  /// No description provided for @creditsCanEarnTag.
  ///
  /// In vi, this message translates to:
  /// **'Có thể ghi +1'**
  String get creditsCanEarnTag;

  /// No description provided for @assignmentTitle.
  ///
  /// In vi, this message translates to:
  /// **'Phân ca học sinh'**
  String get assignmentTitle;

  /// No description provided for @assignmentBulkBtn.
  ///
  /// In vi, this message translates to:
  /// **'Phân ca nhiều HS'**
  String get assignmentBulkBtn;

  /// No description provided for @assignmentAddStudent.
  ///
  /// In vi, this message translates to:
  /// **'Thêm học sinh'**
  String get assignmentAddStudent;

  /// No description provided for @assignmentStudentCount.
  ///
  /// In vi, this message translates to:
  /// **'{count} học sinh'**
  String assignmentStudentCount(Object count);

  /// No description provided for @assignmentNoStudentsInShift.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có học sinh trong ca này'**
  String get assignmentNoStudentsInShift;

  /// No description provided for @assignmentNoSchedules.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có lịch học định kỳ nào để phân ca.'**
  String get assignmentNoSchedules;

  /// No description provided for @assignmentStatusActive.
  ///
  /// In vi, this message translates to:
  /// **'Đang học'**
  String get assignmentStatusActive;

  /// No description provided for @assignmentStatusClosed.
  ///
  /// In vi, this message translates to:
  /// **'Kết thúc'**
  String get assignmentStatusClosed;

  /// No description provided for @assignmentEditStartDate.
  ///
  /// In vi, this message translates to:
  /// **'Sửa ngày bắt đầu'**
  String get assignmentEditStartDate;

  /// No description provided for @assignmentChangeShift.
  ///
  /// In vi, this message translates to:
  /// **'Chuyển ca'**
  String get assignmentChangeShift;

  /// No description provided for @assignmentCloseShift.
  ///
  /// In vi, this message translates to:
  /// **'Kết thúc phân ca'**
  String get assignmentCloseShift;

  /// No description provided for @assignmentCloseConfirmTitle.
  ///
  /// In vi, this message translates to:
  /// **'CHỌN NGÀY KẾT THÚC PHÂN CA'**
  String get assignmentCloseConfirmTitle;

  /// No description provided for @assignmentCloseSuccess.
  ///
  /// In vi, this message translates to:
  /// **'Đã kết thúc phân ca học sinh'**
  String get assignmentCloseSuccess;

  /// No description provided for @bulkAssignmentSheetTitle.
  ///
  /// In vi, this message translates to:
  /// **'Phân ca hàng loạt học sinh'**
  String get bulkAssignmentSheetTitle;

  /// No description provided for @bulkAssignmentSelectShift.
  ///
  /// In vi, this message translates to:
  /// **'Chọn ca học *'**
  String get bulkAssignmentSelectShift;

  /// No description provided for @bulkAssignmentStartDate.
  ///
  /// In vi, this message translates to:
  /// **'Ngày bắt đầu phân ca'**
  String get bulkAssignmentStartDate;

  /// No description provided for @bulkAssignmentCandidateHeader.
  ///
  /// In vi, this message translates to:
  /// **'Danh sách học sinh đủ điều kiện'**
  String get bulkAssignmentCandidateHeader;

  /// No description provided for @bulkAssignmentSearchPlaceholder.
  ///
  /// In vi, this message translates to:
  /// **'Tìm tên học sinh...'**
  String get bulkAssignmentSearchPlaceholder;

  /// No description provided for @bulkAssignmentAllAssigned.
  ///
  /// In vi, this message translates to:
  /// **'Tất cả học sinh đủ điều kiện đã được phân vào ca này.'**
  String get bulkAssignmentAllAssigned;

  /// No description provided for @bulkAssignmentSelectAll.
  ///
  /// In vi, this message translates to:
  /// **'Chọn tất cả ({count})'**
  String bulkAssignmentSelectAll(Object count);

  /// No description provided for @bulkAssignmentSubmit.
  ///
  /// In vi, this message translates to:
  /// **'Phân ca {count} học sinh'**
  String bulkAssignmentSubmit(Object count);

  /// No description provided for @bulkAssignmentProcessing.
  ///
  /// In vi, this message translates to:
  /// **'Đang xử lý...'**
  String get bulkAssignmentProcessing;

  /// No description provided for @bulkAssignmentSuccess.
  ///
  /// In vi, this message translates to:
  /// **'Đã phân ca thành công {count} học sinh'**
  String bulkAssignmentSuccess(Object count);

  /// No description provided for @bulkAssignmentPreviewTitle.
  ///
  /// In vi, this message translates to:
  /// **'KẾT QUẢ KIỂM TRA PHÂN CA'**
  String get bulkAssignmentPreviewTitle;

  /// No description provided for @bulkAssignmentPreviewReady.
  ///
  /// In vi, this message translates to:
  /// **'Hợp lệ sẵn sàng phân ca: {count} học sinh'**
  String bulkAssignmentPreviewReady(Object count);

  /// No description provided for @bulkAssignmentPreviewBlocked.
  ///
  /// In vi, this message translates to:
  /// **'Không thể phân ca: {count} học sinh'**
  String bulkAssignmentPreviewBlocked(Object count);

  /// No description provided for @bulkAssignmentPreviewWarnings.
  ///
  /// In vi, this message translates to:
  /// **'Cảnh báo không ưu tiên: {count} học sinh'**
  String bulkAssignmentPreviewWarnings(Object count);

  /// No description provided for @bulkAssignmentPreviewConfirmBtn.
  ///
  /// In vi, this message translates to:
  /// **'Phân ca {count} HS hợp lệ'**
  String bulkAssignmentPreviewConfirmBtn(Object count);

  /// No description provided for @editStartDateTitle.
  ///
  /// In vi, this message translates to:
  /// **'Sửa ngày bắt đầu phân ca'**
  String get editStartDateTitle;

  /// No description provided for @editStartDateNew.
  ///
  /// In vi, this message translates to:
  /// **'Ngày bắt đầu phân ca mới'**
  String get editStartDateNew;

  /// No description provided for @editStartDateSuccess.
  ///
  /// In vi, this message translates to:
  /// **'Cập nhật ngày bắt đầu phân ca thành công'**
  String get editStartDateSuccess;

  /// No description provided for @changeShiftTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chuyển ca học định kỳ'**
  String get changeShiftTitle;

  /// No description provided for @changeShiftSelectNew.
  ///
  /// In vi, this message translates to:
  /// **'Chọn ca học mới'**
  String get changeShiftSelectNew;

  /// No description provided for @changeShiftEffectiveDate.
  ///
  /// In vi, this message translates to:
  /// **'Ngày áp dụng ca mới'**
  String get changeShiftEffectiveDate;

  /// No description provided for @changeShiftSuccess.
  ///
  /// In vi, this message translates to:
  /// **'Chuyển ca học sinh thành công'**
  String get changeShiftSuccess;

  /// No description provided for @changeShiftValidationSelect.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng chọn ca học mới'**
  String get changeShiftValidationSelect;

  /// No description provided for @weekdayMonday.
  ///
  /// In vi, this message translates to:
  /// **'Thứ 2'**
  String get weekdayMonday;

  /// No description provided for @weekdayTuesday.
  ///
  /// In vi, this message translates to:
  /// **'Thứ 3'**
  String get weekdayTuesday;

  /// No description provided for @weekdayWednesday.
  ///
  /// In vi, this message translates to:
  /// **'Thứ 4'**
  String get weekdayWednesday;

  /// No description provided for @weekdayThursday.
  ///
  /// In vi, this message translates to:
  /// **'Thứ 5'**
  String get weekdayThursday;

  /// No description provided for @weekdayFriday.
  ///
  /// In vi, this message translates to:
  /// **'Thứ 6'**
  String get weekdayFriday;

  /// No description provided for @weekdaySaturday.
  ///
  /// In vi, this message translates to:
  /// **'Thứ 7'**
  String get weekdaySaturday;

  /// No description provided for @weekdaySunday.
  ///
  /// In vi, this message translates to:
  /// **'Chủ Nhật'**
  String get weekdaySunday;

  /// No description provided for @attendanceTitle.
  ///
  /// In vi, this message translates to:
  /// **'Điểm danh buổi học'**
  String get attendanceTitle;

  /// No description provided for @attendanceShortTitle.
  ///
  /// In vi, this message translates to:
  /// **'Điểm danh'**
  String get attendanceShortTitle;

  /// No description provided for @attendanceCompleted.
  ///
  /// In vi, this message translates to:
  /// **'Đã hoàn tất'**
  String get attendanceCompleted;

  /// No description provided for @attendanceEditingCompleted.
  ///
  /// In vi, this message translates to:
  /// **'Đang sửa điểm danh đã hoàn tất'**
  String get attendanceEditingCompleted;

  /// No description provided for @attendanceStudents.
  ///
  /// In vi, this message translates to:
  /// **'HỌC SINH'**
  String get attendanceStudents;

  /// No description provided for @attendanceLegend.
  ///
  /// In vi, this message translates to:
  /// **'Chú thích điểm danh'**
  String get attendanceLegend;

  /// No description provided for @attendanceEdit.
  ///
  /// In vi, this message translates to:
  /// **'Sửa điểm danh'**
  String get attendanceEdit;

  /// No description provided for @attendanceSaveCorrection.
  ///
  /// In vi, this message translates to:
  /// **'Lưu chỉnh sửa'**
  String get attendanceSaveCorrection;

  /// No description provided for @attendanceCancelCorrection.
  ///
  /// In vi, this message translates to:
  /// **'Hủy chỉnh sửa'**
  String get attendanceCancelCorrection;

  /// No description provided for @attendanceApprovedLeave.
  ///
  /// In vi, this message translates to:
  /// **'Đơn nghỉ đã duyệt'**
  String get attendanceApprovedLeave;

  /// No description provided for @attendanceApplySuggestion.
  ///
  /// In vi, this message translates to:
  /// **'Áp dụng'**
  String get attendanceApplySuggestion;

  /// No description provided for @attendanceMakeup.
  ///
  /// In vi, this message translates to:
  /// **'Học bù'**
  String get attendanceMakeup;

  /// No description provided for @attendanceFinalizeShort.
  ///
  /// In vi, this message translates to:
  /// **'Hoàn tất'**
  String get attendanceFinalizeShort;

  /// No description provided for @attendanceMarkAllPresent.
  ///
  /// In vi, this message translates to:
  /// **'Có mặt hết'**
  String get attendanceMarkAllPresent;

  /// No description provided for @attendanceMarkAllMakeup.
  ///
  /// In vi, this message translates to:
  /// **'Học bù hết'**
  String get attendanceMarkAllMakeup;

  /// No description provided for @attendanceUndo.
  ///
  /// In vi, this message translates to:
  /// **'Hoàn tác'**
  String get attendanceUndo;

  /// No description provided for @attendanceDraftSave.
  ///
  /// In vi, this message translates to:
  /// **'Lưu nháp'**
  String get attendanceDraftSave;

  /// No description provided for @attendanceFinalizeSession.
  ///
  /// In vi, this message translates to:
  /// **'Hoàn tất buổi học'**
  String get attendanceFinalizeSession;

  /// No description provided for @attendanceChangeShift.
  ///
  /// In vi, this message translates to:
  /// **'Đổi ca'**
  String get attendanceChangeShift;

  /// No description provided for @attendanceScheduleMakeup.
  ///
  /// In vi, this message translates to:
  /// **'Xếp học bù'**
  String get attendanceScheduleMakeup;

  /// No description provided for @attendanceCancelAdjustment.
  ///
  /// In vi, this message translates to:
  /// **'Hủy điều chỉnh'**
  String get attendanceCancelAdjustment;

  /// No description provided for @attendanceAddStudent.
  ///
  /// In vi, this message translates to:
  /// **'Thêm học sinh'**
  String get attendanceAddStudent;

  /// No description provided for @attendancePresent.
  ///
  /// In vi, this message translates to:
  /// **'Có mặt'**
  String get attendancePresent;

  /// No description provided for @attendanceLate.
  ///
  /// In vi, this message translates to:
  /// **'Trễ'**
  String get attendanceLate;

  /// No description provided for @attendanceExcused.
  ///
  /// In vi, this message translates to:
  /// **'Có phép'**
  String get attendanceExcused;

  /// No description provided for @attendanceUnexcused.
  ///
  /// In vi, this message translates to:
  /// **'Không phép'**
  String get attendanceUnexcused;

  /// No description provided for @attendanceNotMarked.
  ///
  /// In vi, this message translates to:
  /// **'Chưa điểm danh'**
  String get attendanceNotMarked;

  /// No description provided for @tuitionKpiPreview.
  ///
  /// In vi, this message translates to:
  /// **'Tạm tính'**
  String get tuitionKpiPreview;

  /// No description provided for @tuitionKpiFinalized.
  ///
  /// In vi, this message translates to:
  /// **'Đã chốt'**
  String get tuitionKpiFinalized;

  /// No description provided for @tuitionKpiPaid.
  ///
  /// In vi, this message translates to:
  /// **'Đã thu'**
  String get tuitionKpiPaid;

  /// No description provided for @tuitionKpiDebt.
  ///
  /// In vi, this message translates to:
  /// **'Còn nợ'**
  String get tuitionKpiDebt;

  /// No description provided for @tuitionFinalizeMonth.
  ///
  /// In vi, this message translates to:
  /// **'Chốt học phí tháng'**
  String get tuitionFinalizeMonth;

  /// No description provided for @tuitionRecalculate.
  ///
  /// In vi, this message translates to:
  /// **'Tính lại học phí'**
  String get tuitionRecalculate;

  /// No description provided for @tuitionPaymentHistory.
  ///
  /// In vi, this message translates to:
  /// **'Lịch sử thu'**
  String get tuitionPaymentHistory;

  /// No description provided for @tuitionPaymentAction.
  ///
  /// In vi, this message translates to:
  /// **'Thanh toán'**
  String get tuitionPaymentAction;

  /// No description provided for @tuitionQrAction.
  ///
  /// In vi, this message translates to:
  /// **'QR'**
  String get tuitionQrAction;

  /// No description provided for @tuitionPendingAttendance.
  ///
  /// In vi, this message translates to:
  /// **'Chưa đủ dữ liệu tính học phí'**
  String get tuitionPendingAttendance;

  /// No description provided for @tuitionWaitingCompletion.
  ///
  /// In vi, this message translates to:
  /// **'Đang chờ hoàn tất buổi học'**
  String get tuitionWaitingCompletion;

  /// No description provided for @tuitionFinalizeFirstNotice.
  ///
  /// In vi, this message translates to:
  /// **'Chốt học phí trước khi thu tiền.'**
  String get tuitionFinalizeFirstNotice;

  /// No description provided for @tuitionMonthlyCap.
  ///
  /// In vi, this message translates to:
  /// **'Trần học phí tháng'**
  String get tuitionMonthlyCap;

  /// No description provided for @tuitionEffectiveFrom.
  ///
  /// In vi, this message translates to:
  /// **'Hiệu lực từ ngày'**
  String get tuitionEffectiveFrom;

  /// No description provided for @paymentHistoryTitle.
  ///
  /// In vi, this message translates to:
  /// **'Lịch sử thu tiền'**
  String get paymentHistoryTitle;

  /// No description provided for @paymentEditTitle.
  ///
  /// In vi, this message translates to:
  /// **'Sửa khoản thu'**
  String get paymentEditTitle;

  /// No description provided for @paymentRecordTitle.
  ///
  /// In vi, this message translates to:
  /// **'Ghi nhận thanh toán'**
  String get paymentRecordTitle;

  /// No description provided for @paymentEditReason.
  ///
  /// In vi, this message translates to:
  /// **'Lý do sửa'**
  String get paymentEditReason;

  /// No description provided for @paymentEditReasonValidation.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập lý do sửa khoản thu'**
  String get paymentEditReasonValidation;

  /// No description provided for @paymentEditSuccess.
  ///
  /// In vi, this message translates to:
  /// **'Đã cập nhật khoản thu thành công'**
  String get paymentEditSuccess;

  /// No description provided for @studentDetailTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chi tiết học sinh'**
  String get studentDetailTitle;

  /// No description provided for @studentStatusActive.
  ///
  /// In vi, this message translates to:
  /// **'Đang học'**
  String get studentStatusActive;

  /// No description provided for @studentStatusStopped.
  ///
  /// In vi, this message translates to:
  /// **'Ngừng học'**
  String get studentStatusStopped;

  /// No description provided for @studentJoinedFrom.
  ///
  /// In vi, this message translates to:
  /// **'Tham gia từ: {date}'**
  String studentJoinedFrom(Object date);

  /// No description provided for @studentActiveClassesCount.
  ///
  /// In vi, this message translates to:
  /// **'{count} lớp đang tham gia'**
  String studentActiveClassesCount(Object count);

  /// No description provided for @studentOutstandingDebt.
  ///
  /// In vi, this message translates to:
  /// **'Còn nợ: {amount}'**
  String studentOutstandingDebt(Object amount);

  /// No description provided for @studentEditProfile.
  ///
  /// In vi, this message translates to:
  /// **'Sửa hồ sơ'**
  String get studentEditProfile;

  /// No description provided for @studentAddToClass.
  ///
  /// In vi, this message translates to:
  /// **'Thêm vào lớp'**
  String get studentAddToClass;

  /// No description provided for @studentBusyTime.
  ///
  /// In vi, this message translates to:
  /// **'Giờ bận'**
  String get studentBusyTime;

  /// No description provided for @studentRecordPayment.
  ///
  /// In vi, this message translates to:
  /// **'Ghi nhận thu'**
  String get studentRecordPayment;

  /// No description provided for @studentActiveClasses.
  ///
  /// In vi, this message translates to:
  /// **'Lớp đang tham gia'**
  String get studentActiveClasses;

  /// No description provided for @studentTuitionMonth.
  ///
  /// In vi, this message translates to:
  /// **'Học phí tháng {month}'**
  String studentTuitionMonth(Object month);

  /// No description provided for @studentFinalizedDue.
  ///
  /// In vi, this message translates to:
  /// **'Đã chốt'**
  String get studentFinalizedDue;

  /// No description provided for @studentPaid.
  ///
  /// In vi, this message translates to:
  /// **'Đã thu'**
  String get studentPaid;

  /// No description provided for @studentDebt.
  ///
  /// In vi, this message translates to:
  /// **'Còn nợ'**
  String get studentDebt;

  /// No description provided for @studentTuitionPartiallyPaid.
  ///
  /// In vi, this message translates to:
  /// **'Đã thanh toán một phần'**
  String get studentTuitionPartiallyPaid;

  /// No description provided for @studentTuitionPaid.
  ///
  /// In vi, this message translates to:
  /// **'Đã thanh toán'**
  String get studentTuitionPaid;

  /// No description provided for @studentTuitionUnpaid.
  ///
  /// In vi, this message translates to:
  /// **'Chưa thanh toán'**
  String get studentTuitionUnpaid;

  /// No description provided for @studentTuitionPendingFinalization.
  ///
  /// In vi, this message translates to:
  /// **'Còn lớp chưa chốt'**
  String get studentTuitionPendingFinalization;

  /// No description provided for @studentLatestPayment.
  ///
  /// In vi, this message translates to:
  /// **'Khoản thu gần nhất'**
  String get studentLatestPayment;

  /// No description provided for @studentNoPayment.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có khoản thu trong tháng này'**
  String get studentNoPayment;

  /// No description provided for @studentRecentAttendance.
  ///
  /// In vi, this message translates to:
  /// **'Điểm danh gần đây'**
  String get studentRecentAttendance;

  /// No description provided for @studentSeeAll.
  ///
  /// In vi, this message translates to:
  /// **'Xem tất cả'**
  String get studentSeeAll;

  /// No description provided for @studentBusyTimes.
  ///
  /// In vi, this message translates to:
  /// **'Giờ bận'**
  String get studentBusyTimes;

  /// No description provided for @studentNoActiveClasses.
  ///
  /// In vi, this message translates to:
  /// **'Chưa tham gia lớp nào'**
  String get studentNoActiveClasses;

  /// No description provided for @studentNoDebtToRecord.
  ///
  /// In vi, this message translates to:
  /// **'Không có khoản học phí đã chốt cần thanh toán.'**
  String get studentNoDebtToRecord;

  /// No description provided for @studentSelectTuitionInvoice.
  ///
  /// In vi, this message translates to:
  /// **'Chọn khoản học phí cần thanh toán'**
  String get studentSelectTuitionInvoice;

  /// No description provided for @classKpiActive.
  ///
  /// In vi, this message translates to:
  /// **'Lớp hoạt động'**
  String get classKpiActive;

  /// No description provided for @classKpiTodaySessions.
  ///
  /// In vi, this message translates to:
  /// **'Buổi hôm nay'**
  String get classKpiTodaySessions;

  /// No description provided for @classKpiPendingAttendance.
  ///
  /// In vi, this message translates to:
  /// **'Cần điểm danh'**
  String get classKpiPendingAttendance;

  /// No description provided for @classKpiMissingTuition.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có học phí'**
  String get classKpiMissingTuition;

  /// No description provided for @classListTitle.
  ///
  /// In vi, this message translates to:
  /// **'Danh sách lớp'**
  String get classListTitle;

  /// No description provided for @classCountActive.
  ///
  /// In vi, this message translates to:
  /// **'{count} lớp đang hoạt động'**
  String classCountActive(Object count);

  /// No description provided for @classCountStopped.
  ///
  /// In vi, this message translates to:
  /// **'{count} lớp ngừng hoạt động'**
  String classCountStopped(Object count);

  /// No description provided for @classStatusNeedsAttendance.
  ///
  /// In vi, this message translates to:
  /// **'Cần điểm danh'**
  String get classStatusNeedsAttendance;

  /// No description provided for @classStatusInProgress.
  ///
  /// In vi, this message translates to:
  /// **'Đang diễn ra'**
  String get classStatusInProgress;

  /// No description provided for @classStatusUpcoming.
  ///
  /// In vi, this message translates to:
  /// **'Sắp diễn ra'**
  String get classStatusUpcoming;

  /// No description provided for @classStatusCompleted.
  ///
  /// In vi, this message translates to:
  /// **'Đã hoàn tất'**
  String get classStatusCompleted;

  /// No description provided for @classStatusMissingTuition.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có học phí'**
  String get classStatusMissingTuition;

  /// No description provided for @classStatusDebt.
  ///
  /// In vi, this message translates to:
  /// **'Còn nợ'**
  String get classStatusDebt;

  /// No description provided for @classNeedsAction.
  ///
  /// In vi, this message translates to:
  /// **'Cần xử lý'**
  String get classNeedsAction;

  /// No description provided for @classSeeAll.
  ///
  /// In vi, this message translates to:
  /// **'Xem tất cả'**
  String get classSeeAll;

  /// No description provided for @classWarningMissingTuition.
  ///
  /// In vi, this message translates to:
  /// **'{count} lớp chưa thiết lập học phí'**
  String classWarningMissingTuition(Object count);

  /// No description provided for @classWarningOverdueAttendance.
  ///
  /// In vi, this message translates to:
  /// **'{count} buổi quá giờ cần điểm danh'**
  String classWarningOverdueAttendance(Object count);

  /// No description provided for @classWarningMissingSessions.
  ///
  /// In vi, this message translates to:
  /// **'{count} lớp chưa sinh buổi tuần này'**
  String classWarningMissingSessions(Object count);

  /// No description provided for @classStudentCount.
  ///
  /// In vi, this message translates to:
  /// **'{count} học sinh'**
  String classStudentCount(Object count);

  /// No description provided for @classMultipleShifts.
  ///
  /// In vi, this message translates to:
  /// **'{count} ca đang áp dụng'**
  String classMultipleShifts(Object count);

  /// No description provided for @classEmptyActiveTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có lớp đang hoạt động.'**
  String get classEmptyActiveTitle;

  /// No description provided for @classEmptyStoppedTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có lớp ngừng hoạt động.'**
  String get classEmptyStoppedTitle;

  /// No description provided for @tuitionTitle.
  ///
  /// In vi, this message translates to:
  /// **'Quản lý Học phí'**
  String get tuitionTitle;

  /// No description provided for @tuitionFilterUnpaid.
  ///
  /// In vi, this message translates to:
  /// **'Chưa nộp ({count})'**
  String tuitionFilterUnpaid(Object count);

  /// No description provided for @tuitionFilterPaid.
  ///
  /// In vi, this message translates to:
  /// **'Đã nộp ({count})'**
  String tuitionFilterPaid(Object count);

  /// No description provided for @tuitionUnpaidCount.
  ///
  /// In vi, this message translates to:
  /// **'Chưa nộp ({count})'**
  String tuitionUnpaidCount(Object count);

  /// No description provided for @tuitionPaidCount.
  ///
  /// In vi, this message translates to:
  /// **'Đã nộp ({count})'**
  String tuitionPaidCount(Object count);

  /// No description provided for @tuitionCollected.
  ///
  /// In vi, this message translates to:
  /// **'Đã thu'**
  String get tuitionCollected;

  /// No description provided for @tuitionRemainingDebt.
  ///
  /// In vi, this message translates to:
  /// **'Còn nợ'**
  String get tuitionRemainingDebt;

  /// No description provided for @tuitionUnfinalizedStudents.
  ///
  /// In vi, this message translates to:
  /// **'{unfinalizedCount} học sinh chưa chốt học phí'**
  String tuitionUnfinalizedStudents(Object unfinalizedCount);

  /// No description provided for @tuitionUnfinalizedWithBlocked.
  ///
  /// In vi, this message translates to:
  /// **'{unfinalizedCount} chưa chốt • {blockedCount} chưa đủ dữ liệu'**
  String tuitionUnfinalizedWithBlocked(
    Object blockedCount,
    Object unfinalizedCount,
  );

  /// No description provided for @tuitionFinalizeNow.
  ///
  /// In vi, this message translates to:
  /// **'Chốt học phí'**
  String get tuitionFinalizeNow;

  /// No description provided for @tuitionCollect.
  ///
  /// In vi, this message translates to:
  /// **'Thu tiền'**
  String get tuitionCollect;

  /// No description provided for @tuitionDetails.
  ///
  /// In vi, this message translates to:
  /// **'Chi tiết học phí'**
  String get tuitionDetails;

  /// No description provided for @tuitionNoUnpaid.
  ///
  /// In vi, this message translates to:
  /// **'Không còn học sinh cần thu học phí.'**
  String get tuitionNoUnpaid;

  /// No description provided for @tuitionNoPaid.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có học sinh đã nộp đủ.'**
  String get tuitionNoPaid;

  /// No description provided for @tuitionPartialPayment.
  ///
  /// In vi, this message translates to:
  /// **'Đã thu {paid} • Còn {remaining}'**
  String tuitionPartialPayment(Object paid, Object remaining);

  /// No description provided for @qrPaymentTitle.
  ///
  /// In vi, this message translates to:
  /// **'Mã QR Thanh Toán'**
  String get qrPaymentTitle;

  /// No description provided for @qrShareImage.
  ///
  /// In vi, this message translates to:
  /// **'Chia sẻ ảnh'**
  String get qrShareImage;

  /// No description provided for @qrCopyTransferContent.
  ///
  /// In vi, this message translates to:
  /// **'Sao chép nội dung CK'**
  String get qrCopyTransferContent;

  /// No description provided for @qrCardTitle.
  ///
  /// In vi, this message translates to:
  /// **'THÔNG TIN HỌC PHÍ'**
  String get qrCardTitle;

  /// No description provided for @qrCardMonth.
  ///
  /// In vi, this message translates to:
  /// **'Tháng {month}'**
  String qrCardMonth(Object month);

  /// No description provided for @qrCardStudent.
  ///
  /// In vi, this message translates to:
  /// **'Học sinh: {name}'**
  String qrCardStudent(Object name);

  /// No description provided for @qrCardClass.
  ///
  /// In vi, this message translates to:
  /// **'Lớp: {className}'**
  String qrCardClass(Object className);

  /// No description provided for @qrCardAmount.
  ///
  /// In vi, this message translates to:
  /// **'SỐ TIỀN CẦN CHUYỂN'**
  String get qrCardAmount;

  /// No description provided for @qrCardBank.
  ///
  /// In vi, this message translates to:
  /// **'Ngân hàng'**
  String get qrCardBank;

  /// No description provided for @qrCardAccountNumber.
  ///
  /// In vi, this message translates to:
  /// **'Số TK'**
  String get qrCardAccountNumber;

  /// No description provided for @qrCardAccountHolder.
  ///
  /// In vi, this message translates to:
  /// **'Chủ TK'**
  String get qrCardAccountHolder;

  /// No description provided for @qrCardTransferContent.
  ///
  /// In vi, this message translates to:
  /// **'Nội dung chuyển khoản'**
  String get qrCardTransferContent;

  /// No description provided for @qrCardInstruction.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng chuyển đúng số tiền và nội dung trên.'**
  String get qrCardInstruction;

  /// No description provided for @sessionTabTitle.
  ///
  /// In vi, this message translates to:
  /// **'Buổi học'**
  String get sessionTabTitle;

  /// No description provided for @sessionFrom.
  ///
  /// In vi, this message translates to:
  /// **'Từ'**
  String get sessionFrom;

  /// No description provided for @sessionTo.
  ///
  /// In vi, this message translates to:
  /// **'Đến'**
  String get sessionTo;

  /// No description provided for @sessionAddAction.
  ///
  /// In vi, this message translates to:
  /// **'+ Buổi học'**
  String get sessionAddAction;

  /// No description provided for @sessionGenerateOption.
  ///
  /// In vi, this message translates to:
  /// **'Sinh buổi từ lịch học'**
  String get sessionGenerateOption;

  /// No description provided for @sessionAddManualOption.
  ///
  /// In vi, this message translates to:
  /// **'Thêm buổi học bù/phát sinh'**
  String get sessionAddManualOption;

  /// No description provided for @sessionNoSessionsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có buổi học.'**
  String get sessionNoSessionsTitle;

  /// No description provided for @sessionNoSessionsSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Sinh buổi học từ lịch định kỳ để bắt đầu.'**
  String get sessionNoSessionsSubtitle;

  /// No description provided for @sessionNoFilteredTitle.
  ///
  /// In vi, this message translates to:
  /// **'Không có buổi học trong khoảng thời gian đã chọn.'**
  String get sessionNoFilteredTitle;

  /// No description provided for @sessionMonthHeader.
  ///
  /// In vi, this message translates to:
  /// **'THÁNG {monthYear}'**
  String sessionMonthHeader(Object monthYear);

  /// No description provided for @sessionToday.
  ///
  /// In vi, this message translates to:
  /// **'Hôm nay'**
  String get sessionToday;

  /// No description provided for @sessionTypeMain.
  ///
  /// In vi, this message translates to:
  /// **'Chính'**
  String get sessionTypeMain;

  /// No description provided for @sessionTypeMakeup.
  ///
  /// In vi, this message translates to:
  /// **'Học bù'**
  String get sessionTypeMakeup;

  /// No description provided for @sessionTypeExtra.
  ///
  /// In vi, this message translates to:
  /// **'Phát sinh'**
  String get sessionTypeExtra;

  /// No description provided for @sessionStatusUpcoming.
  ///
  /// In vi, this message translates to:
  /// **'Dự kiến'**
  String get sessionStatusUpcoming;

  /// No description provided for @sessionStatusCompleted.
  ///
  /// In vi, this message translates to:
  /// **'Đã học'**
  String get sessionStatusCompleted;

  /// No description provided for @sessionStatusCanceled.
  ///
  /// In vi, this message translates to:
  /// **'Hủy'**
  String get sessionStatusCanceled;

  /// No description provided for @sessionStatusHoliday.
  ///
  /// In vi, this message translates to:
  /// **'Nghỉ lễ'**
  String get sessionStatusHoliday;

  /// No description provided for @sessionMarkUpcoming.
  ///
  /// In vi, this message translates to:
  /// **'Đánh dấu: DỰ KIẾN'**
  String get sessionMarkUpcoming;

  /// No description provided for @sessionMarkCanceled.
  ///
  /// In vi, this message translates to:
  /// **'Đánh dấu: HỦY'**
  String get sessionMarkCanceled;

  /// No description provided for @sessionMarkHoliday.
  ///
  /// In vi, this message translates to:
  /// **'Đánh dấu: NGHỈ LỄ'**
  String get sessionMarkHoliday;

  /// No description provided for @dashboardRecentCount.
  ///
  /// In vi, this message translates to:
  /// **'{count} cập nhật'**
  String dashboardRecentCount(Object count);

  /// No description provided for @dashboardLatestActivity.
  ///
  /// In vi, this message translates to:
  /// **'Mới nhất: {time}'**
  String dashboardLatestActivity(Object time);

  /// No description provided for @classGradeHeader.
  ///
  /// In vi, this message translates to:
  /// **'KHỐI {grade}'**
  String classGradeHeader(Object grade);

  /// No description provided for @classUnknownGrade.
  ///
  /// In vi, this message translates to:
  /// **'CHƯA XẾP KHỐI'**
  String get classUnknownGrade;

  /// No description provided for @studentLoadDetailError.
  ///
  /// In vi, this message translates to:
  /// **'Không tải được thông tin học sinh.'**
  String get studentLoadDetailError;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'vi':
      return AppLocalizationsVi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
