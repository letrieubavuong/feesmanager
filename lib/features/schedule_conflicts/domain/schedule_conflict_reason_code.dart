// ignore_for_file: constant_identifier_names

enum ScheduleConflictReasonCode {
  EXACT_OVERLAP,
  PARTIAL_OVERLAP,
  CONTAINED_OVERLAP,
  HARD_BLOCK,
  SOFT_PREFERENCE,
  OTHER_CENTER_CLASS,
  TRAVEL_BUFFER,
  ONE_OFF_SESSION_CONFLICT;

  String get displayName => switch (this) {
    ScheduleConflictReasonCode.EXACT_OVERLAP => 'Trùng khớp hoàn toàn giờ học',
    ScheduleConflictReasonCode.PARTIAL_OVERLAP => 'Trùng một phần giờ học',
    ScheduleConflictReasonCode.CONTAINED_OVERLAP => 'Bao hàm giờ học khác',
    ScheduleConflictReasonCode.HARD_BLOCK => 'Ràng buộc giờ bận tuyệt đối',
    ScheduleConflictReasonCode.SOFT_PREFERENCE => 'Khung giờ không ưu tiên',
    ScheduleConflictReasonCode.OTHER_CENTER_CLASS =>
      'Trùng lịch trung tâm khác',
    ScheduleConflictReasonCode.TRAVEL_BUFFER =>
      'Thiếu thời gian di chuyển giữa hai địa điểm',
    ScheduleConflictReasonCode.ONE_OFF_SESSION_CONFLICT =>
      'Trùng lịch buổi học đã xếp trong ngày',
  };
}
