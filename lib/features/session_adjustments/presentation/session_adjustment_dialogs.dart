import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../attendance/presentation/attendance_controller.dart';
import '../../classes/domain/class_service.dart';
import '../../memberships/domain/membership_service.dart';
import '../../schedule_conflicts/presentation/schedule_conflict_banner.dart';
import '../../schedule_conflicts/presentation/schedule_conflict_providers.dart';
import '../../sessions/domain/class_session.dart';
import '../../sessions/domain/session_service.dart';
import '../../students/domain/student_service.dart';
import '../domain/session_adjustment_service.dart';
import 'session_adjustment_controller.dart';

class SessionAdjustmentDialogs {
  static Future<void> showDoiCaDialog({
    required BuildContext context,
    required WidgetRef ref,
    required int studentId,
    required int originalSessionId,
  }) async {
    final sessionService = await ref.read(sessionServiceProvider.future);
    final origSession = await sessionService.getSessionById(originalSessionId);
    if (origSession == null) return;

    final dateSessions = await sessionService.getSessionsForClassAndRange(
      origSession.idLop,
      DateTime.parse(origSession.ngay),
      DateTime.parse(origSession.ngay),
    );

    final eligibleTargets = dateSessions
        .where(
          (s) =>
              s.id != originalSessionId &&
              s.loai == SessionType.CHINH &&
              s.trangThai == SessionStatus.DU_KIEN,
        )
        .toList();

    if (eligibleTargets.isEmpty) {
      if (!context.mounted) return;
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

    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: const Text('Xếp đổi ca học'),
            content: SingleChildScrollView(
              child: Column(
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
                    decoration: const InputDecoration(
                      labelText: 'Lý do đổi ca',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Consumer(
                    builder: (context, ref, _) {
                      final previewAsync = ref.watch(
                        oneOffSessionConflictPreviewProvider((
                          studentId,
                          selectedTargetId,
                          originalSessionId,
                        )),
                      );
                      return previewAsync.when(
                        data: (res) => ScheduleConflictBanner(result: res),
                        loading: () => const LinearProgressIndicator(),
                        error: (e, _) => Text('Lỗi kiểm tra trùng lịch: $e'),
                      );
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('Hủy'),
              ),
              Consumer(
                builder: (context, ref, _) {
                  final previewAsync = ref.watch(
                    oneOffSessionConflictPreviewProvider((
                      studentId,
                      selectedTargetId,
                      originalSessionId,
                    )),
                  );
                  final isBlocked = previewAsync.when(
                    data: (res) => !res.canAssign,
                    loading: () => true,
                    error: (_, __) => true,
                  );

                  return ElevatedButton(
                    onPressed: isBlocked
                        ? null
                        : () async {
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
                                ScaffoldMessenger.of(dialogCtx).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      e.toString().replaceAll(
                                        'Exception: ',
                                        '',
                                      ),
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                    child: const Text('Xác nhận đổi ca'),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  static Future<void> showHocBuDialog({
    required BuildContext context,
    required WidgetRef ref,
    required int studentId,
    required int originalSessionId,
  }) async {
    final sessionService = await ref.read(sessionServiceProvider.future);
    final origSession = await sessionService.getSessionById(originalSessionId);
    if (origSession == null) return;

    final today = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(today);
    final lookaheadEndStr = DateFormat(
      'yyyy-MM-dd',
    ).format(today.add(const Duration(days: 90)));

    final futureHocBuSessions = await sessionService.getUpcomingHocBuSessions(
      fromDate: todayStr,
      toDate: lookaheadEndStr,
    );

    final eligibleSessions = futureHocBuSessions
        .where(
          (s) =>
              s.loai == SessionType.HOC_BU &&
              s.trangThai == SessionStatus.DU_KIEN,
        )
        .toList();

    if (eligibleSessions.isEmpty) {
      if (!context.mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Học bù'),
          content: const Text('Hiện chưa có buổi học bù DỰ KIẾN nào được tạo.'),
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

    final classService = await ref.read(classServiceProvider.future);
    final classIds = eligibleSessions.map((s) => s.idLop).toSet().toList();
    final classes = await classService.getClassesByIds(classIds);
    final classMap = {for (final c in classes) c.id!: c.tenLop};

    final eligibleTargets = eligibleSessions.map((s) {
      final className = classMap[s.idLop] ?? 'Lớp #${s.idLop}';
      return (s, className);
    }).toList();

    int selectedTargetId = eligibleTargets.first.$1.id!;
    final reasonController = TextEditingController();

    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: const Text('Xếp học bù'),
            content: SingleChildScrollView(
              child: Column(
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
                    decoration: const InputDecoration(
                      labelText: 'Ghi chú / Lý do',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Consumer(
                    builder: (context, ref, _) {
                      final previewAsync = ref.watch(
                        oneOffSessionConflictPreviewProvider((
                          studentId,
                          selectedTargetId,
                          null,
                        )),
                      );
                      return previewAsync.when(
                        data: (res) => ScheduleConflictBanner(result: res),
                        loading: () => const LinearProgressIndicator(),
                        error: (e, _) => Text('Lỗi kiểm tra trùng lịch: $e'),
                      );
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('Hủy'),
              ),
              Consumer(
                builder: (context, ref, _) {
                  final previewAsync = ref.watch(
                    oneOffSessionConflictPreviewProvider((
                      studentId,
                      selectedTargetId,
                      null,
                    )),
                  );
                  final isBlocked = previewAsync.when(
                    data: (res) => !res.canAssign,
                    loading: () => true,
                    error: (_, __) => true,
                  );

                  return ElevatedButton(
                    onPressed: isBlocked
                        ? null
                        : () async {
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
                                attendanceControllerProvider(selectedTargetId),
                              );
                              if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                            } catch (e) {
                              if (dialogCtx.mounted) {
                                ScaffoldMessenger.of(dialogCtx).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      e.toString().replaceAll(
                                        'Exception: ',
                                        '',
                                      ),
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                    child: const Text('Xác nhận học bù'),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  static Future<void> showPhatSinhDialog({
    required BuildContext context,
    required WidgetRef ref,
    required int targetSessionId,
  }) async {
    final sessionService = await ref.read(sessionServiceProvider.future);
    final targetSession = await sessionService.getSessionById(targetSessionId);
    if (targetSession == null ||
        targetSession.loai != SessionType.PHAT_SINH ||
        targetSession.trangThai != SessionStatus.DU_KIEN) {
      if (!context.mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Buổi học không hợp lệ'),
          content: const Text(
            'Buổi học phát sinh không tồn tại hoặc không ở trạng thái DỰ KIẾN.',
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

    final studentService = await ref.read(studentServiceProvider.future);
    final allStudents = await studentService.getStudents();

    final adjustmentRepo = await ref.read(
      sessionAdjustmentRepositoryProvider.future,
    );
    final existingAdjustments = await adjustmentRepo.getByTargetSession(
      targetSessionId,
    );
    final existingStudentIds = existingAdjustments
        .map((a) => a.idHocSinh)
        .toSet();

    final membershipService = await ref.read(membershipServiceProvider.future);
    final targetDate = DateTime.parse(targetSession.ngay);
    final activeMemberships = await membershipService
        .getActiveMembershipsOnDate(targetDate);

    final membershipsByStudent = <int, List<int>>{};
    for (final m in activeMemberships) {
      membershipsByStudent.putIfAbsent(m.idHocSinh, () => []).add(m.idLop);
    }

    final classService = await ref.read(classServiceProvider.future);
    final classIds = activeMemberships.map((m) => m.idLop).toSet().toList();
    final classes = await classService.getClassesByIds(classIds);
    final classMap = {for (final c in classes) c.id!: c.tenLop};

    final studentClassOptions = <_StudentClassOption>[];
    for (final s in allStudents) {
      if (s.daLuuTru || existingStudentIds.contains(s.id)) continue;
      final studentClassIds = membershipsByStudent[s.id] ?? [];
      for (final cid in studentClassIds) {
        final className = classMap[cid] ?? 'Lớp #$cid';
        studentClassOptions.add(
          _StudentClassOption(
            studentId: s.id!,
            studentName: s.hoTen,
            classId: cid,
            className: className,
          ),
        );
      }
    }

    if (studentClassOptions.isEmpty) {
      if (!context.mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Thêm học sinh phát sinh'),
          content: const Text(
            'Không có học sinh có lớp hợp lệ để thêm vào buổi này.',
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

    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final selectedOpt = studentClassOptions[selectedOptionIndex];

          return AlertDialog(
            title: const Text('Thêm học sinh tham gia buổi phát sinh'),
            content: SingleChildScrollView(
              child: Column(
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
                  const SizedBox(height: 12),
                  Consumer(
                    builder: (context, ref, _) {
                      final previewAsync = ref.watch(
                        oneOffSessionConflictPreviewProvider((
                          selectedOpt.studentId,
                          targetSessionId,
                          null,
                        )),
                      );
                      return previewAsync.when(
                        data: (res) => ScheduleConflictBanner(result: res),
                        loading: () => const LinearProgressIndicator(),
                        error: (e, _) => Text('Lỗi kiểm tra trùng lịch: $e'),
                      );
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('Hủy'),
              ),
              Consumer(
                builder: (context, ref, _) {
                  final previewAsync = ref.watch(
                    oneOffSessionConflictPreviewProvider((
                      selectedOpt.studentId,
                      targetSessionId,
                      null,
                    )),
                  );
                  final isBlocked = previewAsync.when(
                    data: (res) => !res.canAssign,
                    loading: () => true,
                    error: (_, __) => true,
                  );

                  return ElevatedButton(
                    onPressed: isBlocked
                        ? null
                        : () async {
                            try {
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
                              ref.invalidate(
                                attendanceControllerProvider(targetSessionId),
                              );
                              if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                            } catch (e) {
                              if (dialogCtx.mounted) {
                                ScaffoldMessenger.of(dialogCtx).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      e.toString().replaceAll(
                                        'Exception: ',
                                        '',
                                      ),
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                    child: const Text('Xác nhận thêm'),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StudentClassOption {
  final int studentId;
  final String studentName;
  final int classId;
  final String className;

  _StudentClassOption({
    required this.studentId,
    required this.studentName,
    required this.classId,
    required this.className,
  });
}
