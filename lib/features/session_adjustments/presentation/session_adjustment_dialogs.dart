import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

    // Eligible targets: CHINH, DU_KIEN, targetId != originalSessionId, student NOT in target base roster
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
                  if (val != null) setDialogState(() => selectedTargetId = val);
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
    final origSession = await sessionService.getSessionById(originalSessionId);
    if (origSession == null) return;

    final fromDate = DateTime.parse(origSession.ngay);
    final toDate = fromDate.add(const Duration(days: 90));

    final classSessions = await sessionService.getSessionsForClassAndRange(
      classId,
      fromDate,
      toDate,
    );

    // Eligible target HOC_BU sessions: loai == HOC_BU, trangThai == DU_KIEN, ngay >= origSession.ngay
    final eligibleTargets = classSessions
        .where(
          (s) =>
              s.id != originalSessionId &&
              s.loai == SessionType.HOC_BU &&
              s.trangThai == SessionStatus.DU_KIEN &&
              s.ngay.compareTo(origSession.ngay) >= 0,
        )
        .toList();

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

    int selectedTargetId = eligibleTargets.first.id!;
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
                items: eligibleTargets.map((s) {
                  return DropdownMenuItem<int>(
                    value: s.id,
                    child: Text('${s.ngay} (${s.gioBatDau} - ${s.gioKetThuc})'),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setDialogState(() => selectedTargetId = val);
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

    final targetSession = await sessionService.getSessionById(targetSessionId);
    if (targetSession == null) return;

    final targetDate = DateTime.parse(targetSession.ngay);

    final activeStudentIds = await membershipService.getActiveStudentIdsInClass(
      classId,
      targetDate,
    );

    final allStudents = await studentService.getStudents();
    final classStudents = allStudents
        .where((s) => activeStudentIds.contains(s.id))
        .toList();

    if (!context.mounted) return;

    if (classStudents.isEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Thêm học sinh phát sinh'),
          content: const Text(
            'Lớp học không có học sinh nào đang tham gia vào ngày này.',
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

    int selectedStudentId = classStudents.first.id!;
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
                initialValue: selectedStudentId,
                decoration: const InputDecoration(labelText: 'Chọn học sinh'),
                items: classStudents.map((s) {
                  return DropdownMenuItem<int>(
                    value: s.id,
                    child: Text(s.hoTen),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null)
                    setDialogState(() => selectedStudentId = val);
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
                  await ref
                      .read(
                        sessionAdjustmentControllerProvider(
                          targetSessionId,
                        ).notifier,
                      )
                      .createPhatSinh(
                        studentId: selectedStudentId,
                        originalClassId: classId,
                        targetSessionId: targetSessionId,
                        reason: reasonController.text.trim(),
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
              child: const Text('Thêm học sinh'),
            ),
          ],
        ),
      ),
    );
  }
}
