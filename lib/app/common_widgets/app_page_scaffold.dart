import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../navigation/app_destination.dart';
import '../navigation/app_global_drawer.dart';
import '../navigation/navigation_controller.dart';
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
  }) : assert(title != null || titleWidget != null, 'Provide either title or titleWidget');

  static Future<void> goToGlobalDestination(
    BuildContext context,
    WidgetRef ref,
    AppDestinationId destination, {
    bool isDirty = false,
  }) async {
    // 1. Close drawer if open
    if (Scaffold.of(context).isDrawerOpen) {
      Navigator.of(context).pop();
    }

    // 2. Clear nested route stack back to root AppShell
    Navigator.of(context).popUntil((route) => route.isFirst);

    // 3. Switch active navigation destination
    ref.read(navigationControllerProvider.notifier).goTo(destination);
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
