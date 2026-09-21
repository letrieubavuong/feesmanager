enum ClassFilter {
  active,
  archived,
  all;

  String get label {
    switch (this) {
      case ClassFilter.active:
        return 'Đang hoạt động';
      case ClassFilter.archived:
        return 'Đã lưu trữ';
      case ClassFilter.all:
        return 'Tất cả';
    }
  }
}
