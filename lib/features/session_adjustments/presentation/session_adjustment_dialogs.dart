import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../attendance/presentation/attendance_controller.dart';
import '../../schedule_conflicts/presentation/schedule_conflict_banner.dart';
import '../../schedule_conflicts/presentation/schedule_conflict_providers.dart';
import '../../sessions/domain/class_session.dart';
import '../../sessions/domain/session_service.dart';
import '../../students/domain/student.dart';
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
        builder: (ctx, setDialogState) {
          final targetSession = eligibleTargets.firstWhere(
            (s) => s.id == selectedTargetId,
          );

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
                        oneOffConflictPreviewProvider((
                          studentId,
                          targetSession.ngay,
                          targetSession.gioBatDau,
                          targetSession.gioKetThuc,
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
                  bool isBlocked = false;
                  final previewAsync = ref.watch(
                    oneOffConflictPreviewProvider((
                      studentId,
                      targetSession.ngay,
                      targetSession.gioBatDau,
                      targetSession.gioKetThuc,
                      originalSessionId,
                    )),
                  );
                  if (previewAsync.value != null &&
                      !previewAsync.value!.canAssign) {
                    isBlocked = true;
                  }

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

    final futureSessions = await sessionService.getSessionsForClassAndRange(
      0,
      DateTime.parse(origSession.ngay),
      DateTime.now().add(const Duration(days: 90)),
    );

    final eligibleTargets = <(ClassSession, String)>[];
    for (final s in futureSessions) {
      if (s.loai == SessionType.HOC_BU &&
          s.trangThai == SessionStatus.DU_KIEN) {
        eligibleTargets.add((s, 'Lớp #${s.idLop}'));
      }
    }

    if (eligibleTargets.isEmpty) {
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

    int selectedTargetId = eligibleTargets.first.$1.id!;
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final targetSession = eligibleTargets
              .firstWhere((pair) => pair.$1.id == selectedTargetId)
              .$1;

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
                        oneOffConflictPreviewProvider((
                          studentId,
                          targetSession.ngay,
                          targetSession.gioBatDau,
                          targetSession.gioKetThuc,
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
                  bool isBlocked = false;
                  final previewAsync = ref.watch(
                    oneOffConflictPreviewProvider((
                      studentId,
                      targetSession.ngay,
                      targetSession.gioBatDau,
                      targetSession.gioKetThuc,
                      null,
                    )),
                  );
                  if (previewAsync.value != null &&
                      !previewAsync.value!.canAssign) {
                    isBlocked = true;
                  }

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
    if (targetSession == null) return;

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

    final studentClassOptions = <_StudentClassOption>[];
    for (final s in allStudents) {
      if (s.daLuuTru || existingStudentIds.contains(s.id)) continue;
      studentClassOptions.add(
        _StudentClassOption(
          studentId: s.id!,
          studentName: s.hoTen,
          classId: targetSession.idLop,
          className: 'Lớp #${targetSession.idLop}',
        ),
      );
    }

    if (studentClassOptions.isEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Thêm học sinh phát sinh'),
          content: const Text(
            'Không có học sinh phù hợp để thêm vào buổi này.',
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
                        oneOffConflictPreviewProvider((
                          selectedOpt.studentId,
                          targetSession.ngay,
                          targetSession.gioBatDau,
                          targetSession.gioKetThuc,
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
                  bool isBlocked = false;
                  final previewAsync = ref.watch(
                    oneOffConflictPreviewProvider((
                      selectedOpt.studentId,
                      targetSession.ngay,
                      targetSession.gioBatDau,
                      targetSession.gioKetThuc,
                      null,
                    )),
                  );
                  if (previewAsync.value != null &&
                      !previewAsync.value!.canAssign) {
                    isBlocked = true;
                  }

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
