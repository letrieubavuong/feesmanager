import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
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
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: Row(
                  children: [
                    ChoiceChip(
                      key: UiKeys.studentActiveFilter,
                      label: const Text('Học sinh đang hoạt động'),
                      selected: _filterArchived == false,
                      selectedColor: AppColors.primary,
                      backgroundColor: AppColors.surface,
                      labelStyle: TextStyle(
                        color: _filterArchived == false
                            ? Colors.white
                            : AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      onSelected: (_) {
                        setState(() => _filterArchived = false);
                        ref
                            .read(studentListControllerProvider.notifier)
                            .setFilter(false);
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      key: UiKeys.studentArchivedFilter,
                      label: const Text('Học sinh ngừng học'),
                      selected: _filterArchived == true,
                      selectedColor: AppColors.primary,
                      backgroundColor: AppColors.surface,
                      labelStyle: TextStyle(
                        color: _filterArchived == true
                            ? Colors.white
                            : AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      onSelected: (_) {
                        setState(() => _filterArchived = true);
                        ref
                            .read(studentListControllerProvider.notifier)
                            .setFilter(true);
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Tất cả'),
                      selected: _filterArchived == null,
                      selectedColor: AppColors.primary,
                      backgroundColor: AppColors.surface,
                      labelStyle: TextStyle(
                        color: _filterArchived == null
                            ? Colors.white
                            : AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
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
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: students.length,
              itemBuilder: (context, index) {
                final student = students[index];
                final isStopped = student.daLuuTru;
                return AppSectionCard(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    student.hoTen,
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
                                ),
                                AppActiveStatusBadge(isActive: !isStopped),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${student.khoi != null ? 'Khối ${student.khoi}' : 'Chưa xếp khối'}'
                              '${student.truongDangHoc != null ? ' • ${student.truongDangHoc}' : ''}',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'PH: ${student.tenPhuHuynh ?? 'Chưa cập nhật'} - ${student.sdtPhuHuynh ?? 'Không có SĐT'}',
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 11,
                              ),
                              overflow: TextOverflow.ellipsis,
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
}
