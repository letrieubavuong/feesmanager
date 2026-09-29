import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../../features/settings/presentation/center_profile_controller.dart';
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
    final profile = ref.watch(centerProfileProvider);

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
                        profile.name.isEmpty
                            ? (l10n?.appName ?? 'Tuition manager')
                            : profile.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        profile.subtitle.isEmpty
                            ? l10n?.menuSubtitle ?? 'Quản lý trung tâm dạy thêm'
                            : profile.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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
                  'v2.6 | DB v16',
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
