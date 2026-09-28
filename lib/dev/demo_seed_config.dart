// lib/dev/demo_seed_config.dart

const String demoSeedMarker = '[DEV-SEED-20260928-V1]';

class DemoClassSpec {
  final String tenLop;
  final int khoi;
  final String monHoc;
  final int siSoToiDa;

  const DemoClassSpec({
    required this.tenLop,
    required this.khoi,
    required this.monHoc,
    this.siSoToiDa = 30,
  });
}

class DemoScheduleSpec {
  final String tenLop;
  final int thuTrongTuan; // 1 = Mon, 2 = Tue, ..., 7 = Sun
  final String gioBatDau;
  final String gioKetThuc;

  const DemoScheduleSpec({
    required this.tenLop,
    required this.thuTrongTuan,
    required this.gioBatDau,
    required this.gioKetThuc,
  });
}

class DemoStudentSpec {
  final String hoTen;
  final String gioiTinh; // 'NAM' or 'NU'
  final int birthYear;
  final String sdtPhuHuynh;
  final String truongDangHoc;

  const DemoStudentSpec({
    required this.hoTen,
    required this.gioiTinh,
    required this.birthYear,
    required this.sdtPhuHuynh,
    required this.truongDangHoc,
  });
}

class DemoTuitionPolicySpec {
  final String tenLop;
  final int feePerSession;
  final int standardSessionsPerMonth;

  const DemoTuitionPolicySpec({
    required this.tenLop,
    required this.feePerSession,
    this.standardSessionsPerMonth = 12,
  });
}

class DemoSeedConfig {
  static const String startDate = '2026-07-02';
  static const String referenceDate = '2026-09-28';
  static const String leaveDateForStopped = '2026-08-31';

  static const List<DemoClassSpec> classes = [
    DemoClassSpec(tenLop: 'Toán 6', khoi: 6, monHoc: 'Toán'),
    DemoClassSpec(tenLop: 'Toán 9', khoi: 9, monHoc: 'Toán'),
    DemoClassSpec(tenLop: 'KHTN 8', khoi: 8, monHoc: 'Khoa học tự nhiên'),
    DemoClassSpec(tenLop: 'KHTN 9', khoi: 9, monHoc: 'Khoa học tự nhiên'),
    DemoClassSpec(tenLop: 'Vật lí 12', khoi: 12, monHoc: 'Vật lí'),
  ];

  static const List<DemoScheduleSpec> schedules = [
    // Toán 6: Mon, Thu 08:00 - 09:30
    DemoScheduleSpec(
      tenLop: 'Toán 6',
      thuTrongTuan: 1,
      gioBatDau: '08:00',
      gioKetThuc: '09:30',
    ),
    DemoScheduleSpec(
      tenLop: 'Toán 6',
      thuTrongTuan: 4,
      gioBatDau: '08:00',
      gioKetThuc: '09:30',
    ),

    // Toán 9: Mon, Wed, Fri 17:30 - 19:00
    DemoScheduleSpec(
      tenLop: 'Toán 9',
      thuTrongTuan: 1,
      gioBatDau: '17:30',
      gioKetThuc: '19:00',
    ),
    DemoScheduleSpec(
      tenLop: 'Toán 9',
      thuTrongTuan: 3,
      gioBatDau: '17:30',
      gioKetThuc: '19:00',
    ),
    DemoScheduleSpec(
      tenLop: 'Toán 9',
      thuTrongTuan: 5,
      gioBatDau: '17:30',
      gioKetThuc: '19:00',
    ),

    // KHTN 8: Mon, Sat 10:00 - 11:30
    DemoScheduleSpec(
      tenLop: 'KHTN 8',
      thuTrongTuan: 1,
      gioBatDau: '10:00',
      gioKetThuc: '11:30',
    ),
    DemoScheduleSpec(
      tenLop: 'KHTN 8',
      thuTrongTuan: 6,
      gioBatDau: '10:00',
      gioKetThuc: '11:30',
    ),

    // KHTN 9: Mon, Thu 19:15 - 20:45
    DemoScheduleSpec(
      tenLop: 'KHTN 9',
      thuTrongTuan: 1,
      gioBatDau: '19:15',
      gioKetThuc: '20:45',
    ),
    DemoScheduleSpec(
      tenLop: 'KHTN 9',
      thuTrongTuan: 4,
      gioBatDau: '19:15',
      gioKetThuc: '20:45',
    ),

    // Vật lí 12: Wed, Sun 14:00 - 15:30
    DemoScheduleSpec(
      tenLop: 'Vật lí 12',
      thuTrongTuan: 3,
      gioBatDau: '14:00',
      gioKetThuc: '15:30',
    ),
    DemoScheduleSpec(
      tenLop: 'Vật lí 12',
      thuTrongTuan: 7,
      gioBatDau: '14:00',
      gioKetThuc: '15:30',
    ),
  ];

