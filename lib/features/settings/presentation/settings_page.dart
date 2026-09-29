import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/common_widgets/navy_components.dart';
import '../../../app/design_system/app_theme.dart';
import '../../../app/design_system/theme_controller.dart';
import '../../../app/localization/locale_controller.dart';
import '../../../app/navigation/app_global_drawer.dart';
import '../../../l10n/app_localizations.dart';
import 'bank_account_settings_page.dart';
import '../domain/class_reminder_service.dart';
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
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(child: Text(l10n.settingsThemeMode)),
                SegmentedButton<ThemeMode>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(
                      value: ThemeMode.system,
                      label: Text(l10n.themeSystem),
                    ),
                    ButtonSegment(
                      value: ThemeMode.light,
                      icon: const Icon(Icons.light_mode_outlined),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      icon: const Icon(Icons.dark_mode_outlined),
                    ),
                  ],
                  selected: {themeState.themeMode},
                  onSelectionChanged: (value) => ref
                      .read(themeControllerProvider.notifier)
                      .setThemeMode(value.first),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 2. NGÔN NGỮ
          AppSectionHeader(title: l10n.settingsLanguage),
          AppSectionCard(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(child: Text(l10n.settingsLanguage)),
                SegmentedButton<AppLocaleMode>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(
                      value: AppLocaleMode.system,
                      label: Text('Máy'),
                    ),
                    ButtonSegment(value: AppLocaleMode.vi, label: Text('VI')),
                    ButtonSegment(value: AppLocaleMode.en, label: Text('EN')),
                  ],
                  selected: {localeMode},
                  onSelectionChanged: (value) => ref
                      .read(localeControllerProvider.notifier)
                      .setLocaleMode(value.first),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          const AppSectionHeader(title: 'NHẮC GIỜ DẠY'),
          AppSectionCard(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Thông báo trước buổi học đã lên lịch'),
                const SizedBox(height: 8),
                ref
                    .watch(reminderMinutesProvider)
                    .when(
                      data: (minutes) => SegmentedButton<int>(
                        showSelectedIcon: false,
                        segments: const [
                          ButtonSegment(value: 0, label: Text('Tắt')),
                          ButtonSegment(value: 5, label: Text('5 phút')),
                          ButtonSegment(value: 10, label: Text('10 phút')),
                        ],
                        selected: {minutes},
                        onSelectionChanged: (selected) async {
                          try {
                            await ref
                                .read(classReminderServiceProvider)
                                .setMinutes(selected.first);
                          } catch (error) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  error.toString().replaceFirst(
                                    'Exception: ',
                                    '',
                                  ),
                                ),
                              ),
                            );
                          }
                        },
                      ),
                      loading: () => const LinearProgressIndicator(),
                      error: (error, _) =>
                          Text('Không tải được cài đặt: $error'),
                    ),
                const SizedBox(height: 4),
                const Text(
                  'Nhắc theo các buổi đã sinh trong 30 ngày tới. Mở ứng dụng sau khi sửa lịch để cập nhật thông báo.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          const AppSectionHeader(title: 'CHÍNH SÁCH HỌC PHÍ'),
          AppSectionCard(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            onTap: () =>
                _openSettingsSheet(context, const TuitionPolicySettingsPage()),
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
            padding: const EdgeInsets.all(8),
            onTap: () =>
                _openSettingsSheet(context, const BankAccountSettingsPage()),
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
            padding: const EdgeInsets.all(8),
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
            padding: const EdgeInsets.all(8),
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

  Future<void> _openSettingsSheet(BuildContext context, Widget page) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => SizedBox(
        height: MediaQuery.sizeOf(sheetContext).height * .9,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: page,
        ),
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
