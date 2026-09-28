import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../app/common_widgets/app_empty_state.dart';
import '../../../app/common_widgets/app_error_state.dart';
import '../../../app/common_widgets/app_loading_state.dart';
import '../../../app/common_widgets/navy_components.dart';
import '../../../app/common_widgets/student_avatar.dart';
import '../../../app/design_system/app_theme.dart';
import '../../../app/navigation/app_global_drawer.dart';
import '../../../app/navigation/ui_keys.dart';
import '../../../l10n/app_localizations.dart';
import 'student_controller.dart';
import 'student_detail_page.dart';
import 'student_form_page.dart';

class StudentListPage extends ConsumerStatefulWidget {
  const StudentListPage({super.key});

  @override
  ConsumerState<StudentListPage> createState() => _StudentListPageState();
}

class _StudentListPageState extends ConsumerState<StudentListPage> {
  final _searchController = TextEditingController();
  bool _filterArchived = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final studentListAsync = ref.watch(studentListControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const AppGlobalDrawer(),
      appBar: AppBar(
        leading: const GlobalMenuButton(),
        title: Text(l10n.navStudents),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(104),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: TextField(
                  key: UiKeys.studentSearch,
                  controller: _searchController,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Tìm theo tên hoặc SĐT học sinh...',
                    hintStyle: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.clear,
                              color: AppColors.textMuted,
                              size: 18,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              ref
                                  .read(studentListControllerProvider.notifier)
                                  .search('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.surface,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                  ),
                  onChanged: (value) {
                    ref
                        .read(studentListControllerProvider.notifier)
                        .search(value);
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<bool>(
                    segments: [
                      ButtonSegment<bool>(
                        value: false,
                        icon: const Icon(Icons.school_outlined),
                        label: Text(
                          l10n.studentFilterActive,
                          key: UiKeys.studentActiveFilter,
                        ),
                      ),
                      ButtonSegment<bool>(
                        value: true,
                        icon: const Icon(Icons.person_off_outlined),
                        label: Text(
                          l10n.studentFilterStopped,
                          key: UiKeys.studentArchivedFilter,
                        ),
                      ),
                    ],
                    selected: {_filterArchived},
                    emptySelectionAllowed: false,
                    multiSelectionEnabled: false,
                    onSelectionChanged: (newSelection) {
                      if (newSelection.isNotEmpty) {
                        final selectedVal = newSelection.first;
                        setState(() => _filterArchived = selectedVal);
                        ref
                            .read(studentListControllerProvider.notifier)
                            .setFilter(selectedVal);
                      }
                    },
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.resolveWith<Color>((
                        states,
                      ) {
                        if (states.contains(WidgetState.selected)) {
                          return AppColors.primary;
                        }
                        return AppColors.surface;
                      }),
                      foregroundColor: WidgetStateProperty.resolveWith<Color>((
                        states,
                      ) {
                        if (states.contains(WidgetState.selected)) {
                          return Colors.white;
                        }
                        return AppColors.textSecondary;
                      }),
                      iconColor: WidgetStateProperty.resolveWith<Color>((
                        states,
                      ) {
                        if (states.contains(WidgetState.selected)) {
                          return Colors.white;
                        }
                        return AppColors.textSecondary;
                      }),
                      side: WidgetStateProperty.all(
                        const BorderSide(color: AppColors.border),
                      ),
                      shape: WidgetStateProperty.all(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: studentListAsync.when(
        data: (students) {
          if (students.isEmpty) {
            return AppEmptyState(
              title: _filterArchived
                  ? l10n.studentEmptyStopped
                  : l10n.studentEmptyActive,
            );
          }
          return RefreshIndicator(
            onRefresh: () =>
                ref.read(studentListControllerProvider.notifier).refresh(),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              itemCount: students.length,
              itemBuilder: (context, index) {
                final student = students[index];
                final isStopped = student.daLuuTru;

                final parentPhone = student.sdtPhuHuynh?.trim();
                final hasPhone = parentPhone != null && parentPhone.isNotEmpty;
                final parentName = student.tenPhuHuynh?.trim();
                final contactLabel = parentName == null || parentName.isEmpty
                    ? 'PH • ${parentPhone ?? "Chưa có SĐT"}'
                    : '$parentName • ${parentPhone ?? "Chưa có SĐT"}';

                return AppSectionCard(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            StudentDetailPage(studentId: student.id!),
                      ),
                    );
                    if (context.mounted) {
                      ref
                          .read(studentListControllerProvider.notifier)
                          .refresh();
                    }
                  },
                  child: Row(
                    children: [
                      StudentAvatar(
                        gioiTinh: student.gioiTinh,
                        studentName: student.hoTen,
                        radius: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    student.hoTen,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                if (!isStopped)
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    color: AppColors.success,
                                    size: 16,
                                  )
                                else
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.textMuted.withValues(
                                        alpha: 0.15,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'Ngừng học',
                                      style: TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    contactLabel,
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                _contactButton(
                                  icon: Icons.call_outlined,
                                  tooltip: 'Gọi phụ huynh',
                                  enabled: hasPhone,
                                  onPressed: () => _openContact(
                                    context,
                                    Uri(scheme: 'tel', path: parentPhone),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                _contactButton(
                                  icon: Icons.chat_bubble_outline,
                                  label: 'Zalo',
                                  tooltip: 'Mở Zalo phụ huynh',
                                  enabled: hasPhone,
                                  onPressed: () => _openContact(
                                    context,
                                    Uri.https(
                                      'zalo.me',
                                      '/${parentPhone!.replaceAll(RegExp(r'[^0-9]'), '')}',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        color: AppColors.textMuted,
                        size: 20,
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
        loading: () => const AppLoadingState(),
        error: (error, stack) => AppErrorState(
          title: l10n.commonError,
          error: error.toString(),
          onRetry: () =>
              ref.read(studentListControllerProvider.notifier).refresh(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const StudentFormPage()),
          );
          ref.read(studentListControllerProvider.notifier).refresh();
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _contactButton({
    required IconData icon,
    required String tooltip,
    required bool enabled,
    required VoidCallback onPressed,
    String? label,
  }) {
    return SizedBox(
      height: 36,
      child: OutlinedButton(
        onPressed: enabled ? onPressed : null,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          minimumSize: const Size(44, 36),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          foregroundColor: AppColors.cyanAccent,
          side: const BorderSide(color: AppColors.border),
        ),
        child: Tooltip(
          message: tooltip,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 17),
              if (label != null) ...[
                const SizedBox(width: 4),
                Text(label, style: const TextStyle(fontSize: 11)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openContact(BuildContext context, Uri uri) async {
    try {
      if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
    } catch (_) {
      // Show a message below when no installed app can handle the link.
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể mở liên kết trên thiết bị này.')),
      );
    }
  }
}
