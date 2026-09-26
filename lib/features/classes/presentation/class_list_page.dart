import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/common_widgets/app_empty_state.dart';
import '../../../app/common_widgets/app_error_state.dart';
import '../../../app/common_widgets/app_loading_state.dart';
import '../../../app/navigation/app_global_drawer.dart';
import '../../../app/navigation/ui_keys.dart';
import '../../../l10n/app_localizations.dart';
import '../../memberships/presentation/membership_providers.dart';
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
      drawer: const AppGlobalDrawer(),
      appBar: AppBar(
        leading: const GlobalMenuButton(),
        title: Text(l10n.navClasses),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: SearchBar(
                  key: UiKeys.classSearch,
                  controller: _searchController,
                  hintText: l10n.classSearchPlaceholder,
                  onChanged: (value) {
                    ref
                        .read(classListControllerProvider.notifier)
                        .search(value);
                  },
                  leading: const Icon(Icons.search),
                  trailing: [
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref
                              .read(classListControllerProvider.notifier)
                              .search('');
                        },
                      ),
                  ],
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: Row(
                  children: [
                    FilterChip(
                      key: UiKeys.classActiveFilter,
                      label: Text(l10n.filterActive),
                      selected: _filter == ClassFilter.active,
                      onSelected: (_) {
                        setState(() => _filter = ClassFilter.active);
                        ref
                            .read(classListControllerProvider.notifier)
                            .setFilter(ClassFilter.active);
                      },
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      key: UiKeys.classArchivedFilter,
                      label: Text(l10n.filterArchived),
                      selected: _filter == ClassFilter.archived,
                      onSelected: (_) {
                        setState(() => _filter = ClassFilter.archived);
                        ref
                            .read(classListControllerProvider.notifier)
                            .setFilter(ClassFilter.archived);
                      },
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: Text(l10n.filterAll),
                      selected: _filter == ClassFilter.all,
                      onSelected: (_) {
                        setState(() => _filter = ClassFilter.all);
                        ref
                            .read(classListControllerProvider.notifier)
                            .setFilter(ClassFilter.all);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: classListAsync.when(
        data: (classes) {
          if (classes.isEmpty) {
            return AppEmptyState(title: l10n.searchNoResults);
          }
          return RefreshIndicator(
            onRefresh: () =>
                ref.read(classListControllerProvider.notifier).refresh(),
            child: ListView.separated(
              itemCount: classes.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final cls = classes[index];
                return ClassListTile(cls: cls);
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
        onPressed: () async {
          await showClassFormBottomSheet(context);
          ref.read(classListControllerProvider.notifier).refresh();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class ClassListTile extends ConsumerWidget {
  final ClassEntity cls;
  const ClassListTile({super.key, required this.cls});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final sizeAsync = ref.watch(classSizeProvider(cls.id!));

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: cls.daLuuTru
            ? Theme.of(context).colorScheme.outlineVariant
            : Theme.of(context).colorScheme.primaryContainer,
        child: Icon(
          cls.daLuuTru ? Icons.archive : Icons.class_outlined,
          color: cls.daLuuTru
              ? Theme.of(context).colorScheme.outline
              : Theme.of(context).colorScheme.primary,
        ),
      ),
      title: Text(
        cls.tenLop,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          decoration: cls.daLuuTru ? TextDecoration.lineThrough : null,
          color: cls.daLuuTru ? Theme.of(context).colorScheme.outline : null,
        ),
      ),
      subtitle: Text(
        '${cls.khoi != null ? l10n.studentGradeItem(cls.khoi!) : ''} ${cls.monHoc != null && cls.monHoc!.isNotEmpty ? '• ${cls.monHoc}' : ''}',
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          sizeAsync.when(
            data: (size) => Text(
              '$size / ${cls.siSoToiDa ?? '∞'}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: (cls.siSoToiDa != null && size >= cls.siSoToiDa!)
                    ? Colors.red
                    : null,
                fontWeight: FontWeight.bold,
              ),
            ),
            loading: () => const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            error: (_, __) => const Text('?'),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, size: 20),
        ],
      ),
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ClassDetailPage(classId: cls.id!),
          ),
        );
        ref.read(classListControllerProvider.notifier).refresh();
      },
    );
  }
}
