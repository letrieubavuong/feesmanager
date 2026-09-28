import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/common_widgets/app_feedback.dart';
import '../../../app/common_widgets/navy_components.dart';
import '../../../app/design_system/app_theme.dart';
import '../../../app/design_system/theme_controller.dart';
import '../../../app/localization/locale_controller.dart';
import '../../../app/navigation/app_global_drawer.dart';
import '../../../l10n/app_localizations.dart';
import '../data/school_repository.dart';
import '../domain/teaching_reminder.dart';
import 'app_lock_controller.dart';
import 'app_lock_dialogs.dart';
import 'bank_account_settings_page.dart';
import 'center_profile_controller.dart';
import 'teaching_reminder_controller.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final themeMode = ref.watch(themeControllerProvider).themeMode;
    final localeMode = ref.watch(localeControllerProvider);
    final profile = ref.watch(centerProfileProvider);
    final schools = ref.watch(schoolsProvider);
    final reminderState = ref.watch(teachingReminderControllerProvider);
    final lockState = ref.watch(appLockControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const AppGlobalDrawer(),
      appBar: AppBar(
        leading: const GlobalMenuButton(),
        title: Text(l10n.settingsTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 30),
        children: [
          AppSectionHeader(title: l10n.settingsAppearance),
          AppSectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.settingsThemeMode,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<ThemeMode>(
                    showSelectedIcon: false,
                    segments: [
                      ButtonSegment(
                        value: ThemeMode.system,
                        icon: const Icon(Icons.brightness_auto_outlined),
                        label: Text(l10n.themeSystem),
                      ),
                      ButtonSegment(
                        value: ThemeMode.light,
                        icon: const Icon(Icons.light_mode_outlined),
                        label: Text(l10n.themeLight),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        icon: const Icon(Icons.dark_mode_outlined),
                        label: Text(l10n.themeDark),
                      ),
                    ],
                    selected: {themeMode},
                    onSelectionChanged: (value) => ref
                        .read(themeControllerProvider.notifier)
                        .setThemeMode(value.first),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: AppSectionHeader(title: l10n.settingsLanguage)),
              DropdownButtonHideUnderline(
                child: DropdownButton<AppLocaleMode>(
                  value: localeMode,
                  dropdownColor: AppColors.surfaceHigh,
                  style: const TextStyle(color: AppColors.textPrimary),
                  items: [
                    DropdownMenuItem(
                      value: AppLocaleMode.system,
                      child: Text(l10n.langSystem),
                    ),
                    DropdownMenuItem(
                      value: AppLocaleMode.vi,
                      child: Text(l10n.langVietnamese),
                    ),
                    DropdownMenuItem(
                      value: AppLocaleMode.en,
                      child: Text(l10n.langEnglish),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      ref
                          .read(localeControllerProvider.notifier)
                          .setLocaleMode(value);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const AppSectionHeader(title: 'THÔNG TIN TRUNG TÂM'),
          AppSectionCard(
            onTap: () => _editCenter(context, ref, profile),
            child: Row(
              children: [
                const Icon(
                  Icons.business_outlined,
                  color: AppColors.cyanAccent,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        profile.subtitle.isEmpty
                            ? 'Thêm địa chỉ và số điện thoại'
                            : profile.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.textMuted),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const AppSectionHeader(title: 'TRƯỜNG HỌC QUANH KHU VỰC'),
          AppSectionCard(
            onTap: () => _showSchools(context),
            child: Row(
              children: [
                const Icon(Icons.school_outlined, color: AppColors.cyanAccent),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Danh sách trường học',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        schools.when(
                          data: (items) =>
                              '${items.length} trường • Chọn nhanh khi thêm học sinh',
                          loading: () => 'Đang tải danh sách...',
                          error: (_, __) => 'Không tải được danh sách trường',
                        ),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.textMuted),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const AppSectionHeader(title: 'THANH TOÁN & QR'),
          AppSectionCard(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const BankAccountSettingsPage(),
              ),
            ),
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
          const AppSectionHeader(title: 'NHẮC GIỜ DẠY'),
          AppSectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Thông báo nhắc nhở trước giờ dạy',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<TeachingReminderMinutes>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(
                        value: TeachingReminderMinutes.off,
                        label: Text('Tắt'),
                      ),
                      ButtonSegment(
                        value: TeachingReminderMinutes.fiveMinutes,
                        label: Text('Trước 5m'),
                      ),
                      ButtonSegment(
                        value: TeachingReminderMinutes.tenMinutes,
                        label: Text('Trước 10m'),
                      ),
                    ],
                    selected: {reminderState.minutes},
                    onSelectionChanged: (value) {
                      ref
                          .read(teachingReminderControllerProvider.notifier)
                          .setReminderMinutes(value.first);
                    },
                  ),
                ),
                if (reminderState.minutes != TeachingReminderMinutes.off &&
                    !reminderState.isPermissionGranted) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Lưu ý: Quyền thông báo đã bị hệ điều hành từ chối. Vui lòng cấp quyền trong Cài đặt hệ thống.',
                    style: TextStyle(color: AppColors.error, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          const AppSectionHeader(title: 'BẢO MẬT & KHÓA ỨNG DỤNG'),
          AppSectionCard(
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(
                    Icons.lock_outline,
                    color: AppColors.cyanAccent,
                  ),
                  title: const Text(
                    'Khóa bằng mã PIN',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  subtitle: Text(
                    lockState.isPinSet
                        ? 'Đã bật khóa ứng dụng'
                        : 'Yêu cầu nhập PIN khi mở ứng dụng',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  value: lockState.isPinSet,
                  onChanged: (enabled) {
                    if (enabled) {
                      showSetPinBottomSheet(context, ref);
                    } else {
                      showDisableLockDialog(context, ref);
                    }
                  },
                ),
                if (lockState.isPinSet) ...[
                  const Divider(color: AppColors.border, height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.password,
                      color: AppColors.cyanAccent,
                    ),
                    title: const Text(
                      'Đổi mã PIN',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: AppColors.textMuted,
                    ),
                    onTap: () => showChangePinBottomSheet(context, ref),
                  ),
                ],
                if (lockState.isBiometricsAvailable && lockState.isPinSet) ...[
                  const Divider(color: AppColors.border, height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    secondary: const Icon(
                      Icons.fingerprint,
                      color: AppColors.cyanAccent,
                    ),
                    title: const Text(
                      'Mở khóa bằng vân tay / Sinh trắc học',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    subtitle: const Text(
                      'Sử dụng vân tay để mở ứng dụng nhanh hơn',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    value: lockState.isBiometricsEnabled,
                    onChanged: (enabled) {
                      ref
                          .read(appLockControllerProvider.notifier)
                          .setBiometricsEnabled(enabled);
                    },
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
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
                const CompactInfoRow(
                  icon: Icons.verified_outlined,
                  label: 'Phiên bản',
                  value: '1.0.0+1',
                ),
                const Divider(color: AppColors.border, height: 12),
                const CompactInfoRow(
                  icon: Icons.storage_outlined,
                  label: 'Cơ sở dữ liệu',
                  value: 'v16',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editCenter(
    BuildContext context,
    WidgetRef ref,
    CenterProfile profile,
  ) async {
    final name = TextEditingController(text: profile.name);
    final address = TextEditingController(text: profile.address);
    final phone = TextEditingController(text: profile.phone);
    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppColors.surface,
        builder: (sheetContext) => SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              20,
              20,
              MediaQuery.viewInsetsOf(sheetContext).bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Thông tin trung tâm',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: name,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Tên hiển thị trên menu',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: address,
                    decoration: const InputDecoration(
                      labelText: 'Địa chỉ trung tâm',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phone,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Số điện thoại',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () async {
                        if (name.text.trim().isEmpty) {
                          AppFeedback.showErrorSnackBar(
                            sheetContext,
                            'Vui lòng nhập tên trung tâm',
                          );
                          return;
                        }
                        await ref
                            .read(centerProfileProvider.notifier)
                            .save(
                              CenterProfile(
                                name: name.text,
                                address: address.text,
                                phone: phone.text,
                              ),
                            );
                        if (sheetContext.mounted) Navigator.pop(sheetContext);
                      },
                      child: const Text('Lưu thông tin'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } finally {
      name.dispose();
      address.dispose();
      phone.dispose();
    }
  }

  void _showSchools(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder: (sheetContext) => SafeArea(
        child: FractionallySizedBox(
          heightFactor: 0.72,
          child: Consumer(
            builder: (context, ref, _) {
              final schools = ref.watch(schoolsProvider);
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Trường học',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => _addSchool(sheetContext, ref),
                          icon: const Icon(Icons.add),
                          label: const Text('Thêm'),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(sheetContext),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: schools.when(
                      data: (items) => items.isEmpty
                          ? const Center(
                              child: Text(
                                'Chưa có trường học nào.',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            )
                          : ListView.builder(
                              itemCount: items.length,
                              itemBuilder: (context, index) {
                                final school = items[index];
                                return ListTile(
                                  leading: const Icon(Icons.school_outlined),
                                  title: Text(school.name),
                                  trailing: IconButton(
                                    tooltip: 'Ẩn trường khỏi danh sách chọn',
                                    icon: const Icon(
                                      Icons.remove_circle_outline,
                                    ),
                                    onPressed: () async {
                                      final repo = await ref.read(
                                        schoolRepositoryProvider.future,
                                      );
                                      await repo.archive(school.id);
                                      ref.invalidate(schoolsProvider);
                                    },
                                  ),
                                );
                              },
                            ),
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (error, _) => Center(child: Text('Lỗi: $error')),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _addSchool(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppColors.surface,
        builder: (sheetContext) => SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              20,
              20,
              MediaQuery.viewInsetsOf(sheetContext).bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Thêm trường học',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Tên trường',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () async {
                      try {
                        final repo = await ref.read(
                          schoolRepositoryProvider.future,
                        );
                        await repo.add(controller.text);
                        ref.invalidate(schoolsProvider);
                        if (sheetContext.mounted) Navigator.pop(sheetContext);
                      } catch (error) {
                        if (sheetContext.mounted) {
                          AppFeedback.showErrorSnackBar(
                            sheetContext,
                            error.toString(),
                          );
                        }
                      }
                    },
                    child: const Text('Lưu trường học'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } finally {
      controller.dispose();
    }
  }
}
