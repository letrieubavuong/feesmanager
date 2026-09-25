import 'package:flutter/material.dart';
import 'app_feedback.dart';

class DirtyFormScope extends StatelessWidget {
  final bool isDirty;
  final Widget child;
  final String title;
  final String message;

  const DirtyFormScope({
    super.key,
    required this.isDirty,
    required this.child,
    this.title = 'Rời khỏi trang?',
    this.message =
        'Bạn có thay đổi chưa lưu. Bạn có chắc muốn rời đi và bỏ các thay đổi này không?',
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !isDirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final confirmDiscard = await AppFeedback.showConfirmDialog(
          context,
          title: title,
          message: message,
          confirmLabel: 'Bỏ thay đổi',
          cancelLabel: 'Tiếp tục sửa',
          isDestructive: true,
        );
        if (confirmDiscard && context.mounted) {
          Navigator.of(context).pop(result);
        }
      },
      child: child,
    );
  }
}
