import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/design_system/app_palettes.dart';
import '../../../app/design_system/theme_controller.dart';
import '../../../app/localization/locale_controller.dart';
import '../../../app/navigation/app_global_drawer.dart';
import '../../../app/navigation/ui_keys.dart';
import '../../../l10n/app_localizations.dart';
import 'bank_account_settings_page.dart';
import 'tuition_policy_settings_page.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                  DropdownButtonFormField<ThemeMode>(
                    initialValue: themeState.themeMode,
                    decoration: InputDecoration(
                      labelText: l10n.settingsThemeMode,
                      border: const OutlineInputBorder(),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: ThemeMode.system,
                        key: UiKeys.settingsThemeModeSystem,
                        child: Text(l10n.themeSystem),
                      ),
                      DropdownMenuItem(
                        value: ThemeMode.light,
                        key: UiKeys.settingsThemeModeLight,
                        child: Text(l10n.themeLight),
                      ),
                      DropdownMenuItem(
                        value: ThemeMode.dark,
                        key: UiKeys.settingsThemeModeDark,
                        child: Text(l10n.themeDark),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        ref
                            .read(themeControllerProvider.notifier)
                            .setThemeMode(val);
                      }
                    },
                  ),

                  const SizedBox(height: 16),

                  DropdownButtonFormField<AppPalette>(
                    initialValue: themeState.palette,
                    decoration: InputDecoration(
                      labelText: l10n.settingsPalette,
                      border: const OutlineInputBorder(),
                    ),
                    items: AppPaletteInfo.all.map((info) {
                      return DropdownMenuItem<AppPalette>(
                        value: info.palette,
                        key: info.palette == AppPalette.physicsBlue
                            ? UiKeys.settingsPalettePhysicsBlue
                            : info.palette == AppPalette.emerald
                            ? UiKeys.settingsPaletteEmerald
                            : null,
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 8,
                              backgroundColor: info.primaryColor,
                            ),
                            const SizedBox(width: 8),
                            Text(info.name(l10n)),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        ref
                            .read(themeControllerProvider.notifier)
                            .setPalette(val);
                      }
                    },
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
              child: DropdownButtonFormField<AppLocaleMode>(
                initialValue: localeMode,
                decoration: InputDecoration(
                  labelText: l10n.settingsLanguage,
                  border: const OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(
                    value: AppLocaleMode.system,
                    key: UiKeys.settingsLanguageSystem,
                    child: Text(l10n.langSystem),
                  ),
                  DropdownMenuItem(
                    value: AppLocaleMode.vi,
                    key: UiKeys.settingsLanguageVi,
                    child: Text(l10n.langVietnamese),
                  ),
                  DropdownMenuItem(
                    value: AppLocaleMode.en,
                    key: UiKeys.settingsLanguageEn,
                    child: Text(l10n.langEnglish),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) {
                    ref
                        .read(localeControllerProvider.notifier)
                        .setLocaleMode(val);
                  }
                },
              ),
            ),
          ),

          const SizedBox(height: 24),

          // --- TUITION POLICY SECTION ---
          _buildSectionHeader(
            context,
            title: 'CHÍNH SÁCH HỌC PHÍ',
            icon: Icons.policy_outlined,
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.monetization_on_outlined),
              title: const Text('Chính sách học phí các lớp'),
              subtitle: const Text(
                'Thiết lập đơn giá và số buổi chuẩn tháng cho từng lớp',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const TuitionPolicySettingsPage(),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 24),

          // --- PAYMENT & QR SECTION ---
          _buildSectionHeader(
            context,
            title: 'THANH TOÁN & QR',
            icon: Icons.qr_code_2_outlined,
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              key: const Key('bank_account_settings_tile'),
              leading: const Icon(Icons.account_balance_outlined),
              title: const Text('Tài khoản nhận học phí'),
              subtitle: const Text(
                'Cấu hình thông tin ngân hàng và mã VietQR nhận học phí',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const BankAccountSettingsPage(),
                  ),
                );
              },
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
