import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import 'app_feedback.dart';

class DirtyFormScope extends StatelessWidget {
  final bool isDirty;
  final Widget child;
  final String? title;
  final String? message;

  const DirtyFormScope({
    super.key,
    required this.isDirty,
    required this.child,
    this.title,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return PopScope(
      canPop: !isDirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final confirmDiscard = await AppFeedback.showConfirmDialog(
          context,
          title: title ?? l10n?.dirtyFormTitle ?? 'Rời khỏi trang?',
          message: message ??
              l10n?.dirtyFormMessage ??
              'Bạn có thay đổi chưa lưu. Bạn có chắc muốn rời đi và bỏ các thay đổi này không?',
          confirmLabel: l10n?.dirtyFormDiscard ?? 'Bỏ thay đổi',
          cancelLabel: l10n?.dirtyFormKeepEditing ?? 'Tiếp tục chỉnh sửa',
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
