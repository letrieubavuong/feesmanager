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
  /// **'Xin chào, Thầy/Cô!'**
  String get dashboardGreeting;

  /// No description provided for @dashboardToday.
  ///
  /// In vi, this message translates to:
  /// **'Lịch học hôm nay'**
  String get dashboardToday;

  /// No description provided for @dashboardQuickActions.
  ///
  /// In vi, this message translates to:
  /// **'Thao tác nhanh'**
  String get dashboardQuickActions;

  /// No description provided for @dashboardOverview.
  ///
  /// In vi, this message translates to:
  /// **'Tổng quan trung tâm'**
  String get dashboardOverview;

  /// No description provided for @dashboardSearchPlaceholder.
  ///
  /// In vi, this message translates to:
  /// **'Tìm học sinh hoặc lớp học...'**
  String get dashboardSearchPlaceholder;

  /// No description provided for @dashboardNoSessionsToday.
  ///
  /// In vi, this message translates to:
  /// **'Hôm nay không có buổi học nào.'**
  String get dashboardNoSessionsToday;

  /// No description provided for @dashboardActiveClasses.
  ///
  /// In vi, this message translates to:
  /// **'Lớp học đang mở'**
  String get dashboardActiveClasses;

  /// No description provided for @dashboardActiveStudents.
  ///
  /// In vi, this message translates to:
  /// **'Học sinh đang học'**
  String get dashboardActiveStudents;

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
  /// **'Cơ sở dữ liệu: v13'**
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
  /// **'Đã lưu trữ'**
  String get filterArchived;

  /// No description provided for @filterAll.
  ///
  /// In vi, this message translates to:
  /// **'Tất cả'**
  String get filterAll;

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
