import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../attendance/presentation/attendance_controller.dart';
import '../../classes/domain/class_service.dart';
import '../../memberships/domain/membership_service.dart';
import '../../roster/domain/roster_service.dart';
import '../../sessions/domain/class_session.dart';
import '../../sessions/domain/session_service.dart';
import '../../students/domain/student_service.dart';
import 'session_adjustment_controller.dart';

class SessionAdjustmentDialogs {
  static Future<void> showDoiCaDialog(
    BuildContext context,
    WidgetRef ref, {
    required int studentId,
    required int originalSessionId,
    required int classId,
    required String sessionDate,
  }) async {
    final sessionService = await ref.read(sessionServiceProvider.future);
    final rosterService = await ref.read(rosterServiceProvider.future);

    final allClassSessions = await sessionService.getSessionsForClassAndRange(
      classId,
      DateTime.parse(sessionDate),
      DateTime.parse(sessionDate),
    );

    final eligibleTargets = <ClassSession>[];
    for (final s in allClassSessions) {
      if (s.id == originalSessionId) continue;
      if (s.loai != SessionType.CHINH) continue;
      if (s.trangThai != SessionStatus.DU_KIEN) continue;

      final baseTargetRoster = await rosterService.getBaseRosterForSession(
        s.id!,
      );
      if (!baseTargetRoster.participants.any(
        (m) => m.student.id == studentId,
      )) {
        eligibleTargets.add(s);
      }
    }

    if (!context.mounted) return;

    if (eligibleTargets.isEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Đổi ca'),
          content: const Text(
            'Không có ca học chính thức nào khác trong ngày này để đổi.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Đóng'),
            ),
          ],
        ),
      );
      return;
    }

    int selectedTargetId = eligibleTargets.first.id!;
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Xếp đổi ca học'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                initialValue: selectedTargetId,
                decoration: const InputDecoration(
                  labelText: 'Chọn ca học đích',
                ),
                items: eligibleTargets.map((s) {
                  return DropdownMenuItem<int>(
                    value: s.id,
                    child: Text('${s.gioBatDau} - ${s.gioKetThuc}'),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setDialogState(() => selectedTargetId = val);
                  }
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(labelText: 'Lý do đổi ca'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await ref
                      .read(
                        sessionAdjustmentControllerProvider(
                          selectedTargetId,
                        ).notifier,
                      )
                      .createDoiCa(
                        studentId: studentId,
                        originalSessionId: originalSessionId,
                        targetSessionId: selectedTargetId,
                        reason: reasonController.text.trim(),
                      );
                  ref.invalidate(
                    attendanceControllerProvider(originalSessionId),
                  );
                  ref.invalidate(
                    attendanceControllerProvider(selectedTargetId),
                  );
                  if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                } catch (e) {
                  if (dialogCtx.mounted) {
                    showDialog(
                      context: dialogCtx,
                      builder: (c) => AlertDialog(
                        title: const Text('Lỗi'),
                        content: Text(e.toString()),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(c),
                            child: const Text('Đóng'),
                          ),
                        ],
                      ),
                    );
                  }
                }
              },
              child: const Text('Xác nhận'),
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> showXepHocBuDialog(
    BuildContext context,
    WidgetRef ref, {
    required int studentId,
    required int originalSessionId,
    required int classId,
  }) async {
    final sessionService = await ref.read(sessionServiceProvider.future);
    final classService = await ref.read(classServiceProvider.future);
    final origSession = await sessionService.getSessionById(originalSessionId);
    if (origSession == null) return;

    // Cross-class search: query upcoming HOC_BU sessions from original date
    final upcomingHocBu = await sessionService.getUpcomingHocBuSessions(
      origSession.ngay,
    );

    final eligibleTargets = <(ClassSession, String)>[];
    for (final s in upcomingHocBu) {
      if (s.id == originalSessionId) continue;
      final targetClass = await classService.getClassById(s.idLop);
      final className = targetClass?.tenLop ?? 'Lớp ${s.idLop}';
      eligibleTargets.add((s, className));
    }

    if (!context.mounted) return;

    if (eligibleTargets.isEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Xếp học bù'),
          content: const Text(
            'Chưa có buổi học bù dự kiến nào trong thời gian tới. Vui lòng tạo buổi học bù trước.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Đóng'),
            ),
          ],
        ),
      );
      return;
    }

    int selectedTargetId = eligibleTargets.first.$1.id!;
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Xếp học bù'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                initialValue: selectedTargetId,
                decoration: const InputDecoration(
                  labelText: 'Chọn buổi học bù',
                ),
                items: eligibleTargets.map((pair) {
                  final s = pair.$1;
                  final className = pair.$2;
                  return DropdownMenuItem<int>(
                    value: s.id,
                    child: Text(
                      '$className - ${s.ngay} (${s.gioBatDau} - ${s.gioKetThuc})',
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setDialogState(() => selectedTargetId = val);
                  }
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(labelText: 'Ghi chú / Lý do'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await ref
                      .read(
                        sessionAdjustmentControllerProvider(
                          selectedTargetId,
                        ).notifier,
                      )
                      .createHocBu(
                        studentId: studentId,
                        originalSessionId: originalSessionId,
                        targetSessionId: selectedTargetId,
                        reason: reasonController.text.trim(),
                      );
                  ref.invalidate(
                    attendanceControllerProvider(originalSessionId),
                  );
                  ref.invalidate(
                    attendanceControllerProvider(selectedTargetId),
                  );
                  if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                } catch (e) {
                  if (dialogCtx.mounted) {
                    showDialog(
                      context: dialogCtx,
                      builder: (c) => AlertDialog(
                        title: const Text('Lỗi'),
                        content: Text(e.toString()),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(c),
                            child: const Text('Đóng'),
                          ),
                        ],
                      ),
                    );
                  }
                }
              },
              child: const Text('Xác nhận'),
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> showThemPhatSinhDialog(
    BuildContext context,
    WidgetRef ref, {
    required int targetSessionId,
    required int classId,
  }) async {
    final membershipService = await ref.read(membershipServiceProvider.future);
    final studentService = await ref.read(studentServiceProvider.future);
    final sessionService = await ref.read(sessionServiceProvider.future);
    final classService = await ref.read(classServiceProvider.future);

    final targetSession = await sessionService.getSessionById(targetSessionId);
    if (targetSession == null) return;

    final targetDate = DateTime.parse(targetSession.ngay);

    final allStudents = await studentService.getStudents();
    final studentClassOptions =
        <
          ({int studentId, String studentName, int classId, String className})
        >[];

    for (final s in allStudents) {
      final activeMemberships = await membershipService
          .getActiveMembershipsForStudent(s.id!, date: targetDate);
      for (final m in activeMemberships) {
        final cls = await classService.getClassById(m.idLop);
        if (cls != null) {
          studentClassOptions.add((
            studentId: s.id!,
            studentName: s.hoTen,
            classId: cls.id!,
            className: cls.tenLop,
          ));
        }
      }
    }

    if (!context.mounted) return;

    if (studentClassOptions.isEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Thêm học sinh phát sinh'),
          content: const Text(
            'Không tìm thấy học sinh nào có quá trình học hợp lệ vào ngày này.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Đóng'),
            ),
          ],
        ),
      );
      return;
    }

    int selectedOptionIndex = 0;
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Thêm học sinh tham gia buổi phát sinh'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                initialValue: selectedOptionIndex,
                decoration: const InputDecoration(
                  labelText: 'Chọn học sinh và lớp gốc',
                ),
                items: List.generate(studentClassOptions.length, (idx) {
                  final opt = studentClassOptions[idx];
                  return DropdownMenuItem<int>(
                    value: idx,
                    child: Text('${opt.studentName} (${opt.className})'),
                  );
                }),
                onChanged: (val) {
                  if (val != null) {
                    setDialogState(() => selectedOptionIndex = val);
                  }
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Lý do tham gia phát sinh',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  final selectedOpt = studentClassOptions[selectedOptionIndex];
                  await ref
                      .read(
                        sessionAdjustmentControllerProvider(
                          targetSessionId,
                        ).notifier,
                      )
                      .createPhatSinh(
                        studentId: selectedOpt.studentId,
                        originalClassId: selectedOpt.classId,
                        targetSessionId: targetSessionId,
                        reason: reasonController.text.trim(),
                      );
                  ref.invalidate(attendanceControllerProvider(targetSessionId));
                  if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                } catch (e) {
                  if (dialogCtx.mounted) {
                    showDialog(
                      context: dialogCtx,
                      builder: (c) => AlertDialog(
                        title: const Text('Lỗi'),
                        content: Text(e.toString()),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(c),
                            child: const Text('Đóng'),
                          ),
                        ],
                      ),
                    );
                  }
                }
              },
              child: const Text('Thêm học sinh'),
            ),
          ],
        ),
      ),
    );
  }
}
