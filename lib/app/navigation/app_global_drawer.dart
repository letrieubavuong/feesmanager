import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../common_widgets/app_page_scaffold.dart';
import 'app_destination.dart';
import 'navigation_controller.dart';
import 'ui_keys.dart';

class AppGlobalDrawer extends ConsumerWidget {
  const AppGlobalDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentDestId = ref.watch(navigationControllerProvider);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Drawer(
      key: UiKeys.globalDrawer,
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: theme.colorScheme.primary,
                  child: Icon(
                    Icons.school,
                    size: 32,
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tuition2027',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n?.menuSubtitle ?? 'Quản lý trung tâm dạy thêm',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer
                              .withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: AppDestination.globalMenuDestinations.map((dest) {
                final isSelected = dest.id == currentDestId;
                final label = l10n != null ? dest.label(l10n) : dest.id.name;

                return ListTile(
                  key: dest.drawerKey,
                  leading: Icon(
                    isSelected ? dest.selectedIcon : dest.icon,
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  title: Text(
                    label,
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  selected: isSelected,
                  selectedTileColor: theme.colorScheme.primaryContainer
                      .withValues(alpha: 0.4),
                  onTap: () {
                    AppPageScaffold.goToGlobalDestination(
                      context,
                      ref,
                      dest.id,
                    );
                  },
                );
              }).toList(),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.verified_user_outlined,
                  size: 16,
                  color: theme.colorScheme.outline,
                ),
                const SizedBox(width: 8),
                Text(
                  'v1.0.0+1 | DB v13',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class GlobalMenuButton extends StatelessWidget {
  const GlobalMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return IconButton(
      key: UiKeys.globalMenuButton,
      icon: const Icon(Icons.menu),
      tooltip: l10n?.globalMenu ?? 'Global Menu',
      onPressed: () {
        Scaffold.of(context).openDrawer();
      },
    );
  }
}
