import 'package:flutter_test/flutter_test.dart';
import 'package:tuition2027/features/attendance/domain/attendance_record.dart';
import 'package:tuition2027/features/classes/domain/class.dart';
import 'package:tuition2027/features/memberships/domain/membership.dart';
import 'package:tuition2027/features/sessions/domain/class_session.dart';
import 'package:tuition2027/features/students/domain/student.dart';
import 'package:tuition2027/features/students/domain/student_detail_overview.dart';

void main() {
  final now = DateTime.now();

  group('StudentDetailOverview Read Model Unit Tests', () {
    test(
      'StudentDetailOverview holds student, active classes & financial metrics',
      () {
        final student = Student(
          id: 1,
          hoTen: 'Bùi Gia An',
          sdtPhuHuynh: '0962345678',
          gioiTinh: 'NAM',
          createdAt: now,
          updatedAt: now,
        );

        final classEntity = ClassEntity(
          id: 10,
          tenLop: 'Lớp 11A1',
          daLuuTru: false,
          createdAt: now,
          updatedAt: now,
        );

        final membership = ClassMembership(
          id: 100,
          idHocSinh: 1,
          idLop: 10,
          tuNgay: '2026-09-08',
          createdAt: now,
          updatedAt: now,
        );

        final activeSummary = StudentActiveClassSummary(
          classEntity: classEntity,
          membership: membership,
          shiftText: '17:30–19:00 • Thứ 3,5',
        );

        const financial = StudentMonthFinancialSummary(
          month: '2026-09',
          finalizedDue: 2350000,
          totalPaid: 1900000,
          remainingDebt: 450000,
          finalizedInvoiceCount: 1,
          unfinalizedClassCount: 0,
          previewUnfinalizedAmount: 0,
          state: StudentFinancialDisplayState.partiallyPaid,
        );

        final overview = StudentDetailOverview(
          student: student,
          activeClasses: [activeSummary],
          firstActiveMembershipDate: DateTime(2026, 9, 8),
          financial: financial,
          recentAttendance: [],
          activeBusyTimes: [],
        );

        expect(overview.student.hoTen, 'Bùi Gia An');
        expect(overview.activeClasses.length, 1);
        expect(overview.firstActiveMembershipDate, DateTime(2026, 9, 8));
        expect(overview.financial.finalizedDue, 2350000);
        expect(overview.financial.totalPaid, 1900000);
        expect(overview.financial.remainingDebt, 450000);
        expect(
          overview.financial.state,
          StudentFinancialDisplayState.partiallyPaid,
        );
      },
    );

    test(
      'StudentRecentAttendanceItem connects attendance, session & class',
      () {
        final classEntity = ClassEntity(
          id: 10,
          tenLop: 'Lớp 11A1',
          createdAt: now,
          updatedAt: now,
        );

        final session = ClassSession(
          id: 50,
          idLop: 10,
          ngay: '2026-09-28',
          gioBatDau: '17:30',
          gioKetThuc: '19:00',
          loai: SessionType.CHINH,
          trangThai: SessionStatus.DA_HOC,
          createdAt: now,
          updatedAt: now,
        );

        final attendance = AttendanceRecord(
          id: 500,
          idBuoiHoc: 50,
          idHocSinh: 1,
          idLopGoc: 10,
          trangThai: AttendanceStatus.CO_MAT,
          createdAt: now,
          updatedAt: now,
        );

        final item = StudentRecentAttendanceItem(
          attendance: attendance,
          session: session,
          classEntity: classEntity,
        );

        expect(item.attendance.trangThai, AttendanceStatus.CO_MAT);
        expect(item.session.gioBatDau, '17:30');
        expect(item.classEntity.tenLop, 'Lớp 11A1');
      },
    );
  });
}
