import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/common_widgets/app_empty_state.dart';
import '../../../app/common_widgets/app_error_state.dart';
import '../../../app/common_widgets/app_loading_state.dart';
import '../../../app/common_widgets/navy_components.dart';
import '../../../app/design_system/app_theme.dart';
import '../../../app/navigation/app_global_drawer.dart';
import '../../../app/navigation/ui_keys.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../l10n/app_localizations.dart';
import '../../memberships/presentation/membership_providers.dart';
import '../../tuition/presentation/tuition_controller.dart';
import '../domain/class.dart';
import '../domain/class_filter.dart';
import 'class_controller.dart';
import 'class_detail_page.dart';
import 'class_form_bottom_sheet.dart';

class ClassListPage extends ConsumerStatefulWidget {
  const ClassListPage({super.key});

  @override
  ConsumerState<ClassListPage> createState() => _ClassListPageState();
}

class _ClassListPageState extends ConsumerState<ClassListPage> {
  final _searchController = TextEditingController();
  ClassFilter _filter = ClassFilter.active;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final classListAsync = ref.watch(classListControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const AppGlobalDrawer(),
      appBar: AppBar(
        leading: const GlobalMenuButton(),
        title: Text(l10n.navClasses),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(104),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: TextField(
                  key: UiKeys.classSearch,
                  controller: _searchController,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Tìm theo tên lớp hoặc môn học...',
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
                                  .read(classListControllerProvider.notifier)
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
                        .read(classListControllerProvider.notifier)
                        .search(value);
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<ClassFilter>(
                    segments: [
                      ButtonSegment<ClassFilter>(
                        value: ClassFilter.active,
                        icon: const Icon(Icons.class_outlined),
                        label: Text(
                          l10n.classFilterActive,
                          key: UiKeys.classActiveFilter,
                        ),
                      ),
                      ButtonSegment<ClassFilter>(
                        value: ClassFilter.archived,
                        icon: const Icon(Icons.archive_outlined),
                        label: Text(
                          l10n.classFilterStopped,
                          key: UiKeys.classArchivedFilter,
                        ),
                      ),
                    ],
                    selected: {_filter},
                    emptySelectionAllowed: false,
                    multiSelectionEnabled: false,
                    onSelectionChanged: (newSelection) {
                      if (newSelection.isNotEmpty) {
                        final selectedVal = newSelection.first;
                        setState(() => _filter = selectedVal);
                        ref
                            .read(classListControllerProvider.notifier)
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
      body: classListAsync.when(
        data: (classes) {
          if (classes.isEmpty) {
            return AppEmptyState(
              title: _filter == ClassFilter.archived
                  ? l10n.classEmptyStopped
                  : l10n.classEmptyActive,
            );
          }
          return RefreshIndicator(
            onRefresh: () =>
                ref.read(classListControllerProvider.notifier).refresh(),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: classes.length,
              itemBuilder: (context, index) {
                final cls = classes[index];
                return ClassCardTile(cls: cls);
              },
            ),
          );
        },
        loading: () => const AppLoadingState(),
        error: (error, stack) => AppErrorState(
          title: l10n.commonError,
          error: error.toString(),
          onRetry: () =>
              ref.read(classListControllerProvider.notifier).refresh(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () async {
          await showClassFormBottomSheet(context);
          ref.read(classListControllerProvider.notifier).refresh();
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class ClassCardTile extends ConsumerWidget {
  final ClassEntity cls;
  const ClassCardTile({super.key, required this.cls});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sizeAsync = ref.watch(classSizeProvider(cls.id!));
    final currentMonth = DateFormatter.currentMonthString();
    final policyAsync = ref.watch(
      effectiveTuitionPolicyProvider((cls.id!, currentMonth)),
    );
    final isStopped = cls.daLuuTru;

    return AppSectionCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ClassDetailPage(classId: cls.id!),
          ),
        );
        if (context.mounted) {
          ref.read(classListControllerProvider.notifier).refresh();
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isStopped
                      ? const Color(0x26FF5964)
                      : const Color(0x260A84FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isStopped ? Icons.folder_off_outlined : Icons.school_outlined,
                  color: isStopped ? AppColors.error : AppColors.cyanAccent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cls.tenLop,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        decoration: isStopped
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${cls.khoi != null ? 'Khối ${cls.khoi}' : 'Chưa xếp khối'}'
                      '${cls.monHoc != null && cls.monHoc!.isNotEmpty ? ' • Môn ${cls.monHoc}' : ''}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              AppActiveStatusBadge(isActive: !isStopped),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.groups_outlined,
                    size: 16,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(width: 4),
                  sizeAsync.when(
                    data: (size) => Text(
                      'Sĩ số: $size / ${cls.siSoToiDa ?? '∞'}',
                      style: TextStyle(
                        color: (cls.siSoToiDa != null && size >= cls.siSoToiDa!)
                            ? AppColors.error
                            : AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    loading: () => const Text(
                      '...',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                    error: (_, __) => const Text(
                      '?',
                      style: TextStyle(color: AppColors.error, fontSize: 12),
                    ),
                  ),
                ],
              ),
              policyAsync.when(
                data: (policy) {
                  if (policy == null) {
                    return const Text(
                      'Chưa có học phí',
                      style: TextStyle(
                        color: AppColors.warning,
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                    );
                  }
                  return Text(
                    '${policy.hocPhiMoiBuoi}đ / buổi',
                    style: const TextStyle(
                      color: AppColors.cyanAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
