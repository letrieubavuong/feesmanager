// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Tuition2027';

  @override
  String get navHome => 'Home';

  @override
  String get navClasses => 'Classes';

  @override
  String get navStudents => 'Students';

  @override
  String get navTuition => 'Tuition';

  @override
  String get navReports => 'Reports';

  @override
  String get navSettings => 'Settings';

  @override
  String get globalMenu => 'Global Menu';

  @override
  String get menuTitle => 'Navigation Menu';

  @override
  String get menuSubtitle => 'Tuition Management System';

  @override
  String get palettePhysicsBlue => 'Physics Blue';

  @override
  String get paletteEmerald => 'Emerald Green';

  @override
  String get paletteIndigo => 'Indigo';

  @override
  String get paletteAmber => 'Amber';

  @override
  String get paletteSlate => 'Slate Grey';

  @override
  String get paletteOceanCyan => 'Ocean Cyan';

  @override
  String get paletteBurgundy => 'Burgundy Rose';

  @override
  String get paletteHighContrast => 'High Contrast';

  @override
  String get dashboardTitle => 'Home';

  @override
  String get dashboardGreeting => 'Welcome Teacher!';

  @override
  String get dashboardGreetingSubtitle => 'Have a productive teaching day!';

  @override
  String get dashboardTodaySessions => 'Today\'s Sessions';

  @override
  String get dashboardPendingAttendance => 'Needs Attendance';

  @override
  String get dashboardUnfinalizedTuition => 'Unfinalized Tuition';

  @override
  String get dashboardOutstandingDebt => 'Outstanding Debt';

  @override
  String get dashboardTasks => 'Today\'s Tasks';

  @override
  String get dashboardAttendanceNow => 'Mark Attendance Now';

  @override
  String get dashboardGenerateSessions => 'Generate Sessions';

  @override
  String get dashboardFinalizeTuition => 'Finalize Monthly Tuition';

  @override
  String get dashboardExportReport => 'Export PDF Report';

  @override
  String get dashboardExportReportSubtitle => 'Tuition & Attendance Report';

  @override
  String get dashboardGenerateSessionsSubtitle =>
      'Generate sessions from recurring schedule';

  @override
  String get dashboardNoPendingSessions => 'No pending sessions for attendance';

  @override
  String get dashboardTodaySchedule => 'Today\'s Schedule';

  @override
  String get dashboardDone => 'Completed';

  @override
  String get dashboardNeedsAttendance => 'Needs Attendance';

  @override
  String get dashboardUpcoming => 'Upcoming';

  @override
  String get dashboardInProgress => 'In Progress';

  @override
  String get dashboardCanceled => 'Canceled';

  @override
  String get dashboardHoliday => 'Holiday';

  @override
  String get dashboardWarnings => 'Business Warnings';

  @override
  String get dashboardRecentActivity => 'Recent Activity';

  @override
  String get dashboardNoTasks => 'No pending tasks.';

  @override
  String get dashboardNoWarnings => 'No business warnings.';

  @override
  String get dashboardNoSessions => 'No teaching sessions scheduled for today.';

  @override
  String get dashboardNoActivity => 'No recent activity.';

  @override
  String get actionAddStudent => 'Add Student';

  @override
  String get actionAddClass => 'Add Class';

  @override
  String get actionManageClasses => 'Manage Classes';

  @override
  String get actionViewTuition => 'View Tuition';

  @override
  String get actionViewReports => 'View Reports';

  @override
  String get searchResults => 'Search Results';

  @override
  String get searchNoResults => 'No students or classes found.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsAppearance => 'APPEARANCE & THEME';

  @override
  String get settingsThemeMode => 'Theme Mode';

  @override
  String get themeSystem => 'System Default';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get settingsPalette => 'Color Palette';

  @override
  String get settingsLanguage => 'LANGUAGE';

  @override
  String get langSystem => 'System Default';

  @override
  String get langVietnamese => 'Tiếng Việt';

  @override
  String get langEnglish => 'English';

  @override
  String get settingsAppInfo => 'APPLICATION INFO';

  @override
  String get appVersion => 'Version: 1.0.0+1';

  @override
  String get dbVersion => 'Database: v13';

  @override
  String get studentFormTitleAdd => 'Add Student';

  @override
  String get studentFormTitleEdit => 'Edit Student';

  @override
  String get studentFullName => 'Full Name *';

  @override
  String get studentGrade => 'Grade';

  @override
  String studentGradeItem(Object grade) {
    return 'Grade $grade';
  }

  @override
  String get studentGender => 'Gender';

  @override
  String get studentGenderMale => 'Male';

  @override
  String get studentGenderFemale => 'Female';

  @override
  String get studentGenderOther => 'Other';

  @override
  String get studentSchool => 'School';

  @override
  String get studentParentSection => 'Parent Information';

  @override
  String get studentParentName => 'Parent Name';

  @override
  String get studentParentPhone => 'Parent Phone';

  @override
  String get studentOtherContactSection => 'Other Contacts';

  @override
  String get studentPhone => 'Student Phone';

  @override
  String get studentEmail => 'Email';

  @override
  String get studentAddress => 'Address';

  @override
  String get studentFacebook => 'Facebook';

  @override
  String get studentNotes => 'Notes';

  @override
  String get studentValidationName => 'Please enter full name';

  @override
  String get classFormTitleAdd => 'Add Class';

  @override
  String get classFormTitleEdit => 'Edit Class';

  @override
  String get className => 'Class Name *';

  @override
  String get classSubject => 'Subject';

  @override
  String get classMaxStudents => 'Max Class Size';

  @override
  String get classNotes => 'Notes';

  @override
  String get classValidationName => 'Please enter class name';

  @override
  String get filterActive => 'Active';

  @override
  String get filterArchived => 'Inactive';

  @override
  String get filterAll => 'All';

  @override
  String get studentFilterActive => 'Active';

  @override
  String get studentFilterStopped => 'Stopped';

  @override
  String get studentEmptyActive => 'No active students found.';

  @override
  String get studentEmptyStopped => 'No stopped students found.';

  @override
  String get classFilterActive => 'Active';

  @override
  String get classFilterStopped => 'Stopped';

  @override
  String get classEmptyActive => 'No active classes found.';

  @override
  String get classEmptyStopped => 'No stopped classes found.';

  @override
  String get membershipTitle => 'Students in Class';

  @override
  String get membershipActive => 'Currently Enrolled';

  @override
  String get membershipHistory => 'Enrollment History';

  @override
  String get actionEnrollStudent => 'Add Student to Class';

  @override
  String get actionEndMembership => 'End Enrollment';

  @override
  String get membershipStartDate => 'Start Date (YYYY-MM-DD)';

  @override
  String get membershipEndDate => 'End Date (YYYY-MM-DD)';

  @override
  String get membershipEndTitle => 'End Class Enrollment?';

  @override
  String get membershipEndPrompt =>
      'Are you sure you want to end enrollment for this student from the selected date?';

  @override
  String get selectStudent => 'Select Student *';

  @override
  String get selectClass => 'Select Class *';

  @override
  String get studentSearchPlaceholder => 'Search student name...';

  @override
  String get classSearchPlaceholder => 'Search class name...';

  @override
  String get noStudentsFound => 'No students found.';

  @override
  String get noClassesFound => 'No classes found.';

  @override
  String get policyTitle => 'Tuition Policy';

  @override
  String get policyEffective => 'Current Effective Policy';

  @override
  String get policyHistory => 'Policy History';

  @override
  String get actionCreatePolicy => 'Create New Policy';

  @override
  String get policyStandardSessions => 'Standard Sessions N/month *';

  @override
  String get policyFeePerSession => 'Fee per Session (VND) *';

  @override
  String get policyStartMonth => 'Start Month (YYYY-MM) *';

  @override
  String get policyEndMonth => 'End Month (YYYY-MM)';

  @override
  String get policyStatusActive => 'Active';

  @override
  String get policyStatusExpired => 'Expired';

  @override
  String get policyStatusFuture => 'Upcoming';

  @override
  String get policyValidationSessions => 'Enter valid session count (> 0)';

  @override
  String get policyValidationFee => 'Enter valid fee (>= 0)';

  @override
  String get policyValidationMonth => 'Enter month in YYYY-MM format';

  @override
  String get actionArchive => 'Archive';

  @override
  String get actionRestore => 'Restore';

  @override
  String get actionEdit => 'Edit';

  @override
  String get actionDetail => 'Details';

  @override
  String get actionConfirmArchive => 'Archive this item?';

  @override
  String get actionConfirmRestore => 'Restore this item?';

  @override
  String get commonLoading => 'Loading data...';

  @override
  String get commonEmpty => 'No data available.';

  @override
  String get commonError => 'An error occurred';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonConfirm => 'Confirm';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonSave => 'Save';

  @override
  String get dirtyFormTitle => 'Discard changes?';

  @override
  String get dirtyFormMessage =>
      'You have unsaved changes. Are you sure you want to discard them and leave?';

  @override
  String get dirtyFormDiscard => 'Discard';

  @override
  String get dirtyFormKeepEditing => 'Keep Editing';

  @override
  String get settingsPaymentQr => 'PAYMENT & QR';

  @override
  String get settingsBankAccount => 'Bank Account for Tuition';

  @override
  String get settingsBankAccountSubtitle =>
      'Configure bank account details and VietQR for tuition payments';

  @override
  String get bankAccountTitle => 'BANK ACCOUNT DETAILS';

  @override
  String get bankName => 'Bank Name';

  @override
  String get bankAccountNumber => 'Account Number';

  @override
  String get bankAccountHolder => 'Account Holder Name';

  @override
  String get bankTransferTemplate => 'Transfer Content Template';

  @override
  String bankTransferTemplateHelper(Object maHocSinh, Object thang) {
    return 'Use $maHocSinh for student ID, $thang for month';
  }

  @override
  String get bankAccountSaveSuccess =>
      'Bank account details saved successfully';

  @override
  String get bankAccountValidationNumber => 'Please enter account number';

  @override
  String get bankAccountValidationHolder => 'Please enter account holder name';

  @override
  String get bankAccountValidationTemplate =>
      'Please enter transfer content template';

  @override
  String get vietQrPreviewTitle => 'VIETQR PREVIEW';

  @override
  String get vietQrPreviewSample =>
      'Sample transfer content (e.g. 500,000đ, HS001, 09/2026):';

  @override
  String get vietQrNotConfigured =>
      'Enter account number and account holder name to generate VietQR preview.';

  @override
  String get reportsTitle => 'Reports';

  @override
  String get reportsFilterTitle => 'REPORT FILTERS';

  @override
  String get reportsMode => 'View Mode';

  @override
  String get reportsModeMonth => 'By Month';

  @override
  String get reportsModeCustomRange => 'Custom Date Range';

  @override
  String get reportsSelectMonth => 'Select Report Month';

  @override
  String get reportsFromDate => 'From';

  @override
  String get reportsToDate => 'To';

  @override
  String get reportsFilterClass => 'Class';

  @override
  String get reportsFilterStudent => 'Student';

  @override
  String get reportsAllClasses => 'All Classes';

  @override
  String get reportsAllStudents => 'All Students';

  @override
  String get reportsApplyFilter => 'Apply';

  @override
  String get reportsClearFilter => 'Clear Filters';

  @override
  String get reportsFilteredClass => 'Class Filtered';

  @override
  String get reportsFilteredStudent => 'Student Filtered';

  @override
  String get reportsExportPdf => 'Export PDF Report';

  @override
  String reportsExportPdfError(Object error) {
    return 'PDF Export Error: $error';
  }

  @override
  String get reportsKpiAttendanceRate => 'Attendance Rate';

  @override
  String get reportsKpiInvoiced => 'Invoiced Tuition';

  @override
  String get reportsKpiPaid => 'Collected';

  @override
  String get reportsKpiOutstanding => 'Outstanding Debt';

  @override
  String get reportsSectionAttendance => 'A. ATTENDANCE';

  @override
  String get reportsSectionFinancial => 'B. TUITION';

  @override
  String get reportsSectionSessions => 'C. SESSIONS';

  @override
  String get reportsSectionClassBreakdown => 'D. CLASS BREAKDOWN';

  @override
  String get reportsSectionStudentBreakdown => 'STUDENT BREAKDOWN';

  @override
  String get reportsAttendanceOverallRate => 'Overall Attendance Rate';

  @override
  String get reportsAttendancePresent => 'Present';

  @override
  String get reportsAttendanceLate => 'Late';

  @override
  String get reportsAttendanceExcused => 'Excused';

  @override
  String get reportsAttendanceUnexcused => 'Unexcused';

  @override
  String get reportsFinancialInvoiced => 'Invoiced';

  @override
  String get reportsFinancialPaid => 'Collected';

  @override
  String get reportsFinancialDebt => 'Debt';

  @override
  String get reportsTotalSessions => 'Total Sessions';

  @override
  String get reportsTotalParticipations => 'Total Participations';

  @override
  String get reportsNoData =>
      'No report data available for the selected period.';

  @override
  String get enrollStudentTitle => 'ADD STUDENT TO CLASS';

  @override
  String get enrollOptionExisting => 'Select Existing Student';

  @override
  String get enrollOptionNew => 'Add New Student';

  @override
  String get enrollJoinDate => 'Join Date';

  @override
  String get enrollDiscount => 'Discount (%)';

  @override
  String get enrollPartialSuccess =>
      'Student was created but class enrollment failed.';

  @override
  String get busyTimeTitle => 'ADD STUDENT BUSY TIME';

  @override
  String get busyTimeType => 'Busy Time Type';

  @override
  String get busyTimeFrequency => 'Frequency';

  @override
  String get busyTimeWeekly => 'Weekly';

  @override
  String get busyTimeOneTime => 'One-time';

  @override
  String get busyTimeDayOfWeek => 'Day of Week';

  @override
  String get busyTimeDate => 'Specific Date';

  @override
  String get busyTimeStartTime => 'Start Time';

  @override
  String get busyTimeEndTime => 'End Time';

  @override
  String get busyTimeEffectiveFrom => 'Effective From Date';

  @override
  String get busyTimeEffectiveTo => 'Effective To Date';

  @override
  String get busyTimeDeleteConfirm =>
      'Are you sure you want to delete this busy time?';

  @override
  String get settingsTuitionPolicySection => 'TUITION POLICY';

  @override
  String get settingsTuitionPolicyTitle => 'Class Tuition Policies';

  @override
  String get settingsTuitionPolicySubtitle =>
      'Set unit price and standard monthly session count per class';

  @override
  String get creditsTitle => 'Extra Sessions & Credit';

  @override
  String get creditsHeaderStudent => 'Student';

  @override
  String get creditsHeaderClass => 'Class';

  @override
  String get creditsClosingBalance => 'End-of-Month Balance';

  @override
  String get creditsSummaryTitle => 'Standard Session Statistics';

  @override
  String get creditsMaxStandard => 'Standard Limit';

  @override
  String get creditsEligible => 'Eligible';

  @override
  String get creditsStandard => 'Standard';

  @override
  String get creditsExtra => 'Extra';

  @override
  String get creditsPotential => 'Credit Eligible';

  @override
  String get creditsRecorded => 'Recorded Credit';

  @override
  String get creditsMonthDelta => 'Monthly Delta';

  @override
  String get creditsReconcile => 'Reconcile Extra Sessions';

  @override
  String get creditsManualAdjustment => 'Manual Adjustment';

  @override
  String get creditsCandidatesTitle => 'Eligible Sessions List';

  @override
  String get creditsCandidatesEmpty =>
      'No completed official sessions for this student in this month.';

  @override
  String get creditsLedgerTitle => 'Credit Ledger History';

  @override
  String get creditsLedgerEmpty => 'No credit ledger entries found.';

  @override
  String get creditsStandardTag => 'Standard';

  @override
  String get creditsExtraTag => 'Extra';

  @override
  String get creditsEarnedTag => 'Recorded +1';

  @override
  String get creditsCanEarnTag => 'Eligible +1';

  @override
  String get assignmentTitle => 'Student Shift Assignment';

  @override
  String get assignmentBulkBtn => 'Bulk Shift Assign';

  @override
  String get assignmentAddStudent => 'Add Student';

  @override
  String assignmentStudentCount(Object count) {
    return '$count students';
  }

  @override
  String get assignmentNoStudentsInShift =>
      'No students assigned to this shift';

  @override
  String get assignmentNoSchedules =>
      'No recurring schedules set for assignment.';

  @override
  String get assignmentStatusActive => 'Active';

  @override
  String get assignmentStatusClosed => 'Ended';

  @override
  String get assignmentEditStartDate => 'Edit Start Date';

  @override
  String get assignmentChangeShift => 'Change Shift';

  @override
  String get assignmentCloseShift => 'End Assignment';

  @override
  String get assignmentCloseConfirmTitle => 'SELECT ASSIGNMENT END DATE';

  @override
  String get assignmentCloseSuccess => 'Shift assignment ended successfully';

  @override
  String get bulkAssignmentSheetTitle => 'Bulk Student Shift Assignment';

  @override
  String get bulkAssignmentSelectShift => 'Select Shift *';

  @override
  String get bulkAssignmentStartDate => 'Shift Start Date';

  @override
  String get bulkAssignmentCandidateHeader => 'Eligible Students List';

  @override
  String get bulkAssignmentSearchPlaceholder => 'Search student name...';

  @override
  String get bulkAssignmentAllAssigned =>
      'All eligible students are already assigned to this shift.';

  @override
  String bulkAssignmentSelectAll(Object count) {
    return 'Select All ($count)';
  }

  @override
  String bulkAssignmentSubmit(Object count) {
    return 'Assign Shift ($count students)';
  }

  @override
  String get bulkAssignmentProcessing => 'Processing...';

  @override
  String bulkAssignmentSuccess(Object count) {
    return 'Successfully assigned $count students';
  }

  @override
  String get bulkAssignmentPreviewTitle => 'SHIFT ASSIGNMENT PRE-CHECK RESULT';

  @override
  String bulkAssignmentPreviewReady(Object count) {
    return 'Ready to assign: $count students';
  }

  @override
  String bulkAssignmentPreviewBlocked(Object count) {
    return 'Cannot assign: $count students';
  }

  @override
  String bulkAssignmentPreviewWarnings(Object count) {
    return 'Low priority warnings: $count students';
  }

  @override
  String bulkAssignmentPreviewConfirmBtn(Object count) {
    return 'Assign $count valid students';
  }

  @override
  String get editStartDateTitle => 'Edit Shift Start Date';

  @override
  String get editStartDateNew => 'New Shift Start Date';

  @override
  String get editStartDateSuccess => 'Shift start date updated successfully';

  @override
  String get changeShiftTitle => 'Change Recurring Shift';

  @override
  String get changeShiftSelectNew => 'Select New Shift';

  @override
  String get changeShiftEffectiveDate => 'Effective Date for New Shift';

  @override
  String get changeShiftSuccess => 'Shift changed successfully';

  @override
  String get changeShiftValidationSelect => 'Please select a new shift';

  @override
  String get weekdayMonday => 'Monday';

  @override
  String get weekdayTuesday => 'Tuesday';

  @override
  String get weekdayWednesday => 'Wednesday';

  @override
  String get weekdayThursday => 'Thursday';

  @override
  String get weekdayFriday => 'Friday';

  @override
  String get weekdaySaturday => 'Saturday';

  @override
  String get weekdaySunday => 'Sunday';

  @override
  String get attendanceTitle => 'Session Attendance';

  @override
  String get attendanceMarkAllPresent => 'Mark All Present';

  @override
  String get attendanceMarkAllMakeup => 'Mark All Makeup';

  @override
  String get attendanceUndo => 'Undo';

  @override
  String get attendanceDraftSave => 'Save Draft';

  @override
  String get attendanceFinalizeSession => 'Finalize Session';

  @override
  String get attendanceChangeShift => 'Shift Change';

  @override
  String get attendanceScheduleMakeup => 'Schedule Makeup';

  @override
  String get attendanceCancelAdjustment => 'Cancel Adjustment';

  @override
  String get attendanceAddStudent => 'Add Student';

  @override
  String get attendancePresent => 'Present';

  @override
  String get attendanceLate => 'Late';

  @override
  String get attendanceExcused => 'Excused';

  @override
  String get attendanceUnexcused => 'Unexcused';

  @override
  String get attendanceNotMarked => 'Not Marked';

  @override
  String get tuitionKpiPreview => 'Estimated';

  @override
  String get tuitionKpiFinalized => 'Finalized';

  @override
  String get tuitionKpiPaid => 'Collected';

  @override
  String get tuitionKpiDebt => 'Outstanding Debt';

  @override
  String get tuitionFinalizeMonth => 'Finalize Monthly Tuition';

  @override
  String get tuitionRecalculate => 'Recalculate Tuition';

  @override
  String get tuitionPaymentHistory => 'Payment History';

  @override
  String get tuitionPaymentAction => 'Record Payment';

  @override
  String get tuitionQrAction => 'QR Code';

  @override
  String get tuitionPendingAttendance => 'Insufficient attendance data';

  @override
  String get tuitionWaitingCompletion => 'Awaiting session completion';

  @override
  String get tuitionFinalizeFirstNotice =>
      'Finalize tuition before collecting payments.';

  @override
  String get tuitionMonthlyCap => 'Monthly Tuition Cap';

  @override
  String get tuitionEffectiveFrom => 'Effective From Date';

  @override
  String get paymentHistoryTitle => 'Payment History';

  @override
  String get paymentEditTitle => 'Edit Payment';

  @override
  String get paymentRecordTitle => 'Record Payment';

  @override
  String get paymentEditReason => 'Correction Reason';

  @override
  String get paymentEditReasonValidation => 'Please enter a correction reason';

  @override
  String get paymentEditSuccess => 'Payment updated successfully';

  @override
  String get studentDetailTitle => 'Student Detail';

  @override
  String get studentStatusActive => 'Active';

  @override
  String get studentStatusStopped => 'Stopped';

  @override
  String studentJoinedFrom(Object date) {
    return 'Joined: $date';
  }

  @override
  String studentActiveClassesCount(Object count) {
    return '$count active classes';
  }

  @override
  String studentOutstandingDebt(Object amount) {
    return 'Outstanding debt: $amount';
  }

  @override
  String get studentEditProfile => 'Edit Profile';

  @override
  String get studentAddToClass => 'Add to Class';

  @override
  String get studentBusyTime => 'Busy Time';

  @override
  String get studentRecordPayment => 'Record Payment';

  @override
  String get studentActiveClasses => 'Active Classes';

  @override
  String studentTuitionMonth(Object month) {
    return 'Tuition $month';
  }

  @override
  String get studentFinalizedDue => 'Finalized';

  @override
  String get studentPaid => 'Collected';

  @override
  String get studentDebt => 'Outstanding';

  @override
  String get studentTuitionPartiallyPaid => 'Partially Paid';

  @override
  String get studentTuitionPaid => 'Paid';

  @override
  String get studentTuitionUnpaid => 'Unpaid';

  @override
  String get studentTuitionPendingFinalization => 'Pending Finalization';

  @override
  String get studentLatestPayment => 'Latest Payment';

  @override
  String get studentNoPayment => 'No payments this month';

  @override
  String get studentRecentAttendance => 'Recent Attendance';

  @override
  String get studentSeeAll => 'See All';

  @override
  String get studentBusyTimes => 'Busy Times';

  @override
  String get studentNoActiveClasses => 'No active classes';

  @override
  String get studentNoDebtToRecord => 'No finalized unpaid tuition invoices.';

  @override
  String get studentSelectTuitionInvoice => 'Select Tuition Invoice';

  @override
  String get classKpiActive => 'Active Classes';

  @override
  String get classKpiTodaySessions => 'Today Sessions';

  @override
  String get classKpiPendingAttendance => 'Needs Attendance';

  @override
  String get classKpiMissingTuition => 'No Fee Config';

  @override
  String get classListTitle => 'Class List';

  @override
  String classCountActive(Object count) {
    return '$count active classes';
  }

  @override
  String classCountStopped(Object count) {
    return '$count stopped classes';
  }

  @override
  String get classStatusNeedsAttendance => 'Needs Attendance';

  @override
  String get classStatusInProgress => 'In Progress';

  @override
  String get classStatusUpcoming => 'Upcoming';

  @override
  String get classStatusCompleted => 'Completed';

  @override
  String get classStatusMissingTuition => 'No Fee Config';

  @override
  String get classStatusDebt => 'Has Debt';

  @override
  String get classNeedsAction => 'Requires Attention';

  @override
  String get classSeeAll => 'See All';

  @override
  String classWarningMissingTuition(Object count) {
    return '$count classes missing tuition policy';
  }

  @override
  String classWarningOverdueAttendance(Object count) {
    return '$count overdue sessions need attendance';
  }

  @override
  String classWarningMissingSessions(Object count) {
    return '$count classes missing sessions this week';
  }

  @override
  String classStudentCount(Object count) {
    return '$count students';
  }

  @override
  String classMultipleShifts(Object count) {
    return '$count active shifts';
  }

  @override
  String get classEmptyActiveTitle => 'No active classes.';

  @override
  String get classEmptyStoppedTitle => 'No stopped classes.';
}
