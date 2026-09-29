import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/common_widgets/navy_components.dart';
import '../../../app/design_system/app_theme.dart';
import '../../../app/design_system/theme_controller.dart';
import '../../../app/localization/locale_controller.dart';
import '../../../app/navigation/app_global_drawer.dart';
import '../../../app/navigation/ui_keys.dart';
import '../../../l10n/app_localizations.dart';
import 'bank_account_settings_page.dart';
import 'school_catalog_provider.dart';
import 'tuition_policy_settings_page.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    final themeState = ref.watch(themeControllerProvider);
    final localeMode = ref.watch(localeControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const AppGlobalDrawer(),
      appBar: AppBar(
        leading: const GlobalMenuButton(),
        title: Text(l10n.settingsTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(6, 16, 6, 16),
        children: [
          // 1. GIAO DIỆN
          AppSectionHeader(title: l10n.settingsAppearance),
          AppSectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<ThemeMode>(
                  initialValue: themeState.themeMode,
                  dropdownColor: AppColors.surfaceHigh,
                  style: const TextStyle(color: AppColors.textPrimary),
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
                const SizedBox(height: 8),
                const Padding(
                  padding: EdgeInsets.only(left: 4),
                  child: Text(
                    'Bộ nhận diện mặc định: Xanh Vật Lý (Physics Navy)',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 2. NGÔN NGỮ
          AppSectionHeader(title: l10n.settingsLanguage),
          AppSectionCard(
            child: DropdownButtonFormField<AppLocaleMode>(
              initialValue: localeMode,
              dropdownColor: AppColors.surfaceHigh,
              style: const TextStyle(color: AppColors.textPrimary),
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

          const SizedBox(height: 16),

          const AppSectionHeader(title: 'CHÍNH SÁCH HỌC PHÍ'),
          AppSectionCard(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const TuitionPolicySettingsPage(),
              ),
            ),
            child: const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.rule_outlined),
              title: Text('Quy tắc tính học phí theo lớp'),
              subtitle: Text('Đơn giá, số buổi chuẩn và mức tối đa'),
              trailing: Icon(Icons.chevron_right),
            ),
          ),
          const SizedBox(height: 16),

          // 3. THANH TOÁN & QR
          const AppSectionHeader(title: 'THANH TOÁN & QR'),
          AppSectionCard(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const BankAccountSettingsPage(),
                ),
              );
            },
            child: const Row(
              key: Key('bank_account_settings_tile'),
              children: [
                Icon(
                  Icons.account_balance_outlined,
                  color: AppColors.cyanAccent,
                  size: 24,
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tài khoản nhận học phí',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Cấu hình thông tin ngân hàng và VietQR',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: AppColors.textMuted),
              ],
            ),
          ),

          const SizedBox(height: 16),

          const AppSectionHeader(title: 'TRƯỜNG HỌC'),
          AppSectionCard(
            child: Column(
              children: [
                ...ref
                    .watch(schoolCatalogProvider)
                    .when(
                      data: (schools) => schools
                          .map(
                            (name) => ListTile(
                              dense: true,
                              leading: const Icon(Icons.school_outlined),
                              title: Text(name),
                              trailing: IconButton(
                                tooltip: 'Xóa khỏi danh sách trường',
                                icon: const Icon(Icons.close),
                                onPressed: () async {
                                  final service = await ref.read(
                                    schoolCatalogServiceProvider.future,
                                  );
                                  await service.remove(name);
                                  ref.invalidate(schoolCatalogProvider);
                                },
                              ),
                            ),
                          )
                          .toList(),
                      loading: () => [const CircularProgressIndicator()],
                      error: (error, _) => [
                        Text('Không tải được trường học: $error'),
                      ],
                    ),
                TextButton.icon(
                  onPressed: () => _addSchool(context, ref),
                  icon: const Icon(Icons.add),
                  label: const Text('Thêm trường học'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 4. THÔNG TIN ỨNG DỤNG
          AppSectionHeader(title: l10n.settingsAppInfo),
          AppSectionCard(
            child: Column(
              children: [
                CompactInfoRow(
                  icon: Icons.school_outlined,
                  label: 'Ứng dụng',
                  value: '${l10n.appName} (${l10n.menuSubtitle})',
                ),
                const Divider(color: AppColors.border, height: 12),
                CompactInfoRow(
                  icon: Icons.verified_outlined,
                  label: 'Phiên bản',
                  value: l10n.appVersion,
                ),
                const Divider(color: AppColors.border, height: 12),
                CompactInfoRow(
                  icon: Icons.storage_outlined,
                  label: 'Cơ sở dữ liệu',
                  value: l10n.dbVersion,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addSchool(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final name = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            20,
            16,
            MediaQuery.of(sheetContext).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Thêm trường học'),
              TextField(
                controller: controller,
                autofocus: true,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.school_outlined),
                  labelText: 'Tên trường',
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => Navigator.pop(sheetContext, controller.text),
                child: const Text('Lưu'),
              ),
            ],
          ),
        );
      },
    );
    controller.dispose();
    if (name == null || !context.mounted) return;
    try {
      final service = await ref.read(schoolCatalogServiceProvider.future);
      await service.add(name);
      ref.invalidate(schoolCatalogProvider);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', '')),
          ),
        );
      }
    }
  }
}
