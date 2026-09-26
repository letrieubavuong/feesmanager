import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../navigation/app_destination.dart';
import '../navigation/app_global_drawer.dart';
import '../navigation/navigation_controller.dart';
import 'app_feedback.dart';
import 'dirty_form_scope.dart';

/// Reusable page scaffold providing unified AppBar, Drawer, Back button,
/// Global Menu button, and Dirty Form Protection across operational pages.
class AppPageScaffold extends StatelessWidget {
  final String? title;
  final Widget? titleWidget;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final PreferredSizeWidget? bottom;
  final bool isDirty;
  final String? dirtyTitle;
  final String? dirtyMessage;
  final bool showGlobalMenu;

  const AppPageScaffold({
    super.key,
    this.title,
    this.titleWidget,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.bottom,
    this.isDirty = false,
    this.dirtyTitle,
    this.dirtyMessage,
    this.showGlobalMenu = true,
  }) : assert(
         title != null || titleWidget != null,
         'Provide either title or titleWidget',
       );

  static Future<bool> confirmCanLeave(
    BuildContext context, {
    required bool isDirty,
    String? dirtyTitle,
    String? dirtyMessage,
  }) async {
    if (!isDirty) return true;

    final l10n = AppLocalizations.of(context);
    final confirmDiscard = await AppFeedback.showConfirmDialog(
      context,
      title: dirtyTitle ?? l10n?.dirtyFormTitle ?? 'Rời khỏi trang?',
      message:
          dirtyMessage ??
          l10n?.dirtyFormMessage ??
          'Bạn có thay đổi chưa lưu. Bạn có chắc muốn rời đi và bỏ các thay đổi này không?',
      confirmLabel: l10n?.dirtyFormDiscard ?? 'Bỏ thay đổi',
      cancelLabel: l10n?.dirtyFormKeepEditing ?? 'Tiếp tục chỉnh sửa',
      isDestructive: true,
    );

    return confirmDiscard;
  }

  static Future<bool> goToGlobalDestination(
    BuildContext context,
    WidgetRef ref,
    AppDestinationId destination, {
    bool isDirty = false,
    String? dirtyTitle,
    String? dirtyMessage,
  }) async {
    // 1. Guard unsaved dirty form changes
    final effectiveIsDirty = isDirty || DirtyFormScope.isFormDirty(context);
    if (effectiveIsDirty) {
      final canLeave = await confirmCanLeave(
        context,
        isDirty: true,
        dirtyTitle: dirtyTitle,
        dirtyMessage: dirtyMessage,
      );
      if (!canLeave || !context.mounted) return false;
    }

    if (!context.mounted) return false;

    // 2. Close drawer if open
    if (Scaffold.of(context).isDrawerOpen) {
      Navigator.of(context).pop();
    }

    // 3. Clear nested route stack back to root AppShell
    if (context.mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }

    // 4. Switch active navigation destination
    ref.read(navigationControllerProvider.notifier).goTo(destination);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();

    return DirtyFormScope(
      isDirty: isDirty,
      title: dirtyTitle,
      message: dirtyMessage,
      child: Scaffold(
        drawer: const AppGlobalDrawer(),
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: canPop
              ? BackButton(onPressed: () => Navigator.of(context).maybePop())
              : const GlobalMenuButton(),
          title: titleWidget ?? Text(title!),
          bottom: bottom,
          actions: [
            if (actions != null) ...actions!,
            if (showGlobalMenu && canPop) const GlobalMenuButton(),
          ],
        ),
        body: body,
        floatingActionButton: floatingActionButton,
      ),
    );
  }
}
