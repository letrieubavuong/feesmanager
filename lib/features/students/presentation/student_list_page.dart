import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/common_widgets/app_empty_state.dart';
import '../../../app/common_widgets/app_error_state.dart';
import '../../../app/common_widgets/app_loading_state.dart';
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
  bool? _filterArchived = false;

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
      drawer: const AppGlobalDrawer(),
      appBar: AppBar(
        leading: const GlobalMenuButton(),
        title: Text(l10n.navStudents),
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
                  key: UiKeys.studentSearch,
                  controller: _searchController,
                  hintText: l10n.studentSearchPlaceholder,
                  onChanged: (value) {
                    ref
                        .read(studentListControllerProvider.notifier)
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
                              .read(studentListControllerProvider.notifier)
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
                      key: UiKeys.studentActiveFilter,
                      label: Text(l10n.filterActive),
                      selected: _filterArchived == false,
                      onSelected: (_) {
                        setState(() => _filterArchived = false);
                        ref
                            .read(studentListControllerProvider.notifier)
                            .setFilter(false);
                      },
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      key: UiKeys.studentArchivedFilter,
                      label: Text(l10n.filterArchived),
                      selected: _filterArchived == true,
                      onSelected: (_) {
                        setState(() => _filterArchived = true);
                        ref
                            .read(studentListControllerProvider.notifier)
                            .setFilter(true);
                      },
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: Text(l10n.filterAll),
                      selected: _filterArchived == null,
                      onSelected: (_) {
                        setState(() => _filterArchived = null);
                        ref
                            .read(studentListControllerProvider.notifier)
                            .setFilter(null);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: studentListAsync.when(
        data: (students) {
          if (students.isEmpty) {
            return AppEmptyState(title: l10n.searchNoResults);
          }
          return RefreshIndicator(
            onRefresh: () =>
                ref.read(studentListControllerProvider.notifier).refresh(),
            child: ListView.separated(
              itemCount: students.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final student = students[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: student.daLuuTru
                        ? Theme.of(context).colorScheme.outlineVariant
                        : Theme.of(context).colorScheme.primaryContainer,
                    child: Icon(
                      student.daLuuTru ? Icons.archive : Icons.person,
                      color: student.daLuuTru
                          ? Theme.of(context).colorScheme.outline
                          : Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  title: Text(
                    student.hoTen,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      decoration: student.daLuuTru
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  subtitle: Text(
                    '${student.khoi != null ? l10n.studentGradeItem(student.khoi!) : ''} ${student.truongDangHoc != null ? '- ${student.truongDangHoc}' : ''}\nPH: ${student.tenPhuHuynh ?? 'N/A'} - ${student.sdtPhuHuynh ?? 'N/A'}',
                  ),
                  isThreeLine: true,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            StudentDetailPage(studentId: student.id!),
                      ),
                    );
                    ref.read(studentListControllerProvider.notifier).refresh();
                  },
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
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const StudentFormPage()),
          );
          ref.read(studentListControllerProvider.notifier).refresh();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