  static const List<DemoTuitionPolicySpec> policies = [
    DemoTuitionPolicySpec(tenLop: 'Toán 6', feePerSession: 50000),
    DemoTuitionPolicySpec(tenLop: 'Toán 9', feePerSession: 60000),
    DemoTuitionPolicySpec(tenLop: 'KHTN 8', feePerSession: 55000),
    DemoTuitionPolicySpec(tenLop: 'KHTN 9', feePerSession: 60000),
    DemoTuitionPolicySpec(tenLop: 'Vật lí 12', feePerSession: 70000),
  ];

  static final List<DemoStudentSpec> students = [
    // --- GROUP A: 18 Grade 6 (Toán 6) ---
    const DemoStudentSpec(
      hoTen: 'Nguyễn Văn An',
      gioiTinh: 'NAM',
      birthYear: 2014,
      sdtPhuHuynh: '0907000001',
      truongDangHoc: 'THCS Nguyễn Du',
    ),
    const DemoStudentSpec(
      hoTen: 'Trần Đức Anh',
      gioiTinh: 'NAM',
      birthYear: 2014,
      sdtPhuHuynh: '0907000002',
      truongDangHoc: 'THCS Lê Lợi',
    ),
    const DemoStudentSpec(
      hoTen: 'Lê Hoàng Bách',
      gioiTinh: 'NAM',
      birthYear: 2014,
      sdtPhuHuynh: '0907000003',
      truongDangHoc: 'THCS Nguyễn Du',
    ),
    const DemoStudentSpec(
      hoTen: 'Phạm Quốc Bảo',
      gioiTinh: 'NAM',
      birthYear: 2014,
      sdtPhuHuynh: '0907000004',
      truongDangHoc: 'THCS Chu Văn An',
    ),
    const DemoStudentSpec(
      hoTen: 'Hoàng Gia Bình',
      gioiTinh: 'NAM',
      birthYear: 2014,
      sdtPhuHuynh: '0907000005',
      truongDangHoc: 'THCS Trấn Quốc Toản',
    ),
    const DemoStudentSpec(
      hoTen: 'Vũ Minh Cường',
      gioiTinh: 'NAM',
      birthYear: 2014,
      sdtPhuHuynh: '0907000006',
      truongDangHoc: 'THCS Trầm Trọng Kim',
    ),
    const DemoStudentSpec(
      hoTen: 'Đặng Tiến Dũng',
      gioiTinh: 'NAM',
      birthYear: 2014,
      sdtPhuHuynh: '0907000007',
      truongDangHoc: 'THCS Nguyễn Du',
    ),
    const DemoStudentSpec(
      hoTen: 'Bùi Hoàng Dương',
      gioiTinh: 'NAM',
      birthYear: 2014,
      sdtPhuHuynh: '0907000008',
      truongDangHoc: 'THCS Lê Lợi',
    ),
    const DemoStudentSpec(
      hoTen: 'Đỗ Minh Đức',
      gioiTinh: 'NAM',
      birthYear: 2014,
      sdtPhuHuynh: '0907000009',
      truongDangHoc: 'THCS Trần Đại Nghĩa',
    ),
    const DemoStudentSpec(
      hoTen: 'Hồ Hải Đăng',
      gioiTinh: 'NAM',
      birthYear: 2014,
      sdtPhuHuynh: '0907000010',
      truongDangHoc: 'THCS Chu Văn An',
    ),
    const DemoStudentSpec(
      hoTen: 'Nguyễn Thị An',
      gioiTinh: 'NU',
      birthYear: 2014,
      sdtPhuHuynh: '0907000011',
      truongDangHoc: 'THCS Nguyễn Du',
    ),
    const DemoStudentSpec(
      hoTen: 'Trần Bảo Anh',
      gioiTinh: 'NU',
      birthYear: 2014,
      sdtPhuHuynh: '0907000012',
      truongDangHoc: 'THCS Lê Lợi',
    ),
    const DemoStudentSpec(
      hoTen: 'Lê Trâm Anh',
      gioiTinh: 'NU',
      birthYear: 2014,
      sdtPhuHuynh: '0907000013',
      truongDangHoc: 'THCS Nguyễn Trãi',
    ),
    const DemoStudentSpec(
      hoTen: 'Phạm Ngọc Ánh',
      gioiTinh: 'NU',
      birthYear: 2014,
      sdtPhuHuynh: '0907000014',
      truongDangHoc: 'THCS Chu Văn An',
    ),
    const DemoStudentSpec(
      hoTen: 'Hoàng Thùy Linh',
      gioiTinh: 'NU',
      birthYear: 2014,
      sdtPhuHuynh: '0907000015',
      truongDangHoc: 'THCS Trân Quốc Toản',
    ),
    const DemoStudentSpec(
      hoTen: 'Vũ Châu Anh',
      gioiTinh: 'NU',
      birthYear: 2014,
      sdtPhuHuynh: '0907000016',
      truongDangHoc: 'THCS Lê Lợi',
    ),
    const DemoStudentSpec(
      hoTen: 'Đặng Linh Chi',
      gioiTinh: 'NU',
      birthYear: 2014,
      sdtPhuHuynh: '0907000017',
      truongDangHoc: 'THCS Nguyễn Du',
    ),
    const DemoStudentSpec(
      hoTen: 'Bùi Khánh Dung',
      gioiTinh: 'NU',
      birthYear: 2014,
      sdtPhuHuynh: '0907000018',
      truongDangHoc: 'THCS Trần Đại Nghĩa',
    ),

    // --- GROUP B: 18 Grade 8 (KHTN 8) ---
    const DemoStudentSpec(
      hoTen: 'Ngô Việt Hà',
      gioiTinh: 'NAM',
      birthYear: 2012,
      sdtPhuHuynh: '0907000019',
      truongDangHoc: 'THCS Nguyễn Du',
    ),
    const DemoStudentSpec(
      hoTen: 'Dương Gia Hưng',
      gioiTinh: 'NAM',
      birthYear: 2012,
      sdtPhuHuynh: '0907000020',
      truongDangHoc: 'THCS Lê Lợi',
    ),
    const DemoStudentSpec(
      hoTen: 'Lý Bảo Huy',
      gioiTinh: 'NAM',
      birthYear: 2012,
      sdtPhuHuynh: '0907000021',
      truongDangHoc: 'THCS Chu Văn An',
    ),
    const DemoStudentSpec(
      hoTen: 'Huỳnh Minh Khoa',
      gioiTinh: 'NAM',
      birthYear: 2012,
      sdtPhuHuynh: '0907000022',
      truongDangHoc: 'THCS Nguyễn Du',
    ),
    const DemoStudentSpec(
      hoTen: 'Phan Đăng Khoi',
      gioiTinh: 'NAM',
      birthYear: 2012,
      sdtPhuHuynh: '0907000023',
      truongDangHoc: 'THCS Lê Quý Đôn',
    ),
    const DemoStudentSpec(
      hoTen: 'Trịnh Nguyên Khôi',
      gioiTinh: 'NAM',
      birthYear: 2012,
      sdtPhuHuynh: '0907000024',
      truongDangHoc: 'THCS Trần Đại Nghĩa',
    ),
    const DemoStudentSpec(
      hoTen: 'Đinh Tuấn Kiệt',
      gioiTinh: 'NAM',
      birthYear: 2012,
      sdtPhuHuynh: '0907000025',
      truongDangHoc: 'THCS Lê Lợi',
    ),
    const DemoStudentSpec(
      hoTen: 'Lâm Gia Long',
      gioiTinh: 'NAM',
      birthYear: 2012,
      sdtPhuHuynh: '0907000026',
      truongDangHoc: 'THCS Nguyễn Du',
    ),
    const DemoStudentSpec(
      hoTen: 'Mai Văn Minh',
      gioiTinh: 'NAM',
      birthYear: 2012,
      sdtPhuHuynh: '0907000027',
      truongDangHoc: 'THCS Chu Văn An',
    ),
    const DemoStudentSpec(
      hoTen: 'Đỗ Ánh Dương',
      gioiTinh: 'NU',
      birthYear: 2012,
      sdtPhuHuynh: '0907000028',
      truongDangHoc: 'THCS Lê Quý Đôn',
    ),
    const DemoStudentSpec(
      hoTen: 'Hồ Thùy Dương',
      gioiTinh: 'NU',
      birthYear: 2012,
      sdtPhuHuynh: '0907000029',
      truongDangHoc: 'THCS Nguyễn Du',
    ),
    const DemoStudentSpec(
      hoTen: 'Ngô Hương Giang',
      gioiTinh: 'NU',
      birthYear: 2012,
      sdtPhuHuynh: '0907000030',
      truongDangHoc: 'THCS Lê Lợi',
    ),
    const DemoStudentSpec(
      hoTen: 'Dương Thu Hà',
      gioiTinh: 'NU',
      birthYear: 2012,
      sdtPhuHuynh: '0907000031',
      truongDangHoc: 'THCS Chu Văn An',
    ),
    const DemoStudentSpec(
      hoTen: 'Lý Ngân Hà',
      gioiTinh: 'NU',
      birthYear: 2012,
      sdtPhuHuynh: '0907000032',
      truongDangHoc: 'THCS Nguyễn Trãi',
    ),
    const DemoStudentSpec(
      hoTen: 'Huỳnh Thu Hằng',
      gioiTinh: 'NU',
      birthYear: 2012,
      sdtPhuHuynh: '0907000033',
      truongDangHoc: 'THCS Lê Quý Đôn',
    ),
    const DemoStudentSpec(
      hoTen: 'Phan Gia Hân',
      gioiTinh: 'NU',
      birthYear: 2012,
      sdtPhuHuynh: '0907000034',
      truongDangHoc: 'THCS Nguyễn Du',
    ),
    const DemoStudentSpec(
      hoTen: 'Trịnh Mỹ Hoa',
      gioiTinh: 'NU',
      birthYear: 2012,
      sdtPhuHuynh: '0907000035',
      truongDangHoc: 'THCS Trần Đại Nghĩa',
    ),
    const DemoStudentSpec(
      hoTen: 'Đinh Khánh Huyền',
      gioiTinh: 'NU',
      birthYear: 2012,
      sdtPhuHuynh: '0907000036',
      truongDangHoc: 'THCS Lê Lợi',
    ),

    // --- GROUP C: 18 Grade 12 (Vật lí 12) ---
    const DemoStudentSpec(
      hoTen: 'Trương Đức Nam',
      gioiTinh: 'NAM',
      birthYear: 2008,
      sdtPhuHuynh: '0907000037',
      truongDangHoc: 'THPT Chuyên Lê Hồng Phong',
    ),
    const DemoStudentSpec(
      hoTen: 'Nguyễn Hoàng Nam',
      gioiTinh: 'NAM',
      birthYear: 2008,
      sdtPhuHuynh: '0907000038',
      truongDangHoc: 'THPT Nguyễn Thượng Hiền',
    ),
    const DemoStudentSpec(
      hoTen: 'Trần Nhật Nam',
      gioiTinh: 'NAM',
      birthYear: 2008,
      sdtPhuHuynh: '0907000039',
      truongDangHoc: 'THPT Trần Phú',
    ),
    const DemoStudentSpec(
      hoTen: 'Lê Việt Nghĩa',
      gioiTinh: 'NAM',
      birthYear: 2008,
      sdtPhuHuynh: '0907000040',
      truongDangHoc: 'THPT Gia Định',
    ),
    const DemoStudentSpec(
      hoTen: 'Phạm Hữu Phong',
      gioiTinh: 'NAM',
      birthYear: 2008,
      sdtPhuHuynh: '0907000041',
      truongDangHoc: 'THPT Chuyên Lê Hồng Phong',
    ),
    const DemoStudentSpec(
      hoTen: 'Hoàng Gia Phú',
      gioiTinh: 'NAM',
      birthYear: 2008,
      sdtPhuHuynh: '0907000042',
      truongDangHoc: 'THPT Nguyễn Thượng Hiền',
    ),
    const DemoStudentSpec(
      hoTen: 'Vũ Minh Quân',
      gioiTinh: 'NAM',
      birthYear: 2008,
      sdtPhuHuynh: '0907000043',
      truongDangHoc: 'THPT Bùi Thị Xuân',
    ),
    const DemoStudentSpec(
      hoTen: 'Đặng Trọng Quân',
      gioiTinh: 'NAM',
      birthYear: 2008,
      sdtPhuHuynh: '0907000044',
      truongDangHoc: 'THPT Trần Phú',
    ),
    const DemoStudentSpec(
      hoTen: 'Bùi Đức Quang',
      gioiTinh: 'NAM',
      birthYear: 2008,
      sdtPhuHuynh: '0907000045',
      truongDangHoc: 'THPT Gia Định',
    ),
    const DemoStudentSpec(
      hoTen: 'Lâm Mai Hương',
      gioiTinh: 'NU',
      birthYear: 2008,
      sdtPhuHuynh: '0907000046',
      truongDangHoc: 'THPT Chuyên Lê Hồng Phong',
    ),
    const DemoStudentSpec(
      hoTen: 'Mai Ngọc Khánh',
      gioiTinh: 'NU',
      birthYear: 2008,
      sdtPhuHuynh: '0907000047',
      truongDangHoc: 'THPT Nguyễn Thượng Hiền',
    ),
    const DemoStudentSpec(
      hoTen: 'Trương Kiều Trang',
      gioiTinh: 'NU',
      birthYear: 2008,
      sdtPhuHuynh: '0907000048',
      truongDangHoc: 'THPT Bùi Thị Xuân',
    ),
    const DemoStudentSpec(
      hoTen: 'Nguyễn Phương Linh',
      gioiTinh: 'NU',
      birthYear: 2008,
      sdtPhuHuynh: '0907000049',
      truongDangHoc: 'THPT Trần Phú',
    ),
    const DemoStudentSpec(
      hoTen: 'Trần Khánh Linh',
      gioiTinh: 'NU',
      birthYear: 2008,
      sdtPhuHuynh: '0907000050',
      truongDangHoc: 'THPT Gia Định',
    ),
    const DemoStudentSpec(
      hoTen: 'Lê Thảo Linh',
      gioiTinh: 'NU',
      birthYear: 2008,
      sdtPhuHuynh: '0907000051',
      truongDangHoc: 'THPT Chuyên Lê Hồng Phong',
    ),
    const DemoStudentSpec(
      hoTen: 'Phạm Nhật Lệ',
      gioiTinh: 'NU',
      birthYear: 2008,
      sdtPhuHuynh: '0907000052',
      truongDangHoc: 'THPT Nguyễn Thượng Hiền',
    ),
    const DemoStudentSpec(
      hoTen: 'Hoàng Tuệ Mẫn',
      gioiTinh: 'NU',
      birthYear: 2008,
      sdtPhuHuynh: '0907000053',
      truongDangHoc: 'THPT Bùi Thị Xuân',
    ),
    const DemoStudentSpec(
      hoTen: 'Vũ Bảo Ngọc',
      gioiTinh: 'NU',
      birthYear: 2008,
      sdtPhuHuynh: '0907000054',
      truongDangHoc: 'THPT Trần Phú',
    ),

    // --- GROUP D: 20 Grade 9 (Shared Toán 9 & KHTN 9) ---
    const DemoStudentSpec(
      hoTen: 'Đỗ Minh Quang',
      gioiTinh: 'NAM',
      birthYear: 2011,
      sdtPhuHuynh: '0907000055',
      truongDangHoc: 'THCS Nguyễn Du',
    ),
    const DemoStudentSpec(
      hoTen: 'Hồ Thái Sơn',
      gioiTinh: 'NAM',
      birthYear: 2011,
      sdtPhuHuynh: '0907000056',
      truongDangHoc: 'THCS Lê Lợi',
    ),
    const DemoStudentSpec(
      hoTen: 'Ngô Đức Tài',
      gioiTinh: 'NAM',
      birthYear: 2011,
      sdtPhuHuynh: '0907000057',
      truongDangHoc: 'THCS Chu Văn An',
    ),
    const DemoStudentSpec(
      hoTen: 'Dương Thanh Tùng',
      gioiTinh: 'NAM',
      birthYear: 2011,
      sdtPhuHuynh: '0907000058',
      truongDangHoc: 'THCS Nguyễn Du',
    ),
    const DemoStudentSpec(
      hoTen: 'Lý Đức Thắng',
      gioiTinh: 'NAM',
      birthYear: 2011,
      sdtPhuHuynh: '0907000059',
      truongDangHoc: 'THCS Lê Quý Đôn',
    ),
    const DemoStudentSpec(
      hoTen: 'Huỳnh Anh Khôi',
      gioiTinh: 'NAM',
      birthYear: 2011,
      sdtPhuHuynh: '0907000060',
      truongDangHoc: 'THCS Trần Đại Nghĩa',
    ),
    const DemoStudentSpec(
      hoTen: 'Phan Bảo Minh',
      gioiTinh: 'NAM',
      birthYear: 2011,
      sdtPhuHuynh: '0907000061',
      truongDangHoc: 'THCS Lê Lợi',
    ),
    const DemoStudentSpec(
      hoTen: 'Trịnh Quốc Việt',
      gioiTinh: 'NAM',
      birthYear: 2011,
      sdtPhuHuynh: '0907000062',
      truongDangHoc: 'THCS Nguyễn Du',
    ),
    const DemoStudentSpec(
      hoTen: 'Đinh Hoàng Vinh',
      gioiTinh: 'NAM',
      birthYear: 2011,
      sdtPhuHuynh: '0907000063',
      truongDangHoc: 'THCS Chu Văn An',
    ),
    const DemoStudentSpec(
      hoTen: 'Lâm Quang Vũ',
      gioiTinh: 'NAM',
      birthYear: 2011,
      sdtPhuHuynh: '0907000064',
      truongDangHoc: 'THCS Lê Quý Đôn',
    ),
    const DemoStudentSpec(
      hoTen: 'Đặng Thảo Nguyên',
      gioiTinh: 'NU',
      birthYear: 2011,
      sdtPhuHuynh: '0907000065',
      truongDangHoc: 'THCS Nguyễn Du',
    ),
    const DemoStudentSpec(
      hoTen: 'Bùi Yến Nhi',
      gioiTinh: 'NU',
      birthYear: 2011,
      sdtPhuHuynh: '0907000066',
      truongDangHoc: 'THCS Lê Lợi',
    ),
    const DemoStudentSpec(
      hoTen: 'Đỗ Tố Như',
      gioiTinh: 'NU',
      birthYear: 2011,
      sdtPhuHuynh: '0907000067',
      truongDangHoc: 'THCS Chu Văn An',
    ),
    const DemoStudentSpec(
      hoTen: 'Hồ Như Quỳnh',
      gioiTinh: 'NU',
      birthYear: 2011,
      sdtPhuHuynh: '0907000068',
      truongDangHoc: 'THCS Nguyễn Trãi',
    ),
    const DemoStudentSpec(
      hoTen: 'Ngô Thu Thảo',
      gioiTinh: 'NU',
      birthYear: 2011,
      sdtPhuHuynh: '0907000069',
      truongDangHoc: 'THCS Lê Quý Đôn',
    ),
    const DemoStudentSpec(
      hoTen: 'Dương Phương Thảo',
      gioiTinh: 'NU',
      birthYear: 2011,
      sdtPhuHuynh: '0907000070',
      truongDangHoc: 'THCS Nguyễn Du',
    ),
    const DemoStudentSpec(
      hoTen: 'Lý Thanh Thảo',
      gioiTinh: 'NU',
      birthYear: 2011,
      sdtPhuHuynh: '0907000071',
      truongDangHoc: 'THCS Trần Đại Nghĩa',
    ),
    const DemoStudentSpec(
      hoTen: 'Huỳnh Minh Anh',
      gioiTinh: 'NU',
      birthYear: 2011,
      sdtPhuHuynh: '0907000072',
      truongDangHoc: 'THCS Lê Lợi',
    ),
    const DemoStudentSpec(
      hoTen: 'Phan Bảo Trang',
      gioiTinh: 'NU',
      birthYear: 2011,
      sdtPhuHuynh: '0907000073',
      truongDangHoc: 'THCS Chu Văn An',
    ),
    const DemoStudentSpec(
      hoTen: 'Trịnh Hài Yến',
      gioiTinh: 'NU',
      birthYear: 2011,
      sdtPhuHuynh: '0907000074',
      truongDangHoc: 'THCS Nguyễn Du',
    ),

    // --- GROUP E: 3 Grade 9 (Toán 9 only) ---
    const DemoStudentSpec(
      hoTen: 'Mai Hải Đăng',
      gioiTinh: 'NAM',
      birthYear: 2011,
      sdtPhuHuynh: '0907000075',
      truongDangHoc: 'THCS Lê Quý Đôn',
    ),
    const DemoStudentSpec(
      hoTen: 'Đinh Nhã Phương',
      gioiTinh: 'NU',
      birthYear: 2011,
      sdtPhuHuynh: '0907000076',
      truongDangHoc: 'THCS Nguyễn Du',
    ),
    const DemoStudentSpec(
      hoTen: 'Lâm Thảo Chi',
      gioiTinh: 'NU',
      birthYear: 2011,
      sdtPhuHuynh: '0907000077',
      truongDangHoc: 'THCS Lê Lợi',
    ),

    // --- GROUP F: 3 Grade 9 (KHTN 9 only) ---
    const DemoStudentSpec(
      hoTen: 'Trương Minh Triết',
      gioiTinh: 'NAM',
      birthYear: 2011,
      sdtPhuHuynh: '0907000078',
      truongDangHoc: 'THCS Chu Văn An',
    ),
    const DemoStudentSpec(
      hoTen: 'Mai Uyển Nhi',
      gioiTinh: 'NU',
      birthYear: 2011,
      sdtPhuHuynh: '0907000079',
      truongDangHoc: 'THCS Trần Đại Nghĩa',
    ),
    const DemoStudentSpec(
      hoTen: 'Trương Bảo Châu',
      gioiTinh: 'NU',
      birthYear: 2011,
      sdtPhuHuynh: '0907000080',
      truongDangHoc: 'THCS Lê Quý Đôn',
    ),
  ];
}
