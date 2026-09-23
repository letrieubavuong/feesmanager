enum ConstraintType {
  HARD_BLOCK,
  SOFT_PREFERENCE,
  OTHER_CENTER;

  String get dbValue => name;

  String get displayName => switch (this) {
    ConstraintType.HARD_BLOCK => 'Không thể học',
    ConstraintType.SOFT_PREFERENCE => 'Không ưu tiên',
    ConstraintType.OTHER_CENTER => 'Học ở trung tâm khác',
  };

  static ConstraintType parse(String value) {
    return ConstraintType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => throw ArgumentError('ConstraintType không hợp lệ: $value'),
    );
  }
}

enum OccurrenceType {
  DINH_KY,
  MOT_LAN;

  String get dbValue => name;

  String get displayName => switch (this) {
    OccurrenceType.DINH_KY => 'Định kỳ hàng tuần',
    OccurrenceType.MOT_LAN => 'Một lần',
  };

  static OccurrenceType parse(String value) {
    return OccurrenceType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => throw ArgumentError('OccurrenceType không hợp lệ: $value'),
    );
  }
}

enum ConstraintStatus {
  HOAT_DONG,
  DA_HUY;

  String get dbValue => name;

  String get displayName => switch (this) {
    ConstraintStatus.HOAT_DONG => 'Hoạt động',
    ConstraintStatus.DA_HUY => 'Đã hủy',
  };

  static ConstraintStatus parse(String value) {
    return ConstraintStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () =>
          throw ArgumentError('ConstraintStatus không hợp lệ: $value'),
    );
  }
}

class ScheduleConstraint {
  final int? id;
  final int studentId;
  final ConstraintType type;
  final OccurrenceType occurrenceType;
  final int? weekday; // 1 (Mon) - 7 (Sun) for DINH_KY
  final String? specificDate; // YYYY-MM-DD for MOT_LAN
  final String startTime; // HH:mm
  final String endTime; // HH:mm
  final String? effectiveFrom; // YYYY-MM-DD for DINH_KY
  final String? effectiveTo; // YYYY-MM-DD for DINH_KY optional
  final int travelBufferMinutes; // default 0, used for OTHER_CENTER
  final String? sourceName; // e.g. "Trung tâm A"
  final String? note;
  final ConstraintStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  ScheduleConstraint({
    this.id,
    required this.studentId,
    required this.type,
    required this.occurrenceType,
    this.weekday,
    this.specificDate,
    required this.startTime,
    required this.endTime,
    this.effectiveFrom,
    this.effectiveTo,
    this.travelBufferMinutes = 0,
    this.sourceName,
    this.note,
    this.status = ConstraintStatus.HOAT_DONG,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now() {
    _validate();
  }

  void _validate() {
    if (startTime.compareTo(endTime) >= 0) {
      throw ArgumentError(
        'Giờ kết thúc ($endTime) phải sau giờ bắt đầu ($startTime)',
      );
    }
    if (travelBufferMinutes < 0) {
      throw ArgumentError('Thời gian di chuyển không được âm');
    }
    if (occurrenceType == OccurrenceType.DINH_KY) {
      if (weekday == null || weekday! < 1 || weekday! > 7) {
        throw ArgumentError('Ràng buộc định kỳ phải chọn thứ trong tuần (1-7)');
      }
      if (effectiveFrom == null || effectiveFrom!.trim().isEmpty) {
        throw ArgumentError(
          'Ràng buộc định kỳ phải chọn ngày bắt đầu hiệu lực',
        );
      }
      if (effectiveTo != null && effectiveFrom!.compareTo(effectiveTo!) > 0) {
        throw ArgumentError(
          'Ngày kết thúc hiệu lực không được trước ngày bắt đầu',
        );
      }
      if (specificDate != null) {
        throw ArgumentError('Ràng buộc định kỳ không dùng ngày cụ thể');
      }
    } else {
      if (specificDate == null || specificDate!.trim().isEmpty) {
        throw ArgumentError('Ràng buộc một lần phải chọn ngày cụ thể');
      }
      if (weekday != null) {
        throw ArgumentError('Ràng buộc một lần không cài đặt thứ định kỳ');
      }
    }
  }

  factory ScheduleConstraint.fromRow(Map<String, dynamic> row) {
    return ScheduleConstraint(
      id: row['id'] as int?,
      studentId: row['id_hoc_sinh'] as int,
      type: ConstraintType.parse(row['loai'] as String),
      occurrenceType: OccurrenceType.parse(row['kieu'] as String),
      weekday: row['thu_trong_tuan'] as int?,
      specificDate: row['ngay_cu_the'] as String?,
      startTime: row['gio_bat_dau'] as String,
      endTime: row['gio_ket_thuc'] as String,
      effectiveFrom: row['hieu_luc_tu'] as String?,
      effectiveTo: row['hieu_luc_den'] as String?,
      travelBufferMinutes: row['travel_buffer_phut'] as int? ?? 0,
      sourceName: row['ten_nguon'] as String?,
      note: row['ghi_chu'] as String?,
      status: ConstraintStatus.parse(row['trang_thai'] as String),
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'id_hoc_sinh': studentId,
      'loai': type.dbValue,
      'kieu': occurrenceType.dbValue,
      'thu_trong_tuan': weekday,
      'ngay_cu_the': specificDate,
      'gio_bat_dau': startTime,
      'gio_ket_thuc': endTime,
      'hieu_luc_tu': effectiveFrom,
      'hieu_luc_den': effectiveTo,
      'travel_buffer_phut': travelBufferMinutes,
      'ten_nguon': sourceName,
      'ghi_chu': note,
      'trang_thai': status.dbValue,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  ScheduleConstraint copyWith({
    int? id,
    int? studentId,
    ConstraintType? type,
    OccurrenceType? occurrenceType,
    int? weekday,
    String? specificDate,
    String? startTime,
    String? endTime,
    String? effectiveFrom,
    String? effectiveTo,
    int? travelBufferMinutes,
    String? sourceName,
    String? note,
    ConstraintStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ScheduleConstraint(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      type: type ?? this.type,
      occurrenceType: occurrenceType ?? this.occurrenceType,
      weekday: weekday ?? this.weekday,
      specificDate: specificDate ?? this.specificDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      effectiveFrom: effectiveFrom ?? this.effectiveFrom,
      effectiveTo: effectiveTo ?? this.effectiveTo,
      travelBufferMinutes: travelBufferMinutes ?? this.travelBufferMinutes,
      sourceName: sourceName ?? this.sourceName,
      note: note ?? this.note,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
