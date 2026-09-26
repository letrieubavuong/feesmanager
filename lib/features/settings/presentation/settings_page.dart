import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/design_system/app_palettes.dart';
import '../../../app/design_system/theme_controller.dart';
import '../../../app/localization/locale_controller.dart';
import '../../../app/navigation/app_global_drawer.dart';
import '../../../app/navigation/ui_keys.dart';
import '../../../l10n/app_localizations.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final themeState = ref.watch(themeControllerProvider);
    final localeMode = ref.watch(localeControllerProvider);

    return Scaffold(
      drawer: const AppGlobalDrawer(),
      appBar: AppBar(
        leading: const GlobalMenuButton(),
        title: Text(l10n.settingsTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // --- 1. APPEARANCE & THEME SECTION ---
          _buildSectionHeader(
            context,
            title: l10n.settingsAppearance,
            icon: Icons.palette_outlined,
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.settingsThemeMode,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<ThemeMode>(
                    segments: [
                      ButtonSegment(
                        value: ThemeMode.system,
                        label: Text(
                          l10n.themeSystem,
                          key: UiKeys.settingsThemeModeSystem,
                        ),
                        icon: const Icon(Icons.brightness_auto),
                      ),
                      ButtonSegment(
                        value: ThemeMode.light,
                        label: Text(
                          l10n.themeLight,
                          key: UiKeys.settingsThemeModeLight,
                        ),
                        icon: const Icon(Icons.light_mode),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        label: Text(
                          l10n.themeDark,
                          key: UiKeys.settingsThemeModeDark,
                        ),
                        icon: const Icon(Icons.dark_mode),
                      ),
                    ],
                    selected: {themeState.themeMode},
                    onSelectionChanged: (selection) {
                      ref
                          .read(themeControllerProvider.notifier)
                          .setThemeMode(selection.first);
                    },
                  ),

                  const SizedBox(height: 20),
                  const Divider(height: 1),
                  const SizedBox(height: 16),

                  Text(
                    l10n.settingsPalette,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: AppPaletteInfo.all.map((info) {
                      final isSelected = themeState.palette == info.palette;
                      final paletteName = info.name(l10n);

                      return InkWell(
                        key: info.palette == AppPalette.physicsBlue
                            ? UiKeys.settingsPalettePhysicsBlue
                            : info.palette == AppPalette.emerald
                            ? UiKeys.settingsPaletteEmerald
                            : null,
                        borderRadius: BorderRadius.circular(8),
                        onTap: () {
                          ref
                              .read(themeControllerProvider.notifier)
                              .setPalette(info.palette);
                        },
                        child: Container(
                          width: 140,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.outlineVariant,
                              width: isSelected ? 2 : 1,
                            ),
                            color: isSelected
                                ? theme.colorScheme.primaryContainer.withValues(
                                    alpha: 0.3,
                                  )
                                : null,
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 12,
                                backgroundColor: info.primaryColor,
                                child: isSelected
                                    ? const Icon(
                                        Icons.check,
                                        size: 14,
                                        color: Colors.white,
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  paletteName,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // --- 2. LANGUAGE SECTION ---
          _buildSectionHeader(
            context,
            title: l10n.settingsLanguage,
            icon: Icons.language,
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.settingsLanguage,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<AppLocaleMode>(
                    segments: [
                      ButtonSegment(
                        value: AppLocaleMode.system,
                        label: Text(
                          l10n.langSystem,
                          key: UiKeys.settingsLanguageSystem,
                        ),
                      ),
                      ButtonSegment(
                        value: AppLocaleMode.vi,
                        label: Text(
                          l10n.langVietnamese,
                          key: UiKeys.settingsLanguageVi,
                        ),
                      ),
                      ButtonSegment(
                        value: AppLocaleMode.en,
                        label: Text(
                          l10n.langEnglish,
                          key: UiKeys.settingsLanguageEn,
                        ),
                      ),
                    ],
                    selected: {localeMode},
                    onSelectionChanged: (selection) {
                      ref
                          .read(localeControllerProvider.notifier)
                          .setLocaleMode(selection.first);
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // --- 3. APPLICATION INFO SECTION ---
          _buildSectionHeader(
            context,
            title: l10n.settingsAppInfo,
            icon: Icons.info_outline,
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.school_outlined),
                  title: const Text('Tuition2027'),
                  subtitle: Text(l10n.menuSubtitle),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.verified_outlined),
                  title: Text(l10n.appVersion),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.storage_outlined),
                  title: Text(l10n.dbVersion),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}
